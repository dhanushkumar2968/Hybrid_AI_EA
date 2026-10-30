#property strict
#property version   "1.00"
#property description "Hybrid XAUUSD analysis EA with local Python inference; live execution defaults off."

#include "..\\Include\\XAUUSDHybrid\\CoreTypes.mqh"
#include "LegacyAnalysisAdapter.mqh"
#include "..\\Include\\XAUUSDHybrid\\MarketData.mqh"
#include "..\\Include\\XAUUSDHybrid\\MultiTimeframe.mqh"
#include "..\\Include\\XAUUSDHybrid\\FeatureBuilder.mqh"
#include "..\\Include\\XAUUSDHybrid\\AIClient.mqh"
#include "..\\Include\\XAUUSDHybrid\\SignalEngine.mqh"
#include "..\\Include\\XAUUSDHybrid\\TradePlan.mqh"
#include "..\\Include\\XAUUSDHybrid\\RiskManager.mqh"
#include "..\\Include\\XAUUSDHybrid\\ExecutionEngine.mqh"
#include "..\\Include\\XAUUSDHybrid\\PositionManager.mqh"
#include "..\\Include\\XAUUSDHybrid\\Dashboard.mqh"
#include "..\\Include\\XAUUSDHybrid\\ChartRenderer.mqh"
#include "..\\Include\\XAUUSDHybrid\\StateManager.mqh"
#include "..\\Include\\XAUUSDHybrid\\TradeLogger.mqh"

input group "Safety — all order permissions default off"
input bool BOT_ENABLED=false;
input bool ANALYSIS_ENABLED=true;
input bool AI_ENABLED=false;
input bool DRAWINGS_ENABLED=true;
input bool TRADING_PERMISSION=false;
input bool LIVE_EXECUTION=false;
input bool MOCK_AI_MODE=false;

input group "AI service"
input string AI_ENDPOINT="http://127.0.0.1:8765/v1/analyze";
input int AI_TIMEOUT_MS=1500;
input string EXPECTED_MODEL_VERSION="";

input group "Execution"
input ulong EXPERT_MAGIC=5103001;
input ulong MAX_DEVIATION_POINTS=30;
input double MAX_SPREAD_POINTS=80.0;
input double COMMISSION_PER_LOT_ROUND_TURN=0.0;
input double SLIPPAGE_ALLOWANCE_POINTS=0.0;

input group "Risk limits"
input double RISK_PER_TRADE_PERCENT=0.50;
input double MAX_DAILY_LOSS_PERCENT=3.0;
input double MAX_EQUITY_DRAWDOWN_PERCENT=15.0;
input double MAX_TOTAL_OPEN_RISK_PERCENT=1.50;
input int MAX_OPEN_POSITIONS=1;
input int MAX_DAILY_TRADES=5;
input int MAX_CONSECUTIVE_LOSSES=3;
input bool RESTRICT_TO_UTC_SESSION=true;

input group "Position management (optional)"
input double PARTIAL_CLOSE_AT_TP1_PERCENT=0.0;
input double PARTIAL_CLOSE_AT_TP2_PERCENT=0.0;
input double BREAK_EVEN_AFTER_R=0.0;
input double TRAIL_AFTER_R=0.0;
input double TRAIL_DISTANCE_ATR=1.0;
input int MAX_HOLDING_SECONDS=0;
input bool EMERGENCY_CLOSE_IF_STOP_MISSING=false;

XHMarketData          g_market;
XHMultiTimeframe      g_multi_timeframe;
XHLegacyAnalysisAdapter g_legacy_analysis;
XHFeatureBuilder      g_feature_builder;
XHAIClient            g_ai_client;
XHSignalEngine        g_signal_engine;
XHTradePlanEngine     g_trade_plan_engine;
XHRiskManager         g_risk_manager;
XHExecutionEngine     g_execution_engine;
XHPositionManager     g_position_manager;
XHDashboard           g_dashboard;
XHChartRenderer       g_chart_renderer;
XHStateManager        g_state;
XHTradeLogger         g_logger;

