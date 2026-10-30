from datetime import datetime, timedelta, timezone

import numpy as np
import pandas as pd
import pytest


@pytest.fixture
def synthetic_bars():
    """Deterministic synthetic fixture for software tests, never for model training."""
    count = 260
    timestamps = pd.date_range("2024-01-01", periods=count, freq="30min", tz="UTC")
    drift = np.linspace(0.0, 12.0, count)
    wave = np.sin(np.arange(count) / 7.0) * 1.8
    close = 2000.0 + drift + wave
    open_price = np.concatenate(([close[0] - 0.2], close[:-1]))
    high = np.maximum(open_price, close) + 0.4
    low = np.minimum(open_price, close) - 0.4
    return pd.DataFrame(
        {
            "timestamp": timestamps,
            "open": open_price,
            "high": high,
            "low": low,
            "close": close,
            "volume": np.full(count, 100.0),
            "spread_price": np.full(count, 0.25),
        }
    )
