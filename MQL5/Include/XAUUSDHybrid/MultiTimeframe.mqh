#ifndef XAUUSD_HYBRID_MULTI_TIMEFRAME_MQH
#define XAUUSD_HYBRID_MULTI_TIMEFRAME_MQH

#include "CoreTypes.mqh"
#include "MarketData.mqh"

class XHMultiTimeframe
  {
private:
   int m_trends[8];
   bool m_ready[8];
   double m_atr_m30;
   bool m_atr_ready;
public:
   XHMultiTimeframe()
     {
      for(int i=0;i<8;i++)
        {
         m_trends[i]=0;
         m_ready[i]=false;
        }
      m_atr_m30=0.0;
      m_atr_ready=false;
     }

   bool Refresh(XHMarketData &market,XHAnalysisSnapshot &snapshot,
                const bool new_mn1,const bool new_w1,const bool new_d1,const bool new_h4,
                const bool new_h1,const bool new_m30,const bool new_m15,const bool new_m5)
     {
      bool changed[8];
      changed[0]=new_mn1; changed[1]=new_w1; changed[2]=new_d1; changed[3]=new_h4;
      changed[4]=new_h1; changed[5]=new_m30; changed[6]=new_m15; changed[7]=new_m5;
      ENUM_TIMEFRAMES tfs[8]={PERIOD_MN1,PERIOD_W1,PERIOD_D1,PERIOD_H4,
                              PERIOD_H1,PERIOD_M30,PERIOD_M15,PERIOD_M5};
      for(int i=0;i<8;i++)
        {
         if(!changed[i] && m_ready[i]) continue;
         if(!market.GetTrend(tfs[i],m_trends[i])) return false;
         m_ready[i]=true;
        }
      if(new_m30 || !m_atr_ready)
        {
         if(!market.ATR(PERIOD_M30,14,m_atr_m30)) return false;
         m_atr_ready=true;
        }
      snapshot.trend_mn1=m_trends[0];
      snapshot.trend_w1=m_trends[1];
      snapshot.trend_d1=m_trends[2];
      snapshot.trend_h4=m_trends[3];
      snapshot.trend_h1=m_trends[4];
      snapshot.trend_m30=m_trends[5];
      snapshot.trend_m15=m_trends[6];
      snapshot.trend_m5=m_trends[7];
      snapshot.atr_m30=m_atr_m30;
      return true;
     }

  };

#endif
