# Live Deployment Safety Checklist

Live deployment is not authorized by this development build. Keep all live flags false until validation is complete and explicit authorization is received.

- [ ] Install a supported Python runtime and run all unit tests.
- [ ] Start the API on loopback, verify health/model/schema, and test offline, stale, malformed, and model-mismatch responses.
- [ ] Review actual M30 broker data, data quality, spread history, commissions, slippage, contract size, and cost assumptions.
- [ ] Train chronologically; review walk-forward and untouched out-of-sample report; compare rule and majority baselines.
- [ ] Compile the final EA with 0 errors and warnings in the target terminal.
- [ ] Run Strategy Tester with deterministic mock AI and order flags disabled; inspect chart events, signal reasons, and logs.
- [ ] Test invalid plans, risk locks, duplicate signals, partial closes, SL/TP persistence, restart/reconnect, and broker restrictions on a demo account.
- [ ] Demo-forward test across normal, high-spread, rollover, and session boundary conditions.
- [ ] Confirm the intended symbol suffix, account mode, volume step, stops/freeze levels, margin, and maximum risk.
- [ ] Review the exact EA inputs and verify BOT_ENABLED, TRADING_PERMISSION, and LIVE_EXECUTION values.
- [ ] Obtain explicit authorization for live deployment as a separate step.

Never use a dashboard START control as live-trading authorization.
