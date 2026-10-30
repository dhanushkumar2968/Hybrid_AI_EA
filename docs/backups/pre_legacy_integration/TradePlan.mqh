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

   bool AddTarget(const ENUM_XH_DIRECTION direction,const double candidate,
                  const double entry,double &targets[])
     {
      if(direction==XH_BUY && candidate<=entry) return false;
      if(direction==XH_SELL && candidate>=entry) return false;
      for(int i=0;i<3;i++)
         if(MathAbs(targets[i]-candidate)<=SymbolInfoDouble(_Symbol,SYMBOL_POINT)) return false;
      if(direction==XH_BUY)
        {
         if(candidate<targets[0]) { targets[2]=targets[1]; targets[1]=targets[0]; targets[0]=candidate; }
         else if(candidate<targets[1]) { targets[2]=targets[1]; targets[1]=candidate; }
         else if(candidate<targets[2]) targets[2]=candidate;
        }
      else
        {
         if(candidate>targets[0]) { targets[2]=targets[1]; targets[1]=targets[0]; targets[0]=candidate; }
         else if(candidate>targets[1]) { targets[2]=targets[1]; targets[1]=candidate; }
         else if(candidate>targets[2]) targets[2]=candidate;
        }
      return true;
     }

   bool FindSwingTargets(XHMarketData &market,const ENUM_XH_DIRECTION direction,
                         const double entry,double &tp1,double &tp2,double &tp3)
     {
      MqlRates bars[];
      if(!market.ReadClosedBars(PERIOD_M30,220,bars)) return false;
      double targets[3];
      if(direction==XH_BUY)
        {
         targets[0]=DBL_MAX; targets[1]=DBL_MAX; targets[2]=DBL_MAX;
        }
      else
        {
         targets[0]=-DBL_MAX; targets[1]=-DBL_MAX; targets[2]=-DBL_MAX;
        }
      for(int i=2;i<218;i++)
        {
         if(direction==XH_BUY)
           {
            if(bars[i].high>bars[i-1].high && bars[i].high>bars[i+1].high)
               AddTarget(direction,bars[i].high,entry,targets);
           }
         else
           {
            if(bars[i].low<bars[i-1].low && bars[i].low<bars[i+1].low)
               AddTarget(direction,bars[i].low,entry,targets);
           }
        }
      bool missing=(direction==XH_BUY ? targets[2]==DBL_MAX : targets[2]==-DBL_MAX);
      if(missing) return false;
      tp1=targets[0];
      tp2=targets[1];
      tp3=targets[2];
      return true;
     }

