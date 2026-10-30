import numpy as np

from hybrid_ai.features import build_features, validate_bars
from training.prepare_data import CostAssumptions, label_outcomes
from training.train_model import make_rule_baseline
from hybrid_ai.schemas import FEATURE_NAMES


def test_labels_include_explicit_round_turn_costs(synthetic_bars):
    bars = validate_bars(synthetic_bars)
    features = build_features(bars, "M30")
    costs = CostAssumptions(
        fallback_spread_price=None,
        slippage_price_per_side=0.10,
        commission_usd_per_lot_round_turn=10.0,
        contract_size_oz_per_lot=100.0,
        lots=1.0,
    )
    labeled = label_outcomes(bars, features, 5, costs)
    assert (labeled["round_turn_cost_price"] >= 0.45).all()
    assert set(labeled["label"].unique()).issubset({"BUY_SETUP", "SELL_SETUP", "NO_TRADE"})
    assert np.isfinite(labeled[list(FEATURE_NAMES)].to_numpy(dtype=float)).all()


def test_rule_baseline_returns_only_supported_classes(synthetic_bars):
    features = build_features(validate_bars(synthetic_bars), "M30").dropna()
    baseline = make_rule_baseline(features)
    assert set(np.unique(baseline)).issubset({"BUY_SETUP", "SELL_SETUP", "NO_TRADE"})
