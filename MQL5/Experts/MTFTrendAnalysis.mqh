#ifndef AI_TRADING_SIGNAL_MTF_TREND_ANALYSIS_MQH
#define AI_TRADING_SIGNAL_MTF_TREND_ANALYSIS_MQH

enum ENUM_MTF_DASHBOARD_POSITION
  {
   MTF_PANEL_TOP_LEFT = 0,
   MTF_PANEL_TOP_RIGHT = 1,
   MTF_PANEL_BOTTOM_LEFT = 2,
   MTF_PANEL_BOTTOM_RIGHT = 3,
   MTF_PANEL_CUSTOM = 4
  };

// Structure sensitivity and per-timeframe history.
input int    MTFInpH1SwingLeftBars            = 2;
input int    MTFInpH1SwingRightBars           = 2;
input int    MTFInpH4SwingLeftBars            = 2;
input int    MTFInpH4SwingRightBars           = 2;
input int    MTFInpD1SwingLeftBars            = 2;
input int    MTFInpD1SwingRightBars           = 2;
input int    MTFInpD1LookbackBars            = 360;
input int    MTFInpH4LookbackBars            = 600;
input int    MTFInpH1LookbackBars            = 800;
input int    MTFInpATRPeriod                 = 14;
input double MTFInpMinimumSwingDistancePoints = 0.0;
input double MTFInpMinimumSwingDistanceATR    = 0.10;
input double MTFInpEqualSwingTolerancePoints  = 0.0;
input double MTFInpEqualSwingToleranceATR     = 0.02;

// Closed-candle break confirmation.
input double MTFInpBreakBufferPoints         = 0.0;
input double MTFInpBreakBufferATR            = 0.02;
input double MTFInpMinimumBreakBodyATR       = 0.0;
input double MTFInpMSSBodyATR                = 0.80;

// Structural support and resistance.
input double MTFInpLevelTolerancePoints      = 0.0;
input double MTFInpLevelToleranceATR         = 0.15;
input double MTFInpLevelInvalidationATR      = 0.50;
input int    MTFInpMinimumLevelTests         = 2;
input double MTFInpLiquidityTolerancePoints  = 0.0;
input double MTFInpLiquidityToleranceATR     = 0.02;
input int    MTFInpZoneReactionBars          = 12;
input int    MTFInpZoneLookbackBars          = 180;
input double MTFInpZoneMinMoveAwayATR        = 0.75;
input double MTFInpZoneHalfWidthATR          = 0.25;
input double MTFInpZoneInvalidationATR       = 0.50;

// Drawing and refresh controls.
input bool   MTFInpExtendTrendlines          = true;
input bool   MTFInpShowHistoricalEvents      = false;
input int    MTFInpHistoricalBars            = 120;
input bool   MTFInpShowSwingLabels           = true;
input bool   MTFInpShowZones                 = true;
input bool   MTFInpShowBreakLevels           = true;
input bool   MTFInpShowTrendlines            = true;
input bool   MTFInpShowLiquidityLevels       = true;
input bool   MTFInpShowDashboard             = false;
input bool   MTFInpShowLabels                = true;
input bool   MTFInpShowH1Markings            = true;
input bool   MTFInpShowH4Markings            = true;
input bool   MTFInpShowD1Markings            = true;
input bool   MTFInpDiagnosticLogging         = false;
input int    MTFInpRefreshSeconds            = 1;
input int    MTFInpLineWidth                 = 1;
input int    MTFInpDashboardWidth            = 650;
input int    MTFInpDashboardHeight           = 330;
input int    MTFInpDashboardMinWidth         = 360;
input int    MTFInpDashboardMinHeight        = 250;
input int    MTFInpDashboardWidthPercent     = 42;
input int    MTFInpChartMinimumWidth          = 280;
input int    MTFInpDashboardFontSize         = 9;
input ENUM_MTF_DASHBOARD_POSITION MTFInpDashboardPosition = MTF_PANEL_TOP_LEFT;
input bool   MTFInpRememberDashboard        = true;
input ENUM_LINE_STYLE MTFInpTrendLineStyle   = STYLE_DOT;
input ENUM_LINE_STYLE MTFInpBreakLineStyle   = STYLE_DOT;
input color  MTFInpH1Color                   = clrBlue;
input color  MTFInpH4Color                   = clrDarkOrange;
input color  MTFInpD1Color                   = clrDarkViolet;

enum ENUM_MTF_EVENT
  {
   MTF_EVENT_NONE  = 0,
   MTF_EVENT_BOS   = 1,
   MTF_EVENT_CHOCH = 2,
   MTF_EVENT_MSS   = 3
  };

struct MTFSwingPoint
  {
   bool            valid;
   ENUM_TIMEFRAMES timeframe;
   bool            is_high;
   datetime        time;
   int             shift;
   double          price;
   string          code;
  };

struct MTFStructureEvent
  {
   bool            valid;
   ENUM_TIMEFRAMES timeframe;
   int             direction;
   ENUM_MTF_EVENT  event_type;
   bool            reversal_warning;
   datetime        break_time;
   datetime        swing_time;
   double          break_level;
   double          break_close;
   double          atr;
  };

struct MTFLevel
  {
   bool     valid;
   double   price;
   double   low;
   double   high;
   datetime time;
   int      tests;
   bool     broken;
   bool     invalidated;
  };

struct MTFReactionZone
  {
   bool     valid;
   bool     demand;
   double   low;
   double   high;
   double   midpoint;
   datetime created;
   int      tests;
   bool     invalidated;
  };

struct MTFTrendState
  {
   ENUM_TIMEFRAMES timeframe;
   string          tag;
   int             lookback;
   bool            data_ready;
   datetime        current_bar;
   int             direction;
   int             break_bias;
   bool            high_broken;
   bool            low_broken;
   string          structure;
   MTFSwingPoint   previous_high;
   MTFSwingPoint   latest_high;
   MTFSwingPoint   previous_low;
   MTFSwingPoint   latest_low;
   MTFStructureEvent latest_event;
   MTFStructureEvent latest_reversal_event;
   MTFLevel        support;
   MTFLevel        resistance;
   MTFLevel        equal_highs;
   MTFLevel        equal_lows;
   MTFReactionZone demand;
   MTFReactionZone supply;
   bool            trendline_valid;
   bool            trendline_broken;
   datetime        trendline_break_time;
   double          trendline_break_price;
   int             trendline_break_direction;
   bool            sweep_valid;
   int             sweep_direction;
   datetime        sweep_time;
   double          sweep_level;
   bool            wick_sweep;
   int             wick_sweep_direction;
   double          wick_sweep_level;
   double          atr;
  };

// Read-only state exported to downstream analysis modules.
struct MTFContextSnapshot
  {
   bool              ready;
   ENUM_TIMEFRAMES   timeframe;
   int               direction;
   string            structure;
   MTFSwingPoint     latest_high;
   MTFSwingPoint     latest_low;
   MTFStructureEvent latest_event;
   MTFStructureEvent latest_reversal_event;
   MTFLevel          support;
   MTFLevel          resistance;
   MTFLevel          equal_highs;
   MTFLevel          equal_lows;
   MTFReactionZone   demand;
   MTFReactionZone   supply;
   bool              sweep_valid;
   int               sweep_direction;
   datetime          sweep_time;
   double            sweep_level;
   double            atr;
  };

