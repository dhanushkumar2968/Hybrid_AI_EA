#ifndef AI_TRADING_SIGNAL_M30_ANALYSIS_MQH
#define AI_TRADING_SIGNAL_M30_ANALYSIS_MQH

#include "MTFTrendAnalysis.mqh"
#include "D1Analysis.mqh"

// M30 calculations always use closed PERIOD_M30 bars.  Session hours are in
// broker server time; the optional summer schedule must be selected by the
// user to match the broker's DST calendar.
input int    M30InpLookbackBars             = 360;
input int    M30InpSwingLeftBars            = 2;
input int    M30InpSwingRightBars           = 2;
input int    M30InpATRPeriod                = 14;
input int    M30InpRSIPeriod                = 14;
input int    M30InpMACDFast                 = 12;
input int    M30InpMACDSlow                 = 26;
input int    M30InpMACDSignal               = 9;
input int    M30InpADXPeriod                = 14;
input double M30InpEqualTolerancePoints     = 0.0;
input double M30InpEqualToleranceATR        = 0.04;
input int    M30InpRangeBars                = 12;
input int    M30InpDealingRangeBars         = 48;
input double M30InpZoneHalfWidthATR         = 0.15;
input double M30InpBreakBufferATR           = 0.02;
input double M30InpMinimumDisplacementATR   = 0.80;
input double M30InpOTEStart                 = 0.62;
input double M30InpOTEEnd                   = 0.79;
input double M30InpFalseBreakMaxATR         = 0.75;
input double M30InpADXStrengthLevel         = 20.0;

input int    M30InpAsiaStartHour            = 0;
input int    M30InpAsiaEndHour              = 7;
input int    M30InpLondonStartHour          = 7;
input int    M30InpLondonEndHour            = 12;
input int    M30InpNewYorkStartHour         = 12;
input int    M30InpNewYorkEndHour           = 17;
input bool   M30InpUseSummerSessionHours    = false;
input bool   M30InpBrokerDSTInEffect        = false;
input int    M30InpSummerAsiaStartHour      = 0;
input int    M30InpSummerAsiaEndHour        = 7;
input int    M30InpSummerLondonStartHour    = 6;
input int    M30InpSummerLondonEndHour      = 11;
input int    M30InpSummerNewYorkStartHour   = 11;
input int    M30InpSummerNewYorkEndHour     = 16;

input bool   M30InpEnableMarketStructure    = true;
input bool   M30InpEnableLiquidity          = true;
input bool   M30InpEnableSupportResistance  = true;
input bool   M30InpEnableEngulfing          = true;
input bool   M30InpEnableBreakout           = true;
input bool   M30InpEnableInstitutionalZones = true;
input bool   M30InpEnablePremiumDiscount    = true;
input bool   M30InpEnableFalseBreakout       = true;
input bool   M30InpEnableSessions           = true;
input bool   M30InpEnableMomentum           = true;
input bool   M30InpRequireLiquidity         = false;
input int    M30InpMinimumIndependentSignals = 3;
input double M30InpConfirmationThreshold    = 75.0;
input double M30InpMinimumScoreSeparation   = 20.0;
input bool   M30InpAllowCountertrendConfirm = false;
input double M30InpTradePlanRiskPercent      = 0.50;
input double M30InpTradePlanStopBufferATR    = 0.20;
input bool   M30InpDrawMarkings             = true;
input bool   M30InpDiagnosticLogging        = false;

input int    M30InpWeightStructure          = 15;
input int    M30InpWeightLiquidity          = 12;
input int    M30InpWeightSupportResistance  = 10;
input int    M30InpWeightEngulfing          = 8;
input int    M30InpWeightBreakout           = 8;
input int    M30InpWeightInstitutional      = 15;
input int    M30InpWeightPremiumDiscount    = 8;
input int    M30InpWeightFalseBreakout       = 10;
input int    M30InpWeightSession            = 5;
input int    M30InpWeightMomentum           = 9;

enum ENUM_M30_STRATEGY
  {
   M30_STRATEGY_STRUCTURE = 0,
   M30_STRATEGY_LIQUIDITY = 1,
   M30_STRATEGY_SUPPORT_RESISTANCE = 2,
   M30_STRATEGY_ENGULFING = 3,
   M30_STRATEGY_BREAKOUT = 4,
   M30_STRATEGY_INSTITUTIONAL = 5,
   M30_STRATEGY_PREMIUM_DISCOUNT = 6,
   M30_STRATEGY_FALSE_BREAKOUT = 7,
   M30_STRATEGY_SESSION = 8,
   M30_STRATEGY_MOMENTUM = 9
  };

struct M30SwingPoint
  {
   bool     valid;
   bool     is_high;
   int      shift;
   datetime time;
   double   price;
   string   classification;
  };

struct M30StrategyResult
  {
   bool              enabled;
   int               direction;
   bool              developing;
   bool              confirmed;
   bool              invalidated;
   double            buy_points;
   double            sell_points;
   double            weight;
   double            key_price;
   double            zone_low;
   double            zone_high;
   datetime          event_time;
   string            status;
   string            explanation;
  };

struct M30AnalysisSnapshot
  {
   bool                data_ready;
   datetime            last_closed_bar;
   datetime            last_update;
   double              atr;
   int                 structure_direction;
   bool                bullish_bos;
   bool                bearish_bos;
   bool                bullish_choch;
   bool                bearish_choch;
   bool                bullish_mss;
   bool                bearish_mss;
   M30SwingPoint       latest_high;
   M30SwingPoint       previous_high;
   M30SwingPoint       latest_low;
   M30SwingPoint       previous_low;
   bool                buy_liquidity_valid;
   bool                sell_liquidity_valid;
   bool                equal_highs_valid;
   bool                equal_lows_valid;
   double              equal_highs_level;
   double              equal_lows_level;
   bool                bullish_sweep;
   bool                bearish_sweep;
   bool                reclaim_confirmed;
   double              buy_liquidity_level;
   double              sell_liquidity_level;
   double              support_low;
   double              support_high;
   double              resistance_low;
   double              resistance_high;
   bool                support_valid;
   bool                resistance_valid;
   bool                support_invalidated;
   bool                resistance_invalidated;
   int                 support_tests;
   int                 resistance_tests;
   string              level_retest;
   double              range_low;
   double              range_high;
   double              dealing_range_low;
   double              dealing_range_high;
   double              equilibrium;
   double              ote_low;
   double              ote_high;
   bool                bullish_fvg_valid;
   bool                bearish_fvg_valid;
   bool                fvg_mitigated;
   bool                fvg_invalidated;
   bool                ifvg_valid;
   int                 ifvg_direction;
   double              fvg_low;
   double              fvg_high;
   bool                order_block_valid;
   bool                order_block_mitigated;
   bool                order_block_invalidated;
   bool                breaker_block_valid;
   int                 breaker_block_direction;
   int                 order_block_direction;
   double              order_block_low;
   double              order_block_high;
   bool                breakout_valid;
   bool                breakout_retest;
   int                 breakout_direction;
   double              breakout_level;
   bool                false_breakout_valid;
   int                 false_breakout_direction;
   double              session_high[3];
   double              session_low[3];
   bool                session_breakout_valid;
   int                 session_breakout_direction;
   bool                session_sweep_confirmed;
   bool                judas_swing_candidate;
   double              rsi;
   double              macd_main;
   double              macd_signal;
   double              adx;
   bool                momentum_strengthening;
   bool                momentum_weakening;
   string              d1_context;
   string              h4_context;
   string              h1_location;
   string              alignment;
   string              result;
   string              reason;
   double              buy_points;
   double              sell_points;
   double              neutral_points;
   double              active_max_points;
   double              buy_evidence_percent;
   double              sell_evidence_percent;
   int                 active_strategy_count;
   int                 confirmed_strategy_count;
   int                 developing_strategy_count;
   int                 independent_confirmation_count;
   bool                trade_plan_valid;
   int                 trade_direction;
   double              entry_zone_high;
   double              entry_zone_low;
   double              preferred_entry;
   double              stop_loss;
   double              take_profit_1;
   double              take_profit_2;
   double              take_profit_3;
   double              risk_reward_tp3;
   double              lot_size;
   double              estimated_money_risk;
   string              trade_plan_status;
   M30StrategyResult   strategies[10];
  };

