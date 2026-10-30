#ifndef AI_TRADING_SIGNAL_D1_ANALYSIS_MQH
#define AI_TRADING_SIGNAL_D1_ANALYSIS_MQH

input int    D1InpLookbackBars       = 360;
input int    D1InpPivotLeft          = 2;
input int    D1InpPivotRight         = 2;
input int    D1InpZoneLookback       = 240;
input int    D1InpReactionBars       = 12;
input double D1InpZoneHalfWidthATR   = 0.25;
input double D1InpMinMoveAwayATR     = 0.75;
input double D1InpBreakBufferATR     = 0.02;
input double D1InpMSSBodyATR         = 0.80;
input double D1InpStopBufferATR      = 0.25;
input double D1InpEquilibriumATR     = 0.10;
input int    D1InpRSIPeriod          = 14;
input int    D1InpADXPeriod          = 14;
input int    D1InpMACDFast            = 12;
input int    D1InpMACDSlow            = 26;
input int    D1InpMACDSignal          = 9;
input double D1InpADXTrendLevel      = 25.0;

enum ENUM_D1_DIRECTION
  {
   D1_DIRECTION_BEARISH = -1,
   D1_DIRECTION_NEUTRAL = 0,
   D1_DIRECTION_BULLISH = 1
  };

struct D1Swing
  {
   bool     valid;
   int      shift;
   datetime time;
   double   price;
  };

struct D1Zone
  {
   bool     valid;
   double   low;
   double   high;
   double   center;
   int      reactions;
   datetime time;
  };

// Read-only view of the existing D1 engine for downstream timeframe modules.
struct D1AnalysisSnapshot
  {
   bool               ready;
   ENUM_D1_DIRECTION  direction;
   string             structure;
   bool               bos;
   int                bos_direction;
   bool               choch;
   int                choch_direction;
   bool               mss;
   D1Swing            latest_high;
   D1Swing            latest_low;
   D1Zone             support;
   D1Zone             resistance;
   double             range_low;
   double             range_high;
   double             equilibrium;
   string             location;
  };

