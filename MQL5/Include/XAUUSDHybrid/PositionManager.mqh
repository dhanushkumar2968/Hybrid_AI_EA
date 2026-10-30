#ifndef XAUUSD_HYBRID_POSITION_MANAGER_MQH
#define XAUUSD_HYBRID_POSITION_MANAGER_MQH

#include "CoreTypes.mqh"
#include "MarketData.mqh"
#include "StateManager.mqh"

class XHPositionManager
  {
private:
   long m_magic;
   double m_tp1_partial_percent;
   double m_tp2_partial_percent;
   double m_break_even_rr;
   double m_trailing_start_rr;
   double m_trailing_atr;
   int m_max_holding_seconds;
   bool m_emergency_close_missing_stop;

   double PartialVolume(const string symbol,const double position_volume,const double percent)
     {
      double step=SymbolInfoDouble(symbol,SYMBOL_VOLUME_STEP);
      double minimum=SymbolInfoDouble(symbol,SYMBOL_VOLUME_MIN);
      if(step<=0.0 || minimum<=0.0) return 0.0;
      double close_volume=MathFloor((position_volume*percent/100.0)/step+1e-10)*step;
      close_volume=NormalizeDouble(close_volume,8);
      if(close_volume<minimum || position_volume-close_volume<minimum) return 0.0;
      return close_volume;
     }

   void SetCommand(XHManagementCommand &command,const ulong ticket,const int kind,
                   const double volume,const double sl,const double tp,const string reason)
     {
      command.valid=true;
      command.ticket=ticket;
      command.kind=kind;
      command.volume=volume;
      command.stop_loss=sl;
      command.take_profit=tp;
      command.reason=reason;
     }

public:
   XHPositionManager()
     {
      m_magic=5103001;
      m_tp1_partial_percent=0.0;
      m_tp2_partial_percent=0.0;
      m_break_even_rr=0.0;
      m_trailing_start_rr=0.0;
      m_trailing_atr=1.0;
      m_max_holding_seconds=0;
      m_emergency_close_missing_stop=false;
     }

   void Configure(const long magic,const double tp1_partial_percent,
                  const double tp2_partial_percent,const double break_even_rr,
                  const double trailing_start_rr,const double trailing_atr,
                  const int max_holding_seconds,const bool emergency_close_missing_stop)
     {
      m_magic=magic;
      m_tp1_partial_percent=MathMax(0.0,MathMin(tp1_partial_percent,90.0));
      m_tp2_partial_percent=MathMax(0.0,MathMin(tp2_partial_percent,90.0));
      m_break_even_rr=MathMax(0.0,break_even_rr);
      m_trailing_start_rr=MathMax(0.0,trailing_start_rr);
      m_trailing_atr=MathMax(0.1,trailing_atr);
      m_max_holding_seconds=MathMax(0,max_holding_seconds);
      m_emergency_close_missing_stop=emergency_close_missing_stop;
     }

   bool NextCommand(const string symbol,XHMarketData &market,XHStateManager &state,
                    XHManagementCommand &command,string &status)
     {
      command.valid=false;
      status="";
      MqlTick tick;
      if(!market.CurrentTick(tick)) return false;
      double atr=0.0;
      market.ATR(PERIOD_M30,14,atr);
      datetime now=TimeCurrent();
      for(int i=0;i<PositionsTotal();i++)
        {
         ulong ticket=PositionGetTicket(i);
         if(ticket==0 || !PositionSelectByTicket(ticket)) continue;
         if(PositionGetString(POSITION_SYMBOL)!=symbol ||
            PositionGetInteger(POSITION_MAGIC)!=m_magic) continue;
         double volume=PositionGetDouble(POSITION_VOLUME);
         double open=PositionGetDouble(POSITION_PRICE_OPEN);
         double stop=PositionGetDouble(POSITION_SL);
         double take=PositionGetDouble(POSITION_TP);
         ENUM_POSITION_TYPE type=(ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
         if(stop<=0.0)
           {
            state.SetRiskLocked(true);
            status="EA position "+IntegerToString((long)ticket)+" has no protective stop; entry risk is locked.";
            if(m_emergency_close_missing_stop)
              {
               SetCommand(command,ticket,XH_MANAGE_CLOSE,0.0,0.0,0.0,"Emergency close: missing protective stop.");
               return true;
              }
            continue;
           }
         double current=(type==POSITION_TYPE_BUY ? tick.bid : tick.ask);
         double initial_stop=state.LoadTarget(ticket,0);
         if(initial_stop<=0.0) initial_stop=stop;
         double initial_risk=MathAbs(open-initial_stop);
         double favorable=(type==POSITION_TYPE_BUY ? current-open : open-current);
         double rr=(initial_risk>0.0 ? favorable/initial_risk : 0.0);

         if(m_max_holding_seconds>0)
           {
            datetime opened=(datetime)PositionGetInteger(POSITION_TIME);
            if(opened>0 && now-opened>=m_max_holding_seconds)
              {
               SetCommand(command,ticket,XH_MANAGE_CLOSE,0.0,0.0,0.0,"Maximum holding time reached.");
               return true;
              }
           }

         double target1=state.LoadTarget(ticket,1);
         if(m_tp1_partial_percent>0.0 && target1>0.0 &&
            !state.PartialStageDone(ticket,1) &&
            ((type==POSITION_TYPE_BUY && current>=target1) ||
             (type==POSITION_TYPE_SELL && current<=target1)))
           {
            double partial=PartialVolume(symbol,volume,m_tp1_partial_percent);
            if(partial>0.0)
              {
               SetCommand(command,ticket,XH_MANAGE_PARTIAL_CLOSE,partial,0.0,0.0,"1");
               return true;
              }
           }
         double target2=state.LoadTarget(ticket,2);
         if(m_tp2_partial_percent>0.0 && target2>0.0 &&
            !state.PartialStageDone(ticket,2) &&
            ((type==POSITION_TYPE_BUY && current>=target2) ||
             (type==POSITION_TYPE_SELL && current<=target2)))
           {
            double partial=PartialVolume(symbol,volume,m_tp2_partial_percent);
            if(partial>0.0)
              {
               SetCommand(command,ticket,XH_MANAGE_PARTIAL_CLOSE,partial,0.0,0.0,"2");
               return true;
              }
           }

         if(m_break_even_rr>0.0 && rr>=m_break_even_rr)
           {
            bool needs_be=(type==POSITION_TYPE_BUY ? stop<open : stop>open);
            if(needs_be)
              {
               SetCommand(command,ticket,XH_MANAGE_MODIFY,0.0,open,take,"Break-even stop.");
               return true;
              }
           }
         if(m_trailing_start_rr>0.0 && atr>0.0 && rr>=m_trailing_start_rr)
           {
            double candidate=(type==POSITION_TYPE_BUY ? current-atr*m_trailing_atr
                                                       : current+atr*m_trailing_atr);
            if(type==POSITION_TYPE_BUY)
              {
               candidate=MathMax(candidate,open);
               if(candidate>stop && candidate<current)
                 {
                  SetCommand(command,ticket,XH_MANAGE_MODIFY,0.0,candidate,take,"ATR trailing stop.");
                  return true;
                 }
              }
            else
              {
               candidate=MathMin(candidate,open);
               if(candidate<stop && candidate>current)
                 {
                  SetCommand(command,ticket,XH_MANAGE_MODIFY,0.0,candidate,take,"ATR trailing stop.");
                  return true;
                 }
              }
           }
        }
      return false;
     }
  };

#endif
