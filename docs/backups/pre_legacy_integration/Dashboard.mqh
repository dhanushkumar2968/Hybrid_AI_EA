#ifndef XAUUSD_HYBRID_DASHBOARD_MQH
#define XAUUSD_HYBRID_DASHBOARD_MQH

#include "CoreTypes.mqh"
#include "StateManager.mqh"

class XHDashboard
  {
private:
   int m_x;
   int m_y;
   int m_w;
   int m_h;
   bool m_compact;
   string m_prefix;

   void Rect(const string suffix,const int x,const int y,const int w,const int h,
             const color fill,const color border)
     {
      string name=m_prefix+suffix;
      if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
      ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
      ObjectSetInteger(0,name,OBJPROP_BGCOLOR,fill);
      ObjectSetInteger(0,name,OBJPROP_COLOR,border);
      ObjectSetInteger(0,name,OBJPROP_BORDER_TYPE,BORDER_FLAT);
      ObjectSetInteger(0,name,OBJPROP_BACK,false);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
     }

   void Label(const string suffix,const string text,const int x,const int y,
              const int size,const color text_color)
     {
      string name=m_prefix+suffix;
      if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_LABEL,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,size);
      ObjectSetInteger(0,name,OBJPROP_COLOR,text_color);
      ObjectSetInteger(0,name,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,false);
      ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
      ObjectSetString(0,name,OBJPROP_FONT,"Segoe UI");
      ObjectSetString(0,name,OBJPROP_TEXT,text);
     }

   void Button(const string suffix,const string text,const int x,const int y,
               const int w,const int h,const color fill,const color text_color)
     {
      string name=m_prefix+suffix;
      if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,x);
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,y);
      ObjectSetInteger(0,name,OBJPROP_XSIZE,w);
      ObjectSetInteger(0,name,OBJPROP_YSIZE,h);
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,8);
      ObjectSetInteger(0,name,OBJPROP_BGCOLOR,fill);
      ObjectSetInteger(0,name,OBJPROP_COLOR,text_color);
      ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,C'50,62,78');
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,true);
      ObjectSetString(0,name,OBJPROP_FONT,"Segoe UI");
      ObjectSetString(0,name,OBJPROP_TEXT,text);
     }

   color DirectionColor(const int direction)
     {
      if(direction>0) return C'57,197,151';
      if(direction<0) return C'239,104,104';
      return C'170,180,194';
     }

   string TrendText(const int direction)
     {
      if(direction>0) return "BULL";
      if(direction<0) return "BEAR";
      return "FLAT";
     }

   string PriceText(const double value,const int digits)
     {
      if(value<=0.0) return "N/A";
      return DoubleToString(value,digits);
     }

   void HideDetailObjects()
     {
      string exact[]={"PANEL_LEFT","PANEL_RIGHT","NAV","MTF","STRUCT","SIGNAL","EXPLAIN",
                      "PLAN","PLAN2","RISK","SESSION","POSITIONS","RISK_RESET",
                      "STRATEGY_TITLE","RESET_SIZE","COMPACT_STATE",
                      "NAV_MARKET","NAV_MTF","NAV_SETUPS","NAV_AI","NAV_RISK","NAV_EXEC"};
      for(int i=0;i<ArraySize(exact);i++)
        {
         string name=m_prefix+exact[i];
         if(ObjectFind(0,name)>=0) ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,0);
        }
      for(int s=0;s<XH_STRATEGY_COUNT;s++)
        {
         string name=m_prefix+"STRAT_"+IntegerToString(s);
         if(ObjectFind(0,name)>=0) ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,0);
         name=m_prefix+"STRAT_BTN_"+IntegerToString(s);
         if(ObjectFind(0,name)>=0) ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,0);
        }
     }

   void ShowDetails()
     {
      int total=ObjectsTotal(0,0,-1);
      for(int i=0;i<total;i++)
        {
         string name=ObjectName(0,i,0,-1);
         if(StringFind(name,m_prefix)!=0) continue;
         if(StringFind(name,m_prefix+"STRAT_")==0 ||
            StringFind(name,m_prefix+"NAV_")==0 ||
            name==m_prefix+"MTF" || name==m_prefix+"STRUCT" ||
            name==m_prefix+"SIGNAL" || name==m_prefix+"EXPLAIN" ||
            name==m_prefix+"PLAN" || name==m_prefix+"PLAN2" ||
            name==m_prefix+"RISK" || name==m_prefix+"SESSION" ||
            name==m_prefix+"POSITIONS" || name==m_prefix+"RISK_RESET" ||
            name==m_prefix+"PANEL_LEFT" || name==m_prefix+"PANEL_RIGHT" ||
            name==m_prefix+"NAV" || name==m_prefix+"STRATEGY_TITLE" ||
            name==m_prefix+"RESET_SIZE" || name==m_prefix+"COMPACT_STATE")
            ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
        }
     }

