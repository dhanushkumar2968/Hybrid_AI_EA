#ifndef XAUUSD_HYBRID_LIQUIDITY_MQH
#define XAUUSD_HYBRID_LIQUIDITY_MQH

#include "StrategyModuleBase.mqh"

class XHLiquidityStrategy
  {
public:
   void Evaluate(const MqlRates &bars[],XHStrategyResult &result,
                 const double high10,const double low10)
     {
      if(bars[0].low<low10 && bars[0].close>low10)
         XHStrategyBuy(result,bars[0],low10,low10,bars[0].low,bars[0].low,
                       "SSL sweep: completed candle traded below the prior 10-bar low and reclaimed it.");
      else if(bars[0].high>high10 && bars[0].close<high10)
         XHStrategySell(result,bars[0],high10,bars[0].high,high10,bars[0].high,
                        "BSL sweep: completed candle traded above the prior 10-bar high and reclaimed below it.");
     }
  };

#endif
