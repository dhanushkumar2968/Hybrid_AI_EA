#ifndef XAUUSD_HYBRID_SESSION_ANALYSIS_MQH
#define XAUUSD_HYBRID_SESSION_ANALYSIS_MQH

#include "StrategyModuleBase.mqh"

class XHSessionStrategy
  {
public:
   void Evaluate(const MqlRates &bars[],XHStrategyResult &result,const double atr)
     {
      int offset=(int)(TimeCurrent()-TimeGMT());
      datetime close_utc=(datetime)(bars[0].time+PeriodSeconds(PERIOD_M30)-offset);
      MqlDateTime parts;
      TimeToStruct(close_utc,parts);
      bool active=(parts.hour>=7 && parts.hour<=16);
      double body=bars[0].close-bars[0].open;
      if(active && body>=atr*0.25)
         XHStrategyBuy(result,bars[0],bars[0].close,bars[0].high,bars[0].low,bars[0].low,
                       "Bullish displacement during the configured UTC London/overlap window.");
      else if(active && body<=-atr*0.25)
         XHStrategySell(result,bars[0],bars[0].close,bars[0].high,bars[0].low,bars[0].high,
                        "Bearish displacement during the configured UTC London/overlap window.");
      else if(!active)
         result.reason="Completed candle is outside the configured UTC session window.";
     }
  };

#endif