class CD1Analysis
  {
private:
   string             m_prefix;
   int                m_rsi_handle;
   int                m_macd_handle;
   int                m_adx_handle;
   datetime           m_last_daily_bar;
   bool               m_data_ready;
   bool               m_markings_visible;
   bool               m_master_markings_visible;
   ENUM_D1_DIRECTION  m_structure_bias;
   ENUM_D1_DIRECTION  m_final_bias;
   D1Swing            m_last_high;
   D1Swing            m_previous_high;
   D1Swing            m_last_low;
   D1Swing            m_previous_low;
   D1Zone             m_support;
   D1Zone             m_resistance;
   double             m_atr;
   double             m_range_low;
   double             m_range_high;
   double             m_equilibrium;
   double             m_rsi;
   double             m_macd_main;
   double             m_macd_signal;
   double             m_adx;
   double             m_plus_di;
   double             m_minus_di;
   double             m_entry_low;
   double             m_entry_high;
   double             m_entry_price;
   double             m_stop_loss;
   double             m_tp1;
   double             m_tp2;
   double             m_tp3;
   bool               m_plan_valid;
   bool               m_bos;
   int                m_bos_direction;
   bool               m_choch;
   int                m_choch_direction;
   bool               m_mss;
   string             m_structure_text;
   string             m_trend_text;
   string             m_divergence_text;
   string             m_rsi_text;
   string             m_macd_text;
   string             m_adx_text;
   string             m_reversal_text;
   string             m_panel_text;

   void ResetSwing(D1Swing &swing)
     {
      swing.valid = false;
      swing.shift = -1;
      swing.time  = 0;
      swing.price = 0.0;
     }

   void ResetZone(D1Zone &zone)
     {
      zone.valid     = false;
      zone.low       = 0.0;
      zone.high      = 0.0;
      zone.center    = 0.0;
      zone.reactions = 0;
      zone.time      = 0;
     }

   bool ReadIndicator(const int handle,
                      const int buffer_number,
                      const int shift,
                      double &value)
     {
      if(handle == INVALID_HANDLE || shift < 0)
         return false;
      double values[];
      ArraySetAsSeries(values, true);
      if(CopyBuffer(handle, buffer_number, shift, 1, values) != 1)
         return false;
      value = values[0];
      return true;
     }

   double ATRAt(const MqlRates &rates[],
                const int total,
                const int shift,
                const int period)
     {
      if(period < 1 || shift < 0 || shift + period >= total)
         return 0.0;
      double sum = 0.0;
      for(int i = shift; i < shift + period; i++)
        {
         double previous_close = rates[i + 1].close;
         double true_range = MathMax(rates[i].high - rates[i].low,
                                     MathMax(MathAbs(rates[i].high - previous_close),
                                             MathAbs(rates[i].low - previous_close)));
         sum += true_range;
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

   void StoreSwing(D1Swing &swing, const int shift, const MqlRates &bar, const bool high)
     {
      swing.valid = true;
      swing.shift = shift;
      swing.time  = bar.time;
      swing.price = high ? bar.high : bar.low;
     }

   void FindSwings(const MqlRates &rates[],
                   const int total,
                   D1Swing &last_high,
                   D1Swing &previous_high,
                   D1Swing &last_low,
                   D1Swing &previous_low)
     {
      ResetSwing(last_high);
      ResetSwing(previous_high);
      ResetSwing(last_low);
      ResetSwing(previous_low);

      for(int shift = D1InpPivotRight + 1; shift < total - D1InpPivotLeft; shift++)
        {
         if(IsPivotHigh(rates, total, shift, D1InpPivotLeft, D1InpPivotRight))
           {
            if(!last_high.valid)
               StoreSwing(last_high, shift, rates[shift], true);
            else if(!previous_high.valid)
               StoreSwing(previous_high, shift, rates[shift], true);
           }
         if(IsPivotLow(rates, total, shift, D1InpPivotLeft, D1InpPivotRight))
           {
            if(!last_low.valid)
               StoreSwing(last_low, shift, rates[shift], false);
            else if(!previous_low.valid)
               StoreSwing(previous_low, shift, rates[shift], false);
           }
         if(last_high.valid && previous_high.valid && last_low.valid && previous_low.valid)
            break;
        }
     }

   bool HasReaction(const MqlRates &rates[],
                    const int total,
                    const int pivot,
                    const bool support,
                    const double current_atr)
     {
      double pivot_atr = ATRAt(rates, total, pivot, 14);
      if(pivot_atr <= 0.0)
         pivot_atr = current_atr;
      if(pivot_atr <= 0.0 || pivot <= 1)
         return false;

      int first_shift = pivot - D1InpReactionBars;
      if(first_shift < 1)
         first_shift = 1;
      double extreme = support ? rates[pivot - 1].high : rates[pivot - 1].low;
      for(int shift = pivot - 1; shift >= first_shift; shift--)
        {
         if(support)
            extreme = MathMax(extreme, rates[shift].high);
         else
            extreme = MathMin(extreme, rates[shift].low);
        }

      double move_away = support ? extreme - rates[pivot].low
                                 : rates[pivot].high - extreme;
      return (move_away >= D1InpMinMoveAwayATR * pivot_atr);
     }

   void FindMajorZone(const MqlRates &rates[],
                      const int total,
                      const bool support,
                      const double current_price,
                      const double current_atr,
                      D1Zone &zone)
     {
      ResetZone(zone);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double half_width = MathMax(5.0 * point, D1InpZoneHalfWidthATR * current_atr);
      int last_shift = D1InpZoneLookback;
      int available_last = total - D1InpPivotLeft - 1;
      if(last_shift > available_last)
         last_shift = available_last;

      int best_reactions = 0;
      double best_distance = DBL_MAX;
      double best_center = 0.0;
      datetime best_time = 0;

      for(int pivot = D1InpPivotRight + 1; pivot <= last_shift; pivot++)
        {
         bool is_pivot = support
                         ? IsPivotLow(rates, total, pivot, D1InpPivotLeft, D1InpPivotRight)
                         : IsPivotHigh(rates, total, pivot, D1InpPivotLeft, D1InpPivotRight);
         if(!is_pivot || !HasReaction(rates, total, pivot, support, current_atr))
            continue;

         double center = support ? rates[pivot].low : rates[pivot].high;
         if(support && center > current_price + half_width)
            continue;
         if(!support && center < current_price - half_width)
            continue;

         int reactions = 0;
         for(int other = D1InpPivotRight + 1; other <= last_shift; other++)
           {
            bool other_is_pivot = support
                                  ? IsPivotLow(rates, total, other, D1InpPivotLeft, D1InpPivotRight)
                                  : IsPivotHigh(rates, total, other, D1InpPivotLeft, D1InpPivotRight);
            if(!other_is_pivot || !HasReaction(rates, total, other, support, current_atr))
               continue;
            double other_price = support ? rates[other].low : rates[other].high;
            if(MathAbs(other_price - center) <= half_width)
               reactions++;
           }

         double distance = MathAbs(current_price - center);
         if(reactions > best_reactions ||
            (reactions == best_reactions && reactions > 0 && distance < best_distance))
           {
            best_reactions = reactions;
            best_distance = distance;
            best_center = center;
            best_time = rates[pivot].time;
           }
        }

      if(best_reactions < 1)
         return;

      zone.valid     = true;
      zone.center    = best_center;
      zone.low       = best_center - half_width;
      zone.high      = best_center + half_width;
      zone.reactions = best_reactions;
      zone.time      = best_time;
     }

   string DirectionText(const ENUM_D1_DIRECTION direction)
     {
      if(direction == D1_DIRECTION_BULLISH)
         return "BULLISH";
      if(direction == D1_DIRECTION_BEARISH)
         return "BEARISH";
      return "SIDEWAYS / MIXED";
     }

   string PriceText(const double price)
     {
      if(price <= 0.0)
         return "n/a";
      int digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
      return DoubleToString(price, digits);
     }

   string ZoneText(const D1Zone &zone, const string label)
     {
      if(!zone.valid)
         return label + ": NOT IDENTIFIED";
      return label + ": " + PriceText(zone.low) + " - " + PriceText(zone.high) +
             " (" + IntegerToString(zone.reactions) + " reactions)";
     }

   string CurrentLocation()
     {
      if(m_range_high <= m_range_low || m_equilibrium <= 0.0)
         return "NOT AVAILABLE";
      double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double tolerance = MathMax(m_atr * D1InpEquilibriumATR,
                                 5.0 * SymbolInfoDouble(_Symbol, SYMBOL_POINT));
      if(MathAbs(price - m_equilibrium) <= tolerance)
         return "EQUILIBRIUM";
      if(price < m_equilibrium)
         return "DISCOUNT";
      return "PREMIUM";
     }

   string EntryStatus()
     {
      if(!m_plan_valid)
         return "NO QUALIFIED D1 PLAN";
      double price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      string location = CurrentLocation();

      if(m_final_bias == D1_DIRECTION_BULLISH)
        {
         if(price < m_entry_low)
            return "BUY ZONE INVALIDATED - REASSESS";
         if(price >= m_entry_low && price <= m_entry_high && location == "DISCOUNT")
            return "BUY ZONE ACTIVE - WAIT FOR LOWER-TF CONFIRMATION";
         if(location != "DISCOUNT")
            return "WAIT FOR DISCOUNT";
         return "WAIT FOR BUY ZONE";
        }

      if(m_final_bias == D1_DIRECTION_BEARISH)
        {
         if(price > m_entry_high)
            return "SELL ZONE INVALIDATED - REASSESS";
         if(price >= m_entry_low && price <= m_entry_high && location == "PREMIUM")
            return "SELL ZONE ACTIVE - WAIT FOR LOWER-TF CONFIRMATION";
         if(location != "PREMIUM")
            return "WAIT FOR PREMIUM";
         return "WAIT FOR SELL ZONE";
        }
      return "WAIT - D1 DIRECTION IS NOT CONFIRMED";
     }

   string BuildPanelText()
     {
      string support_label = m_support.reactions >= 2 ? "MAJOR SUPPORT" : "SUPPORT CANDIDATE";
      string resistance_label = m_resistance.reactions >= 2 ? "MAJOR RESISTANCE" : "RESISTANCE CANDIDATE";
      string break_text = "NOT DETECTED";
      if(m_bos)
         break_text = m_bos_direction > 0 ? "BULLISH BOS" : "BEARISH BOS";
      if(m_choch)
         break_text = m_choch_direction > 0 ? "CHoCH UP" : "CHoCH DOWN";
      if(m_mss)
         break_text += " + MSS";

      string range_text = "n/a";
      if(m_range_high > m_range_low)
         range_text = PriceText(m_range_low) + " - " + PriceText(m_range_high) +
                      " | EQ " + PriceText(m_equilibrium);

      string rsi_value = m_rsi > 0.0 ? DoubleToString(m_rsi, 1) : "n/a";
      string macd_value = (m_macd_main == 0.0 && m_macd_signal == 0.0)
                          ? "n/a" : m_macd_text;
      string adx_value = m_adx > 0.0
                         ? DoubleToString(m_adx, 1) + " " + m_adx_text
                         : "n/a";

      string final_bias = DirectionText(m_final_bias);
      if(m_reversal_text != "")
         final_bias = m_reversal_text;

      string plan_text = m_plan_valid
                         ? (m_final_bias == D1_DIRECTION_BULLISH ? "BUY FROM SUPPORT" : "SELL FROM RESISTANCE")
                         : "NO PLAN - WAIT";
      string levels_text = m_plan_valid
                           ? ("Entry zone: " + PriceText(m_entry_low) + " - " + PriceText(m_entry_high) + "\n" +
                              "SL: " + PriceText(m_stop_loss) + "\n" +
                              "TP1 (1R): " + PriceText(m_tp1) + "\n" +
                              "TP2 (2R): " + PriceText(m_tp2) + "\n" +
                              "TP3 (3R): " + PriceText(m_tp3))
                           : "SL / TP1-TP3: not drawn without a directional major-zone plan";

      return "D1 ANALYSIS  |  " + _Symbol + "\n" +
             "Structure: " + m_structure_text + "\n" +
             "Trend: " + m_trend_text + "\n" +
             "Break: " + break_text + "\n" +
             ZoneText(m_support, support_label) + "\n" +
             ZoneText(m_resistance, resistance_label) + "\n" +
             "Dealing range: " + range_text + "\n" +
             "Current location: " + CurrentLocation() + "\n" +
             "RSI " + rsi_value + " " + m_rsi_text + "\n" +
             "MACD: " + macd_value + "\n" +
             "ADX: " + adx_value + "\n" +
             "RSI divergence: " + m_divergence_text + "\n" +
             "FINAL D1 BIAS: " + final_bias + "\n" +
             "Plan: " + plan_text + "\n" +
             levels_text + "\n" +
             "Status: " + EntryStatus();
     }

   bool CreateOrMoveText(const string name,
                         const string text,
                         const datetime time,
                         const double price,
                         const color text_color,
                         const int font_size = 8)
     {
      if(ObjectFind(0, name) < 0)
        {
         if(!ObjectCreate(0, name, OBJ_TEXT, 0, time, price))
            return false;
        }
      else
         ObjectMove(0, name, 0, time, price);

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

   void DrawRectangle(const string name,
                      const datetime start_time,
                      const datetime end_time,
                      const double top,
                      const double bottom,
                      const color fill_color)
     {
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_RECTANGLE, 0, start_time, top, end_time, bottom);
      else
        {
         ObjectMove(0, name, 0, start_time, top);
         ObjectMove(0, name, 1, end_time, bottom);
        }
      ObjectSetInteger(0, name, OBJPROP_COLOR, fill_color);
      ObjectSetInteger(0, name, OBJPROP_FILL, true);
      ObjectSetInteger(0, name, OBJPROP_BACK, true);
      ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
       ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);
     }

   void DrawLevel(const string tag,
                  const double price,
                  const color level_color,
                  const ENUM_LINE_STYLE style)
     {
      if(price <= 0.0)
         return;
      string line_name = m_prefix + tag + "_LINE";
      string text_name = m_prefix + tag + "_TEXT";
      if(ObjectFind(0, line_name) < 0)
         ObjectCreate(0, line_name, OBJ_HLINE, 0, 0, price);
      else
         ObjectSetDouble(0, line_name, OBJPROP_PRICE, price);
      ObjectSetInteger(0, line_name, OBJPROP_COLOR, level_color);
      ObjectSetInteger(0, line_name, OBJPROP_STYLE, style);
      ObjectSetInteger(0, line_name, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, line_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, line_name, OBJPROP_HIDDEN, true);
       ObjectSetInteger(0, line_name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS);

      datetime label_time = iTime(_Symbol, _Period, 0);
      if(label_time <= 0)
         label_time = TimeCurrent();
      CreateOrMoveText(text_name, tag + "  " + PriceText(price),
                       label_time, price, level_color, 8);
     }

   void DrawPanel()
     {
      string background_name = m_prefix + "PANEL_BG";
      string text_name = m_prefix + "PANEL_TEXT";

      if(ObjectFind(0, background_name) < 0)
         ObjectCreate(0, background_name, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ObjectSetInteger(0, background_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, background_name, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, background_name, OBJPROP_YDISTANCE, 74);
      ObjectSetInteger(0, background_name, OBJPROP_XSIZE, 370);
      ObjectSetInteger(0, background_name, OBJPROP_YSIZE, 310);
      ObjectSetInteger(0, background_name, OBJPROP_BGCOLOR, clrBlack);
      ObjectSetInteger(0, background_name, OBJPROP_COLOR, clrDimGray);
      ObjectSetInteger(0, background_name, OBJPROP_BACK, false);
      ObjectSetInteger(0, background_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, background_name, OBJPROP_HIDDEN, true);

      if(ObjectFind(0, text_name) < 0)
         ObjectCreate(0, text_name, OBJ_LABEL, 0, 0, 0);
      ObjectSetInteger(0, text_name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
      ObjectSetInteger(0, text_name, OBJPROP_XDISTANCE, 18);
      ObjectSetInteger(0, text_name, OBJPROP_YDISTANCE, 82);
      ObjectSetInteger(0, text_name, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(0, text_name, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, text_name, OBJPROP_FONT, "Arial");
      ObjectSetInteger(0, text_name, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(0, text_name, OBJPROP_HIDDEN, true);
      string text = BuildPanelText();
      ObjectSetString(0, text_name, OBJPROP_TEXT, text);
      m_panel_text = text;
     }

   void DrawChartAnnotations()
     {
       if(!m_markings_visible || !m_master_markings_visible)
          return;
      ObjectsDeleteAll(0, m_prefix, 0, -1);

      datetime fallback_start = TimeCurrent() -
                                (datetime)(PeriodSeconds(PERIOD_D1) * D1InpZoneLookback);
      datetime end_time = TimeCurrent() +
                          (datetime)(PeriodSeconds(PERIOD_D1) * 20);
      datetime label_time = iTime(_Symbol, _Period, 0);
      if(label_time <= 0)
         label_time = TimeCurrent();

      if(m_plan_valid)
        {
         datetime plan_start = m_final_bias == D1_DIRECTION_BULLISH
                               ? m_support.time : m_resistance.time;
         if(plan_start <= 0)
            plan_start = fallback_start;
         color plan_color = m_final_bias == D1_DIRECTION_BULLISH
                            ? clrSeaGreen : clrFireBrick;
         DrawRectangle(m_prefix + "D1_PLAN_ZONE", plan_start, end_time,
                       m_entry_high, m_entry_low, plan_color);
         CreateOrMoveText(m_prefix + "D1_PLAN_LABEL",
                          "D1 DIRECTIONAL PLAN ZONE", label_time,
                          m_entry_high, clrWhite, 8);
         DrawLevel("SL", m_stop_loss, clrTomato, STYLE_DASH);
         DrawLevel("TP1", m_tp1, clrDodgerBlue, STYLE_DOT);
         DrawLevel("TP2", m_tp2, clrMediumSeaGreen, STYLE_DOT);
         DrawLevel("TP3", m_tp3, clrLimeGreen, STYLE_DASH);
        }

      ChartRedraw(0);
     }

   void RefreshPanel()
     {
      if(!m_data_ready)
         return;
      string text = BuildPanelText();
      if(text == m_panel_text)
         return;
      string label_name = m_prefix + "PANEL_TEXT";
      if(ObjectFind(0, label_name) >= 0)
        {
         ObjectSetString(0, label_name, OBJPROP_TEXT, text);
         m_panel_text = text;
        }
     }

   bool AnalyzeDaily()
     {
      MqlRates rates[];
      ArraySetAsSeries(rates, true);
      int copied = CopyRates(_Symbol, PERIOD_D1, 0, D1InpLookbackBars, rates);
      if(copied < D1InpPivotLeft + D1InpPivotRight + 40)
         return false;
      ArraySetAsSeries(rates, true);

      m_atr = ATRAt(rates, copied, 1, 14);
      if(m_atr <= 0.0)
         return false;

      FindSwings(rates, copied, m_last_high, m_previous_high, m_last_low, m_previous_low);
      double point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
      double tolerance = MathMax(3.0 * point, m_atr * 0.02);
      bool higher_high = m_last_high.valid && m_previous_high.valid &&
                         m_last_high.price > m_previous_high.price + tolerance;
      bool lower_high = m_last_high.valid && m_previous_high.valid &&
                        m_last_high.price < m_previous_high.price - tolerance;
      bool higher_low = m_last_low.valid && m_previous_low.valid &&
                        m_last_low.price > m_previous_low.price + tolerance;
      bool lower_low = m_last_low.valid && m_previous_low.valid &&
                       m_last_low.price < m_previous_low.price - tolerance;

      m_structure_bias = D1_DIRECTION_NEUTRAL;
      m_structure_text = "MIXED / INSUFFICIENT SWINGS";
      m_trend_text = "SIDEWAYS";
      if(higher_high && higher_low)
        {
         m_structure_bias = D1_DIRECTION_BULLISH;
         m_structure_text = "BULLISH (HH / HL)";
         m_trend_text = "UPWARD";
        }
      else if(lower_high && lower_low)
        {
         m_structure_bias = D1_DIRECTION_BEARISH;
         m_structure_text = "BEARISH (LH / LL)";
         m_trend_text = "DOWNWARD";
        }
      else if(m_last_high.valid && m_previous_high.valid &&
              m_last_low.valid && m_previous_low.valid)
         m_structure_text = "MIXED (NO HH/HL OR LH/LL SEQUENCE)";

      m_range_low = 0.0;
      m_range_high = 0.0;
      m_equilibrium = 0.0;
      if(m_last_high.valid && m_last_low.valid)
        {
         m_range_low = MathMin(m_last_high.price, m_last_low.price);
         m_range_high = MathMax(m_last_high.price, m_last_low.price);
         if(m_range_high > m_range_low)
            m_equilibrium = (m_range_high + m_range_low) / 2.0;
        }

      MqlTick tick;
      double current_price = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      if(SymbolInfoTick(_Symbol, tick) && tick.bid > 0.0)
         current_price = tick.bid;
      FindMajorZone(rates, copied, true, current_price, m_atr, m_support);
      FindMajorZone(rates, copied, false, current_price, m_atr, m_resistance);

      m_bos = false;
      m_bos_direction = 0;
      m_choch = false;
      m_choch_direction = 0;
      m_mss = false;
      m_reversal_text = "";
      m_final_bias = m_structure_bias;
      double last_close = rates[1].close;
      double break_buffer = m_atr * D1InpBreakBufferATR;
      bool broke_high = m_last_high.valid && rates[2].close <=
                        m_last_high.price + break_buffer &&
                        last_close > m_last_high.price + break_buffer;
      bool broke_low = m_last_low.valid && rates[2].close >=
                       m_last_low.price - break_buffer &&
                       last_close < m_last_low.price - break_buffer;

      if(broke_high)
        {
         if(m_structure_bias == D1_DIRECTION_BEARISH)
           {
            m_choch = true;
            m_choch_direction = 1;
            m_final_bias = D1_DIRECTION_NEUTRAL;
            m_reversal_text = "POTENTIAL BULLISH REVERSAL";
            m_mss = MathAbs(rates[1].close - rates[1].open) >= D1InpMSSBodyATR * m_atr;
           }
         else
           {
            m_bos = true;
            m_bos_direction = 1;
           }
        }
      else if(broke_low)
        {
         if(m_structure_bias == D1_DIRECTION_BULLISH)
           {
            m_choch = true;
            m_choch_direction = -1;
            m_final_bias = D1_DIRECTION_NEUTRAL;
            m_reversal_text = "POTENTIAL BEARISH REVERSAL";
            m_mss = MathAbs(rates[1].close - rates[1].open) >= D1InpMSSBodyATR * m_atr;
           }
         else
           {
            m_bos = true;
            m_bos_direction = -1;
           }
        }

      m_rsi = 0.0;
      m_macd_main = 0.0;
      m_macd_signal = 0.0;
      m_adx = 0.0;
      m_plus_di = 0.0;
      m_minus_di = 0.0;
      ReadIndicator(m_rsi_handle, 0, 1, m_rsi);
      ReadIndicator(m_macd_handle, 0, 1, m_macd_main);
      ReadIndicator(m_macd_handle, 1, 1, m_macd_signal);
      ReadIndicator(m_adx_handle, 0, 1, m_adx);
      ReadIndicator(m_adx_handle, 1, 1, m_plus_di);
      ReadIndicator(m_adx_handle, 2, 1, m_minus_di);

      m_rsi_text = "NEUTRAL";
      if(m_final_bias == D1_DIRECTION_BULLISH)
         m_rsi_text = m_rsi >= 50.0 && m_rsi <= 70.0 ? "SUPPORTING" :
                      (m_rsi > 70.0 ? "EXTENDED" : "CONFLICTING");
      else if(m_final_bias == D1_DIRECTION_BEARISH)
         m_rsi_text = m_rsi <= 50.0 && m_rsi >= 30.0 ? "SUPPORTING" :
                      (m_rsi < 30.0 ? "EXTENDED" : "CONFLICTING");

      m_macd_text = "NEUTRAL";
      if(m_final_bias == D1_DIRECTION_BULLISH)
         m_macd_text = m_macd_main > m_macd_signal ? "SUPPORTING" : "CONFLICTING";
      else if(m_final_bias == D1_DIRECTION_BEARISH)
         m_macd_text = m_macd_main < m_macd_signal ? "SUPPORTING" : "CONFLICTING";

      m_adx_text = (m_adx >= D1InpADXTrendLevel ? "STRONG TREND" : "WEAK TREND");
      if(m_plus_di > m_minus_di)
         m_adx_text += " | DI UP";
      else if(m_minus_di > m_plus_di)
         m_adx_text += " | DI DOWN";

      m_divergence_text = "NOT DETECTED";
      double rsi_latest = 0.0;
      double rsi_previous = 0.0;
      if(m_last_low.valid && m_previous_low.valid &&
         ReadIndicator(m_rsi_handle, 0, m_last_low.shift, rsi_latest) &&
         ReadIndicator(m_rsi_handle, 0, m_previous_low.shift, rsi_previous) &&
         m_last_low.price < m_previous_low.price - tolerance &&
         rsi_latest > rsi_previous)
         m_divergence_text = "BULLISH";
      else if(m_last_high.valid && m_previous_high.valid &&
              ReadIndicator(m_rsi_handle, 0, m_last_high.shift, rsi_latest) &&
              ReadIndicator(m_rsi_handle, 0, m_previous_high.shift, rsi_previous) &&
              m_last_high.price > m_previous_high.price + tolerance &&
              rsi_latest < rsi_previous)
         m_divergence_text = "BEARISH";

      m_plan_valid = false;
      m_entry_low = 0.0;
      m_entry_high = 0.0;
      m_entry_price = 0.0;
      m_stop_loss = 0.0;
      m_tp1 = 0.0;
      m_tp2 = 0.0;
      m_tp3 = 0.0;

      if(m_final_bias == D1_DIRECTION_BULLISH && m_support.valid && m_support.reactions >= 2)
        {
         m_entry_low = m_support.low;
         m_entry_high = m_support.high;
         m_entry_price = (m_entry_low + m_entry_high) / 2.0;
         m_stop_loss = m_entry_low - D1InpStopBufferATR * m_atr;
         double risk = m_entry_price - m_stop_loss;
         if(risk > 0.0)
           {
            m_tp1 = m_entry_price + risk;
            m_tp2 = m_entry_price + 2.0 * risk;
            m_tp3 = m_entry_price + 3.0 * risk;
            m_plan_valid = true;
           }
        }
      else if(m_final_bias == D1_DIRECTION_BEARISH &&
              m_resistance.valid && m_resistance.reactions >= 2)
        {
         m_entry_low = m_resistance.low;
         m_entry_high = m_resistance.high;
         m_entry_price = (m_entry_low + m_entry_high) / 2.0;
         m_stop_loss = m_entry_high + D1InpStopBufferATR * m_atr;
         double risk = m_stop_loss - m_entry_price;
         if(risk > 0.0)
           {
            m_tp1 = m_entry_price - risk;
            m_tp2 = m_entry_price - 2.0 * risk;
            m_tp3 = m_entry_price - 3.0 * risk;
            m_plan_valid = true;
           }
        }

      return true;
     }

public:
                     CD1Analysis(void)
     {
      m_prefix = "AI_D1_" + _Symbol + "_" +
                 IntegerToString((long)ChartID()) + "_";
      m_rsi_handle = INVALID_HANDLE;
      m_macd_handle = INVALID_HANDLE;
      m_adx_handle = INVALID_HANDLE;
      m_last_daily_bar = 0;
      m_data_ready = false;
      m_markings_visible = true;
      m_master_markings_visible = true;
      m_structure_bias = D1_DIRECTION_NEUTRAL;
      m_final_bias = D1_DIRECTION_NEUTRAL;
      m_atr = 0.0;
      m_range_low = 0.0;
      m_range_high = 0.0;
      m_equilibrium = 0.0;
      m_rsi = 0.0;
      m_macd_main = 0.0;
      m_macd_signal = 0.0;
      m_adx = 0.0;
      m_plus_di = 0.0;
      m_minus_di = 0.0;
      m_plan_valid = false;
      m_bos = false;
      m_bos_direction = 0;
      m_choch = false;
      m_choch_direction = 0;
      m_mss = false;
      m_structure_text = "WAITING FOR D1 DATA";
      m_trend_text = "UNKNOWN";
      m_divergence_text = "NOT DETECTED";
      m_rsi_text = "n/a";
      m_macd_text = "n/a";
      m_adx_text = "n/a";
      m_reversal_text = "";
      m_panel_text = "";
      ResetSwing(m_last_high);
      ResetSwing(m_previous_high);
      ResetSwing(m_last_low);
      ResetSwing(m_previous_low);
      ResetZone(m_support);
      ResetZone(m_resistance);
     }

   void Initialize()
     {
      m_rsi_handle = iRSI(_Symbol, PERIOD_D1, D1InpRSIPeriod, PRICE_CLOSE);
      m_macd_handle = iMACD(_Symbol, PERIOD_D1, D1InpMACDFast,
                            D1InpMACDSlow, D1InpMACDSignal, PRICE_CLOSE);
      m_adx_handle = iADX(_Symbol, PERIOD_D1, D1InpADXPeriod);
      if(m_rsi_handle == INVALID_HANDLE ||
         m_macd_handle == INVALID_HANDLE ||
         m_adx_handle == INVALID_HANDLE)
         Print("D1 analysis: one or more indicator handles could not be created.");
      Update();
     }

   void Update()
     {
      datetime daily_bar = iTime(_Symbol, PERIOD_D1, 0);
      if(daily_bar <= 0)
         return;

      if(daily_bar != m_last_daily_bar || !m_data_ready)
        {
         if(!AnalyzeDaily())
            return;
         m_last_daily_bar = daily_bar;
         m_data_ready = true;
         DrawChartAnnotations();
        }
     }

   void SetMarkingsVisible(const bool visible)
     {
      if(m_markings_visible == visible)
         return;
      m_markings_visible = visible;
      long timeframe_mask = (visible && m_master_markings_visible) ?
                            OBJ_ALL_PERIODS : OBJ_NO_PERIODS;
      int total = ObjectsTotal(0, 0, -1);
      for(int i = total - 1; i >= 0; i--)
        {
         string name = ObjectName(0, i, 0, -1);
         if(StringFind(name, m_prefix) == 0)
            ObjectSetInteger(0, name, OBJPROP_TIMEFRAMES, timeframe_mask);
        }
      if(visible && m_master_markings_visible && m_data_ready)
         DrawChartAnnotations();
      ChartRedraw(0);
     }

   void SetMasterMarkingsVisible(const bool visible)
     {
      m_master_markings_visible=visible;
      long timeframe_mask=(visible && m_markings_visible) ? OBJ_ALL_PERIODS : OBJ_NO_PERIODS;
      int total=ObjectsTotal(0,0,-1);
      for(int i=total-1;i>=0;i--)
        {
         string name=ObjectName(0,i,0,-1);
         if(StringFind(name,m_prefix)==0)
            ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,timeframe_mask);
        }
      if(visible && m_markings_visible && m_data_ready)
         DrawChartAnnotations();
      ChartRedraw(0);
     }

   bool GetSnapshot(D1AnalysisSnapshot &snapshot)
     {
      snapshot.ready = m_data_ready;
      snapshot.direction = m_final_bias;
      snapshot.structure = m_structure_text;
      snapshot.bos = m_bos;
      snapshot.bos_direction = m_bos_direction;
      snapshot.choch = m_choch;
      snapshot.choch_direction = m_choch_direction;
      snapshot.mss = m_mss;
      snapshot.latest_high = m_last_high;
      snapshot.latest_low = m_last_low;
      snapshot.support = m_support;
      snapshot.resistance = m_resistance;
      snapshot.range_low = m_range_low;
      snapshot.range_high = m_range_high;
      snapshot.equilibrium = m_equilibrium;
      snapshot.location = CurrentLocation();
      return snapshot.ready;
     }

   void Deinitialize(const bool preserve_chart_objects = false)
     {
      if(m_rsi_handle != INVALID_HANDLE)
         IndicatorRelease(m_rsi_handle);
      if(m_macd_handle != INVALID_HANDLE)
         IndicatorRelease(m_macd_handle);
      if(m_adx_handle != INVALID_HANDLE)
         IndicatorRelease(m_adx_handle);
       if(!preserve_chart_objects)
          ObjectsDeleteAll(0, m_prefix, 0, -1);
      ChartRedraw(0);
     }
  };

#endif // AI_TRADING_SIGNAL_D1_ANALYSIS_MQH
