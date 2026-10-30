#ifndef XAUUSD_HYBRID_INSTITUTIONAL_ZONES_MQH
#define XAUUSD_HYBRID_INSTITUTIONAL_ZONES_MQH

#include "StrategyModuleBase.mqh"

class XHInstitutionalZoneStrategy
  {
public:
   void Evaluate(const MqlRates &bars[],XHStrategyResult &result,const double atr)
     {
      for(int i=2;i<=14;i++)
        {
         bool demand=(bars[i].close<bars[i].open &&
                      bars[i-1].close>bars[i].high &&
                      bars[i-1].close-bars[i].high>=atr*0.50);
         double demand_high=bars[i].open;
         double demand_low=bars[i].low;
         if(demand && bars[0].low<=demand_high && bars[0].high>=demand_low &&
            bars[0].close>=(demand_high+demand_low)/2.0)
           {
            XHStrategyBuy(result,bars[0],demand_high,demand_high,demand_low,demand_low,
                          "Price retested the last bearish displacement-origin demand candle.");
            return;
           }
         bool supply=(bars[i].close>bars[i].open &&
                      bars[i].low-bars[i-1].close>=atr*0.50 &&
                      bars[i-1].close<bars[i].low);
         double supply_high=bars[i].high;
         double supply_low=bars[i].open;
         if(supply && bars[0].high>=supply_low && bars[0].low<=supply_high &&
            bars[0].close<=(supply_high+supply_low)/2.0)
           {
            XHStrategySell(result,bars[0],supply_low,supply_high,supply_low,supply_high,
                           "Price retested the last bullish displacement-origin supply candle.");
            return;
           }
        }
     }
  };

#endif