class CM30Analysis
  {
private:
   MqlRates             m_rates[];
   int                  m_atr_handle;
   int                  m_rsi_handle;
   int                  m_macd_handle;
   int                  m_adx_handle;
   datetime             m_current_bar;
   bool                 m_ready;
   bool                 m_drawings_visible;
   bool                 m_master_drawings_visible;
   long                 m_draw_chart_id;
   bool                 m_runtime_strategy_enabled[10];
   int                  m_last_control_revision;
   string               m_prefix;
   M30SwingPoint        m_high_pivots[8];
   M30SwingPoint        m_low_pivots[8];
   int                  m_high_count;
   int                  m_low_count;
   M30AnalysisSnapshot  m_snapshot;
   MTFContextSnapshot   m_h1;
   MTFContextSnapshot   m_h4;
   MTFContextSnapshot   m_mtf_d1;
   D1AnalysisSnapshot   m_d1;
   double               m_buy_liquidity;
   double               m_sell_liquidity;
   double               m_support_low;
   double               m_support_high;
   double               m_resistance_low;
   double               m_resistance_high;
   bool                 m_fvg_valid;
   bool                 m_fvg_bullish;
   double               m_fvg_low;
   double               m_fvg_high;
   datetime             m_fvg_time;
   datetime             m_fvg_start_time;
   bool                 m_ob_valid;
   int                  m_ob_direction;
   double               m_ob_low;
   double               m_ob_high;
   datetime             m_ob_time;
   bool                 m_breakout_valid;
   int                  m_breakout_direction;
   double               m_breakout_level;
   bool                 m_false_breakout_valid;
   int                  m_false_breakout_direction;
   double               m_range_high;
   double               m_range_low;
   bool                 m_bullish_bos;
   bool                 m_bearish_bos;
   bool                 m_bullish_choch;
   bool                 m_bearish_choch;
   bool                 m_bullish_sweep;
   bool                 m_bearish_sweep;
   bool                 m_reclaim;
   double               m_atr;

   void ResetSwing(M30SwingPoint &point)
     {
      point.valid = false;
      point.is_high = false;
      point.shift = -1;
      point.time = 0;
      point.price = 0.0;
      point.classification = "";
     }

   void ResetResult(M30StrategyResult &item)
     {
      item.enabled = false;
      item.direction = 0;
      item.developing = false;
      item.confirmed = false;
      item.invalidated = false;
      item.buy_points = 0.0;
      item.sell_points = 0.0;
      item.weight = 0.0;
      item.key_price = 0.0;
      item.zone_low = 0.0;
      item.zone_high = 0.0;
      item.event_time = 0;
      item.status = "WAIT";
      item.explanation = "No confirmed evidence";
     }

   string StrategyName(const int index)
     {
      if(index == M30_STRATEGY_STRUCTURE) return "MARKET STRUCTURE";
      if(index == M30_STRATEGY_LIQUIDITY) return "LIQUIDITY";
      if(index == M30_STRATEGY_SUPPORT_RESISTANCE) return "SUPPORT/RESISTANCE";
      if(index == M30_STRATEGY_ENGULFING) return "ENGULFING";
      if(index == M30_STRATEGY_BREAKOUT) return "BREAKOUT";
      if(index == M30_STRATEGY_INSTITUTIONAL) return "INSTITUTIONAL ZONES";
      if(index == M30_STRATEGY_PREMIUM_DISCOUNT) return "PREMIUM/DISCOUNT";
      if(index == M30_STRATEGY_FALSE_BREAKOUT) return "FALSE BREAKOUT";
      if(index == M30_STRATEGY_SESSION) return "SESSION";
      return "MOMENTUM";
     }

   bool StrategyEnabled(const int index)
     {
      if(index < 0 || index >= 10) return false;
      return m_runtime_strategy_enabled[index];
     }

   void PublishDashboard(CMTFTrendAnalysis &mtf_analysis,
                         const bool paused)
     {
      string rows[10];
      string levels[5];
      string plan[7];
      string na = "N/A";
      string price_high = m_snapshot.data_ready && m_snapshot.latest_high.valid ? DoubleToString(m_snapshot.latest_high.price, _Digits) : na;
      string price_low = m_snapshot.data_ready && m_snapshot.latest_low.valid ? DoubleToString(m_snapshot.latest_low.price, _Digits) : na;
      string support_text = m_snapshot.data_ready && m_snapshot.support_valid ? DoubleToString(m_snapshot.support_low, _Digits) + "-" + DoubleToString(m_snapshot.support_high, _Digits) : na;
      string resistance_text = m_snapshot.data_ready && m_snapshot.resistance_valid ? DoubleToString(m_snapshot.resistance_low, _Digits) + "-" + DoubleToString(m_snapshot.resistance_high, _Digits) : na;
      string bsl_text = m_snapshot.data_ready && m_snapshot.buy_liquidity_valid ? DoubleToString(m_snapshot.buy_liquidity_level, _Digits) : na;
      string ssl_text = m_snapshot.data_ready && m_snapshot.sell_liquidity_valid ? DoubleToString(m_snapshot.sell_liquidity_level, _Digits) : na;
      string fvg_text = m_snapshot.data_ready && (m_snapshot.bullish_fvg_valid || m_snapshot.bearish_fvg_valid) ?
                        DoubleToString(m_snapshot.fvg_low, _Digits) + "-" + DoubleToString(m_snapshot.fvg_high, _Digits) : na;
      string ob_text = m_snapshot.data_ready && m_snapshot.order_block_valid ?
                       DoubleToString(m_snapshot.order_block_low, _Digits) + "-" + DoubleToString(m_snapshot.order_block_high, _Digits) : na;
      levels[0] = "Swing H " + price_high + " | L " + price_low;
      levels[1] = "Support " + support_text + " | Resistance " + resistance_text;
      levels[2] = "BSL " + bsl_text + " | SSL " + ssl_text;
      levels[3] = "FVG " + fvg_text + " | Order block " + ob_text;
      levels[4] = "Range " + (m_snapshot.data_ready && m_snapshot.range_low > 0.0 ? DoubleToString(m_snapshot.range_low, _Digits) : na) +
                  " - " + (m_snapshot.data_ready && m_snapshot.range_high > 0.0 ? DoubleToString(m_snapshot.range_high, _Digits) : na);
      string direction = !m_snapshot.data_ready ? na : (m_snapshot.trade_direction > 0 ? "BUY" : (m_snapshot.trade_direction < 0 ? "SELL" : "N/A"));
      string entry_high = m_snapshot.data_ready && m_snapshot.trade_plan_valid ? DoubleToString(m_snapshot.entry_zone_high, _Digits) : na;
      string entry_low = m_snapshot.data_ready && m_snapshot.trade_plan_valid ? DoubleToString(m_snapshot.entry_zone_low, _Digits) : na;
      string entry = m_snapshot.data_ready && m_snapshot.trade_plan_valid ? DoubleToString(m_snapshot.preferred_entry, _Digits) : na;
      string stop = m_snapshot.data_ready && m_snapshot.trade_plan_valid ? DoubleToString(m_snapshot.stop_loss, _Digits) : na;
      string tp1 = m_snapshot.data_ready && m_snapshot.trade_plan_valid ? DoubleToString(m_snapshot.take_profit_1, _Digits) : na;
      string tp2 = m_snapshot.data_ready && m_snapshot.trade_plan_valid ? DoubleToString(m_snapshot.take_profit_2, _Digits) : na;
      string tp3 = m_snapshot.data_ready && m_snapshot.trade_plan_valid ? DoubleToString(m_snapshot.take_profit_3, _Digits) : na;
      string rr = m_snapshot.data_ready && m_snapshot.trade_plan_valid ? DoubleToString(m_snapshot.risk_reward_tp3, 2) + "R" : na;
      string lot = m_snapshot.data_ready && m_snapshot.lot_size > 0.0 ? DoubleToString(m_snapshot.lot_size, VolumePrecision(SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP))) : na;
      string money = m_snapshot.data_ready && m_snapshot.estimated_money_risk > 0.0 ?
                     DoubleToString(m_snapshot.estimated_money_risk, 2) + " " + AccountInfoString(ACCOUNT_CURRENCY) : na;
      plan[0] = "Direction " + direction + " | Status " + (m_snapshot.data_ready ? m_snapshot.trade_plan_status : "INSUFFICIENT DATA");
      plan[1] = "Entry high " + entry_high + " | Entry low " + entry_low;
      plan[2] = "Preferred entry " + entry + " | Stop loss " + stop;
      plan[3] = "TP1 " + tp1 + " | TP2 " + tp2;
      plan[4] = "TP3 " + tp3 + " | Risk/reward " + rr;
      plan[5] = "Lot size " + lot + " | Est. risk " + money;
      plan[6] = "Mode ANALYSIS ONLY | Permission OFF";
      for(int i = 0; i < 10; i++)
        {
         M30StrategyResult item = m_snapshot.strategies[i];
         bool enabled = mtf_analysis.M30StrategyEnabled(i);
         string state = enabled ? item.status : "OFF";
         if(paused && enabled)
            state = m_snapshot.data_ready ? "PAUSED / " + state : "WAITING";
         string price = item.key_price > 0.0 ? DoubleToString(item.key_price, _Digits) : "n/a";
         rows[i] = StringFormat("%02d %s | B %.1f S %.1f | %s | %s | %s",
                                i + 1, StrategyName(i), item.buy_points,
                                item.sell_points, state, price,
                                item.explanation);
        }
      string summary;
      string reason = m_snapshot.data_ready ? m_snapshot.reason : "Waiting for M30 history";
      if(paused)
        {
         summary = "ANALYSIS OFF" +
                   (m_snapshot.data_ready ? " | last result: " + m_snapshot.result + " | values preserved" :
                                            " | waiting for analysis and M30 history");
         reason = "M30 analysis is disabled; previous results and drawings are preserved";
        }
      else
        {
         summary = "BUY " + DoubleToString(m_snapshot.buy_evidence_percent, 1) +
                   "% | SELL " + DoubleToString(m_snapshot.sell_evidence_percent, 1) +
                   "% | NEU " + DoubleToString(MathMax(0.0, 100.0 - m_snapshot.buy_evidence_percent - m_snapshot.sell_evidence_percent), 1) +
                   "% | ON " + IntegerToString(m_snapshot.active_strategy_count) +
                   " C " + IntegerToString(m_snapshot.confirmed_strategy_count) +
                   " D " + IntegerToString(m_snapshot.developing_strategy_count);
         reason = m_snapshot.result + " | " + m_snapshot.reason;
        }
      if(paused && m_snapshot.data_ready)
         reason = m_snapshot.result + " | " + reason;
      mtf_analysis.SetM30DashboardData(summary, reason, rows, 10,
                                       levels, 5, plan, 7);
     }

   double StrategyWeight(const int index)
     {
      if(index == M30_STRATEGY_STRUCTURE) return M30InpWeightStructure;
      if(index == M30_STRATEGY_LIQUIDITY) return M30InpWeightLiquidity;
      if(index == M30_STRATEGY_SUPPORT_RESISTANCE) return M30InpWeightSupportResistance;
      if(index == M30_STRATEGY_ENGULFING) return M30InpWeightEngulfing;
      if(index == M30_STRATEGY_BREAKOUT) return M30InpWeightBreakout;
      if(index == M30_STRATEGY_INSTITUTIONAL) return M30InpWeightInstitutional;
      if(index == M30_STRATEGY_PREMIUM_DISCOUNT) return M30InpWeightPremiumDiscount;
      if(index == M30_STRATEGY_FALSE_BREAKOUT) return M30InpWeightFalseBreakout;
      if(index == M30_STRATEGY_SESSION) return M30InpWeightSession;
      return M30InpWeightMomentum;
     }

   bool InputsValid()
     {
      int required = M30InpSwingLeftBars + M30InpSwingRightBars +
                     M30InpATRPeriod + M30InpDealingRangeBars + 10;
      return (M30InpLookbackBars >= required &&
              M30InpSwingLeftBars >= 1 && M30InpSwingRightBars >= 1 &&
              M30InpATRPeriod >= 2 && M30InpRSIPeriod >= 2 &&
              M30InpMACDFast >= 2 && M30InpMACDSlow > M30InpMACDFast &&
              M30InpMACDSignal >= 2 && M30InpADXPeriod >= 2 &&
              M30InpEqualTolerancePoints >= 0.0 &&
              M30InpEqualToleranceATR >= 0.0 && M30InpRangeBars >= 3 &&
              M30InpDealingRangeBars >= 8 && M30InpZoneHalfWidthATR > 0.0 &&
              M30InpBreakBufferATR >= 0.0 && M30InpMinimumDisplacementATR >= 0.0 &&
              M30InpOTEStart > 0.0 && M30InpOTEStart < M30InpOTEEnd &&
              M30InpOTEEnd < 1.0 && M30InpFalseBreakMaxATR > 0.0 &&
              M30InpADXStrengthLevel >= 0.0 &&
              M30InpMinimumIndependentSignals >= 1 &&
              M30InpConfirmationThreshold >= 0.0 &&
              M30InpConfirmationThreshold <= 100.0 &&
              M30InpMinimumScoreSeparation >= 0.0 &&
              M30InpTradePlanRiskPercent > 0.0 && M30InpTradePlanRiskPercent <= 5.0 &&
              M30InpTradePlanStopBufferATR >= 0.0 &&
              M30InpAsiaStartHour >= 0 && M30InpAsiaStartHour <= 23 &&
              M30InpAsiaEndHour >= 0 && M30InpAsiaEndHour <= 23 &&
              M30InpLondonStartHour >= 0 && M30InpLondonStartHour <= 23 &&
              M30InpLondonEndHour >= 0 && M30InpLondonEndHour <= 23 &&
              M30InpNewYorkStartHour >= 0 && M30InpNewYorkStartHour <= 23 &&
              M30InpNewYorkEndHour >= 0 && M30InpNewYorkEndHour <= 23 &&
              M30InpSummerAsiaStartHour >= 0 && M30InpSummerAsiaStartHour <= 23 &&
              M30InpSummerAsiaEndHour >= 0 && M30InpSummerAsiaEndHour <= 23 &&
              M30InpSummerLondonStartHour >= 0 && M30InpSummerLondonStartHour <= 23 &&
              M30InpSummerLondonEndHour >= 0 && M30InpSummerLondonEndHour <= 23 &&
              M30InpSummerNewYorkStartHour >= 0 && M30InpSummerNewYorkStartHour <= 23 &&
              M30InpSummerNewYorkEndHour >= 0 && M30InpSummerNewYorkEndHour <= 23 &&
              M30InpWeightStructure >= 0 && M30InpWeightLiquidity >= 0 &&
              M30InpWeightSupportResistance >= 0 && M30InpWeightEngulfing >= 0 &&
              M30InpWeightBreakout >= 0 && M30InpWeightInstitutional >= 0 &&
              M30InpWeightPremiumDiscount >= 0 && M30InpWeightFalseBreakout >= 0 &&
              M30InpWeightSession >= 0 && M30InpWeightMomentum >= 0);
     }

   bool ReadBuffer(const int handle,
                   const int buffer_number,
                   const int shift,
                   double &value)
     {
      if(handle == INVALID_HANDLE || shift < 0)
         return false;
      double sample[1];
      if(CopyBuffer(handle, buffer_number, shift, 1, sample) != 1)
         return false;
      value = sample[0];
      return MathIsValidNumber(value);
     }

   void AddPivot(M30SwingPoint &points[],
                 int &count,
                 const int shift,
                 const bool is_high)
     {
      if(count >= 8 || shift < 0 || shift >= ArraySize(m_rates))
         return;
      M30SwingPoint point;
      ResetSwing(point);
      point.valid = true;
      point.is_high = is_high;
      point.shift = shift;
      point.time = m_rates[shift].time;
      point.price = is_high ? m_rates[shift].high : m_rates[shift].low;
      if(count > 0)
        {
         if(is_high)
            point.classification = point.price > points[0].price ? "HH" : "LH";
         else
            point.classification = point.price > points[0].price ? "HL" : "LL";
        }
      else
         point.classification = is_high ? "H" : "L";
      for(int i = count; i > 0; i--)
         points[i] = points[i - 1];
      points[0] = point;
      count++;
     }

   void FindPivots()
     {
      m_high_count = 0;
      m_low_count = 0;
      for(int i = 0; i < 8; i++)
        {
         ResetSwing(m_high_pivots[i]);
         ResetSwing(m_low_pivots[i]);
        }
      int bars = ArraySize(m_rates);
      int first = M30InpSwingRightBars + 1;
      int last = bars - M30InpSwingLeftBars - 1;
      for(int shift = first; shift <= last && (m_high_count < 8 || m_low_count < 8); shift++)
        {
         bool high = true;
         bool low = true;
         for(int n = 1; n <= M30InpSwingRightBars; n++)
           {
            if(m_rates[shift].high <= m_rates[shift - n].high) high = false;
            if(m_rates[shift].low >= m_rates[shift - n].low) low = false;
           }
         for(int n = 1; n <= M30InpSwingLeftBars; n++)
           {
            if(m_rates[shift].high <= m_rates[shift + n].high) high = false;
            if(m_rates[shift].low >= m_rates[shift + n].low) low = false;
           }
         if(high) AddPivot(m_high_pivots, m_high_count, shift, true);
         if(low) AddPivot(m_low_pivots, m_low_count, shift, false);
        }
      if(m_high_count >= 2)
        {
         m_high_pivots[0].classification = m_high_pivots[0].price > m_high_pivots[1].price ? "HH" : "LH";
         m_high_pivots[1].classification = m_high_pivots[1].price > (m_high_count > 2 ? m_high_pivots[2].price : m_high_pivots[1].price) ? "HH" : "LH";
        }
      if(m_low_count >= 2)
        {
         m_low_pivots[0].classification = m_low_pivots[0].price > m_low_pivots[1].price ? "HL" : "LL";
         m_low_pivots[1].classification = m_low_pivots[1].price > (m_low_count > 2 ? m_low_pivots[2].price : m_low_pivots[1].price) ? "HL" : "LL";
        }
     }

   void AddEvidence(const int index,
                    const int direction,
                    const double strength,
                    const bool confirmed,
                    const string explanation,
                    const double price,
                    const datetime event_time,
                    const double zone_low = 0.0,
                    const double zone_high = 0.0)
     {
      if(index < 0 || index >= 10 || direction == 0)
         return;
      m_snapshot.strategies[index].enabled = StrategyEnabled(index);
      m_snapshot.strategies[index].weight = StrategyWeight(index);
      m_snapshot.strategies[index].direction = direction;
      m_snapshot.strategies[index].confirmed = confirmed;
      m_snapshot.strategies[index].developing = !confirmed;
      m_snapshot.strategies[index].invalidated = false;
      m_snapshot.strategies[index].key_price = price;
      m_snapshot.strategies[index].zone_low = zone_low;
      m_snapshot.strategies[index].zone_high = zone_high;
      m_snapshot.strategies[index].event_time = event_time;
      m_snapshot.strategies[index].status = confirmed ? "CONFIRMED" : "DEVELOPING";
      m_snapshot.strategies[index].explanation = explanation;
      if(!m_snapshot.strategies[index].enabled)
         return;
      double bounded_strength = MathMax(0.0, MathMin(1.0, strength));
      double context_factor = 1.0;
      if(m_d1.ready && (int)m_d1.direction != 0 &&
         (int)m_d1.direction != direction)
         context_factor *= 0.65;
      if(m_h4.ready && m_h4.direction != 0 && m_h4.direction != direction)
         context_factor *= 0.70;
      if(m_h1.ready)
        {
         if(direction > 0 && m_h1.supply.valid &&
            m_rates[1].close <= m_h1.supply.high && m_rates[1].close >= m_h1.supply.low)
            context_factor *= 0.72;
         if(direction < 0 && m_h1.demand.valid &&
            m_rates[1].close <= m_h1.demand.high && m_rates[1].close >= m_h1.demand.low)
            context_factor *= 0.72;
        }
      double points = m_snapshot.strategies[index].weight * bounded_strength * context_factor;
      if(direction > 0) m_snapshot.strategies[index].buy_points = points;
      else m_snapshot.strategies[index].sell_points = points;
     }

   void AnalyzeStructure()
     {
      m_bullish_bos = false;
      m_bearish_bos = false;
      m_bullish_choch = false;
      m_bearish_choch = false;
      m_snapshot.bullish_mss = false;
      m_snapshot.bearish_mss = false;
      int structure_direction = 0;
      if(m_high_count >= 2 && m_low_count >= 2)
        {
         bool higher_high = m_high_pivots[0].price > m_high_pivots[1].price;
         bool higher_low = m_low_pivots[0].price > m_low_pivots[1].price;
         bool lower_high = m_high_pivots[0].price < m_high_pivots[1].price;
         bool lower_low = m_low_pivots[0].price < m_low_pivots[1].price;
         if(higher_high && higher_low) structure_direction = 1;
         else if(lower_high && lower_low) structure_direction = -1;
        }
      double buffer = m_atr * M30InpBreakBufferATR;
      if(m_high_count > 0 && m_rates[1].close > m_high_pivots[0].price + buffer &&
         m_rates[2].close <= m_high_pivots[0].price + buffer)
        {
         m_bullish_bos = (structure_direction >= 0);
         m_bullish_choch = (structure_direction < 0);
         if(m_bullish_choch) structure_direction = 1;
        }
      if(m_low_count > 0 && m_rates[1].close < m_low_pivots[0].price - buffer &&
         m_rates[2].close >= m_low_pivots[0].price - buffer)
        {
         m_bearish_bos = (structure_direction <= 0);
         m_bearish_choch = (structure_direction > 0);
         if(m_bearish_choch) structure_direction = -1;
        }
      m_snapshot.structure_direction = structure_direction;
      m_snapshot.bullish_bos = m_bullish_bos;
      m_snapshot.bearish_bos = m_bearish_bos;
      m_snapshot.bullish_choch = m_bullish_choch;
      m_snapshot.bearish_choch = m_bearish_choch;
      double displacement = MathAbs(m_rates[1].close - m_rates[1].open);
      m_snapshot.bullish_mss = m_bullish_choch && displacement >= m_atr * M30InpMinimumDisplacementATR;
      m_snapshot.bearish_mss = m_bearish_choch && displacement >= m_atr * M30InpMinimumDisplacementATR;
      if(m_bullish_bos || m_bullish_choch)
         AddEvidence(M30_STRATEGY_STRUCTURE, 1,
                     m_bullish_choch ? (m_snapshot.bullish_mss ? 1.0 : 0.75) : 1.0, true,
                     m_bullish_choch ? (m_snapshot.bullish_mss ? "Bullish CHoCH + MSS: displacement closed through a confirmed swing high" :
                                                                "Bullish CHoCH: closed M30 candle broke a confirmed swing high") :
                                      "Bullish BOS: closed M30 candle broke a confirmed swing high",
                     m_high_pivots[0].price, m_rates[1].time);
      else if(m_bearish_bos || m_bearish_choch)
         AddEvidence(M30_STRATEGY_STRUCTURE, -1,
                     m_bearish_choch ? (m_snapshot.bearish_mss ? 1.0 : 0.75) : 1.0, true,
                     m_bearish_choch ? (m_snapshot.bearish_mss ? "Bearish CHoCH + MSS: displacement closed through a confirmed swing low" :
                                                                "Bearish CHoCH: closed M30 candle broke a confirmed swing low") :
                                      "Bearish BOS: closed M30 candle broke a confirmed swing low",
                     m_low_pivots[0].price, m_rates[1].time);
      else if(m_high_count > 0 && m_low_count > 0 && structure_direction != 0)
         AddEvidence(M30_STRATEGY_STRUCTURE, structure_direction, 0.35, false,
                     "Confirmed swing sequence is directional; no new closed-candle break",
                     structure_direction > 0 ? m_high_pivots[0].price : m_low_pivots[0].price,
                     m_rates[1].time);
     }

   void AnalyzeLiquidity()
     {
      m_bullish_sweep = false;
      m_bearish_sweep = false;
      m_reclaim = false;
      double tolerance = MathMax(M30InpEqualTolerancePoints * _Point,
                                m_atr * M30InpEqualToleranceATR);
      bool equal_highs = m_high_count >= 2 &&
                         MathAbs(m_high_pivots[0].price - m_high_pivots[1].price) <= tolerance;
      bool equal_lows = m_low_count >= 2 &&
                        MathAbs(m_low_pivots[0].price - m_low_pivots[1].price) <= tolerance;
      m_buy_liquidity = 0.0;
      m_sell_liquidity = 0.0;
      if(equal_highs)
         m_buy_liquidity = (m_high_pivots[0].price + m_high_pivots[1].price) * 0.5;
      else if(m_high_count > 0)
         m_buy_liquidity = m_high_pivots[0].price;
      if(equal_lows)
         m_sell_liquidity = (m_low_pivots[0].price + m_low_pivots[1].price) * 0.5;
      else if(m_low_count > 0)
         m_sell_liquidity = m_low_pivots[0].price;
      if(m_sell_liquidity > 0.0 && m_rates[1].low < m_sell_liquidity - tolerance * 0.10 &&
         m_rates[1].close > m_sell_liquidity)
         m_bullish_sweep = true;
      if(m_buy_liquidity > 0.0 && m_rates[1].high > m_buy_liquidity + tolerance * 0.10 &&
         m_rates[1].close < m_buy_liquidity)
         m_bearish_sweep = true;
      m_reclaim = m_bullish_sweep || m_bearish_sweep;
      m_snapshot.buy_liquidity_valid = (m_buy_liquidity > 0.0);
      m_snapshot.sell_liquidity_valid = (m_sell_liquidity > 0.0);
      m_snapshot.equal_highs_valid = equal_highs;
      m_snapshot.equal_lows_valid = equal_lows;
      m_snapshot.equal_highs_level = equal_highs ? m_buy_liquidity : 0.0;
      m_snapshot.equal_lows_level = equal_lows ? m_sell_liquidity : 0.0;
      m_snapshot.buy_liquidity_level = m_buy_liquidity;
      m_snapshot.sell_liquidity_level = m_sell_liquidity;
      m_snapshot.bullish_sweep = m_bullish_sweep;
      m_snapshot.bearish_sweep = m_bearish_sweep;
      m_snapshot.reclaim_confirmed = m_reclaim;
      if(m_bullish_sweep)
         AddEvidence(M30_STRATEGY_LIQUIDITY, 1, 1.0, true,
                     "Sell-side liquidity swept and closed back above the pool",
                     m_sell_liquidity, m_rates[1].time);
      else if(m_bearish_sweep)
         AddEvidence(M30_STRATEGY_LIQUIDITY, -1, 1.0, true,
                     "Buy-side liquidity swept and closed back below the pool",
                     m_buy_liquidity, m_rates[1].time);
      else if(m_buy_liquidity > 0.0 || m_sell_liquidity > 0.0)
        {
         int direction = m_buy_liquidity > 0.0 && m_sell_liquidity > 0.0 ? 0 :
                         (m_sell_liquidity > 0.0 ? 1 : -1);
         if(direction != 0)
            AddEvidence(M30_STRATEGY_LIQUIDITY, direction, 0.20, false,
                        "Liquidity pool identified; no sweep and reclaim confirmed",
                        direction > 0 ? m_sell_liquidity : m_buy_liquidity,
                        m_rates[1].time);
        }
     }

   int CountTouches(const double low,
                    const double high,
                    const int start_shift,
                    const int end_shift)
     {
      int tests = 0;
      int last = (int)MathMin(ArraySize(m_rates) - 1, end_shift);
      for(int i = start_shift; i <= last; i++)
         if(m_rates[i].low <= high && m_rates[i].high >= low)
            tests++;
      return tests;
     }

   void AnalyzeSupportResistance()
     {
      m_support_low = 0.0;
      m_support_high = 0.0;
      m_resistance_low = 0.0;
      m_resistance_high = 0.0;
      double half = m_atr * M30InpZoneHalfWidthATR;
      if(m_low_count > 0)
        {
         m_support_low = m_low_pivots[0].price - half;
         m_support_high = m_low_pivots[0].price + half;
        }
      if(m_high_count > 0)
        {
         m_resistance_low = m_high_pivots[0].price - half;
         m_resistance_high = m_high_pivots[0].price + half;
        }
      m_snapshot.support_low = m_support_low;
      m_snapshot.support_high = m_support_high;
      m_snapshot.resistance_low = m_resistance_low;
      m_snapshot.resistance_high = m_resistance_high;
      m_snapshot.support_tests = m_support_low > 0.0 ? CountTouches(m_support_low, m_support_high, 1, 60) : 0;
      m_snapshot.resistance_tests = m_resistance_low > 0.0 ? CountTouches(m_resistance_low, m_resistance_high, 1, 60) : 0;
      m_snapshot.support_invalidated = m_support_low > 0.0 &&
                                       m_rates[1].close < m_support_low - m_atr * M30InpBreakBufferATR;
      m_snapshot.resistance_invalidated = m_resistance_high > 0.0 &&
                                          m_rates[1].close > m_resistance_high + m_atr * M30InpBreakBufferATR;
      m_snapshot.support_valid = m_support_low > 0.0 && !m_snapshot.support_invalidated;
      m_snapshot.resistance_valid = m_resistance_low > 0.0 && !m_snapshot.resistance_invalidated;
      m_snapshot.level_retest = "NONE";
      bool at_support = m_snapshot.support_valid && m_rates[1].low <= m_support_high &&
                        m_rates[1].high >= m_support_low;
      bool at_resistance = m_snapshot.resistance_valid && m_rates[1].low <= m_resistance_high &&
                           m_rates[1].high >= m_resistance_low;
      bool rbs = m_resistance_low > 0.0 && m_rates[2].close > m_resistance_high &&
                 m_rates[1].low <= m_resistance_high && m_rates[1].close > m_resistance_high;
      bool sbr = m_support_low > 0.0 && m_rates[2].close < m_support_low &&
                 m_rates[1].high >= m_support_low && m_rates[1].close < m_support_low;
      if(rbs) m_snapshot.level_retest = "RBS";
      if(sbr) m_snapshot.level_retest = "SBR";
      if(at_support)
         AddEvidence(M30_STRATEGY_SUPPORT_RESISTANCE, 1,
                     m_rates[1].close > m_rates[1].open ? 0.80 : 0.45,
                     m_rates[1].close > m_rates[1].open,
                     "Price tested swing-low support zone; tests=" +
                     IntegerToString(m_snapshot.support_tests),
                     (m_support_low + m_support_high) * 0.5, m_rates[1].time,
                     m_support_low, m_support_high);
      else if(at_resistance)
         AddEvidence(M30_STRATEGY_SUPPORT_RESISTANCE, -1,
                     m_rates[1].close < m_rates[1].open ? 0.80 : 0.45,
                     m_rates[1].close < m_rates[1].open,
                     "Price tested swing-high resistance zone; tests=" +
                     IntegerToString(m_snapshot.resistance_tests),
                     (m_resistance_low + m_resistance_high) * 0.5, m_rates[1].time,
                     m_resistance_low, m_resistance_high);
      else if(rbs)
         AddEvidence(M30_STRATEGY_SUPPORT_RESISTANCE, 1, 0.85, true,
                     "Resistance converted to support and held on a closed-candle retest",
                     m_resistance_high, m_rates[1].time, m_resistance_low, m_resistance_high);
      else if(sbr)
         AddEvidence(M30_STRATEGY_SUPPORT_RESISTANCE, -1, 0.85, true,
                     "Support converted to resistance and held on a closed-candle retest",
                     m_support_low, m_rates[1].time, m_support_low, m_support_high);
      else if(m_low_count > 0 && m_high_count > 0)
         m_snapshot.strategies[M30_STRATEGY_SUPPORT_RESISTANCE].explanation =
            "Swing-based zones active; current candle is outside both zones";
     }

   bool IsBullishEngulfing(const int current_shift,
                           const int previous_shift)
     {
      return (m_rates[current_shift].close > m_rates[current_shift].open &&
              m_rates[previous_shift].close < m_rates[previous_shift].open &&
              m_rates[current_shift].open <= m_rates[previous_shift].close &&
              m_rates[current_shift].close >= m_rates[previous_shift].open);
     }

   bool IsBearishEngulfing(const int current_shift,
                           const int previous_shift)
     {
      return (m_rates[current_shift].close < m_rates[current_shift].open &&
              m_rates[previous_shift].close > m_rates[previous_shift].open &&
              m_rates[current_shift].open >= m_rates[previous_shift].close &&
              m_rates[current_shift].close <= m_rates[previous_shift].open);
     }

   void AnalyzeEngulfing()
     {
      bool bull_now = IsBullishEngulfing(1, 2);
      bool bear_now = IsBearishEngulfing(1, 2);
      bool bull_failed = IsBullishEngulfing(2, 3) && m_rates[1].close < m_rates[2].low;
      bool bear_failed = IsBearishEngulfing(2, 3) && m_rates[1].close > m_rates[2].high;
      if(bull_failed)
        {
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].enabled = StrategyEnabled(M30_STRATEGY_ENGULFING);
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].weight = StrategyWeight(M30_STRATEGY_ENGULFING);
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].invalidated = true;
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].status = "INVALIDATED";
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].explanation = "Bullish engulfing invalidated by a later closed candle below its low";
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].key_price = m_rates[2].low;
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].event_time = m_rates[1].time;
        }
      else if(bear_failed)
        {
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].enabled = StrategyEnabled(M30_STRATEGY_ENGULFING);
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].weight = StrategyWeight(M30_STRATEGY_ENGULFING);
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].invalidated = true;
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].status = "INVALIDATED";
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].explanation = "Bearish engulfing invalidated by a later closed candle above its high";
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].key_price = m_rates[2].high;
         m_snapshot.strategies[M30_STRATEGY_ENGULFING].event_time = m_rates[1].time;
        }
      else if(bull_now)
         AddEvidence(M30_STRATEGY_ENGULFING, 1, 0.85, true,
                     "Closed bullish candle body fully engulfed the prior bearish body",
                     m_rates[1].close, m_rates[1].time,
                     m_rates[1].low, m_rates[1].high);
      else if(bear_now)
         AddEvidence(M30_STRATEGY_ENGULFING, -1, 0.85, true,
                     "Closed bearish candle body fully engulfed the prior bullish body",
                     m_rates[1].close, m_rates[1].time,
                     m_rates[1].low, m_rates[1].high);
     }

   void AnalyzeBreakout()
     {
      int start = 2;
      int end = (int)MathMin(ArraySize(m_rates) - 1, M30InpRangeBars + 1);
      m_range_high = -DBL_MAX;
      m_range_low = DBL_MAX;
      for(int i = start; i <= end; i++)
        {
         m_range_high = MathMax(m_range_high, m_rates[i].high);
         m_range_low = MathMin(m_range_low, m_rates[i].low);
        }
      m_breakout_valid = false;
      m_breakout_direction = 0;
      m_breakout_level = 0.0;
      m_snapshot.breakout_retest = false;
      m_false_breakout_valid = false;
      m_false_breakout_direction = 0;
      m_snapshot.false_breakout_valid = false;
      m_snapshot.false_breakout_direction = 0;
      double buffer = m_atr * M30InpBreakBufferATR;
      if(m_rates[1].close > m_range_high + buffer)
        {
         m_breakout_valid = true;
         m_breakout_direction = 1;
         m_breakout_level = m_range_high;
         AddEvidence(M30_STRATEGY_BREAKOUT, 1, 0.75, true,
                     "Closed candle broke above the prior completed-candle range",
                     m_range_high, m_rates[1].time, m_range_low, m_range_high);
        }
      else if(m_rates[1].close < m_range_low - buffer)
        {
         m_breakout_valid = true;
         m_breakout_direction = -1;
         m_breakout_level = m_range_low;
         AddEvidence(M30_STRATEGY_BREAKOUT, -1, 0.75, true,
                     "Closed candle broke below the prior completed-candle range",
                     m_range_low, m_rates[1].time, m_range_low, m_range_high);
        }
      else if(m_rates[1].high > m_range_high + buffer && m_rates[1].close <= m_range_high)
        {
         m_false_breakout_valid = true;
         m_false_breakout_direction = -1;
         m_breakout_level = m_range_high;
        }
      else if(m_rates[1].low < m_range_low - buffer && m_rates[1].close >= m_range_low)
        {
         m_false_breakout_valid = true;
         m_false_breakout_direction = 1;
         m_breakout_level = m_range_low;
        }
      if(!m_breakout_valid && !m_false_breakout_valid)
        {
         double prior_high = -DBL_MAX;
         double prior_low = DBL_MAX;
         int prior_end = (int)MathMin(ArraySize(m_rates) - 1, M30InpRangeBars + 2);
         for(int i = 3; i <= prior_end; i++)
           {
            prior_high = MathMax(prior_high, m_rates[i].high);
            prior_low = MathMin(prior_low, m_rates[i].low);
           }
         if(prior_high > 0.0 && m_rates[2].close > prior_high + buffer &&
            m_rates[1].low <= prior_high + buffer && m_rates[1].close > prior_high)
           {
            m_breakout_valid = true;
            m_breakout_direction = 1;
            m_breakout_level = prior_high;
            m_snapshot.breakout_retest = true;
            AddEvidence(M30_STRATEGY_BREAKOUT, 1, 1.0, true,
                        "Prior close broke the range; closed M30 candle retested and held the breakout level",
                        prior_high, m_rates[1].time, prior_low, prior_high);
           }
         else if(prior_low < DBL_MAX && m_rates[2].close < prior_low - buffer &&
                 m_rates[1].high >= prior_low - buffer && m_rates[1].close < prior_low)
           {
            m_breakout_valid = true;
            m_breakout_direction = -1;
            m_breakout_level = prior_low;
            m_snapshot.breakout_retest = true;
            AddEvidence(M30_STRATEGY_BREAKOUT, -1, 1.0, true,
                        "Prior close broke the range; closed M30 candle retested and held below the breakout level",
                        prior_low, m_rates[1].time, prior_low, prior_high);
           }
        }
      m_snapshot.range_high = m_range_high;
      m_snapshot.range_low = m_range_low;
      m_snapshot.breakout_valid = m_breakout_valid;
      m_snapshot.breakout_direction = m_breakout_direction;
      m_snapshot.breakout_level = m_breakout_level;
     }

   void AnalyzeInstitutionalZones()
     {
      m_fvg_valid = false;
      m_fvg_bullish = false;
      m_fvg_low = 0.0;
      m_fvg_high = 0.0;
      m_fvg_time = 0;
      m_fvg_start_time = 0;
      int limit = (int)MathMin(24, ArraySize(m_rates) - 3);
      for(int shift = 1; shift <= limit; shift++)
        {
         // In series indexing, shift is candle three and shift+2 is candle one.
         if(m_rates[shift].low > m_rates[shift + 2].high)
           {
            m_fvg_valid = true;
            m_fvg_bullish = true;
            m_fvg_low = m_rates[shift + 2].high;
            m_fvg_high = m_rates[shift].low;
            m_fvg_time = m_rates[shift].time;
            m_fvg_start_time = m_rates[shift + 2].time;
            break;
           }
         if(m_rates[shift].high < m_rates[shift + 2].low)
           {
            m_fvg_valid = true;
            m_fvg_bullish = false;
            m_fvg_low = m_rates[shift].high;
            m_fvg_high = m_rates[shift + 2].low;
            m_fvg_time = m_rates[shift].time;
            m_fvg_start_time = m_rates[shift + 2].time;
            break;
           }
        }
      m_ob_valid = false;
      m_ob_direction = 0;
      m_ob_low = 0.0;
      m_ob_high = 0.0;
      m_ob_time = 0;
      bool structural_break = m_bullish_bos || m_bullish_choch || m_bearish_bos || m_bearish_choch;
      double body = MathAbs(m_rates[1].close - m_rates[1].open);
      if(structural_break && body >= m_atr * M30InpMinimumDisplacementATR)
        {
         int direction = (m_bullish_bos || m_bullish_choch) ? 1 : -1;
         for(int shift = 2; shift <= (int)MathMin(10, ArraySize(m_rates) - 1); shift++)
           {
            bool opposite = direction > 0 ? m_rates[shift].close < m_rates[shift].open :
                                             m_rates[shift].close > m_rates[shift].open;
            if(opposite)
              {
               m_ob_valid = true;
               m_ob_direction = direction;
               m_ob_low = m_rates[shift].low;
               m_ob_high = m_rates[shift].high;
               m_ob_time = m_rates[shift].time;
               break;
              }
           }
        }
      bool fvg_touch = m_fvg_valid && m_rates[1].low <= m_fvg_high && m_rates[1].high >= m_fvg_low;
      bool fvg_invalid = m_fvg_valid &&
                         (m_fvg_bullish ? m_rates[1].close < m_fvg_low :
                                          m_rates[1].close > m_fvg_high);
      m_snapshot.fvg_mitigated = fvg_touch;
      m_snapshot.fvg_invalidated = fvg_invalid;
      m_snapshot.ifvg_valid = fvg_invalid;
      m_snapshot.ifvg_direction = fvg_invalid ? (m_fvg_bullish ? -1 : 1) : 0;
      m_snapshot.bullish_fvg_valid = m_fvg_valid && m_fvg_bullish && !fvg_invalid;
      m_snapshot.bearish_fvg_valid = m_fvg_valid && !m_fvg_bullish && !fvg_invalid;
      m_snapshot.fvg_low = m_fvg_low;
      m_snapshot.fvg_high = m_fvg_high;
      m_snapshot.order_block_valid = m_ob_valid;
      m_snapshot.order_block_mitigated = m_ob_valid &&
                                         m_rates[1].low <= m_ob_high &&
                                         m_rates[1].high >= m_ob_low;
      m_snapshot.order_block_invalidated = m_ob_valid &&
                                           (m_ob_direction > 0 ? m_rates[1].close < m_ob_low :
                                                                 m_rates[1].close > m_ob_high);
      m_snapshot.breaker_block_valid = m_snapshot.order_block_invalidated;
      m_snapshot.breaker_block_direction = m_snapshot.breaker_block_valid ? -m_ob_direction : 0;
      m_snapshot.order_block_direction = m_ob_direction;
      m_snapshot.order_block_low = m_ob_low;
      m_snapshot.order_block_high = m_ob_high;
      if(m_ob_valid && !m_snapshot.order_block_invalidated)
        {
         int direction = m_ob_direction;
         double low = m_ob_low;
         double high = m_ob_high;
         bool touched = m_snapshot.order_block_mitigated;
         bool aligned = (direction > 0 && (m_bullish_bos || m_bullish_choch)) ||
                        (direction < 0 && (m_bearish_bos || m_bearish_choch));
         AddEvidence(M30_STRATEGY_INSTITUTIONAL, direction,
                     touched && aligned ? 1.0 : (aligned ? 0.75 : (touched ? 0.60 : 0.35)),
                     touched && aligned,
                     (m_ob_valid ? "Displacement-confirmed order block" : "Three-candle fair value gap") +
                     (touched ? " tested by the closed M30 candle" : " remains active; waiting for retest"),
                     (low + high) * 0.5, m_ob_valid ? m_ob_time : m_rates[1].time,
                     low, high);
        }
      else if(m_fvg_valid && !fvg_invalid)
        {
         int direction = m_fvg_bullish ? 1 : -1;
         bool aligned = (direction > 0 && (m_bullish_bos || m_bullish_choch)) ||
                        (direction < 0 && (m_bearish_bos || m_bearish_choch));
         AddEvidence(M30_STRATEGY_INSTITUTIONAL, direction,
                     fvg_touch && aligned ? 0.90 : (aligned ? 0.70 : (fvg_touch ? 0.55 : 0.30)),
                     fvg_touch && aligned,
                     "Three-candle fair value gap" +
                     (fvg_touch ? " mitigated by the closed M30 candle" : " active; waiting for mitigation"),
                     (m_fvg_low + m_fvg_high) * 0.5, m_fvg_time,
                     m_fvg_low, m_fvg_high);
        }
      else if(m_snapshot.breaker_block_valid)
         AddEvidence(M30_STRATEGY_INSTITUTIONAL, m_snapshot.breaker_block_direction,
                     0.60, false, "Invalidated order block is now a breaker block candidate",
                     (m_ob_low + m_ob_high) * 0.5, m_rates[1].time, m_ob_low, m_ob_high);
      else if(m_snapshot.ifvg_valid)
         AddEvidence(M30_STRATEGY_INSTITUTIONAL, m_snapshot.ifvg_direction,
                     0.60, false, "Fair value gap invalidated on a closed candle; inverse FVG candidate",
                     (m_fvg_low + m_fvg_high) * 0.5, m_rates[1].time, m_fvg_low, m_fvg_high);
     }

   void AnalyzePremiumDiscount()
     {
      int end = (int)MathMin(ArraySize(m_rates) - 1, M30InpDealingRangeBars);
      double high = -DBL_MAX;
      double low = DBL_MAX;
      for(int i = 1; i <= end; i++)
        {
         high = MathMax(high, m_rates[i].high);
         low = MathMin(low, m_rates[i].low);
        }
      double width = high - low;
      double equilibrium = (high + low) * 0.5;
      m_snapshot.range_high = MathMax(m_snapshot.range_high, high);
      m_snapshot.range_low = m_snapshot.range_low <= 0.0 ? low : MathMin(m_snapshot.range_low, low);
      m_snapshot.dealing_range_high = high;
      m_snapshot.dealing_range_low = low;
      m_snapshot.equilibrium = equilibrium;
      // OTE prices are retracement levels measured from the relevant range edge.
      if(m_snapshot.structure_direction < 0)
        {
         m_snapshot.ote_low = low + width * M30InpOTEStart;
         m_snapshot.ote_high = low + width * M30InpOTEEnd;
        }
      else
        {
         m_snapshot.ote_low = high - width * M30InpOTEEnd;
         m_snapshot.ote_high = high - width * M30InpOTEStart;
        }
      if(m_snapshot.structure_direction > 0 && m_rates[1].close < equilibrium)
         AddEvidence(M30_STRATEGY_PREMIUM_DISCOUNT, 1, 0.45, false,
                     "Price is in discount of the confirmed recent dealing range; location filter only",
                     equilibrium, m_rates[1].time, low, equilibrium);
      else if(m_snapshot.structure_direction < 0 && m_rates[1].close > equilibrium)
         AddEvidence(M30_STRATEGY_PREMIUM_DISCOUNT, -1, 0.45, false,
                     "Price is in premium of the confirmed recent dealing range; location filter only",
                     equilibrium, m_rates[1].time, equilibrium, high);
      else
         m_snapshot.strategies[M30_STRATEGY_PREMIUM_DISCOUNT].explanation =
            "Premium/discount is a location filter; current price does not support the M30 structure direction";
     }

   void AnalyzeFalseBreakout()
     {
      if(!m_false_breakout_valid)
        {
         m_snapshot.false_breakout_valid = false;
         return;
        }
      double excursion = m_false_breakout_direction > 0 ?
                         m_range_low - m_rates[1].low :
                         m_rates[1].high - m_range_high;
      if(excursion <= 0.0 || excursion > m_atr * M30InpFalseBreakMaxATR)
        {
         m_false_breakout_valid = false;
         m_snapshot.false_breakout_valid = false;
         return;
        }
      m_snapshot.false_breakout_valid = true;
      m_snapshot.false_breakout_direction = m_false_breakout_direction;
      AddEvidence(M30_STRATEGY_FALSE_BREAKOUT, m_false_breakout_direction,
                  0.90, true,
                  "Range boundary excursion was capped by ATR and the closed candle reclaimed the range",
                  m_breakout_level, m_rates[1].time,
                  m_range_low, m_range_high);
     }

   bool InSession(const int hour,
                  const int start_hour,
                  const int end_hour)
     {
      if(start_hour == end_hour) return false;
      if(start_hour < end_hour) return (hour >= start_hour && hour < end_hour);
      return (hour >= start_hour || hour < end_hour);
     }

   void SessionHours(const int index, int &start_hour, int &end_hour)
     {
      bool summer = M30InpUseSummerSessionHours && M30InpBrokerDSTInEffect;
      if(index == 0)
        {
         start_hour = summer ? M30InpSummerAsiaStartHour : M30InpAsiaStartHour;
         end_hour = summer ? M30InpSummerAsiaEndHour : M30InpAsiaEndHour;
        }
      else if(index == 1)
        {
         start_hour = summer ? M30InpSummerLondonStartHour : M30InpLondonStartHour;
         end_hour = summer ? M30InpSummerLondonEndHour : M30InpLondonEndHour;
        }
      else
        {
         start_hour = summer ? M30InpSummerNewYorkStartHour : M30InpNewYorkStartHour;
         end_hour = summer ? M30InpSummerNewYorkEndHour : M30InpNewYorkEndHour;
        }
     }

   void AnalyzeSessions()
     {
      int starts[3], ends[3];
      double highs[3], lows[3];
      for(int s = 0; s < 3; s++)
        {
         SessionHours(s, starts[s], ends[s]);
         highs[s] = -DBL_MAX;
         lows[s] = DBL_MAX;
        }
      MqlDateTime current_day;
      TimeToStruct(m_rates[1].time, current_day);
      for(int shift = 2; shift < ArraySize(m_rates); shift++)
        {
         MqlDateTime bar_time;
         TimeToStruct(m_rates[shift].time, bar_time);
         if(bar_time.year != current_day.year || bar_time.mon != current_day.mon ||
            bar_time.day != current_day.day)
            continue;
         for(int s = 0; s < 3; s++)
            if(InSession(bar_time.hour, starts[s], ends[s]))
              {
               highs[s] = MathMax(highs[s], m_rates[shift].high);
               lows[s] = MathMin(lows[s], m_rates[shift].low);
              }
        }
      for(int s = 0; s < 3; s++)
        {
         m_snapshot.session_high[s] = highs[s] == -DBL_MAX ? 0.0 : highs[s];
         m_snapshot.session_low[s] = lows[s] == DBL_MAX ? 0.0 : lows[s];
        }
      int direction = 0;
      double key = 0.0;
      bool is_breakout = false;
      bool is_judas = false;
      MqlDateTime closed_time;
      TimeToStruct(m_rates[1].time, closed_time);
      for(int s = 0; s < 3; s++)
        {
         if(highs[s] == -DBL_MAX || lows[s] == DBL_MAX ||
            !InSession(closed_time.hour, starts[s], ends[s]))
            continue;
         if(m_rates[1].low < lows[s] && m_rates[1].close > lows[s])
           { direction = 1; key = lows[s]; break; }
         if(m_rates[1].high > highs[s] && m_rates[1].close < highs[s])
           { direction = -1; key = highs[s]; break; }
         if(m_rates[1].close > highs[s])
           { direction = 1; key = highs[s]; is_breakout = true; break; }
         if(m_rates[1].close < lows[s])
           { direction = -1; key = lows[s]; is_breakout = true; break; }
        }
      if(InSession(closed_time.hour, starts[1], ends[1]) &&
         highs[0] != -DBL_MAX && lows[0] != DBL_MAX)
        {
         if(m_rates[1].low < lows[0] && m_rates[1].close > lows[0])
           { direction = 1; key = lows[0]; is_judas = true; is_breakout = false; }
         else if(m_rates[1].high > highs[0] && m_rates[1].close < highs[0])
           { direction = -1; key = highs[0]; is_judas = true; is_breakout = false; }
        }
      m_snapshot.session_breakout_valid = is_breakout;
      m_snapshot.session_breakout_direction = is_breakout ? direction : 0;
      m_snapshot.session_sweep_confirmed = direction != 0 && !is_breakout && !is_judas;
      m_snapshot.judas_swing_candidate = is_judas;
      if(direction != 0)
         AddEvidence(M30_STRATEGY_SESSION, direction, is_judas ? 0.75 : 0.70, !is_judas,
                     is_judas ? "London Judas swing candidate swept and reclaimed the Asian range" :
                     (is_breakout ? "Closed M30 candle broke the active session range" :
                                    "Session-range liquidity sweep and close reclaim using broker server-time hours"),
                     key, m_rates[1].time);
      else if(m_snapshot.session_high[0] > 0.0)
         m_snapshot.strategies[M30_STRATEGY_SESSION].explanation =
            "Session ranges tracked in broker server time; no confirmed sweep or breakout";
     }

   void AnalyzeMomentum()
     {
      double rsi1 = 0.0, rsi2 = 0.0;
      double macd1 = 0.0, macd2 = 0.0;
      double signal1 = 0.0, signal2 = 0.0;
      double adx1 = 0.0, plus1 = 0.0, minus1 = 0.0;
      bool ok = ReadBuffer(m_rsi_handle, 0, 1, rsi1) &&
                ReadBuffer(m_rsi_handle, 0, 2, rsi2) &&
                ReadBuffer(m_macd_handle, 0, 1, macd1) &&
                ReadBuffer(m_macd_handle, 0, 2, macd2) &&
                ReadBuffer(m_macd_handle, 1, 1, signal1) &&
                ReadBuffer(m_macd_handle, 1, 2, signal2) &&
                ReadBuffer(m_adx_handle, 0, 1, adx1) &&
                ReadBuffer(m_adx_handle, 1, 1, plus1) &&
                ReadBuffer(m_adx_handle, 2, 1, minus1);
      if(!ok)
        {
         m_snapshot.strategies[M30_STRATEGY_MOMENTUM].explanation = "Indicator buffer unavailable";
         return;
        }
      m_snapshot.rsi = rsi1;
      m_snapshot.macd_main = macd1;
      m_snapshot.macd_signal = signal1;
      m_snapshot.adx = adx1;
      bool bull_div = false, bear_div = false;
      if(m_low_count >= 2 && m_low_pivots[0].price < m_low_pivots[1].price)
        {
         double newer_rsi = 0.0, older_rsi = 0.0;
         if(ReadBuffer(m_rsi_handle, 0, m_low_pivots[0].shift, newer_rsi) &&
            ReadBuffer(m_rsi_handle, 0, m_low_pivots[1].shift, older_rsi))
            bull_div = newer_rsi > older_rsi;
        }
      if(m_high_count >= 2 && m_high_pivots[0].price > m_high_pivots[1].price)
        {
         double newer_rsi = 0.0, older_rsi = 0.0;
         if(ReadBuffer(m_rsi_handle, 0, m_high_pivots[0].shift, newer_rsi) &&
            ReadBuffer(m_rsi_handle, 0, m_high_pivots[1].shift, older_rsi))
            bear_div = newer_rsi < older_rsi;
        }
      bool bullish = bull_div || (macd1 > signal1 && macd1 > macd2 && plus1 > minus1);
      bool bearish = bear_div || (macd1 < signal1 && macd1 < macd2 && minus1 > plus1);
      double hist1 = macd1 - signal1;
      double hist2 = macd2 - signal2;
      m_snapshot.momentum_strengthening =
         (((hist1 > hist2 && hist1 > 0.0) || (hist1 < hist2 && hist1 < 0.0)) &&
          adx1 >= M30InpADXStrengthLevel);
      m_snapshot.momentum_weakening =
         ((hist1 < hist2 && hist1 > 0.0) || (hist1 > hist2 && hist1 < 0.0));
      bool strong = adx1 >= M30InpADXStrengthLevel;
      if(bullish && !bearish)
         AddEvidence(M30_STRATEGY_MOMENTUM, 1,
                     bull_div && strong ? 0.90 : (bull_div ? 0.75 : (strong ? 0.65 : 0.45)),
                     bull_div && strong,
                     bull_div ? "Bullish RSI divergence at confirmed price pivots" :
                                (m_snapshot.momentum_strengthening ?
                                 "Bullish MACD/DI momentum strengthening; ADX confirms trend strength" :
                                 "Bullish MACD/DI momentum; ADX used only as a strength filter"),
                     m_rates[1].close, m_rates[1].time);
      else if(bearish && !bullish)
         AddEvidence(M30_STRATEGY_MOMENTUM, -1,
                     bear_div && strong ? 0.90 : (bear_div ? 0.75 : (strong ? 0.65 : 0.45)),
                     bear_div && strong,
                     bear_div ? "Bearish RSI divergence at confirmed price pivots" :
                                (m_snapshot.momentum_strengthening ?
                                 "Bearish MACD/DI momentum strengthening; ADX confirms trend strength" :
                                 "Bearish MACD/DI momentum; ADX used only as a strength filter"),
                     m_rates[1].close, m_rates[1].time);
      else
         m_snapshot.strategies[M30_STRATEGY_MOMENTUM].explanation =
            "No single indicator is treated as a standalone setup confirmation";
     }

   string DirectionText(const int direction)
     {
      if(direction > 0) return "BULLISH";
      if(direction < 0) return "BEARISH";
      return "NEUTRAL";
     }

   double ContextDirectionFactor(const int direction)
     {
      double factor = 1.0;
      if(m_d1.ready && (int)m_d1.direction != 0 && (int)m_d1.direction != direction)
         factor *= 0.65;
      if(m_h4.ready && m_h4.direction != 0 && m_h4.direction != direction)
         factor *= 0.70;
      return factor;
     }

   void ScoreAndClassify()
     {
      double buy = 0.0, sell = 0.0, maximum = 0.0;
      int active = 0, confirmed = 0, developing = 0;
      bool independent[6] = {false,false,false,false,false,false};
      for(int i = 0; i < 10; i++)
        {
         M30StrategyResult item = m_snapshot.strategies[i];
         item.enabled = StrategyEnabled(i);
         item.weight = StrategyWeight(i);
         m_snapshot.strategies[i].enabled = item.enabled;
         m_snapshot.strategies[i].weight = item.weight;
         if(!item.enabled) continue;
         maximum += item.weight;
         active++;
         buy += item.buy_points;
         sell += item.sell_points;
         if(item.confirmed)
           {
            confirmed++;
            // Related structure/breakout and liquidity/false-breakout signals
            // share confirmation groups so one event cannot count twice.
            int group = i;
            if(i == M30_STRATEGY_BREAKOUT) group = M30_STRATEGY_STRUCTURE;
            if(i == M30_STRATEGY_FALSE_BREAKOUT) group = M30_STRATEGY_LIQUIDITY;
            if(i == M30_STRATEGY_SUPPORT_RESISTANCE || i == M30_STRATEGY_INSTITUTIONAL)
               group = M30_STRATEGY_SUPPORT_RESISTANCE;
            if(i == M30_STRATEGY_PREMIUM_DISCOUNT) group = -1;
            if(i == M30_STRATEGY_MOMENTUM) group = 5;
            if(group >= 0 && group < 6) independent[group] = true;
           }
         else if(item.developing)
            developing++;
        }
      int independent_count = 0;
      for(int g = 0; g < 6; g++) if(independent[g]) independent_count++;
      double buy_pct = maximum > 0.0 ? 100.0 * buy / maximum : 0.0;
      double sell_pct = maximum > 0.0 ? 100.0 * sell / maximum : 0.0;
      m_snapshot.buy_points = buy;
      m_snapshot.sell_points = sell;
      m_snapshot.active_max_points = maximum;
      m_snapshot.neutral_points = MathMax(0.0, maximum - buy - sell);
      m_snapshot.buy_evidence_percent = buy_pct;
      m_snapshot.sell_evidence_percent = sell_pct;
      m_snapshot.active_strategy_count = active;
      m_snapshot.confirmed_strategy_count = confirmed;
      m_snapshot.developing_strategy_count = developing;
      m_snapshot.independent_confirmation_count = independent_count;
      bool bull = buy_pct >= 40.0 && buy_pct > sell_pct;
      bool bear = sell_pct >= 40.0 && sell_pct > buy_pct;
      double separation = MathAbs(buy_pct - sell_pct);
      int candidate_direction = bull ? 1 : (bear ? -1 : 0);
      if(buy_pct >= 40.0 && sell_pct >= 40.0 &&
         separation < M30InpMinimumScoreSeparation)
         candidate_direction = 0;
      string alignment = "HTF DATA UNAVAILABLE";
      if(candidate_direction == 0)
         alignment = "MIXED / NO DIRECTION";
      else if(m_d1.ready && m_h4.ready && m_h1.ready)
        {
         bool d1_aligned = (int)m_d1.direction == 0 || (int)m_d1.direction == candidate_direction;
         bool h4_aligned = m_h4.direction == 0 || m_h4.direction == candidate_direction;
         bool h1_aligned = true;
         if(candidate_direction > 0 && m_h1.supply.valid &&
            m_rates[1].close >= m_h1.supply.low && m_rates[1].close <= m_h1.supply.high)
            h1_aligned = false;
         if(candidate_direction < 0 && m_h1.demand.valid &&
            m_rates[1].close >= m_h1.demand.low && m_rates[1].close <= m_h1.demand.high)
            h1_aligned = false;
         alignment = d1_aligned && h4_aligned && h1_aligned ? "ALIGNED" : "CONFLICT / COUNTERTREND";
        }
      m_snapshot.alignment = alignment;
      string status = "NO VALID SETUP";
      string reason = "No directional evidence has reached the developing threshold";
      if(maximum <= 0.0)
        { status = "NO VALID SETUP"; reason = "All M30 strategies are disabled"; }
      else if(candidate_direction == 0)
        {
         if(buy_pct >= 40.0 && sell_pct >= 40.0)
           { status = "MIXED EVIDENCE"; reason = "Bullish and bearish evidence scores are too close"; }
         else if(buy_pct > 0.0 || sell_pct > 0.0)
           { status = "WAIT"; reason = "Evidence remains below 40 normalized points"; }
        }
      else
        {
         double score = candidate_direction > 0 ? buy_pct : sell_pct;
         bool direction_htf_conflict =
            (m_d1.ready && (int)m_d1.direction != 0 && (int)m_d1.direction != candidate_direction) ||
            (m_h4.ready && m_h4.direction != 0 && m_h4.direction != candidate_direction);
         if(candidate_direction > 0 && m_h1.ready && m_h1.supply.valid &&
            m_rates[1].close >= m_h1.supply.low && m_rates[1].close <= m_h1.supply.high)
            direction_htf_conflict = true;
         if(candidate_direction < 0 && m_h1.ready && m_h1.demand.valid &&
            m_rates[1].close >= m_h1.demand.low && m_rates[1].close <= m_h1.demand.high)
            direction_htf_conflict = true;
         bool htf_ready = m_d1.ready && m_h4.ready && m_h1.ready;
         bool structure_ok = candidate_direction > 0 ?
                             (m_bullish_bos || m_bullish_choch || m_bullish_sweep) :
                             (m_bearish_bos || m_bearish_choch || m_bearish_sweep);
         bool liquidity_ok = !M30InpRequireLiquidity ||
                             (candidate_direction > 0 ? m_bullish_sweep : m_bearish_sweep);
         bool enough_independent = independent_count >= M30InpMinimumIndependentSignals;
         bool enough_separation = separation >= M30InpMinimumScoreSeparation;
         bool confirm_candidate = score >= M30InpConfirmationThreshold;
         if(direction_htf_conflict && !M30InpAllowCountertrendConfirm)
           {
            status = "COUNTERTREND SETUP";
            reason = "M30 direction conflicts with D1 or H4 context";
           }
         else if(confirm_candidate && !htf_ready)
           {
            status = candidate_direction > 0 ? "BUY SETUP DEVELOPING" : "SELL SETUP DEVELOPING";
            reason = "Higher-timeframe context is incomplete; final confirmation is withheld";
           }
         else if(confirm_candidate && (!structure_ok || !liquidity_ok ||
                                      !enough_independent || !enough_separation))
           {
            status = candidate_direction > 0 ? "BUY SETUP DEVELOPING" : "SELL SETUP DEVELOPING";
            if(!structure_ok) reason = "Score threshold met, but no matching confirmed M30 structure or reclaim";
            else if(!liquidity_ok) reason = "Score threshold met, but required liquidity sweep is absent";
            else if(!enough_independent) reason = "Score threshold met, but independent confirmation count is too low";
            else reason = "Score threshold met, but BUY/SELL evidence separation is insufficient";
           }
         else if(confirm_candidate)
           {
            status = candidate_direction > 0 ? "BUY SETUP CONFIRMED" : "SELL SETUP CONFIRMED";
            reason = "Threshold, closed-candle structure, independent evidence, score separation and HTF rules passed; analysis only";
           }
         else if(score >= 60.0)
           { status = candidate_direction > 0 ? "BUY SETUP DEVELOPING" : "SELL SETUP DEVELOPING";
             reason = "Strong evidence; confirmation gates or score threshold are not yet met"; }
         else if(score >= 40.0)
           { status = candidate_direction > 0 ? "BUY SETUP DEVELOPING" : "SELL SETUP DEVELOPING";
             reason = "Developing evidence; wait for additional independent confirmation"; }
         else
           { status = "WAIT"; reason = "Directional evidence is below the developing threshold"; }
        }
      m_snapshot.result = status;
      m_snapshot.reason = reason;
      m_snapshot.d1_context = m_d1.ready ? DirectionText((int)m_d1.direction) : "DATA UNAVAILABLE";
      m_snapshot.h4_context = m_h4.ready ? DirectionText(m_h4.direction) : "DATA UNAVAILABLE";
      m_snapshot.h1_location = "DATA UNAVAILABLE";
      if(m_h1.ready)
        {
         double price = m_rates[1].close;
         if(m_h1.demand.valid && price >= m_h1.demand.low && price <= m_h1.demand.high)
            m_snapshot.h1_location = "AT DEMAND";
         else if(m_h1.supply.valid && price >= m_h1.supply.low && price <= m_h1.supply.high)
            m_snapshot.h1_location = "AT SUPPLY";
         else if(m_h1.support.valid && price >= m_h1.support.low && price <= m_h1.support.high)
            m_snapshot.h1_location = "NEAR SUPPORT";
         else if(m_h1.resistance.valid && price >= m_h1.resistance.low && price <= m_h1.resistance.high)
            m_snapshot.h1_location = "NEAR RESISTANCE";
         else m_snapshot.h1_location = "BETWEEN H1 ZONES";
        }
     }

   int VolumePrecision(const double step)
     {
      for(int digits = 0; digits <= 8; digits++)
         if(MathAbs(NormalizeDouble(step, digits) - step) < 0.000000001)
            return digits;
      return 8;
     }

   void BuildTradePlan()
     {
      m_snapshot.trade_plan_valid = false;
      m_snapshot.trade_direction = 0;
      m_snapshot.entry_zone_high = 0.0;
      m_snapshot.entry_zone_low = 0.0;
      m_snapshot.preferred_entry = 0.0;
      m_snapshot.stop_loss = 0.0;
      m_snapshot.take_profit_1 = 0.0;
      m_snapshot.take_profit_2 = 0.0;
      m_snapshot.take_profit_3 = 0.0;
      m_snapshot.risk_reward_tp3 = 0.0;
      m_snapshot.lot_size = 0.0;
      m_snapshot.estimated_money_risk = 0.0;
      m_snapshot.trade_plan_status = m_snapshot.result;

      int direction = StringFind(m_snapshot.result, "BUY SETUP CONFIRMED") == 0 ? 1 :
                      (StringFind(m_snapshot.result, "SELL SETUP CONFIRMED") == 0 ? -1 : 0);
      m_snapshot.trade_direction = direction;
      if(direction == 0)
         return;

      double zone_low = 0.0;
      double zone_high = 0.0;
      if(m_snapshot.order_block_valid && !m_snapshot.order_block_invalidated &&
         m_snapshot.order_block_direction == direction)
        {
         zone_low = m_snapshot.order_block_low;
         zone_high = m_snapshot.order_block_high;
        }
      else if(direction > 0 && m_snapshot.bullish_fvg_valid && !m_snapshot.fvg_invalidated)
        {
         zone_low = m_snapshot.fvg_low;
         zone_high = m_snapshot.fvg_high;
        }
      else if(direction < 0 && m_snapshot.bearish_fvg_valid && !m_snapshot.fvg_invalidated)
        {
         zone_low = m_snapshot.fvg_low;
         zone_high = m_snapshot.fvg_high;
        }
      else if(direction > 0 && m_snapshot.support_valid && !m_snapshot.support_invalidated)
        {
         zone_low = m_snapshot.support_low;
         zone_high = m_snapshot.support_high;
        }
      else if(direction < 0 && m_snapshot.resistance_valid && !m_snapshot.resistance_invalidated)
        {
         zone_low = m_snapshot.resistance_low;
         zone_high = m_snapshot.resistance_high;
        }

      if(zone_low <= 0.0 || zone_high <= zone_low || m_snapshot.atr <= 0.0)
        {
         m_snapshot.trade_plan_status += " | ENTRY ZONE UNAVAILABLE";
         return;
        }
      double entry = (zone_low + zone_high) * 0.5;
      double stop_buffer = MathMax(_Point, m_snapshot.atr * M30InpTradePlanStopBufferATR);
      double stop = direction > 0 ? zone_low - stop_buffer : zone_high + stop_buffer;
      double risk_distance = MathAbs(entry - stop);
      if(entry <= 0.0 || stop <= 0.0 || risk_distance <= _Point)
        {
         m_snapshot.trade_plan_status += " | INVALID PRICE DISTANCE";
         return;
        }

      m_snapshot.entry_zone_high = zone_high;
      m_snapshot.entry_zone_low = zone_low;
      m_snapshot.preferred_entry = entry;
      m_snapshot.stop_loss = stop;
      m_snapshot.take_profit_1 = entry + direction * risk_distance;
      m_snapshot.take_profit_2 = entry + direction * risk_distance * 2.0;
      m_snapshot.take_profit_3 = entry + direction * risk_distance * 3.0;
      m_snapshot.risk_reward_tp3 = 3.0;
      m_snapshot.trade_plan_valid = true;

      double equity = AccountInfoDouble(ACCOUNT_EQUITY);
      double risk_budget = equity * M30InpTradePlanRiskPercent / 100.0;
      double one_lot_profit = 0.0;
      ENUM_ORDER_TYPE order_type = direction > 0 ? ORDER_TYPE_BUY : ORDER_TYPE_SELL;
      double volume_min = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
      double volume_max = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
      double volume_step = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
      if(equity > 0.0 && risk_budget > 0.0 && volume_min > 0.0 &&
         volume_max >= volume_min && volume_step > 0.0 &&
         OrderCalcProfit(order_type, _Symbol, 1.0, entry, stop, one_lot_profit))
        {
         double loss_per_lot = MathAbs(one_lot_profit);
         if(loss_per_lot > 0.0)
           {
            double raw_volume = MathMin(volume_max, risk_budget / loss_per_lot);
            double volume = MathFloor((raw_volume + 1e-10) / volume_step) * volume_step;
            volume = NormalizeDouble(volume, VolumePrecision(volume_step));
            if(volume >= volume_min)
              {
               double estimated_profit = 0.0;
               if(OrderCalcProfit(order_type, _Symbol, volume, entry, stop, estimated_profit))
                 {
                  m_snapshot.lot_size = volume;
                  m_snapshot.estimated_money_risk = MathAbs(estimated_profit);
                 }
              }
           }
        }
      if(m_snapshot.lot_size <= 0.0)
         m_snapshot.trade_plan_status += " | RISK SIZE UNAVAILABLE";
     }

   bool CreateOrMoveHLine(const string name,
                          const double price,
                          const color line_color,
                          const ENUM_LINE_STYLE style,
                          const int width)
     {
      if(price <= 0.0 || !MathIsValidNumber(price)) return false;
      long chart_id = m_draw_chart_id > 0 ? m_draw_chart_id : ChartID();
      if(ObjectFind(chart_id, name) < 0 && !ObjectCreate(chart_id, name, OBJ_HLINE, 0, 0, price))
         return false;
      bool ok = ObjectSetDouble(chart_id, name, OBJPROP_PRICE, price);
      ok = ObjectSetInteger(chart_id, name, OBJPROP_COLOR, line_color) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_STYLE, style) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_WIDTH, width) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_SELECTABLE, false) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN, true) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS) && ok;
      if(M30InpDiagnosticLogging)
         Print("M30 drawing | ", _Symbol, " | chart=", EnumToString(_Period),
               " | analysis=M30 | object=", name, " | type=HLINE | price=",
               DoubleToString(price, _Digits), " | update=", (ok ? "OK" : "FAILED"));
      return ok;
     }

   bool CreateOrMoveText(const string name,
                         const string text,
                         const datetime when,
                         const double price,
                         const color text_color)
     {
      if(when <= 0 || price <= 0.0) return false;
      long chart_id = m_draw_chart_id > 0 ? m_draw_chart_id : ChartID();
      if(ObjectFind(chart_id, name) < 0 && !ObjectCreate(chart_id, name, OBJ_TEXT, 0, when, price))
         return false;
      bool ok = ObjectMove(chart_id, name, 0, when, price);
      ok = ObjectSetString(chart_id, name, OBJPROP_TEXT, text) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_COLOR, text_color) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_FONTSIZE, 8) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_SELECTABLE, false) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN, true) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS) && ok;
      return ok;
     }

   bool CreateOrMoveRectangle(const string name,
                              const datetime first_time,
                              const datetime second_time,
                              const double top,
                              const double bottom,
                              const color zone_color)
     {
      if(first_time <= 0 || second_time <= 0 || top <= bottom || bottom <= 0.0)
         return false;
      long chart_id = m_draw_chart_id > 0 ? m_draw_chart_id : ChartID();
      if(ObjectFind(chart_id, name) < 0 &&
         !ObjectCreate(chart_id, name, OBJ_RECTANGLE, 0, first_time, top, second_time, bottom))
         return false;
      bool ok = ObjectMove(chart_id, name, 0, first_time, top);
      ok = ObjectMove(chart_id, name, 1, second_time, bottom) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_COLOR, zone_color) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_STYLE, STYLE_DOT) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_WIDTH, 1) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_FILL, false) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_BACK, true) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_SELECTABLE, false) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_HIDDEN, true) && ok;
      ok = ObjectSetInteger(chart_id, name, OBJPROP_TIMEFRAMES, OBJ_ALL_PERIODS) && ok;
      return ok;
     }

   string ObjectTag(const string strategy,
                    const string type,
                    const datetime when)
     {
      return m_prefix + strategy + "_" + type + "_" +
             IntegerToString((long)when);
     }

   void ApplyVisibility()
     {
      long mask = m_master_drawings_visible && m_drawings_visible && M30InpDrawMarkings ?
                  OBJ_ALL_PERIODS : OBJ_NO_PERIODS;
      long chart_id = m_draw_chart_id > 0 ? m_draw_chart_id : ChartID();
      int total = ObjectsTotal(chart_id, 0, -1);
      for(int i = total - 1; i >= 0; i--)
        {
         string name = ObjectName(chart_id, i, 0, -1);
         if(StringFind(name, m_prefix) == 0)
            ObjectSetInteger(chart_id, name, OBJPROP_TIMEFRAMES, mask);
        }
     }

   void DrawAnalysis()
     {
      if(!m_master_drawings_visible || !m_drawings_visible ||
         !M30InpDrawMarkings || !m_snapshot.data_ready)
        { ApplyVisibility(); return; }
      datetime event_time = m_snapshot.last_closed_bar;
      if(m_high_count > 0)
        {
         string swing_name = ObjectTag("STRUCTURE", "SWING_HIGH", m_high_pivots[0].time);
         CreateOrMoveText(swing_name, m_high_pivots[0].classification + " H", m_high_pivots[0].time,
                          m_high_pivots[0].price, clrTomato);
         if(m_bullish_bos || m_bullish_choch)
           {
            string tag = m_snapshot.bullish_mss ? "MSS" : (m_bullish_choch ? "CHOCH" : "BOS");
            CreateOrMoveHLine(ObjectTag("STRUCTURE", tag, event_time), m_high_pivots[0].price,
                              clrLimeGreen, STYLE_DOT, 1);
           }
        }
      if(m_low_count > 0)
        {
         string swing_name = ObjectTag("STRUCTURE", "SWING_LOW", m_low_pivots[0].time);
         CreateOrMoveText(swing_name, m_low_pivots[0].classification + " L", m_low_pivots[0].time,
                          m_low_pivots[0].price, clrDeepSkyBlue);
         if(m_bearish_bos || m_bearish_choch)
           {
            string tag = m_snapshot.bearish_mss ? "MSS" : (m_bearish_choch ? "CHOCH" : "BOS");
            CreateOrMoveHLine(ObjectTag("STRUCTURE", tag, event_time), m_low_pivots[0].price,
                              clrTomato, STYLE_DOT, 1);
           }
        }
      if(m_buy_liquidity > 0.0)
         CreateOrMoveHLine(ObjectTag("LIQUIDITY", "BSL", m_high_count > 0 ? m_high_pivots[0].time : event_time), m_buy_liquidity,
                           clrOrange, STYLE_DOT, 1);
      if(m_sell_liquidity > 0.0)
         CreateOrMoveHLine(ObjectTag("LIQUIDITY", "SSL", m_low_count > 0 ? m_low_pivots[0].time : event_time), m_sell_liquidity,
                           clrAqua, STYLE_DOT, 1);
      if(m_snapshot.equal_highs_valid)
        {
         CreateOrMoveHLine(ObjectTag("LIQUIDITY", "EQH", m_high_pivots[0].time),
                           m_snapshot.equal_highs_level, clrGold, STYLE_DASHDOT, 1);
         CreateOrMoveText(ObjectTag("LIQUIDITY", "EQH_LABEL", m_high_pivots[0].time),
                          "EQH", m_high_pivots[0].time, m_snapshot.equal_highs_level, clrGold);
        }
      if(m_snapshot.equal_lows_valid)
        {
         CreateOrMoveHLine(ObjectTag("LIQUIDITY", "EQL", m_low_pivots[0].time),
                           m_snapshot.equal_lows_level, clrAqua, STYLE_DASHDOT, 1);
         CreateOrMoveText(ObjectTag("LIQUIDITY", "EQL_LABEL", m_low_pivots[0].time),
                          "EQL", m_low_pivots[0].time, m_snapshot.equal_lows_level, clrAqua);
        }
      if(m_bullish_sweep)
         CreateOrMoveText(ObjectTag("LIQUIDITY", "BULL_RECLAIM", event_time),
                          "SSL SWEEP / RECLAIM", event_time, m_rates[1].low, clrLimeGreen);
      if(m_bearish_sweep)
         CreateOrMoveText(ObjectTag("LIQUIDITY", "BEAR_RECLAIM", event_time),
                          "BSL SWEEP / RECLAIM", event_time, m_rates[1].high, clrTomato);
      if(m_support_low > 0.0)
         CreateOrMoveRectangle(ObjectTag("SUPPORT", "DEMAND", m_low_pivots[0].time),
                               m_low_pivots[0].time, event_time,
                               m_support_high, m_support_low, clrSeaGreen);
      if(m_resistance_high > 0.0)
         CreateOrMoveRectangle(ObjectTag("RESISTANCE", "SUPPLY", m_high_pivots[0].time),
                               m_high_pivots[0].time, event_time,
                               m_resistance_high, m_resistance_low, clrIndianRed);
      if(m_fvg_valid)
         CreateOrMoveRectangle(ObjectTag("INSTITUTIONAL",
                               m_snapshot.ifvg_valid ?
                               (m_snapshot.ifvg_direction > 0 ? "BULL_IFVG" : "BEAR_IFVG") :
                               (m_fvg_bullish ? "BULL_FVG" : "BEAR_FVG"), m_fvg_time),
                               m_fvg_start_time, event_time,
                               m_fvg_high, m_fvg_low, m_fvg_bullish ? clrDodgerBlue : clrOrangeRed);
      if(m_ob_valid)
         CreateOrMoveRectangle(ObjectTag("INSTITUTIONAL",
                               m_snapshot.breaker_block_valid ? "BREAKER" :
                               (m_ob_direction > 0 ? "BULL_OB" : "BEAR_OB"), m_ob_time),
                               m_ob_time, event_time, m_ob_high, m_ob_low,
                               m_ob_direction > 0 ? clrMediumSeaGreen : clrFireBrick);
      if(m_snapshot.equilibrium > 0.0)
         CreateOrMoveHLine(ObjectTag("PREMIUM_DISCOUNT", "EQUILIBRIUM", event_time),
                           m_snapshot.equilibrium, clrSilver, STYLE_DOT, 1);
      if(m_snapshot.dealing_range_high > 0.0 && m_snapshot.dealing_range_low > 0.0)
        {
         CreateOrMoveHLine(ObjectTag("PREMIUM_DISCOUNT", "RANGE_HIGH", 0),
                           m_snapshot.dealing_range_high, clrSlateGray, STYLE_DASH, 1);
         CreateOrMoveHLine(ObjectTag("PREMIUM_DISCOUNT", "RANGE_LOW", 0),
                           m_snapshot.dealing_range_low, clrSlateGray, STYLE_DASH, 1);
         if(m_snapshot.ote_low > 0.0 && m_snapshot.ote_high > m_snapshot.ote_low)
           {
            CreateOrMoveHLine(ObjectTag("PREMIUM_DISCOUNT", "OTE_LOW", 0),
                              m_snapshot.ote_low, clrGoldenrod, STYLE_DOT, 1);
            CreateOrMoveHLine(ObjectTag("PREMIUM_DISCOUNT", "OTE_HIGH", 0),
                              m_snapshot.ote_high, clrGoldenrod, STYLE_DOT, 1);
           }
        }
      CreateOrMoveHLine(ObjectTag("BREAKOUT", "RANGE_HIGH", 0), m_range_high,
                        clrSteelBlue, STYLE_DOT, 1);
      CreateOrMoveHLine(ObjectTag("BREAKOUT", "RANGE_LOW", 0), m_range_low,
                        clrSteelBlue, STYLE_DOT, 1);
      if(m_breakout_valid)
         CreateOrMoveText(ObjectTag("BREAKOUT", "CLOSE_CONFIRMED", event_time),
                          m_snapshot.breakout_retest ? "M30 BREAKOUT RETEST" :
                          (m_breakout_direction > 0 ? "M30 BREAKOUT UP" : "M30 BREAKOUT DOWN"),
                          event_time, m_rates[1].close,
                          m_breakout_direction > 0 ? clrLimeGreen : clrTomato);
      if(m_false_breakout_valid)
        {
         double excursion_price = m_false_breakout_direction > 0 ? m_rates[1].low : m_rates[1].high;
         CreateOrMoveText(ObjectTag("FALSE_BREAKOUT", "EXCURSION", event_time),
                          "FALSE BREAKOUT", event_time, excursion_price, clrOrange);
         CreateOrMoveText(ObjectTag("FALSE_BREAKOUT", "RECLAIM", event_time),
                          "RANGE RECLAIM", event_time, m_rates[1].close, clrWhite);
        }
      if(m_snapshot.strategies[M30_STRATEGY_ENGULFING].confirmed)
         CreateOrMoveText(ObjectTag("ENGULFING", "PATTERN", event_time),
                          m_snapshot.strategies[M30_STRATEGY_ENGULFING].direction > 0 ?
                          "BULLISH ENGULF" : "BEARISH ENGULF",
                          event_time, m_rates[1].close,
                          m_snapshot.strategies[M30_STRATEGY_ENGULFING].direction > 0 ?
                          clrLimeGreen : clrTomato);
      if(m_snapshot.strategies[M30_STRATEGY_MOMENTUM].confirmed &&
         StringFind(m_snapshot.strategies[M30_STRATEGY_MOMENTUM].explanation, "divergence") >= 0)
         CreateOrMoveText(ObjectTag("MOMENTUM", "DIVERGENCE", event_time),
                          m_snapshot.strategies[M30_STRATEGY_MOMENTUM].direction > 0 ?
                          "BULLISH DIVERGENCE" : "BEARISH DIVERGENCE",
                          event_time, m_rates[1].close,
                          m_snapshot.strategies[M30_STRATEGY_MOMENTUM].direction > 0 ?
                          clrLimeGreen : clrTomato);
      MqlDateTime day_parts;
      TimeToStruct(event_time, day_parts);
      day_parts.hour = 0;
      day_parts.min = 0;
      day_parts.sec = 0;
      datetime day_key = StructToTime(day_parts);
      string session_names[3] = {"ASIA", "LONDON", "NEW_YORK"};
      for(int session = 0; session < 3; session++)
         if(m_snapshot.session_high[session] > 0.0 && m_snapshot.session_low[session] > 0.0)
           {
            CreateOrMoveHLine(ObjectTag("SESSION", session_names[session] + "_HIGH", day_key),
                              m_snapshot.session_high[session], clrDarkKhaki, STYLE_DOT, 1);
            CreateOrMoveHLine(ObjectTag("SESSION", session_names[session] + "_LOW", day_key),
                              m_snapshot.session_low[session], clrDarkKhaki, STYLE_DOT, 1);
           }
      long chart_id = m_draw_chart_id > 0 ? m_draw_chart_id : ChartID();
      string plan_names[4] = {m_prefix + "TRADE_PLAN_ENTRY", m_prefix + "TRADE_PLAN_SL",
                              m_prefix + "TRADE_PLAN_TP1", m_prefix + "TRADE_PLAN_TP2"};
      string plan_labels[4] = {m_prefix + "TRADE_PLAN_ENTRY_LABEL", m_prefix + "TRADE_PLAN_SL_LABEL",
                               m_prefix + "TRADE_PLAN_TP1_LABEL", m_prefix + "TRADE_PLAN_TP2_LABEL"};
      double plan_prices[4] = {m_snapshot.preferred_entry, m_snapshot.stop_loss,
                               m_snapshot.take_profit_1, m_snapshot.take_profit_2};
      string plan_texts[4] = {"ENTRY", "STOP LOSS", "TP1", "TP2"};
      color plan_colors[4] = {clrDeepSkyBlue, clrTomato, clrLimeGreen, clrLimeGreen};
      if(m_snapshot.trade_plan_valid)
        {
         for(int i = 0; i < 4; i++)
           {
            CreateOrMoveHLine(plan_names[i], plan_prices[i], plan_colors[i], STYLE_DASH, 1);
            CreateOrMoveText(plan_labels[i], plan_texts[i] + " " +
                             DoubleToString(plan_prices[i], _Digits),
                             m_snapshot.last_closed_bar, plan_prices[i], plan_colors[i]);
           }
         CreateOrMoveHLine(m_prefix + "TRADE_PLAN_TP3", m_snapshot.take_profit_3,
                           clrLimeGreen, STYLE_DASH, 1);
         CreateOrMoveText(m_prefix + "TRADE_PLAN_TP3_LABEL", "TP3 " +
                          DoubleToString(m_snapshot.take_profit_3, _Digits),
                          m_snapshot.last_closed_bar, m_snapshot.take_profit_3, clrLimeGreen);
        }
      else
        {
         for(int i = 0; i < 4; i++)
           {
            ObjectDelete(chart_id, plan_names[i]);
            ObjectDelete(chart_id, plan_labels[i]);
           }
         ObjectDelete(chart_id, m_prefix + "TRADE_PLAN_TP3");
         ObjectDelete(chart_id, m_prefix + "TRADE_PLAN_TP3_LABEL");
        }
      ApplyVisibility();
      ChartRedraw(chart_id);
     }

   void LogAnalysis()
     {
      if(!M30InpDiagnosticLogging) return;
      Print("M30 analysis | symbol=", _Symbol, " | chart=", EnumToString(_Period),
            " | analysis=PERIOD_M30 | close=", TimeToString(m_snapshot.last_closed_bar),
            " | result=", m_snapshot.result, " | buy=", DoubleToString(m_snapshot.buy_evidence_percent, 1),
            " | sell=", DoubleToString(m_snapshot.sell_evidence_percent, 1),
            " | active_max=", DoubleToString(m_snapshot.active_max_points, 1),
            " | confirmed=", m_snapshot.confirmed_strategy_count,
            " | independent=", m_snapshot.independent_confirmation_count,
            " | alignment=", m_snapshot.alignment, " | reason=", m_snapshot.reason);
      for(int i = 0; i < 10; i++)
         if(m_snapshot.strategies[i].enabled || m_snapshot.strategies[i].invalidated)
            Print("M30 strategy | ", StrategyName(i), " | status=", m_snapshot.strategies[i].status,
                  " | buy=", DoubleToString(m_snapshot.strategies[i].buy_points, 1),
                  " | sell=", DoubleToString(m_snapshot.strategies[i].sell_points, 1),
                  " | price=", DoubleToString(m_snapshot.strategies[i].key_price, _Digits),
                  " | explanation=", m_snapshot.strategies[i].explanation);
     }

   bool Analyze(CD1Analysis &d1_analysis,
                CMTFTrendAnalysis &mtf_analysis)
     {
      m_draw_chart_id = mtf_analysis.AnalysisChartId();
      if(m_draw_chart_id <= 0) m_draw_chart_id = ChartID();
      bool previous_drawings = m_drawings_visible;
      m_drawings_visible = mtf_analysis.M30DrawingsEnabled();
      for(int i = 0; i < 10; i++)
         m_runtime_strategy_enabled[i] = mtf_analysis.M30StrategyEnabled(i);
      int control_revision = mtf_analysis.M30ControlRevision();
      datetime current = iTime(_Symbol, PERIOD_M30, 0);
      if(current <= 0)
        {
         m_ready = false;
         m_snapshot.data_ready = false;
         m_snapshot.result = "INSUFFICIENT DATA";
         m_snapshot.reason = "No M30 series is available for this symbol";
         PublishDashboard(mtf_analysis, false);
         return false;
        }
      if(!mtf_analysis.M30ProcessingEnabled())
        {
         if(previous_drawings != m_drawings_visible)
           {
            if(m_drawings_visible && m_snapshot.data_ready) DrawAnalysis();
            else if(!m_drawings_visible) ApplyVisibility();
           }
         PublishDashboard(mtf_analysis, true);
         return false;
        }
      if(m_ready && current == m_current_bar && control_revision == m_last_control_revision)
        {
         if(previous_drawings != m_drawings_visible)
           {
            if(m_drawings_visible) DrawAnalysis();
            else ApplyVisibility();
           }
         return true;
        }
      ArraySetAsSeries(m_rates, true);
      int copied = CopyRates(_Symbol, PERIOD_M30, 0, M30InpLookbackBars, m_rates);
      int min_needed = M30InpSwingLeftBars + M30InpSwingRightBars +
                       M30InpATRPeriod + M30InpRangeBars + 8;
      if(copied < min_needed)
        {
         m_ready = false;
         m_snapshot.data_ready = false;
         m_snapshot.result = "INSUFFICIENT DATA";
         m_snapshot.reason = "M30 history is shorter than the configured analysis window";
         m_current_bar = current;
         PublishDashboard(mtf_analysis, false);
         return false;
        }
      m_current_bar = current;
      m_h1.ready = mtf_analysis.GetContext(PERIOD_H1, m_h1);
      m_h4.ready = mtf_analysis.GetContext(PERIOD_H4, m_h4);
      m_mtf_d1.ready = mtf_analysis.GetContext(PERIOD_D1, m_mtf_d1);
      m_d1.ready = d1_analysis.GetSnapshot(m_d1);
      double atr = 0.0;
      if(!ReadBuffer(m_atr_handle, 0, 1, atr) || atr <= 0.0)
        {
         m_ready = false;
         m_snapshot.data_ready = false;
         m_snapshot.result = "INSUFFICIENT DATA";
         m_snapshot.reason = "M30 ATR indicator buffer is unavailable";
         PublishDashboard(mtf_analysis, false);
         return false;
        }
      m_atr = atr;
      for(int i = 0; i < 10; i++) ResetResult(m_snapshot.strategies[i]);
      m_snapshot.buy_points = 0.0;
      m_snapshot.sell_points = 0.0;
      m_snapshot.neutral_points = 0.0;
      m_snapshot.active_max_points = 0.0;
      m_snapshot.buy_evidence_percent = 0.0;
      m_snapshot.sell_evidence_percent = 0.0;
      m_snapshot.active_strategy_count = 0;
      m_snapshot.confirmed_strategy_count = 0;
      m_snapshot.developing_strategy_count = 0;
      m_snapshot.independent_confirmation_count = 0;
      m_snapshot.equilibrium = 0.0;
      m_snapshot.dealing_range_low = 0.0;
      m_snapshot.dealing_range_high = 0.0;
      m_snapshot.ote_low = 0.0;
      m_snapshot.ote_high = 0.0;
      m_snapshot.rsi = 0.0;
      m_snapshot.macd_main = 0.0;
      m_snapshot.macd_signal = 0.0;
      m_snapshot.adx = 0.0;
      for(int i = 0; i < 3; i++)
        { m_snapshot.session_high[i] = 0.0; m_snapshot.session_low[i] = 0.0; }
      m_snapshot.data_ready = true;
      m_snapshot.last_closed_bar = m_rates[1].time;
      m_snapshot.last_update = TimeCurrent();
      m_snapshot.atr = m_atr;
      FindPivots();
      ResetSwing(m_snapshot.latest_high);
      ResetSwing(m_snapshot.previous_high);
      ResetSwing(m_snapshot.latest_low);
      ResetSwing(m_snapshot.previous_low);
      if(m_high_count > 0) m_snapshot.latest_high = m_high_pivots[0];
      if(m_high_count > 1) m_snapshot.previous_high = m_high_pivots[1];
      if(m_low_count > 0) m_snapshot.latest_low = m_low_pivots[0];
      if(m_low_count > 1) m_snapshot.previous_low = m_low_pivots[1];
      m_snapshot.latest_high.valid = m_high_count > 0;
      m_snapshot.previous_high.valid = m_high_count > 1;
      m_snapshot.latest_low.valid = m_low_count > 0;
      m_snapshot.previous_low.valid = m_low_count > 1;
      AnalyzeStructure();
      AnalyzeLiquidity();
      AnalyzeSupportResistance();
      AnalyzeEngulfing();
      AnalyzeBreakout();
      AnalyzeInstitutionalZones();
      AnalyzePremiumDiscount();
      AnalyzeFalseBreakout();
      AnalyzeSessions();
      AnalyzeMomentum();
      ScoreAndClassify();
      BuildTradePlan();
      m_ready = true;
      m_last_control_revision = control_revision;
      PublishDashboard(mtf_analysis, false);
      DrawAnalysis();
      LogAnalysis();
      return true;
     }

