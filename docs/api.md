# Local AI API

The EA sends HTTP JSON to http://127.0.0.1:8765/v1/analyze. The Python service never submits orders or accepts commands. Start it from the python/ directory with python -m hybrid_ai; this binds Uvicorn to loopback only.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| GET | /health | Service/schema/model availability |
| GET | /model/info | Model and feature-schema version |
| POST | /v1/analyze | Validated M30 feature inference |
| POST | /v1/evaluate | Class-level evaluation of caller-supplied labels/predictions |
| GET | /metrics | In-memory request and error counters |

## Analyze request

Extra properties are rejected. All timestamps must include an offset. requested_at must be recent; the M30 candle may be at most four hours old. Feature names must match the schema exactly, values must be finite, and bounded values must remain within the defined ranges.

    {
      "schema_version": "1.0",
      "request_id": "1720000000-4",
      "symbol": "XAUUSD",
      "timeframe": "M30",
      "source_candle_timestamp": "2026-10-30T09:30:00Z",
      "requested_at": "2026-10-30T10:00:00Z",
      "feature_schema_version": "xauusd-features-v1",
      "expected_model_version": null,
      "features": {
        "trend_direction": 1.0,
        "mtf_alignment": 0.66666667,
        "structure_break": 0.0,
        "liquidity_sweep": 1.0,
        "sr_distance_atr": -0.4,
        "candle_body_atr": 0.2,
        "volatility_atr": 0.001,
        "momentum": 0.3,
        "spread_atr": 0.02,
        "session_code": 3.0
      }
    }

Example values are illustrative only, not market data.

## Response and errors

The response echoes request id, symbol, timeframe, and candle timestamp. It includes model/version/schema, BUY_SETUP, SELL_SETUP, or NO_TRADE, textual evidence/warnings, and elapsed inference time. scores_are_calibrated_probabilities is always false. No win probability is returned.

Validation errors use a structured body with error_code, message, retryable, and timestamp. Model and feature version mismatches return HTTP 409. Model unavailable/inference error returns a NO_TRADE response with warning; the EA rejects those responses.

Mock inference is enabled only by AI_MOCK_MODE=true or the EA's deterministic tester mock. Responses explicitly warn that they are not trained predictions.

## MT5 setup

Add http://127.0.0.1:8765 to MT5 Tools → Options → Expert Advisors → Allow WebRequest for listed URL. AI_ENABLED defaults false. The EA validates request id, schema, symbol, timeframe, candle timestamp, prediction class, and optional expected model version. Service offline, timeout, or mismatch leaves the signal unauthorized.
