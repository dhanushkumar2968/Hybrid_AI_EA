#ifndef XAUUSD_HYBRID_DASHBOARD_MQH
#define XAUUSD_HYBRID_DASHBOARD_MQH

#include "CoreTypes.mqh"
#include "StateManager.mqh"

class XHDashboard
  {
private:
   int    m_x;
   int    m_y;
   int    m_w;
   int    m_h;
   int    m_actual_w;
   int    m_actual_h;
   int    m_content_h;
   double m_scale;
   bool   m_compact;
   bool   m_visible;
   bool   m_strategies_open;
   bool   m_m30_levels_open;
   bool   m_levels_open;
   bool   m_plan_open;
   bool   m_controls_open;
   string m_prefix;

   int S(const int value) const
     {
      return (int)MathMax(1.0,MathRound(value*m_scale));
     }

   int F(const int value) const
     {
      return (int)MathMax(7.0,MathRound(value*m_scale));
     }

   int MaxChars(const int width,const int font_size) const
     {
      double average_char_width=MathMax(4.0,F(font_size)*0.62);
      return (int)MathMax(18.0,MathFloor(S(width)/average_char_width));
     }

   string FitText(const string value,const int width,const int font_size) const
     {
      int limit=MaxChars(width,font_size);
      if(StringLen(value)<=limit) return value;
      if(limit<=3) return StringSubstr(value,0,limit);
      return StringSubstr(value,0,limit-3)+"...";
     }

   string AIStatusText(const XHAIResponse &ai,const bool enabled) const
     {
      if(!enabled) return "AI OFF | model status unavailable because inference is disabled.";
      if(ai.valid)
        {
         string model=(ai.model_name=="" ? "MODEL" : ai.model_name);
         string version=(ai.model_version=="" ? "version unknown" : ai.model_version);
         return "AI ONLINE | "+model+" "+version;
        }
      string reason=ai.warning;
      if(reason=="") reason="AI service/model has not returned a valid response.";
      string model_status=(ai.model_version=="" || ai.model_version=="unavailable" ?
                           "MODEL UNAVAILABLE | " : "MODEL "+ai.model_version+" | ");
      return "AI OFFLINE | "+model_status+reason;
     }

   string LayerStatusText(const string label,const bool selected,const bool master_on) const
     {
      if(!selected) return label+" OFF";
      return label+(master_on ? " ON" : " ARM");
     }

   int PX(const int value) const { return m_x+S(value); }
   int PY(const int value) const { return m_y+S(value); }

   string Key(const string name) const
     {
      return "dash_v4_"+name;
     }

   int ContentHeight() const
     {
      if(!m_visible)
         return 30;
      if(m_compact)
         return 10+34+6+28+6+18+4+18+4+18+10;

      int height=528;
      if(m_strategies_open) height+=114;
      if(m_m30_levels_open) height+=112;
      if(m_levels_open) height+=64;
      if(m_plan_open) height+=152;
      if(m_controls_open) height+=94;
      return height;
     }

   void ComputeGeometry()
     {
      int chart_w=(int)ChartGetInteger(0,CHART_WIDTH_IN_PIXELS,0);
      int chart_h=(int)ChartGetInteger(0,CHART_HEIGHT_IN_PIXELS,0);
      if(chart_w<320) chart_w=320;
      if(chart_h<240) chart_h=240;

      m_content_h=ContentHeight();
      double width_scale=(chart_w-16.0)/(double)m_w;
      double height_scale=(chart_h-16.0)/(double)m_content_h;
      m_scale=MathMin(1.0,MathMin(width_scale,height_scale));
      m_scale=MathMax(0.45,m_scale);
      m_actual_w=S(m_w);
      m_actual_h=S(m_content_h);
      m_h=m_actual_h;

      int max_x=(int)MathMax(4,chart_w-m_actual_w-4);
      int max_y=(int)MathMax(4,chart_h-m_actual_h-4);
      m_x=(int)MathMax(4,MathMin(m_x,max_x));
      m_y=(int)MathMax(4,MathMin(m_y,max_y));
     }

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
      ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
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
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,F(8));
      ObjectSetInteger(0,name,OBJPROP_BGCOLOR,fill);
      ObjectSetInteger(0,name,OBJPROP_COLOR,text_color);
      ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,C'50,62,78');
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,true);
      ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
      ObjectSetString(0,name,OBJPROP_FONT,"Segoe UI");
      ObjectSetString(0,name,OBJPROP_TEXT,text);
     }

   void BodyRect(const string suffix,const int x,const int y,const int w,const int h,
                 const color fill,const color border)
     {
      Rect("BODY_"+suffix,PX(x),PY(y),S(w),S(h),fill,border);
     }

   void BodyLabel(const string suffix,const string text,const int x,const int y,
                  const int size,const color text_color)
     {
      Label("BODY_"+suffix,text,PX(x),PY(y),F(size),text_color);
     }

   void BodyButton(const string suffix,const string text,const int x,const int y,
                   const int w,const int h,const color fill,const color text_color)
     {
      Button("BODY_"+suffix,text,PX(x),PY(y),S(w),S(h),fill,text_color);
     }

   void HideByPrefix(const string full_prefix)
     {
      for(int i=ObjectsTotal(0,0,-1)-1;i>=0;i--)
        {
         string name=ObjectName(0,i,0,-1);
         if(StringFind(name,full_prefix)==0)
            ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,0);
        }
     }

   void HideBodyObjects()
     {
      HideByPrefix(m_prefix+"BODY_");
      string compact=m_prefix+"COMPACT_STATE";
      if(ObjectFind(0,compact)>=0)
         ObjectSetInteger(0,compact,OBJPROP_TIMEFRAMES,0);
     }

   color DirectionColor(const int direction) const
     {
      if(direction>0) return C'57,197,151';
      if(direction<0) return C'239,104,104';
      return C'170,180,194';
     }

   string TrendText(const int direction) const
     {
      if(direction>0) return "BULLISH";
      if(direction<0) return "BEARISH";
      return "NEUTRAL";
     }

   string TimeframeText(const ENUM_TIMEFRAMES timeframe) const
     {
      if(timeframe==PERIOD_M1) return "M1";
      if(timeframe==PERIOD_M5) return "M5";
      if(timeframe==PERIOD_M15) return "M15";
      if(timeframe==PERIOD_M30) return "M30";
      if(timeframe==PERIOD_H1) return "H1";
      if(timeframe==PERIOD_H4) return "H4";
      if(timeframe==PERIOD_D1) return "D1";
      if(timeframe==PERIOD_W1) return "W1";
      if(timeframe==PERIOD_MN1) return "MN1";
      return EnumToString(timeframe);
     }

   string PriceText(const double value,const int digits) const
     {
      if(value<=0.0) return "N/A";
      return DoubleToString(value,digits);
     }

   string StrategyState(const XHStrategyResult &strategy) const
     {
      if(!strategy.enabled && !strategy.invalidated) return "OFF";
      if(strategy.invalidated) return "INVALID";
      if(strategy.confirmed) return "READY";
      if(strategy.developing) return "DEVELOPING";
      return "WAITING";
     }

   void DrawSectionHeader(const string suffix,const string title,const string summary,
                          const bool expanded,const int y)
     {
      string arrow=(expanded ? "v" : ">");
      BodyButton("SECTION_"+suffix,title+"  |  "+summary+"   ["+arrow+"]",
                 12,y,m_w-24,24,C'28,36,48',C'143,201,255');
     }

   void DrawResizeGrip()
     {
      string name=m_prefix+"RESIZE_GRIP";
      if(ObjectFind(0,name)<0) ObjectCreate(0,name,OBJ_BUTTON,0,0,0);
      ObjectSetInteger(0,name,OBJPROP_CORNER,CORNER_LEFT_UPPER);
      ObjectSetInteger(0,name,OBJPROP_XDISTANCE,m_x+m_actual_w-S(16));
      ObjectSetInteger(0,name,OBJPROP_YDISTANCE,m_y+m_actual_h-S(16));
      ObjectSetInteger(0,name,OBJPROP_XSIZE,S(14));
      ObjectSetInteger(0,name,OBJPROP_YSIZE,S(14));
      ObjectSetInteger(0,name,OBJPROP_FONTSIZE,F(7));
      ObjectSetInteger(0,name,OBJPROP_BGCOLOR,C'49,63,81');
      ObjectSetInteger(0,name,OBJPROP_COLOR,C'190,202,218');
      ObjectSetInteger(0,name,OBJPROP_BORDER_COLOR,C'68,84,105');
      ObjectSetInteger(0,name,OBJPROP_HIDDEN,true);
      ObjectSetInteger(0,name,OBJPROP_SELECTABLE,true);
      ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,OBJ_ALL_PERIODS);
      ObjectSetString(0,name,OBJPROP_FONT,"Segoe UI");
      ObjectSetString(0,name,OBJPROP_TEXT,"+");
      ObjectSetString(0,name,OBJPROP_TOOLTIP,"Drag this corner to resize the dashboard.");
     }

   void PreserveDragProgress()
     {
      string header=m_prefix+"HEADER_BG";
      string show=m_prefix+"SHOW_DASHBOARD";
      if(ObjectFind(0,header)>=0 && ObjectGetInteger(0,header,OBJPROP_SELECTED)>0)
        {
         m_x=(int)ObjectGetInteger(0,header,OBJPROP_XDISTANCE);
         m_y=(int)ObjectGetInteger(0,header,OBJPROP_YDISTANCE);
        }
      else if(ObjectFind(0,show)>=0 && ObjectGetInteger(0,show,OBJPROP_SELECTED)>0)
        {
         m_x=(int)ObjectGetInteger(0,show,OBJPROP_XDISTANCE);
         m_y=(int)ObjectGetInteger(0,show,OBJPROP_YDISTANCE);
        }

      string grip=m_prefix+"RESIZE_GRIP";
      if(ObjectFind(0,grip)>=0 && ObjectGetInteger(0,grip,OBJPROP_SELECTED)>0)
        {
         int handle_x=(int)ObjectGetInteger(0,grip,OBJPROP_XDISTANCE);
         int requested=(int)MathRound((handle_x-m_x+S(14))/m_scale);
         m_w=(int)MathMax(420,MathMin(960,requested));
        }
     }