XHAnalysisSnapshot    g_context;
XHStrategyResult      g_strategies[XH_STRATEGY_COUNT];
XHFeatureVector       g_features;
XHAIResponse          g_ai_response;
XHSignalDecision      g_signal;
XHTradePlan           g_trade_plan;
XHRiskLimits          g_risk_limits;

string g_symbol="";
bool g_bot_enabled=false;
bool g_analysis_enabled=true;
bool g_ai_enabled=false;
bool g_drawings_enabled=true;
bool g_show_structure_marks=false;
bool g_show_zone_marks=true;
bool g_show_plan_marks=true;
bool g_show_legacy_marks=false;
bool g_force_refresh=false;
string g_last_execution_attempt="";
string g_position_status="No EA-managed positions.";
string g_risk_check_reason="Waiting for a fresh M30 analysis.";
bool g_risk_check_passed=false;
datetime g_last_protection_draw=0;
datetime g_last_status_log=0;
datetime g_last_risk_monitor=0;

string SessionNameUTC()
  {
   MqlDateTime now;
   TimeToStruct(TimeGMT(),now);
   if(now.hour>=13 && now.hour<=16) return "London / New York overlap";
   if(now.hour>=7 && now.hour<=12) return "London";
   if(now.hour>=17 && now.hour<=20) return "New York";
   return "Asia / off-session";
  }

string PositionsSummary()
  {
   int count=0;
   string summary="POSITIONS: none";
   for(int i=0;i<PositionsTotal();i++)
     {
      ulong ticket=PositionGetTicket(i);
      if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL)!=g_symbol ||
         PositionGetInteger(POSITION_MAGIC)!=(long)EXPERT_MAGIC) continue;
      count++;
      ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
      summary="POSITIONS: "+XHDirectionName(type==POSITION_TYPE_BUY ? XH_BUY : XH_SELL)+
              " "+DoubleToString(PositionGetDouble(POSITION_VOLUME),2)+
              " lots  OPEN "+DoubleToString(PositionGetDouble(POSITION_PRICE_OPEN),_Digits)+
              "  SL "+DoubleToString(PositionGetDouble(POSITION_SL),_Digits)+
              "  TP "+DoubleToString(PositionGetDouble(POSITION_TP),_Digits);
      break;
     }
   if(count>1) summary+="  +"+IntegerToString(count-1)+" more";
   if(g_position_status!="") summary+="  |  "+StringSubstr(g_position_status,0,52);
   return summary;
  }

void RefreshDashboard()
  {
   MqlTick tick;
   double bid=(g_market.CurrentTick(tick) ? tick.bid : 0.0);
   XHObservedTradeLevels observed;
   g_legacy_analysis.ObservedTradeLevels(observed);
   M30AnalysisSnapshot m30_snapshot;
   g_legacy_analysis.M30Snapshot(m30_snapshot);
   g_dashboard.Render(g_symbol,bid,(ENUM_TIMEFRAMES)_Period,(int)SymbolInfoInteger(g_symbol,SYMBOL_DIGITS),
                      g_context,g_strategies,g_signal,g_trade_plan,observed,m30_snapshot,g_ai_response,
                      g_bot_enabled,g_analysis_enabled,g_ai_enabled,g_drawings_enabled,
                      g_show_structure_marks,g_show_zone_marks,g_show_plan_marks,g_show_legacy_marks,
                      TRADING_PERMISSION,LIVE_EXECUTION,g_state.RiskLocked(),
                      g_risk_check_passed,g_risk_check_reason,
                      g_execution_engine.State(),SessionNameUTC(),PositionsSummary(),
                      g_legacy_analysis.M30AnalysisEnabled(),g_legacy_analysis.M30DrawingsEnabled(),
                      g_legacy_analysis.AllM30StrategiesEnabled(),
                      g_legacy_analysis.MarkingsVisible(0),g_legacy_analysis.MarkingsVisible(1),
                      g_legacy_analysis.MarkingsVisible(2),g_legacy_analysis.AllMarkingsVisible());
  }

