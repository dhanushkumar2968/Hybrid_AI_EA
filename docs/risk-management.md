# Risk Management

Risk checks are handled in MQL5 and use the broker's current symbol/account properties.

- Lot size is derived from equity risk budget and OrderCalcProfit for one lot at the exact planned entry and stop.
- Volume is rounded down to broker volume step. If the minimum lot exceeds the risk budget, the plan is rejected.
- The EA checks maximum open positions, daily loss, equity drawdown, total open monetary risk, daily entry count, consecutive losing deals, UTC session, spread, margin, symbol mode, and duplicate signal IDs.
- Existing positions without a stop trigger a persistent risk lock and block new entries. No unobserved stop is invented.
- Persistent state uses terminal Global Variables keyed by account login and EA magic number. Peak equity, risk lock, signal IDs, partial stages, and planned targets survive terminal restart.
- A risk lock reset button is visible on the dashboard. The next risk assessment reapplies active limits, so a still-breached daily-loss or drawdown limit re-locks entries.
- Martingale and volume escalation are not implemented.

Risk settings in the sample EA inputs are starting examples only. Validate XAUUSD tick size/value, contract size, commission, volume rules, stop levels, freeze levels, leverage, and account currency on the intended broker before demo use.

Daily losses are reconstructed from matching symbol/magic deals since server midnight. Consecutive-loss logic currently counts matching closing deal outcomes; partial exits can therefore be counted separately. This is conservative and should be reconciled against the intended account's deal semantics before deployment.
