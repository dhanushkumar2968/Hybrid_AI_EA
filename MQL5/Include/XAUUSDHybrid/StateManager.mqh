#ifndef XAUUSD_HYBRID_STATE_MANAGER_MQH
#define XAUUSD_HYBRID_STATE_MANAGER_MQH

#include "CoreTypes.mqh"

class XHStateManager
  {
private:
   string m_prefix;

   ulong Hash(const string value)
     {
      ulong hash=2166136261;
      for(int i=0;i<StringLen(value);i++)
        {
         hash^=(ulong)StringGetCharacter(value,i);
         hash*=16777619;
        }
      return hash;
     }

   string Key(const string name)
     {
      return m_prefix+name;
     }

public:
   XHStateManager()
     {
      m_prefix="XH.";
     }

   void Configure(const long magic)
     {
      m_prefix="XH."+IntegerToString((long)AccountInfoInteger(ACCOUNT_LOGIN))+"."+
               IntegerToString(magic)+".";
     }

   bool SetNumber(const string name,const double value)
     {
      ResetLastError();
      if(GlobalVariableSet(Key(name),value)==0)
        {
         Print("XH: Failed to persist state ",name,", error=",GetLastError());
         return false;
        }
      return true;
     }

   double GetNumber(const string name,const double fallback)
     {
      string key=Key(name);
      if(!GlobalVariableCheck(key)) return fallback;
      return GlobalVariableGet(key);
     }

   bool RiskLocked()
     {
      return GetNumber("risk_lock",0.0)>0.5;
     }

   bool SetRiskLocked(const bool locked)
     {
      return SetNumber("risk_lock",locked ? 1.0 : 0.0);
     }

   bool SignalSeen(const string signal_id)
     {
      string suffix=StringFormat("%I64u",Hash(signal_id));
      return GlobalVariableCheck(Key("signal."+suffix));
     }

   bool MarkSignalSeen(const string signal_id)
     {
      string suffix=StringFormat("%I64u",Hash(signal_id));
      return SetNumber("signal."+suffix,(double)TimeCurrent());
     }

   bool PartialStageDone(const ulong ticket,const int stage)
     {
      string name="partial."+IntegerToString((long)ticket)+"."+IntegerToString(stage);
      return GetNumber(name,0.0)>0.5;
     }

   bool MarkPartialStageDone(const ulong ticket,const int stage)
     {
      string name="partial."+IntegerToString((long)ticket)+"."+IntegerToString(stage);
      return SetNumber(name,1.0);
     }

   bool MarkMissingStopReported(const ulong ticket)
     {
      string name="missing_stop."+IntegerToString((long)ticket);
      if(GetNumber(name,0.0)>0.5) return false;
      SetNumber(name,1.0);
      return true;
     }

   bool SaveTarget(const ulong ticket,const int target_index,const double price)
     {
      string name="target."+IntegerToString((long)ticket)+"."+IntegerToString(target_index);
      return SetNumber(name,price);
     }

   double LoadTarget(const ulong ticket,const int target_index)
     {
      string name="target."+IntegerToString((long)ticket)+"."+IntegerToString(target_index);
      return GetNumber(name,0.0);
     }

   bool EntryPending(const string signal_id)
     {
      string suffix=StringFormat("%I64u",Hash(signal_id));
      return GetNumber("pending."+suffix,0.0)>0.5;
     }

   bool SetEntryPending(const string signal_id,const bool pending)
     {
      string suffix=StringFormat("%I64u",Hash(signal_id));
      return SetNumber("pending."+suffix,pending ? 1.0 : 0.0);
     }
  };

#endif