void RefreshChartAnalysis()
  {
   if(!g_drawings_enabled)
     {
      g_chart_renderer.HideAnalysis();
      return;
     }
   XHObservedTradeLevels observed;
   g_legacy_analysis.ObservedTradeLevels(observed);
   g_chart_renderer.RenderAnalysis(g_market,g_context,g_strategies,g_trade_plan,observed,true,
                                   g_show_structure_marks,g_show_zone_marks,g_show_plan_marks);
  }

void ProcessPositionManager()
  {
   XHManagementCommand command;
   string status="";
   if(g_position_manager.NextCommand(g_symbol,g_market,g_state,command,status))
     {
      if(TRADING_PERMISSION && LIVE_EXECUTION)
        {
         string reason="";
         g_execution_engine.ApplyManagement(g_symbol,command,TRADING_PERMISSION,LIVE_EXECUTION,
                                            g_state,g_logger,reason);
         g_position_status=(reason=="" ? command.reason : reason);
        }
      else
        {
         g_position_status="Management inactive; broker-side SL/TP remains.";
        }
     }
   else if(status!="")
     {
      g_position_status=status;
      if(TimeCurrent()-g_last_status_log>=60)
        {
         g_logger.Log("RISK_LOCK",g_symbol,"",status);
         g_last_status_log=TimeCurrent();
        }
     }
   else
      g_position_status="Positions reconciled; broker-side protection checked.";
  }

