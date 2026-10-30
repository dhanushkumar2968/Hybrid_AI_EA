#ifndef XAUUSD_HYBRID_CHART_RENDERER_MQH
#define XAUUSD_HYBRID_CHART_RENDERER_MQH

#include "CoreTypes.mqh"
#include "MarketData.mqh"

class XHChartRenderer
  {
private:
   string m_analysis_prefix;
   string m_protection_prefix;

   void DeletePrefix(const string prefix)
     {
      for(int i=ObjectsTotal(0,0,-1)-1;i>=0;i--)
        {
         string name=ObjectName(0,i,0,-1);
         if(StringFind(name,prefix)==0) ObjectDelete(0,name);
        }
     }

   void Horizontal(const string name,const double price,const color line_color,
                   const ENUM_LINE_STYLE style,const int width,const string label)
     {
      if(price<=0.0) return;
      if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_HLINE,0,0,price);
      ObjectSetDouble(0,name,OBJPROP_PRICE,price);
      ObjectSetInteger(0,name,OBJPROP_COLOR,line_color);
      ObjectSetInteger(0,name,OBJPROP_STYLE,style);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,width);
      ObjectSetInteger(0,name,OBJPROP_BACK,true);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetString(0,name,OBJPROP_TEXT,label);
     }

   void TextAt(const string name,const datetime time,const double price,const string text,
               const color text_color,const ENUM_ANCHOR_POINT anchor)
     {
      if(time<=0 || price<=0.0) return;
      if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_TEXT,0,time,price);
      ObjectMove(0,name,0,time,price);
      ObjectSetString(0,name,OBJPROP_TEXT,text);
      ObjectSetString(0,name,OBJPROP_FONT,"Segoe UI");
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,name,OBJPROP_COLOR,text_color);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,anchor);
      ObjectSetInteger(0,name,OBJPROP_BACK,true);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
     }

   void PriceZone(const string name,const datetime start_time,const datetime end_time,
                  const double high,const double low,const color zone_color)
     {
      if(start_time<=0 || end_time<=start_time || high<=low) return;
      if(ObjectFind(0,name)<0 &&
         !ObjectCreate(0,name,OBJ_RECTANGLE,0,start_time,high,end_time,low)) return;
      ObjectMove(0,name,0,start_time,high);
      ObjectMove(0,name,1,end_time,low);
      ObjectSetInteger(0,name,OBJPROP_COLOR,zone_color);
      ObjectSetInteger(0,name,OBJPROP_STYLE,STYLE_SOLID);
      ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
      ObjectSetInteger(0,name,OBJPROP_FILL,false);
      ObjectSetInteger(0,name,OBJPROP_BACK,true);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
     }

   void DrawFvgs(const MqlRates &bars[],const int count)
     {
      int limit=(int)MathMin(count-3,16);
      for(int i=0;i<limit;i++)
        {
         bool bullish_gap=(bars[i].low>bars[i+2].high);
         bool bearish_gap=(bars[i].high<bars[i+2].low);
         if(!bullish_gap && !bearish_gap) continue;
         bool inverted=false;
         if(bullish_gap)
           {
            for(int j=0;j<i;j++) if(bars[j].close<bars[i+2].high) inverted=true;
           }
         else
           {
            for(int j=0;j<i;j++) if(bars[j].close>bars[i+2].low) inverted=true;
           }
         string name=m_analysis_prefix+(bullish_gap ? (inverted ? "IFVG_B_" : "FVG_B_")
                                                        : (inverted ? "IFVG_S_" : "FVG_S_"))+
                     IntegerToString(i);
         datetime earlier=bars[i+2].time;
         datetime later=bars[i].time;
         double top=(bullish_gap ? bars[i].low : bars[i+2].low);
         double bottom=(bullish_gap ? bars[i+2].high : bars[i].high);
         if(ObjectCreate(0,name,OBJ_RECTANGLE,0,earlier,top,later,bottom))
           {
            ObjectSetInteger(0,name,OBJPROP_COLOR,
                             bullish_gap ? C'50,140,117' : C'164,81,91');
            ObjectSetInteger(0,name,OBJPROP_STYLE,inverted ? STYLE_DASH : STYLE_SOLID);
            ObjectSetInteger(0,name,OBJPROP_WIDTH,1);
            ObjectSetInteger(0,name,OBJPROP_FILL,false);
            ObjectSetInteger(0,name,OBJPROP_BACK,true);
            ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
            ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
           }
        }
     }

