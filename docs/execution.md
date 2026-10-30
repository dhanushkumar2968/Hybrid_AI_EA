# Execution and Position Management

`ExecutionEngine.mqh` is the only active module that calls `CTrade`. Before sending an order it rechecks BOT state, both explicit execution flags, terminal/account/EA permissions, signal age, broker symbol mode, entry zone, stop and target direction, spread, duplicate signal state, monetary risk, margin, and broker volume rules.

The separate trade-plan engine accepts levels only from the existing M30 analysis snapshot. The legacy M30 plan chooses observed order block, FVG, or support/resistance zones and calculates its stop and three R-multiple targets from those prices. The hybrid layer validates the source candle and price ordering, then forwards those exact prices. Missing or invalid source levels reject the plan.

Accepted server retcodes are logged with descriptions and returned fill data. `OnTradeTransaction` records actual deal prices, volume, fees, commission, swap, profit, and server retcode. A true CTrade return is not treated as proof of a completed fill.

Partial close, break-even, trailing stop, maximum holding time, and emergency close for an unprotected EA position are configurable and disabled by default. Position management is processed from tick and timer events; changes still pass through `ExecutionEngine`. Stopping BOT disables new entries but does not remove broker-side SL/TP.

`BOT_ENABLED`, `AI_ENABLED`, `TRADING_PERMISSION`, and `LIVE_EXECUTION` start false. Analysis and chart drawings start on. On first install or drawing-settings migration, the individual hybrid, legacy, and timeframe marking layers default on; their preferences can then be changed independently. The dashboard master switch hides selected markings without changing those saved preferences. Dashboard controls do not override either explicit execution permission. No real order was placed during development.

No MT5 Strategy Tester or demo execution was performed. The inspected terminal profiles contained no XAUUSD tester history, and no demo authorization was used. Before demo testing, configure Python, a broker data set, and the MT5 WebRequest allowlist; instructions are in `compile-test.md` and `live-deployment-checklist.md`.