void AnalyzeOnBarEvents(const bool new_mn1,const bool new_w1,const bool new_d1,
                        const bool new_h4,const bool new_h1,const bool new_m30,
                        const bool new_m15,const bool new_m5)
  {
   if(!g_analysis_enabled) return;
   bool any_event=(new_mn1 || new_w1 || new_d1 || new_h4 || new_h1 || new_m30 || new_m15 || new_m5);
   if(!any_event && !g_force_refresh) return;
   bool refresh_all=g_force_refresh;
   bool update_m30=(new_m30 || refresh_all);
   if(!g_multi_timeframe.Refresh(g_market,g_context,
        new_mn1||refresh_all,new_w1||refresh_all,new_d1||refresh_all,new_h4||refresh_all,
        new_h1||refresh_all,new_m30||refresh_all,new_m15||refresh_all,new_m5||refresh_all))
     {
      if(TimeCurrent()-g_last_status_log>=60)
        {
         g_logger.Log("ANALYSIS_ERROR",g_symbol,"","Insufficient completed-candle history for one or more timeframes.");
         g_last_status_log=TimeCurrent();
        }
      g_force_refresh=false;
      return;
     }
   g_context.symbol=g_symbol;
   g_context.analysis_time=TimeCurrent();
   g_context.spread_points=g_market.SpreadPoints();
   MqlTick tick;
   if(g_market.CurrentTick(tick))
     {
      g_context.bid=tick.bid;
      g_context.ask=tick.ask;
     }
   MqlRates latest[];
   if(g_market.ReadClosedBars(PERIOD_M30,1,latest))
      g_context.source_candle_time=latest[0].time;

   if(update_m30)
     {
      bool legacy_ready=g_legacy_analysis.Apply(g_context,g_strategies);
      if(!legacy_ready)
         g_logger.Log("STRATEGY_WAIT",g_symbol,"","Existing M30 analysis engine is waiting for sufficient broker history.");
      if(g_ai_enabled && legacy_ready)
        {
         if(g_feature_builder.Build(g_market,g_context,g_context.source_candle_time,
                                    g_context.spread_points,g_features))
           {
            M30AnalysisSnapshot legacy_m30;
            if(g_legacy_analysis.M30Snapshot(legacy_m30))
              {
               g_features.structure_break=0.0;
               if(legacy_m30.bullish_bos || legacy_m30.bullish_choch || legacy_m30.bullish_mss)
                  g_features.structure_break=1.0;
               else if(legacy_m30.bearish_bos || legacy_m30.bearish_choch || legacy_m30.bearish_mss)
                  g_features.structure_break=-1.0;
               g_features.liquidity_sweep=0.0;
               if(legacy_m30.bullish_sweep) g_features.liquidity_sweep=1.0;
               else if(legacy_m30.bearish_sweep) g_features.liquidity_sweep=-1.0;
              }
            g_ai_client.Analyze(g_symbol,"M30",g_context.source_candle_time,g_features,
                                MOCK_AI_MODE,g_ai_response);
           }
         else
           {
            g_ai_response.valid=false;
            g_ai_response.warning="Feature generation failed.";
           }
        }
      else
        {
         g_ai_response.valid=false;
         g_ai_response.warning="AI disabled.";
         g_ai_response.prediction_class="NO_TRADE";
         g_ai_response.model_version="disabled";
        }
     }
   g_signal_engine.Decide(g_context,g_strategies,g_ai_response,g_ai_enabled,
                          MAX_SPREAD_POINTS,g_signal);
   XHObservedTradeLevels observed_levels;
   g_legacy_analysis.ObservedTradeLevels(observed_levels);
   g_trade_plan_engine.Build(g_market,g_signal,observed_levels,g_trade_plan);
   string risk_reason=g_trade_plan.rejection_reason;
   g_risk_check_passed=false;
   if(g_trade_plan.valid)
     {
      if(g_risk_manager.CheckAndSize(g_symbol,g_context.spread_points,g_trade_plan.direction,
                                     g_trade_plan,g_state,risk_reason))
        {
         g_risk_check_passed=true;
         g_logger.LogRisk(g_symbol,g_signal.signal_id,true,"Analysis-time risk sizing passed.",g_trade_plan);
        }
      else
         g_logger.LogRisk(g_symbol,g_signal.signal_id,false,risk_reason,g_trade_plan);
     }
   g_risk_check_reason=risk_reason;
   if(g_bot_enabled && g_signal.valid && g_signal.signal_id!=g_last_execution_attempt)
     {
      g_last_execution_attempt=g_signal.signal_id;
      string execution_reason="";
      g_execution_engine.ExecuteEntry(g_symbol,g_signal,g_trade_plan,g_bot_enabled,
                                      TRADING_PERMISSION,LIVE_EXECUTION,g_risk_manager,
                                      g_state,g_logger,execution_reason);
     }
   g_logger.LogAnalysis(g_context,g_strategies,g_ai_response,g_signal,g_trade_plan,risk_reason);
   g_logger.LogTradePlan(g_symbol,g_signal.signal_id,g_trade_plan);
   RefreshChartAnalysis();
   g_force_refresh=false;
  }

void UpdateSignalLifecycle()
  {
   bool active=(g_signal.state==XH_BUY_DEVELOPING || g_signal.state==XH_SELL_DEVELOPING ||
               g_signal.state==XH_BUY_CONFIRMED || g_signal.state==XH_SELL_CONFIRMED);
   if(!active) return;
   if(g_signal.source_candle_time<=0 ||
      TimeCurrent()-g_signal.source_candle_time>3*PeriodSeconds(PERIOD_M30))
     {
      g_signal.state=XH_EXPIRED;
      g_signal.valid=false;
      g_signal.explanation="Signal expired because its M30 source candle is stale.";
      g_trade_plan.valid=false;
      g_trade_plan.rejection_reason="Signal expired.";
      g_risk_check_passed=false;
      g_risk_check_reason="Signal expired.";
      g_logger.Log("SIGNAL_EXPIRED",g_symbol,g_signal.signal_id,g_signal.explanation);
      RefreshChartAnalysis();
      return;
     }
   if(!g_signal.valid || !g_trade_plan.valid) return;
   MqlTick tick;
   if(!g_market.CurrentTick(tick)) return;
   bool invalidated=(g_signal.direction==XH_BUY ? tick.bid<=g_trade_plan.stop_loss
                                                 : tick.ask>=g_trade_plan.stop_loss);
   if(invalidated)
     {
      g_signal.state=XH_INVALIDATED;
      g_signal.valid=false;
      g_signal.explanation="Current broker price crossed the exact observed trade-plan invalidation.";
      g_trade_plan.valid=false;
      g_trade_plan.rejection_reason="Setup invalidated before an entry.";
      g_risk_check_passed=false;
      g_risk_check_reason="Setup invalidated before an entry.";
      g_logger.Log("SIGNAL_INVALIDATED",g_symbol,g_signal.signal_id,g_signal.explanation);
      RefreshChartAnalysis();
     }
  }

