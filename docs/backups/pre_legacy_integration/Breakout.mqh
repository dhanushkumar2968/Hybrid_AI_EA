#ifndef XAUUSD_HYBRID_BREAKOUT_MQH
#define XAUUSD_HYBRID_BREAKOUT_MQH

#include "StrategyModuleBase.mqh"

class XHBreakoutStrategy
  {
public:
   void Evaluate(const MqlRates &bars[],XHStrategyResult &result,
                 const double high20,const double low20)
     {
      if(bars[0].close>high20)
         XHStrategyBuy(result,bars[0],high20,bars[0].high,high20,high20,
                       "Completed M30 candle closed above the prior 20-bar range.");
      else if(bars[0].close<low20)
         XHStrategySell(result,bars[0],low20,low20,bars[0].low,low20,
                        "Completed M30 candle closed below the prior 20-bar range.");
     }
  };

#endif
