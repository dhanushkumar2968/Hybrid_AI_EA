# Compilation and Test Status

## MQL5 compile

MetaEditor is installed at `C:\Program Files\MetaTrader 5\MetaEditor64.exe` (file version 5.0.0.6290). The final integration was compiled from the workspace main EA:

```powershell
& 'C:\Program Files\MetaTrader 5\MetaEditor64.exe' /compile:'<workspace>\MQL5\Experts\XAUUSD_Hybrid_AI_EA.mq5' /log:'<workspace>\mql5_compile.log'
```

The final compiler log reports **0 errors, 0 warnings** and produces `MQL5/Experts/XAUUSD_Hybrid_AI_EA.ex5`. MetaEditor may return a nonzero launcher exit code; the `Result:` line in the compiler log is the compilation result.

## Project smoke checks

Run from the workspace root:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tools\verify_project.ps1
```

The script passed checks for required files, quoted MQL5 include resolution, safe order defaults, `CTrade` isolation to `ExecutionEngine.mqh`, and the clean compile log plus artifact. These are source/build smoke checks, not behavioral unit or integration tests.

## Python tests

Tests in `python/tests/` cover strict schemas, stale requests, fail-closed inference, mock behavior, feature generation, cost-aware labels, API validation/evaluation/metrics, and training baselines. Python 3.14.10 and the declared dependencies were installed into the workspace virtual environment. Result:

```
19 passed, 1 warning
```

The warning is emitted by the installed FastAPI/Starlette test-client compatibility layer recommending httpx2; the tests completed successfully.

## Python API smoke run

The local service started successfully on 127.0.0.1:8765 with AI_MOCK_MODE=true. The /health, /model/info, and /v1/analyze endpoints all returned valid responses. The analyze smoke request returned NO_TRADE, model deterministic_mock / mock-v1, and an explicit warning not to use mock output for trading. This verifies the Python HTTP API contract; it does not verify an MQL5 WebRequest from a running chart.

## Not run

- MQL-to-Python HTTP bridge from a running MT5 chart.
- MQL behavioral tests for strategy, risk, position, or UI interactions.
- MT5 Strategy Tester, historical backtest, or model evaluation; no XAUUSD tester history or dataset was found.
- Demo forward testing.
- Live deployment. No order was placed.
