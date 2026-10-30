# Historical Data and Model Training

No dataset or trained model is included. Use a broker export for the target XAUUSD symbol and M30 bars. python/tests uses deterministic synthetic fixtures for software checks only; never use those fixtures to train or report market performance.

## Input format

CSV columns:

    timestamp,open,high,low,close,volume,spread_price

timestamp is candle open time with timezone or UTC. spread_price is the full bid-ask price spread for that candle. Prices must be positive, OHLC ordering valid, timestamps unique after duplicate cleanup, and at least 100 bars must remain for feature preparation.

## Environment and preparation

Create a project virtual environment and install dependencies as described in the README. Then from python/:

    python -m training.prepare_data --input ..\data\raw\broker_xauusd_m30.csv --output ..\data\processed\xauusd_m30_labeled.csv --timeframe M30 --horizon-bars 5 --slippage-price-per-side 0.05 --commission-usd-per-lot-round-turn 7 --contract-size-oz-per-lot 100 --lots 1

If the CSV has no spread_price, add an explicit --fallback-spread-price. Defaults for slippage, commission, and contract size are examples, not verified broker values. Replace them with broker-specific values before interpreting labels. Label costs include spread, two-sided slippage, and round-turn commission converted to quoted price units.

## Training and evaluation

    python -m training.train_model --input ..\data\processed\xauusd_m30_labeled.csv --model-dir ..\models --horizon-bars 5 --folds 5

The pipeline checks data columns and finite features, orders rows chronologically, reserves the final 15% for out-of-sample evaluation, purges the forward-label horizon at split boundaries, compares logistic regression and random forest, performs expanding walk-forward folds, and compares the selected model with a transparent rule baseline and majority-class baseline. It saves model metadata, source-data SHA-256, and an evaluation report. Reported aggregate price changes are decision-row summaries, not a portfolio backtest.

Do not claim profitability from classification metrics. A portfolio backtest must account for order timing, spread, commissions, slippage, margin, broker contract rules, and overlapping positions. No metric is available until real broker data is processed.

## Load a trained artifact

Start the API with MODEL_PATH pointing to the .joblib file:

    Set-Location .\python
    $env:MODEL_PATH = "..\models\xauusd_setup_classifier.joblib"
    $env:AI_MOCK_MODE = "false"
    python -m hybrid_ai

The adjacent .metadata.json file is required and must match feature schema xauusd-features-v1. The EA's EXPECTED_MODEL_VERSION can be set to the version recorded in that metadata; otherwise the EA validates schema and request identity but accepts the service's current model version.