int OnInit()
  {
   g_symbol=_Symbol;
   g_bot_enabled=BOT_ENABLED;
   g_analysis_enabled=ANALYSIS_ENABLED;
   g_ai_enabled=AI_ENABLED;
   g_drawings_enabled=DRAWINGS_ENABLED;
   g_state.Configure((long)EXPERT_MAGIC);
   if(g_state.GetNumber("dash_v4_layer_cfg",0.0)<0.5)
     {
      // Upgrade once from the old layer flags, which could be forced OFF by
      // the previous drawings-master implementation during initialization.
      g_state.SetNumber("dash_v4_structure",1.0);
      g_state.SetNumber("dash_v4_zones",1.0);
      g_state.SetNumber("dash_v4_plan_marks",1.0);
      g_state.SetNumber("dash_v4_legacy_marks",1.0);
      g_state.SetNumber("dash_v4_layer_cfg",1.0);
     }
   g_show_structure_marks=(g_state.GetNumber("dash_v4_structure",1.0)>0.5);
   g_show_zone_marks=(g_state.GetNumber("dash_v4_zones",1.0)>0.5);
   g_show_plan_marks=(g_state.GetNumber("dash_v4_plan_marks",1.0)>0.5);
   g_show_legacy_marks=(g_state.GetNumber("dash_v4_legacy_marks",1.0)>0.5);
   if(!g_market.Initialize(g_symbol)) return INIT_FAILED;

   if(!g_legacy_analysis.Initialize()) return INIT_FAILED;
   g_legacy_analysis.SetBotEnabled(g_bot_enabled);
   g_legacy_analysis.SetM30AnalysisEnabled(g_analysis_enabled);
   g_legacy_analysis.SetDrawingsVisible(g_drawings_enabled);
   g_legacy_analysis.SetLegacyDrawingsVisible(g_show_legacy_marks);

   g_risk_limits.risk_per_trade_pct=RISK_PER_TRADE_PERCENT;
   g_risk_limits.max_daily_loss_pct=MAX_DAILY_LOSS_PERCENT;
   g_risk_limits.max_equity_drawdown_pct=MAX_EQUITY_DRAWDOWN_PERCENT;
   g_risk_limits.max_total_open_risk_pct=MAX_TOTAL_OPEN_RISK_PERCENT;
   g_risk_limits.max_spread_points=MAX_SPREAD_POINTS;
   g_risk_limits.commission_per_lot_round_turn=COMMISSION_PER_LOT_ROUND_TURN;
   g_risk_limits.slippage_allowance_points=SLIPPAGE_ALLOWANCE_POINTS;
   g_risk_limits.max_open_positions=MAX_OPEN_POSITIONS;
   g_risk_limits.max_daily_trades=MAX_DAILY_TRADES;
   g_risk_limits.max_consecutive_losses=MAX_CONSECUTIVE_LOSSES;
   g_risk_limits.restrict_session=RESTRICT_TO_UTC_SESSION;
   g_risk_limits.magic=(long)EXPERT_MAGIC;
   g_risk_manager.Configure(g_risk_limits);
   g_execution_engine.Configure((long)EXPERT_MAGIC,MAX_DEVIATION_POINTS);
   g_position_manager.Configure((long)EXPERT_MAGIC,PARTIAL_CLOSE_AT_TP1_PERCENT,
      PARTIAL_CLOSE_AT_TP2_PERCENT,BREAK_EVEN_AFTER_R,TRAIL_AFTER_R,
      TRAIL_DISTANCE_ATR,MAX_HOLDING_SECONDS,EMERGENCY_CLOSE_IF_STOP_MISSING);
   g_ai_client.Configure(AI_ENDPOINT,AI_TIMEOUT_MS,EXPECTED_MODEL_VERSION);
   g_dashboard.Initialize(g_state);
   g_context.symbol=g_symbol;
   g_signal.state=XH_NO_VALID_SETUP;
   g_signal.direction=XH_FLAT;
   g_signal.valid=false;
   g_signal.explanation="Waiting for completed analysis candles.";
   g_trade_plan.valid=false;
   g_trade_plan.rejection_reason="Waiting for completed analysis candles.";
   g_ai_response.valid=false;
   g_ai_response.prediction_class="NO_TRADE";
   g_ai_response.model_version="unavailable";
   g_ai_response.warning="No AI inference has run.";
   g_force_refresh=true;
   if(!EventSetTimer(MTFInpRefreshSeconds))
     {
      Print("XH: EventSetTimer failed, error=",GetLastError());
      g_legacy_analysis.Deinitialize(REASON_INITFAILED);
      return INIT_FAILED;
     }
   g_logger.Log("INIT",g_symbol,"",
      "analysis="+(g_analysis_enabled ? "on" : "off")+
      ";ai="+(g_ai_enabled ? "on" : "off")+
      ";bot="+(g_bot_enabled ? "on" : "off")+
      ";trading_permission="+(TRADING_PERMISSION ? "on" : "off")+
      ";live_execution="+(LIVE_EXECUTION ? "on" : "off"));
   RefreshDashboard();
   return INIT_SUCCEEDED;
  }

