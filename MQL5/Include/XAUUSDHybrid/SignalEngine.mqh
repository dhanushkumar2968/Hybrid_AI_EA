#ifndef XAUUSD_HYBRID_SIGNAL_ENGINE_MQH
#define XAUUSD_HYBRID_SIGNAL_ENGINE_MQH

#include "CoreTypes.mqh"

class XHSignalEngine
  {
public:
   void Decide(const XHAnalysisSnapshot &context,const XHStrategyResult &strategies[],
               const XHAIResponse &ai,const bool ai_enabled,const double max_spread_points,
               XHSignalDecision &decision)
     {
      decision.state=XH_NO_VALID_SETUP;
      decision.direction=XH_FLAT;
      decision.source_candle_time=context.source_candle_time;
      decision.signal_id="";
      decision.buy_score=context.buy_score;
      decision.sell_score=context.sell_score;
      decision.valid=false;
      decision.explanation="No setup met the mandatory confirmation rules.";

      if(!ai_enabled || !ai.valid)
        {
         decision.state=XH_AI_UNAVAILABLE;
         decision.explanation=ai_enabled ? "AI response unavailable or invalid; no setup is authorized."
                                         : "AI is disabled; signal confirmation is withheld.";
         return;
        }
      if(context.spread_points>max_spread_points)
        {
         decision.state=XH_WAIT;
         decision.explanation="Current spread exceeds the configured analysis limit.";
         return;
        }
      if(context.trend_d1==0 || context.trend_h4==0 || context.trend_d1!=context.trend_h4)
        {
         decision.state=XH_MIXED_EVIDENCE;
         decision.explanation="D1 and H4 direction are neutral or conflict.";
         return;
        }
      if(MathAbs(context.buy_score-context.sell_score)<15.0)
        {
         decision.state=XH_MIXED_EVIDENCE;
         decision.explanation="Independent strategy groups do not separate BUY and SELL evidence enough.";
         return;
        }

      ENUM_XH_DIRECTION direction=(context.buy_score>context.sell_score ? XH_BUY : XH_SELL);
      bool higher_aligned=(direction==XH_BUY ? context.trend_d1>0 : context.trend_d1<0);
      if(!higher_aligned)
        {
         decision.state=XH_COUNTERTREND;
         decision.direction=direction;
         decision.explanation="Strategy evidence points against the D1/H4 direction.";
         return;
        }
      int m30_direction=context.trend_m30;
      int m15_direction=context.trend_m15;
      int m5_direction=context.trend_m5;
      int wanted=(int)direction;
      if(m30_direction!=wanted)
        {
         decision.state=XH_WAIT;
         decision.direction=direction;
         decision.explanation="M30 setup direction does not match the higher-timeframe candidate.";
         return;
        }
      if((direction==XH_BUY && ai.prediction_class!="BUY_SETUP") ||
         (direction==XH_SELL && ai.prediction_class!="SELL_SETUP"))
        {
         decision.state=XH_WAIT;
         decision.direction=direction;
         decision.explanation="Python model did not agree with the mandatory rule-based direction.";
         return;
        }

      bool active_groups[5]={false,false,false,false,false};
      int matching_groups=0;
      for(int i=0;i<XH_STRATEGY_COUNT;i++)
        {
         if(!strategies[i].enabled) continue;
         int group=strategies[i].correlation_group;
         bool evidence=(direction==XH_BUY ? strategies[i].buy_points>0.0
                                           : strategies[i].sell_points>0.0);
         if(evidence && group>=0 && group<5 && !active_groups[group])
           {
            active_groups[group]=true;
            matching_groups++;
           }
        }
      bool has_m30_evidence=(direction==XH_BUY ? context.buy_score>=40.0 : context.sell_score>=40.0);
      if(!has_m30_evidence || matching_groups<2)
        {
         decision.state=XH_NO_VALID_SETUP;
         decision.explanation="M30 score or two-independent-group confirmation requirement was not met.";
         return;
        }
      if(m15_direction!=wanted || m5_direction!=wanted)
        {
         decision.state=(direction==XH_BUY ? XH_BUY_DEVELOPING : XH_SELL_DEVELOPING);
         decision.direction=direction;
         decision.explanation="M30, higher-timeframe evidence, and AI agree; M15/M5 confirmation is still pending.";
         return;
        }
      decision.direction=direction;
      decision.valid=true;
      decision.signal_id=context.symbol+"-"+IntegerToString((long)context.source_candle_time)+"-"+
                         XHDirectionName(direction);
      decision.state=(direction==XH_BUY ? XH_BUY_CONFIRMED : XH_SELL_CONFIRMED);
      decision.explanation="D1/H4 direction, M30 evidence, M15 refinement, M5 confirmation, spread, and AI class agree.";
     }
  };

#endif
