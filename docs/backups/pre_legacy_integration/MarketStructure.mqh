#ifndef XAUUSD_HYBRID_MARKET_STRUCTURE_MQH
#define XAUUSD_HYBRID_MARKET_STRUCTURE_MQH

#include "StrategyModuleBase.mqh"

class XHMarketStructureStrategy
  {
public:
   void Evaluate(const MqlRates &bars[],XHStrategyResult &result,
                 const double high20,const double low20,const double atr,
                 const int prior_trend)
     {
      if(bars[0].close>high20 && bars[1].close<=high20)
        {
         string label=(prior_trend<0 && bars[0].close-bars[0].open>=atr*0.50 ?
                       "Bullish CHoCH/MSS" : "Bullish BOS");
         XHStrategyBuy(result,bars[0],high20,bars[0].high,bars[0].low,bars[0].low,
                       "Completed M30 candle closed above prior 20-bar structure: "+label+".");
        }
      else if(bars[0].close<low20 && bars[1].close>=low20)
        {
         string label=(prior_trend>0 && bars[0].open-bars[0].close>=atr*0.50 ?
                       "Bearish CHoCH/MSS" : "Bearish BOS");
         XHStrategySell(result,bars[0],low20,bars[0].high,bars[0].low,bars[0].high,
                        "Completed M30 candle closed below prior 20-bar structure: "+label+".");
        }
     }
  };

#endif
