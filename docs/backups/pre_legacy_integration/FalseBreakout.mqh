#ifndef XAUUSD_HYBRID_FALSE_BREAKOUT_MQH
#define XAUUSD_HYBRID_FALSE_BREAKOUT_MQH

#include "StrategyModuleBase.mqh"

class XHFalseBreakoutStrategy
  {
public:
   void Evaluate(const MqlRates &bars[],XHStrategyResult &result,
                 const double high10,const double low10)
     {
      double range=MathMax(bars[0].high-bars[0].low,_Point);
      double lower_wick=MathMin(bars[0].open,bars[0].close)-bars[0].low;
      double upper_wick=bars[0].high-MathMax(bars[0].open,bars[0].close);
      if(bars[0].low<low10 && bars[0].close>low10 && lower_wick/range>=0.35)
         XHStrategyBuy(result,bars[0],low10,low10,bars[0].low,bars[0].low,
                       "False break below the prior 10-bar low reclaimed with a rejection wick.");
      else if(bars[0].high>high10 && bars[0].close<high10 && upper_wick/range>=0.35)
         XHStrategySell(result,bars[0],high10,bars[0].high,high10,bars[0].high,
                        "False break above the prior 10-bar high reclaimed with a rejection wick.");
     }
  };

#endif