public:
   XHDashboard()
     {
      m_x=12;
      m_y=12;
      m_w=420;
      m_h=620;
      m_actual_w=760;
      m_actual_h=620;
      m_content_h=620;
      m_scale=1.0;
      m_compact=true;
      m_visible=true;
      m_strategies_open=false;
      m_m30_levels_open=false;
      m_levels_open=false;
      m_plan_open=false;
      m_controls_open=false;
      m_prefix="XH_AI_DASH_";
     }

   void Initialize(XHStateManager &state)
     {
      m_w=(int)state.GetNumber(Key("w"),420.0);
      m_w=(int)MathMax(420,MathMin(960,m_w));
      m_compact=state.GetNumber(Key("compact"),1.0)>0.5;
      m_visible=state.GetNumber(Key("visible"),1.0)>0.5;
      m_strategies_open=state.GetNumber(Key("strategies_open"),0.0)>0.5;
      m_m30_levels_open=state.GetNumber(Key("m30_levels_open"),0.0)>0.5;
      m_levels_open=state.GetNumber(Key("levels_open"),0.0)>0.5;
      m_plan_open=state.GetNumber(Key("plan_open"),0.0)>0.5;
      m_controls_open=state.GetNumber(Key("controls_open"),0.0)>0.5;
      m_x=(int)state.GetNumber(Key("x"),-1.0);
      m_y=(int)state.GetNumber(Key("y"),-1.0);
      DeleteOwnedObjects();
      ComputeGeometry();
      if(m_x<=4)
         m_x=12;
      if(m_y<=4) m_y=12;
      state.SetNumber(Key("x"),m_x);
      state.SetNumber(Key("y"),m_y);
     }

   void ResetSize(XHStateManager &state)
     {
      m_w=420;
      state.SetNumber(Key("w"),m_w);
      ComputeGeometry();
     }

   void SetVisible(XHStateManager &state,const bool visible)
     {
      m_visible=visible;
      state.SetNumber(Key("visible"),visible ? 1.0 : 0.0);
      ComputeGeometry();
     }

   void ResetPosition(XHStateManager &state)
     {
      ComputeGeometry();
      m_x=12;
      m_y=12;
      state.SetNumber(Key("x"),m_x);
      state.SetNumber(Key("y"),m_y);
     }

   void Resize(XHStateManager &state,const int delta)
     {
      m_w=(int)MathMax(420,MathMin(960,m_w+delta));
      state.SetNumber(Key("w"),m_w);
      ComputeGeometry();
     }

   void Compact(XHStateManager &state,const bool compact)
     {
      m_compact=compact;
      state.SetNumber(Key("compact"),compact ? 1.0 : 0.0);
      ComputeGeometry();
     }

   bool IsCompact() const { return m_compact; }

   string Action(const string object_name) const
     {
      if(StringFind(object_name,m_prefix)!=0) return "";
      return StringSubstr(object_name,StringLen(m_prefix));
     }

   bool ToggleSection(const string action,XHStateManager &state)
     {
      if(action=="BODY_SECTION_STRATEGIES")
        {
         m_strategies_open=!m_strategies_open;
         state.SetNumber(Key("strategies_open"),m_strategies_open ? 1.0 : 0.0);
         return true;
        }
      if(action=="BODY_SECTION_M30_LEVELS")
        {
         m_m30_levels_open=!m_m30_levels_open;
         state.SetNumber(Key("m30_levels_open"),m_m30_levels_open ? 1.0 : 0.0);
         return true;
        }
      if(action=="BODY_SECTION_LEVELS")
        {
         m_levels_open=!m_levels_open;
         state.SetNumber(Key("levels_open"),m_levels_open ? 1.0 : 0.0);
         return true;
        }
      if(action=="BODY_SECTION_PLAN")
        {
         m_plan_open=!m_plan_open;
         state.SetNumber(Key("plan_open"),m_plan_open ? 1.0 : 0.0);
         return true;
        }
      if(action=="BODY_SECTION_CONTROLS")
        {
         m_controls_open=!m_controls_open;
         state.SetNumber(Key("controls_open"),m_controls_open ? 1.0 : 0.0);
         return true;
        }
      return false;
     }

   bool HandleDrag(const string object_name,XHStateManager &state)
     {
      if(object_name==m_prefix+"HEADER_BG")
        {
         m_x=(int)ObjectGetInteger(0,object_name,OBJPROP_XDISTANCE);
         m_y=(int)ObjectGetInteger(0,object_name,OBJPROP_YDISTANCE);
         ComputeGeometry();
         state.SetNumber(Key("x"),m_x);
         state.SetNumber(Key("y"),m_y);
         return true;
        }
      if(object_name==m_prefix+"SHOW_DASHBOARD")
        {
         m_x=(int)ObjectGetInteger(0,object_name,OBJPROP_XDISTANCE);
         m_y=(int)ObjectGetInteger(0,object_name,OBJPROP_YDISTANCE);
         ComputeGeometry();
         state.SetNumber(Key("x"),m_x);
         state.SetNumber(Key("y"),m_y);
         return true;
        }
      if(object_name==m_prefix+"RESIZE_GRIP")
        {
         int handle_x=(int)ObjectGetInteger(0,object_name,OBJPROP_XDISTANCE);
         int requested=(int)MathRound((handle_x-m_x+S(14))/m_scale);
         m_w=(int)MathMax(420,MathMin(960,requested));
         state.SetNumber(Key("w"),m_w);
         ComputeGeometry();
         return true;
        }
      return false;
     }

   void Render(const string symbol,const double bid,const ENUM_TIMEFRAMES chart_tf,
               const int digits,const XHAnalysisSnapshot &context,
               const XHStrategyResult &strategies[],const XHSignalDecision &signal,
               const XHTradePlan &plan,const XHObservedTradeLevels &observed,
               const M30AnalysisSnapshot &m30,
               const XHAIResponse &ai,const bool bot_enabled,const bool analysis_enabled,
               const bool ai_enabled,const bool drawings_enabled,
               const bool structure_marks,const bool zone_marks,const bool plan_marks,
               const bool legacy_marks,const bool trading_permission,
               const bool live_execution,const bool risk_locked,
               const bool risk_check_passed,const string risk_reason,
               const ENUM_XH_EXECUTION_STATE execution_state,
               const string session_text,const string positions_text,
               const bool m30_analysis_enabled,const bool m30_drawings_enabled,
               const bool all_strategies_enabled,const bool h1_marks,
               const bool h4_marks,const bool d1_marks,const bool all_marks)
     {
      PreserveDragProgress();
      ComputeGeometry();
      if(!m_visible)
        {
         HideByPrefix(m_prefix);
         Button("SHOW_DASHBOARD","SHOW DASHBOARD",m_x,m_y,S(118),S(28),
                C'30,85,130',clrWhite);
         ObjectSetString(0,m_prefix+"SHOW_DASHBOARD",OBJPROP_TOOLTIP,
                         "Click to restore the dashboard. Drag to move it.");
         ChartRedraw(0);
         return;
        }

      Rect("BG",m_x,m_y,m_actual_w,m_actual_h,C'15,20,28',C'52,63,78');
      Rect("HEADER_BG",m_x,m_y,m_actual_w,S(34),C'28,36,48',C'28,36,48');
      ObjectSetInteger(0,m_prefix+"HEADER_BG",OBJPROP_SELECTABLE,true);
      ObjectSetString(0,m_prefix+"HEADER_BG",OBJPROP_TOOLTIP,"Drag this title bar to move the dashboard.");

      Label("TITLE","XAUUSD HYBRID AI",PX(12),PY(10),F(11),C'235,240,247');
      Label("SYMBOL",symbol+" | "+TimeframeText(chart_tf),PX(150),PY(11),F(9),C'143,201,255');
      string bot_status=(bot_enabled ?
                         ((trading_permission && live_execution) ? "BOT RUNNING" : "NO ORDERS") :
                         "BOT STOPPED");
      Label("BOT_STATUS",bot_status,PX(m_w-196),PY(11),F(7),
            bot_enabled ? ((trading_permission && live_execution) ? C'57,197,151' : C'255,190,93') :
                          C'226,137,142');
      Button("COMPACT",m_compact ? "RESTORE" : "MIN",
             PX(m_w-134),PY(5),S(54),S(24),C'46,60,77',clrWhite);
      Button("HIDE","HIDE",PX(m_w-74),PY(5),S(62),S(24),C'46,60,77',clrWhite);
      ObjectSetString(0,m_prefix+"BOT_STATUS",OBJPROP_TOOLTIP,
                      bot_enabled && !(trading_permission && live_execution) ?
                      "BOT is on for analysis. Orders remain disabled because trade input and live execution permissions are not both ON." :
                      "BOT state controls the analysis/automation loop. Order execution also requires trade input and live execution permissions.");

      int control_y=44;
      Button("BOT",bot_enabled ? "BOT ON" : "BOT OFF",PX(12),PY(control_y),S(84),S(27),
             bot_enabled ? C'25,96,73' : C'94,57,59',clrWhite);
      ObjectSetString(0,m_prefix+"BOT",OBJPROP_TOOLTIP,
                      "BOT ON enables the analysis/automation loop only. Orders require trade input and live execution permissions.");
      Button("ANALYSIS",analysis_enabled ? "ANALYSIS ON" : "ANALYSIS OFF",
             PX(102),PY(control_y),S(102),S(27),
             analysis_enabled ? C'31,75,97' : C'72,77,83',clrWhite);
      ObjectSetString(0,m_prefix+"ANALYSIS",OBJPROP_TOOLTIP,
                      "Pause or resume chart and M30 analysis. Existing positions keep their broker-side protection.");
      Button("AI",ai_enabled ? "AI ON" : "AI OFF",PX(212),PY(control_y),S(68),S(27),
             ai_enabled ? C'31,75,97' : C'72,77,83',clrWhite);
      ObjectSetString(0,m_prefix+"AI",OBJPROP_TOOLTIP,AIStatusText(ai,ai_enabled));
      Button("DRAWINGS",drawings_enabled ? "DRAWINGS ON" : "DRAWINGS OFF",
             PX(286),PY(control_y),S(106),S(27),
             drawings_enabled ? C'31,75,97' : C'72,77,83',clrWhite);
      ObjectSetString(0,m_prefix+"DRAWINGS",OBJPROP_TOOLTIP,
                      "Master visibility for the unified chart analysis layers and the selected legacy/timeframe marking layers.");

      if(m_compact)
        {
         HideBodyObjects();
         Label("PERMISSIONS","TRADE INPUT "+(trading_permission ? "ON" : "OFF")+
               " | LIVE "+(live_execution ? "ON" : "OFF"),
               PX(12),PY(78),F(7),
               (trading_permission && live_execution) ? C'255,190,93' : C'180,190,202');
         Label("EXECUTION",(bot_enabled && trading_permission && live_execution && !risk_locked) ?
               "AUTO ENTRY ARMED" : "AUTO ENTRY OFF",
               PX(m_w-174),PY(78),F(7),
               (bot_enabled && trading_permission && live_execution && !risk_locked) ?
               C'255,190,93' : C'180,190,202');
         string pane_text="ACTIVE "+TimeframeText(chart_tf)+" | EMBEDDED M30"+
                          (chart_tf==PERIOD_M30 ? " (BOTH M30)" : "");
         Label("PANE_STATUS",FitText(pane_text,m_w-24,8),PX(12),PY(98),F(8),C'143,201,255');
         Label("COMPACT_STATE",FitText(AIStatusText(ai,ai_enabled),m_w-24,7),
               PX(12),PY(118),F(7),ai.valid ? C'57,197,151' : C'255,190,93');
         DrawResizeGrip();
         ChartRedraw(0);
         return;
        }

      Label("PERMISSIONS","TRADE INPUT "+(trading_permission ? "ON" : "OFF")+
            "  |  LIVE "+(live_execution ? "ON" : "OFF"),
            PX(12),PY(78),F(8),
            (trading_permission && live_execution) ? C'255,190,93' : C'180,190,202');
      Label("EXECUTION","EXECUTION "+
            (execution_state==XH_EXEC_PROCESSING ? "PROCESSING" :
             execution_state==XH_EXEC_ERROR ? "ERROR" : "IDLE"),
            PX(m_w-174),PY(78),F(8),
            execution_state==XH_EXEC_ERROR ? C'239,104,104' : C'180,190,202');
      string pane_text="ACTIVE "+TimeframeText(chart_tf)+" | EMBEDDED M30"+
                       (chart_tf==PERIOD_M30 ? " (BOTH M30)" : "");
      Label("PANE_STATUS",FitText(pane_text,m_w-24,7),PX(12),PY(90),F(7),C'143,201,255');

      string compact=m_prefix+"COMPACT_STATE";
      if(ObjectFind(0,compact)>=0) ObjectSetInteger(0,compact,OBJPROP_TIMEFRAMES,0);

      int y=102;
      BodyLabel("MARKET_TITLE","MARKET CONTEXT",12,y,9,C'143,201,255');
      y+=18;
      int card_w=(m_w-40)/3;
      int card_gap=8;
      int card_h=68;
      BodyRect("CARD_D1",12,y,card_w,card_h,C'20,27,37',C'44,56,71');
      BodyRect("CARD_H4",12+card_w+card_gap,y,card_w,card_h,C'20,27,37',C'44,56,71');
      BodyRect("CARD_H1",12+2*(card_w+card_gap),y,card_w,card_h,C'20,27,37',C'44,56,71');
      BodyLabel("CARD_D1_TITLE","D1 BIAS",22,y+8,8,C'143,201,255');
      BodyLabel("CARD_D1_VALUE",TrendText(context.trend_d1),22,y+27,10,DirectionColor(context.trend_d1));
      BodyLabel("CARD_D1_SUB","CLOSED DAILY TREND",22,y+48,7,C'170,180,194');
      int h4_x=12+card_w+card_gap;
      BodyLabel("CARD_H4_TITLE","H4 CONTEXT",h4_x+10,y+8,8,C'143,201,255');
      BodyLabel("CARD_H4_VALUE",TrendText(context.trend_h4),h4_x+10,y+27,10,DirectionColor(context.trend_h4));
      BodyLabel("CARD_H4_SUB","H1 "+TrendText(context.trend_h1),h4_x+10,y+48,7,C'170,180,194');
      int h1_x=12+2*(card_w+card_gap);
      BodyLabel("CARD_H1_TITLE","H1 LOCATION",h1_x+10,y+8,8,C'143,201,255');
      BodyLabel("CARD_H1_VALUE",TrendText(context.trend_h1),h1_x+10,y+27,10,DirectionColor(context.trend_h1));
      BodyLabel("CARD_H1_SUB","M30 "+TrendText(context.trend_m30),h1_x+10,y+48,7,C'170,180,194');
      y+=76;

      BodyRect("M30_RESULT_PANEL",12,y,m_w-24,76,C'20,27,37',C'44,56,71');
      color m30_color=C'255,190,93';
      if(StringFind(m30.result,"BUY")>=0) m30_color=C'57,197,151';
      else if(StringFind(m30.result,"SELL")>=0) m30_color=C'239,104,104';
      string m30_result=m30.data_ready ? m30.result :
         (m30.result=="" ? "WAITING FOR M30 HISTORY" : m30.result);
      BodyLabel("M30_RESULT",FitText(m30_result,m_w-44,9),22,y+6,9,m30_color);
      double neutral_percent=MathMax(0.0,100.0-m30.buy_evidence_percent-m30.sell_evidence_percent);
      string evidence="BUY "+DoubleToString(m30.buy_evidence_percent,1)+"%  |  SELL "+
         DoubleToString(m30.sell_evidence_percent,1)+"%  |  NEUTRAL "+
         DoubleToString(neutral_percent,1)+"%  |  ON "+IntegerToString(m30.active_strategy_count)+
         "  CONF "+IntegerToString(m30.confirmed_strategy_count)+
         "  DEV "+IntegerToString(m30.developing_strategy_count);
      BodyLabel("M30_EVIDENCE",FitText(evidence,m_w-44,8),22,y+25,8,C'211,218,228');
      string m30_reason=m30.reason;
      if(m30_reason=="") m30_reason=m30.data_ready ? "Analysis is updating." : "Waiting for completed M30 data.";
      BodyLabel("M30_REASON",FitText(m30_reason,m_w-44,7),22,y+42,7,C'170,180,194');
      string ai_status=AIStatusText(ai,ai_enabled);
      BodyLabel("AI_STATUS",FitText(ai_status,m_w-44,7),22,y+60,7,
                ai.valid ? C'57,197,151' : C'255,190,93');
      ObjectSetString(0,m_prefix+"BODY_AI_STATUS",OBJPROP_TOOLTIP,ai_status);
      y+=84;

      BodyRect("SIGNAL_PANEL",12,y,m_w-24,50,C'20,27,37',C'44,56,71');
      string signal_title=XHSignalStateName(signal.state)+
         " | BUY "+DoubleToString(context.buy_score,1)+
         " / SELL "+DoubleToString(context.sell_score,1);
      BodyLabel("SIGNAL_TITLE",FitText(signal_title,m_w-44,9),22,y+7,9,
                signal.valid ? DirectionColor((int)signal.direction) : C'211,218,228');
      BodyLabel("SIGNAL_REASON",FitText(signal.explanation,m_w-44,8),22,y+28,8,C'170,180,194');
      y+=58;

      int ready=0,waiting=0,disabled=0;
      for(int i=0;i<XH_STRATEGY_COUNT;i++)
        {
         if(!strategies[i].enabled) { disabled++; continue; }
         if(strategies[i].confirmed || strategies[i].developing) ready++;
         else waiting++;
        }
      DrawSectionHeader("STRATEGIES","M30 STRATEGIES ("+IntegerToString(XH_STRATEGY_COUNT)+")",
                        IntegerToString(ready)+" Ready | "+IntegerToString(waiting)+
                        " Waiting | "+IntegerToString(disabled)+" Off",
                        m_strategies_open,y);
      if(!m_strategies_open) HideByPrefix(m_prefix+"BODY_M30STRAT_");
      y+=24;
      if(m_strategies_open)
        {
         y+=4;
         int column_w=(m_w-32)/2;
         for(int i=0;i<XH_STRATEGY_COUNT;i++)
           {
            int col=i%2;
            int row=i/2;
            string state_text=StrategyState(strategies[i]);
            string line=strategies[i].name+" | "+state_text+
               " | B "+DoubleToString(strategies[i].buy_points,0)+
               " / S "+DoubleToString(strategies[i].sell_points,0);
            if(strategies[i].reason!="")
               line+=" | "+strategies[i].reason;
            color text_color=(strategies[i].confirmed ? C'57,197,151' :
                              strategies[i].developing ? C'255,190,93' :
                              strategies[i].invalidated ? C'239,104,104' :
                              strategies[i].enabled ? C'200,208,219' : C'112,120,132');
         int max_chars=(int)MathMax(22,MaxChars(column_w-8,8));
            string short_line=StringSubstr(line,0,max_chars);
            color fill=strategies[i].enabled ? C'25,43,55' : C'39,42,49';
            BodyButton("M30STRAT_"+IntegerToString(i),short_line,
                       16+col*column_w,y+row*22,column_w-4,20,fill,text_color);
            ObjectSetString(0,m_prefix+"BODY_M30STRAT_"+IntegerToString(i),OBJPROP_TOOLTIP,
                            strategies[i].name+" | "+state_text+" | BUY "+
                            DoubleToString(strategies[i].buy_points,1)+" / SELL "+
                            DoubleToString(strategies[i].sell_points,1)+" | "+strategies[i].reason+
                            "\nClick to toggle this M30 strategy.");
           }
         y+=5*22;
        }

      y+=8;
      DrawSectionHeader("M30_LEVELS","M30 MARKET LEVELS","swings · zones · liquidity",
                        m_m30_levels_open,y);
      if(!m_m30_levels_open) HideByPrefix(m_prefix+"BODY_M30LEVEL_");
      y+=24;
      if(m_m30_levels_open)
        {
         y+=4;
         string swing_line="SWING H "+(m30.latest_high.valid ? PriceText(m30.latest_high.price,digits) : "N/A")+
            "  |  SWING L "+(m30.latest_low.valid ? PriceText(m30.latest_low.price,digits) : "N/A");
         string zones_line="SUPPORT "+(m30.support_valid ? PriceText(m30.support_low,digits)+"-"+
            PriceText(m30.support_high,digits) : "N/A")+"  |  RESISTANCE "+
            (m30.resistance_valid ? PriceText(m30.resistance_low,digits)+"-"+
            PriceText(m30.resistance_high,digits) : "N/A");
         string liquidity_line="BSL "+(m30.buy_liquidity_valid ? PriceText(m30.buy_liquidity_level,digits) : "N/A")+
            "  |  SSL "+(m30.sell_liquidity_valid ? PriceText(m30.sell_liquidity_level,digits) : "N/A")+
            "  |  EQH "+(m30.equal_highs_valid ? PriceText(m30.equal_highs_level,digits) : "N/A")+
            "  |  EQL "+(m30.equal_lows_valid ? PriceText(m30.equal_lows_level,digits) : "N/A");
         string fvg_line="FVG "+((m30.bullish_fvg_valid || m30.bearish_fvg_valid) ?
            PriceText(m30.fvg_low,digits)+"-"+PriceText(m30.fvg_high,digits) : "N/A")+
            "  |  ORDER BLOCK "+(m30.order_block_valid ? PriceText(m30.order_block_low,digits)+"-"+
            PriceText(m30.order_block_high,digits) : "N/A")+
            (m30.ifvg_valid ? "  |  IFVG "+PriceText(m30.fvg_low,digits)+"-"+PriceText(m30.fvg_high,digits) : "");
         string range_line="RANGE "+PriceText(m30.range_low,digits)+"-"+PriceText(m30.range_high,digits)+
            "  |  EQ "+PriceText(m30.equilibrium,digits)+"  |  OTE "+
            PriceText(m30.ote_low,digits)+"-"+PriceText(m30.ote_high,digits);
         string momentum_line="ATR "+DoubleToString(m30.atr,digits)+"  |  RSI "+
            DoubleToString(m30.rsi,1)+"  |  MACD "+DoubleToString(m30.macd_main,digits)+
            "  |  ADX "+DoubleToString(m30.adx,1)+"  |  "+m30.alignment;
         string m30_lines[6];
         m30_lines[0]=swing_line;
         m30_lines[1]=zones_line;
         m30_lines[2]=liquidity_line;
         m30_lines[3]=fvg_line;
         m30_lines[4]=range_line;
         m30_lines[5]=momentum_line;
         for(int i=0;i<6;i++)
            BodyLabel("M30LEVEL_"+IntegerToString(i),FitText(m30_lines[i],m_w-40,7),
                      16,y+i*18,7,C'211,218,228');
         y+=6*18;
        }

      y+=8;
      DrawSectionHeader("LEVELS","PRICE LEVELS","entry · stop · targets",m_levels_open,y);
      if(!m_levels_open) HideByPrefix(m_prefix+"BODY_LEVEL_");
      y+=24;
      if(m_levels_open)
        {
         y+=4;
         bool fresh_observed=observed.valid && observed.source_candle_time>0 &&
            TimeCurrent()-observed.source_candle_time<=PeriodSeconds(PERIOD_M30)*3;
         bool have_levels=plan.valid || fresh_observed;
         double zone_low=(plan.valid ? plan.entry_zone_low : observed.entry_zone_low);
         double zone_high=(plan.valid ? plan.entry_zone_high : observed.entry_zone_high);
         double entry=(plan.valid ? plan.preferred_entry : observed.preferred_entry);
         double stop=(plan.valid ? plan.stop_loss : observed.stop_loss);
         double tp1=(plan.valid ? plan.tp1 : observed.tp1);
         double tp2=(plan.valid ? plan.tp2 : observed.tp2);
         double tp3=(plan.valid ? plan.tp3 : observed.tp3);
         if(have_levels)
           {
            BodyLabel("LEVEL_1","ENTRY ZONE  "+PriceText(zone_low,digits)+
                      " - "+PriceText(zone_high,digits)+" | PREFERRED "+
                      PriceText(entry,digits),16,y+2,8,C'211,218,228');
            BodyLabel("LEVEL_2","STOP LOSS  "+PriceText(stop,digits)+
                      " | TP1  "+PriceText(tp1,digits),16,y+22,8,C'232,145,151');
            BodyLabel("LEVEL_3","TP2  "+PriceText(tp2,digits)+
                      " | TP3  "+PriceText(tp3,digits)+
                      (plan.valid ? " | RR "+DoubleToString(plan.risk_reward_1,2) : " | CANDIDATE"),
                      16,y+42,8,C'92,190,163');
           }
         else
           {
            BodyLabel("LEVEL_1","No fresh M30 entry zone or price plan is available.",16,y+2,8,C'170,180,194');
            BodyLabel("LEVEL_2","BID "+PriceText(context.bid,digits)+
                      " | SPREAD "+DoubleToString(context.spread_points,1)+" pts",16,y+22,8,C'170,180,194');
            BodyLabel("LEVEL_3","Levels appear here when the M30 analysis exports a fresh setup.",16,y+42,8,C'170,180,194');
           }
         y+=60;
        }

      y+=8;
      string plan_summary=plan.valid ? (risk_check_passed ? "risk approved" : "risk rejected") : "analysis only";
      if(risk_locked) plan_summary="risk locked";
      DrawSectionHeader("PLAN","TRADE PLAN",plan_summary,m_plan_open,y);
      if(!m_plan_open) HideByPrefix(m_prefix+"BODY_PLAN_");
      y+=24;
      if(m_plan_open)
        {
         y+=4;
         string plan_state=(plan.valid ?
                            (risk_check_passed ? "RISK CHECK PASSED" : "RISK REJECTED") :
                            "ANALYSIS ONLY");
         if(risk_locked) plan_state="RISK LOCKED";
         BodyLabel("PLAN_STATE",plan_state+" | "+
                   (plan.valid ? XHDirectionName(plan.direction) : XHSignalStateName(signal.state)),
                   16,y+2,8,(plan.valid && risk_check_passed) ? C'57,197,151' : C'255,190,93');
         string risk_text=(plan.valid && risk_check_passed ?
            "VOLUME "+DoubleToString(plan.volume,2)+" | EST. RISK "+
             DoubleToString(plan.estimated_risk_money,2)+" | SESSION "+session_text :
            "ENTRY DISABLED | "+(risk_reason=="" ?
             (plan.rejection_reason=="" ? signal.explanation : plan.rejection_reason) : risk_reason));
         BodyLabel("PLAN_RISK",FitText(risk_text,m_w-40,8),16,y+20,8,C'170,180,194');
         BodyLabel("PLAN_POSITIONS",FitText(positions_text,m_w-40,7),16,y+38,7,C'170,180,194');
         string m30_plan_status="M30 "+(m30.data_ready ? m30.trade_plan_status : "INSUFFICIENT DATA")+
            " | "+(m30.trade_direction>0 ? "BUY" : (m30.trade_direction<0 ? "SELL" : "NO DIRECTION"));
         BodyLabel("PLAN_M30_STATUS",FitText(m30_plan_status,m_w-40,7),16,y+56,7,C'143,201,255');
         string m30_entry="M30 ENTRY "+PriceText(m30.entry_zone_low,digits)+"-"+
            PriceText(m30.entry_zone_high,digits)+" | PREFERRED "+PriceText(m30.preferred_entry,digits);
         BodyLabel("PLAN_M30_ENTRY",FitText(m30_entry,m_w-40,7),16,y+74,7,C'211,218,228');
         string m30_stop="M30 STOP "+PriceText(m30.stop_loss,digits)+" | TP1 "+
            PriceText(m30.take_profit_1,digits)+" | TP2 "+PriceText(m30.take_profit_2,digits);
         BodyLabel("PLAN_M30_STOP",FitText(m30_stop,m_w-40,7),16,y+92,7,C'232,145,151');
         string m30_targets="M30 TP3 "+PriceText(m30.take_profit_3,digits)+" | RR "+
            (m30.risk_reward_tp3>0.0 ? DoubleToString(m30.risk_reward_tp3,2)+"R" : "N/A")+
            " | LOT "+(m30.lot_size>0.0 ? DoubleToString(m30.lot_size,2) : "N/A")+
            " | RISK "+(m30.estimated_money_risk>0.0 ? DoubleToString(m30.estimated_money_risk,2) : "N/A");
         BodyLabel("PLAN_M30_TARGETS",FitText(m30_targets,m_w-40,7),16,y+110,7,C'92,190,163');
         BodyLabel("PLAN_M30_MODE",FitText("M30 plan is analysis-only; live order permission is controlled separately.",m_w-40,7),
                   16,y+128,7,C'170,180,194');
         y+=148;
        }

      y+=8;
      DrawSectionHeader("CONTROLS","DISPLAY & DASHBOARD CONTROLS","chart layers · strategy switches · panel size",
                        m_controls_open,y);
      if(!m_controls_open) HideByPrefix(m_prefix+"BODY_CONTROL_");
      y+=24;
      if(m_controls_open)
        {
         y+=4;
         bool legacy_gate=(drawings_enabled && legacy_marks);
         int control_gap=6;
         int control_w=(m_w-24-3*control_gap)/4;
         BodyButton("CONTROL_STRUCTURE",LayerStatusText("STRUCT",structure_marks,drawings_enabled),
                    12,y,control_w,26,
                    structure_marks ? (drawings_enabled ? C'40,77,70' : C'99,76,45') : C'49,55,65',clrWhite);
         BodyButton("CONTROL_ZONES",LayerStatusText("ZONES",zone_marks,drawings_enabled),
                    12+control_w+control_gap,y,control_w,26,
                    zone_marks ? (drawings_enabled ? C'40,77,70' : C'99,76,45') : C'49,55,65',clrWhite);
         BodyButton("CONTROL_PLAN_MARKS",LayerStatusText("ENTRY/SLTP",plan_marks,drawings_enabled),
                    12+2*(control_w+control_gap),y,control_w,26,
                    plan_marks ? (drawings_enabled ? C'40,77,70' : C'99,76,45') : C'49,55,65',clrWhite);
         BodyButton("CONTROL_LEGACY",LayerStatusText("LEGACY",legacy_marks,drawings_enabled),
                    12+3*(control_w+control_gap),y,control_w,26,
                    legacy_marks ? (drawings_enabled ? C'40,77,70' : C'99,76,45') : C'49,55,65',clrWhite);
         ObjectSetString(0,m_prefix+"BODY_CONTROL_STRUCTURE",OBJPROP_TOOLTIP,
                         "Toggle structure markings. ARM means selected but hidden by DRAWINGS OFF.");
         ObjectSetString(0,m_prefix+"BODY_CONTROL_ZONES",OBJPROP_TOOLTIP,
                         "Toggle M30 zones and fair-value-gap markings. ARM means selected but hidden by DRAWINGS OFF.");
         ObjectSetString(0,m_prefix+"BODY_CONTROL_PLAN_MARKS",OBJPROP_TOOLTIP,
                         "Toggle M30 entry zone, entry, stop loss, and targets.");
         ObjectSetString(0,m_prefix+"BODY_CONTROL_LEGACY",OBJPROP_TOOLTIP,
                         "Master switch for legacy H1/H4/D1/M30 markings. ARM means selected but hidden by DRAWINGS OFF.");
         y+=30;
         int mark_gap=5;
         int mark_w=(m_w-24-5*mark_gap)/6;
         BodyButton("TF_H1",LayerStatusText("H1",h1_marks,legacy_gate),12,y,mark_w,26,
                    h1_marks ? (legacy_gate ? C'40,77,70' : C'99,76,45') : C'49,55,65',clrWhite);
         BodyButton("TF_H4",LayerStatusText("H4",h4_marks,legacy_gate),12+mark_w+mark_gap,y,mark_w,26,
                    h4_marks ? (legacy_gate ? C'40,77,70' : C'99,76,45') : C'49,55,65',clrWhite);
         BodyButton("TF_D1",LayerStatusText("D1",d1_marks,legacy_gate),12+2*(mark_w+mark_gap),y,mark_w,26,
                    d1_marks ? (legacy_gate ? C'40,77,70' : C'99,76,45') : C'49,55,65',clrWhite);
         string all_tf_text=(all_marks ? LayerStatusText("TF ALL",true,legacy_gate) :
                             ((h1_marks || h4_marks || d1_marks) ? "TF MIXED" : "TF ALL OFF"));
         BodyButton("ALL_MARKS",all_tf_text,
                    12+3*(mark_w+mark_gap),y,mark_w,26,
                    all_marks ? (legacy_gate ? C'40,77,70' : C'99,76,45') : C'46,70,92',clrWhite);
         BodyButton("M30_MARKS",LayerStatusText("M30",m30_drawings_enabled,legacy_gate),
                    12+4*(mark_w+mark_gap),y,mark_w,26,
                    m30_drawings_enabled ? (legacy_gate ? C'40,77,70' : C'99,76,45') : C'49,55,65',clrWhite);
         bool some_strategies=(disabled<XH_STRATEGY_COUNT);
         string strategy_state=(all_strategies_enabled ? "STRAT ALL ON" :
                                (some_strategies ? "STRAT MIXED" : "STRAT ALL OFF"));
         BodyButton("ALL_STRATEGIES",strategy_state,
                    12+5*(mark_w+mark_gap),y,mark_w,26,
                    all_strategies_enabled ? C'46,70,92' : C'85,62,47',clrWhite);
         ObjectSetString(0,m_prefix+"BODY_TF_H1",OBJPROP_TOOLTIP,
                         "Toggle H1 legacy structure marks. ARM means selected but hidden by DRAWINGS or LEGACY OFF.");
         ObjectSetString(0,m_prefix+"BODY_TF_H4",OBJPROP_TOOLTIP,
                         "Toggle H4 legacy structure marks. ARM means selected but hidden by DRAWINGS or LEGACY OFF.");
         ObjectSetString(0,m_prefix+"BODY_TF_D1",OBJPROP_TOOLTIP,
                         "Toggle D1 legacy structure marks. ARM means selected but hidden by DRAWINGS or LEGACY OFF.");
         ObjectSetString(0,m_prefix+"BODY_ALL_MARKS",OBJPROP_TOOLTIP,
                         "Toggle H1, H4, and D1 marks together. M30 marks have their own control.");
         ObjectSetString(0,m_prefix+"BODY_M30_MARKS",OBJPROP_TOOLTIP,
                         "Toggle legacy M30 markings. ARM means selected but hidden by DRAWINGS or LEGACY OFF.");
         ObjectSetString(0,m_prefix+"BODY_ALL_STRATEGIES",OBJPROP_TOOLTIP,
                         "Toggle all ten M30 strategies. When turning all off, the previous selection is saved for restore.");
         y+=30;
         int setting_gap=6;
         int setting_w=(m_w-24-3*setting_gap)/4;
         BodyButton("WIDTH_MINUS","WIDTH -",12,y,setting_w,26,C'46,60,77',clrWhite);
         BodyButton("WIDTH_PLUS","WIDTH +",12+setting_w+setting_gap,y,setting_w,26,C'46,60,77',clrWhite);
         BodyButton("RESET_POS","RESET POSITION",12+2*(setting_w+setting_gap),y,setting_w,26,C'46,60,77',clrWhite);
         BodyButton("RESET_SIZE","RESET SIZE",12+3*(setting_w+setting_gap),y,setting_w,26,C'46,60,77',clrWhite);
         y+=30;
        }

      y+=8;
      string last_update=m30.last_closed_bar>0 ? TimeToString(m30.last_closed_bar,TIME_DATE|TIME_MINUTES) : "waiting";
      string footer="M30 "+(m30_analysis_enabled ? "ACTIVE" : "PAUSED")+
                " | AI "+(ai_enabled ? (ai.valid ? "ONLINE" : "OFFLINE") : "OFF")+
                " | "+(risk_locked ? "RISK LOCKED" : "RISK NORMAL")+
                " | LAST M30 "+last_update;
      BodyLabel("FOOTER",FitText(footer,m_w-(risk_locked ? 160 : 24),7),
                12,y,7,risk_locked ? C'239,104,104' : C'143,201,255');
      if(risk_locked)
         BodyButton("RISK_RESET","CLEAR RISK LOCK",m_w-138,y-4,126,22,C'118,73,56',clrWhite);
      else
         HideByPrefix(m_prefix+"BODY_RISK_RESET");

      DrawResizeGrip();
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
