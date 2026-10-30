"""Create cost-aware labels from a broker-exported OHLCV CSV."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path

import numpy as np
import pandas as pd

from hybrid_ai.features import build_features, validate_bars
from hybrid_ai.schemas import FEATURE_NAMES


@dataclass(frozen=True)
class CostAssumptions:
    fallback_spread_price: float | None
    slippage_price_per_side: float
    commission_usd_per_lot_round_turn: float
    contract_size_oz_per_lot: float
    lots: float

    @property
    def commission_price(self) -> float:
        if self.contract_size_oz_per_lot <= 0 or self.lots <= 0:
            raise ValueError("contract size and lots must be positive")
        return self.commission_usd_per_lot_round_turn / (
            self.contract_size_oz_per_lot * self.lots
        )


def label_outcomes(
    bars: pd.DataFrame,
    features: pd.DataFrame,
    horizon_bars: int,
    costs: CostAssumptions,
) -> pd.DataFrame:
    if horizon_bars < 1:
        raise ValueError("horizon_bars must be positive")
    spread = (
        pd.to_numeric(bars["spread_price"], errors="coerce")
        if "spread_price" in bars
        else pd.Series(np.nan, index=bars.index)
    )
    if spread.isna().any():
        if costs.fallback_spread_price is None:
            raise ValueError("spread_price is missing; provide --fallback-spread-price explicitly")
        spread = spread.fillna(costs.fallback_spread_price)
    if (spread < 0).any():
        raise ValueError("spread_price cannot be negative")

    future_return = bars["close"].shift(-horizon_bars) - bars["close"]
    round_turn_cost = spread + (2.0 * costs.slippage_price_per_side) + costs.commission_price
    buy_net = future_return - round_turn_cost
    sell_net = -future_return - round_turn_cost
    labels = np.where(
        (buy_net > 0) & (buy_net >= sell_net),
        "BUY_SETUP",
        np.where((sell_net > 0) & (sell_net > buy_net), "SELL_SETUP", "NO_TRADE"),
    )
    result = features.copy()
    result["label"] = labels
    result["gross_forward_price_change"] = future_return
    result["round_turn_cost_price"] = round_turn_cost
    result = result.iloc[:-horizon_bars].copy()
    result = result.dropna(subset=list(FEATURE_NAMES) + ["gross_forward_price_change"])
    if result.empty:
        raise ValueError("not enough usable rows remain after feature and label generation")
    return result.reset_index(drop=True)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True, type=Path, help="Broker OHLCV CSV")
    parser.add_argument("--output", required=True, type=Path, help="Output labeled CSV")
    parser.add_argument("--timeframe", default="M30", choices=("M30",),
                        help="Model schema v1 is trained and served on M30 only.")
    parser.add_argument("--horizon-bars", type=int, default=5)
    parser.add_argument("--fallback-spread-price", type=float, default=None)
    parser.add_argument("--slippage-price-per-side", type=float, default=0.05)
    parser.add_argument("--commission-usd-per-lot-round-turn", type=float, default=7.0)
    parser.add_argument("--contract-size-oz-per-lot", type=float, default=100.0)
    parser.add_argument("--lots", type=float, default=1.0)
    args = parser.parse_args()

    bars = validate_bars(pd.read_csv(args.input))
    if "spread_price" not in bars:
        if args.fallback_spread_price is None:
            raise SystemExit("CSV needs spread_price or an explicit --fallback-spread-price.")
        bars["spread_price"] = args.fallback_spread_price
    else:
        bars["spread_price"] = pd.to_numeric(bars["spread_price"], errors="coerce")
        if bars["spread_price"].isna().any():
            if args.fallback_spread_price is None:
                raise SystemExit("CSV spread_price has missing values; supply --fallback-spread-price.")
            bars["spread_price"] = bars["spread_price"].fillna(args.fallback_spread_price)
    features = build_features(bars, args.timeframe)
    costs = CostAssumptions(
        fallback_spread_price=args.fallback_spread_price,
        slippage_price_per_side=args.slippage_price_per_side,
        commission_usd_per_lot_round_turn=args.commission_usd_per_lot_round_turn,
        contract_size_oz_per_lot=args.contract_size_oz_per_lot,
        lots=args.lots,
    )
    prepared = label_outcomes(bars, features, args.horizon_bars, costs)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    prepared.to_csv(args.output, index=False)
    print(f"Prepared {len(prepared)} rows from {args.input}; output={args.output}")
    print(
        "Assumptions: spread="
        f"{args.fallback_spread_price if args.fallback_spread_price is not None else 'CSV column'}, "
        f"slippage_per_side={args.slippage_price_per_side}, "
        f"commission_round_turn={args.commission_usd_per_lot_round_turn}, "
        f"contract_size_oz={args.contract_size_oz_per_lot}, lots={args.lots}"
    )


if __name__ == "__main__":
    main()
