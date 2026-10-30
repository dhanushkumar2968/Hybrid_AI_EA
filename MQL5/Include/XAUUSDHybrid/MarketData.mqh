#ifndef XAUUSD_HYBRID_MARKET_DATA_MQH
#define XAUUSD_HYBRID_MARKET_DATA_MQH

#include "CoreTypes.mqh"
#include "IndicatorManager.mqh"

class XHMarketData
  {
private:
   string m_symbol;
   ENUM_TIMEFRAMES m_timeframes[8];
   datetime m_last_bar[8];
public:
   XHMarketData()
     {
      m_symbol="";
      m_timeframes[0]=PERIOD_MN1;
      m_timeframes[1]=PERIOD_W1;
      m_timeframes[2]=PERIOD_D1;
      m_timeframes[3]=PERIOD_H4;
      m_timeframes[4]=PERIOD_H1;
      m_timeframes[5]=PERIOD_M30;
      m_timeframes[6]=PERIOD_M15;
      m_timeframes[7]=PERIOD_M5;
      for(int i=0;i<8;i++) m_last_bar[i]=0;
     }

   bool Initialize(const string symbol)
     {
      m_symbol=symbol;
      if(!SymbolSelect(m_symbol,true))
        {
         Print("XH: SymbolSelect failed for ",m_symbol,", error=",GetLastError());
         return false;
        }
      return true;
     }

   string Symbol() const { return m_symbol; }

   bool ReadClosedBars(const ENUM_TIMEFRAMES timeframe,const int requested,MqlRates &bars[])
     {
      if(requested<2) return false;
      ArraySetAsSeries(bars,true);
      ResetLastError();
      int copied=CopyRates(m_symbol,timeframe,1,requested,bars);
      if(copied<requested)
        {
         Print("XH: CopyRates incomplete, tf=",EnumToString(timeframe),
               ", requested=",requested,", copied=",copied,", error=",GetLastError());
         return false;
        }
      ArraySetAsSeries(bars,true);
      return true;
     }

   bool ReadClosedBar(const ENUM_TIMEFRAMES timeframe,MqlRates &bar)
     {
      MqlRates rows[];
      if(!ReadClosedBars(timeframe,1,rows)) return false;
      bar=rows[0];
      return true;
     }

   bool IsNewBar(const ENUM_TIMEFRAMES timeframe)
     {
      datetime current=iTime(m_symbol,timeframe,0);
      if(current<=0) return false;
      for(int i=0;i<8;i++)
        {
         if(m_timeframes[i]!=timeframe) continue;
         if(m_last_bar[i]==0)
           {
            m_last_bar[i]=current;
            return true;
           }
         if(current!=m_last_bar[i])
           {
            m_last_bar[i]=current;
            return true;
           }
         return false;
        }
      return false;
     }

   double SpreadPoints()
     {
      MqlTick tick;
      if(!SymbolInfoTick(m_symbol,tick) || _Point<=0.0) return DBL_MAX;
      double point=SymbolInfoDouble(m_symbol,SYMBOL_POINT);
      if(point<=0.0) point=_Point;
      return (tick.ask-tick.bid)/point;
     }

   bool GetTrend(const ENUM_TIMEFRAMES timeframe,int &direction)
     {
      direction=0;
      MqlRates bars[];
      if(!ReadClosedBars(timeframe,60,bars)) return false;
      XHIndicatorManager indicators;
      double ema_fast=indicators.EMA(bars,60,20);
      double ema_slow=indicators.EMA(bars,60,50);
      double tolerance=SymbolInfoDouble(m_symbol,SYMBOL_POINT);
      if(ema_fast-ema_slow>tolerance) direction=1;
      else if(ema_slow-ema_fast>tolerance) direction=-1;
      return true;
     }

   bool ATR(const ENUM_TIMEFRAMES timeframe,const int period,double &value)
     {
      value=0.0;
      if(period<2) return false;
      MqlRates bars[];
      if(!ReadClosedBars(timeframe,period+1,bars)) return false;
      XHIndicatorManager indicators;
      value=indicators.ATR(bars,0,period);
      return value>0.0;
     }

   bool CurrentTick(MqlTick &tick) const
     {
      return SymbolInfoTick(m_symbol,tick);
     }
  };

#endif
