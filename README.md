# XAUUSD Hybrid AI EA

An MT5 Expert Advisor for XAUUSD analysis with an optional local Python inference service. The MQL5 EA owns market data, analysis, signals, risk checks, chart drawings, position management, and any broker requests. Python validates features and returns a setup classification; it has no broker connection or order execution capability.

The project is organized as a complete source bundle: MQL5 EA and include modules, installable Python packages, example configuration, training utilities, tests, and technical documentation. No broker history or trained model is included.

## Safety defaults

The EA inputs default to analysis without live execution:

| Input | Default | Purpose |
|---|---:|---|
| `BOT_ENABLED` | `false` | EA automation state |
| `ANALYSIS_ENABLED` | `true` | Run market analysis |
| `AI_ENABLED` | `false` | Call the local inference service |
| `DRAWINGS_ENABLED` | `true` | Show chart analysis markings |
| `TRADING_PERMISSION` | `false` | Explicit order permission gate |
| `LIVE_EXECUTION` | `false` | Explicit live execution gate |

Turning BOT on does not enable orders. Both `TRADING_PERMISSION` and `LIVE_EXECUTION` must also be enabled, and the EA still applies its existing signal, risk, and broker checks. The Python service cannot place orders. Mock mode is only for interface testing and must never be treated as a real model result.

## Repository contents

```text
MQL5/
  Experts/                     EA entry point and H1/H4/D1/M30 analysis engines
  Include/XAUUSDHybrid/         Market, signal, risk, execution, dashboard, API modules
python/
  hybrid_ai/                    FastAPI service, schema, feature and model modules
  training/                     CSV preparation and walk-forward model training
  tests/                         Python unit and API contract tests
config/                          Example EA and training settings
docs/                            Architecture, API, training, dashboard and safety notes
data/raw/                        Empty placeholder; add broker exports locally
data/processed/                  Empty placeholder; generated datasets stay local
models/                          Empty placeholder; generated models stay local
logs/                            Empty placeholder; runtime logs stay local
tools/                           Project source/build checks
```

### MQL5 modules

- `MQL5/Experts/XAUUSD_Hybrid_AI_EA.mq5` is the EA entry point and event coordinator.
- `LegacyAnalysisAdapter.mqh` connects the existing structural engines to the single dashboard and hybrid signal flow.
- `MTFTrendAnalysis.mqh`, `D1Analysis.mqh`, and `M30_Analysis.mqh` contain the existing higher-timeframe and M30 analysis engines.
- `MQL5/Include/XAUUSDHybrid/` contains `CoreTypes`, `StateManager`, `MarketData`, `IndicatorManager`, `MultiTimeframe`, `FeatureBuilder`, `AIClient`, `StrategyScoring`, `SignalEngine`, `TradePlan`, `RiskManager`, `ExecutionEngine`, `PositionManager`, `TradeLogger`, `Dashboard`, and `ChartRenderer`.
- The dashboard keeps the active chart and embedded M30 chart as separate panes. Its controls expose the analysis and marking layers without creating a second M30 dashboard.

### Python packages

- `hybrid_ai` provides the local API, versioned request/response schemas, feature validation, and fail-closed model loading.
- `training` prepares broker CSV data and trains/evaluates classifiers using chronological splits and walk-forward validation.
- The package can be installed from the project root with `pip install -e ".[dev]"`.
- Installation also provides the `xauusd-ai`, `xauusd-prepare-data`, and `xauusd-train-model` commands.

## Requirements

- Windows and MetaTrader 5/MetaEditor to compile and run the EA.
- Python 3.10 or newer for the service and training package. Python 3.14.10 was used for the recorded project verification.
- Python dependencies are declared in `pyproject.toml` and mirrored in `requirements.txt`; test and packaging tools are in the `dev` extra and `requirements-dev.txt`.
- MT5's standard `Trade` library is supplied by the terminal; the EA source uses it through `ExecutionEngine.mqh`.

## Set up the Python service

From the project root in PowerShell:

```powershell
py -3.14 -m venv .venv
.\.venv\Scripts\python.exe -m pip install --upgrade pip
.\.venv\Scripts\python.exe -m pip install -e ".[dev]"
```

The service binds to loopback at `127.0.0.1:8765`:

```powershell
.\.venv\Scripts\python.exe -m hybrid_ai
```

With no validated model configured, `/health` reports the model as unavailable and inference returns `NO_TRADE`. For interface testing only, start a separate process with mock mode enabled:

```powershell
$env:AI_MOCK_MODE = "true"
.\.venv\Scripts\python.exe -m hybrid_ai
```

Mock predictions are deterministic placeholders, not trained outputs. To load a trained model, set `MODEL_PATH` to its `.joblib` file and keep the matching `.metadata.json` beside it. The service validates the metadata and feature schema before loading.

See [the API guide](docs/api.md) for endpoints and payloads.

## Prepare data and train a model

No market data or model is included. Use a broker export containing M30 `timestamp`, OHLC, `volume`, and `spread_price` fields. Set realistic spread, slippage, commission, contract-size, and lot assumptions for the broker before interpreting any output.

From the project root, after installing the package:

```powershell
.\.venv\Scripts\python.exe -m training.prepare_data `
  --input .\data\raw\broker_xauusd_m30.csv `
  --output .\data\processed\xauusd_m30_labeled.csv `
  --timeframe M30 --horizon-bars 5 `
  --slippage-price-per-side 0.05 `
  --commission-usd-per-lot-round-turn 7 `
  --contract-size-oz-per-lot 100 --lots 1

.\.venv\Scripts\python.exe -m training.train_model `
  --input .\data\processed\xauusd_m30_labeled.csv `
  --model-dir .\models --horizon-bars 5 --folds 5
```

The numeric costs above are illustrative only. Replace them with broker-specific values. Training writes the model, adjacent metadata, and an evaluation report under `models/`; these generated artifacts are intentionally excluded from Git. Classification results are not a profitability claim or a portfolio backtest. See [the training guide](docs/training.md).

## Install and compile the EA

1. In MT5, choose **File > Open Data Folder**.
2. Copy this project's `MQL5/Experts/` and `MQL5/Include/` contents into the matching folders in the terminal's data directory, preserving the folder structure.
3. Open `MQL5/Experts/XAUUSD_Hybrid_AI_EA.mq5` in MetaEditor and compile it. The generated `.ex5` should be beside the EA source.
4. Attach the EA to the desired XAUUSD chart. The main view follows the chart timeframe; the embedded analysis pane remains M30.
5. To enable the Python bridge, add `http://127.0.0.1:8765` under **Tools > Options > Expert Advisors > Allow WebRequest for listed URL** and start the service locally.

The repository includes the latest compiled `.ex5` as a convenience. The `.mq5` and `.mqh` files are the authoritative, editable source.

See [compile and verification notes](docs/compile-test.md), [dashboard controls](docs/dashboard.md), and [risk controls](docs/risk-management.md).

## Verification status

- MetaEditor compiled the current EA source with **0 errors and 0 warnings** on 2026-10-30, including a compile from the active JustMarkets data folder.
- The recorded Python validation is **19 passing tests**; see [compile and test notes](docs/compile-test.md) for its scope.
- No XAUUSD history or tester dataset was supplied. No trained model, broker-specific backtest, profitability result, or live trading result is included.
- The updated chart layout was not visually verified in MT5 in this session because native MT5 UI control was unavailable.

## Configuration and data hygiene

Copy `.env.example` to `.env` only for local configuration. Never commit `.env`, credentials, broker exports, generated models, or runtime logs. Example configuration in `config/` keeps the two explicit order permissions disabled.
