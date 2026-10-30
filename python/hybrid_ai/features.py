"""Leakage-aware OHLC feature engineering matching xauusd-features-v1."""

from __future__ import annotations

import numpy as np
import pandas as pd

from .schemas import FEATURE_NAMES

TIMEFRAME_MINUTES = {"M5": 5, "M15": 15, "M30": 30, "H1": 60, "H4": 240, "D1": 1440}
REQUIRED_COLUMNS = ("timestamp", "open", "high", "low", "close", "volume")


def validate_bars(frame: pd.DataFrame) -> pd.DataFrame:
    missing = sorted(set(REQUIRED_COLUMNS) - set(frame.columns))
    if missing:
        raise ValueError(f"missing historical columns: {', '.join(missing)}")
    clean = frame.copy()
    clean["timestamp"] = pd.to_datetime(clean["timestamp"], utc=True, errors="coerce")
    if clean["timestamp"].isna().any():
        raise ValueError("timestamp contains invalid values")
    for column in ("open", "high", "low", "close", "volume"):
        clean[column] = pd.to_numeric(clean[column], errors="coerce")
    if clean[list(REQUIRED_COLUMNS[1:])].isna().any().any():
        raise ValueError("OHLCV data contains missing or non-numeric values")
    if (clean[["open", "high", "low", "close"]] <= 0).any().any():
        raise ValueError("OHLC prices must be positive")
    if (clean["volume"] < 0).any():
        raise ValueError("volume cannot be negative")
    if (clean["high"] < clean[["open", "low", "close"]].max(axis=1)).any():
        raise ValueError("high is below another OHLC value")
    if (clean["low"] > clean[["open", "high", "close"]].min(axis=1)).any():
        raise ValueError("low is above another OHLC value")
    clean = clean.sort_values("timestamp").drop_duplicates("timestamp", keep="last")
    if len(clean) < 100:
        raise ValueError("at least 100 chronologically ordered bars are required")
    return clean.reset_index(drop=True)


def _trend(close: pd.Series) -> pd.Series:
    fast = close.ewm(span=20, adjust=False, min_periods=20).mean()
    slow = close.ewm(span=50, adjust=False, min_periods=50).mean()
    return pd.Series(np.sign(fast - slow), index=close.index, dtype="float64")


def _higher_timeframe_trend(bars: pd.DataFrame, rule: str) -> pd.DataFrame:
    indexed = bars.set_index("timestamp")
    higher = indexed.resample(rule, label="right", closed="left").agg(
        open=("open", "first"),
        high=("high", "max"),
        low=("low", "min"),
        close=("close", "last"),
        volume=("volume", "sum"),
    )
    higher = higher.dropna(subset=["close"]).reset_index()
    higher["direction"] = _trend(higher["close"])
    return higher[["timestamp", "direction"]].rename(columns={"direction": f"{rule}_trend"})


def build_features(bars: pd.DataFrame, timeframe: str = "M30") -> pd.DataFrame:
    """Build closed-bar features; higher-timeframe values use only completed bars."""
    if timeframe not in TIMEFRAME_MINUTES:
        raise ValueError(f"unsupported timeframe: {timeframe}")
    frame = validate_bars(bars)
    previous_close = frame["close"].shift(1)
    true_range = pd.concat(
        [
            frame["high"] - frame["low"],
            (frame["high"] - previous_close).abs(),
            (frame["low"] - previous_close).abs(),
        ],
        axis=1,
    ).max(axis=1)
    atr = true_range.rolling(14, min_periods=14).mean()
    trend_votes: list[pd.Series] = []
    evaluation_time = frame["timestamp"] + pd.to_timedelta(TIMEFRAME_MINUTES[timeframe], unit="m")
    base_trend = _trend(frame["close"])
    merged = pd.DataFrame({"timestamp": evaluation_time, "base_trend": base_trend})
    for rule in ("1h", "4h", "1D"):
        higher = _higher_timeframe_trend(frame, rule)
        merged = pd.merge_asof(
            merged.sort_values("timestamp"),
            higher.sort_values("timestamp"),
            on="timestamp",
            direction="backward",
        )
        trend_votes.append(merged[f"{rule}_trend"])

    votes = pd.concat(trend_votes, axis=1)
    vote_sum = votes.sum(axis=1, min_count=3)
    trend_direction = np.sign(vote_sum).where(vote_sum.notna(), 0.0)
    alignment = votes.eq(trend_direction, axis=0).sum(axis=1) / 3.0
    alignment = alignment.where(vote_sum.notna(), 0.0)

    range_high_20 = frame["high"].shift(1).rolling(20, min_periods=20).max()
    range_low_20 = frame["low"].shift(1).rolling(20, min_periods=20).min()
    range_high_10 = frame["high"].shift(1).rolling(10, min_periods=10).max()
    range_low_10 = frame["low"].shift(1).rolling(10, min_periods=10).min()
    structure_break = pd.Series(0.0, index=frame.index)
    structure_break = structure_break.mask(frame["close"] > range_high_20, 1.0)
    structure_break = structure_break.mask(frame["close"] < range_low_20, -1.0)
    liquidity_sweep = pd.Series(0.0, index=frame.index)
    liquidity_sweep = liquidity_sweep.mask(
        (frame["low"] < range_low_10) & (frame["close"] > range_low_10), 1.0
    )
    liquidity_sweep = liquidity_sweep.mask(
        (frame["high"] > range_high_10) & (frame["close"] < range_high_10), -1.0
    )
    atr_safe = atr.replace(0.0, np.nan)
    range_mid = (range_high_20 + range_low_20) / 2.0

    spread = (
        pd.to_numeric(frame["spread_price"], errors="coerce")
        if "spread_price" in frame
        else pd.Series(np.nan, index=frame.index)
    )
    features = pd.DataFrame(
        {
            "timestamp": frame["timestamp"],
            "trend_direction": trend_direction.to_numpy(),
            "mtf_alignment": alignment.to_numpy(),
            "structure_break": structure_break,
            "liquidity_sweep": liquidity_sweep,
            "sr_distance_atr": (frame["close"] - range_mid) / atr_safe,
            "candle_body_atr": (frame["close"] - frame["open"]) / atr_safe,
            "volatility_atr": atr_safe / frame["close"],
            "momentum": (frame["close"] - frame["close"].shift(5)) / atr_safe,
            "spread_atr": spread / atr_safe,
        }
    )
    hour = frame["timestamp"].dt.hour
    features["session_code"] = np.select(
        [hour.between(13, 16), hour.between(7, 12), hour.between(13, 20)],
        [3.0, 1.0, 2.0],
        default=0.0,
    )
    for name in FEATURE_NAMES:
        if name not in features:
            raise RuntimeError(f"feature definition missing: {name}")
    return features
