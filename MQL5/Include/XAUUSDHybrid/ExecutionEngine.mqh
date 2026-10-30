#ifndef XAUUSD_HYBRID_EXECUTION_ENGINE_MQH
#define XAUUSD_HYBRID_EXECUTION_ENGINE_MQH

#include <Trade/Trade.mqh>
#include "CoreTypes.mqh"
#include "RiskManager.mqh"
#include "StateManager.mqh"
#include "TradeLogger.mqh"

class XHExecutionEngine
  {
private:
   CTrade m_trade;
   long m_magic;
   ulong m_deviation;
   ENUM_XH_EXECUTION_STATE m_state;

   bool SymbolAllows(const string symbol,const ENUM_XH_DIRECTION direction)
     {
      long mode=SymbolInfoInteger(symbol,SYMBOL_TRADE_MODE);
      if(mode==SYMBOL_TRADE_MODE_DISABLED || mode==SYMBOL_TRADE_MODE_CLOSEONLY) return false;
      if(direction==XH_BUY && mode==SYMBOL_TRADE_MODE_SHORTONLY) return false;
      if(direction==XH_SELL && mode==SYMBOL_TRADE_MODE_LONGONLY) return false;
      return true;
     }

   bool RetcodeAccepted(const uint code)
     {
      return (code==TRADE_RETCODE_DONE ||
              code==TRADE_RETCODE_DONE_PARTIAL ||
              code==TRADE_RETCODE_PLACED);
     }

   void SaveTargets(const string symbol,const XHTradePlan &plan,const ulong deal,
                    XHStateManager &state)
     {
      if(deal==0 || !HistoryDealSelect(deal)) return;
      long position_id=HistoryDealGetInteger(deal,DEAL_POSITION_ID);
      if(position_id<=0) return;
      for(int i=0;i<PositionsTotal();i++)
        {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
         if(PositionGetString(POSITION_SYMBOL)!=symbol ||
            PositionGetInteger(POSITION_MAGIC)!=m_magic ||
            PositionGetInteger(POSITION_IDENTIFIER)!=position_id) continue;
         state.SaveTarget(ticket,1,plan.tp1);
         state.SaveTarget(ticket,2,plan.tp2);
         state.SaveTarget(ticket,3,plan.tp3);
         state.SaveTarget(ticket,0,plan.stop_loss);
        }
     }

public:
   XHExecutionEngine()
     {
      m_magic=5103001;
      m_deviation=30;
      m_state=XH_EXEC_IDLE;
     }

   void Configure(const long magic,const ulong deviation_points)
     {
      m_magic=magic;
      m_deviation=deviation_points;
      m_trade.SetExpertMagicNumber((ulong)m_magic);
      m_trade.SetDeviationInPoints(m_deviation);
      m_trade.SetAsyncMode(false);
     }

   ENUM_XH_EXECUTION_STATE State() const { return m_state; }

   bool ExecuteEntry(const string symbol,const XHSignalDecision &signal,
                     XHTradePlan &plan,const bool bot_enabled,
                     const bool trading_permission,const bool live_execution,
                     XHRiskManager &risk,XHStateManager &state,XHTradeLogger &logger,
                     string &reason)
     {
      reason="";
      m_state=XH_EXEC_IDLE;
      if(!bot_enabled) { reason="Bot is stopped; new entries are disabled."; return false; }
      if(!trading_permission || !live_execution)
        {
         reason="Execution denied: TRADING_PERMISSION and LIVE_EXECUTION are both required.";
         return false;
        }
      if(!TerminalInfoInteger(TERMINAL_CONNECTED) ||
         !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ||
         !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) ||
         !MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         reason="Terminal, account, or EA trading permission is unavailable.";
         m_state=XH_EXEC_ERROR;
         return false;
        }
      if(!signal.valid || signal.source_candle_time<=0 ||
         TimeCurrent()-signal.source_candle_time>PeriodSeconds(PERIOD_M30)*3)
        {
         reason="Signal is invalid or stale.";
         return false;
        }
      if(!plan.valid || plan.direction!=signal.direction)
        {
         reason="Trade plan is invalid or direction does not match the signal.";
         return false;
        }
      if(!SymbolAllows(symbol,signal.direction))
        {
         reason="Broker symbol mode does not permit this order direction.";
         return false;
        }
      if(state.SignalSeen(signal.signal_id) || state.EntryPending(signal.signal_id))
        {
         reason="Duplicate or pending signal id.";
         return false;
        }
      MqlTick tick;
      if(!SymbolInfoTick(symbol,tick))
        {
         reason="No current broker tick.";
         return false;
        }
      double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
      double current=(signal.direction==XH_BUY ? tick.ask : tick.bid);
      if(current<plan.entry_zone_low-point || current>plan.entry_zone_high+point)
        {
         reason="Current broker price moved outside the approved entry zone.";
         return false;
        }
      double stop_level=(double)SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL)*point;
      if(signal.direction==XH_BUY &&
         (plan.stop_loss>=current || plan.tp3<=current ||
          current-plan.stop_loss<stop_level || plan.tp3-current<stop_level))
        {
         reason="BUY entry, stop, or final target violates current price or broker stop constraints.";
         return false;
        }
      if(signal.direction==XH_SELL &&
         (plan.stop_loss<=current || plan.tp3>=current ||
          plan.stop_loss-current<stop_level || current-plan.tp3<stop_level))
        {
         reason="SELL entry, stop, or final target violates current price or broker stop constraints.";
         return false;
        }
      double spread=(tick.ask-tick.bid)/point;
      plan.preferred_entry=current;
      if(!risk.CheckAndSize(symbol,spread,signal.direction,plan,state,reason))
        {
         logger.LogRisk(symbol,signal.signal_id,false,reason,plan);
         return false;
        }
      if(plan.volume<=0.0)
        {
         reason="Risk manager returned a non-positive lot size.";
         return false;
        }

      m_state=XH_EXEC_PROCESSING;
      m_trade.SetExpertMagicNumber((ulong)m_magic);
      m_trade.SetDeviationInPoints(m_deviation);
      if(!m_trade.SetTypeFillingBySymbol(symbol))
        {
         reason="Could not select a broker-supported order filling mode.";
         m_state=XH_EXEC_ERROR;
         logger.LogRisk(symbol,signal.signal_id,false,reason,plan);
         return false;
        }
      state.SetEntryPending(signal.signal_id,true);
      logger.LogRisk(symbol,signal.signal_id,true,"All entry, market, and exposure checks passed.",plan);
      bool request_sent=false;
      if(signal.direction==XH_BUY)
         request_sent=m_trade.Buy(plan.volume,symbol,0.0,plan.stop_loss,plan.tp3,
                                  StringSubstr(signal.signal_id,0,30));
      else
         request_sent=m_trade.Sell(plan.volume,symbol,0.0,plan.stop_loss,plan.tp3,
                                   StringSubstr(signal.signal_id,0,30));
      uint retcode=m_trade.ResultRetcode();
      bool accepted=(request_sent && RetcodeAccepted(retcode));
      if(accepted)
        {
         state.MarkSignalSeen(signal.signal_id);
        }
      state.SetEntryPending(signal.signal_id,false);
      if(accepted && (retcode==TRADE_RETCODE_DONE || retcode==TRADE_RETCODE_DONE_PARTIAL))
        {
         double fill_price=m_trade.ResultPrice();
         double fill_volume=m_trade.ResultVolume();
         double actual_risk=0.0;
         string fill_risk_reason="";
         if(!risk.ActualFillRisk(symbol,signal.direction,fill_volume,fill_price,
                                 plan.stop_loss,actual_risk,fill_risk_reason) ||
            actual_risk>plan.estimated_risk_money+0.01)
           {
            state.SetRiskLocked(true);
            string close_reason="Post-fill monetary risk exceeded the plan. "+
                                fill_risk_reason+" risk="+DoubleToString(actual_risk,2)+
                                " plan="+DoubleToString(plan.estimated_risk_money,2);
            bool close_sent=false;
            ulong position_id=0;
            ulong deal=m_trade.ResultDeal();
            if(deal>0 && HistoryDealSelect(deal))
               position_id=(ulong)HistoryDealGetInteger(deal,DEAL_POSITION_ID);
            for(int i=0;i<PositionsTotal();i++)
              {
               ulong ticket=PositionGetTicket(i);
               if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
               if(PositionGetString(POSITION_SYMBOL)!=symbol ||
                  PositionGetInteger(POSITION_MAGIC)!=m_magic ||
                  (position_id>0 && (ulong)PositionGetInteger(POSITION_IDENTIFIER)!=position_id))
                  continue;
               close_sent=m_trade.PositionClose(ticket);
               break;
              }
            logger.Log("POST_FILL_RISK_BREACH",symbol,signal.signal_id,
                       close_reason+";emergency_close_sent="+(close_sent ? "true" : "false")+
                       ";retcode="+IntegerToString((long)m_trade.ResultRetcode())+
                       ";description="+m_trade.ResultRetcodeDescription());
            reason=close_reason;
            m_state=XH_EXEC_ERROR;
            return false;
           }
         SaveTargets(symbol,plan,m_trade.ResultDeal(),state);
        }
      logger.LogOrder(symbol,signal.signal_id,accepted,retcode,
                      m_trade.ResultRetcodeDescription(),m_trade.ResultPrice(),
                      m_trade.ResultVolume());
      if(!accepted)
        {
         reason="Broker rejected or did not confirm the order: "+m_trade.ResultRetcodeDescription();
         m_state=XH_EXEC_ERROR;
         return false;
        }
      reason=(retcode==TRADE_RETCODE_PLACED ?
              "Order accepted as placed; broker fill is not yet confirmed." :
              "Broker acknowledged the order; fill details are recorded separately.");
      m_state=XH_EXEC_IDLE;
      return true;
     }

   bool ApplyManagement(const string symbol,const XHManagementCommand &command,
                        const bool trading_permission,const bool live_execution,
                        XHStateManager &state,XHTradeLogger &logger,string &reason)
     {
      reason="";
      if(!command.valid) return false;
      if(!trading_permission || !live_execution)
        {
         reason="Position modification is disabled; broker-side SL/TP protection remains in place.";
         return false;
        }
      if(!TerminalInfoInteger(TERMINAL_CONNECTED) ||
         !TerminalInfoInteger(TERMINAL_TRADE_ALLOWED) ||
         !AccountInfoInteger(ACCOUNT_TRADE_ALLOWED) ||
         !MQLInfoInteger(MQL_TRADE_ALLOWED))
        {
         reason="Position management is blocked by terminal or account trading permissions.";
         return false;
        }
      if(!PositionSelectByTicket(command.ticket))
        {
         reason="Position ticket is no longer open.";
         return false;
        }
      if(PositionGetString(POSITION_SYMBOL)!=symbol ||
         PositionGetInteger(POSITION_MAGIC)!=m_magic)
        {
         reason="Position ownership validation failed.";
         return false;
        }
      m_trade.SetExpertMagicNumber((ulong)m_magic);
      m_trade.SetDeviationInPoints(m_deviation);
      bool sent=false;
      if(command.kind==XH_MANAGE_MODIFY)
        {
         double old_sl=PositionGetDouble(POSITION_SL);
         double new_sl=command.stop_loss;
         double tp=(command.take_profit>0.0 ? command.take_profit : PositionGetDouble(POSITION_TP));
         ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         double point=SymbolInfoDouble(symbol,SYMBOL_POINT);
         double current=(type==POSITION_TYPE_BUY ? SymbolInfoDouble(symbol,SYMBOL_BID)
                                                  : SymbolInfoDouble(symbol,SYMBOL_ASK));
         double stop_points=(double)SymbolInfoInteger(symbol,SYMBOL_TRADE_STOPS_LEVEL);
         double freeze_points=(double)SymbolInfoInteger(symbol,SYMBOL_TRADE_FREEZE_LEVEL);
         double min_distance=MathMax(stop_points,freeze_points)*point;
         bool improves=(type==POSITION_TYPE_BUY ? (old_sl<=0.0 || new_sl>old_sl)
                                                : (old_sl<=0.0 || new_sl<old_sl));
         bool valid_distance=(type==POSITION_TYPE_BUY ? current-new_sl>=min_distance
                                                      : new_sl-current>=min_distance);
         if(new_sl<=0.0 || !improves || !valid_distance)
           {
            reason="Stop modification is invalid or would loosen existing protection.";
            return false;
           }
         sent=m_trade.PositionModify(command.ticket,new_sl,tp);
        }
      else if(command.kind==XH_MANAGE_PARTIAL_CLOSE)
        {
         double step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
         double minimum=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
         double volume=MathFloor(command.volume/step+1e-10)*step;
         if(volume<minimum || volume>=PositionGetDouble(POSITION_VOLUME))
           {
            reason="Partial-close volume violates broker volume constraints.";
            return false;
           }
         sent=m_trade.PositionClosePartial(command.ticket,volume);
        }
      else if(command.kind==XH_MANAGE_CLOSE)
         sent=m_trade.PositionClose(command.ticket);
      else
        {
         reason="Unknown position-management command.";
         return false;
        }
      uint retcode=m_trade.ResultRetcode();
      bool accepted=(sent && RetcodeAccepted(retcode));
      logger.LogPosition(symbol,command.ticket,
                         accepted ? "POSITION_COMMAND_ACCEPTED" : "POSITION_COMMAND_REJECTED",
                         m_trade.ResultVolume(),m_trade.ResultPrice(),
                         command.reason+";retcode="+IntegerToString((long)retcode)+
                         ";description="+m_trade.ResultRetcodeDescription());
      if(!accepted)
        {
         reason="Broker rejected position command: "+m_trade.ResultRetcodeDescription();
         return false;
        }
      if(command.kind==XH_MANAGE_PARTIAL_CLOSE)
        {
         int stage=(int)StringToInteger(command.reason);
         if(stage>0) state.MarkPartialStageDone(command.ticket,stage);
        }
      return true;
     }
  };

#endif
