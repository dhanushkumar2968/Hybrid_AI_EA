#ifndef XAUUSD_HYBRID_TRADE_LOGGER_MQH
#define XAUUSD_HYBRID_TRADE_LOGGER_MQH

#include "CoreTypes.mqh"

class XHTradeLogger
  {
private:
   string m_file;
public:
   XHTradeLogger()
     {
      m_file="XAUUSD_Hybrid_AI_Audit.csv";
     }

   void Log(const string event,const string symbol,const string request_id,
            const string details)
     {
      ResetLastError();
      int handle=FileOpen(m_file,FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_SHARE_READ,';');
      if(handle==INVALID_HANDLE)
        {
         Print("XH: Audit log open failed, error=",GetLastError(),", event=",event);
         return;
        }
      if(FileSize(handle)==0)
         FileWrite(handle,"timestamp","event","symbol","request_id","details");
      FileSeek(handle,0,SEEK_END);
      FileWrite(handle,TimeToString(TimeCurrent(),TIME_DATE|TIME_SECONDS),event,symbol,request_id,details);
      FileFlush(handle);
      FileClose(handle);
     }

   void LogAnalysis(const XHAnalysisSnapshot &context,const XHStrategyResult &strategies[],
                    const XHAIResponse &ai,const XHSignalDecision &signal,
                    const XHTradePlan &plan,const string risk_reason)
     {
      string summary="state="+XHSignalStateName(signal.state)+
         ";direction="+XHDirectionName(signal.direction)+
         ";buy_score="+DoubleToString(context.buy_score,2)+
         ";sell_score="+DoubleToString(context.sell_score,2)+
         ";enabled="+IntegerToString(context.enabled_strategy_count)+
         ";ai="+ai.prediction_class+";model="+ai.model_version+
         ";plan="+(plan.valid ? "valid" : "rejected")+":"+plan.rejection_reason+
         ";risk="+risk_reason+";reason="+signal.explanation;
      Log("ANALYSIS",context.symbol,ai.request_id,summary);
      for(int i=0;i<XH_STRATEGY_COUNT;i++)
        {
         string details="enabled="+(strategies[i].enabled ? "true" : "false")+
            ";buy="+DoubleToString(strategies[i].buy_points,2)+
            ";sell="+DoubleToString(strategies[i].sell_points,2)+
            ";source_time="+TimeToString(strategies[i].signal_time,TIME_DATE|TIME_SECONDS)+
            ";price="+DoubleToString(strategies[i].relevant_price,_Digits)+
            ";zone_low="+DoubleToString(strategies[i].zone_low,_Digits)+
            ";zone_high="+DoubleToString(strategies[i].zone_high,_Digits)+
            ";invalidation="+DoubleToString(strategies[i].invalidation,_Digits)+
            ";reason="+strategies[i].reason;
         Log("STRATEGY:"+strategies[i].name,context.symbol,ai.request_id,details);
        }
     }

   void LogTradePlan(const string symbol,const string signal_id,const XHTradePlan &plan)
     {
      string details="valid="+(plan.valid ? "true" : "false")+
         ";direction="+XHDirectionName(plan.direction)+
         ";entry_low="+DoubleToString(plan.entry_zone_low,_Digits)+
         ";entry_high="+DoubleToString(plan.entry_zone_high,_Digits)+
         ";preferred="+DoubleToString(plan.preferred_entry,_Digits)+
         ";sl="+DoubleToString(plan.stop_loss,_Digits)+
         ";tp1="+DoubleToString(plan.tp1,_Digits)+
         ";tp2="+DoubleToString(plan.tp2,_Digits)+
         ";tp3="+DoubleToString(plan.tp3,_Digits)+
         ";volume="+DoubleToString(plan.volume,2)+
         ";risk="+DoubleToString(plan.estimated_risk_money,2)+
         ";reject="+plan.rejection_reason;
      Log("TRADE_PLAN",symbol,signal_id,details);
     }

   void LogRisk(const string symbol,const string signal_id,const bool approved,
                const string reason,const XHTradePlan &plan)
     {
      Log(approved ? "RISK_APPROVED" : "RISK_REJECTED",symbol,signal_id,
          reason+";volume="+DoubleToString(plan.volume,2)+
          ";estimated_risk="+DoubleToString(plan.estimated_risk_money,2));
     }

   void LogOrder(const string symbol,const string signal_id,const bool sent,
                 const uint retcode,const string description,const double fill_price,
                 const double fill_volume)
     {
      Log("ORDER",symbol,signal_id,
          "sent="+(sent ? "true" : "false")+
          ";retcode="+IntegerToString((long)retcode)+
          ";description="+description+
          ";fill_price="+DoubleToString(fill_price,_Digits)+
          ";fill_volume="+DoubleToString(fill_volume,2));
     }

   void LogPosition(const string symbol,const ulong ticket,const string event,
                    const double volume,const double price,const string details)
     {
      Log(event,symbol,IntegerToString((long)ticket),
          "volume="+DoubleToString(volume,2)+";price="+DoubleToString(price,_Digits)+";"+details);
     }
  };

#endif
