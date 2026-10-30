#ifndef XAUUSD_HYBRID_FEATURE_BUILDER_MQH
#define XAUUSD_HYBRID_FEATURE_BUILDER_MQH

#include "CoreTypes.mqh"
#include "MarketData.mqh"
#include "IndicatorManager.mqh"

struct XHFeatureVector
  {
   double trend_direction;
   double mtf_alignment;
   double structure_break;
   double liquidity_sweep;
   double sr_distance_atr;
   double candle_body_atr;
   double volatility_atr;
   double momentum;
   double spread_atr;
   double session_code;
   bool valid;
  };

class XHFeatureBuilder
  {
private:
   int SessionCode(const datetime utc_time)
     {
      MqlDateTime parts;
      TimeToStruct(utc_time,parts);
      if(parts.hour>=13 && parts.hour<=16) return 3;
      if(parts.hour>=7 && parts.hour<=12) return 1;
      if(parts.hour>=13 && parts.hour<=20) return 2;
      return 0;
     }

public:
   bool Build(XHMarketData &market,const XHAnalysisSnapshot &context,
              const datetime utc_time,const double spread_points,XHFeatureVector &features)
     {
      features.valid=false;
      MqlRates bars[];
      if(!market.ReadClosedBars(PERIOD_M30,61,bars)) return false;
      double atr=context.atr_m30;
      if(atr<=0.0) return false;

      double range_high=-DBL_MAX;
      double range_low=DBL_MAX;
      double high_10=-DBL_MAX;
      double low_10=DBL_MAX;
      for(int i=1;i<=20;i++)
        {
         range_high=MathMax(range_high,bars[i].high);
         range_low=MathMin(range_low,bars[i].low);
         if(i<=10)
           {
            high_10=MathMax(high_10,bars[i].high);
            low_10=MathMin(low_10,bars[i].low);
           }
        }
      int htf[3];
      htf[0]=context.trend_h1;
      htf[1]=context.trend_h4;
      htf[2]=context.trend_d1;
      int vote=htf[0]+htf[1]+htf[2];
      features.trend_direction=(double)((vote>0)-(vote<0));
      if(vote==0) features.mtf_alignment=0.0;
      else
        {
         int aligned=0;
         for(int j=0;j<3;j++) if(htf[j]==(int)features.trend_direction) aligned++;
         features.mtf_alignment=(double)aligned/3.0;
        }

      features.structure_break=0.0;
      if(bars[0].close>range_high) features.structure_break=1.0;
      else if(bars[0].close<range_low) features.structure_break=-1.0;
      features.liquidity_sweep=0.0;
      if(bars[0].low<low_10 && bars[0].close>low_10) features.liquidity_sweep=1.0;
      else if(bars[0].high>high_10 && bars[0].close<high_10) features.liquidity_sweep=-1.0;
      features.sr_distance_atr=(bars[0].close-(range_high+range_low)/2.0)/atr;
      features.candle_body_atr=(bars[0].close-bars[0].open)/atr;
      features.volatility_atr=atr/bars[0].close;
      features.momentum=(bars[0].close-bars[5].close)/atr;
      double point=SymbolInfoDouble(market.Symbol(),SYMBOL_POINT);
      features.spread_atr=(spread_points*point)/atr;
      long candle_seconds=PeriodSeconds(PERIOD_M30);
      datetime close_time=(datetime)(bars[0].time+candle_seconds);
      int server_offset=(int)(TimeCurrent()-TimeGMT());
      datetime utc_close=close_time-server_offset;
      features.session_code=(double)SessionCode(utc_close);
      features.valid=true;
      return true;
     }
  };

#endif
