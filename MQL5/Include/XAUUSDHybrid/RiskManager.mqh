#ifndef XAUUSD_HYBRID_RISK_MANAGER_MQH
#define XAUUSD_HYBRID_RISK_MANAGER_MQH

#include "CoreTypes.mqh"
#include "StateManager.mqh"

struct XHRiskLimits
  {
   double risk_per_trade_pct;
   double max_daily_loss_pct;
   double max_equity_drawdown_pct;
   double max_total_open_risk_pct;
   double max_spread_points;
   double commission_per_lot_round_turn;
   double slippage_allowance_points;
   int max_open_positions;
   int max_daily_trades;
   int max_consecutive_losses;
   bool restrict_session;
   long magic;
  };

class XHRiskManager
  {
private:
   XHRiskLimits m_limits;

   datetime DayStart()
     {
      MqlDateTime now;
      TimeToStruct(TimeCurrent(),now);
      now.hour=0; now.min=0; now.sec=0;
      return StructToTime(now);
     }

   bool DailyHistory(const string symbol,double &net,int &entries,int &loss_streak)
     {
      net=0.0;
      entries=0;
      loss_streak=0;
      datetime from=DayStart();
      if(!HistorySelect(from,TimeCurrent()))
        {
         Print("XH: HistorySelect failed, error=",GetLastError());
         return false;
        }
      for(int i=0;i<HistoryDealsTotal();i++)
        {
         ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0) continue;
         if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=symbol) continue;
         if(HistoryDealGetInteger(ticket,DEAL_MAGIC)!=m_limits.magic) continue;
         net+=HistoryDealGetDouble(ticket,DEAL_PROFIT)+
              HistoryDealGetDouble(ticket,DEAL_COMMISSION)+
              HistoryDealGetDouble(ticket,DEAL_SWAP)+
              HistoryDealGetDouble(ticket,DEAL_FEE);
         ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY);
         if(entry==DEAL_ENTRY_IN || entry==DEAL_ENTRY_INOUT) entries++;
        }
      if(!HistorySelect(0,TimeCurrent()))
        {
         Print("XH: Full history selection failed during loss-streak reconciliation.");
         return false;
        }
      for(int i=HistoryDealsTotal()-1;i>=0;i--)
        {
         ulong ticket=HistoryDealGetTicket(i);
         if(ticket==0) continue;
         if(HistoryDealGetString(ticket,DEAL_SYMBOL)!=symbol) continue;
         if(HistoryDealGetInteger(ticket,DEAL_MAGIC)!=m_limits.magic) continue;
         ENUM_DEAL_ENTRY entry=(ENUM_DEAL_ENTRY)HistoryDealGetInteger(ticket,DEAL_ENTRY);
         if(entry!=DEAL_ENTRY_OUT && entry!=DEAL_ENTRY_OUT_BY && entry!=DEAL_ENTRY_INOUT) continue;
         double result=HistoryDealGetDouble(ticket,DEAL_PROFIT)+
                       HistoryDealGetDouble(ticket,DEAL_COMMISSION)+
                       HistoryDealGetDouble(ticket,DEAL_SWAP)+
                       HistoryDealGetDouble(ticket,DEAL_FEE);
         if(result<0.0) loss_streak++;
         else if(result>0.0) break;
        }
      if(!HistorySelect(from,TimeCurrent()))
         return false;
      return true;
     }

   bool SessionAllowed()
     {
      if(!m_limits.restrict_session) return true;
      MqlDateTime utc;
      TimeToStruct(TimeGMT(),utc);
      return (utc.hour>=7 && utc.hour<=20);
     }

   bool OpenPositions(const string symbol,int &count,double &open_risk,string &reason)
     {
      count=0;
      open_risk=0.0;
      reason="";
      for(int i=0;i<PositionsTotal();i++)
        {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
         if(PositionGetString(POSITION_SYMBOL)!=symbol ||
            PositionGetInteger(POSITION_MAGIC)!=m_limits.magic) continue;
         count++;
         double stop=PositionGetDouble(POSITION_SL);
         if(stop<=0.0)
           {
            reason="An existing EA position has no protective stop; new entries are locked.";
            return false;
           }
         ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         ENUM_ORDER_TYPE order_type=(type==POSITION_TYPE_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
         double profit=0.0;
         double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
         double slip=m_limits.slippage_allowance_points*point;
         double risk_stop=(type==POSITION_TYPE_BUY ? stop-slip : stop+slip);
         if(!OrderCalcProfit(order_type,symbol,PositionGetDouble(POSITION_VOLUME),
                             PositionGetDouble(POSITION_PRICE_OPEN),risk_stop,profit))
           {
            reason="Could not calculate monetary risk for an existing position.";
            return false;
           }
         open_risk+=MathAbs(profit)+
                    m_limits.commission_per_lot_round_turn*PositionGetDouble(POSITION_VOLUME);
        }
      return true;
     }

   int VolumeDigits(const double step)
     {
      for(int digits=0;digits<=8;digits++)
         if(MathAbs(step-NormalizeDouble(step,digits))<1e-10) return digits;
      return 8;
     }

public:
   XHRiskManager()
     {
      m_limits.risk_per_trade_pct=0.5;
      m_limits.max_daily_loss_pct=3.0;
      m_limits.max_equity_drawdown_pct=15.0;
      m_limits.max_total_open_risk_pct=1.5;
      m_limits.max_spread_points=80.0;
      m_limits.commission_per_lot_round_turn=0.0;
      m_limits.slippage_allowance_points=0.0;
      m_limits.max_open_positions=2;
      m_limits.max_daily_trades=5;
      m_limits.max_consecutive_losses=3;
      m_limits.restrict_session=true;
      m_limits.magic=5103001;
     }

   void Configure(const XHRiskLimits &limits)
     {
      m_limits=limits;
     }

   bool MonitorAccountRisk(const string symbol,XHStateManager &state,string &reason)
     {
      reason="";
      if(state.RiskLocked())
        {
         reason="Persistent risk lock is active.";
         return false;
        }
      double equity=AccountInfoDouble(ACCOUNT_EQUITY);
      double balance=AccountInfoDouble(ACCOUNT_BALANCE);
      if(equity<=0.0 || balance<=0.0)
        {
         reason="Account equity or balance is unavailable.";
         return false;
        }
      double peak=state.GetNumber("equity_peak",equity);
      if(equity>peak)
        {
         peak=equity;
         state.SetNumber("equity_peak",peak);
        }
      if(m_limits.max_equity_drawdown_pct>0.0 &&
         equity<=peak*(1.0-m_limits.max_equity_drawdown_pct/100.0))
        {
         state.SetRiskLocked(true);
         reason="Maximum equity drawdown reached; persistent risk lock activated.";
         return false;
        }
      if(!HistorySelect(DayStart(),TimeCurrent()))
        {
         reason="Could not reconcile today's deal history.";
         return false;
        }
      double daily_net=0.0;
      for(int i=0;i<HistoryDealsTotal();i++)
        {
         ulong deal=HistoryDealGetTicket(i);
         if(deal==0 || HistoryDealGetString(deal,DEAL_SYMBOL)!=symbol ||
            HistoryDealGetInteger(deal,DEAL_MAGIC)!=m_limits.magic) continue;
         daily_net+=HistoryDealGetDouble(deal,DEAL_PROFIT)+
                    HistoryDealGetDouble(deal,DEAL_COMMISSION)+
                    HistoryDealGetDouble(deal,DEAL_SWAP)+
                    HistoryDealGetDouble(deal,DEAL_FEE);
        }
      double daily_limit=balance*m_limits.max_daily_loss_pct/100.0;
      if(m_limits.max_daily_loss_pct>0.0 && daily_net<=-daily_limit)
        {
         state.SetRiskLocked(true);
         reason="Maximum daily loss reached; persistent risk lock activated.";
         return false;
        }
      return true;
     }

   bool CheckAndSize(const string symbol,const double spread_points,
                     const ENUM_XH_DIRECTION direction,XHTradePlan &plan,
                     XHStateManager &state,string &reason)
     {
      reason="";
      if(!plan.valid) { reason="Trade plan is invalid."; return false; }
      if(state.RiskLocked()) { reason="Persistent risk lock is active."; return false; }
      if(!SessionAllowed()) { reason="Current UTC time is outside the configured session."; return false; }
      if(spread_points>m_limits.max_spread_points) { reason="Spread limit exceeded."; return false; }
      long trade_mode=SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE);
      if(trade_mode==SYMBOL_TRADE_MODE_DISABLED || trade_mode==SYMBOL_TRADE_MODE_CLOSEONLY)
        { reason="Symbol trade mode does not permit new entries."; return false; }
      if(direction==XH_BUY && trade_mode==SYMBOL_TRADE_MODE_SHORTONLY)
        { reason="Symbol is configured as short-only."; return false; }
      if(direction==XH_SELL && trade_mode==SYMBOL_TRADE_MODE_LONGONLY)
        { reason="Symbol is configured as long-only."; return false; }

      double equity=AccountInfoDouble(ACCOUNT_EQUITY);
      double balance=AccountInfoDouble(ACCOUNT_BALANCE);
      if(equity<=0.0 || balance<=0.0) { reason="Account equity or balance is invalid."; return false; }
      double peak=state.GetNumber("equity_peak",equity);
      if(equity>peak)
        {
         peak=equity;
         state.SetNumber("equity_peak",peak);
        }
      if(m_limits.max_equity_drawdown_pct>0.0 &&
         equity<=peak*(1.0-m_limits.max_equity_drawdown_pct/100.0))
        {
         state.SetRiskLocked(true);
         reason="Maximum equity drawdown reached; persistent risk lock activated.";
         return false;
        }

      double daily_net=0.0;
      int daily_entries=0,loss_streak=0;
      if(!DailyHistory(symbol,daily_net,daily_entries,loss_streak))
        { reason="Daily history could not be reconciled; new entries are rejected."; return false; }
      double daily_loss_limit=balance*m_limits.max_daily_loss_pct/100.0;
      if(m_limits.max_daily_loss_pct>0.0 && daily_net<=-daily_loss_limit)
        {
         state.SetRiskLocked(true);
         reason="Maximum daily loss reached; persistent risk lock activated.";
         return false;
        }
      if(daily_entries>=m_limits.max_daily_trades)
        { reason="Maximum daily trade count reached."; return false; }
      if(loss_streak>=m_limits.max_consecutive_losses)
        { reason="Maximum consecutive loss count reached."; return false; }

      int positions=0;
      double open_risk=0.0;
      if(!OpenPositions(symbol,positions,open_risk,reason)) return false;
      if(positions>=m_limits.max_open_positions)
        { reason="Maximum open-position count reached."; return false; }
      double risk_budget=equity*m_limits.risk_per_trade_pct/100.0;
      double total_risk_limit=equity*m_limits.max_total_open_risk_pct/100.0;
      if(risk_budget<=0.0 || m_limits.risk_per_trade_pct<=0.0)
        { reason="Risk-per-trade setting is invalid."; return false; }
      if(m_limits.commission_per_lot_round_turn<0.0 || m_limits.slippage_allowance_points<0.0)
        { reason="Commission or slippage allowance cannot be negative."; return false; }

      ENUM_ORDER_TYPE order_type=(direction==XH_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      double one_lot_loss=0.0;
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      double slip=m_limits.slippage_allowance_points*point;
      double risk_entry=(direction==XH_BUY ? plan.preferred_entry+slip : plan.preferred_entry-slip);
      double risk_stop=(direction==XH_BUY ? plan.stop_loss-slip : plan.stop_loss+slip);
      if(!OrderCalcProfit(order_type,symbol,1.0,risk_entry,risk_stop,one_lot_loss))
        { reason="Broker profit calculation failed for the planned stop distance."; return false; }
      one_lot_loss=MathAbs(one_lot_loss)+m_limits.commission_per_lot_round_turn;
      if(one_lot_loss<=0.0)
        { reason="Calculated one-lot risk is zero."; return false; }
      double minimum=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
      double maximum=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MAX);
      double step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
      if(minimum<=0.0 || maximum<minimum || step<=0.0)
        { reason="Broker volume specifications are invalid."; return false; }
      double raw_volume=risk_budget/one_lot_loss;
      double volume=MathFloor(raw_volume/step+1e-10)*step;
      volume=NormalizeDouble(volume,VolumeDigits(step));
      if(volume<minimum)
        { reason="Broker minimum lot would exceed the configured monetary risk."; return false; }
      volume=MathMin(volume,maximum);
      double planned_risk=one_lot_loss*volume;
      if(planned_risk>risk_budget+0.01)
        { reason="Rounded lot size exceeds the configured monetary risk."; return false; }
      if(open_risk+planned_risk>total_risk_limit+0.01)
        { reason="Maximum combined open risk would be exceeded."; return false; }

      double required_margin=0.0;
      if(!OrderCalcMargin(order_type,symbol,volume,plan.preferred_entry,required_margin))
        { reason="Broker margin calculation failed."; return false; }
      if(required_margin>AccountInfoDouble(ACCOUNT_MARGIN_FREE))
        { reason="Insufficient free margin for the planned volume."; return false; }
      plan.volume=volume;
      plan.estimated_risk_money=planned_risk;
      return true;
     }

   bool ActualFillRisk(const string symbol,const ENUM_XH_DIRECTION direction,
                      const double volume,const double fill_price,const double stop_loss,
                      double &risk_money,string &reason)
     {
      risk_money=0.0;
      reason="";
      if(volume<=0.0 || fill_price<=0.0 || stop_loss<=0.0)
        { reason="Broker fill or stop value is invalid."; return false; }
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      double slip=m_limits.slippage_allowance_points*point;
      double adverse_stop=(direction==XH_BUY ? stop_loss-slip : stop_loss+slip);
      ENUM_ORDER_TYPE order_type=(direction==XH_BUY ? ORDER_TYPE_BUY : ORDER_TYPE_SELL);
      double profit=0.0;
      if(!OrderCalcProfit(order_type,symbol,volume,fill_price,adverse_stop,profit))
        { reason="Could not calculate monetary risk from the actual broker fill."; return false; }
      risk_money=MathAbs(profit)+m_limits.commission_per_lot_round_turn*volume;
      return true;
     }
  };

#endif