void OnDeinit(const int reason)
  {
   EventKillTimer();
   g_chart_renderer.HideAnalysis();
   g_dashboard.DeleteOwnedObjects();
   g_legacy_analysis.Deinitialize(reason);
   g_logger.Log("DEINIT",g_symbol,"","reason="+IntegerToString(reason));
  }

void OnTick()
  {
   ProcessPositionManager();
  }

void OnTimer()
  {
   if(g_analysis_enabled) g_legacy_analysis.Update();
   if(TimeCurrent()-g_last_risk_monitor>=30)
     {
      string risk_status="";
      if(!g_risk_manager.MonitorAccountRisk(g_symbol,g_state,risk_status) &&
         risk_status!="Persistent risk lock is active.")
         g_logger.Log("RISK_MONITOR",g_symbol,"",risk_status);
      g_last_risk_monitor=TimeCurrent();
     }
   bool new_mn1=g_market.IsNewBar(PERIOD_MN1);
   bool new_w1=g_market.IsNewBar(PERIOD_W1);
   bool new_d1=g_market.IsNewBar(PERIOD_D1);
   bool new_h4=g_market.IsNewBar(PERIOD_H4);
   bool new_h1=g_market.IsNewBar(PERIOD_H1);
   bool new_m30=g_market.IsNewBar(PERIOD_M30);
   bool new_m15=g_market.IsNewBar(PERIOD_M15);
   bool new_m5=g_market.IsNewBar(PERIOD_M5);
   AnalyzeOnBarEvents(new_mn1,new_w1,new_d1,new_h4,new_h1,new_m30,new_m15,new_m5);
   UpdateSignalLifecycle();
   ProcessPositionManager();
   if(TimeCurrent()-g_last_protection_draw>=5)
     {
      g_chart_renderer.RenderProtection(g_symbol,(long)EXPERT_MAGIC);
      g_last_protection_draw=TimeCurrent();
     }
   RefreshDashboard();
  }

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
  {
   string action="";
   if(id==CHARTEVENT_OBJECT_CLICK)
      action=g_dashboard.Action(sparam);
   bool legacy_bot_button=false;
   if(action=="")
     {
      legacy_bot_button=(id==CHARTEVENT_OBJECT_CLICK && g_legacy_analysis.IsBotButton(sparam));
      g_legacy_analysis.HandleChartEvent(id,lparam,dparam,sparam);
     }
   if(legacy_bot_button)
     {
      g_bot_enabled=g_legacy_analysis.BotEnabled();
      g_logger.Log("BOT_TOGGLE",g_symbol,"",g_bot_enabled ?
                   "System started; explicit trade and live permissions still gate orders." :
                   "New entries stopped; broker-side protection is unchanged.");
      RefreshDashboard();
      return;
     }
   if(id==CHARTEVENT_CHART_CHANGE)
     {
      RefreshDashboard();
      return;
     }
   if(id==CHARTEVENT_OBJECT_DRAG)
     {
      if(g_dashboard.HandleDrag(sparam,g_state)) RefreshDashboard();
      return;
     }
   if(id!=CHARTEVENT_OBJECT_CLICK || action=="") return;
   if(action=="BOT")
     {
      g_bot_enabled=!g_bot_enabled;
      g_legacy_analysis.SetBotEnabled(g_bot_enabled);
      g_logger.Log("BOT_TOGGLE",g_symbol,"",g_bot_enabled ?
                   "System started for analysis; explicit trade and live permissions still gate orders." :
                   "New entries stopped; broker-side protection is unchanged.");
     }
   else if(action=="ANALYSIS")
     {
      g_analysis_enabled=!g_analysis_enabled;
      g_legacy_analysis.SetM30AnalysisEnabled(g_analysis_enabled);
      if(g_analysis_enabled) g_force_refresh=true;
      g_logger.Log("ANALYSIS_TOGGLE",g_symbol,"",g_analysis_enabled ? "analysis active" : "analysis paused");
     }
   else if(action=="AI")
     {
      g_ai_enabled=!g_ai_enabled;
      if(!g_ai_enabled)
        {
         g_ai_response.valid=false;
         g_ai_response.warning="AI disabled from dashboard.";
         g_ai_response.prediction_class="NO_TRADE";
        }
      g_logger.Log("AI_TOGGLE",g_symbol,"",g_ai_enabled ? "AI enabled; next request is on a controlled M30 event." :
                   "AI disabled; no model response authorizes entries.");
      g_force_refresh=true;
     }
   else if(action=="DRAWINGS")
     {
      g_drawings_enabled=!g_drawings_enabled;
      g_legacy_analysis.SetDrawingsVisible(g_drawings_enabled);
      RefreshChartAnalysis();
      g_logger.Log("DRAWINGS_TOGGLE",g_symbol,"",g_drawings_enabled ? "analysis markings shown" : "analysis markings hidden");
     }
   else if(action=="COMPACT")
      g_dashboard.Compact(g_state,!g_dashboard.IsCompact());
   else if(action=="HIDE")
      g_dashboard.SetVisible(g_state,false);
   else if(action=="SHOW_DASHBOARD")
      g_dashboard.SetVisible(g_state,true);
   else if(action=="WIDTH_PLUS" || action=="BODY_WIDTH_PLUS")
      g_dashboard.Resize(g_state,60);
   else if(action=="WIDTH_MINUS" || action=="BODY_WIDTH_MINUS")
      g_dashboard.Resize(g_state,-60);
   else if(action=="RESET_POS" || action=="BODY_RESET_POS")
      g_dashboard.ResetPosition(g_state);
   else if(action=="RESET_SIZE" || action=="BODY_RESET_SIZE")
      g_dashboard.ResetSize(g_state);
   else if(action=="BODY_RISK_RESET")
     {
      g_state.SetRiskLocked(false);
      g_logger.Log("RISK_LOCK_RESET",g_symbol,"","Manual dashboard reset; current limits are checked again before any entry.");
     }
   else if(g_dashboard.ToggleSection(action,g_state))
     {
      ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
      RefreshDashboard();
      return;
     }
   else if(StringFind(action,"BODY_M30STRAT_")==0)
     {
      int strategy_index=(int)StringToInteger(StringSubstr(action,StringLen("BODY_M30STRAT_")));
      if(strategy_index>=0 && strategy_index<XH_STRATEGY_COUNT)
        {
         g_legacy_analysis.ToggleM30Strategy(strategy_index);
         g_legacy_analysis.RefreshStrategyStates(g_strategies);
         g_force_refresh=true;
        }
     }
   else if(action=="BODY_ALL_STRATEGIES")
     {
      g_legacy_analysis.ToggleAllM30Strategies();
      g_legacy_analysis.RefreshStrategyStates(g_strategies);
      g_force_refresh=true;
     }
   else if(action=="BODY_M30_MARKS")
      g_legacy_analysis.SetM30DrawingsEnabled(!g_legacy_analysis.M30DrawingsEnabled());
   else if(action=="BODY_TF_H1")
      g_legacy_analysis.SetMarkingsVisible(0,!g_legacy_analysis.MarkingsVisible(0));
   else if(action=="BODY_TF_H4")
      g_legacy_analysis.SetMarkingsVisible(1,!g_legacy_analysis.MarkingsVisible(1));
   else if(action=="BODY_TF_D1")
      g_legacy_analysis.SetMarkingsVisible(2,!g_legacy_analysis.MarkingsVisible(2));
   else if(action=="BODY_ALL_MARKS")
      g_legacy_analysis.ToggleAllMarkings();
   else if(action=="BODY_CONTROL_STRUCTURE")
     {
      g_show_structure_marks=!g_show_structure_marks;
      g_state.SetNumber("dash_v4_structure",g_show_structure_marks ? 1.0 : 0.0);
      RefreshChartAnalysis();
     }
   else if(action=="BODY_CONTROL_ZONES")
     {
      g_show_zone_marks=!g_show_zone_marks;
      g_state.SetNumber("dash_v4_zones",g_show_zone_marks ? 1.0 : 0.0);
      RefreshChartAnalysis();
     }
   else if(action=="BODY_CONTROL_PLAN_MARKS")
     {
      g_show_plan_marks=!g_show_plan_marks;
      g_state.SetNumber("dash_v4_plan_marks",g_show_plan_marks ? 1.0 : 0.0);
      RefreshChartAnalysis();
     }
   else if(action=="BODY_CONTROL_LEGACY")
     {
      g_show_legacy_marks=!g_show_legacy_marks;
      g_state.SetNumber("dash_v4_legacy_marks",g_show_legacy_marks ? 1.0 : 0.0);
      g_legacy_analysis.SetLegacyDrawingsVisible(g_show_legacy_marks);
     }
   ObjectSetInteger(0,sparam,OBJPROP_STATE,false);
   RefreshDashboard();
  }

