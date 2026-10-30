from datetime import datetime, timedelta, timezone

from fastapi.testclient import TestClient

from hybrid_ai.schemas import FEATURE_NAMES, FEATURE_SCHEMA_VERSION
from hybrid_ai.service import app

client = TestClient(app)


def valid_payload():
    now = datetime.now(timezone.utc)
    return {
        "schema_version": "1.0",
        "request_id": "service-test-1",
        "symbol": "XAUUSD",
        "timeframe": "M30",
        "source_candle_timestamp": (now - timedelta(minutes=30)).isoformat(),
        "requested_at": now.isoformat(),
        "feature_schema_version": FEATURE_SCHEMA_VERSION,
        "expected_model_version": None,
        "features": {name: 0.0 for name in FEATURE_NAMES},
    }


def test_health_and_model_info_contracts():
    health = client.get("/health")
    info = client.get("/model/info")
    assert health.status_code == 200
    assert health.json()["schema_version"] == "1.0"
    assert info.status_code == 200
    assert info.json()["feature_schema_version"] == FEATURE_SCHEMA_VERSION


def test_analyze_echoes_request_identity_and_never_returns_win_probability():
    response = client.post("/v1/analyze", json=valid_payload())
    assert response.status_code == 200
    result = response.json()
    assert result["request_id"] == "service-test-1"
    assert result["prediction_class"] in {"BUY_SETUP", "SELL_SETUP", "NO_TRADE"}
    assert result["scores_are_calibrated_probabilities"] is False
    assert "broker" not in str(result).lower() or result["prediction_class"] == "NO_TRADE"


def test_invalid_schema_has_structured_error():
    payload = valid_payload()
    payload["features"]["extra"] = 1.0
    response = client.post("/v1/analyze", json=payload)
    assert response.status_code == 422
    result = response.json()
    assert result["error_code"] == "INVALID_REQUEST"
    assert result["retryable"] is False


def test_unknown_feature_version_is_rejected_with_conflict():
    payload = valid_payload()
    payload["feature_schema_version"] = "future-schema"
    response = client.post("/v1/analyze", json=payload)
    assert response.status_code == 409
    assert response.json()["error_code"] == "FEATURE_SCHEMA_MISMATCH"


def test_stale_source_candle_is_rejected():
    payload = valid_payload()
    payload["source_candle_timestamp"] = (
        datetime.now(timezone.utc) - timedelta(hours=8)
    ).isoformat()
    response = client.post("/v1/analyze", json=payload)
    assert response.status_code == 422
    assert response.json()["error_code"] == "INVALID_REQUEST"


def test_evaluate_endpoint_reports_class_metrics():
    response = client.post(
        "/v1/evaluate",
        json={
            "schema_version": "1.0",
            "request_id": "eval-1",
            "items": [
                {"predicted_class": "BUY_SETUP", "actual_class": "BUY_SETUP"},
                {"predicted_class": "NO_TRADE", "actual_class": "SELL_SETUP"},
            ],
        },
    )
    assert response.status_code == 200
    result = response.json()
    assert result["sample_count"] == 2
    assert result["accuracy"] == 0.5
    assert result["per_class"]["SELL_SETUP"]["recall"] == 0.0


def test_metrics_endpoint_is_json():
    response = client.get("/metrics")
    assert response.status_code == 200
    assert "counts" in response.json()
