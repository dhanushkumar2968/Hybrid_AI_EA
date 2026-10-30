"""Optional local model loading and conservative inference behavior."""

from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .schemas import FEATURE_NAMES, FEATURE_SCHEMA_VERSION, MODEL_NAME, PREDICTION_CLASSES


@dataclass
class Inference:
    prediction_class: str
    model_version: str
    model_name: str
    evidence: list[str]
    warnings: list[str]


class ModelRegistry:
    def __init__(self) -> None:
        self._model: Any | None = None
        self._version = "unavailable"
        self._source = "none"
        self._notes = ["No trained model loaded; inference safely returns NO_TRADE."]
        self._mock = os.getenv("AI_MOCK_MODE", "false").strip().lower() in {"1", "true", "yes"}
        self._load_configured_model()

    def _load_configured_model(self) -> None:
        model_path = os.getenv("MODEL_PATH", "").strip()
        if not model_path:
            return
        path = Path(model_path)
        if not path.is_file():
            self._notes = [f"Configured model file does not exist: {path.name}."]
            return
        try:
            import joblib

            model = joblib.load(path)
            metadata_path = path.with_suffix(".metadata.json")
            metadata = json.loads(metadata_path.read_text(encoding="utf-8"))
            if metadata.get("feature_schema_version") != FEATURE_SCHEMA_VERSION:
                raise ValueError("model feature schema version does not match the service")
            if tuple(metadata.get("feature_names", ())) != FEATURE_NAMES:
                raise ValueError("model feature names do not match the service schema")
            self._model = model
            self._version = str(metadata["model_version"])
            self._source = str(path)
            self._notes = ["Model metadata and feature schema validated."]
        except Exception as exc:
            self._notes = [f"Model unavailable: {type(exc).__name__}: {exc}"]
            self._model = None

    @property
    def ready(self) -> bool:
        return self._model is not None or self._mock

    @property
    def model_version(self) -> str:
        return "mock-v1" if self._mock else self._version

    @property
    def source(self) -> str:
        return "deterministic_mock" if self._mock else self._source

    @property
    def notes(self) -> list[str]:
        return list(self._notes)

    def info(self) -> dict[str, object]:
        return {
            "model_name": "deterministic_mock" if self._mock else MODEL_NAME,
            "model_version": self.model_version,
            "feature_schema_version": FEATURE_SCHEMA_VERSION,
            "model_ready": self.ready,
            "model_source": self.source,
            "notes": self.notes,
        }

    def predict(self, features: dict[str, float]) -> Inference:
        warnings: list[str] = []
        if self._mock:
            score = (
                0.30 * features["trend_direction"]
                + 0.25 * features["structure_break"]
                + 0.20 * features["liquidity_sweep"]
                + 0.15 * features["momentum"]
                + 0.10 * (features["mtf_alignment"] * 2.0 - 1.0)
            )
            result = "BUY_SETUP" if score > 0.20 else "SELL_SETUP" if score < -0.20 else "NO_TRADE"
            return Inference(
                result,
                "mock-v1",
                "deterministic_mock",
                ["Deterministic integration-test response; not a trained model."],
                ["Mock mode is enabled. Do not use this response for trading."],
            )

        if self._model is None:
            return Inference(
                "NO_TRADE",
                "unavailable",
                MODEL_NAME,
                ["No validated model is loaded; the service does not authorize a setup."],
                ["MODEL_UNAVAILABLE"],
            )

        try:
            row = [[features[name] for name in FEATURE_NAMES]]
            prediction = str(self._model.predict(row)[0])
            if prediction not in PREDICTION_CLASSES:
                raise ValueError(f"unsupported model class: {prediction}")
        except Exception as exc:
            return Inference(
                "NO_TRADE",
                self._version,
                MODEL_NAME,
                ["Model inference failed; no setup was authorized."],
                [f"INFERENCE_ERROR:{type(exc).__name__}"],
            )

        evidence = [
            f"Model output class: {prediction}.",
            "Decision scores are not represented as calibrated win probabilities.",
        ]
        if features["spread_atr"] > 0.15:
            warnings.append("SPREAD_ELEVATED")
        if features["mtf_alignment"] < 0.5:
            warnings.append("MULTI_TIMEFRAME_MIXED")
        return Inference(prediction, self._version, MODEL_NAME, evidence, warnings)
