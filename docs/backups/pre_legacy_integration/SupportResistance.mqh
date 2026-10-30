#ifndef XAUUSD_HYBRID_SUPPORT_RESISTANCE_MQH
#define XAUUSD_HYBRID_SUPPORT_RESISTANCE_MQH

#include "StrategyModuleBase.mqh"

class XHSupportResistanceStrategy
  {
public:
   void Evaluate(const MqlRates &bars[],XHStrategyResult &result,
                 const double atr,const double high20,const double low20)
     {
      double tolerance=atr*0.30;
      if(bars[0].low<=low20+tolerance && bars[0].close>=low20)
         XHStrategyBuy(result,bars[0],low20,low20+tolerance,low20,low20,
                       "Completed candle held within 0.30 ATR of observed 20-bar support.");
      else if(bars[0].high>=high20-tolerance && bars[0].close<=high20)
         XHStrategySell(result,bars[0],high20,high20,high20-tolerance,high20,
                        "Completed candle held within 0.30 ATR of observed 20-bar resistance.");
     }
  };

#endif