public:
   CM30Analysis()
     {
      m_atr_handle = INVALID_HANDLE;
      m_rsi_handle = INVALID_HANDLE;
      m_macd_handle = INVALID_HANDLE;
      m_adx_handle = INVALID_HANDLE;
      m_current_bar = 0;
      m_ready = false;
      m_drawings_visible = M30InpDrawMarkings;
      m_master_drawings_visible = true;
      m_last_control_revision = -1;
      string safe_symbol = _Symbol;
      StringReplace(safe_symbol, ".", "_");
      StringReplace(safe_symbol, " ", "_");
      m_prefix = "AI_M30_" + safe_symbol + "_" + IntegerToString((long)ChartID()) + "_";
      m_high_count = 0;
      m_low_count = 0;
      m_atr = 0.0;
      m_runtime_strategy_enabled[0] = M30InpEnableMarketStructure;
      m_runtime_strategy_enabled[1] = M30InpEnableLiquidity;
      m_runtime_strategy_enabled[2] = M30InpEnableSupportResistance;
      m_runtime_strategy_enabled[3] = M30InpEnableEngulfing;
      m_runtime_strategy_enabled[4] = M30InpEnableBreakout;
      m_runtime_strategy_enabled[5] = M30InpEnableInstitutionalZones;
      m_runtime_strategy_enabled[6] = M30InpEnablePremiumDiscount;
      m_runtime_strategy_enabled[7] = M30InpEnableFalseBreakout;
      m_runtime_strategy_enabled[8] = M30InpEnableSessions;
      m_runtime_strategy_enabled[9] = M30InpEnableMomentum;
      for(int i = 0; i < 8; i++)
        { ResetSwing(m_high_pivots[i]); ResetSwing(m_low_pivots[i]); }
      for(int i = 0; i < 10; i++) ResetResult(m_snapshot.strategies[i]);
      m_snapshot.data_ready = false;
      m_snapshot.result = "INSUFFICIENT DATA";
      m_snapshot.reason = "M30 analysis has not initialized";
      m_snapshot.trade_plan_status = "INSUFFICIENT DATA";
      m_draw_chart_id = ChartID();
     }

   bool Initialize(CMTFTrendAnalysis &mtf_analysis)
     {
      if(!InputsValid())
        {
         Print("M30 analysis: invalid input values.");
         return false;
        }
      m_atr_handle = iATR(_Symbol, PERIOD_M30, M30InpATRPeriod);
      m_rsi_handle = iRSI(_Symbol, PERIOD_M30, M30InpRSIPeriod, PRICE_CLOSE);
      m_macd_handle = iMACD(_Symbol, PERIOD_M30, M30InpMACDFast,
                            M30InpMACDSlow, M30InpMACDSignal, PRICE_CLOSE);
      m_adx_handle = iADX(_Symbol, PERIOD_M30, M30InpADXPeriod);
      if(m_atr_handle == INVALID_HANDLE || m_rsi_handle == INVALID_HANDLE ||
         m_macd_handle == INVALID_HANDLE || m_adx_handle == INVALID_HANDLE)
        {
         Print("M30 analysis: indicator handle creation failed; error ", GetLastError());
         Deinitialize();
         return false;
        }
      bool defaults[10];
      defaults[0] = M30InpEnableMarketStructure;
      defaults[1] = M30InpEnableLiquidity;
      defaults[2] = M30InpEnableSupportResistance;
      defaults[3] = M30InpEnableEngulfing;
      defaults[4] = M30InpEnableBreakout;
      defaults[5] = M30InpEnableInstitutionalZones;
      defaults[6] = M30InpEnablePremiumDiscount;
      defaults[7] = M30InpEnableFalseBreakout;
      defaults[8] = M30InpEnableSessions;
      defaults[9] = M30InpEnableMomentum;
      mtf_analysis.ConfigureM30Defaults(defaults, M30InpDrawMarkings);
      for(int i = 0; i < 10; i++)
         m_runtime_strategy_enabled[i] = mtf_analysis.M30StrategyEnabled(i);
      m_drawings_visible = mtf_analysis.M30DrawingsEnabled();
      m_ready = false;
      return true;
     }

   void Update(CD1Analysis &d1_analysis,
               CMTFTrendAnalysis &mtf_analysis)
     {
      Analyze(d1_analysis, mtf_analysis);
     }

   bool GetSnapshot(M30AnalysisSnapshot &snapshot)
     {
      snapshot = m_snapshot;
      return m_snapshot.data_ready;
     }

   string Summary()
     {
      return _Symbol + " | chart " + EnumToString(_Period) + " | M30 | " +
             m_snapshot.result + " | BUY " +
             DoubleToString(m_snapshot.buy_evidence_percent, 1) +
             "% | SELL " + DoubleToString(m_snapshot.sell_evidence_percent, 1) +
             "% | active " + IntegerToString(m_snapshot.active_strategy_count) +
             " confirmed " + IntegerToString(m_snapshot.confirmed_strategy_count) +
             " developing " + IntegerToString(m_snapshot.developing_strategy_count) +
             " | " + m_snapshot.alignment + " | updated " +
             TimeToString(m_snapshot.last_update, TIME_MINUTES) + " | trading permission OFF";
     }

   void SetMarkingsVisible(const bool visible)
     {
      m_drawings_visible = visible;
      if(visible && m_master_drawings_visible && m_snapshot.data_ready) DrawAnalysis();
      else ApplyVisibility();
      ChartRedraw(m_draw_chart_id > 0 ? m_draw_chart_id : ChartID());
     }

   void SetMasterDrawingsVisible(const bool visible)
     {
      m_master_drawings_visible=visible;
      if(visible && m_drawings_visible && m_snapshot.data_ready) DrawAnalysis();
      else ApplyVisibility();
      ChartRedraw(m_draw_chart_id > 0 ? m_draw_chart_id : ChartID());
     }

   void HandleChartEvent(const int id)
     {
      if(id == CHARTEVENT_CHART_CHANGE && m_snapshot.data_ready)
        {
         DrawAnalysis();
         ApplyVisibility();
        }
     }

   void Deinitialize(const bool preserve_chart_objects = false)
     {
      if(m_atr_handle != INVALID_HANDLE) IndicatorRelease(m_atr_handle);
      if(m_rsi_handle != INVALID_HANDLE) IndicatorRelease(m_rsi_handle);
      if(m_macd_handle != INVALID_HANDLE) IndicatorRelease(m_macd_handle);
      if(m_adx_handle != INVALID_HANDLE) IndicatorRelease(m_adx_handle);
      m_atr_handle = INVALID_HANDLE;
      m_rsi_handle = INVALID_HANDLE;
      m_macd_handle = INVALID_HANDLE;
      m_adx_handle = INVALID_HANDLE;
      if(!preserve_chart_objects)
         ObjectsDeleteAll(m_draw_chart_id > 0 ? m_draw_chart_id : ChartID(), m_prefix, 0, -1);
      m_ready = false;
      ChartRedraw(m_draw_chart_id > 0 ? m_draw_chart_id : ChartID());
     }
  };

#endif // AI_TRADING_SIGNAL_M30_ANALYSIS_MQH