public:
   bool Build(XHMarketData &market,const XHSignalDecision &signal,
              const XHStrategyResult &strategies[],XHTradePlan &plan)
     {
      plan.valid=false;
      plan.direction=signal.direction;
      plan.entry_zone_high=0.0;
      plan.entry_zone_low=0.0;
      plan.preferred_entry=0.0;
      plan.stop_loss=0.0;
      plan.tp1=0.0; plan.tp2=0.0; plan.tp3=0.0;
      plan.risk_reward_1=0.0; plan.risk_reward_2=0.0; plan.risk_reward_3=0.0;
      plan.volume=0.0;
      plan.estimated_risk_money=0.0;
      plan.rejection_reason="";
      if(!signal.valid)
        {
         Reject(plan,"Signal is not confirmed.");
         return false;
        }
      if(signal.source_candle_time<=0 || TimeCurrent()-signal.source_candle_time>PeriodSeconds(PERIOD_M30)*3)
        {
         Reject(plan,"Signal source candle is stale.");
         return false;
        }

      int selected=-1;
      double best_distance=DBL_MAX;
      MqlTick tick;
      if(!market.CurrentTick(tick))
        {
         Reject(plan,"No valid broker tick is available.");
         return false;
        }
      double current=(signal.direction==XH_BUY ? tick.ask : tick.bid);
      for(int i=0;i<XH_STRATEGY_COUNT;i++)
        {
         bool evidence=(signal.direction==XH_BUY ? strategies[i].buy_points>0.0
                                                 : strategies[i].sell_points>0.0);
         if(!strategies[i].enabled || !evidence || strategies[i].zone_high<=strategies[i].zone_low)
            continue;
         double distance=(current<strategies[i].zone_low ? strategies[i].zone_low-current :
                          current>strategies[i].zone_high ? current-strategies[i].zone_high : 0.0);
         if(distance<best_distance)
           {
            best_distance=distance;
            selected=i;
           }
        }
      if(selected<0)
        {
         Reject(plan,"No enabled strategy supplied an observed entry zone.");
         return false;
        }
      if(best_distance>SymbolInfoDouble(market.Symbol(),SYMBOL_POINT))
        {
         Reject(plan,"Current broker price is outside every observed entry zone.");
         return false;
        }
      plan.entry_zone_high=MathMax(strategies[selected].zone_high,strategies[selected].zone_low);
      plan.entry_zone_low=MathMin(strategies[selected].zone_high,strategies[selected].zone_low);
      plan.preferred_entry=current;
      plan.stop_loss=strategies[selected].invalidation;
      if(plan.stop_loss<=0.0)
        {
         Reject(plan,"Selected strategy did not provide an exact invalidation price.");
         return false;
        }
      if(signal.direction==XH_BUY && plan.stop_loss>=plan.preferred_entry)
        {
         Reject(plan,"Observed invalidation is not below the BUY entry.");
         return false;
        }
      if(signal.direction==XH_SELL && plan.stop_loss<=plan.preferred_entry)
        {
         Reject(plan,"Observed invalidation is not above the SELL entry.");
         return false;
        }
      if(!FindSwingTargets(market,signal.direction,plan.preferred_entry,plan.tp1,plan.tp2,plan.tp3))
        {
         Reject(plan,"Three distinct completed-candle swing targets are not available.");
         return false;
        }
      double risk=MathAbs(plan.preferred_entry-plan.stop_loss);
      if(risk<=0.0)
        {
         Reject(plan,"Entry-to-invalidation distance is zero.");
         return false;
        }
      plan.risk_reward_1=MathAbs(plan.tp1-plan.preferred_entry)/risk;
      plan.risk_reward_2=MathAbs(plan.tp2-plan.preferred_entry)/risk;
      plan.risk_reward_3=MathAbs(plan.tp3-plan.preferred_entry)/risk;
      long digits=SymbolInfoInteger(market.Symbol(),SYMBOL_DIGITS);
      double point=SymbolInfoDouble(market.Symbol(),SYMBOL_POINT);
      long stop_points=SymbolInfoInteger(market.Symbol(),SYMBOL_TRADE_STOPS_LEVEL);
      double min_distance=(double)stop_points*point;
      if(signal.direction==XH_BUY &&
         (current-plan.stop_loss<min_distance || plan.tp1-current<min_distance))
        {
         Reject(plan,"Observed stop or first target violates the broker stop distance.");
         return false;
        }
      if(signal.direction==XH_SELL &&
         (plan.stop_loss-current<min_distance || current-plan.tp1<min_distance))
        {
         Reject(plan,"Observed stop or first target violates the broker stop distance.");
         return false;
        }
      plan.entry_zone_high=NormalizeDouble(plan.entry_zone_high,(int)digits);
      plan.entry_zone_low=NormalizeDouble(plan.entry_zone_low,(int)digits);
      plan.preferred_entry=NormalizeDouble(plan.preferred_entry,(int)digits);
      plan.stop_loss=NormalizeDouble(plan.stop_loss,(int)digits);
      plan.tp1=NormalizeDouble(plan.tp1,(int)digits);
      plan.tp2=NormalizeDouble(plan.tp2,(int)digits);
      plan.tp3=NormalizeDouble(plan.tp3,(int)digits);
      plan.valid=true;
      return true;
     }
  };

#endif
