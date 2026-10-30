#ifndef XAUUSD_HYBRID_CORE_TYPES_MQH
#define XAUUSD_HYBRID_CORE_TYPES_MQH

#define XH_STRATEGY_COUNT 10
#define XH_FEATURE_SCHEMA "xauusd-features-v1"
#define XH_API_SCHEMA "1.0"

enum ENUM_XH_DIRECTION
  {
   XH_SELL=-1,
   XH_FLAT=0,
   XH_BUY=1
  };

enum ENUM_XH_SIGNAL_STATE
  {
   XH_NO_VALID_SETUP=0,
   XH_BUY_DEVELOPING,
   XH_BUY_CONFIRMED,
   XH_SELL_DEVELOPING,
   XH_SELL_CONFIRMED,
   XH_COUNTERTREND,
   XH_MIXED_EVIDENCE,
   XH_WAIT,
   XH_INVALIDATED,
   XH_EXPIRED,
   XH_AI_UNAVAILABLE
  };

enum ENUM_XH_EXECUTION_STATE
  {
   XH_EXEC_IDLE=0,
   XH_EXEC_PROCESSING,
   XH_EXEC_ERROR
  };

enum ENUM_XH_MANAGEMENT_KIND
  {
   XH_MANAGE_MODIFY=1,
   XH_MANAGE_PARTIAL_CLOSE=2,
   XH_MANAGE_CLOSE=3
  };

struct XHStrategyResult
  {
   string name;
   bool enabled;
   double buy_points;
   double sell_points;
   double max_points;
   bool buy_confirmed;
   bool sell_confirmed;
   double relevant_price;
   double zone_high;
   double zone_low;
   datetime signal_time;
   double invalidation;
   int correlation_group;
   string reason;
  };

struct XHAnalysisSnapshot
  {
   string symbol;
   datetime analysis_time;
   datetime source_candle_time;
   double bid;
   double ask;
   double spread_points;
   int trend_mn1;
   int trend_w1;
   int trend_d1;
   int trend_h4;
   int trend_h1;
   int trend_m30;
   int trend_m15;
   int trend_m5;
   double atr_m30;
   double buy_score;
   double sell_score;
   double score_denominator;
   int enabled_strategy_count;
   string explanation;
  };

struct XHSignalDecision
  {
   ENUM_XH_SIGNAL_STATE state;
   ENUM_XH_DIRECTION direction;
   datetime source_candle_time;
   string signal_id;
   double buy_score;
   double sell_score;
   string explanation;
   bool valid;
  };

struct XHTradePlan
  {
   bool valid;
   ENUM_XH_DIRECTION direction;
   double entry_zone_high;
   double entry_zone_low;
   double preferred_entry;
   double stop_loss;
   double tp1;
   double tp2;
   double tp3;
   double risk_reward_1;
   double risk_reward_2;
   double risk_reward_3;
   double volume;
   double estimated_risk_money;
   string rejection_reason;
  };

struct XHAIResponse
  {
   bool valid;
   bool mock;
   string request_id;
   string model_name;
   string model_version;
   string feature_schema_version;
   string prediction_class;
   string warning;
   double inference_ms;
  };

struct XHManagementCommand
  {
   bool valid;
   ulong ticket;
   int kind;
   double volume;
   double stop_loss;
   double take_profit;
   string reason;
  };

string XHSignalStateName(const ENUM_XH_SIGNAL_STATE state)
  {
   switch(state)
     {
      case XH_BUY_DEVELOPING: return "BUY SETUP DEVELOPING";
      case XH_BUY_CONFIRMED:  return "BUY SETUP CONFIRMED";
      case XH_SELL_DEVELOPING:return "SELL SETUP DEVELOPING";
      case XH_SELL_CONFIRMED: return "SELL SETUP CONFIRMED";
      case XH_COUNTERTREND:   return "COUNTERTREND";
      case XH_MIXED_EVIDENCE: return "MIXED EVIDENCE";
      case XH_WAIT:           return "WAIT";
      case XH_INVALIDATED:    return "INVALIDATED";
      case XH_EXPIRED:        return "EXPIRED";
      case XH_AI_UNAVAILABLE: return "AI UNAVAILABLE";
      default:                return "NO VALID SETUP";
     }
  }

string XHDirectionName(const ENUM_XH_DIRECTION direction)
  {
   if(direction==XH_BUY) return "BUY";
   if(direction==XH_SELL) return "SELL";
   return "FLAT";
  }

#endif
