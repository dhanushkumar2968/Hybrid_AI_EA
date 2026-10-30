#ifndef XAUUSD_HYBRID_INDICATOR_MANAGER_MQH
#define XAUUSD_HYBRID_INDICATOR_MANAGER_MQH

class XHIndicatorManager
  {
public:
   double EMA(const MqlRates &bars[],const int count,const int period)
     {
      if(period<2 || count<period) return 0.0;
      double alpha=2.0/(period+1.0);
      double result=bars[count-1].close;
      for(int i=count-2;i>=0;i--)
         result=alpha*bars[i].close+(1.0-alpha)*result;
      return result;
     }

   double ATR(const MqlRates &bars[],const int start,const int period)
     {
      if(period<2 || ArraySize(bars)<start+period+1) return 0.0;
      double sum=0.0;
      for(int i=start;i<start+period;i++)
        {
         double previous=bars[i+1].close;
         sum+=MathMax(bars[i].high-bars[i].low,
                      MathMax(MathAbs(bars[i].high-previous),MathAbs(bars[i].low-previous)));
        }
      return sum/period;
     }

   double RSI(const MqlRates &bars[],const int start,const int period)
     {
      if(period<2 || ArraySize(bars)<start+period+1) return 50.0;
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
  };

#endif
