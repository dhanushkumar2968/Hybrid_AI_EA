# Environment and Architecture Inspection

**Date:** 2026-10-30  
**Workspace:** `C:\Users\Dhanushkumar\Python_AI_MQL5_Automated_EA_XAUUSD`

## Findings

The workspace was initially empty, so no local EA or service could be mapped in Phase 0. The expanded environment inspection found the user's analysis code in the second MT5 terminal Data Folder:

`C:\Users\Dhanushkumar\AppData\Roaming\MetaQuotes\Terminal\E7DB6AF1FE93F292652A5D3B98342601\MQL5\Experts`

The relevant source was `MTFTrendAnalysis.mqh`, `D1Analysis.mqh`, and `M30_Analysis.mqh`, referenced by `AI_TRADING_SIGNAL.mq5`. They contain the existing H1/H4/D1 structural analysis and dashboards, daily analysis, and ten M30 strategies. The sources were copied into the project, the installed originals were left unchanged, and the hybrid EA now calls them through `MQL5/Experts/LegacyAnalysisAdapter.mqh`. The project-local generated ten-strategy duplicate was archived and removed from the active include tree.

## Active dependency map

```text
XAUUSD_Hybrid_AI_EA.mq5
├─ LegacyAnalysisAdapter.mqh → MTFTrendAnalysis.mqh / D1Analysis.mqh / M30_Analysis.mqh
├─ MarketData.mqh → IndicatorManager.mqh
├─ MultiTimeframe.mqh
├─ StrategyScoring.mqh
├─ FeatureBuilder.mqh → AIClient.mqh → local FastAPI
├─ SignalEngine.mqh → TradePlan.mqh → RiskManager.mqh
├─ ExecutionEngine.mqh → CTrade / TradeLogger.mqh
├─ PositionManager.mqh / StateManager.mqh
└─ Dashboard.mqh / ChartRenderer.mqh / TradeLogger.mqh
```

## Reuse and boundaries

- Existing MTF, D1, and M30 analysis source was reused; marking visibility and shared runtime Bot-state methods were added to the project copy of the MTF class for the hybrid dashboard.
- The M30 adapter exports strategy points, weights, state, event time, zone, and explanation. Grouped scoring prevents correlated outputs from inflating independent evidence.
- The trade-plan layer validates and forwards the exact legacy M30 entry, SL, and TP1/TP2/TP3 values.
- Python owns inference only. MQL5 is the sole owner of risk decisions and broker execution.
- The supplied reference dashboard image and broker-specific XAUUSD history were unavailable.

For installed tools, data availability, and test limitations see [docs/environment.md](docs/environment.md) and [docs/final-report.md](docs/final-report.md).