public:
   XHChartRenderer()
     {
      m_analysis_prefix="XH_AI_ANALYSIS_";
      m_protection_prefix="XH_AI_PROTECT_";
     }

   void HideAnalysis()
     {
      DeletePrefix(m_analysis_prefix);
      ChartRedraw(0);
     }

   void RenderAnalysis(XHMarketData &market,const XHAnalysisSnapshot &context,
                       const XHStrategyResult &strategies[],
                       const XHTradePlan &plan,const XHObservedTradeLevels &observed,
                       const bool enabled,const bool show_structure,
                       const bool show_zones,const bool show_plan)
     {
      DeletePrefix(m_analysis_prefix);
      if(!enabled)
        {
         ChartRedraw(0);
         return;
        }
      MqlRates bars[];
      if(!market.ReadClosedBars(PERIOD_M30,100,bars)) return;
      double atr=context.atr_m30;
      double prior_high=-DBL_MAX,prior_low=DBL_MAX;
      for(int i=1;i<=20;i++)
        {
         prior_high=MathMax(prior_high,bars[i].high);
         prior_low=MathMin(prior_low,bars[i].low);
        }

      if(show_structure)
        {
         Horizontal(m_analysis_prefix+"BSL",prior_high,C'224,113,120',STYLE_DASH,1,"BSL");
         Horizontal(m_analysis_prefix+"SSL",prior_low,C'72,170,145',STYLE_DASH,1,"SSL");
         Horizontal(m_analysis_prefix+"PD_MID",(prior_high+prior_low)/2.0,
                    C'132,142,157',STYLE_DOT,1,"Premium / Discount");

         double last_swing_high=0.0,last_swing_low=0.0;
         for(int i=2;i<26;i++)
           {
            bool swing_high=(bars[i].high>bars[i-1].high && bars[i].high>bars[i+1].high);
            bool swing_low=(bars[i].low<bars[i-1].low && bars[i].low<bars[i+1].low);
            if(swing_high)
              {
               string tag=(last_swing_high<=0.0 ? "SH" :
                           bars[i].high>last_swing_high ? "HH" : "LH");
               TextAt(m_analysis_prefix+"SW_H_"+IntegerToString(i),bars[i].time,bars[i].high,tag,
                      C'226,137,142',ANCHOR_LOWER);
               last_swing_high=bars[i].high;
              }
            if(swing_low)
              {
               string tag=(last_swing_low<=0.0 ? "SL" :
                           bars[i].low>last_swing_low ? "HL" : "LL");
               TextAt(m_analysis_prefix+"SW_L_"+IntegerToString(i),bars[i].time,bars[i].low,tag,
                      C'92,190,163',ANCHOR_UPPER);
               last_swing_low=bars[i].low;
              }
           }

         double equal_tolerance=MathMax(SymbolInfoDouble(market.Symbol(),SYMBOL_POINT)*4.0,atr*0.10);
         bool eqh_drawn=false,eql_drawn=false;
         for(int i=2;i<20;i++)
           {
            if(!eqh_drawn && MathAbs(bars[i].high-bars[i+1].high)<=equal_tolerance)
              {
               TextAt(m_analysis_prefix+"EQH",bars[i].time,
                      (bars[i].high+bars[i+1].high)/2.0,"EQH / BSL",
                      C'231,190,111',ANCHOR_LOWER);
               eqh_drawn=true;
              }
            if(!eql_drawn && MathAbs(bars[i].low-bars[i+1].low)<=equal_tolerance)
              {
               TextAt(m_analysis_prefix+"EQL",bars[i].time,
                      (bars[i].low+bars[i+1].low)/2.0,"EQL / SSL",
                      C'231,190,111',ANCHOR_UPPER);
               eql_drawn=true;
              }
           }
        }

      if(show_zones)
        {
         DrawFvgs(bars,ArraySize(bars));
         int zone_count=0;
         datetime zone_end=TimeCurrent()+PeriodSeconds(PERIOD_M30)*3;
         for(int j=0;j<XH_STRATEGY_COUNT && zone_count<4;j++)
           {
            if(!strategies[j].enabled || strategies[j].zone_high<=strategies[j].zone_low) continue;
            bool buy=(strategies[j].buy_points>=strategies[j].sell_points);
            color c=(buy ? C'67,187,151' : C'226,111,121');
            PriceZone(m_analysis_prefix+"STRAT_ZONE_"+IntegerToString(j),
                      strategies[j].signal_time,zone_end,
                      strategies[j].zone_high,strategies[j].zone_low,c);
            zone_count++;
           }
        }

      if(show_plan)
        {
         bool fresh_observed=observed.valid && observed.source_candle_time>0 &&
            TimeCurrent()-observed.source_candle_time<=PeriodSeconds(PERIOD_M30)*3;
         bool have_plan=plan.valid || fresh_observed;
         if(have_plan)
           {
            double zone_low=(plan.valid ? plan.entry_zone_low : observed.entry_zone_low);
            double zone_high=(plan.valid ? plan.entry_zone_high : observed.entry_zone_high);
            double entry=(plan.valid ? plan.preferred_entry : observed.preferred_entry);
            double stop=(plan.valid ? plan.stop_loss : observed.stop_loss);
            double tp1=(plan.valid ? plan.tp1 : observed.tp1);
            double tp2=(plan.valid ? plan.tp2 : observed.tp2);
            double tp3=(plan.valid ? plan.tp3 : observed.tp3);
            datetime start=(observed.source_candle_time>0 ? observed.source_candle_time : context.source_candle_time);
            datetime end=TimeCurrent()+PeriodSeconds(PERIOD_M30)*3;
            PriceZone(m_analysis_prefix+"ENTRY_ZONE",start,end,zone_high,zone_low,C'83,169,228');
            Horizontal(m_analysis_prefix+"ENTRY",entry,C'83,169,228',STYLE_SOLID,2,
                       plan.valid ? "ENTRY" : "CANDIDATE ENTRY");
            Horizontal(m_analysis_prefix+"SL",stop,C'232,86,96',STYLE_SOLID,2,"SL");
            Horizontal(m_analysis_prefix+"TP1",tp1,C'72,181,139',STYLE_DASH,1,"TP1");
            Horizontal(m_analysis_prefix+"TP2",tp2,C'72,181,139',STYLE_DASH,1,"TP2");
            Horizontal(m_analysis_prefix+"TP3",tp3,C'72,181,139',STYLE_SOLID,2,"TP3");
           }
        }
      ChartRedraw(0);
     }

   void RenderProtection(const string symbol,const long magic)
     {
      DeletePrefix(m_protection_prefix);
      for(int i=0;i<PositionsTotal();i++)
        {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
         if(PositionGetString(POSITION_SYMBOL)!=symbol ||
            PositionGetInteger(POSITION_MAGIC)!=magic) continue;
         double stop=PositionGetDouble(POSITION_SL);
         double take=PositionGetDouble(POSITION_TP);
         if(stop>0.0)
            Horizontal(m_protection_prefix+"SL_"+IntegerToString((long)ticket),stop,
                       C'255,85,95',STYLE_SOLID,2,"ACTIVE TRADE SL");
         if(take>0.0)
            Horizontal(m_protection_prefix+"TP_"+IntegerToString((long)ticket),take,
                       C'75,205,150',STYLE_SOLID,2,"ACTIVE TRADE TP");
        }
      ChartRedraw(0);
     }

   void DeleteProtection()
     {
      DeletePrefix(m_protection_prefix);
     }
  };

#endif
