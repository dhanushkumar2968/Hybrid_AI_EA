#ifndef XAUUSD_HYBRID_ENGULFING_MQH
#define XAUUSD_HYBRID_ENGULFING_MQH

#include "StrategyModuleBase.mqh"

class XHEngulfingStrategy
  {
public:
   void Evaluate(const MqlRates &bars[],XHStrategyResult &result)
     {
      bool previous_bear=bars[1].close<bars[1].open;
      bool current_bull=bars[0].close>bars[0].open;
      bool previous_bull=bars[1].close>bars[1].open;
      bool current_bear=bars[0].close<bars[0].open;
      if(previous_bear && current_bull && bars[0].open<=bars[1].close &&
         bars[0].close>=bars[1].open)
         XHStrategyBuy(result,bars[0],bars[0].close,bars[0].high,bars[0].low,bars[0].low,
                       "Completed bullish candle body engulfed the prior bearish body.");
      else if(previous_bull && current_bear && bars[0].open>=bars[1].close &&
              bars[0].close<=bars[1].open)
         XHStrategySell(result,bars[0],bars[0].close,bars[0].high,bars[0].low,bars[0].high,
                        "Completed bearish candle body engulfed the prior bullish body.");
     }
  };

#endif
