#ifndef XAUUSD_HYBRID_STRATEGY_ENGINE_MQH
#define XAUUSD_HYBRID_STRATEGY_ENGINE_MQH

#include "CoreTypes.mqh"
#include "MarketData.mqh"
#include "MarketStructure.mqh"
#include "Liquidity.mqh"
#include "SupportResistance.mqh"
#include "Engulfing.mqh"
#include "Breakout.mqh"
#include "InstitutionalZones.mqh"
#include "PremiumDiscount.mqh"
#include "FalseBreakout.mqh"
#include "SessionAnalysis.mqh"
#include "MomentumDivergence.mqh"
#include "StrategyScoring.mqh"

class XHStrategyEngine
  {
private:
   bool m_enabled[XH_STRATEGY_COUNT];
   XHMarketStructureStrategy m_market_structure;
   XHLiquidityStrategy m_liquidity;
   XHSupportResistanceStrategy m_support_resistance;
   XHEngulfingStrategy m_engulfing;
   XHBreakoutStrategy m_breakout;
   XHInstitutionalZoneStrategy m_institutional_zones;
   XHPremiumDiscountStrategy m_premium_discount;
   XHFalseBreakoutStrategy m_false_breakout;
   XHSessionStrategy m_session;
   XHMomentumDivergenceStrategy m_momentum_divergence;
   XHStrategyScoring m_scoring;

public:
   XHStrategyEngine()
     {
      for(int i=0;i<XH_STRATEGY_COUNT;i++) m_enabled[i]=true;
     }

   void Configure(const bool &enabled[])
     {
      for(int i=0;i<XH_STRATEGY_COUNT;i++) m_enabled[i]=enabled[i];
     }

   bool Enabled(const int index) const
     {
      if(index<0 || index>=XH_STRATEGY_COUNT) return false;
      return m_enabled[index];
     }

   void SetEnabled(const int index,const bool enabled)
     {
      if(index>=0 && index<XH_STRATEGY_COUNT) m_enabled[index]=enabled;
     }

   string Name(const int index) const
     {
      string names[XH_STRATEGY_COUNT]={"Market Structure","Liquidity Sweep",
         "Support / Resistance","Engulfing","Breakout","Institutional Zones",
         "Premium / Discount","False Breakout","Session Trading","Momentum / Divergence"};
      if(index<0 || index>=XH_STRATEGY_COUNT) return "Unknown";
      return names[index];
     }

   bool Evaluate(XHMarketData &market,const XHAnalysisSnapshot &context,
                 XHStrategyResult &results[])
     {
      MqlRates bars[];
      if(!market.ReadClosedBars(PERIOD_M30,80,bars)) return false;
      double high20=-DBL_MAX,low20=DBL_MAX,high10=-DBL_MAX,low10=DBL_MAX;
      for(int i=1;i<=20;i++)
        {
         high20=MathMax(high20,bars[i].high);
         low20=MathMin(low20,bars[i].low);
         if(i<=10)
           {
            high10=MathMax(high10,bars[i].high);
            low10=MathMin(low10,bars[i].low);
           }
        }
      double atr=context.atr_m30;
      int context_direction=context.trend_h1+context.trend_h4+context.trend_d1;
      context_direction=(context_direction>0)-(context_direction<0);
      int groups[XH_STRATEGY_COUNT]={0,1,2,3,0,2,2,1,4,3};
      for(int i=0;i<XH_STRATEGY_COUNT;i++)
         XHInitStrategy(results[i],Name(i),groups[i],bars[0].time,m_enabled[i]);
      if(atr<=0.0) return false;

      if(m_enabled[0]) m_market_structure.Evaluate(bars,results[0],high20,low20,atr,context.trend_m30);
      if(m_enabled[1]) m_liquidity.Evaluate(bars,results[1],high10,low10);
      if(m_enabled[2]) m_support_resistance.Evaluate(bars,results[2],atr,high20,low20);
      if(m_enabled[3]) m_engulfing.Evaluate(bars,results[3]);
      if(m_enabled[4]) m_breakout.Evaluate(bars,results[4],high20,low20);
      if(m_enabled[5]) m_institutional_zones.Evaluate(bars,results[5],atr);
      if(m_enabled[6]) m_premium_discount.Evaluate(bars,results[6],context_direction,high20,low20);
      if(m_enabled[7]) m_false_breakout.Evaluate(bars,results[7],high10,low10);
      if(m_enabled[8]) m_session.Evaluate(bars,results[8],atr);
      if(m_enabled[9]) m_momentum_divergence.Evaluate(bars,results[9]);
      return true;
     }

   void Score(const XHStrategyResult &results[],XHAnalysisSnapshot &context)
     {
      m_scoring.Score(results,context);
     }
  };

#endif