void OnTradeTransaction(const MqlTradeTransaction &trans,const MqlTradeRequest &request,
                        const MqlTradeResult &result)
  {
   if(trans.type!=TRADE_TRANSACTION_DEAL_ADD || trans.deal==0) return;
   if(!HistoryDealSelect(trans.deal)) return;
   if(HistoryDealGetString(trans.deal,DEAL_SYMBOL)!=g_symbol ||
      HistoryDealGetInteger(trans.deal,DEAL_MAGIC)!=(long)EXPERT_MAGIC) return;
   string details="deal="+IntegerToString((long)trans.deal)+
      ";position_id="+IntegerToString((long)trans.position)+
      ";deal_type="+EnumToString((ENUM_DEAL_TYPE)HistoryDealGetInteger(trans.deal,DEAL_TYPE))+
      ";entry="+EnumToString((ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal,DEAL_ENTRY))+
      ";profit="+DoubleToString(HistoryDealGetDouble(trans.deal,DEAL_PROFIT),2)+
      ";commission="+DoubleToString(HistoryDealGetDouble(trans.deal,DEAL_COMMISSION),2)+
      ";swap="+DoubleToString(HistoryDealGetDouble(trans.deal,DEAL_SWAP),2)+
      ";retcode="+IntegerToString((long)result.retcode);
   g_logger.LogPosition(g_symbol,(ulong)trans.position,"ACTUAL_BROKER_DEAL",
                        trans.volume,trans.price,details);
  }

