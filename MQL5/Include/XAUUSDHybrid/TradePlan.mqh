#ifndef XAUUSD_HYBRID_TRADE_PLAN_MQH
#define XAUUSD_HYBRID_TRADE_PLAN_MQH

#include "CoreTypes.mqh"
#include "MarketData.mqh"

class XHTradePlanEngine
  {
private:
   void Reject(XHTradePlan &plan,const string reason)
     {
      plan.valid=false;
      plan.rejection_reason=reason;
     }

public:
   bool Build(XHMarketData &market,const XHSignalDecision &signal,
              const XHObservedTradeLevels &observed,XHTradePlan &plan)
     {
      plan.valid=false;
      plan.direction=signal.direction;
      plan.entry_zone_high=0.0;
      plan.entry_zone_low=0.0;
      plan.preferred_entry=0.0;
      plan.stop_loss=0.0;
      plan.tp1=0.0;
      plan.tp2=0.0;
      plan.tp3=0.0;
      plan.risk_reward_1=0.0;
      plan.risk_reward_2=0.0;
      plan.risk_reward_3=0.0;
      plan.volume=0.0;
      plan.estimated_risk_money=0.0;
      plan.rejection_reason="";

      if(!signal.valid)
        {
         Reject(plan,"Signal is not confirmed.");
         return false;
        }
      if(signal.source_candle_time<=0 ||
         TimeCurrent()-signal.source_candle_time>PeriodSeconds(PERIOD_M30)*3)
        {
         Reject(plan,"Signal source candle is stale.");
         return false;
        }
      if(!observed.valid || observed.source_candle_time!=signal.source_candle_time ||
         observed.direction!=(int)signal.direction)
        {
         Reject(plan,"Existing M30 analysis did not provide a matching confirmed trade plan.");
         return false;
        }

      double point=SymbolInfoDouble(market.Symbol(),SYMBOL_POINT);
      if(point<=0.0 || observed.entry_zone_low<=0.0 ||
         observed.entry_zone_high<=observed.entry_zone_low ||
         observed.preferred_entry<observed.entry_zone_low-point ||
         observed.preferred_entry>observed.entry_zone_high+point ||
         observed.stop_loss<=0.0 || observed.tp1<=0.0 ||
         observed.tp2<=0.0 || observed.tp3<=0.0)
        {
         Reject(plan,"Existing M30 analysis returned incomplete price levels.");
         return false;
        }
      if(signal.direction==XH_BUY &&
         !(observed.stop_loss<observed.preferred_entry &&
           observed.tp1>observed.preferred_entry &&
           observed.tp2>observed.tp1 && observed.tp3>observed.tp2))
        {
         Reject(plan,"Observed BUY plan levels are not strictly ordered.");
         return false;
        }
      if(signal.direction==XH_SELL &&
         !(observed.stop_loss>observed.preferred_entry &&
           observed.tp1<observed.preferred_entry &&
           observed.tp2<observed.tp1 && observed.tp3<observed.tp2))
        {
         Reject(plan,"Observed SELL plan levels are not strictly ordered.");
         return false;
        }

      plan.direction=signal.direction;
      plan.entry_zone_high=NormalizeDouble(observed.entry_zone_high,_Digits);
      plan.entry_zone_low=NormalizeDouble(observed.entry_zone_low,_Digits);
      plan.preferred_entry=NormalizeDouble(observed.preferred_entry,_Digits);
      plan.stop_loss=NormalizeDouble(observed.stop_loss,_Digits);
      plan.tp1=NormalizeDouble(observed.tp1,_Digits);
      plan.tp2=NormalizeDouble(observed.tp2,_Digits);
      plan.tp3=NormalizeDouble(observed.tp3,_Digits);
      double risk=MathAbs(plan.preferred_entry-plan.stop_loss);
      if(risk<=point)
        {
         Reject(plan,"Observed entry-to-stop distance is not valid.");
         return false;
        }
      plan.risk_reward_1=MathAbs(plan.tp1-plan.preferred_entry)/risk;
      plan.risk_reward_2=MathAbs(plan.tp2-plan.preferred_entry)/risk;
      plan.risk_reward_3=MathAbs(plan.tp3-plan.preferred_entry)/risk;
      plan.valid=true;
      return true;
     }
  };

#endif
