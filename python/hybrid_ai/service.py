"""Local-only FastAPI service. It has no broker or order execution code."""

from __future__ import annotations

import os
import threading
import time
from collections import Counter
from datetime import datetime, timezone

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse

from . import __version__
from .model import ModelRegistry
from .schemas import (
    AnalyzeRequest,
    AnalyzeResponse,
    ErrorResponse,
    EvaluateRequest,
    EvaluateResponse,
    FEATURE_SCHEMA_VERSION,
    ModelInfoResponse,
    SCHEMA_VERSION,
)

_docs_url = None if os.getenv("APP_ENV", "").lower() == "production" else "/docs"
_openapi_url = None if os.getenv("APP_ENV", "").lower() == "production" else "/openapi.json"
app = FastAPI(
    title="XAUUSD Hybrid AI Local Service",
    version=__version__,
    docs_url=_docs_url,
    openapi_url=_openapi_url,
    redoc_url=None,
)
registry = ModelRegistry()
_metrics: Counter[str] = Counter()
_metrics_lock = threading.Lock()


def _count(name: str) -> None:
    with _metrics_lock:
        _metrics[name] += 1


def _error(status: int, code: str, message: str, request_id: str | None, retryable: bool) -> JSONResponse:
    body = ErrorResponse(
        schema_version=SCHEMA_VERSION,
        request_id=request_id,
        error_code=code,
        message=message,
        retryable=retryable,
        timestamp=datetime.now(timezone.utc),
    )
    return JSONResponse(status_code=status, content=body.model_dump(mode="json"))


@app.exception_handler(RequestValidationError)
async def validation_error_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    _count("validation_errors")
    return _error(422, "INVALID_REQUEST", "Request does not match the versioned API schema.", None, False)


@app.get("/health")
def health() -> dict[str, object]:
    return {
        "status": "ok",
        "service_version": __version__,
        "schema_version": SCHEMA_VERSION,
        "model_ready": registry.ready,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@app.get("/model/info", response_model=ModelInfoResponse)
def model_info() -> dict[str, object]:
    return {"schema_version": SCHEMA_VERSION, **registry.info()}


@app.post("/v1/analyze", response_model=AnalyzeResponse)
def analyze(payload: AnalyzeRequest):
    started = time.perf_counter()
    _count("analyze_requests")
    if payload.feature_schema_version != FEATURE_SCHEMA_VERSION:
        _count("rejected_requests")
        return _error(409, "FEATURE_SCHEMA_MISMATCH", "Unsupported feature schema version.", payload.request_id, False)

    if payload.expected_model_version and payload.expected_model_version != registry.model_version:
        _count("rejected_requests")
        return _error(409, "MODEL_VERSION_MISMATCH", "Loaded model does not match the requested version.", payload.request_id, False)

    result = registry.predict(payload.features)
    duration_ms = max(0.0, (time.perf_counter() - started) * 1000.0)
    _count("inference_warning" if result.warnings else "inference_success")
    return AnalyzeResponse(
        schema_version=SCHEMA_VERSION,
        request_id=payload.request_id,
        symbol=payload.symbol,
        timeframe=payload.timeframe,
        source_candle_timestamp=payload.source_candle_timestamp,
        model_name=result.model_name,
        model_version=result.model_version,
        feature_schema_version=FEATURE_SCHEMA_VERSION,
        prediction_class=result.prediction_class,
        prediction_evidence=result.evidence,
        warnings=result.warnings,
        inference_duration_ms=duration_ms,
    )


@app.post("/v1/evaluate", response_model=EvaluateResponse)
def evaluate(payload: EvaluateRequest) -> EvaluateResponse:
    _count("evaluate_requests")
    classes = ("BUY_SETUP", "SELL_SETUP", "NO_TRADE")
    totals = {name: {"support": 0, "correct": 0, "predicted": 0} for name in classes}
    correct_total = 0
    for item in payload.items:
        totals[item.actual_class]["support"] += 1
        totals[item.predicted_class]["predicted"] += 1
        if item.predicted_class == item.actual_class:
            correct_total += 1
            totals[item.actual_class]["correct"] += 1
    per_class: dict[str, dict[str, float | int]] = {}
    for name, values in totals.items():
        support = int(values["support"])
        predicted = int(values["predicted"])
        correct = int(values["correct"])
        per_class[name] = {
            "support": support,
            "precision": correct / predicted if predicted else 0.0,
            "recall": correct / support if support else 0.0,
        }
    return EvaluateResponse(
        schema_version=SCHEMA_VERSION,
        request_id=payload.request_id,
        sample_count=len(payload.items),
        accuracy=correct_total / len(payload.items),
        per_class=per_class,
    )


@app.get("/metrics")
def metrics() -> dict[str, object]:
    with _metrics_lock:
        snapshot = dict(_metrics)
    return {
        "service_version": __version__,
        "model_ready": registry.ready,
        "counts": snapshot,
    }

