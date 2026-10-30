# Architecture and Module Map

## Ownership

- **MQL5** owns broker market data, analysis, signal gating, trade-plan validation, risk limits, every broker request, position management, chart objects, and audit logging.
- **Python** validates a strict feature schema and returns a versioned setup class with evidence and warnings. It has no broker connection or order capability.
- **Training** prepares features and labels from user supplied OHLCV plus explicit broker cost assumptions. No dataset or trained model is bundled.

## MQL5 dependency map

```text
XAUUSD_Hybrid_AI_EA.mq5
├─ LegacyAnalysisAdapter.mqh
│  ├─ MTFTrendAnalysis.mqh  (existing H1/H4/D1 structure, zones and dashboard)
│  ├─ D1Analysis.mqh        (existing daily structure, bias, and zones)
│  └─ M30_Analysis.mqh      (existing ten M30 strategies, results, and analysis UI)
├─ XHMarketData ─ IndicatorManager
├─ XHMultiTimeframe         (MN1/W1/D1/H4/H1/M30/M15/M5 data and cached EMA context)
├─ XHStrategyScoring        (groups related M30 evidence before scoring)
├─ XHFeatureBuilder ─ XHAIClient
├─ XHSignalEngine
├─ XHTradePlanEngine        (validates exact M30 exported prices)
├─ XHRiskManager ─ XHStateManager
├─ XHExecutionEngine ─ CTrade / XHTradeLogger
├─ XHPositionManager ─ XHStateManager
├─ XHDashboard
└─ XHChartRenderer / XHTradeLogger
```

The three existing analysis headers were copied from the `E7DB6AF1FE93F292652A5D3B98342601` MT5 Data Folder into `MQL5/Experts/`. The installed originals were left untouched. The project copy of `MTFTrendAnalysis.mqh` exposes marking-visibility, M30 strategy, and runtime Bot-state methods to `LegacyAnalysisAdapter.mqh`. The legacy dashboard is suppressed while its embedded M30 chart and analysis engines continue to run. The unified `XHDashboard` resolves chart clicks before unhandled events are forwarded to the analysis engines.

The earlier project-local ten strategy classes were redundant with `M30_Analysis.mqh`; they were archived under `docs/backups/pre_legacy_integration/` and removed from the active include tree. Strategy names, points, weights, confirmation states, event times, zones, and explanations now come from the existing M30 snapshot. Premium/discount remains contextual and does not add an independent score vote. Related strategies are grouped to reduce double counting, and disabled strategies are omitted from the denominator.

## Timeframes and events

The EA reads MN1, W1, D1, H4, H1, M30, M15, and M5 directly. The existing structural engine supplies H1/H4/D1 contexts and M30 strategy evidence. `XHMultiTimeframe` supplies cached EMA context across the required timeframes; the structural engine's ready H1/H4/D1 directions and M30 setup direction take precedence when available. Timer events drive the existing engines and independent new bar checks. M30 analysis and AI requests run on M30 bar events or an explicit refresh. The visible chart timeframe does not replace the analysis timeframes.

Confirmed M30 strategy results use the existing engine's closed-bar calculations. The MTF engine also displays a live H1 wick sweep as a developing dashboard item; this wick-only field is not mapped into confirmed M30 strategy evidence. The signal engine requires D1/H4 agreement, grouped M30 evidence, M15/M5 direction alignment, acceptable spread, and matching AI class before marking a signal valid.

## Trade plan, risk, and execution

`XHTradePlanEngine` accepts only a matching, fresh confirmed signal and a valid plan exported by the M30 engine. It validates direction, price ordering, and source-candle time, then copies the exact entry zone, preferred entry, stop, and TP1/TP2/TP3. `XHRiskManager` recalculates monetary risk and lot size using the broker's `OrderCalcProfit`, volume limits, margin, commission and slippage allowances. Any invalid or missing source prices reject the plan.

Only `ExecutionEngine.mqh` calls `CTrade`. It rechecks both explicit order permissions, terminal/account permissions, broker symbol rules, current entry zone, stops, spread, margin, risk, and duplicate signal state. The default flags are `BOT_ENABLED=false`, `AI_ENABLED=false`, `TRADING_PERMISSION=false`, and `LIVE_EXECUTION=false`. A dashboard Bot toggle cannot enable either explicit execution permission.

## Python bridge and model

The local API binds to `127.0.0.1:8765`. MQL5 checks `/health` and `/model/info`, validates response schema/model/timestamp, uses a request timeout and request ID, and fails closed when the service is unavailable or incompatible. Mock AI is deterministic and clearly marked; it is not a trained model. Add `http://127.0.0.1:8765` to the MT5 WebRequest allowlist when using the bridge.

API schema: `1.0`. Feature schema: `xauusd-features-v1`. Inference timeframe: M30. Without a validated model, the Python service returns `NO_TRADE`.

## Validation limits

- The EA compiled with MetaEditor at 0 errors and 0 warnings.
- All 19 Python tests passed. The loopback service and /health, /model/info, and /v1/analyze were smoke-tested in mock mode; the MQL5 chart's actual WebRequest call was not tested.
- No XAUUSD history or tester history was found in the inspected terminal folders, so there is no gold Strategy Tester, backtest, or model performance result.
- No demo account action or live order was performed.
- No dashboard reference image was supplied; the dark native overlay is an original layout.
