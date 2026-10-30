"""Strict, versioned API contracts shared by the EA bridge and local service."""

from __future__ import annotations

from datetime import datetime, timezone
from math import isfinite
from typing import Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator

SCHEMA_VERSION = "1.0"
FEATURE_SCHEMA_VERSION = "xauusd-features-v1"
MODEL_NAME = "xauusd_setup_classifier"
PREDICTION_CLASSES = ("BUY_SETUP", "SELL_SETUP", "NO_TRADE")
TIMEFRAMES = ("M30",)
FEATURE_NAMES = (
    "trend_direction",
    "mtf_alignment",
    "structure_break",
    "liquidity_sweep",
    "sr_distance_atr",
    "candle_body_atr",
    "volatility_atr",
    "momentum",
    "spread_atr",
    "session_code",
)


class StrictModel(BaseModel):
    model_config = ConfigDict(extra="forbid", strict=True)


class AnalyzeRequest(StrictModel):
    schema_version: Literal["1.0"]
    request_id: str = Field(min_length=1, max_length=64, pattern=r"^[A-Za-z0-9._:-]+$")
    symbol: str = Field(min_length=3, max_length=32, pattern=r"^[A-Za-z0-9._-]+$")
    timeframe: Literal["M30"]
    # HTTP JSON represents timestamps as strings. Keep the rest of this model
    # strict while allowing Pydantic to parse these two ISO-8601 fields.
    source_candle_timestamp: datetime = Field(strict=False)
    requested_at: datetime = Field(strict=False)
    feature_schema_version: str = Field(min_length=1, max_length=64)
    expected_model_version: str | None = Field(default=None, max_length=64)
    features: dict[str, float]

    @field_validator("source_candle_timestamp", "requested_at")
    @classmethod
    def require_timezone(cls, value: datetime) -> datetime:
        if value.tzinfo is None or value.utcoffset() is None:
            raise ValueError("timestamps must include a timezone")
        return value.astimezone(timezone.utc)

    @field_validator("features")
    @classmethod
    def validate_features(cls, value: dict[str, float]) -> dict[str, float]:
        if set(value) != set(FEATURE_NAMES):
            missing = sorted(set(FEATURE_NAMES) - set(value))
            extra = sorted(set(value) - set(FEATURE_NAMES))
            raise ValueError(f"feature keys mismatch (missing={missing}, extra={extra})")
        if any(not isfinite(number) for number in value.values()):
            raise ValueError("feature values must be finite")
        bounded = {
            "trend_direction": (-1.0, 1.0),
            "mtf_alignment": (0.0, 1.0),
            "structure_break": (-1.0, 1.0),
            "liquidity_sweep": (-1.0, 1.0),
            "volatility_atr": (0.0, 1.0),
            "spread_atr": (0.0, 10.0),
            "session_code": (0.0, 3.0),
        }
        for name, (minimum, maximum) in bounded.items():
            if not minimum <= value[name] <= maximum:
                raise ValueError(f"{name} is outside [{minimum}, {maximum}]")
        return value

    @model_validator(mode="after")
    def validate_request_time(self) -> "AnalyzeRequest":
        now = datetime.now(timezone.utc)
        age = (now - self.requested_at).total_seconds()
        if age < -10:
            raise ValueError("requested_at is too far in the future")
        if age > 120:
            raise ValueError("analysis request is stale")
        candle_age = (now - self.source_candle_timestamp).total_seconds()
        if candle_age < -30:
            raise ValueError("source candle timestamp is too far in the future")
        if candle_age > 4 * 60 * 60:
            raise ValueError("source candle is stale for M30 analysis")
        return self


class AnalyzeResponse(StrictModel):
    schema_version: Literal["1.0"]
    request_id: str
    symbol: str
    timeframe: str
    source_candle_timestamp: datetime
    model_name: str
    model_version: str
    feature_schema_version: str
    prediction_class: Literal["BUY_SETUP", "SELL_SETUP", "NO_TRADE"]
    prediction_evidence: list[str]
    warnings: list[str]
    inference_duration_ms: float = Field(ge=0)
    scores_are_calibrated_probabilities: Literal[False] = False


class EvaluationItem(StrictModel):
    predicted_class: Literal["BUY_SETUP", "SELL_SETUP", "NO_TRADE"]
    actual_class: Literal["BUY_SETUP", "SELL_SETUP", "NO_TRADE"]


class EvaluateRequest(StrictModel):
    schema_version: Literal["1.0"]
    request_id: str = Field(min_length=1, max_length=64, pattern=r"^[A-Za-z0-9._:-]+$")
    items: list[EvaluationItem] = Field(min_length=1, max_length=10000)


class EvaluateResponse(StrictModel):
    schema_version: Literal["1.0"]
    request_id: str
    sample_count: int
    accuracy: float
    per_class: dict[str, dict[str, float | int]]


class ErrorResponse(StrictModel):
    schema_version: Literal["1.0"]
    request_id: str | None
    error_code: str
    message: str
    retryable: bool
    timestamp: datetime


class ModelInfoResponse(StrictModel):
    schema_version: Literal["1.0"]
    model_name: str
    model_version: str
    feature_schema_version: str
    model_ready: bool
    model_source: str
    notes: list[str]
