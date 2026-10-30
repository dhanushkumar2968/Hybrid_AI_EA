# Development Log

## 2026-10-30 — Integration and verification

### Inspection

- The project workspace was initially empty.
- The broader environment scan found original user analysis code in MT5 profile `E7DB6AF1FE93F292652A5D3B98342601`: MTF structure/dashboard, D1 analysis, M30 analysis with ten strategies, and the original analysis-only EA. The originals remain unchanged in that terminal profile.
- MT5 and MetaEditor were found at `C:\Program Files\MetaTrader 5` and `C:\Program Files\JustMarkets MetaTrader 5`. MetaEditor is file version 5.0.0.6290.
- Git 2.56.0.windows.4 and VS Code 1.144.0 were found. Python, `py`, `pip`, and `uv` were unavailable; no package manager was found.
- No XAUUSD/GOLD history, MT5 tester history, user market dataset, trained model, or dashboard reference image was available.

### Implementation and integration

- Built the hybrid EA shell, Python API, training pipeline, tests, configs, and documentation in the workspace.
- Copied the original MTF, D1, and M30 analysis headers into `MQL5/Experts/` and integrated them through `LegacyAnalysisAdapter.mqh`.
- Removed duplicate generated strategy implementations from the active include tree after archiving them under `docs/backups/pre_legacy_integration/`. Scoring now maps the existing M30 snapshot and groups correlated strategies.
- Trade plans now consume the existing M30 engine's own entry, stop, and targets. Risk sizing remains in the hybrid risk manager; only `ExecutionEngine.mqh` can call `CTrade`.
- Connected the dashboard drawing toggle to the legacy marking controls and synchronized both BOT controls to one runtime state. Added a separate demo simulation config that keeps BOT, trade permission, and live execution off.
- Preserved all order-safety defaults. No real order was submitted.

### Verification

- Final MetaEditor compile: **0 errors, 0 warnings**; `.ex5` artifact generated.
- `tools/verify_project.ps1`: passed required file, local include, safe-default, CTrade isolation, and compile artifact/log checks.
- Python tests were authored but not run because no Python runtime/package installer was available.
- API startup, HTTP bridge, MT5 Strategy Tester, backtest, and demo-forward checks were not run.

### Remaining work after initial build

- Exercise the EA's HTTP request from a running MT5 chart after configuring the WebRequest allowlist.
- Supply broker-specific XAUUSD history and exact commission/slippage assumptions, then train and evaluate chronologically.
- Run the EA in the intended MT5 terminal and inspect the dashboard, chart markings, Strategy Tester behavior, and demo-forward behavior. Live deployment remains disabled and requires separate explicit authorization.

## 2026-10-30 — Python runtime and API verification follow-up

- Installed official Python 3.14.10 for the current user after verifying the installer SHA-256; installed the project requirements in .venv.
- Initial pytest run found three defects: JSON ISO timestamps were rejected by strict Pydantic datetime fields, and the mock warning did not match the explicit safety wording checked by its test. Corrected the two datetime fields to parse ISO strings while keeping the rest of the request model strict, and clarified the mock warning.
- Final test run: **19 passed, 1 upstream FastAPI/Starlette httpx2 deprecation warning**.
- Started the API in mock mode on 127.0.0.1:8765; /health, /model/info, and /v1/analyze passed. The sample analysis returned NO_TRADE and explicitly warned that mock output must not be used for trading.
- Reran tools/verify_project.ps1: all required-file, include, safety-default, CTrade isolation, and compiled artifact/log checks passed.
- No MT5 chart request, Strategy Tester, historical backtest, demo forward test, or order was run. There is no XAUUSD history or trained model.
