"""Chronological comparison, walk-forward validation, and untouched OOS test."""

from __future__ import annotations

import argparse
import hashlib
import json
from datetime import datetime, timezone
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from sklearn.dummy import DummyClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score, balanced_accuracy_score, f1_score
from sklearn.model_selection import TimeSeriesSplit
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler

from hybrid_ai.schemas import FEATURE_NAMES, FEATURE_SCHEMA_VERSION, MODEL_NAME

CLASSES = ("BUY_SETUP", "SELL_SETUP", "NO_TRADE")


def make_rule_baseline(frame: pd.DataFrame) -> np.ndarray:
    """Transparent non-ML baseline based on structure, sweep, then momentum."""
    direction = np.where(
        frame["structure_break"] != 0,
        frame["structure_break"],
        np.where(frame["liquidity_sweep"] != 0, frame["liquidity_sweep"], np.sign(frame["momentum"])),
    )
    confidence = (
        (frame["mtf_alignment"].to_numpy() >= 2.0 / 3.0)
        & (np.abs(frame["momentum"].to_numpy()) >= 0.25)
    )
    return np.where(
        confidence & (direction > 0),
        "BUY_SETUP",
        np.where(confidence & (direction < 0), "SELL_SETUP", "NO_TRADE"),
    )


def _metrics(actual: np.ndarray, predicted: np.ndarray) -> dict[str, float]:
    return {
        "accuracy": float(accuracy_score(actual, predicted)),
        "balanced_accuracy": float(balanced_accuracy_score(actual, predicted)),
        "macro_f1": float(f1_score(actual, predicted, labels=list(CLASSES), average="macro", zero_division=0)),
    }