class CMTFTrendAnalysis
  {
private:
   MTFTrendState m_states[3];
   int           m_atr_handles[3];
   string        m_prefix;
   bool          m_ready;
   bool          m_handles_ready;
   datetime      m_last_chart_bar;
   ulong         m_last_dashboard_update;
   int           m_panel_x;
   int           m_panel_y;
   int           m_panel_width;
   int           m_panel_height;
   bool          m_panel_manual_size;
   ENUM_MTF_DASHBOARD_POSITION m_panel_position;
   string        m_settings_key;
   int           m_last_mouse_x;
   int           m_last_mouse_y;
   int           m_panel_drag_mode;
   bool          m_panel_drag_active;
   bool          m_show_markings[3];
   bool          m_master_drawings_enabled;
   bool          m_dashboard_visible;
   bool          m_dashboard_expanded;
   bool          m_dashboard_suppressed;
   bool          m_show_changed;
   string        m_m30_dashboard_summary;
   string        m_m30_dashboard_reason;
   string        m_m30_dashboard_lines[10];
   int           m_m30_dashboard_line_count;
   string        m_m30_level_lines[5];
   string        m_m30_plan_lines[7];
   string        m_split_chart_name;
   long          m_analysis_chart_id;
   bool          m_bot_enabled;
   bool          m_m30_analysis_enabled;
   bool          m_m30_drawings_enabled;
   bool          m_m30_strategy_enabled[10];
   bool          m_m30_saved_strategy_enabled[10];
   bool          m_m30_settings_loaded;
   bool          m_m30_all_suspended;
   bool          m_dashboard_minimized;
   int           m_m30_control_revision;

   string PanelBackgroundName() { return m_prefix + "PANEL_BG"; }
   string SplitChartName() { return m_prefix + "PANEL_SPLIT_CHART"; }
   string PanelHeaderName() { return m_prefix + "PANEL_HEADER"; }
   string PanelResizeName() { return m_prefix + "PANEL_RESIZE"; }
   string PanelShowName() { return m_prefix + "PANEL_SHOW"; }
   string PanelCompactName() { return m_prefix + "PANEL_COMPACT"; }
   string PanelMarkName(const int index)
     {
      return m_prefix + "PANEL_MARK_" + IntegerToString(index);
     }
   string PanelAllMarkName() { return m_prefix + "PANEL_MARK_ALL"; }
   string PanelBotName() { return m_prefix + "PANEL_BOT"; }
   string PanelMinimizeName() { return m_prefix + "PANEL_MINIMIZE"; }
   string PanelM30AnalysisName() { return m_prefix + "PANEL_M30_ANALYSIS"; }
   string PanelM30DrawingsName() { return m_prefix + "PANEL_M30_DRAWINGS"; }
   string PanelM30AllStrategiesName() { return m_prefix + "PANEL_M30_ALL_STRATEGIES"; }
   string PanelM30StrategyName(const int index)
     { return m_prefix + "PANEL_M30_STRATEGY_" + IntegerToString(index); }
   string PanelM30ResetPositionName() { return m_prefix + "PANEL_M30_RESET_POSITION"; }
   string PanelM30ResetSizeName() { return m_prefix + "PANEL_M30_RESET_SIZE"; }
   string PanelLabelName(const int row)
     {
      return m_prefix + "PANEL_LABEL_" + IntegerToString(row);
     }

   string ReactionZoneName(const MTFTrendState &state,
                           const bool demand)
     {
      return m_prefix + state.tag + "_ZONE_" +
             (demand ? "DEMAND_" : "SUPPLY_") +
             IntegerToString((long)(demand ? state.demand.created :
                                             state.supply.created));
     }

   string ReactionZoneLabelName(const MTFTrendState &state,
                                const bool demand)
     {
      return m_prefix + state.tag + "_LABEL_" +
             (demand ? "DEMAND_" : "SUPPLY_") +
             IntegerToString((long)(demand ? state.demand.created :
                                             state.supply.created));
     }

   string SettingsKey(const string suffix)
     {
      return m_settings_key + suffix;
     }

   void LoadDashboardSettings()
     {
      if(!MTFInpRememberDashboard)
         return;
      if(GlobalVariableCheck(SettingsKey("X")))
         m_panel_x = (int)GlobalVariableGet(SettingsKey("X"));
      if(GlobalVariableCheck(SettingsKey("Y")))
         m_panel_y = (int)GlobalVariableGet(SettingsKey("Y"));
      if(GlobalVariableCheck(SettingsKey("W")))
         m_panel_width = (int)GlobalVariableGet(SettingsKey("W"));
      if(GlobalVariableCheck(SettingsKey("H")))
         m_panel_height = (int)GlobalVariableGet(SettingsKey("H"));
      if(GlobalVariableCheck(SettingsKey("P")))
        {
         int stored_position = (int)GlobalVariableGet(SettingsKey("P"));
         if(stored_position >= MTF_PANEL_TOP_LEFT &&
            stored_position <= MTF_PANEL_CUSTOM)
            m_panel_position = (ENUM_MTF_DASHBOARD_POSITION)stored_position;
        }
      if(GlobalVariableCheck(SettingsKey("M")))
         m_panel_manual_size = GlobalVariableGet(SettingsKey("M")) > 0.5;
      if(GlobalVariableCheck(SettingsKey("V")))
         m_dashboard_visible = GlobalVariableGet(SettingsKey("V")) > 0.5;
      if(GlobalVariableCheck(SettingsKey("E")))
         m_dashboard_expanded = GlobalVariableGet(SettingsKey("E")) > 0.5;
      if(GlobalVariableCheck(SettingsKey("MIN")))
         m_dashboard_minimized = GlobalVariableGet(SettingsKey("MIN")) > 0.5;
      if(GlobalVariableCheck(SettingsKey("BOT")))
        {
         m_bot_enabled = GlobalVariableGet(SettingsKey("BOT")) > 0.5;
         m_m30_settings_loaded = true;
        }
      if(GlobalVariableCheck(SettingsKey("M30A")))
        {
         m_m30_analysis_enabled = GlobalVariableGet(SettingsKey("M30A")) > 0.5;
         m_m30_settings_loaded = true;
        }
      if(GlobalVariableCheck(SettingsKey("M30D")))
        {
         m_m30_drawings_enabled = GlobalVariableGet(SettingsKey("M30D")) > 0.5;
         m_m30_settings_loaded = true;
        }
      if(GlobalVariableCheck(SettingsKey("M30ALL")))
         m_m30_all_suspended = GlobalVariableGet(SettingsKey("M30ALL")) > 0.5;
      for(int i = 0; i < 10; i++)
         if(GlobalVariableCheck(SettingsKey("M30S" + IntegerToString(i))))
           {
            m_m30_strategy_enabled[i] = GlobalVariableGet(SettingsKey("M30S" + IntegerToString(i))) > 0.5;
            m_m30_saved_strategy_enabled[i] = GlobalVariableCheck(SettingsKey("M30P" + IntegerToString(i))) ?
                                               GlobalVariableGet(SettingsKey("M30P" + IntegerToString(i))) > 0.5 :
                                               m_m30_strategy_enabled[i];
            m_m30_settings_loaded = true;
           }
      for(int i = 0; i < 3; i++)
         if(GlobalVariableCheck(SettingsKey("TF" + IntegerToString(i))))
            m_show_markings[i] = GlobalVariableGet(SettingsKey("TF" + IntegerToString(i))) > 0.5;
     }

   void MigrateDrawingDefaults()
     {
      if(!MTFInpRememberDashboard || GlobalVariableCheck(SettingsKey("LAYER_CFG_V2")))
         return;
      // Older builds persisted the DRAWINGS master toggle as individual OFF
      // settings. Seed the configured defaults once, then keep user selections.
      m_show_markings[0]=MTFInpShowH1Markings;
      m_show_markings[1]=MTFInpShowH4Markings;
      m_show_markings[2]=MTFInpShowD1Markings;
      m_m30_drawings_enabled=true;
      SaveDashboardSettings();
      GlobalVariableSet(SettingsKey("LAYER_CFG_V2"),2.0);
      GlobalVariablesFlush();
     }

   void SaveDashboardSettings()
     {
      if(!MTFInpRememberDashboard)
         return;
      GlobalVariableSet(SettingsKey("X"), (double)m_panel_x);
      GlobalVariableSet(SettingsKey("Y"), (double)m_panel_y);
      GlobalVariableSet(SettingsKey("W"), (double)m_panel_width);
      GlobalVariableSet(SettingsKey("H"), (double)m_panel_height);
      GlobalVariableSet(SettingsKey("P"), (double)m_panel_position);
      GlobalVariableSet(SettingsKey("M"), m_panel_manual_size ? 1.0 : 0.0);
      GlobalVariableSet(SettingsKey("V"), m_dashboard_visible ? 1.0 : 0.0);
      GlobalVariableSet(SettingsKey("E"), m_dashboard_expanded ? 1.0 : 0.0);
      GlobalVariableSet(SettingsKey("MIN"), m_dashboard_minimized ? 1.0 : 0.0);
      GlobalVariableSet(SettingsKey("BOT"), m_bot_enabled ? 1.0 : 0.0);
      GlobalVariableSet(SettingsKey("M30A"), m_m30_analysis_enabled ? 1.0 : 0.0);
      GlobalVariableSet(SettingsKey("M30D"), m_m30_drawings_enabled ? 1.0 : 0.0);
      GlobalVariableSet(SettingsKey("M30ALL"), m_m30_all_suspended ? 1.0 : 0.0);
      for(int i = 0; i < 10; i++)
        {
         GlobalVariableSet(SettingsKey("M30S" + IntegerToString(i)),
                           m_m30_strategy_enabled[i] ? 1.0 : 0.0);
         GlobalVariableSet(SettingsKey("M30P" + IntegerToString(i)),
                           m_m30_saved_strategy_enabled[i] ? 1.0 : 0.0);
        }
      for(int i = 0; i < 3; i++)
         GlobalVariableSet(SettingsKey("TF" + IntegerToString(i)),
                           m_show_markings[i] ? 1.0 : 0.0);
      GlobalVariablesFlush();
     }

   color TimeframeColor(const int index)
     {
      if(index == 0) return MTFInpH1Color;
      if(index == 1) return MTFInpH4Color;
      return MTFInpD1Color;
     }

   int SwingLeftBars(const MTFTrendState &state)
     {
      if(state.timeframe == PERIOD_H1) return MTFInpH1SwingLeftBars;
      if(state.timeframe == PERIOD_H4) return MTFInpH4SwingLeftBars;
      return MTFInpD1SwingLeftBars;
     }

   int SwingRightBars(const MTFTrendState &state)
     {
      if(state.timeframe == PERIOD_H1) return MTFInpH1SwingRightBars;
      if(state.timeframe == PERIOD_H4) return MTFInpH4SwingRightBars;
      return MTFInpD1SwingRightBars;
     }

   bool MarkingsEnabled(const int index)
     {
      if(index < 0 || index > 2) return false;
      return m_show_markings[index];
     }

   void ApplyTimeframeVisibility(const int index)
     {
      if(index < 0 || index > 2) return;
      string tag = m_states[index].tag;
      string object_prefix = m_prefix + tag + "_";
      long visibility = (m_master_drawings_enabled && m_show_markings[index]) ?
                        OBJ_ALL_PERIODS : OBJ_NO_PERIODS;
      int total = ObjectsTotal(0, 0, -1);
      for(int i = total - 1; i >= 0; i--)
        {
         string name = ObjectName(0, i, 0, -1);
         if(StringFind(name, object_prefix) == 0)
            ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, visibility);
        }
     }

   int PanelDisplayHeight()
     {
      if(m_dashboard_minimized)
         return 30;
      int height = m_panel_height > 0 ? m_panel_height : MTFInpDashboardHeight;
      return (int)MathMax(150, height);
     }

   string TimeframeText(const ENUM_TIMEFRAMES timeframe)
     {
      if(timeframe == PERIOD_H1) return "H1";
      if(timeframe == PERIOD_H4) return "H4";
      return "D1";
     }

   color DirectionColor(const int direction)
     {
      if(direction > 0) return clrLimeGreen;
      if(direction < 0) return clrTomato;
      return clrSilver;
     }

   string DirectionText(const int direction)
     {
      if(direction > 0) return "BULLISH";
      if(direction < 0) return "BEARISH";
      return "NEUTRAL";
     }

   string EventName(const ENUM_MTF_EVENT event_type)
     {
      if(event_type == MTF_EVENT_BOS) return "BOS";
      if(event_type == MTF_EVENT_CHOCH) return "CHoCH";
      if(event_type == MTF_EVENT_MSS) return "CHoCH + MSS";
      return "NO CONFIRMED BREAK";
     }

   string EventSummary(const MTFStructureEvent &event)
     {
      if(!event.valid)
         return "NO BREAK";
      string side = event.direction > 0 ? "UP" : "DOWN";
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      return EventName(event.event_type) + " " + side + " @ " +
             DoubleToString(event.break_level, digits);
     }

   void ResetSwing(MTFSwingPoint &swing)
     {
      swing.valid = false;
      swing.timeframe = PERIOD_CURRENT;
      swing.is_high = false;
      swing.time = 0;
      swing.shift = -1;
      swing.price = 0.0;
      swing.code = "";
     }

   void ResetEvent(MTFStructureEvent &event)
     {
      event.valid = false;
      event.timeframe = PERIOD_CURRENT;
      event.direction = 0;
      event.event_type = MTF_EVENT_NONE;
      event.reversal_warning = false;
      event.break_time = 0;
      event.swing_time = 0;
      event.break_level = 0.0;
      event.break_close = 0.0;
      event.atr = 0.0;
     }

   void ResetLevel(MTFLevel &level)
     {
      level.valid = false;
      level.price = 0.0;
      level.low = 0.0;
      level.high = 0.0;
      level.time = 0;
      level.tests = 0;
      level.broken = false;
      level.invalidated = false;
     }

   void ResetZone(MTFReactionZone &zone)
     {
      zone.valid = false;
      zone.demand = false;
      zone.low = 0.0;
      zone.high = 0.0;
      zone.midpoint = 0.0;
      zone.created = 0;
      zone.tests = 0;
      zone.invalidated = false;
     }

   void ResetState(MTFTrendState &state)
     {
      state.data_ready = false;
      state.current_bar = 0;
      state.direction = 0;
      state.break_bias = 0;
      state.high_broken = false;
      state.low_broken = false;
      state.structure = "WAIT FOR HISTORY";
      ResetSwing(state.previous_high);
      ResetSwing(state.latest_high);
      ResetSwing(state.previous_low);
      ResetSwing(state.latest_low);
      ResetEvent(state.latest_event);
      ResetEvent(state.latest_reversal_event);
      ResetLevel(state.support);
      ResetLevel(state.resistance);
      ResetLevel(state.equal_highs);
      ResetLevel(state.equal_lows);
      ResetZone(state.demand);
      ResetZone(state.supply);
      state.trendline_valid = false;
      state.trendline_broken = false;
      state.trendline_break_time = 0;
      state.trendline_break_price = 0.0;
      state.trendline_break_direction = 0;
      state.sweep_valid = false;
      state.sweep_direction = 0;
      state.sweep_time = 0;
      state.sweep_level = 0.0;
      state.wick_sweep = false;
      state.wick_sweep_direction = 0;
      state.wick_sweep_level = 0.0;
      state.atr = 0.0;
     }

   double ATRAt(const MqlRates &rates[],
                const int total,
                const int shift,
                const int period)
     {
      if(period <= 0 || shift < 0 || shift + period >= total)
         return 0.0;
      double sum = 0.0;
      for(int i = shift; i < shift + period; i++)
        {
         double previous_close = rates[i + 1].close;
         double tr = MathMax(rates[i].high - rates[i].low,
                    MathMax(MathAbs(rates[i].high - previous_close),
                            MathAbs(rates[i].low - previous_close)));
         sum += tr;
        }
      return sum / period;
     }

   bool IsPivotHigh(const MqlRates &rates[],
                    const int total,
                    const int pivot,
                    const int left_bars,
                    const int right_bars)
     {
      if(pivot - right_bars < 1 || pivot + left_bars >= total)
         return false;
      for(int i = 1; i <= left_bars; i++)
         if(rates[pivot].high <= rates[pivot + i].high)
            return false;
      for(int i = 1; i <= right_bars; i++)
         if(rates[pivot].high < rates[pivot - i].high)
            return false;
      return true;
     }

   bool IsPivotLow(const MqlRates &rates[],
                   const int total,
                   const int pivot,
                   const int left_bars,
                   const int right_bars)
     {
      if(pivot - right_bars < 1 || pivot + left_bars >= total)
         return false;
      for(int i = 1; i <= left_bars; i++)
         if(rates[pivot].low >= rates[pivot + i].low)
            return false;
      for(int i = 1; i <= right_bars; i++)
         if(rates[pivot].low > rates[pivot - i].low)
            return false;
      return true;
     }

   string ClassifyHigh(const double price,
                       const double prior,
                       const double tolerance)
     {
      if(prior <= 0.0) return "H";
      if(price > prior + tolerance) return "HH";
      if(price < prior - tolerance) return "LH";
      return "EQH";
     }

   string ClassifyLow(const double price,
                      const double prior,
                      const double tolerance)
     {
      if(prior <= 0.0) return "L";
      if(price > prior + tolerance) return "HL";
      if(price < prior - tolerance) return "LL";
      return "EQL";
     }

   void AppendSwing(MTFSwingPoint &points[], const MTFSwingPoint &swing)
     {
      int count = ArraySize(points);
      if(ArrayResize(points, count + 1) == count + 1)
         points[count] = swing;
     }

   string SwingObjectName(const MTFTrendState &state,
                          const MTFSwingPoint &swing)
     {
      return m_prefix + state.tag + "_SW_" +
             (swing.is_high ? "HIGH_" : "LOW_") +
             IntegerToString((long)swing.time);
     }

   bool CreateOrMoveText(const string name,
                         const string text,
                         const datetime time,
                         const double price,
                         const color text_color,
                         const int font_size)
     {
      if(ObjectFind(0, name) < 0)
        {
         if(!ObjectCreate(0, name, OBJ_TEXT, 0, time, price))
            return false;
        }
      else if(!ObjectMove(0, name, 0, time, price))
         return false;
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
      ObjectSetInteger(0, name, OBJPROP_COLOR, text_color);
      ObjectSetInteger(0, name, OBJPROP_BACK, false);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      return true;
     }

   void DrawSwingMark(const MTFTrendState &state,
                      const MTFSwingPoint &swing,
                      const double atr)
     {
      int index = state.timeframe == PERIOD_H1 ? 0 :
                  (state.timeframe == PERIOD_H4 ? 1 : 2);
       if(!MTFInpShowSwingLabels ||
         swing.shift > MTFInpHistoricalBars)
         return;
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double offset = MathMax(point * 4.0, atr * 0.05);
      double label_price = swing.is_high ? swing.price + offset :
                                           swing.price - offset;
       color mark_color = (swing.code == "HH" || swing.code == "HL")
                          ? clrForestGreen : clrFireBrick;
      if(swing.code == "H" || swing.code == "L" ||
         StringFind(swing.code, "EQ") == 0)
         mark_color = clrSilver;
      CreateOrMoveText(SwingObjectName(state, swing), swing.code,
                       swing.time, label_price, mark_color, 8);
     }

   string EventTimeText(const datetime when)
     {
      return TimeToString(when, TIME_DATE | TIME_MINUTES);
     }

   void DrawEvent(const MTFTrendState &state,
                  const MTFStructureEvent &event)
     {
      int index = state.timeframe == PERIOD_H1 ? 0 :
                  (state.timeframe == PERIOD_H4 ? 1 : 2);
       if(!event.valid)
         return;
      string type_name = event.event_type == MTF_EVENT_BOS ? "BOS" :
                         (event.event_type == MTF_EVENT_MSS ? "MSS" : "CHOCH");
      string key = state.tag + "_EV_" + type_name + "_" +
                   IntegerToString((long)event.break_time);
      string line_name = m_prefix + state.tag + "_LEVEL_" + key;
      string text_name = m_prefix + state.tag + "_LABEL_" + key;
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
       color c = event.reversal_warning ? clrDarkOrange :
                 TimeframeColor(state.tag == "H1" ? 0 :
                                (state.tag == "H4" ? 1 : 2));
      string side = event.direction > 0 ? "UP" : "DOWN";
       string event_label = event.event_type == MTF_EVENT_MSS ? "MSS / CHoCH" :
                            (event.event_type == MTF_EVENT_CHOCH ? "CHoCH" : "BOS");
       string text = state.tag + " " + event_label + " " + side +
                    " | " + DoubleToString(event.break_level, digits) +
                    " | " + EventTimeText(event.break_time);

      if(MTFInpShowBreakLevels)
        {
         if(ObjectFind(0, line_name) < 0)
            ObjectCreate(0, line_name, OBJ_TREND, 0,
                         event.swing_time, event.break_level,
                         event.break_time, event.break_level);
         ObjectMove(0, line_name, 0, event.swing_time, event.break_level);
         ObjectMove(0, line_name, 1, event.break_time, event.break_level);
         ObjectSetInteger(0, line_name, OBJPROP_COLOR, c);
          ObjectSetInteger(0, line_name, OBJPROP_STYLE,
                           event.reversal_warning ? STYLE_DASH : MTFInpBreakLineStyle);
          ObjectSetInteger(0, line_name, OBJPROP_WIDTH,
                           event.reversal_warning ? 2 : MTFInpLineWidth);
         ObjectSetInteger(0, line_name, OBJPROP_RAY_RIGHT, false);
         ObjectSetInteger(0, line_name, OBJPROP_BACK, true);
         ObjectSetInteger(0, line_name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, line_name, OBJPROP_HIDDEN, true);
          ObjectSetInteger(0, line_name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        }
      if(MTFInpShowLabels)
        {
         double offset = MathMax(SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 4.0,
                                 event.atr * 0.08);
         double label_price = event.direction > 0 ?
                              event.break_close + offset :
                              event.break_close - offset;
         CreateOrMoveText(text_name, text, event.break_time,
                          label_price, c, 8);
        }
     }

   void ClearTimeframeObjects(const MTFTrendState &state)
     {
      ObjectsDeleteAll(0, m_prefix + state.tag + "_SW_", 0, -1);
      ObjectsDeleteAll(0, m_prefix + state.tag + "_EV_", 0, -1);
      ObjectsDeleteAll(0, m_prefix + state.tag + "_LEVEL_", 0, -1);
      ObjectsDeleteAll(0, m_prefix + state.tag + "_LABEL_", 0, -1);
      ObjectsDeleteAll(0, m_prefix + state.tag + "_TREND_", 0, -1);
      ObjectsDeleteAll(0, m_prefix + state.tag + "_SR_", 0, -1);
      ObjectsDeleteAll(0, m_prefix + state.tag + "_ZONE_", 0, -1);
      ObjectsDeleteAll(0, m_prefix + state.tag + "_SWEEP_", 0, -1);
     }

   void UpdateStructureDirection(MTFTrendState &state,
                                 const double tolerance)
     {
      bool enough_highs = state.previous_high.valid && state.latest_high.valid;
      bool enough_lows = state.previous_low.valid && state.latest_low.valid;
      if(!enough_highs || !enough_lows)
        {
         if(state.latest_high.valid && state.latest_low.valid)
            state.structure = state.latest_high.code + " / " + state.latest_low.code;
         else
            state.structure = "WAIT FOR CONFIRMED SWINGS";
         return;
        }

      bool hh = state.latest_high.price > state.previous_high.price + tolerance;
      bool lh = state.latest_high.price < state.previous_high.price - tolerance;
      bool hl = state.latest_low.price > state.previous_low.price + tolerance;
      bool ll = state.latest_low.price < state.previous_low.price - tolerance;
      if(hh && hl)
        {
         state.direction = 1;
         state.break_bias = 1;
         state.structure = "HH / HL";
        }
      else if(lh && ll)
        {
         state.direction = -1;
         state.break_bias = -1;
         state.structure = "LH / LL";
        }
      else
        {
         state.structure = state.latest_high.code + " / " +
                           state.latest_low.code + " (MIXED)";
         // Keep the last confirmed trend until an opposite HH/HL or LH/LL
         // sequence is complete. A CHoCH warning alone does not flip bias.
        }
     }

   double GetATRValue(const int handle,
                      const double &atr_values[],
                      const int atr_copied,
                      const MqlRates &rates[],
                      const int total,
                      const int shift)
     {
      if(handle != INVALID_HANDLE && shift < atr_copied &&
         atr_values[shift] > 0.0)
         return atr_values[shift];
      return ATRAt(rates, total, shift, MTFInpATRPeriod);
     }

   bool SwingPassesDistance(const double price,
                            const double prior_price,
                            const double atr)
     {
      if(prior_price <= 0.0)
         return true;
      double minimum = MathMax(MTFInpMinimumSwingDistancePoints *
                               SymbolInfoDouble(_Symbol, SYMBOL_POINT),
                               MTFInpMinimumSwingDistanceATR * atr);
      return MathAbs(price - prior_price) >= minimum;
     }

   void RecordEvent(MTFTrendState &state,
                    const int direction,
                    const MTFStructureEvent &event)
     {
      state.latest_event = event;
      if(event.reversal_warning)
         state.latest_reversal_event = event;
      if(direction == state.break_bias || state.break_bias == 0)
         state.break_bias = direction;
     }

   void PushAndClassifySwing(MTFTrendState &state,
                             MTFSwingPoint &history[],
                             const MTFSwingPoint &swing,
                             const double atr,
                             const bool is_high)
     {
      if(is_high)
        {
         double tol = MathMax(MTFInpEqualSwingTolerancePoints *
                              SymbolInfoDouble(_Symbol, SYMBOL_POINT),
                              MTFInpEqualSwingToleranceATR * atr);
         string code = ClassifyHigh(swing.price,
                                    state.latest_high.valid ?
                                    state.latest_high.price : 0.0, tol);
         MTFSwingPoint accepted = swing;
         accepted.code = code;
         if(state.latest_high.valid &&
            accepted.code != "EQH" &&
            !SwingPassesDistance(accepted.price, state.latest_high.price, atr))
            return;
         state.previous_high = state.latest_high;
         state.latest_high = accepted;
         AppendSwing(history, accepted);
         state.high_broken = false;
         DrawSwingMark(state, accepted, atr);
         if(MTFInpDiagnosticLogging &&
            accepted.shift == SwingRightBars(state) + 1)
            PrintFormat("%s %s swing %s price=%.*f time=%s",
                        state.tag, TimeframeText(state.timeframe), accepted.code,
                        _Digits, accepted.price, EventTimeText(accepted.time));
         UpdateStructureDirection(state, tol);
        }
      else
        {
         double tol = MathMax(MTFInpEqualSwingTolerancePoints *
                              SymbolInfoDouble(_Symbol, SYMBOL_POINT),
                              MTFInpEqualSwingToleranceATR * atr);
         string code = ClassifyLow(swing.price,
                                   state.latest_low.valid ?
                                   state.latest_low.price : 0.0, tol);
         MTFSwingPoint accepted = swing;
         accepted.code = code;
         if(state.latest_low.valid &&
            accepted.code != "EQL" &&
            !SwingPassesDistance(accepted.price, state.latest_low.price, atr))
            return;
         state.previous_low = state.latest_low;
         state.latest_low = accepted;
         AppendSwing(history, accepted);
         state.low_broken = false;
         DrawSwingMark(state, accepted, atr);
         if(MTFInpDiagnosticLogging &&
            accepted.shift == SwingRightBars(state) + 1)
            PrintFormat("%s %s swing %s price=%.*f time=%s",
                        state.tag, TimeframeText(state.timeframe), accepted.code,
                        _Digits, accepted.price, EventTimeText(accepted.time));
         UpdateStructureDirection(state, tol);
        }
     }

   void FindCluster(MTFSwingPoint &points[],
                    const int count,
                    const bool support_side,
                    const double current_price,
                    const double tolerance,
                    MTFLevel &result)
     {
      ResetLevel(result);
      if(count <= 0)
         return;
      int best_tests = 0;
      double best_distance = DBL_MAX;
      int best_index = -1;
      for(int i = 0; i < count; i++)
        {
         double center = points[i].price;
         if(support_side && center > current_price + tolerance)
            continue;
         if(!support_side && center < current_price - tolerance)
            continue;
         int tests = 0;
         for(int j = 0; j < count; j++)
            if(MathAbs(points[j].price - center) <= tolerance)
               tests++;
         double distance = MathAbs(current_price - center);
         if(tests > best_tests ||
            (tests == best_tests && tests > 0 && distance < best_distance))
           {
            best_tests = tests;
            best_distance = distance;
            best_index = i;
           }
        }
      // If price has broken through every candidate, keep the closest one so
      // the dashboard can report it as broken instead of hiding the level.
      if(best_index < 0)
        {
         for(int i = 0; i < count; i++)
           {
            int tests = 0;
            for(int j = 0; j < count; j++)
               if(MathAbs(points[j].price - points[i].price) <= tolerance)
                  tests++;
            double distance = MathAbs(current_price - points[i].price);
            if(tests > best_tests ||
               (tests == best_tests && tests > 0 && distance < best_distance))
              {
               best_distance = distance;
               best_index = i;
               best_tests = tests;
              }
           }
        }
      if(best_index < 0)
         return;

      double center = points[best_index].price;
      result.valid = true;
      result.price = center;
      result.low = center - tolerance * 0.5;
      result.high = center + tolerance * 0.5;
      result.time = points[best_index].time;
      result.tests = best_tests;
      result.broken = support_side ? current_price < center - tolerance * 0.5
                                   : current_price > center + tolerance * 0.5;
     }

   void FindReactionZone(MTFSwingPoint &points[],
                         const MqlRates &rates[],
                         const int copied,
                         const bool demand,
                         MTFReactionZone &zone)
     {
      ResetZone(zone);
      zone.demand = demand;
      int count = ArraySize(points);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      for(int i = count - 1; i >= 0; i--)
        {
         int pivot = points[i].shift;
         if(pivot <= 1 || pivot >= copied ||
            pivot > MTFInpZoneLookbackBars)
            continue;
         double atr = ATRAt(rates, copied, pivot, MTFInpATRPeriod);
         if(atr <= 0.0)
            continue;
         int oldest_reaction = (int)MathMax(1,
                                  pivot - MTFInpZoneReactionBars);
         double extreme = demand ? -DBL_MAX : DBL_MAX;
         for(int shift = pivot - 1; shift >= oldest_reaction; shift--)
           {
            if(demand)
               extreme = MathMax(extreme, rates[shift].high);
            else
               extreme = MathMin(extreme, rates[shift].low);
           }
         double move_away = demand ? extreme - points[i].price :
                                     points[i].price - extreme;
         if(move_away < MTFInpZoneMinMoveAwayATR * atr)
            continue;

         double half_width = MathMax(point * 2.0,
                                     MTFInpZoneHalfWidthATR * atr);
         zone.valid = true;
         zone.demand = demand;
         zone.low = demand ? points[i].price : points[i].price - half_width;
         zone.high = demand ? points[i].price + half_width : points[i].price;
         zone.midpoint = (zone.low + zone.high) * 0.5;
         zone.created = points[i].time;
         for(int shift = 1; shift < pivot; shift++)
            if(rates[shift].low <= zone.high &&
               rates[shift].high >= zone.low)
               zone.tests++;
         zone.invalidated = demand ?
                            rates[1].close < zone.low -
                            MTFInpZoneInvalidationATR * atr :
                            rates[1].close > zone.high +
                            MTFInpZoneInvalidationATR * atr;
         return;
        }
     }

   void FindEqualLiquidity(MTFSwingPoint &points[],
                           const int count,
                           const double tolerance,
                           const double current_price,
                           const bool highs,
                           MTFLevel &result)
     {
      ResetLevel(result);
      if(count < 2 || tolerance <= 0.0)
         return;
      double best_distance = DBL_MAX;
      for(int i = 0; i < count; i++)
        {
         int tests = 0;
         double sum = 0.0;
         double low = DBL_MAX;
         double high = -DBL_MAX;
         datetime newest_time = 0;
         for(int j = 0; j < count; j++)
            if(MathAbs(points[j].price - points[i].price) <= tolerance)
              {
               tests++;
               sum += points[j].price;
               low = MathMin(low, points[j].price);
               high = MathMax(high, points[j].price);
               if(points[j].time > newest_time)
                  newest_time = points[j].time;
              }
         if(tests < 2)
            continue;
         double center = sum / tests;
         double distance = MathAbs(current_price - center);
         if(distance >= best_distance)
            continue;
         best_distance = distance;
         result.valid = true;
         result.price = center;
         result.low = low - tolerance * 0.25;
         result.high = high + tolerance * 0.25;
         result.time = newest_time;
         result.tests = tests;
         result.broken = highs ? current_price > result.high :
                                 current_price < result.low;
        }
     }

   void DrawReactionZone(const MTFTrendState &state,
                         const MTFReactionZone &zone,
                         const bool demand,
                         const int index)
     {
      string side = demand ? "DEMAND" : "SUPPLY";
      string key = m_prefix + state.tag + "_ZONE_" + side + "_" +
                   IntegerToString((long)zone.created);
      string label_name = m_prefix + state.tag + "_LABEL_" + side + "_" +
                          IntegerToString((long)zone.created);
       if(!zone.valid || !MTFInpShowZones)
        {
         ObjectDelete(0, key);
         ObjectDelete(0, label_name);
         return;
        }
      int seconds = PeriodSeconds(state.timeframe);
      if(seconds <= 0)
         seconds = 60;
      datetime end_time = TimeCurrent() + (datetime)(seconds * 30);
      if(ObjectFind(0, key) < 0)
         ObjectCreate(0, key, OBJ_RECTANGLE, 0, zone.created, zone.high,
                      end_time, zone.low);
      else
        {
         ObjectMove(0, key, 0, zone.created, zone.high);
         ObjectMove(0, key, 1, end_time, zone.low);
        }
      color zone_color = zone.invalidated ? clrDarkGray :
                         (demand ? clrSeaGreen : clrIndianRed);
      ObjectSetInteger(0, key, OBJPROP_COLOR, zone_color);
      ObjectSetInteger(0, key, OBJPROP_STYLE,
                       zone.invalidated ? STYLE_DASH : STYLE_SOLID);
      ObjectSetInteger(0, key, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, key, OBJPROP_FILL, true);
      ObjectSetInteger(0, key, OBJPROP_BACK, true);
      ObjectSetInteger(0, key, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, key, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, key, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      if(MTFInpShowLabels)
        {
         string label = state.tag + " " + side +
                        (zone.invalidated ? " INVALID" : "");
         double label_price = zone.midpoint +
                              (index - 1) * state.atr * 0.08;
         CreateOrMoveText(label_name, label, end_time, label_price,
                          zone_color, 8);
        }
      else
         ObjectDelete(0, label_name);
     }

   void DrawLiquidityLevel(const MTFTrendState &state,
                           const MTFLevel &level,
                           const bool buy_side,
                           const int index)
     {
      string side = buy_side ? "BSL" : "SSL";
      string object_name = m_prefix + state.tag + "_LIQ_" + side + "_" +
                           IntegerToString((long)level.time);
      string label_name = m_prefix + state.tag + "_LABEL_LIQ_" + side + "_" +
                          IntegerToString((long)level.time);
       if(!level.valid ||
         !MTFInpShowLiquidityLevels)
        {
         ObjectDelete(0, object_name);
         ObjectDelete(0, label_name);
         return;
        }
      if(ObjectFind(0, object_name) < 0)
         ObjectCreate(0, object_name, OBJ_HLINE, 0, 0, level.price);
      ObjectSetDouble(0, object_name, OBJPROP_PRICE, level.price);
      ObjectSetInteger(0, object_name, OBJPROP_COLOR,
                       level.broken ? clrDarkGray : clrMediumPurple);
      ObjectSetInteger(0, object_name, OBJPROP_STYLE,
                       level.broken ? STYLE_DASHDOT : STYLE_DOT);
      ObjectSetInteger(0, object_name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, object_name, OBJPROP_BACK, true);
      ObjectSetInteger(0, object_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, object_name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, object_name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      if(MTFInpShowLabels)
        {
         string label = state.tag + " " + side +
                        (level.broken ? " TAKEN" : "");
         double label_price = level.price + (index - 1) * state.atr * 0.08;
         CreateOrMoveText(label_name, label, iTime(_Symbol, _Period, 0),
                          label_price, clrMediumPurple, 8);
        }
      else
         ObjectDelete(0, label_name);
     }

   void DrawLevelZone(const MTFTrendState &state,
                      const MTFLevel &level,
                      const bool support_side,
                      const int index)
     {
      string side = support_side ? "SUPPORT" : "RESISTANCE";
      string line_name = m_prefix + state.tag + "_SR_" + side + "_LINE";
      string zone_name = m_prefix + state.tag + "_SRZONE_" + side;
      string text_name = m_prefix + state.tag + "_LABEL_SR_" + side;
       if(!level.valid)
        {
         ObjectDelete(0, line_name);
         ObjectDelete(0, zone_name);
         ObjectDelete(0, text_name);
         return;
        }

      color c = level.invalidated ? clrDarkGray :
                (level.broken ? clrOrange : TimeframeColor(index));
      if(ObjectFind(0, line_name) < 0)
         ObjectCreate(0, line_name, OBJ_HLINE, 0, 0, level.price);
      ObjectSetDouble(0, line_name, OBJPROP_PRICE, level.price);
      ObjectSetInteger(0, line_name, OBJPROP_COLOR, c);
      ObjectSetInteger(0, line_name, OBJPROP_STYLE,
                       level.invalidated ? STYLE_DASHDOT :
                       (level.broken ? STYLE_DASH : STYLE_SOLID));
      ObjectSetInteger(0, line_name, OBJPROP_WIDTH, MTFInpLineWidth);
      ObjectSetInteger(0, line_name, OBJPROP_BACK, true);
      ObjectSetInteger(0, line_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, line_name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, line_name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);

      if(MTFInpShowZones)
        {
         int seconds = PeriodSeconds(state.timeframe);
         if(seconds <= 0) seconds = 60;
         datetime end_time = TimeCurrent() + (datetime)(seconds * 30);
         if(ObjectFind(0, zone_name) < 0)
            ObjectCreate(0, zone_name, OBJ_RECTANGLE, 0,
                         level.time, level.high, end_time, level.low);
         else
           {
            ObjectMove(0, zone_name, 0, level.time, level.high);
            ObjectMove(0, zone_name, 1, end_time, level.low);
           }
         ObjectSetInteger(0, zone_name, OBJPROP_COLOR, c);
         ObjectSetInteger(0, zone_name, OBJPROP_STYLE,
                          level.invalidated ? STYLE_DASHDOT :
                          (level.broken ? STYLE_DASH : STYLE_SOLID));
         ObjectSetInteger(0, zone_name, OBJPROP_WIDTH, 1);
         ObjectSetInteger(0, zone_name, OBJPROP_FILL, true);
         ObjectSetInteger(0, zone_name, OBJPROP_BACK, true);
         ObjectSetInteger(0, zone_name, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(0, zone_name, OBJPROP_HIDDEN, true);
         ObjectSetInteger(0, zone_name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
        }
      else
         ObjectDelete(0, zone_name);

       if(MTFInpShowLabels)
        {
         int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
         datetime label_time = iTime(_Symbol, _Period, 0);
          string status = level.invalidated ? "INV" :
                          (level.broken ? "BRK" :
                          (level.tests >= MTFInpMinimumLevelTests ? "ACT" : "CAND"));
          string text = state.tag + " " + (support_side ? "S" : "R") + " " +
                        status + " " +
                       DoubleToString(level.price, digits);
         double label_price = support_side ? level.high : level.low;
         label_price += (index - 1) * state.atr * 0.08;
         if(label_time <= 0) label_time = TimeCurrent();
         CreateOrMoveText(text_name, text, label_time, label_price, c, 8);
        }
      else
         ObjectDelete(0, text_name);
     }

   void DrawTrendline(MTFTrendState &state, const int index, const MqlRates &last_closed)
     {
      ObjectsDeleteAll(0, m_prefix + state.tag + "_TREND_", 0, -1);
      state.trendline_valid = false;
      state.trendline_broken = false;
      state.trendline_break_time = 0;
      state.trendline_break_price = 0.0;
      state.trendline_break_direction = 0;
       if(!MTFInpShowTrendlines)
         return;
      bool bullish = state.direction > 0 &&
                     state.previous_low.valid && state.latest_low.valid &&
                     state.previous_low.code == "HL" &&
                     state.latest_low.code == "HL" &&
                     state.previous_low.time < state.latest_low.time &&
                     state.latest_low.price > state.previous_low.price;
      bool bearish = state.direction < 0 &&
                     state.previous_high.valid && state.latest_high.valid &&
                     state.previous_high.code == "LH" &&
                     state.latest_high.code == "LH" &&
                     state.previous_high.time < state.latest_high.time &&
                     state.latest_high.price < state.previous_high.price;
      if(!bullish && !bearish)
         return;

      MTFSwingPoint first = bullish ? state.previous_low : state.previous_high;
      MTFSwingPoint second = bullish ? state.latest_low : state.latest_high;
      if(first.time <= 0 || second.time <= first.time ||
         second.time > last_closed.time)
         return;

      double projected = first.price +
                         (second.price - first.price) *
                         (double)(last_closed.time - first.time) /
                         (double)(second.time - first.time);
      double break_buffer = MTFInpBreakBufferPoints *
                            SymbolInfoDouble(_Symbol, SYMBOL_POINT) +
                            MTFInpBreakBufferATR * state.atr;
      state.trendline_broken = bullish
                               ? last_closed.close < projected - break_buffer
                               : last_closed.close > projected + break_buffer;
      state.trendline_valid = true;
      if(state.trendline_broken)
        {
         state.trendline_break_time = last_closed.time;
         state.trendline_break_price = last_closed.close;
         state.trendline_break_direction = bullish ? -1 : 1;
        }

      string direction = bullish ? "BULL" : "BEAR";
      string name = m_prefix + state.tag + "_TREND_" + direction + "_" +
                    IntegerToString((long)first.time) + "_" +
                    IntegerToString((long)second.time);
      if(!ObjectCreate(0, name, OBJ_TREND, 0,
                       first.time, first.price, second.time, second.price))
         return;
       color c = state.trendline_broken ? clrDarkOrange : TimeframeColor(index);
      ObjectSetInteger(0, name, OBJPROP_COLOR, c);
      ObjectSetInteger(0, name, OBJPROP_STYLE, MTFInpTrendLineStyle);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, MTFInpLineWidth);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT,
                       MTFInpExtendTrendlines && !state.trendline_broken);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);

      if(MTFInpDiagnosticLogging)
         PrintFormat("%s trendline %s anchors %.*f @ %s -> %.*f @ %s",
                     state.tag, direction, _Digits, first.price,
                     EventTimeText(first.time), _Digits, second.price,
                     EventTimeText(second.time));
      if(state.trendline_broken && MTFInpShowLabels)
        {
         string note = m_prefix + state.tag + "_LABEL_TREND_BROKEN_" +
                       IntegerToString((long)second.time);
          string break_side = bullish ? "DOWN" : "UP";
          string break_text = state.tag + " TRENDLINE BREAK " + break_side +
                              " @ " + DoubleToString(last_closed.close, _Digits);
          CreateOrMoveText(note, break_text, last_closed.time,
                           last_closed.close, clrDarkOrange, 9);
        }
     }

   void FindLiquiditySweep(MTFTrendState &state,
                           const MqlRates &rates[],
                           const double buffer)
     {
      state.sweep_valid = false;
      state.wick_sweep = false;
      double ssl = state.equal_lows.valid ? state.equal_lows.price :
                   (state.latest_low.valid ? state.latest_low.price : 0.0);
      double bsl = state.equal_highs.valid ? state.equal_highs.price :
                   (state.latest_high.valid ? state.latest_high.price : 0.0);
      if(ssl > 0.0 && rates[1].low < ssl - buffer &&
         rates[1].close > ssl)
        {
         state.sweep_valid = true;
         state.sweep_direction = 1;
         state.sweep_level = ssl;
         state.sweep_time = rates[1].time;
        }
      else if(bsl > 0.0 && rates[1].high > bsl + buffer &&
              rates[1].close < bsl)
        {
         state.sweep_valid = true;
         state.sweep_direction = -1;
         state.sweep_level = bsl;
         state.sweep_time = rates[1].time;
        }

      if(ssl > 0.0 && rates[0].low < ssl - buffer)
        {
         state.wick_sweep = true;
         state.wick_sweep_direction = 1;
         state.wick_sweep_level = ssl;
        }
      else if(bsl > 0.0 && rates[0].high > bsl + buffer)
        {
         state.wick_sweep = true;
         state.wick_sweep_direction = -1;
         state.wick_sweep_level = bsl;
        }

      int index = state.timeframe == PERIOD_H1 ? 0 :
                  (state.timeframe == PERIOD_H4 ? 1 : 2);
       if(state.sweep_valid && MTFInpShowLabels)
        {
         string name = m_prefix + state.tag + "_SWEEP_" +
                       IntegerToString((long)state.sweep_time);
         string label = state.sweep_direction > 0 ?
                        state.tag + " SSL SWEEP / CLOSE RECLAIM UP" :
                        state.tag + " BSL SWEEP / CLOSE RECLAIM DOWN";
         double offset = MathMax(SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 4.0,
                                 state.atr * 0.08);
         double price = state.sweep_direction > 0 ?
                        rates[1].low - offset : rates[1].high + offset;
         CreateOrMoveText(name, label, state.sweep_time, price,
                          state.sweep_direction > 0 ? clrLimeGreen : clrTomato, 8);
        }
     }

   bool AnalyzeTimeframe(MTFTrendState &state, const int index)
     {
      ulong calculation_started = GetTickCount64();
      int left_bars = SwingLeftBars(state);
      int right_bars = SwingRightBars(state);
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      int copied = CopyRates(_Symbol, state.timeframe, 0,
                             state.lookback, rates);
      int minimum_bars = left_bars + right_bars +
                         MTFInpATRPeriod + 5;
      if(copied < minimum_bars)
        {
         state.data_ready = false;
         state.structure = "WAIT FOR HISTORY";
         if(MTFInpDiagnosticLogging)
            Print("MTF analysis: insufficient ", state.tag,
                  " history on ", _Symbol, ". Copied ", copied,
                  " bars; need ", minimum_bars, ".");
         return false;
        }

      double atr_values[];
      ArraySetAsSeries(atr_values, true);
      int atr_copied = m_atr_handles[index] == INVALID_HANDLE ? 0 :
                       CopyBuffer(m_atr_handles[index], 0, 0,
                                  copied, atr_values);

      ResetState(state);
      state.current_bar = rates[0].time;

      MTFSwingPoint highs[];
      MTFSwingPoint lows[];
      ArrayResize(highs, 0);
      ArrayResize(lows, 0);
      int oldest_confirmation_bar = copied - 1 -
                                    left_bars - right_bars;
      if(oldest_confirmation_bar < 1)
         return false;

      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);

      for(int bar = oldest_confirmation_bar; bar >= 1; bar--)
        {
         double atr = GetATRValue(m_atr_handles[index], atr_values,
                                  atr_copied, rates, copied, bar);
         if(atr <= 0.0)
            atr = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10.0;
         double break_buffer = MTFInpBreakBufferPoints * point +
                               MTFInpBreakBufferATR * atr;
         double candle_body = MathAbs(rates[bar].close - rates[bar].open);
         bool body_ok = MTFInpMinimumBreakBodyATR <= 0.0 ||
                        candle_body >= MTFInpMinimumBreakBodyATR * atr;

         bool break_up = !state.high_broken && state.latest_high.valid && body_ok &&
                         rates[bar].close > state.latest_high.price + break_buffer;
         bool break_down = !state.low_broken && state.latest_low.valid && body_ok &&
                           rates[bar].close < state.latest_low.price - break_buffer;
         if(break_up || break_down)
           {
            int direction = break_up ? 1 : -1;
            bool reversal = state.direction != 0 ?
                            direction != state.direction :
                            (state.break_bias != 0 &&
                             direction != state.break_bias);
            bool displacement = reversal && atr > 0.0 &&
                                candle_body >= MTFInpMSSBodyATR * atr;
            MTFStructureEvent event;
            ResetEvent(event);
            event.valid = true;
            event.timeframe = state.timeframe;
            event.direction = direction;
            event.event_type = !reversal ? MTF_EVENT_BOS :
                               (displacement ? MTF_EVENT_MSS : MTF_EVENT_CHOCH);
            event.reversal_warning = reversal;
            event.break_time = rates[bar].time;
            event.swing_time = break_up ? state.latest_high.time :
                                          state.latest_low.time;
            event.break_level = break_up ? state.latest_high.price :
                                          state.latest_low.price;
            event.break_close = rates[bar].close;
            event.atr = atr;
            RecordEvent(state, direction, event);
            if(break_up) state.high_broken = true;
            if(break_down) state.low_broken = true;

            if(MTFInpShowHistoricalEvents &&
               bar <= MTFInpHistoricalBars)
               DrawEvent(state, event);
            if(MTFInpDiagnosticLogging && bar == 1)
               PrintFormat("%s %s %s level=%.*f break-time=%s close=%.*f",
                           state.tag, TimeframeText(state.timeframe),
                           EventName(event.event_type), _Digits,
                           event.break_level, EventTimeText(event.break_time),
                           _Digits, event.break_close);
           }

         int pivot = bar + right_bars;
         if(IsPivotHigh(rates, copied, pivot,
                        left_bars, right_bars))
           {
            double pivot_atr = GetATRValue(m_atr_handles[index], atr_values,
                                           atr_copied, rates, copied, pivot);
            MTFSwingPoint swing;
            ResetSwing(swing);
            swing.valid = true;
            swing.timeframe = state.timeframe;
            swing.is_high = true;
            swing.time = rates[pivot].time;
            swing.shift = pivot;
            swing.price = rates[pivot].high;
            PushAndClassifySwing(state, highs, swing, pivot_atr, true);
           }
         if(IsPivotLow(rates, copied, pivot,
                       left_bars, right_bars))
           {
            double pivot_atr = GetATRValue(m_atr_handles[index], atr_values,
                                           atr_copied, rates, copied, pivot);
            MTFSwingPoint swing;
            ResetSwing(swing);
            swing.valid = true;
            swing.timeframe = state.timeframe;
            swing.is_high = false;
            swing.time = rates[pivot].time;
            swing.shift = pivot;
            swing.price = rates[pivot].low;
            PushAndClassifySwing(state, lows, swing, pivot_atr, false);
           }
        }

      state.atr = GetATRValue(m_atr_handles[index], atr_values,
                              atr_copied, rates, copied, 1);
      if(state.atr <= 0.0)
         state.atr = ATRAt(rates, copied, 1, MTFInpATRPeriod);
      double tolerance = MathMax(MTFInpLevelTolerancePoints * point,
                                 MTFInpLevelToleranceATR * state.atr);
      tolerance = MathMax(tolerance, point * 2.0);
      double level_break_buffer = MTFInpBreakBufferPoints * point +
                                  MTFInpBreakBufferATR * state.atr;
      FindCluster(lows, ArraySize(lows), true, rates[1].close,
                  tolerance, state.support);
      FindCluster(highs, ArraySize(highs), false, rates[1].close,
                  tolerance, state.resistance);
      if(state.support.valid)
        {
         state.support.broken = rates[1].close <
                                state.support.price - level_break_buffer;
         state.support.invalidated = rates[1].close < state.support.low -
                                     MTFInpLevelInvalidationATR * state.atr;
        }
      if(state.resistance.valid)
        {
         state.resistance.broken = rates[1].close >
                                   state.resistance.price + level_break_buffer;
         state.resistance.invalidated = rates[1].close > state.resistance.high +
                                        MTFInpLevelInvalidationATR * state.atr;
        }

      double equal_tolerance = MathMax(MTFInpEqualSwingTolerancePoints * point,
                                       MTFInpEqualSwingToleranceATR * state.atr);
      UpdateStructureDirection(state, equal_tolerance);
      double liquidity_tolerance = MathMax(MTFInpLiquidityTolerancePoints * point,
                                           MTFInpLiquidityToleranceATR * state.atr);
      FindEqualLiquidity(highs, ArraySize(highs), liquidity_tolerance,
                         rates[1].close, true, state.equal_highs);
      FindEqualLiquidity(lows, ArraySize(lows), liquidity_tolerance,
                         rates[1].close, false, state.equal_lows);
      FindReactionZone(lows, rates, copied, true, state.demand);
      FindReactionZone(highs, rates, copied, false, state.supply);
      FindLiquiditySweep(state, rates, level_break_buffer);
      DrawTrendline(state, index, rates[1]);
      DrawLevelZone(state, state.support, true, index);
      DrawLevelZone(state, state.resistance, false, index);
      // Replace only the small, current liquidity/zone object groups. Confirmed
      // swing and historical event objects retain stable time-based names.
      ObjectsDeleteAll(0, m_prefix + state.tag + "_LIQ_", 0, -1);
      ObjectsDeleteAll(0, m_prefix + state.tag + "_LABEL_LIQ_", 0, -1);
      ObjectsDeleteAll(0, m_prefix + state.tag + "_ZONE_DEMAND_", 0, -1);
      ObjectsDeleteAll(0, m_prefix + state.tag + "_ZONE_SUPPLY_", 0, -1);
      ObjectsDeleteAll(0, m_prefix + state.tag + "_LABEL_DEMAND_", 0, -1);
      ObjectsDeleteAll(0, m_prefix + state.tag + "_LABEL_SUPPLY_", 0, -1);
      DrawReactionZone(state, state.demand, true, index);
      DrawReactionZone(state, state.supply, false, index);
      DrawLiquidityLevel(state, state.equal_highs, true, index);
       DrawLiquidityLevel(state, state.equal_lows, false, index);
      if(!MTFInpShowHistoricalEvents)
        {
         ObjectsDeleteAll(0, m_prefix + state.tag + "_LEVEL_", 0, -1);
         ObjectsDeleteAll(0, m_prefix + state.tag + "_LABEL_" +
                          state.tag + "_EV_", 0, -1);
        }
      if(!MTFInpShowHistoricalEvents && state.latest_event.valid)
         DrawEvent(state, state.latest_event);
       if(state.latest_reversal_event.valid &&
          (!state.latest_event.valid ||
           state.latest_reversal_event.break_time != state.latest_event.break_time))
          DrawEvent(state, state.latest_reversal_event);
       ApplyTimeframeVisibility(index);

      state.data_ready = true;
      state.current_bar = rates[0].time;
      if(MTFInpDiagnosticLogging)
        {
         int elapsed_ms = (int)(GetTickCount64() - calculation_started);
         string high_text = state.latest_high.valid ?
                            DoubleToString(state.latest_high.price, _Digits) +
                            " @ " + EventTimeText(state.latest_high.time) : "n/a";
         string low_text = state.latest_low.valid ?
                           DoubleToString(state.latest_low.price, _Digits) +
                           " @ " + EventTimeText(state.latest_low.time) : "n/a";
         string demand_text = state.demand.valid ?
                              DoubleToString(state.demand.low, _Digits) + "-" +
                              DoubleToString(state.demand.high, _Digits) : "n/a";
         string supply_text = state.supply.valid ?
                              DoubleToString(state.supply.low, _Digits) + "-" +
                              DoubleToString(state.supply.high, _Digits) : "n/a";
         PrintFormat("%s calculation %d ms | %s | direction=%d | H=%s | L=%s | %s | demand=%s | supply=%s | objects=%s_*",
                     state.tag, elapsed_ms, state.structure, state.direction,
                     high_text, low_text, EventDetail(state), demand_text,
                     supply_text, m_prefix + state.tag);
        }
      return true;
     }

   void CreateATRHandles()
     {
      for(int i = 0; i < 3; i++)
        {
         m_atr_handles[i] = iATR(_Symbol, m_states[i].timeframe,
                                 MTFInpATRPeriod);
         if(m_atr_handles[i] == INVALID_HANDLE)
            Print("MTF analysis: cannot create ATR handle for ",
                  m_states[i].tag, ". Manual ATR fallback will be used.");
        }
      m_handles_ready = true;
     }

   void ReleaseATRHandles()
     {
      for(int i = 0; i < 3; i++)
        {
         if(m_atr_handles[i] != INVALID_HANDLE)
           {
            IndicatorRelease(m_atr_handles[i]);
            m_atr_handles[i] = INVALID_HANDLE;
           }
        }
      m_handles_ready = false;
     }

   string LevelText(const MTFLevel &level,
                    const string caption)
     {
      if(!level.valid)
         return caption + " n/a";
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      string status = level.invalidated ? "INVALIDATED" :
                      (level.broken ? "BROKEN" :
                       (level.tests >= MTFInpMinimumLevelTests ? "ACTIVE" : "CANDIDATE"));
      if(m_panel_width < 580)
         return caption + " " + DoubleToString(level.low, digits) + "-" +
                DoubleToString(level.high, digits) + " " +
                (level.invalidated ? "INV" :
                 (level.broken ? "BRK" : "ACT")) +
                IntegerToString(level.tests) + "x";
      return caption + " " + DoubleToString(level.low, digits) + "-" +
             DoubleToString(level.high, digits) + " " + status + " " +
             IntegerToString(level.tests) + "x";
     }

   int FinalDirection(string &status, string &reason)
     {
      status = "INSUFFICIENT DATA";
      reason = "Waiting for confirmed D1, H4 and H1 history.";
      if(!m_states[0].data_ready || !m_states[1].data_ready ||
         !m_states[2].data_ready)
         return 0;

      int d1 = m_states[2].direction;
      int h4 = m_states[1].direction;
      int h1 = m_states[0].direction;
      if(d1 == 0 || h4 == 0)
        {
         status = "RANGE / WAIT";
         reason = "D1 or H4 has no confirmed HH/HL or LH/LL direction.";
         return 0;
        }
      if(d1 != h4)
        {
         status = "CONFLICTING";
         reason = "D1 and H4 directions are not aligned.";
         return 0;
        }
      if(m_states[2].latest_event.valid &&
         m_states[2].latest_event.reversal_warning &&
         m_states[2].latest_event.direction != d1)
        {
         status = "WAIT";
         reason = "D1 has an opposing CHoCH/MSS warning; major trend has not reversed.";
         return 0;
        }
      if(m_states[1].latest_event.valid &&
         m_states[1].latest_event.reversal_warning &&
         m_states[1].latest_event.direction != h4)
        {
         status = "WAIT";
         reason = "H4 has an opposing CHoCH/MSS warning; structure needs confirmation.";
         return 0;
        }
      int higher_direction = d1;
      if(m_states[0].latest_event.valid &&
         m_states[0].latest_event.reversal_warning &&
         m_states[0].latest_event.direction != higher_direction)
        {
         status = "WAIT";
         reason = "H1 has an opposite CHoCH/MSS warning; trend has not confirmed a reversal.";
         return 0;
        }
      if(h1 == 0)
        {
         status = "WAIT";
         reason = "H1 structure is mixed or unconfirmed.";
         return 0;
        }
      if(h1 != higher_direction)
        {
         status = "WAIT";
         reason = "H1 direction conflicts with aligned D1 and H4 structure.";
         return 0;
        }

      status = higher_direction > 0 ? "BUY BIAS" : "SELL BIAS";
      reason = "D1, H4 and H1 confirmed structure agree; location alone is not an entry.";
      return higher_direction;
     }

   string RegimeText(const MTFTrendState &state)
     {
      if(!state.data_ready)
         return "INSUFFICIENT DATA";
      if(state.latest_event.valid && state.latest_event.reversal_warning &&
         state.latest_event.direction != state.direction)
         return "TRANSITION";
      if(state.direction > 0)
         return "BULLISH";
      if(state.direction < 0)
         return "BEARISH";
      if(StringFind(state.structure, "MIXED") >= 0)
         return "RANGE";
      return "TRANSITION";
     }

   string H4ConfirmationText()
     {
      if(!m_states[1].data_ready || !m_states[2].data_ready)
         return "INSUFFICIENT DATA";
      int h4 = m_states[1].direction;
      int d1 = m_states[2].direction;
      if(h4 == 0)
         return StringFind(m_states[1].structure, "MIXED") >= 0 ?
                "RANGE" : "TRANSITION";
      if(m_states[1].latest_event.valid &&
         m_states[1].latest_event.reversal_warning &&
         m_states[1].latest_event.direction != h4)
         return "TRANSITION";
      if(d1 == 0)
         return "D1 UNCONFIRMED";
      if(h4 != d1)
         return "COUNTER-TREND";
      return h4 > 0 ? "BULLISH CONFIRMATION" : "BEARISH CONFIRMATION";
     }

   string PremiumDiscountTextForState(const MTFTrendState &state)
     {
      if(!state.latest_high.valid || !state.latest_low.valid)
         return "RANGE N/A";
      double high = MathMax(state.latest_high.price, state.latest_low.price);
      double low = MathMin(state.latest_high.price, state.latest_low.price);
      if(high <= low)
         return "RANGE N/A";
      double midpoint = (high + low) * 0.5;
      double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(price <= 0.0)
         return "PRICE N/A";
      double equilibrium_band = MathMax(state.atr * 0.05,
                                        SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 2.0);
      if(MathAbs(price - midpoint) <= equilibrium_band)
         return "EQUILIBRIUM";
      return price > midpoint ? "PREMIUM" : "DISCOUNT";
     }

   string PremiumDiscountText()
     {
      return PremiumDiscountTextForState(m_states[2]);
     }

   string ZoneRangeText(const MTFReactionZone &zone,
                        const string caption)
     {
      if(!zone.valid)
         return caption + " n/a";
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      return caption + " " + DoubleToString(zone.low, digits) + "-" +
             DoubleToString(zone.high, digits) +
             " [" + IntegerToString(zone.tests) + " touches]" +
             (zone.invalidated ? " INVALID" : "");
     }

   string EventDetail(const MTFTrendState &state)
     {
      if(!state.latest_event.valid)
          return "No confirmed BOS / CHoCH";
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      string side = state.latest_event.direction > 0 ? "UP" : "DOWN";
       return EventName(state.latest_event.event_type) + " " + side +
              " @ " + DoubleToString(state.latest_event.break_level, digits);
     }

   string ReversalDetail(const MTFTrendState &state)
     {
      if(!state.latest_reversal_event.valid)
         return "CHoCH / MSS: none in history";
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      string event_name = state.latest_reversal_event.event_type == MTF_EVENT_MSS ?
                          "MSS / CHoCH" : "CHoCH";
      string side = state.latest_reversal_event.direction > 0 ? "UP" : "DOWN";
      return event_name + " " + side + " @ " +
             DoubleToString(state.latest_reversal_event.break_level, digits) +
             " " + TimeToString(state.latest_reversal_event.break_time, TIME_DATE);
     }

   string ShortReversalDetail(const MTFTrendState &state)
     {
      if(!state.latest_reversal_event.valid)
         return "No CHoCH / MSS";
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      string event_name = state.latest_reversal_event.event_type == MTF_EVENT_MSS ?
                          "MSS" : "CHoCH";
      string side = state.latest_reversal_event.direction > 0 ? "UP" : "DOWN";
      return event_name + " " + side + " " +
             DoubleToString(state.latest_reversal_event.break_level, digits);
     }

   string TrendlineDetail(const MTFTrendState &state)
     {
      if(!state.data_ready)
         return "Trendline: waiting for data";
      if(!MTFInpShowTrendlines)
         return "Trendline display: off";
      if(!state.trendline_valid)
         return "No confirmed swing trendline";
      if(!state.trendline_broken)
         return "Trendline intact";
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      string side = state.trendline_break_direction > 0 ? "UP" : "DOWN";
      return "Trendline BROKE " + side + " @ " +
             DoubleToString(state.trendline_break_price, digits) + " " +
             TimeToString(state.trendline_break_time, TIME_DATE);
     }

   string ShortZoneText(const MTFReactionZone &zone,
                        const string caption)
     {
      if(!zone.valid)
         return caption + " n/a";
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      return caption + " " + DoubleToString(zone.low, digits) + "-" +
             DoubleToString(zone.high, digits) +
             (zone.invalidated ? " invalid" : "");
     }

   string ShortLevelPairText(const MTFTrendState &state)
     {
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      return "S " + (state.support.valid ?
                     DoubleToString(state.support.price, digits) : "n/a") +
             " / R " + (state.resistance.valid ?
                       DoubleToString(state.resistance.price, digits) : "n/a");
     }

   string LevelPairText(const MTFTrendState &state)
     {
      return LevelText(state.support, "S") + " | " +
             LevelText(state.resistance, "R");
     }

   bool NearZone(const double price,
                 const MTFReactionZone &zone,
                 const double atr)
     {
      if(!zone.valid || zone.invalidated)
         return false;
      double padding = MathMax(atr * 0.15,
                              SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 5.0);
      return price >= zone.low - padding && price <= zone.high + padding;
     }

   double ZoneDistanceATR(const double price,
                          const MTFReactionZone &zone,
                          const double atr)
     {
      if(!zone.valid || atr <= 0.0)
         return -1.0;
      if(price >= zone.low && price <= zone.high)
         return 0.0;
      double edge_distance = price < zone.low ? zone.low - price :
                                                price - zone.high;
      return edge_distance / atr;
     }

   string HigherZoneDistances(const double price)
     {
      MTFTrendState d1 = m_states[2];
      MTFTrendState h4 = m_states[1];
      double dd = ZoneDistanceATR(price, d1.demand, d1.atr);
      double ds = ZoneDistanceATR(price, d1.supply, d1.atr);
      double hd = ZoneDistanceATR(price, h4.demand, h4.atr);
      double hs = ZoneDistanceATR(price, h4.supply, h4.atr);
      string result = "DIST ATR D1 D";
      result += dd < 0.0 ? "n/a" : DoubleToString(dd, 1);
      result += "/S";
      result += ds < 0.0 ? "n/a" : DoubleToString(ds, 1);
      result += " | H4 D";
      result += hd < 0.0 ? "n/a" : DoubleToString(hd, 1);
      result += "/S";
      result += hs < 0.0 ? "n/a" : DoubleToString(hs, 1);
      return result;
     }

   string TradingLocation()
     {
      if(!m_states[0].data_ready || !m_states[1].data_ready ||
         !m_states[2].data_ready)
         return "INSUFFICIENT DATA";
      double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(price <= 0.0)
         return "NO LIVE PRICE";
      MTFTrendState h1 = m_states[0];
      MTFTrendState h4 = m_states[1];
      MTFTrendState d1 = m_states[2];
      if(h1.sweep_valid)
         return h1.sweep_direction > 0 ? "LIQUIDITY RECLAIM UP (CLOSED H1)" :
                                         "LIQUIDITY RECLAIM DOWN (CLOSED H1)";
      if(h1.wick_sweep)
         return "WICK SWEEP - WAIT FOR H1 CLOSE";
      if(NearZone(price, d1.demand, d1.atr)) return "NEAR D1 DEMAND";
      if(NearZone(price, d1.supply, d1.atr)) return "NEAR D1 SUPPLY";
      if(NearZone(price, h4.demand, h4.atr)) return "NEAR H4 DEMAND";
      if(NearZone(price, h4.supply, h4.atr)) return "NEAR H4 SUPPLY";
      if(NearZone(price, h1.demand, h1.atr)) return "NEAR H1 DEMAND";
      if(NearZone(price, h1.supply, h1.atr)) return "NEAR H1 SUPPLY";
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double d1_tol = MathMax(d1.atr * MTFInpLevelToleranceATR, point * 5.0);
      double h4_tol = MathMax(h4.atr * MTFInpLevelToleranceATR, point * 5.0);
      double h1_tol = MathMax(h1.atr * MTFInpLevelToleranceATR, point * 5.0);
      if(d1.support.valid && MathAbs(price - d1.support.price) <= d1_tol)
         return "NEAR D1 SUPPORT";
      if(d1.resistance.valid && MathAbs(price - d1.resistance.price) <= d1_tol)
         return "NEAR D1 RESISTANCE";
      if(h4.support.valid && MathAbs(price - h4.support.price) <= h4_tol)
         return "NEAR H4 SUPPORT";
      if(h4.resistance.valid && MathAbs(price - h4.resistance.price) <= h4_tol)
         return "NEAR H4 RESISTANCE";
      if(h1.support.valid && MathAbs(price - h1.support.price) <= h1_tol)
         return "NEAR H1 SUPPORT";
      if(h1.resistance.valid && MathAbs(price - h1.resistance.price) <= h1_tol)
         return "NEAR H1 RESISTANCE";
      bool any_zone = d1.demand.valid || d1.supply.valid || h4.demand.valid ||
                      h4.supply.valid || h1.demand.valid || h1.supply.valid;
      return any_zone ? "BETWEEN ZONES" : "NO CLEAR LOCATION";
     }

   void UpdateLiveH1WickSweep()
     {
      if(!m_states[0].data_ready)
         return;
      MqlRates live[];
      ArraySetAsSeries(live, true);
      if(CopyRates(_Symbol, PERIOD_H1, 0, 1, live) != 1)
         return;
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double buffer = MTFInpBreakBufferPoints * point +
                      MTFInpBreakBufferATR * m_states[0].atr;
      double ssl = m_states[0].equal_lows.valid ?
                   m_states[0].equal_lows.price :
                   (m_states[0].latest_low.valid ?
                    m_states[0].latest_low.price : 0.0);
      double bsl = m_states[0].equal_highs.valid ?
                   m_states[0].equal_highs.price :
                   (m_states[0].latest_high.valid ?
                    m_states[0].latest_high.price : 0.0);
      m_states[0].wick_sweep = false;
      if(ssl > 0.0 && live[0].low < ssl - buffer)
        {
         m_states[0].wick_sweep = true;
         m_states[0].wick_sweep_direction = 1;
         m_states[0].wick_sweep_level = ssl;
        }
      else if(bsl > 0.0 && live[0].high > bsl + buffer)
        {
         m_states[0].wick_sweep = true;
         m_states[0].wick_sweep_direction = -1;
         m_states[0].wick_sweep_level = bsl;
        }
     }

   string AlgoStateText()
     {
      bool algo_allowed = TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) &&
                          MQLInfoInteger(MQL_TRADE_ALLOWED) &&
                          AccountInfoInteger(ACCOUNT_TRADE_ALLOWED);
      return "EA ATTACHED | ANALYSIS RUNNING | ALGO " +
             (algo_allowed ? "PERMISSION ON" : "PERMISSION OFF") +
             " | AUTO TRADING OFF";
     }

   bool CreateOrMoveLabel(const string name,
                          const string text,
                          const int x,
                          const int y,
                          const color c,
                          const int font_size)
     {
      if(ObjectFind(0, name) < 0 && !ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0))
         return false;
      ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
      ObjectSetInteger(0, name, OBJPROP_COLOR, c);
      ObjectSetInteger(0, name, OBJPROP_FONTSIZE, font_size);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, name, OBJPROP_ZORDER, 120);
      ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      ObjectSetString(0, name, OBJPROP_FONT, "Arial");
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      return true;
     }

    bool CreatePanelBox(const string name,
                        const int x,
                        const int y,
                        const int width,
                        const int height,
                        const color background,
                        const color border)
      {
       if(ObjectFind(0, name) < 0 &&
          !ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0))
          return false;
       ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
       ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
       ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
       ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
       ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
       ObjectSetInteger(0, name, OBJPROP_BGCOLOR, background);
       ObjectSetInteger(0, name, OBJPROP_COLOR, border);
       ObjectSetInteger(0, name, OBJPROP_BACK, false);
       ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
       ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
       ObjectSetInteger(0, name, OBJPROP_ZORDER, 100);
       ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
       return true;
      }

    bool CreatePanelButton(const string name,
                           const string text,
                           const int x,
                           const int y,
                           const int width,
                           const int height,
                           const color background,
                           const color foreground)
      {
       if(ObjectFind(0, name) < 0 &&
          !ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0))
          return false;
       ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
       ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
       ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
       ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
       ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
       ObjectSetInteger(0, name, OBJPROP_BGCOLOR, background);
       ObjectSetInteger(0, name, OBJPROP_COLOR, foreground);
       ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, C'77,91,108');
       ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
       ObjectSetString(0, name, OBJPROP_FONT, "Arial");
       ObjectSetString(0, name, OBJPROP_TEXT, text);
       ObjectSetInteger(0, name, OBJPROP_STATE, false);
       ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
       ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
       ObjectSetInteger(0, name, OBJPROP_ZORDER, 135);
       ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
       return true;
      }

    void SetPanelCard(const int index,
                      const string title,
                      const color title_color,
                      string &lines[],
                      const int line_count,
                      const int x,
                      const int y,
                      const int width,
                      const int height,
                      const bool compact)
      {
       string card_name = m_prefix + "PANEL_CARD_" + IntegerToString(index);
       CreatePanelBox(card_name, x, y, width, height,
                      C'35,42,54', C'67,79,94');
       string title_name = m_prefix + "PANEL_CARD_TITLE_" + IntegerToString(index);
       CreateOrMoveLabel(title_name, title, x + 8, y + 5, title_color, 9);
        int visible_lines = compact ? 0 :
                            (int)MathMin(line_count, MathMax(0, (height - 18) / 14));
       int max_chars = (int)MathMax(10,
                           (width - 16) / MathMax(5, MTFInpDashboardFontSize * 6 / 10));
       if(compact)
         {
          string compact_text = title + "  " + lines[0];
          if(StringLen(compact_text) > max_chars)
             compact_text = StringSubstr(compact_text, 0, max_chars - 3) + "...";
          CreateOrMoveLabel(title_name, compact_text, x + 8, y + 6,
                            title_color, 8);
         }
       else
          CreateOrMoveLabel(title_name, title, x + 8, y + 5, title_color, 9);
       for(int row = 0; row < 8; row++)
         {
          string label_name = m_prefix + "PANEL_CARD_" + IntegerToString(index) +
                              "_LINE_" + IntegerToString(row);
          if(row >= visible_lines)
            {
             if(ObjectFind(0, label_name) >= 0)
                ObjectSetInteger(0, label_name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
             continue;
            }
          string line = lines[row];
          if(StringLen(line) > max_chars)
             line = StringSubstr(line, 0, max_chars - 3) + "...";
           int font = compact ? 8 : (int)MathMax(8, MTFInpDashboardFontSize - 1);
           color line_color = StringFind(line, "CHoCH") >= 0 ||
                              StringFind(line, "MSS") >= 0 ? clrOrange : clrWhite;
          CreateOrMoveLabel(label_name, line, x + 8, y + 22 + row * 14,
                             line_color, font);
         }
      }

    bool SetSplitLine(const string name, const double price, const color line_color,
                      const ENUM_LINE_STYLE style, const string label)
      {
       if(m_analysis_chart_id <= 0)
          return false;
       if(price <= 0.0 || !MathIsValidNumber(price))
         {
          ObjectDelete(m_analysis_chart_id, name);
          return false;
         }
       if(ObjectFind(m_analysis_chart_id, name) < 0 &&
          !ObjectCreate(m_analysis_chart_id, name, OBJ_HLINE, 0, 0, price))
          return false;
       bool ok = ObjectSetDouble(m_analysis_chart_id, name, OBJPROP_PRICE, price);
       ok = ObjectSetInteger(m_analysis_chart_id, name, OBJPROP_COLOR, line_color) && ok;
       ok = ObjectSetInteger(m_analysis_chart_id, name, OBJPROP_STYLE, style) && ok;
       ok = ObjectSetInteger(m_analysis_chart_id, name, OBJPROP_WIDTH, 1) && ok;
       ok = ObjectSetString(m_analysis_chart_id, name, OBJPROP_TEXT,
                            label + " " + DoubleToString(price, _Digits)) && ok;
       ok = ObjectSetInteger(m_analysis_chart_id, name, OBJPROP_SELECTABLE, false) && ok;
       ok = ObjectSetInteger(m_analysis_chart_id, name, OBJPROP_HIDDEN, true) && ok;
       return ok;
      }

    bool SetSplitZone(const string name, const double low, const double high,
                      const datetime created, const color zone_color,
                      const string label)
      {
       if(m_analysis_chart_id <= 0)
          return false;
       if(low <= 0.0 || high <= low)
         {
          ObjectDelete(m_analysis_chart_id, name);
          return false;
         }
       datetime first_time = created > 0 ? created : iTime(_Symbol, PERIOD_M30, 20);
       datetime last_time = iTime(_Symbol, PERIOD_M30, 0);
       if(first_time <= 0 || last_time <= first_time)
          return false;
       if(ObjectFind(m_analysis_chart_id, name) < 0 &&
          !ObjectCreate(m_analysis_chart_id, name, OBJ_RECTANGLE, 0,
                        first_time, high, last_time, low))
          return false;
       bool ok = ObjectMove(m_analysis_chart_id, name, 0, first_time, high);
       ok = ObjectMove(m_analysis_chart_id, name, 1, last_time, low) && ok;
       ok = ObjectSetInteger(m_analysis_chart_id, name, OBJPROP_COLOR, zone_color) && ok;
       ok = ObjectSetInteger(m_analysis_chart_id, name, OBJPROP_STYLE, STYLE_DOT) && ok;
       ok = ObjectSetInteger(m_analysis_chart_id, name, OBJPROP_WIDTH, 1) && ok;
       ok = ObjectSetInteger(m_analysis_chart_id, name, OBJPROP_FILL, false) && ok;
       ok = ObjectSetInteger(m_analysis_chart_id, name, OBJPROP_BACK, true) && ok;
       ok = ObjectSetString(m_analysis_chart_id, name, OBJPROP_TEXT, label) && ok;
       ok = ObjectSetInteger(m_analysis_chart_id, name, OBJPROP_SELECTABLE, false) && ok;
       ok = ObjectSetInteger(m_analysis_chart_id, name, OBJPROP_HIDDEN, true) && ok;
       return ok;
      }

    void SetSplitPaneTag(const long chart_id,const string name,const string text,
                         const int x,const int y,const color text_color)
      {
       if(ObjectFind(chart_id,name)<0 && !ObjectCreate(chart_id,name,OBJ_LABEL,0,0,0))
          return;
       ObjectSetInteger(chart_id,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
       ObjectSetInteger(chart_id,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
       ObjectSetInteger(chart_id,name,OBJPROP_XDISTANCE,x);
       ObjectSetInteger(chart_id,name,OBJPROP_YDISTANCE,y);
       ObjectSetInteger(chart_id,name,OBJPROP_COLOR,text_color);
       ObjectSetInteger(chart_id,name,OBJPROP_FONTSIZE,8);
       ObjectSetInteger(chart_id,name,OBJPROP_BACK,false);
       ObjectSetInteger(chart_id,name,OBJPROP_SELECTABLE,false);
       ObjectSetInteger(chart_id,name,OBJPROP_HIDDEN,true);
       ObjectSetInteger(chart_id,name,OBJPROP_ZORDER,145);
       ObjectSetInteger(chart_id,name,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
       ObjectSetString(chart_id,name,OBJPROP_FONT,"Arial");
       ObjectSetString(chart_id,name,OBJPROP_TEXT,text);
      }

    void RenderEmbeddedChart(const int chart_width, const int chart_height,
                             const int chart_left)
      {
       string name = SplitChartName();
       if(ObjectFind(0, name) < 0 && !ObjectCreate(0, name, OBJ_CHART, 0, 0, 0))
         {
          m_analysis_chart_id = 0;
          Print("MTF dashboard: native embedded chart creation failed. Error ", GetLastError());
          return;
         }
       int chart_x = (int)MathMax(4,chart_left);
       int chart_y = 4;
       int chart_w = (int)MathMax(0, chart_width - chart_x - 4);
       int chart_h = (int)MathMax(0, chart_height - chart_y - 4);
       ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
       ObjectSetInteger(0, name, OBJPROP_XDISTANCE, chart_x);
       ObjectSetInteger(0, name, OBJPROP_YDISTANCE, chart_y);
       ObjectSetInteger(0, name, OBJPROP_XSIZE, chart_w);
       ObjectSetInteger(0, name, OBJPROP_YSIZE, chart_h);
       ObjectSetInteger(0, name, OBJPROP_BACK, false);
       ObjectSetInteger(0, name, OBJPROP_SELECTABLE, true);
       ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
       ObjectSetInteger(0, name, OBJPROP_ZORDER, 1);
       ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
       ObjectSetInteger(0, name, OBJPROP_COLOR, C'89,105,124');
       ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES,
                        chart_w >= 180 && chart_h >= 150 ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
       if(chart_w < 180 || chart_h < 150)
         {
          m_analysis_chart_id = 0;
          return;
         }
       long child_id = (long)ObjectGetInteger(0, name, OBJPROP_CHART_ID);
       if(child_id <= 0)
         {
          m_analysis_chart_id = 0;
          return;
         }
       m_analysis_chart_id = child_id;
       if(ChartSymbol(child_id) != _Symbol || ChartPeriod(child_id) != PERIOD_M30)
          ObjectSetString(0, name, OBJPROP_SYMBOL, _Symbol);
       if(ChartPeriod(child_id) != PERIOD_M30)
          ObjectSetInteger(0, name, OBJPROP_PERIOD, PERIOD_M30);
       ChartSetInteger(child_id, CHART_MODE, CHART_CANDLES);
       ChartSetInteger(child_id, CHART_SHOW_GRID, false);
       ChartSetInteger(child_id, CHART_SHOW_VOLUMES, CHART_VOLUME_HIDE);
       ChartSetInteger(child_id, CHART_SHOW_PERIOD_SEP, false);
       ChartSetInteger(child_id, CHART_SHOW_OBJECT_DESCR, true);
       ChartSetInteger(child_id, CHART_AUTOSCROLL, true);
       ChartSetInteger(child_id, CHART_SHIFT, true);
       SetSplitPaneTag(child_id,m_prefix+"SPLIT_PANE_TAG","EMBEDDED M30",8,8,C'143,201,255');
       string active_period=(_Period==PERIOD_M30 ? "ACTIVE M30" : "ACTIVE "+EnumToString(_Period));
       SetSplitPaneTag(0,m_prefix+"ACTIVE_PANE_TAG",active_period,
                       8,MathMax(8,chart_height-24),C'143,201,255');
       string divider=m_prefix+"PANEL_SPLIT_DIVIDER";
       if(ObjectFind(0,divider)<0) ObjectCreate(0,divider,OBJ_RECTANGLE_LABEL,0,0,0);
       ObjectSetInteger(0,divider,OBJPROP_CORNER,CORNER_LEFT_UPPER);
       ObjectSetInteger(0,divider,OBJPROP_XDISTANCE,MathMax(0,chart_x-3));
       ObjectSetInteger(0,divider,OBJPROP_YDISTANCE,4);
       ObjectSetInteger(0,divider,OBJPROP_XSIZE,3);
       ObjectSetInteger(0,divider,OBJPROP_YSIZE,chart_h);
       ObjectSetInteger(0,divider,OBJPROP_BGCOLOR,C'73,86,102');
       ObjectSetInteger(0,divider,OBJPROP_COLOR,C'73,86,102');
       ObjectSetInteger(0,divider,OBJPROP_SELECTABLE,false);
       ObjectSetInteger(0,divider,OBJPROP_HIDDEN,true);
       ObjectSetInteger(0,divider,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
       ChartRedraw(child_id);
       for(int i = 0; i < 3; i++)
         {
          if(!m_states[i].data_ready) continue;
          string prefix = m_prefix + "SPLIT_" + m_states[i].tag + "_";
          long mask = (m_master_drawings_enabled && m_show_markings[i]) ?
                      OBJ_ALL_PERIODS : OBJ_NO_PERIODS;
          if(!m_states[i].data_ready)
            {
             int stale_total = ObjectsTotal(child_id, 0, -1);
             for(int stale_index = stale_total - 1; stale_index >= 0; stale_index--)
               {
                string stale_name = ObjectName(child_id, stale_index, 0, -1);
                if(StringFind(stale_name, prefix) == 0)
                   ObjectSetInteger(child_id, stale_name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
               }
             continue;
            }
          color timeframe_color = i == 0 ? MTFInpH1Color : (i == 1 ? MTFInpH4Color : MTFInpD1Color);
          SetSplitLine(prefix + "SWING_H", m_states[i].latest_high.valid ? m_states[i].latest_high.price : 0.0,
                       timeframe_color, STYLE_DOT, m_states[i].tag + " Swing high");
          SetSplitLine(prefix + "SWING_L", m_states[i].latest_low.valid ? m_states[i].latest_low.price : 0.0,
                       timeframe_color, STYLE_DOT, m_states[i].tag + " Swing low");
          SetSplitLine(prefix + "SUPPORT", m_states[i].support.valid ? m_states[i].support.price : 0.0,
                       clrDeepSkyBlue, STYLE_DASH, m_states[i].tag + " Support");
          SetSplitLine(prefix + "RESISTANCE", m_states[i].resistance.valid ? m_states[i].resistance.price : 0.0,
                       clrOrangeRed, STYLE_DASH, m_states[i].tag + " Resistance");
          SetSplitLine(prefix + "EQH", m_states[i].equal_highs.valid ? m_states[i].equal_highs.price : 0.0,
                       clrViolet, STYLE_DOT, m_states[i].tag + " Equal highs / BSL");
          SetSplitLine(prefix + "EQL", m_states[i].equal_lows.valid ? m_states[i].equal_lows.price : 0.0,
                       clrViolet, STYLE_DOT, m_states[i].tag + " Equal lows / SSL");
          SetSplitLine(prefix + "EVENT", m_states[i].latest_event.valid ? m_states[i].latest_event.break_level : 0.0,
                       m_states[i].latest_event.direction > 0 ? clrLimeGreen : clrTomato,
                       STYLE_SOLID, m_states[i].tag + " " + EventName(m_states[i].latest_event.event_type));
          SetSplitLine(prefix + "REVERSAL", m_states[i].latest_reversal_event.valid ? m_states[i].latest_reversal_event.break_level : 0.0,
                       clrOrange, STYLE_DASH, m_states[i].tag + " CHoCH / reversal");
          SetSplitLine(prefix + "SWEEP", m_states[i].sweep_valid ? m_states[i].sweep_level : 0.0,
                       clrGold, STYLE_DASH, m_states[i].tag + " Liquidity sweep");
          SetSplitZone(prefix + "DEMAND", m_states[i].demand.low,
                       m_states[i].demand.high, m_states[i].demand.created,
                       clrSeaGreen, m_states[i].tag + " Demand");
          SetSplitZone(prefix + "SUPPLY", m_states[i].supply.low,
                       m_states[i].supply.high, m_states[i].supply.created,
                       clrIndianRed, m_states[i].tag + " Supply");
          int total = ObjectsTotal(child_id, 0, -1);
          for(int object_index = total - 1; object_index >= 0; object_index--)
            {
             string object_name = ObjectName(child_id, object_index, 0, -1);
             if(StringFind(object_name, prefix) == 0)
                ObjectSetInteger(child_id, object_name, OBJPROP_TIMEFRAMES, mask);
            }
         }
       ChartRedraw(child_id);
      }

    void RenderSplitDashboard()
      {
       long raw_width = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
       long raw_height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
       int chart_width = (int)(raw_width > 0 ? raw_width : 900);
       int chart_height = (int)(raw_height > 0 ? raw_height : 650);
       int available_width = MathMax(180, chart_width - 8);
       int available_height = MathMax(160, chart_height - 8);
       if(!m_panel_manual_size)
          m_panel_width = (int)MathRound(available_width * MTFInpDashboardWidthPercent / 100.0);
       int min_chart_width = MathMax(180, MTFInpChartMinimumWidth);
       int max_panel_width = available_width - min_chart_width - 4;
       if(max_panel_width < 210)
         {
          m_panel_width = (int)MathMax(180, available_width / 2);
         }
       else
         {
          int min_panel_width = MathMin(MTFInpDashboardMinWidth, max_panel_width);
          m_panel_width = (int)MathMax(min_panel_width, MathMin(m_panel_width, max_panel_width));
         }
      int panel_height = (int)MathMin(available_height, 650);
      m_panel_height = panel_height;
       int visible_height = m_dashboard_visible ? (m_dashboard_minimized ? 30 : panel_height) : 30;
       m_panel_x = (int)MathMax(4, MathMin(m_panel_x, chart_width - m_panel_width - min_chart_width - 4));
       m_panel_y = (int)MathMax(4, MathMin(m_panel_y, chart_height - panel_height - 4));
       int embedded_chart_left = m_dashboard_visible ? m_panel_x + m_panel_width + 4 : 4;
       if(m_dashboard_visible && m_dashboard_minimized)
          embedded_chart_left = m_panel_x + 86;
       RenderEmbeddedChart(chart_width, chart_height, embedded_chart_left);
       if(!m_dashboard_visible)
         {
          int total = ObjectsTotal(0, 0, -1);
          for(int i = total - 1; i >= 0; i--)
            {
             string object_name = ObjectName(0, i, 0, -1);
             if(StringFind(object_name, m_prefix + "PANEL_") == 0 && object_name != PanelShowName())
                ObjectSetInteger(0, object_name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
            }
          CreatePanelButton(PanelShowName(), "SHOW DASHBOARD", 4, 4, 145, 26, C'30,85,130', clrWhite);
          return;
         }
       ObjectDelete(0, PanelShowName());
       int rendered_panel_height = m_dashboard_minimized ? 30 : panel_height;
       CreatePanelBox(PanelBackgroundName(), m_panel_x, m_panel_y,
                      m_panel_width, rendered_panel_height, C'22,27,36', C'73,86,102');
       string header = PanelHeaderName();
       if(ObjectFind(0, header) < 0) ObjectCreate(0, header, OBJ_RECTANGLE_LABEL, 0, 0, 0);
       ObjectSetInteger(0, header, OBJPROP_CORNER, CORNER_LEFT_UPPER);
       ObjectSetInteger(0, header, OBJPROP_XDISTANCE, m_panel_x);
       ObjectSetInteger(0, header, OBJPROP_YDISTANCE, m_panel_y);
       ObjectSetInteger(0, header, OBJPROP_XSIZE, m_panel_width);
       ObjectSetInteger(0, header, OBJPROP_YSIZE, 26);
       ObjectSetInteger(0, header, OBJPROP_BGCOLOR, C'30,85,130');
       ObjectSetInteger(0, header, OBJPROP_COLOR, C'60,139,196');
       ObjectSetInteger(0, header, OBJPROP_BACK, false);
       ObjectSetInteger(0, header, OBJPROP_SELECTABLE, true);
       ObjectSetInteger(0, header, OBJPROP_SELECTED, false);
       ObjectSetInteger(0, header, OBJPROP_HIDDEN, true);
       ObjectSetInteger(0, header, OBJPROP_ZORDER, 125);
       ObjectSetInteger(0, header, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
       CreateOrMoveLabel(m_prefix + "PANEL_TITLE",
                         m_panel_width < 480 ? "M30 ANALYSIS" : _Symbol + " M30 ANALYSIS",
                         m_panel_x + 9, m_panel_y + 4, clrWhite, 9);
       int button_y = m_panel_y + 3;
       CreatePanelButton(PanelBotName(), m_bot_enabled ? "BOT STARTED" : "BOT STOPPED",
                         m_panel_x + m_panel_width - 94, button_y, 86, 20,
                         m_bot_enabled ? C'35,91,69' : C'115,48,48', clrWhite);
       CreatePanelButton(PanelMinimizeName(), m_dashboard_minimized ? "+" : "-",
                         m_panel_x + m_panel_width - 124, button_y, 24, 20, C'42,57,73', clrWhite);
       CreatePanelButton(PanelShowName(), "HIDE", m_panel_x + m_panel_width - 194,
                         button_y, 60, 20, C'42,57,73', clrWhite);
       CreatePanelButton(PanelCompactName(), m_dashboard_expanded ? "COMPACT" : "EXPAND",
                         m_panel_x + m_panel_width - 264, button_y, 64, 20,
                         C'42,57,73', clrWhite);
       if(m_dashboard_minimized)
         {
          int total = ObjectsTotal(0, 0, -1);
          for(int i = total - 1; i >= 0; i--)
            {
             string object_name = ObjectName(0, i, 0, -1);
             if(StringFind(object_name, m_prefix + "PANEL_") != 0) continue;
             if(object_name == PanelBackgroundName() || object_name == PanelHeaderName() ||
                object_name == m_prefix + "PANEL_TITLE" || object_name == PanelBotName() ||
                object_name == PanelMinimizeName() || object_name == PanelShowName() ||
                object_name == PanelCompactName())
                ObjectSetInteger(0, object_name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
             else ObjectSetInteger(0, object_name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
            }
          return;
         }

       bool compact = (!m_dashboard_expanded || panel_height < 610 || m_panel_width < 440);
       int inner_x = m_panel_x + 8;
       int inner_width = m_panel_width - 16;
       int top_y = m_panel_y + 31;
       int card_height = compact ? 66 : 80;
       int card_gap = 4;
       int card_width = (inner_width - 2 * card_gap) / 3;
       MTFTrendState d1 = m_states[2];
       MTFTrendState h4 = m_states[1];
       MTFTrendState h1 = m_states[0];
       string d1_lines[8], h4_lines[8], h1_lines[8];
       d1_lines[0] = RegimeText(d1) + " " + d1.structure;
       d1_lines[1] = "H " + (d1.latest_high.valid ? DoubleToString(d1.latest_high.price, _Digits) : "N/A") +
                     " L " + (d1.latest_low.valid ? DoubleToString(d1.latest_low.price, _Digits) : "N/A");
       d1_lines[2] = ShortZoneText(d1.demand, "D") + " | " + ShortZoneText(d1.supply, "S");
       h4_lines[0] = RegimeText(h4) + " " + h4.structure;
       h4_lines[1] = "D1 " + (h4.direction == d1.direction ? "ALIGNED" : "CONFLICT");
       h4_lines[2] = ShortLevelPairText(h4);
       h1_lines[0] = RegimeText(h1) + " " + h1.structure;
       h1_lines[1] = "Location " + TradingLocation();
       h1_lines[2] = ShortLevelPairText(h1);
       SetPanelCard(0, "D1 | BIAS", MTFInpD1Color, d1_lines, 3,
                    inner_x, top_y, card_width, card_height, false);
       SetPanelCard(1, "H4 | CONTEXT", MTFInpH4Color, h4_lines, 3,
                    inner_x + card_width + card_gap, top_y, card_width, card_height, false);
       SetPanelCard(2, "H1 | LOCATION", MTFInpH1Color, h1_lines, 3,
                    inner_x + (card_width + card_gap) * 2, top_y, card_width, card_height, false);

       int y = top_y + card_height + 5;
       int score_height = compact ? 42 : 48;
       CreatePanelBox(m_prefix + "PANEL_M30_SCORE_BG", inner_x, y, inner_width,
                      score_height, C'28,36,47', C'67,79,94');
       string score_text = "BUY / SELL EVIDENCE | " + m_m30_dashboard_summary;
       int max_summary = MathMax(24, inner_width / 7);
       if(StringLen(score_text) > max_summary) score_text = StringSubstr(score_text, 0, max_summary - 3) + "...";
       CreateOrMoveLabel(m_prefix + "PANEL_M30_SCORE_TITLE", score_text,
                         inner_x + 8, y + 5, clrDeepSkyBlue, 8);
       string reason_summary = "STATUS / REASON | " + m_m30_dashboard_reason;
       if(StringLen(reason_summary) > max_summary) reason_summary = StringSubstr(reason_summary, 0, max_summary - 3) + "...";
       CreateOrMoveLabel(m_prefix + "PANEL_M30_SCORE_LINE", reason_summary,
                         inner_x + 8, y + 23, clrWhite, 8);

       y += score_height + 4;
       CreatePanelBox(m_prefix + "PANEL_M30_STRATEGIES_BG", inner_x, y,
                      inner_width, compact ? 152 : 184, C'28,36,47', C'67,79,94');
       CreateOrMoveLabel(m_prefix + "PANEL_M30_STRATEGIES_TITLE",
                         "TEN M30 STRATEGIES | BUY / SELL POINTS | STATUS | REASON",
                         inner_x + 8, y + 4, clrDeepSkyBlue, 8);
       int strategy_top = y + (compact ? 20 : 22);
       int row_height = compact ? 24 : 30;
       int row_gap = 2;
       int column_gap = 5;
       int col_width = (inner_width - 16 - column_gap) / 2;
       for(int i = 0; i < 10; i++)
         {
          int col = i / 5;
          int row = i % 5;
          int row_x = inner_x + 8 + col * (col_width + column_gap);
          int row_y = strategy_top + row * (row_height + row_gap);
          string item_name = PanelM30StrategyName(i);
          if(i >= m_m30_dashboard_line_count) continue;
          string full_line = m_m30_dashboard_lines[i];
          int title_end = StringFind(full_line, " | ");
          string item_title = title_end > 0 ? StringSubstr(full_line, 0, title_end) : full_line;
          if(StringLen(item_title) > 3 && StringGetCharacter(item_title, 2) == ' ')
             item_title = StringSubstr(item_title, 3);
          if(StringLen(item_title) > 18) item_title = StringSubstr(item_title, 0, 18);
          string status = "WAIT";
          if(StringFind(full_line, "CONFIRMED") >= 0) status = "CONFIRMED";
          else if(StringFind(full_line, "DEVELOPING") >= 0) status = "DEVELOPING";
          else if(StringFind(full_line, "INVALIDATED") >= 0) status = "INVALIDATED";
          else if(!m_m30_strategy_enabled[i]) status = "OFF";
          int buy_pos = StringFind(full_line, "| B ");
          int sell_pos = StringFind(full_line, " S ");
          string points = buy_pos >= 0 && sell_pos > buy_pos ? StringSubstr(full_line, buy_pos + 2, sell_pos - buy_pos - 2) : "B/S N/A";
          string reason = full_line;
          int last_sep = StringFind(full_line, " | ", 0);
          for(int search_from = 0; search_from >= 0; )
            {
             int next_sep = StringFind(full_line, " | ", search_from + 3);
             if(next_sep < 0) break;
             last_sep = next_sep;
             search_from = next_sep;
            }
          if(last_sep >= 0) reason = StringSubstr(full_line, last_sep + 3);
          if(StringLen(reason) > 54) reason = StringSubstr(reason, 0, 51) + "...";
          string first_line = StringFormat("%02d %s [%s]", i + 1, item_title,
                                           m_m30_strategy_enabled[i] ? "ON" : "OFF");
          string second_line = points + " " + status + " | " + reason;
          if(StringLen(second_line) > MathMax(20, col_width / 5))
             second_line = StringSubstr(second_line, 0, MathMax(17, col_width / 5 - 3)) + "...";
          CreatePanelButton(item_name, first_line + "\n" + second_line,
                            row_x, row_y, col_width, row_height,
                            m_m30_strategy_enabled[i] ? C'35,71,62' : C'67,57,57',
                            StringFind(status, "CONFIRMED") >= 0 ? clrPaleGreen : clrWhite);
          ObjectSetInteger(0, item_name, OBJPROP_FONTSIZE, compact ? 6 : 7);
          ObjectSetString(0, item_name, OBJPROP_TOOLTIP,
                          m_m30_dashboard_lines[i] + "\nClick to toggle this strategy.");
         }

       y += compact ? 156 : 188;
       int final_height = compact ? 38 : 44;
       CreatePanelBox(m_prefix + "PANEL_DECISION_BG", inner_x, y, inner_width,
                      final_height, C'29,36,48', C'67,79,94');
       string final_status, final_reason;
       int final_direction = FinalDirection(final_status, final_reason);
       color decision_color = final_direction > 0 ? clrLimeGreen :
                              (final_direction < 0 ? clrTomato : clrOrange);
       int result_sep = StringFind(m_m30_dashboard_reason, " | ");
       string m30_status = result_sep >= 0 ? StringSubstr(m_m30_dashboard_reason, 0, result_sep) :
                           (m_m30_dashboard_reason == "" ? final_status : m_m30_dashboard_reason);
       string m30_explanation = result_sep >= 0 ? StringSubstr(m_m30_dashboard_reason, result_sep + 3) : final_reason;
       if(StringFind(m30_status, "BUY") >= 0) decision_color = clrLimeGreen;
       else if(StringFind(m30_status, "SELL") >= 0) decision_color = clrTomato;
       string final_summary = "FINAL M30 RESULT | " + m30_status;
       if(StringLen(final_summary) > MathMax(24, inner_width / 6))
          final_summary = StringSubstr(final_summary, 0, MathMax(21, inner_width / 6 - 3)) + "...";
       CreateOrMoveLabel(m_prefix + "PANEL_DECISION", final_summary,
                         inner_x + 8, y + 4, decision_color, 8);
       string final_reason_text = "Reason: " + m30_explanation;
       if(StringLen(final_reason_text) > MathMax(24, inner_width / 6))
          final_reason_text = StringSubstr(final_reason_text, 0, MathMax(21, inner_width / 6 - 3)) + "...";
       CreateOrMoveLabel(m_prefix + "PANEL_REASON", final_reason_text,
                         inner_x + 8, y + 21, clrWhite, 7);

       y += final_height + 4;
       int levels_height = compact ? 68 : 78;
       CreatePanelBox(m_prefix + "PANEL_M30_LEVELS_BG", inner_x, y, inner_width,
                      levels_height, C'28,36,47', C'67,79,94');
       CreateOrMoveLabel(m_prefix + "PANEL_M30_LEVELS_TITLE", "EXACT M30 PRICE LEVELS",
                         inner_x + 8, y + 4, clrDeepSkyBlue, 8);
       for(int i = 0; i < 5; i++)
         {
          string level = m_m30_level_lines[i];
          if(StringLen(level) > MathMax(24, inner_width / 6))
             level = StringSubstr(level, 0, MathMax(21, inner_width / 6 - 3)) + "...";
          CreateOrMoveLabel(m_prefix + "PANEL_M30_LEVEL_" + IntegerToString(i),
                            level, inner_x + 8, y + 19 + i * (compact ? 10 : 11),
                            clrWhite, compact ? 6 : 7);
         }

       y += levels_height + 4;
       int plan_height = compact ? 92 : 106;
       CreatePanelBox(m_prefix + "PANEL_M30_PLAN_BG", inner_x, y, inner_width,
                      plan_height, C'28,36,47', C'67,79,94');
       CreateOrMoveLabel(m_prefix + "PANEL_M30_PLAN_TITLE", "TRADE PLAN | ANALYSIS ONLY",
                         inner_x + 8, y + 4, clrDeepSkyBlue, 8);
       for(int i = 0; i < 7; i++)
         {
          string plan_line = m_m30_plan_lines[i];
          if(StringLen(plan_line) > MathMax(24, inner_width / 6))
             plan_line = StringSubstr(plan_line, 0, MathMax(21, inner_width / 6 - 3)) + "...";
          CreateOrMoveLabel(m_prefix + "PANEL_M30_PLAN_" + IntegerToString(i),
                            plan_line, inner_x + 8, y + 18 + i * (compact ? 10 : 12),
                            clrWhite, compact ? 6 : 7);
         }

       int footer_y = m_panel_y + panel_height - (compact ? 42 : 48);
       int first_w = (inner_width - 20) / 5;
       CreatePanelButton(PanelM30AnalysisName(), m_m30_analysis_enabled ? "ANALYSIS ON" : "ANALYSIS OFF",
                         inner_x, footer_y, first_w, 19,
                         m_m30_analysis_enabled ? C'35,91,69' : C'85,62,47', clrWhite);
       CreatePanelButton(PanelM30DrawingsName(), m_m30_drawings_enabled ? "DRAWINGS ON" : "DRAWINGS OFF",
                         inner_x + first_w + 5, footer_y, first_w, 19,
                         m_m30_drawings_enabled ? C'35,91,69' : C'67,57,57', clrWhite);
       bool all_strategies_on = true;
       for(int i = 0; i < 10; i++) if(!m_m30_strategy_enabled[i]) all_strategies_on = false;
       CreatePanelButton(PanelM30AllStrategiesName(), m_m30_all_suspended ? "RESTORE ALL" : "ALL STRATEGIES",
                         inner_x + (first_w + 5) * 2, footer_y, first_w, 19,
                         all_strategies_on ? C'46,70,92' : C'85,62,47', clrWhite);
       CreatePanelButton(PanelM30ResetPositionName(), "RESET POS",
                         inner_x + (first_w + 5) * 3, footer_y, first_w, 19,
                         C'42,57,73', clrWhite);
       CreatePanelButton(PanelM30ResetSizeName(), "RESET SIZE",
                         inner_x + (first_w + 5) * 4, footer_y, first_w, 19,
                         C'42,57,73', clrWhite);
       int mark_y = footer_y + 22;
       int mark_width = (inner_width - 20) / 4;
       string tf_names[3] = {"H1", "H4", "D1"};
       for(int i = 0; i < 3; i++)
          CreatePanelButton(PanelMarkName(i), tf_names[i] + (m_show_markings[i] ? " ON" : " OFF"),
                            inner_x + i * (mark_width + 5), mark_y, mark_width, 18,
                            m_show_markings[i] ? C'35,91,69' : C'67,57,57', clrWhite);
       bool all_marks_on = m_show_markings[0] && m_show_markings[1] && m_show_markings[2];
       CreatePanelButton(PanelAllMarkName(), all_marks_on ? "MARKS OFF" : "MARKS ON",
                         inner_x + 3 * (mark_width + 5), mark_y, mark_width, 18,
                         all_marks_on ? C'35,91,69' : C'46,70,92', clrWhite);

       string resize = PanelResizeName();
       if(ObjectFind(0, resize) < 0) ObjectCreate(0, resize, OBJ_RECTANGLE_LABEL, 0, 0, 0);
       ObjectSetInteger(0, resize, OBJPROP_CORNER, CORNER_LEFT_UPPER);
       ObjectSetInteger(0, resize, OBJPROP_XDISTANCE, m_panel_x + m_panel_width - 6);
       ObjectSetInteger(0, resize, OBJPROP_YDISTANCE, m_panel_y + panel_height / 2 - 18);
       ObjectSetInteger(0, resize, OBJPROP_XSIZE, 12);
       ObjectSetInteger(0, resize, OBJPROP_YSIZE, 36);
       ObjectSetInteger(0, resize, OBJPROP_BGCOLOR, MTFInpH1Color);
       ObjectSetInteger(0, resize, OBJPROP_COLOR, clrWhite);
       ObjectSetInteger(0, resize, OBJPROP_BACK, false);
       ObjectSetInteger(0, resize, OBJPROP_SELECTABLE, true);
       ObjectSetInteger(0, resize, OBJPROP_SELECTED, false);
       ObjectSetInteger(0, resize, OBJPROP_HIDDEN, true);
       ObjectSetInteger(0, resize, OBJPROP_ZORDER, 140);
       ObjectSetInteger(0, resize, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
       ChartRedraw(0);
      }

    void RenderDashboardLegacy()
      {
       long chart_width = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
       long chart_height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
       if(chart_width <= 0) chart_width = 900;
       if(chart_height <= 0) chart_height = 600;
       int available_width = (int)MathMax(180, chart_width - 8);
       int available_height = (int)MathMax(150, chart_height - 8);
       if(!m_panel_manual_size)
         {
          m_panel_width = MTFInpDashboardWidth;
          m_panel_height = MTFInpDashboardHeight;
         }
       int actual_height = m_dashboard_visible ? PanelDisplayHeight() : 30;
       int min_width = (int)MathMin(MathMax(180, MTFInpDashboardMinWidth),
                                    available_width);
       m_panel_width = (int)MathMax(min_width,
                                    MathMin(m_panel_width, available_width));
       m_panel_height = (int)MathMax(MTFInpDashboardMinHeight,
                                     MathMin(m_panel_height, available_height));
       actual_height = m_dashboard_visible ? PanelDisplayHeight() : 30;
       actual_height = (int)MathMin(actual_height, available_height);
       if(m_panel_position == MTF_PANEL_TOP_LEFT)
         { m_panel_x = 4; m_panel_y = 4; }
       else if(m_panel_position == MTF_PANEL_TOP_RIGHT)
         { m_panel_x = (int)MathMax(4, chart_width - m_panel_width - 4); m_panel_y = 4; }
       else if(m_panel_position == MTF_PANEL_BOTTOM_LEFT)
         { m_panel_x = 4; m_panel_y = (int)MathMax(4, chart_height - actual_height - 4); }
       else if(m_panel_position == MTF_PANEL_BOTTOM_RIGHT)
         { m_panel_x = (int)MathMax(4, chart_width - m_panel_width - 4);
           m_panel_y = (int)MathMax(4, chart_height - actual_height - 4); }
       else
         {
          m_panel_x = (int)MathMax(4, MathMin(m_panel_x, chart_width - m_panel_width - 4));
          m_panel_y = (int)MathMax(4, MathMin(m_panel_y, chart_height - actual_height - 4));
         }

       if(!m_dashboard_visible)
         {
          int total = ObjectsTotal(0, 0, -1);
          for(int i = total - 1; i >= 0; i--)
            {
             string object_name = ObjectName(0, i, 0, -1);
             if(StringFind(object_name, m_prefix + "PANEL_") == 0 &&
                object_name != PanelShowName())
                ObjectSetInteger(0, object_name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
            }
          CreatePanelButton(PanelShowName(), "SHOW DASHBOARD",
                            m_panel_x, m_panel_y, 145, 26,
                            C'30,85,130', clrWhite);
          return;
         }
       ObjectDelete(0, PanelShowName());

       int height = (int)MathMin(PanelDisplayHeight(), available_height);
       CreatePanelBox(PanelBackgroundName(), m_panel_x, m_panel_y,
                      m_panel_width, height, C'22,27,36', C'73,86,102');
       string header = PanelHeaderName();
       if(ObjectFind(0, header) < 0)
          ObjectCreate(0, header, OBJ_RECTANGLE_LABEL, 0, 0, 0);
       ObjectSetInteger(0, header, OBJPROP_CORNER, CORNER_LEFT_UPPER);
       ObjectSetInteger(0, header, OBJPROP_XDISTANCE, m_panel_x);
       ObjectSetInteger(0, header, OBJPROP_YDISTANCE, m_panel_y);
       ObjectSetInteger(0, header, OBJPROP_XSIZE, m_panel_width);
       ObjectSetInteger(0, header, OBJPROP_YSIZE, 26);
       ObjectSetInteger(0, header, OBJPROP_BGCOLOR, C'30,85,130');
       ObjectSetInteger(0, header, OBJPROP_COLOR, C'60,139,196');
       ObjectSetInteger(0, header, OBJPROP_BACK, false);
       ObjectSetInteger(0, header, OBJPROP_SELECTABLE, true);
       ObjectSetInteger(0, header, OBJPROP_SELECTED, false);
       ObjectSetInteger(0, header, OBJPROP_HIDDEN, true);
       ObjectSetInteger(0, header, OBJPROP_ZORDER, 125);
       ObjectSetInteger(0, header, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
       CreateOrMoveLabel(m_prefix + "PANEL_TITLE",
                         m_panel_width >= 500 ? "D1 / H4 / H1 + M30 MARKET ANALYSIS" : "M30",
                         m_panel_x + 9, m_panel_y + 4, clrWhite, 9);
       int button_y = m_panel_y + 3;
       CreatePanelButton(PanelBotName(), m_bot_enabled ? "BOT STARTED" : "BOT STOPPED",
                         m_panel_x + m_panel_width - 94, button_y, 86, 20,
                         m_bot_enabled ? C'35,91,69' : C'115,48,48', clrWhite);
       CreatePanelButton(PanelMinimizeName(), m_dashboard_minimized ? "+" : "-",
                         m_panel_x + m_panel_width - 124, button_y, 24, 20,
                         C'42,57,73', clrWhite);
       CreatePanelButton(PanelShowName(), "HIDE",
                         m_panel_x + m_panel_width - 194, button_y, 60, 20,
                         C'42,57,73', clrWhite);
       if(m_dashboard_minimized)
         {
          int total = ObjectsTotal(0, 0, -1);
          for(int i = total - 1; i >= 0; i--)
            {
             string object_name = ObjectName(0, i, 0, -1);
             if(StringFind(object_name, m_prefix + "PANEL_") != 0) continue;
             if(object_name == PanelBackgroundName() || object_name == PanelHeaderName() ||
                object_name == m_prefix + "PANEL_TITLE" || object_name == PanelBotName() ||
                object_name == PanelMinimizeName() || object_name == PanelShowName())
                ObjectSetInteger(0, object_name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
             else
                ObjectSetInteger(0, object_name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
            }
          return;
         }
       CreatePanelButton(PanelCompactName(),
                         m_dashboard_expanded ? "COMPACT" : "EXPAND",
                         m_panel_x + m_panel_width - 264, button_y, 64, 20,
                         C'42,57,73', clrWhite);

       int control_y = m_panel_y + 31;
       int control_width = (int)MathMax(60, MathMin(90, (m_panel_width - 44) / 4));
       string tf_names[3] = {"H1", "H4", "D1"};
       for(int i = 0; i < 3; i++)
         {
          string text = tf_names[i] + (m_show_markings[i] ? ": ON" : ": OFF");
          CreatePanelButton(PanelMarkName(i), text,
                            m_panel_x + 8 + i * (control_width + 4), control_y,
                            control_width, 20,
                            m_show_markings[i] ? C'35,91,69' : C'67,57,57',
                            m_show_markings[i] ? clrPaleGreen : clrSalmon);
         }
       bool all_on = m_show_markings[0] && m_show_markings[1] && m_show_markings[2];
       CreatePanelButton(PanelAllMarkName(), all_on ? "ALL OFF" : "ALL ON",
                         m_panel_x + 8 + 3 * (control_width + 4), control_y,
                         control_width, 20,
                         all_on ? C'35,91,69' : C'46,70,92', clrWhite);

       MTFTrendState d1 = m_states[2];
       MTFTrendState h4 = m_states[1];
       MTFTrendState h1 = m_states[0];
       string final_status, reason;
       int final_direction = FinalDirection(final_status, reason);
       string d1_lines[8], h4_lines[8], h1_lines[8];
       d1_lines[0] = RegimeText(d1) + " | " + d1.structure;
       d1_lines[1] = "Latest: " + EventDetail(d1);
       d1_lines[2] = ReversalDetail(d1);
       d1_lines[3] = ShortZoneText(d1.demand, "Demand") + " | " + ShortZoneText(d1.supply, "Supply");
       d1_lines[4] = "Major H/L: " +
                     (d1.latest_high.valid ? DoubleToString(d1.latest_high.price, _Digits) : "n/a") + " / " +
                     (d1.latest_low.valid ? DoubleToString(d1.latest_low.price, _Digits) : "n/a");
       d1_lines[5] = ShortLevelPairText(d1);
       d1_lines[6] = "Premium / discount: " + PremiumDiscountText();
       d1_lines[7] = TrendlineDetail(d1);
       h4_lines[0] = RegimeText(h4) + " | " + h4.structure;
       h4_lines[1] = "D1 alignment: " + (h4.direction == d1.direction && d1.direction != 0 ? "ALIGNED" : "CONFLICT");
       h4_lines[2] = ReversalDetail(h4);
       h4_lines[3] = "Latest: " + EventDetail(h4);
       h4_lines[4] = ShortLevelPairText(h4);
       h4_lines[5] = ShortZoneText(h4.demand, "Demand") + " | " + ShortZoneText(h4.supply, "Supply");
       h4_lines[6] = "Liquidity: " + (h4.equal_highs.valid || h4.equal_lows.valid ? "pool detected" : "no equal swing pool");
       h4_lines[7] = TrendlineDetail(h4);
       h1_lines[0] = RegimeText(h1) + " | " + h1.structure;
       h1_lines[1] = "Latest: " + EventDetail(h1);
       h1_lines[2] = "Location: " + TradingLocation();
       h1_lines[3] = ShortZoneText(h1.demand, "Demand") + " | " + ShortZoneText(h1.supply, "Supply");
       h1_lines[4] = ShortLevelPairText(h1);
       h1_lines[5] = TrendlineDetail(h1);
       h1_lines[6] = "Liquidity: " + (h1.sweep_valid ? (h1.sweep_direction > 0 ? "SSL swept, close reclaimed up" : "BSL swept, close reclaimed down") :
                             (h1.wick_sweep ? "wick sweep; wait for close" : "no confirmed sweep"));
       h1_lines[7] = "Price location: " + PremiumDiscountTextForState(h1);

       bool compact = !m_dashboard_expanded;
       int start_y = control_y + 25;
       bool horizontal = m_panel_width >= 600;
       if(!horizontal)
         {
          d1_lines[2] = ShortReversalDetail(d1) + " | " +
                         ShortZoneText(d1.demand, "D");
          h4_lines[2] = ShortReversalDetail(h4);
          h1_lines[1] = ReversalDetail(h1) + " | " + EventDetail(h1);
          h1_lines[2] = "Location: " + TradingLocation() + " | " +
                         ShortZoneText(h1.demand, "D") + " | " +
                         ShortZoneText(h1.supply, "S");
          h1_lines[3] = ShortLevelPairText(h1) + " | " + TrendlineDetail(h1);
         }
       int card_gap = 6;
       int card_x[3], card_y[3], card_w[3], card_h[3];
       if(horizontal)
         {
          int width = (m_panel_width - 28 - 2 * card_gap) / 3;
          for(int i = 0; i < 3; i++)
            { card_x[i] = m_panel_x + 8 + i * (width + card_gap); card_y[i] = start_y;
              card_w[i] = width; card_h[i] = compact ? 46 : 136; }
         }
       else if(compact)
         {
          for(int i = 0; i < 3; i++)
            { card_x[i] = m_panel_x + 8; card_y[i] = start_y + i * 28;
              card_w[i] = m_panel_width - 16; card_h[i] = 25; }
         }
       else
         {
          int gap = 4;
          int left_width = (m_panel_width - 28 - gap) / 2;
          int top_height = 82;
          card_x[0] = m_panel_x + 8;
          card_y[0] = start_y;
          card_w[0] = left_width;
          card_h[0] = top_height;
          card_x[1] = card_x[0] + left_width + gap;
          card_y[1] = start_y;
          card_w[1] = left_width;
          card_h[1] = top_height;
          card_x[2] = m_panel_x + 8;
          card_y[2] = start_y + top_height + gap;
          card_w[2] = m_panel_width - 16;
          card_h[2] = 78;
         }
       SetPanelCard(0, "D1 | PRIMARY DIRECTION", MTFInpD1Color,
                    d1_lines, 8, card_x[0], card_y[0], card_w[0], card_h[0], compact);
       SetPanelCard(1, "H4 | CONFIRMATION", MTFInpH4Color,
                    h4_lines, 8, card_x[1], card_y[1], card_w[1], card_h[1], compact);
       SetPanelCard(2, "H1 | LOCATION & STRUCTURE", MTFInpH1Color,
                    h1_lines, 8, card_x[2], card_y[2], card_w[2], card_h[2], compact);

       int m30_top = horizontal ? start_y + 142 : card_y[2] + card_h[2] + 6;
       int decision_y = m_panel_y + height - (compact ? 26 : 44);
       if(!compact && m30_top + 174 < decision_y)
         {
          int m30_height = decision_y - m30_top - 5;
          CreatePanelBox(m_prefix + "PANEL_M30_BG", m_panel_x + 8, m30_top,
                         m_panel_width - 16, m30_height, C'28,36,47', C'67,79,94');
          CreateOrMoveLabel(m_prefix + "PANEL_M30_TITLE",
                            "M30 STRATEGIES | BUY / SELL EVIDENCE | CLOSED-BAR ANALYSIS",
                            m_panel_x + 16, m30_top + 5, clrDeepSkyBlue, 9);
          string summary = m_m30_dashboard_summary;
          int summary_max = (int)MathMax(20, (m_panel_width - 32) / 5);
          if(StringLen(summary) > summary_max)
             summary = StringSubstr(summary, 0, summary_max - 3) + "...";
          CreateOrMoveLabel(m_prefix + "PANEL_M30_SUMMARY", summary,
                            m_panel_x + 16, m30_top + 23, clrWhite, 8);
          string m30_reason = m_m30_dashboard_reason;
          if(StringLen(m30_reason) > summary_max)
             m30_reason = StringSubstr(m30_reason, 0, summary_max - 3) + "...";
          CreateOrMoveLabel(m_prefix + "PANEL_M30_REASON", m30_reason,
                            m_panel_x + 16, m30_top + 39, clrSilver, 8);
          string analysis_text = m_m30_analysis_enabled ? "ANALYSIS ON" : "ANALYSIS OFF";
          string drawings_text = m_m30_drawings_enabled ? "DRAWINGS ON" : "DRAWINGS OFF";
          bool all_strategies_on = true;
          for(int i = 0; i < 10; i++)
             if(!m_m30_strategy_enabled[i]) all_strategies_on = false;
          CreatePanelButton(PanelM30AnalysisName(), analysis_text,
                            m_panel_x + 16, m30_top + 55, 92, 18,
                            m_m30_analysis_enabled ? C'35,91,69' : C'85,62,47', clrWhite);
          CreatePanelButton(PanelM30DrawingsName(), drawings_text,
                            m_panel_x + 112, m30_top + 55, 94, 18,
                            m_m30_drawings_enabled ? C'35,91,69' : C'67,57,57', clrWhite);
          CreatePanelButton(PanelM30AllStrategiesName(),
                            m_m30_all_suspended ? "RESTORE ALL" : (all_strategies_on ? "ALL OFF" : "ALL ON"),
                            m_panel_x + 210, m30_top + 55, 112, 18,
                            all_strategies_on ? C'46,70,92' : C'85,62,47', clrWhite);
          if(m_panel_width >= 500)
            {
             CreatePanelButton(PanelM30ResetPositionName(), "RESET POSITION",
                               m_panel_x + m_panel_width - 176, m30_top + 55, 78, 18,
                               C'42,57,73', clrWhite);
             CreatePanelButton(PanelM30ResetSizeName(), "RESET SIZE",
                               m_panel_x + m_panel_width - 94, m30_top + 55, 78, 18,
                               C'42,57,73', clrWhite);
            }
          else
            {
             if(ObjectFind(0, PanelM30ResetPositionName()) >= 0)
                ObjectSetInteger(0, PanelM30ResetPositionName(), OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
             if(ObjectFind(0, PanelM30ResetSizeName()) >= 0)
                ObjectSetInteger(0, PanelM30ResetSizeName(), OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
            }
          int col_width = (m_panel_width - 40) / 2;
          for(int i = 0; i < 10; i++)
            {
             string row_name = PanelM30StrategyName(i);
             int col = i / 5;
             int row = i % 5;
             int row_x = m_panel_x + 16 + col * (col_width + 8);
             int row_y = m30_top + 78 + row * 17;
             if(i >= m_m30_dashboard_line_count || row_y + 16 >= decision_y)
               {
                if(ObjectFind(0, row_name) >= 0)
                   ObjectSetInteger(0, row_name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
                continue;
               }
             string row_text = m_m30_dashboard_lines[i];
             int row_max = (int)MathMax(15, col_width / 5);
             if(StringLen(row_text) > row_max)
                row_text = StringSubstr(row_text, 0, row_max - 3) + "...";
             color row_color = StringFind(row_text, "CONFIRMED") >= 0 ? clrPaleGreen : clrWhite;
             CreatePanelButton(row_name,
                               row_text + (m_m30_strategy_enabled[i] ? " [ON]" : " [OFF]"),
                               row_x, row_y, col_width, 16,
                               m_m30_strategy_enabled[i] ? C'35,71,62' : C'67,57,57',
                               m_m30_strategy_enabled[i] ? row_color : clrSalmon);
            }
         }
       else
         {
          int total = ObjectsTotal(0, 0, -1);
          for(int i = total - 1; i >= 0; i--)
            {
             string object_name = ObjectName(0, i, 0, -1);
             if(StringFind(object_name, m_prefix + "PANEL_M30_") == 0)
                ObjectSetInteger(0, object_name, OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);
            }
         }

       CreatePanelBox(m_prefix + "PANEL_DECISION_BG", m_panel_x + 8,
                      decision_y, m_panel_width - 16, compact ? 20 : 38,
                      C'29,36,48', C'67,79,94');
       color decision_color = final_direction > 0 ? clrLimeGreen :
                              (final_direction < 0 ? clrTomato : clrOrange);
       string decision_text = "FINAL: " + final_status;
       if(compact && StringLen(m_m30_dashboard_summary) > 0)
          decision_text += " | M30: " + m_m30_dashboard_summary;
       int decision_max = (int)MathMax(24, (m_panel_width - 28) / 5);
       if(StringLen(decision_text) > decision_max)
          decision_text = StringSubstr(decision_text, 0, decision_max - 3) + "...";
       CreateOrMoveLabel(m_prefix + "PANEL_DECISION",
                         decision_text,
                         m_panel_x + 16, decision_y + (compact ? 4 : 3), decision_color,
                         compact ? 8 : 10);
       string reason_text = reason;
       int reason_max = (int)MathMax(16, (m_panel_width - 32) / 5);
       if(StringLen(reason_text) > reason_max)
          reason_text = StringSubstr(reason_text, 0, reason_max - 3) + "...";
       if(!compact)
          CreateOrMoveLabel(m_prefix + "PANEL_REASON", reason_text,
                            m_panel_x + 132, decision_y + 7, clrWhite, 8);
       else if(ObjectFind(0, m_prefix + "PANEL_REASON") >= 0)
          ObjectSetInteger(0, m_prefix + "PANEL_REASON", OBJPROP_TIMEFRAMES, OBJ_NO_PERIODS);

       string resize = PanelResizeName();
       if(ObjectFind(0, resize) < 0)
          ObjectCreate(0, resize, OBJ_RECTANGLE_LABEL, 0, 0, 0);
       ObjectSetInteger(0, resize, OBJPROP_CORNER, CORNER_LEFT_UPPER);
       ObjectSetInteger(0, resize, OBJPROP_XDISTANCE, m_panel_x + m_panel_width - 14);
       ObjectSetInteger(0, resize, OBJPROP_YDISTANCE, m_panel_y + height - 14);
       ObjectSetInteger(0, resize, OBJPROP_XSIZE, 14);
       ObjectSetInteger(0, resize, OBJPROP_YSIZE, 14);
       ObjectSetInteger(0, resize, OBJPROP_BGCOLOR, MTFInpH1Color);
       ObjectSetInteger(0, resize, OBJPROP_COLOR, clrWhite);
       ObjectSetInteger(0, resize, OBJPROP_BACK, false);
       ObjectSetInteger(0, resize, OBJPROP_SELECTABLE, true);
       ObjectSetInteger(0, resize, OBJPROP_SELECTED, false);
       ObjectSetInteger(0, resize, OBJPROP_HIDDEN, true);
       ObjectSetInteger(0, resize, OBJPROP_ZORDER, 140);
       ObjectSetInteger(0, resize, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
      }

    void RenderDashboard()
      {
       if(m_dashboard_suppressed)
         {
          long raw_width = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
          long raw_height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
          int chart_width = (int)(raw_width > 0 ? raw_width : 900);
          int chart_height = (int)(raw_height > 0 ? raw_height : 650);
          int total = ObjectsTotal(0, 0, -1);
          for(int i = total - 1; i >= 0; i--)
            {
             string object_name = ObjectName(0, i, 0, -1);
             if(StringFind(object_name, m_prefix + "PANEL_") == 0 &&
                object_name != SplitChartName())
                ObjectDelete(0, object_name);
            }
          RenderEmbeddedChart(chart_width, chart_height, chart_width / 2);
          return;
         }
       RenderSplitDashboard();
      }

    void DrawPointOne()
     {
      string name = m_prefix + "H1_POINT1_" + _Symbol;
      string status;
      string reason;
      int direction = FinalDirection(status, reason);
      datetime bar_time = iTime(_Symbol, _Period, 1);
      if(direction == 0 || bar_time <= 0)
        {
         ObjectDelete(0, name);
         return;
        }
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double price = direction > 0 ?
                     iLow(_Symbol, _Period, 1) - 12.0 * point :
                     iHigh(_Symbol, _Period, 1) + 12.0 * point;
      string text = direction > 0 ? "1 - BUY BIAS (D1/H4/H1)" :
                                    "1 - SELL BIAS (D1/H4/H1)";
      CreateOrMoveText(name, text, bar_time, price,
                       DirectionColor(direction), 9);
       ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES,
                        MarkingsEnabled(0) ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS);
     }

   void DrawAll()
     {
      for(int i = 0; i < 3; i++)
        {
         if(!m_states[i].data_ready)
            continue;
         MqlRates closed[];
         ArraySetAsSeries(closed, true);
         if(CopyRates(_Symbol, m_states[i].timeframe, 1, 1, closed) != 1)
            continue;
         DrawTrendline(m_states[i], i, closed[0]);
          ApplyTimeframeVisibility(i);
        }
      DrawPointOne();
       ApplyTimeframeVisibility(0);
      RenderDashboard();
      m_last_chart_bar = iTime(_Symbol, _Period, 0);
      m_last_dashboard_update = GetTickCount64();
      ChartRedraw(0);
     }

public:
   CMTFTrendAnalysis()
     {
      m_prefix = "AI_MS_" + _Symbol + "_" +
                 IntegerToString((long)ChartID()) + "_";
      m_ready = false;
      m_handles_ready = false;
      m_last_chart_bar = 0;
      m_last_dashboard_update = 0;
      string safe_symbol = _Symbol;
      StringReplace(safe_symbol, ".", "_");
      StringReplace(safe_symbol, " ", "_");
      m_settings_key = "AI_PANEL_" +
                       IntegerToString((long)ChartID()) + "_" + safe_symbol + "_";
      m_panel_x = 4;
      m_panel_y = 4;
      m_panel_width = MTFInpDashboardWidth;
      m_panel_height = MTFInpDashboardHeight;
      m_panel_manual_size = false;
      m_panel_position = MTFInpDashboardPosition;
      m_last_mouse_x = 0;
      m_last_mouse_y = 0;
      m_panel_drag_mode = 0;
      m_panel_drag_active = false;
      m_show_markings[0] = MTFInpShowH1Markings;
      m_show_markings[1] = MTFInpShowH4Markings;
      m_show_markings[2] = MTFInpShowD1Markings;
      m_master_drawings_enabled = true;
      m_dashboard_visible = MTFInpShowDashboard;
      m_dashboard_expanded = true;
      m_dashboard_suppressed = false;
      m_show_changed = false;
      m_m30_dashboard_summary = "M30 DATA UNAVAILABLE";
       m_m30_dashboard_reason = "Waiting for M30 data";
      m_m30_dashboard_line_count = 0;
      for(int i = 0; i < 10; i++) m_m30_dashboard_lines[i] = "";
      for(int i = 0; i < 5; i++) m_m30_level_lines[i] = "";
      for(int i = 0; i < 7; i++) m_m30_plan_lines[i] = "";
      m_split_chart_name = m_prefix + "PANEL_SPLIT_CHART";
      m_analysis_chart_id = 0;
      m_bot_enabled = false;
      m_m30_analysis_enabled = true;
      m_m30_drawings_enabled = true;
      m_m30_settings_loaded = false;
      m_m30_all_suspended = false;
      m_dashboard_minimized = false;
      m_m30_control_revision = 0;
      for(int i = 0; i < 10; i++)
        {
         m_m30_strategy_enabled[i] = true;
         m_m30_saved_strategy_enabled[i] = true;
        }

      m_states[0].timeframe = PERIOD_H1;
      m_states[0].tag = "H1";
      m_states[0].lookback = MTFInpH1LookbackBars;
      m_states[1].timeframe = PERIOD_H4;
      m_states[1].tag = "H4";
      m_states[1].lookback = MTFInpH4LookbackBars;
      m_states[2].timeframe = PERIOD_D1;
      m_states[2].tag = "D1";
      m_states[2].lookback = MTFInpD1LookbackBars;
      for(int i = 0; i < 3; i++)
        {
         m_atr_handles[i] = INVALID_HANDLE;
         ResetState(m_states[i]);
        }
     }

   bool InputsValid()
     {
      int h1_required = MTFInpH1SwingLeftBars + MTFInpH1SwingRightBars +
                        MTFInpATRPeriod + 5;
      int h4_required = MTFInpH4SwingLeftBars + MTFInpH4SwingRightBars +
                        MTFInpATRPeriod + 5;
      int d1_required = MTFInpD1SwingLeftBars + MTFInpD1SwingRightBars +
                        MTFInpATRPeriod + 5;
      return (MTFInpH1SwingLeftBars >= 1 && MTFInpH1SwingRightBars >= 1 &&
              MTFInpH4SwingLeftBars >= 1 && MTFInpH4SwingRightBars >= 1 &&
              MTFInpD1SwingLeftBars >= 1 && MTFInpD1SwingRightBars >= 1 &&
              MTFInpATRPeriod >= 2 &&
              MTFInpH1LookbackBars >= h1_required &&
              MTFInpH4LookbackBars >= h4_required &&
              MTFInpD1LookbackBars >= d1_required &&
              MTFInpMinimumSwingDistancePoints >= 0.0 &&
              MTFInpMinimumSwingDistanceATR >= 0.0 &&
              MTFInpEqualSwingTolerancePoints >= 0.0 &&
              MTFInpEqualSwingToleranceATR >= 0.0 &&
              MTFInpBreakBufferPoints >= 0.0 && MTFInpBreakBufferATR >= 0.0 &&
              MTFInpMinimumBreakBodyATR >= 0.0 && MTFInpMSSBodyATR >= 0.0 &&
              MTFInpLevelTolerancePoints >= 0.0 &&
              MTFInpLevelToleranceATR >= 0.0 &&
              MTFInpLevelInvalidationATR >= 0.0 &&
              MTFInpLiquidityTolerancePoints >= 0.0 &&
              MTFInpLiquidityToleranceATR >= 0.0 &&
              MTFInpZoneReactionBars >= 1 && MTFInpZoneLookbackBars >= 1 &&
              MTFInpZoneMinMoveAwayATR >= 0.0 &&
              MTFInpZoneHalfWidthATR > 0.0 &&
              MTFInpZoneInvalidationATR >= 0.0 &&
              MTFInpMinimumLevelTests >= 1 && MTFInpHistoricalBars >= 1 &&
              MTFInpRefreshSeconds >= 1 && MTFInpRefreshSeconds <= 60 &&
              MTFInpLineWidth >= 1 && MTFInpLineWidth <= 5 &&
              MTFInpDashboardWidth >= 180 && MTFInpDashboardHeight >= 180 &&
              MTFInpDashboardMinWidth >= 180 &&
              MTFInpDashboardMinHeight >= 150 &&
              MTFInpDashboardWidthPercent >= 25 && MTFInpDashboardWidthPercent <= 70 &&
              MTFInpChartMinimumWidth >= 180 &&
              MTFInpDashboardFontSize >= 6 && MTFInpDashboardFontSize <= 16 &&
              MTFInpDashboardPosition >= MTF_PANEL_TOP_LEFT &&
              MTFInpDashboardPosition <= MTF_PANEL_CUSTOM);
     }

   bool Initialize()
     {
      if(!InputsValid())
        {
         Print("MTF analysis: invalid input values.");
         return false;
        }
      LoadDashboardSettings();
      MigrateDrawingDefaults();
      if(MTFInpRememberDashboard && !GlobalVariableCheck(SettingsKey("SPLIT_LAYOUT_V")))
        {
         m_dashboard_expanded = true;
         GlobalVariableSet(SettingsKey("SPLIT_LAYOUT_V"), 1.0);
        }
       ObjectsDeleteAll(0, m_prefix + "PANEL_", 0, -1);
      m_analysis_chart_id = 0;
      ChartSetInteger(0, CHART_EVENT_MOUSE_MOVE, true);
      CreateATRHandles();
      Update();
      m_ready = true;
      return true;
     }

   void Update()
     {
      bool changed = !m_ready;
      for(int i = 0; i < 3; i++)
        {
         datetime current = iTime(_Symbol, m_states[i].timeframe, 0);
         if(current > 0 && current != m_states[i].current_bar)
            if(AnalyzeTimeframe(m_states[i], i))
               changed = true;
        }
      if(changed)
        {
         UpdateLiveH1WickSweep();
         DrawAll();
         m_ready = true;
        }
      else
        {
         datetime chart_bar = iTime(_Symbol, _Period, 0);
         if(chart_bar > 0 && chart_bar != m_last_chart_bar)
           {
            DrawPointOne();
            m_last_chart_bar = chart_bar;
            ChartRedraw(0);
           }
         ulong now = GetTickCount64();
         if(now - m_last_dashboard_update >= 750)
           {
            UpdateLiveH1WickSweep();
            RenderDashboard();
            m_last_dashboard_update = now;
           }
        }
     }

   void HandleChartEvent(const int id,
                         const long &lparam,
                         const double &dparam,
                         const string &sparam)
     {
       if(id == CHARTEVENT_OBJECT_CLICK)
         {
          if(sparam == PanelShowName())
            {
             ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
             m_dashboard_visible = !m_dashboard_visible;
             m_panel_drag_mode = 0;
             m_panel_drag_active = false;
             SaveDashboardSettings();
             RenderDashboard();
             ChartRedraw(0);
             return;
            }
          if(sparam == PanelBotName())
            {
             ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
             m_bot_enabled = !m_bot_enabled;
             m_m30_control_revision++;
             SaveDashboardSettings();
             RenderDashboard();
             ChartRedraw(0);
             return;
            }
          if(sparam == PanelMinimizeName())
            {
             ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
             m_dashboard_minimized = !m_dashboard_minimized;
             m_panel_drag_mode = 0;
             m_panel_drag_active = false;
             SaveDashboardSettings();
             RenderDashboard();
             ChartRedraw(0);
             return;
            }
          if(sparam == PanelM30AnalysisName())
            {
             ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
             m_m30_analysis_enabled = !m_m30_analysis_enabled;
             m_m30_control_revision++;
             SaveDashboardSettings();
             RenderDashboard();
             ChartRedraw(0);
             return;
            }
          if(sparam == PanelM30DrawingsName())
            {
             ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
             m_m30_drawings_enabled = !m_m30_drawings_enabled;
             SaveDashboardSettings();
             RenderDashboard();
             ChartRedraw(0);
             return;
            }
          if(sparam == PanelM30AllStrategiesName())
            {
             ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
             bool all_on = true, all_off = true;
             for(int i = 0; i < 10; i++)
               {
                if(!m_m30_strategy_enabled[i]) all_on = false;
                if(m_m30_strategy_enabled[i]) all_off = false;
               }
             if(all_on)
               {
                for(int i = 0; i < 10; i++)
                  {
                   m_m30_saved_strategy_enabled[i] = m_m30_strategy_enabled[i];
                   m_m30_strategy_enabled[i] = false;
                  }
                m_m30_all_suspended = true;
               }
             else if(m_m30_all_suspended && all_off)
               {
                for(int i = 0; i < 10; i++)
                   m_m30_strategy_enabled[i] = m_m30_saved_strategy_enabled[i];
                m_m30_all_suspended = false;
               }
             else
               {
                for(int i = 0; i < 10; i++)
                  {
                   m_m30_saved_strategy_enabled[i] = m_m30_strategy_enabled[i];
                   m_m30_strategy_enabled[i] = true;
                  }
                m_m30_all_suspended = false;
               }
             m_m30_control_revision++;
             SaveDashboardSettings();
             RenderDashboard();
             ChartRedraw(0);
             return;
            }
          if(sparam == PanelM30ResetPositionName())
            {
             ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
             m_panel_position = MTFInpDashboardPosition;
             m_panel_x = 4;
             m_panel_y = 4;
             m_panel_manual_size = false;
             SaveDashboardSettings();
             RenderDashboard();
             ChartRedraw(0);
             return;
            }
          if(sparam == PanelM30ResetSizeName())
            {
             ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
             m_panel_manual_size = false;
             m_panel_width = (int)MathRound((ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0) - 8) *
                                             MTFInpDashboardWidthPercent / 100.0);
             m_panel_height = MTFInpDashboardHeight;
             SaveDashboardSettings();
             RenderDashboard();
             ChartRedraw(0);
             return;
            }
          for(int i = 0; i < 10; i++)
             if(sparam == PanelM30StrategyName(i))
               {
                ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                m_m30_strategy_enabled[i] = !m_m30_strategy_enabled[i];
                m_m30_saved_strategy_enabled[i] = m_m30_strategy_enabled[i];
                m_m30_all_suspended = false;
                m_m30_control_revision++;
                SaveDashboardSettings();
                RenderDashboard();
                ChartRedraw(0);
                return;
               }
          if(sparam == PanelCompactName())
            {
             ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
             m_dashboard_minimized = false;
             m_dashboard_expanded = !m_dashboard_expanded;
             SaveDashboardSettings();
             RenderDashboard();
             ChartRedraw(0);
             return;
            }
          for(int i = 0; i < 3; i++)
             if(sparam == PanelMarkName(i))
               {
                ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
                m_show_markings[i] = !m_show_markings[i];
                ApplyTimeframeVisibility(i);
                SaveDashboardSettings();
                RenderDashboard();
                ChartRedraw(0);
                return;
               }
          if(sparam == PanelAllMarkName())
            {
             ObjectSetInteger(0, sparam, OBJPROP_STATE, false);
             bool turn_on = !(m_show_markings[0] && m_show_markings[1] &&
                              m_show_markings[2]);
             for(int i = 0; i < 3; i++)
               {
                m_show_markings[i] = turn_on;
                ApplyTimeframeVisibility(i);
               }
             SaveDashboardSettings();
             RenderDashboard();
             ChartRedraw(0);
             return;
            }
         }
      if(id == CHARTEVENT_MOUSE_MOVE)
        {
         int mouse_x = (int)lparam;
         int mouse_y = (int)dparam;
         bool left_down = (((int)StringToInteger(sparam) & 1) != 0);
         if(left_down && m_panel_drag_mode == 0)
           {
            int visible_panel_height = m_dashboard_visible ? PanelDisplayHeight() : 30;
             bool on_resize = m_dashboard_visible && !m_dashboard_minimized &&
                              mouse_x >= m_panel_x + m_panel_width - 20 &&
                             mouse_x <= m_panel_x + m_panel_width &&
                             mouse_y >= m_panel_y + visible_panel_height / 2 - 22 &&
                             mouse_y <= m_panel_y + visible_panel_height / 2 + 22;
             bool on_header = m_dashboard_visible && mouse_x >= m_panel_x &&
                              mouse_x <= m_panel_x + m_panel_width - 270 &&
                             mouse_y >= m_panel_y && mouse_y <= m_panel_y + 25;
             if(!m_dashboard_visible &&
                mouse_x >= m_panel_x && mouse_x <= m_panel_x + 145 &&
                mouse_y >= m_panel_y && mouse_y <= m_panel_y + 26)
                on_header = false;
            if(on_resize)
               m_panel_drag_mode = 2;
            else if(on_header)
               m_panel_drag_mode = 1;
            if(m_panel_drag_mode != 0)
              {
               m_panel_drag_active = true;
               m_last_mouse_x = mouse_x;
               m_last_mouse_y = mouse_y;
              }
           }
         else if(left_down && m_panel_drag_mode != 0)
           {
            int dx = mouse_x - m_last_mouse_x;
            int dy = mouse_y - m_last_mouse_y;
            if(m_panel_drag_mode == 1)
              {
                long chart_width = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
                long chart_height = ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS, 0);
                int visible_height = m_dashboard_visible ? PanelDisplayHeight() : 30;
                m_panel_x = (int)MathMax(4, MathMin(m_panel_x + dx,
                                                   chart_width - m_panel_width - MTFInpChartMinimumWidth - 4));
                m_panel_y = (int)MathMax(4, MathMin(m_panel_y + dy,
                                                   chart_height - visible_height - 4));
               m_panel_position = MTF_PANEL_CUSTOM;
              }
            else
              {
                long chart_width = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
                int maximum_width = (int)MathMax(210, chart_width - m_panel_x - MTFInpChartMinimumWidth - 4);
                int minimum_width = (int)MathMin(220, maximum_width);
                m_panel_width = (int)MathMax(minimum_width,
                                   MathMin(m_panel_width + dx, maximum_width));
               m_panel_manual_size = true;
              }
            m_last_mouse_x = mouse_x;
            m_last_mouse_y = mouse_y;
            RenderDashboard();
            ChartRedraw(0);
           }
         else if(!left_down && m_panel_drag_mode != 0)
           {
            m_panel_drag_mode = 0;
            m_panel_drag_active = false;
            SaveDashboardSettings();
           }
         return;
        }
      if(id == CHARTEVENT_OBJECT_CLICK &&
         (sparam == PanelHeaderName() || sparam == PanelResizeName()))
        {
         ObjectSetInteger(0, sparam, OBJPROP_SELECTED, false);
         m_panel_drag_mode = 0;
         m_panel_drag_active = false;
         SaveDashboardSettings();
         return;
        }
      if(id == CHARTEVENT_OBJECT_DRAG && sparam == PanelHeaderName())
        {
         m_panel_x = (int)ObjectGetInteger(0, PanelHeaderName(), OBJPROP_XDISTANCE);
         m_panel_y = (int)ObjectGetInteger(0, PanelHeaderName(), OBJPROP_YDISTANCE);
         m_panel_position = MTF_PANEL_CUSTOM;
         RenderDashboard();
         SaveDashboardSettings();
         ChartRedraw(0);
        }
      else if(id == CHARTEVENT_OBJECT_DRAG && sparam == PanelResizeName())
        {
         long chart_width = ChartGetInteger(0, CHART_WIDTH_IN_PIXELS, 0);
         int handle_x = (int)ObjectGetInteger(0, PanelResizeName(), OBJPROP_XDISTANCE);
         int requested_width = handle_x - m_panel_x + 14;
         int max_width = (int)MathMax(210, chart_width - m_panel_x - MTFInpChartMinimumWidth - 4);
         m_panel_width = (int)MathMax(MathMin(220, max_width),
                                      MathMin(max_width, requested_width));
         m_panel_height = PanelDisplayHeight();
         m_panel_manual_size = true;
         RenderDashboard();
         SaveDashboardSettings();
         ChartRedraw(0);
        }
      else if(id == CHARTEVENT_CHART_CHANGE)
        {
         DrawAll();
         SaveDashboardSettings();
        }
     }

    bool MarkingsVisible(const int index)
      {
       if(index < 0 || index > 2) return false;
       return m_show_markings[index];
      }

   void SuppressDashboard(const bool suppressed)
     {
      m_dashboard_suppressed = suppressed;
      if(suppressed)
         m_dashboard_visible = false;
      RenderDashboard();
      ChartRedraw(0);
     }

   void SetMarkingsVisible(const int index,const bool visible)
     {
      if(index < 0 || index > 2 || m_show_markings[index] == visible)
         return;
      m_show_markings[index] = visible;
      ApplyTimeframeVisibility(index);
      SaveDashboardSettings();
      RenderDashboard();
      ChartRedraw(0);
     }

   void SetMasterDrawingsVisible(const bool visible)
     {
      m_master_drawings_enabled=visible;
      for(int i=0;i<3;i++) ApplyTimeframeVisibility(i);
      RenderDashboard();
      ChartRedraw(0);
     }

   long AnalysisChartId()
     {
      return m_analysis_chart_id > 0 ? m_analysis_chart_id : ChartID();
     }

   void SetM30DashboardData(const string summary,
                            const string reason,
                            string &lines[],
                            const int line_count,
                            string &levels[],
                            const int level_count,
                            string &plan[],
                            const int plan_count)
     {
      int bounded_count = (int)MathMax(0, MathMin(10, line_count));
      int bounded_levels = (int)MathMax(0, MathMin(5, level_count));
      int bounded_plan = (int)MathMax(0, MathMin(7, plan_count));
      bool changed = (m_m30_dashboard_summary != summary ||
                      m_m30_dashboard_reason != reason ||
                      m_m30_dashboard_line_count != bounded_count);
      m_m30_dashboard_summary = summary;
      m_m30_dashboard_reason = reason;
      m_m30_dashboard_line_count = bounded_count;
      for(int i = 0; i < 10; i++)
        {
         string line = i < m_m30_dashboard_line_count && i < ArraySize(lines) ? lines[i] : "";
         if(m_m30_dashboard_lines[i] != line) changed = true;
         m_m30_dashboard_lines[i] = line;
        }
      for(int i = 0; i < 5; i++)
        {
         string level = i < bounded_levels && i < ArraySize(levels) ? levels[i] : "";
         if(m_m30_level_lines[i] != level) changed = true;
         m_m30_level_lines[i] = level;
        }
      for(int i = 0; i < 7; i++)
        {
         string plan_line = i < bounded_plan && i < ArraySize(plan) ? plan[i] : "";
         if(m_m30_plan_lines[i] != plan_line) changed = true;
         m_m30_plan_lines[i] = plan_line;
        }
      if(m_ready && changed)
         RenderDashboard();
     }

   void ConfigureM30Defaults(bool &strategy_defaults[],
                             const bool drawings_default)
     {
      if(m_m30_settings_loaded)
         return;
      m_bot_enabled = false;
      m_m30_analysis_enabled = true;
      m_m30_drawings_enabled = drawings_default;
      for(int i = 0; i < 10; i++)
        {
         bool enabled = i < ArraySize(strategy_defaults) ? strategy_defaults[i] : true;
         m_m30_strategy_enabled[i] = enabled;
         m_m30_saved_strategy_enabled[i] = enabled;
        }
      SaveDashboardSettings();
      m_m30_settings_loaded = true;
     }

   bool M30BotEnabled() { return m_bot_enabled; }
   void SetBotEnabled(const bool enabled)
     {
      if(m_bot_enabled == enabled) return;
      m_bot_enabled = enabled;
      SaveDashboardSettings();
      RenderDashboard();
      ChartRedraw(0);
     }
   bool IsBotButton(const string object_name)
     {
      return object_name == PanelBotName();
     }
   bool M30AnalysisEnabled() { return m_m30_analysis_enabled; }
   bool M30ProcessingEnabled() { return m_m30_analysis_enabled; }
   bool M30DrawingsEnabled() { return m_m30_drawings_enabled; }
   void SetM30AnalysisEnabled(const bool enabled)
     {
      if(m_m30_analysis_enabled == enabled) return;
      m_m30_analysis_enabled = enabled;
      m_m30_control_revision++;
      SaveDashboardSettings();
      RenderDashboard();
     }
   void SetM30DrawingsEnabled(const bool enabled)
     {
      if(m_m30_drawings_enabled == enabled) return;
      m_m30_drawings_enabled = enabled;
      SaveDashboardSettings();
      RenderDashboard();
     }
   bool M30StrategyEnabled(const int index)
     {
      if(index < 0 || index >= 10) return false;
      return m_m30_strategy_enabled[index];
     }
   bool AllM30StrategiesEnabled()
     {
      for(int i = 0; i < 10; i++)
         if(!m_m30_strategy_enabled[i]) return false;
      return true;
     }
   void ToggleM30Strategy(const int index)
     {
      if(index < 0 || index >= 10) return;
      m_m30_strategy_enabled[index] = !m_m30_strategy_enabled[index];
      m_m30_saved_strategy_enabled[index] = m_m30_strategy_enabled[index];
      m_m30_all_suspended = false;
      m_m30_control_revision++;
      SaveDashboardSettings();
      RenderDashboard();
     }
   void ToggleAllM30Strategies()
     {
      bool all_on = true;
      bool all_off = true;
      for(int i = 0; i < 10; i++)
        {
         if(!m_m30_strategy_enabled[i]) all_on = false;
         if(m_m30_strategy_enabled[i]) all_off = false;
        }
      if(all_on)
        {
         for(int i = 0; i < 10; i++)
           {
            m_m30_saved_strategy_enabled[i] = m_m30_strategy_enabled[i];
            m_m30_strategy_enabled[i] = false;
           }
         m_m30_all_suspended = true;
        }
      else if(m_m30_all_suspended && all_off)
        {
         for(int i = 0; i < 10; i++)
            m_m30_strategy_enabled[i] = m_m30_saved_strategy_enabled[i];
         m_m30_all_suspended = false;
        }
      else
        {
         for(int i = 0; i < 10; i++)
           {
            m_m30_saved_strategy_enabled[i] = m_m30_strategy_enabled[i];
            m_m30_strategy_enabled[i] = true;
           }
         m_m30_all_suspended = false;
        }
      m_m30_control_revision++;
      SaveDashboardSettings();
      RenderDashboard();
     }
   bool AllMarkingsEnabled()
     {
      return m_show_markings[0] && m_show_markings[1] && m_show_markings[2];
     }
   int M30ControlRevision() { return m_m30_control_revision; }

   bool GetContext(const ENUM_TIMEFRAMES timeframe,
                   MTFContextSnapshot &snapshot)
     {
      int index = -1;
      if(timeframe == PERIOD_H1) index = 0;
      else if(timeframe == PERIOD_H4) index = 1;
      else if(timeframe == PERIOD_D1) index = 2;
      if(index < 0)
         return false;

      MTFTrendState state = m_states[index];
      snapshot.ready = state.data_ready;
      snapshot.timeframe = state.timeframe;
      snapshot.direction = state.direction;
      snapshot.structure = state.structure;
      snapshot.latest_high = state.latest_high;
      snapshot.latest_low = state.latest_low;
      snapshot.latest_event = state.latest_event;
      snapshot.latest_reversal_event = state.latest_reversal_event;
      snapshot.support = state.support;
      snapshot.resistance = state.resistance;
      snapshot.equal_highs = state.equal_highs;
      snapshot.equal_lows = state.equal_lows;
      snapshot.demand = state.demand;
      snapshot.supply = state.supply;
      snapshot.sweep_valid = state.sweep_valid;
      snapshot.sweep_direction = state.sweep_direction;
      snapshot.sweep_time = state.sweep_time;
      snapshot.sweep_level = state.sweep_level;
      snapshot.atr = state.atr;
      return snapshot.ready;
     }

    void Deinitialize(const bool preserve_chart_objects = false)
     {
      SaveDashboardSettings();
      ReleaseATRHandles();
       if(!preserve_chart_objects)
          ObjectsDeleteAll(0, m_prefix, 0, -1);
      ChartRedraw(0);
      m_ready = false;
     }
  };

#endif // AI_TRADING_SIGNAL_MTF_TREND_ANALYSIS_MQH
