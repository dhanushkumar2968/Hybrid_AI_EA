#ifndef XAUUSD_HYBRID_PREMIUM_DISCOUNT_MQH
#define XAUUSD_HYBRID_PREMIUM_DISCOUNT_MQH

#include "StrategyModuleBase.mqh"

class XHPremiumDiscountStrategy
  {
public:
   void Evaluate(const MqlRates &bars[],XHStrategyResult &result,
                 const int context_direction,const double high20,const double low20)
     {
      double mid=(high20+low20)/2.0;
      if(bars[0].close<mid && context_direction>0)
         XHStrategyBuy(result,bars[0],mid,mid,low20,low20,
                       "Price is in the observed range discount with bullish H1/H4/D1 context.");
      else if(bars[0].close>mid && context_direction<0)
         XHStrategySell(result,bars[0],mid,high20,mid,high20,
                        "Price is in the observed range premium with bearish H1/H4/D1 context.");
     }
  };

#endif
