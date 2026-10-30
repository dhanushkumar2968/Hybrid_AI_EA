# Dashboard and Chart Drawings

The EA presents one hybrid dashboard over the active chart and keeps the existing M30 analysis engine running in a separate embedded M30 chart pane. The active pane follows the attached chart timeframe. When that timeframe is M30, both panes are labeled as M30. The old M30 dashboard is suppressed; its analysis engine and controls remain available through the hybrid dashboard.

The dashboard opens in a compact view so it covers less chart area. **RESTORE** expands the analysis sections; **MIN** returns to compact view. The panel can be moved by dragging its header, resized from its corner grip or width controls, hidden and shown, and reset to its default position or size. Position, size, expanded sections, and marking preferences are persisted by account and EA magic number.

## Controls

- **BOT** changes the EA automation state. Orders remain gated by both `TRADING_PERMISSION` and `LIVE_EXECUTION`, as well as the existing signal, risk, terminal, and broker checks.
- **ANALYSIS** pauses or resumes analysis updates.
- **AI** enables or disables calls to the local Python service. The status text distinguishes disabled inference from an unavailable service or model and shows the response warning when one is available.
- **DRAWINGS** is the master visibility gate. It hides or shows the selected marking layers without overwriting each layer's saved preference.
- **STRUCT**, **ZONES**, and **ENTRY/SLTP** toggle the hybrid structure, zone, and entry/stop/target markings.
- **LEGACY** gates the existing H1/H4/D1 and M30 engine markings. Its selection is separate from the master `DRAWINGS` switch.
- **H1**, **H4**, **D1**, **ALL MARKS**, and **M30 MARKS** select timeframe-specific legacy markings. **ALL STRATEGIES** and each strategy button select the ten M30 strategies independently.
- Section headers expand or collapse Strategies, M30 Levels, Price Levels, Trade Plan, and Display & Dashboard Controls.
- **WIDTH -/+**, **RESET POSITION**, **RESET SIZE**, and **CLEAR RISK LOCK** perform their named dashboard or risk-state actions.

On a first install or schema upgrade, drawing layers default on when data is available. Later toggles are preserved. A selected layer shows **ARM** when its master visibility gate is off and **ON** when it is visible. **OFF** indicates that the individual layer itself is not selected.

The zone layer shows available M30 analysis zones and fair-value gaps. The plan layer displays the candidate entry zone, preferred entry, stop, and TP1-TP3 when the source analysis has a valid plan. A visible candidate plan can coexist with a `WAIT` signal and does not authorize an order. Position-protection markings are separate from analysis drawings.

The dashboard button handler resolves its object name before forwarding unhandled events to the legacy engines. Timer redraws do not clear a pressed button before its action is applied. Drag progress is carried through redraws so the panel does not snap back while moving or resizing.

See [architecture](architecture.md) for engine ownership and [risk management](risk-management.md) for execution gates.
