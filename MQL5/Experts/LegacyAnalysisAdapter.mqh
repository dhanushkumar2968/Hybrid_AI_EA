#ifndef XAUUSD_HYBRID_LEGACY_ANALYSIS_ADAPTER_MQH
#define XAUUSD_HYBRID_LEGACY_ANALYSIS_ADAPTER_MQH

#include "MTFTrendAnalysis.mqh"
#include "D1Analysis.mqh"
#include "M30_Analysis.mqh"
#include "..\\Include\\XAUUSDHybrid\\CoreTypes.mqh"
#include "..\\Include\\XAUUSDHybrid\\StrategyScoring.mqh"

// Adapts the existing MT5 analysis engines to the hybrid AI/risk interfaces.
// Analysis and chart markings stay in the legacy engines; dashboard controls
// are presented by the single XH dashboard.
class XHLegacyAnalysisAdapter
  {
private:
   CMTFTrendAnalysis m_mtf;
   CD1Analysis       m_d1;
   CM30Analysis      m_m30;
   D1AnalysisSnapshot m_d1_snapshot;
   MTFContextSnapshot m_h1_snapshot;
   MTFContextSnapshot m_h4_snapshot;
   MTFContextSnapshot m_mtf_d1_snapshot;
   M30AnalysisSnapshot m_m30_snapshot;
   XHStrategyScoring m_scoring;
   bool m_initialized;
   bool m_master_drawings_enabled;
   bool m_legacy_drawings_enabled;

   void ApplyDrawingVisibility()
     {
      if(!m_initialized) return;
      bool legacy_visible=m_master_drawings_enabled && m_legacy_drawings_enabled;
      m_mtf.SetMasterDrawingsVisible(legacy_visible);
      m_d1.SetMasterMarkingsVisible(legacy_visible);
      m_m30.SetMasterDrawingsVisible(legacy_visible);
     }

   int DirectionSign(const int direction)
     {
      return (direction>0)-(direction<0);
     }

   string StrategyName(const int index)
     {
      string names[10]={"Market Structure","Liquidity Sweep",
         "Support / Resistance","Engulfing","Breakout","Institutional Zones",
         "Premium / Discount","False Breakout","Session Trading","Momentum / Divergence"};
      if(index<0 || index>=10) return "Unknown";
      return names[index];
     }

   int CorrelationGroup(const int index)
     {
      // Related outputs from one structural/liquidity event count only once.
      if(index==0 || index==4) return 0;
      if(index==1 || index==7) return 1;
      if(index==2 || index==5) return 2;
      if(index==3 || index==9) return 3;
      if(index==8) return 4;
      return -1; // Premium/discount is contextual, not an independent vote.
     }

   double ConfiguredWeight(const int index)
     {
      if(index==0) return M30InpWeightStructure;
      if(index==1) return M30InpWeightLiquidity;
      if(index==2) return M30InpWeightSupportResistance;
      if(index==3) return M30InpWeightEngulfing;
      if(index==4) return M30InpWeightBreakout;
      if(index==5) return M30InpWeightInstitutional;
      if(index==6) return M30InpWeightPremiumDiscount;
      if(index==7) return M30InpWeightFalseBreakout;
      if(index==8) return M30InpWeightSession;
      return M30InpWeightMomentum;
     }

   bool UpdateSnapshots()
     {
      m_d1.GetSnapshot(m_d1_snapshot);
      m_mtf.GetContext(PERIOD_H1,m_h1_snapshot);
      m_mtf.GetContext(PERIOD_H4,m_h4_snapshot);
      m_mtf.GetContext(PERIOD_D1,m_mtf_d1_snapshot);
      return m_m30.GetSnapshot(m_m30_snapshot);
     }

   void MapStrategies(XHStrategyResult &results[])
     {
      for(int i=0;i<XH_STRATEGY_COUNT;i++)
        {
         M30StrategyResult source=m_m30_snapshot.strategies[i];
         results[i].name=StrategyName(i);
         results[i].enabled=m_mtf.M30AnalysisEnabled() && m_mtf.M30StrategyEnabled(i);
         results[i].buy_points=source.buy_points;
         results[i].sell_points=source.sell_points;
         results[i].max_points=(source.weight>0.0 ? source.weight : ConfiguredWeight(i));
         results[i].developing=source.developing;
         results[i].confirmed=source.confirmed;
         results[i].invalidated=source.invalidated;
         results[i].buy_confirmed=source.confirmed && source.direction>0;
         results[i].sell_confirmed=source.confirmed && source.direction<0;
         results[i].relevant_price=source.key_price;
         results[i].zone_high=source.zone_high;
         results[i].zone_low=source.zone_low;
         results[i].signal_time=source.event_time;
         results[i].invalidation=0.0;
         results[i].correlation_group=CorrelationGroup(i);
         results[i].reason=(source.status=="" ?
                            (m_m30_snapshot.data_ready ? source.explanation : "Waiting for M30 history") :
                            source.status+" | "+source.explanation);

         // Publish the existing M30 engine's stop only for the strategy whose
         // observed zone produced that exact plan.
         double point=SymbolInfoDouble(_Symbol,SYMBOL_POINT);
         double tolerance=MathMax(point,point*2.0);
         bool same_zone=m_m30_snapshot.trade_plan_valid &&
            source.zone_high>source.zone_low &&
            MathAbs(source.zone_low-m_m30_snapshot.entry_zone_low)<=tolerance &&
            MathAbs(source.zone_high-m_m30_snapshot.entry_zone_high)<=tolerance;
         if(same_zone) results[i].invalidation=m_m30_snapshot.stop_loss;
        }
     }

public:
   XHLegacyAnalysisAdapter()
     {
      m_initialized=false;
      m_master_drawings_enabled=true;
      m_legacy_drawings_enabled=true;
     }

   bool Initialize()
     {
      if(!m_mtf.InputsValid())
        {
         Print("XH legacy adapter: invalid MTF analysis inputs.");
         return false;
        }
      m_d1.Initialize();
      if(!m_mtf.Initialize())
        {
         m_d1.Deinitialize();
         return false;
        }
      m_mtf.SuppressDashboard(true);
      if(!m_m30.Initialize(m_mtf))
        {
         m_mtf.Deinitialize();
         m_d1.Deinitialize();
         return false;
        }
      m_d1.SetMarkingsVisible(m_mtf.MarkingsVisible(2));
      m_initialized=true;
      Update();
      return true;
     }

   void RefreshStrategyStates(XHStrategyResult &results[])
     {
      if(!m_initialized) return;
      UpdateSnapshots();
      MapStrategies(results);
     }

   void Update()
     {
      if(!m_initialized) return;
      m_d1.Update();
      m_mtf.Update();
      m_m30.Update(m_d1,m_mtf);
      UpdateSnapshots();
     }

   bool Apply(XHAnalysisSnapshot &context,XHStrategyResult &results[])
     {
      if(!m_initialized) return false;
      UpdateSnapshots();
      if(m_d1_snapshot.ready)
         context.trend_d1=DirectionSign((int)m_d1_snapshot.direction);
      else if(m_mtf_d1_snapshot.ready)
         context.trend_d1=DirectionSign(m_mtf_d1_snapshot.direction);
      if(m_h4_snapshot.ready) context.trend_h4=DirectionSign(m_h4_snapshot.direction);
      if(m_h1_snapshot.ready) context.trend_h1=DirectionSign(m_h1_snapshot.direction);
      if(m_m30_snapshot.data_ready)
        {
         int setup_direction=0;
         if(StringFind(m_m30_snapshot.result,"BUY SETUP")==0) setup_direction=1;
         else if(StringFind(m_m30_snapshot.result,"SELL SETUP")==0) setup_direction=-1;
         else setup_direction=DirectionSign(m_m30_snapshot.structure_direction);
         context.trend_m30=setup_direction;
         context.atr_m30=m_m30_snapshot.atr;
         context.source_candle_time=m_m30_snapshot.last_closed_bar;
         context.analysis_time=m_m30_snapshot.last_update;
         context.explanation=m_m30_snapshot.result+" | "+m_m30_snapshot.reason+
                             " | "+m_m30_snapshot.alignment;
        }
      MapStrategies(results);
      m_scoring.Score(results,context);
      return m_m30_snapshot.data_ready;
     }

   bool M30Snapshot(M30AnalysisSnapshot &snapshot)
     {
      snapshot=m_m30_snapshot;
      return snapshot.data_ready;
     }

   bool M30AnalysisEnabled()
     {
      return m_initialized && m_mtf.M30AnalysisEnabled();
     }

   bool M30DrawingsEnabled()
     {
      return m_initialized && m_mtf.M30DrawingsEnabled();
     }

   bool M30StrategyEnabled(const int index)
     {
      return m_initialized && m_mtf.M30StrategyEnabled(index);
     }

   bool AllM30StrategiesEnabled()
     {
      return m_initialized && m_mtf.AllM30StrategiesEnabled();
     }

   void SetM30AnalysisEnabled(const bool enabled)
     {
      if(!m_initialized) return;
      m_mtf.SetM30AnalysisEnabled(enabled);
     }

   void SetM30DrawingsEnabled(const bool enabled)
     {
      if(!m_initialized) return;
      m_mtf.SetM30DrawingsEnabled(enabled);
      m_m30.SetMarkingsVisible(enabled);
     }

   void ToggleM30Strategy(const int index)
     {
      if(m_initialized) m_mtf.ToggleM30Strategy(index);
     }

   void ToggleAllM30Strategies()
     {
      if(m_initialized) m_mtf.ToggleAllM30Strategies();
     }

   bool MarkingsVisible(const int index)
     {
      return m_initialized && m_mtf.MarkingsVisible(index);
     }

   bool AllMarkingsVisible()
     {
      return m_initialized && m_mtf.AllMarkingsEnabled();
     }

   void SetMarkingsVisible(const int index,const bool visible)
     {
      if(!m_initialized) return;
      m_mtf.SetMarkingsVisible(index,visible);
      if(index==2) m_d1.SetMarkingsVisible(visible);
     }

   void ToggleAllMarkings()
     {
      if(!m_initialized) return;
      bool turn_on=!m_mtf.AllMarkingsEnabled();
      for(int i=0;i<3;i++)
         SetMarkingsVisible(i,turn_on);
     }

   void SetDrawingsVisible(const bool visible)
     {
      if(!m_initialized) return;
      m_master_drawings_enabled=visible;
      ApplyDrawingVisibility();
     }

   void SetLegacyDrawingsVisible(const bool visible)
     {
      if(!m_initialized) return;
      m_legacy_drawings_enabled=visible;
      ApplyDrawingVisibility();
     }

   void SetBotEnabled(const bool enabled)
     {
      if(m_initialized) m_mtf.SetBotEnabled(enabled);
     }

   bool BotEnabled()
     {
      return m_initialized && m_mtf.M30BotEnabled();
     }

   bool IsBotButton(const string object_name)
     {
      return m_initialized && m_mtf.IsBotButton(object_name);
     }

   void ObservedTradeLevels(XHObservedTradeLevels &levels)
     {
      levels.valid=m_m30_snapshot.data_ready && m_m30_snapshot.trade_plan_valid;
      levels.direction=DirectionSign(m_m30_snapshot.trade_direction);
      levels.source_candle_time=m_m30_snapshot.last_closed_bar;
      levels.entry_zone_high=m_m30_snapshot.entry_zone_high;
      levels.entry_zone_low=m_m30_snapshot.entry_zone_low;
      levels.preferred_entry=m_m30_snapshot.preferred_entry;
      levels.stop_loss=m_m30_snapshot.stop_loss;
      levels.tp1=m_m30_snapshot.take_profit_1;
      levels.tp2=m_m30_snapshot.take_profit_2;
      levels.tp3=m_m30_snapshot.take_profit_3;
     }

   void HandleChartEvent(const int id,const long &lparam,const double &dparam,
                         const string &sparam)
     {
      if(!m_initialized) return;
      m_mtf.HandleChartEvent(id,lparam,dparam,sparam);
      m_m30.HandleChartEvent(id);
      if(id==CHARTEVENT_OBJECT_CLICK)
         m_d1.SetMarkingsVisible(m_mtf.MarkingsVisible(2));
     }

   void Deinitialize(const int reason)
     {
      if(!m_initialized) return;
      bool preserve_chart_objects=(reason==REASON_CHARTCHANGE);
      m_m30.Deinitialize(preserve_chart_objects);
      m_mtf.Deinitialize(preserve_chart_objects);
      m_d1.Deinitialize(preserve_chart_objects);
      m_initialized=false;
     }
  };

#endif