public:
   XHDashboard()
     {
      m_x=20; m_y=25; m_w=760; m_h=560; m_compact=false;
      m_prefix="XH_AI_DASH_";
     }

   void Initialize(XHStateManager &state)
     {
      m_x=(int)state.GetNumber("dash_x",20.0);
      m_y=(int)state.GetNumber("dash_y",25.0);
      m_w=(int)state.GetNumber("dash_w",760.0);
      m_compact=(state.GetNumber("dash_compact",0.0)>0.5);
      if(m_w<640 || m_w>1200) m_w=760;
      if(m_x<0) m_x=20;
      if(m_y<0) m_y=25;
      m_h=(m_compact ? 150 : 560);
     }

   void ResetPosition(XHStateManager &state)
     {
      m_x=20; m_y=25;
      state.SetNumber("dash_x",m_x);
      state.SetNumber("dash_y",m_y);
     }

   void ResetSize(XHStateManager &state)
     {
      m_w=760;
      m_compact=false;
      m_h=560;
      state.SetNumber("dash_w",m_w);
      state.SetNumber("dash_compact",0.0);
     }

   void Compact(XHStateManager &state,const bool compact)
     {
      m_compact=compact;
      m_h=(compact ? 150 : 560);
      state.SetNumber("dash_compact",compact ? 1.0 : 0.0);
     }

   void Resize(XHStateManager &state,const int delta)
     {
      m_w=MathMax(640,MathMin(1200,m_w+delta));
      state.SetNumber("dash_w",m_w);
     }

   bool HandleDrag(const string object_name,XHStateManager &state)
     {
      if(object_name!=m_prefix+"TITLE") return false;
      m_x=(int)ObjectGetInteger(0,object_name,OBJPROP_XDISTANCE);
      m_y=(int)ObjectGetInteger(0,object_name,OBJPROP_YDISTANCE);
      state.SetNumber("dash_x",m_x);
      state.SetNumber("dash_y",m_y);
      return true;
     }

   string Prefix() const { return m_prefix; }
   bool IsCompact() const { return m_compact; }

   void Render(const string symbol,const double bid,const ENUM_TIMEFRAMES chart_tf,
               const int digits,const XHAnalysisSnapshot &context,
               const XHStrategyResult &strategies[],const XHSignalDecision &signal,
               const XHTradePlan &plan,const XHAIResponse &ai,
               const bool bot_enabled,const bool analysis_enabled,const bool ai_enabled,
               const bool drawings_enabled,const bool trading_permission,const bool live_execution,
               const bool risk_locked,const ENUM_XH_EXECUTION_STATE execution_state,
               const string session_text,const string positions_text)
     {
      m_h=(m_compact ? 150 : 560);
      Rect("BG",m_x,m_y,m_w,m_h,C'15,20,28',C'52,63,78');
      Rect("TITLE_BG",m_x,m_y,m_w,33,C'28,36,48',C'28,36,48');
      string title=m_prefix+"TITLE";
      if(ObjectFind(0,title)<0) ObjectCreate(0,title,OBJ_RECTANGLE_LABEL,0,0,0);
      ObjectSetInteger(0,title,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,title,OBJPROP_XDISTANCE,m_x);
      ObjectSetInteger(0,title,OBJPROP_YDISTANCE,m_y);
      ObjectSetInteger(0,title,OBJPROP_XSIZE,m_w);
      ObjectSetInteger(0,title,OBJPROP_YSIZE,30);
      ObjectSetInteger(0,title,OBJPROP_BGCOLOR,C'28,36,48');
      ObjectSetInteger(0,title,OBJPROP_COLOR,C'28,36,48');
      ObjectSetInteger(0,title,OBJPROP_SELECTABLE,true);
      ObjectSetInteger(0,title,OBJPROP_HIDDEN,true);
      ObjectSetString(0,title,OBJPROP_TOOLTIP,"Drag this title bar to move the dashboard.");
      Label("TITLE","XAUUSD  |  HYBRID AI SYSTEM",m_x+12,m_y+7,10,C'235,240,247');
      Label("PRICE",symbol+"  "+PriceText(bid,digits)+"  "+EnumToString(chart_tf),
            m_x+300,m_y+8,9,C'143,201,255');
      Button("MIN","MIN",m_x+m_w-236,m_y+5,32,23,C'46,60,77',clrWhite);
      Button("COMPACT",m_compact ? "RESTORE" : "COMPACT",m_x+m_w-199,m_y+5,70,23,C'46,60,77',clrWhite);
      Button("SIZE_MINUS","-",m_x+m_w-123,m_y+5,22,23,C'46,60,77',clrWhite);
      Button("SIZE_PLUS","+",m_x+m_w-97,m_y+5,22,23,C'46,60,77',clrWhite);
      Button("RESET_POS","RESET POS",m_x+m_w-71,m_y+5,67,23,C'46,60,77',clrWhite);

      Button("BOT",bot_enabled ? "BOT ON" : "BOT OFF",m_x+12,m_y+40,70,24,
             bot_enabled ? C'25,96,73' : C'94,57,59',clrWhite);
      Button("ANALYSIS",analysis_enabled ? "ANALYSIS ON" : "ANALYSIS OFF",m_x+88,m_y+40,98,24,
             analysis_enabled ? C'31,75,97' : C'72,77,83',clrWhite);
      Button("AI",ai_enabled ? "AI ON" : "AI OFF",m_x+192,m_y+40,58,24,
             ai_enabled ? C'31,75,97' : C'72,77,83',clrWhite);
      Button("DRAWINGS",drawings_enabled ? "DRAWINGS ON" : "DRAWINGS OFF",m_x+256,m_y+40,108,24,
             drawings_enabled ? C'31,75,97' : C'72,77,83',clrWhite);
      Label("TRADE_PERMISSION","TRADE INPUT "+(trading_permission ? "ON" : "OFF")+
            "  LIVE "+(live_execution ? "ON" : "OFF"),m_x+380,m_y+45,8,
            (trading_permission && live_execution) ? C'255,190,93' : C'180,190,202');
      Label("EXEC_STATE","EXECUTION: "+
            (execution_state==XH_EXEC_PROCESSING ? "PROCESSING" :
             execution_state==XH_EXEC_ERROR ? "ERROR" : "IDLE"),
            m_x+m_w-155,m_y+45,8,
            execution_state==XH_EXEC_ERROR ? C'239,104,104' : C'180,190,202');
      if(m_compact)
        {
         Label("COMPACT_STATE",XHSignalStateName(signal.state)+"  |  "+
               (ai_enabled ? (ai.valid ? "AI ONLINE" : "AI OFFLINE") : "AI DISABLED")+
               "  |  "+(risk_locked ? "RISK LOCKED" : "RISK NORMAL")+
               "  |  ENTRY "+((bot_enabled && trading_permission && live_execution && !risk_locked) ? "ARMED" : "DISABLED"),
               m_x+12,m_y+80,10,signal.valid ? C'57,197,151' : C'202,209,219');
         HideDetailObjects();
         ChartRedraw(0);
         return;
        }
      ShowDetails();
      Rect("NAV",m_x+10,m_y+74,55,450,C'18,24,33',C'44,56,71');
      Label("NAV_MARKET","MARKET",m_x+17,m_y+94,7,C'143,201,255');
      Label("NAV_MTF","MTF",m_x+17,m_y+132,7,C'170,180,194');
      Label("NAV_SETUPS","SETUPS",m_x+17,m_y+170,7,C'170,180,194');
      Label("NAV_AI","AI",m_x+17,m_y+208,7,C'170,180,194');
      Label("NAV_RISK","RISK",m_x+17,m_y+246,7,C'170,180,194');
      Label("NAV_EXEC","EXEC",m_x+17,m_y+284,7,C'170,180,194');
      Rect("PANEL_LEFT",m_x+72,m_y+74,298,154,C'20,27,37',C'44,56,71');
      Rect("PANEL_RIGHT",m_x+378,m_y+74,m_w-388,154,C'20,27,37',C'44,56,71');
      Label("MTF","MULTI-TIMEFRAME DIRECTION",m_x+82,m_y+82,9,C'143,201,255');
      string mtf1="MN1 "+TrendText(context.trend_mn1)+"   W1 "+TrendText(context.trend_w1)+
                  "   D1 "+TrendText(context.trend_d1)+"   H4 "+TrendText(context.trend_h4);
      string mtf2="H1  "+TrendText(context.trend_h1)+"   M30 "+TrendText(context.trend_m30)+
                  "   M15 "+TrendText(context.trend_m15)+"   M5  "+TrendText(context.trend_m5);
      Label("MTF1",mtf1,m_x+82,m_y+103,8,C'211,218,228');
      Label("MTF2",mtf2,m_x+82,m_y+124,8,C'211,218,228');
      Label("STRUCT","SPREAD "+DoubleToString(context.spread_points,1)+" pts"+
            "   ATR M30 "+PriceText(context.atr_m30,digits),m_x+82,m_y+150,8,C'170,180,194');
      Label("SESSION","UTC SESSION: "+session_text,m_x+82,m_y+177,7,C'170,180,194');
      string ai_state=(ai_enabled ? (ai.valid ? "ONLINE / "+ai.model_version : "OFFLINE") : "DISABLED");
      Label("AI_STATUS","AI "+ai_state+"  MODEL "+
            (ai.valid ? ai.model_name : "NOT READY"),m_x+388,m_y+82,8,
            ai.valid ? C'57,197,151' : C'239,170,110');
      Label("SIGNAL",XHSignalStateName(signal.state)+
            "  BUY "+DoubleToString(context.buy_score,1)+
            " / SELL "+DoubleToString(context.sell_score,1),
            m_x+388,m_y+104,9,signal.valid ? DirectionColor((int)signal.direction) : C'211,218,228');
      Label("EXPLAIN",StringSubstr(signal.explanation,0,86),m_x+388,m_y+126,8,C'170,180,194');
      Label("PLAN","PLAN "+(plan.valid ? XHDirectionName(plan.direction) : "N/A")+
            "  ENTRY "+(plan.valid ? PriceText(plan.preferred_entry,digits) : "N/A")+
            "  SL "+(plan.valid ? PriceText(plan.stop_loss,digits) : "N/A")+
            "  TP1 "+(plan.valid ? PriceText(plan.tp1,digits) : "N/A"),
            m_x+388,m_y+151,8,C'211,218,228');
      Label("PLAN2","TP2 "+(plan.valid ? PriceText(plan.tp2,digits) : "N/A")+
            "  TP3 "+(plan.valid ? PriceText(plan.tp3,digits) : "N/A")+
            "  RR "+(plan.valid ? DoubleToString(plan.risk_reward_1,2)+"/"+
            DoubleToString(plan.risk_reward_2,2)+"/"+DoubleToString(plan.risk_reward_3,2) : "N/A"),
            m_x+388,m_y+175,8,C'170,180,194');
      Label("POSITIONS",positions_text,m_x+388,m_y+199,7,C'170,180,194');
      Label("RISK","RISK "+(risk_locked ? "LOCKED" : "NORMAL")+
            "  AUTO ENTRY "+((bot_enabled && trading_permission && live_execution && !risk_locked) ? "ARMED" : "DISABLED")+
            "  ANALYSIS "+(analysis_enabled ? "ACTIVE" : "PAUSED"),
            m_x+72,m_y+236,8,risk_locked ? C'239,104,104' : C'170,180,194');
      Button("RISK_RESET",risk_locked ? "CLEAR LOCK" : "RISK OK",
             m_x+m_w-96,m_y+231,82,20,risk_locked ? C'118,73,56' : C'41,72,64',clrWhite);
      Label("STRATEGY_TITLE","TEN STRATEGY ENGINES  |  GROUPED EVIDENCE",m_x+72,m_y+257,9,C'143,201,255');
      for(int i=0;i<XH_STRATEGY_COUNT;i++)
        {
         int col=(i%2);
         int row=(int)MathFloor(i/2.0);
         int column_width=(m_w-96)/2;
         int base_x=m_x+80+col*column_width;
         int base_y=m_y+278+row*42;
         string detail=strategies[i].name+"  B "+DoubleToString(strategies[i].buy_points,0)+
                       " / S "+DoubleToString(strategies[i].sell_points,0)+
                       "  "+StringSubstr(strategies[i].reason,0,42);
         Label("STRAT_"+IntegerToString(i),detail,base_x,base_y,7,
               strategies[i].enabled ? C'200,208,219' : C'112,120,132');
         Button("STRAT_BTN_"+IntegerToString(i),strategies[i].enabled ? "ON" : "OFF",
                base_x+column_width-50,base_y-3,42,19,
                strategies[i].enabled ? C'31,75,97' : C'72,77,83',clrWhite);
        }
      Button("RESET_SIZE","RESET SIZE",m_x+m_w-92,m_y+m_h-28,78,20,C'46,60,77',clrWhite);
      ChartRedraw(0);
     }

   void DeleteOwnedObjects()
     {
      for(int i=ObjectsTotal(0,0,-1)-1;i>=0;i--)
        {
         string name=ObjectName(0,i,0,-1);
         if(StringFind(name,m_prefix)==0) ObjectDelete(0,name);
        }
     }
  };

#endif
