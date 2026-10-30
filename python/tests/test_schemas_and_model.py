from datetime import datetime, timedelta, timezone

import pytest
from pydantic import ValidationError

from hybrid_ai.model import ModelRegistry
from hybrid_ai.schemas import AnalyzeRequest, FEATURE_NAMES, FEATURE_SCHEMA_VERSION


def request_payload():
    now = datetime.now(timezone.utc)
    return {
        "schema_version": "1.0",
        "request_id": "test-req-001",
        "symbol": "XAUUSD",
        "timeframe": "M30",
        "source_candle_timestamp": now - timedelta(minutes=30),
        "requested_at": now,
        "feature_schema_version": FEATURE_SCHEMA_VERSION,
        "expected_model_version": None,
        "features": {name: 0.0 for name in FEATURE_NAMES},
    }


def test_strict_request_accepts_versioned_feature_contract():
    payload = request_payload()
    payload["features"]["mtf_alignment"] = 0.5
    request = AnalyzeRequest.model_validate(payload)
    assert request.request_id == "test-req-001"


@pytest.mark.parametrize("bad_value", [float("nan"), float("inf")])
def test_non_finite_feature_values_are_rejected(bad_value):
    payload = request_payload()
    payload["features"]["momentum"] = bad_value
    with pytest.raises(ValidationError):
        AnalyzeRequest.model_validate(payload)


def test_missing_or_extra_feature_keys_are_rejected():
    payload = request_payload()
    payload["features"].pop("momentum")
    with pytest.raises(ValidationError):
        AnalyzeRequest.model_validate(payload)
    payload = request_payload()
    payload["features"]["arbitrary_command"] = 1.0
    with pytest.raises(ValidationError):
        AnalyzeRequest.model_validate(payload)


def test_stale_request_is_rejected():
    payload = request_payload()
    payload["requested_at"] = datetime.now(timezone.utc) - timedelta(minutes=5)
    with pytest.raises(ValidationError):
        AnalyzeRequest.model_validate(payload)


def test_model_registry_without_model_fails_closed(monkeypatch, tmp_path):
    monkeypatch.setenv("AI_MOCK_MODE", "false")
    monkeypatch.setenv("MODEL_PATH", str(tmp_path / "missing.joblib"))
    registry = ModelRegistry()
    result = registry.predict({name: 0.0 for name in FEATURE_NAMES})
    assert not registry.ready
    assert result.prediction_class == "NO_TRADE"
    assert result.model_version == "unavailable"


def test_deterministic_mock_is_explicit_and_marked(monkeypatch):
    monkeypatch.setenv("AI_MOCK_MODE", "true")
    monkeypatch.delenv("MODEL_PATH", raising=False)
    registry = ModelRegistry()
    features = {name: 0.0 for name in FEATURE_NAMES}
    features["trend_direction"] = 1.0
    features["structure_break"] = 1.0
    features["mtf_alignment"] = 1.0
    result = registry.predict(features)
    assert registry.ready
    assert result.prediction_class == "BUY_SETUP"
    assert result.model_version == "mock-v1"
    assert any("Do not use" in warning for warning in result.warnings)