def _net_price_result(
    predicted: np.ndarray,
    gross: np.ndarray,
    cost: np.ndarray,
) -> dict[str, float | int]:
    direction = np.where(predicted == "BUY_SETUP", 1.0, np.where(predicted == "SELL_SETUP", -1.0, 0.0))
    net = direction * gross - np.where(direction != 0.0, cost, 0.0)
    return {
        "trades": int(np.count_nonzero(direction)),
        "sum_net_price_change": float(net.sum()),
        "mean_net_price_change_per_row": float(net.mean()) if len(net) else 0.0,
    }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path, help="Cost-labeled CSV from prepare_data.py")
    parser.add_argument("--model-dir", default=Path("models"), type=Path)
    parser.add_argument("--horizon-bars", type=int, default=5, help="Purged bars at each validation boundary")
    parser.add_argument("--folds", type=int, default=5)
    args = parser.parse_args()

    data = pd.read_csv(args.input)
    required = set(FEATURE_NAMES) | {"label", "gross_forward_price_change", "round_turn_cost_price"}
    missing = sorted(required - set(data.columns))
    if missing:
        raise SystemExit(f"Input lacks required columns: {', '.join(missing)}")
    data["timestamp"] = pd.to_datetime(data["timestamp"], utc=True, errors="raise")
    data = data.sort_values("timestamp").drop_duplicates("timestamp", keep="last").reset_index(drop=True)
    if not data["label"].isin(CLASSES).all():
        raise SystemExit("Input contains labels outside BUY_SETUP, SELL_SETUP, NO_TRADE.")
    if len(data) < 300:
        raise SystemExit("At least 300 labeled rows are required for train/validation/OOS evaluation.")
    if args.horizon_bars < 1:
        raise SystemExit("--horizon-bars must be positive.")

    features = data.loc[:, FEATURE_NAMES].replace([np.inf, -np.inf], np.nan)
    if features.isna().any().any():
        raise SystemExit("Feature matrix contains non-finite values.")
    labels = data["label"].to_numpy(dtype=str)
    n = len(data)
    train_end = int(n * 0.70)
    validation_end = int(n * 0.85)
    if train_end <= args.horizon_bars * (args.folds + 1):
        raise SystemExit("Insufficient training rows for the requested walk-forward folds.")
    if validation_end - train_end <= args.horizon_bars or n - validation_end <= 20:
        raise SystemExit("Chronological validation or out-of-sample window is too small.")

    candidates = {
        "logistic_regression": make_pipeline(
            StandardScaler(),
            LogisticRegression(max_iter=1000, class_weight="balanced", random_state=17),
        ),
        "random_forest": RandomForestClassifier(
            n_estimators=400,
            min_samples_leaf=5,
            class_weight="balanced_subsample",
            random_state=17,
            n_jobs=-1,
        ),
    }
    walk_forward: dict[str, list[dict[str, float]]] = {name: [] for name in candidates}
    splitter = TimeSeriesSplit(n_splits=args.folds)
    x_train_val = features.iloc[:validation_end].reset_index(drop=True)
    y_train_val = labels[:validation_end]
    for fold, (train_idx, valid_idx) in enumerate(splitter.split(x_train_val), start=1):
        purged_train = train_idx[:-args.horizon_bars]
        if len(purged_train) == 0:
            continue
        for name, prototype in candidates.items():
            model = clone_model(prototype)
            model.fit(x_train_val.iloc[purged_train], y_train_val[purged_train])
            prediction = model.predict(x_train_val.iloc[valid_idx])
            walk_forward[name].append({"fold": fold, **_metrics(y_train_val[valid_idx], prediction)})

    validation_slice = slice(train_end, validation_end)
    y_validation = labels[validation_slice]
    validation_results: dict[str, dict[str, float]] = {}
    for name, prototype in candidates.items():
        model = clone_model(prototype)
        fit_end = train_end - args.horizon_bars
        model.fit(features.iloc[:fit_end], labels[:fit_end])
        prediction = model.predict(features.iloc[validation_slice])
        validation_results[name] = _metrics(y_validation, prediction)
    selected_name = max(validation_results, key=lambda name: validation_results[name]["macro_f1"])

    test_start = validation_end + args.horizon_bars
    final_model = clone_model(candidates[selected_name])
    final_fit_end = test_start - args.horizon_bars
    if final_fit_end <= 0:
        raise SystemExit("Insufficient rows after purging the out-of-sample boundary.")
    final_model.fit(features.iloc[:final_fit_end], labels[:final_fit_end])
    test_features = features.iloc[test_start:]
    test_labels = labels[test_start:]
    ml_prediction = final_model.predict(test_features)
    baseline_prediction = make_rule_baseline(data.iloc[test_start:])
    dummy = DummyClassifier(strategy="most_frequent")
    dummy.fit(features.iloc[:final_fit_end], labels[:final_fit_end])
    dummy_prediction = dummy.predict(test_features)
    gross = data.loc[test_start:, "gross_forward_price_change"].to_numpy(dtype=float)
    costs = data.loc[test_start:, "round_turn_cost_price"].to_numpy(dtype=float)

    source_hash = hashlib.sha256(args.input.read_bytes()).hexdigest()
    model_version = datetime.now(timezone.utc).strftime("xau-%Y%m%dT%H%M%SZ")
    args.model_dir.mkdir(parents=True, exist_ok=True)
    model_path = args.model_dir / "xauusd_setup_classifier.joblib"
    metadata_path = model_path.with_suffix(".metadata.json")
    joblib.dump(final_model, model_path)
    metadata = {
        "model_name": MODEL_NAME,
        "model_version": model_version,
        "feature_schema_version": FEATURE_SCHEMA_VERSION,
        "feature_names": list(FEATURE_NAMES),
        "classes": list(CLASSES),
        "selected_model_family": selected_name,
        "training_rows": test_start,
        "out_of_sample_rows": len(test_labels),
        "training_data_sha256": source_hash,
        "trained_at_utc": datetime.now(timezone.utc).isoformat(),
        "scores_are_calibrated_probabilities": False,
    }
    metadata_path.write_text(json.dumps(metadata, indent=2), encoding="utf-8")
    report = {
        "model_version": model_version,
        "data_file": str(args.input),
        "data_sha256": source_hash,
        "rows": n,
        "chronological_splits": {"train_end": train_end, "validation_end": validation_end, "oos_start": test_start},
        "walk_forward": walk_forward,
        "validation_model_comparison": validation_results,
        "selected_model_family": selected_name,
        "out_of_sample": {
            "ml": {**_metrics(test_labels, ml_prediction), **_net_price_result(ml_prediction, gross, costs)},
            "rule_baseline": {
                **_metrics(test_labels, baseline_prediction),
                **_net_price_result(baseline_prediction, gross, costs),
            },
            "majority_class_baseline": {
                **_metrics(test_labels, dummy_prediction),
                **_net_price_result(dummy_prediction, gross, costs),
            },
            "note": "Historical sample metrics only; not a claim of future profitability.",
        },
        "model_artifacts": [str(model_path), str(metadata_path)],
    }
    report_path = args.model_dir / "evaluation_report.json"
    report_path.write_text(json.dumps(report, indent=2), encoding="utf-8")
    print(json.dumps(report, indent=2))
    print(f"Saved model metadata to {metadata_path}")
    print(f"Saved evaluation report to {report_path}")


def clone_model(model):
    from sklearn.base import clone

    return clone(model)


if __name__ == "__main__":
    main()
