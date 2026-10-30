import numpy as np

from hybrid_ai.features import build_features, validate_bars
from hybrid_ai.schemas import FEATURE_NAMES


def test_features_use_expected_names_and_finite_recent_values(synthetic_bars):
    validated = validate_bars(synthetic_bars)
    features = build_features(validated, "M30")
    assert tuple(name for name in FEATURE_NAMES if name in features.columns) == FEATURE_NAMES
    assert np.isfinite(features.iloc[-1][list(FEATURE_NAMES)].astype(float)).all()
    assert 0.0 <= features.iloc[-1]["mtf_alignment"] <= 1.0
    assert 0.0 <= features.iloc[-1]["session_code"] <= 3.0


def test_invalid_ohlc_is_rejected(synthetic_bars):
    synthetic_bars.loc[10, "high"] = synthetic_bars.loc[10, "low"] - 1.0
    try:
        validate_bars(synthetic_bars)
    except ValueError as exc:
        assert "high is below" in str(exc)
    else:
        raise AssertionError("invalid high/low relationship was accepted")


def test_higher_timeframe_features_do_not_depend_on_future_rows(synthetic_bars):
    full = build_features(synthetic_bars, "M30")
    truncated = build_features(synthetic_bars.iloc[:220], "M30")
    expected = full.iloc[219][list(FEATURE_NAMES)].astype(float).to_numpy()
    actual = truncated.iloc[-1][list(FEATURE_NAMES)].astype(float).to_numpy()
    assert np.allclose(expected, actual, equal_nan=True)
