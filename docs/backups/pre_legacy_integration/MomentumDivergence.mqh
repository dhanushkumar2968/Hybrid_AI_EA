#ifndef XAUUSD_HYBRID_MOMENTUM_DIVERGENCE_MQH
#define XAUUSD_HYBRID_MOMENTUM_DIVERGENCE_MQH

#include "StrategyModuleBase.mqh"

class XHMomentumDivergenceStrategy
  {
private:
   double RSI(const MqlRates &bars[],const int start,const int period)
     {
      double gains=0.0,losses=0.0;
      for(int i=start;i<start+period;i++)
        {
         double change=bars[i].close-bars[i+1].close;
         if(change>0.0) gains+=change;
         else losses-=change;
        }
      if(losses<=0.0) return 100.0;
      double rs=(gains/period)/(losses/period);
      return 100.0-(100.0/(1.0+rs));
     }

public:
   void Evaluate(const MqlRates &bars[],XHStrategyResult &result)
     {
      double prior_low=DBL_MAX,prior_high=-DBL_MAX;
      for(int i=5;i<=14;i++)
        {
         prior_low=MathMin(prior_low,bars[i].low);
         prior_high=MathMax(prior_high,bars[i].high);
        }
      double current_rsi=RSI(bars,0,14);
      double previous_rsi=RSI(bars,5,14);
      if(bars[0].low<prior_low && current_rsi>previous_rsi+5.0 &&
         bars[0].close>bars[0].open)
         XHStrategyBuy(result,bars[0],bars[0].close,bars[0].high,bars[0].low,bars[0].low,
                       "Price made a lower swing low while RSI(14) made a higher reading.");
      else if(bars[0].high>prior_high && current_rsi<previous_rsi-5.0 &&
              bars[0].close<bars[0].open)
         XHStrategySell(result,bars[0],bars[0].close,bars[0].high,bars[0].low,bars[0].high,
                        "Price made a higher swing high while RSI(14) made a lower reading.");
     }
  };

#endif
