#ifndef XAUUSD_HYBRID_AI_CLIENT_MQH
#define XAUUSD_HYBRID_AI_CLIENT_MQH

#include "CoreTypes.mqh"
#include "FeatureBuilder.mqh"

class XHAIClient
  {
private:
   string m_url;
   int m_timeout_ms;
   string m_expected_model_version;
   string m_service_model_version;
   uint m_sequence;

   string FormatISO(const datetime utc_time)
     {
      string value=TimeToString(utc_time,TIME_DATE|TIME_SECONDS);
      StringReplace(value,".","-");
      StringReplace(value," ","T");
      return value+"Z";
     }

   string TimestampServerISO(const datetime server_time)
     {
      int offset=(int)(TimeCurrent()-TimeGMT());
      return FormatISO(server_time-offset);
     }

   string JsonString(const string json,const string key)
     {
      string token="\""+key+"\"";
      int start=StringFind(json,token);
      if(start<0) return "";
      int colon=StringFind(json,":",start+StringLen(token));
      if(colon<0) return "";
      int quote=StringFind(json,"\"",colon+1);
      if(quote<0) return "";
      int end=StringFind(json,"\"",quote+1);
      if(end<0) return "";
      return StringSubstr(json,quote+1,end-quote-1);
     }

   string EndpointRoot()
     {
      int scheme=StringFind(m_url,"://");
      if(scheme<0) return "";
      int path=StringFind(m_url,"/",scheme+3);
      if(path<0) return m_url;
      return StringSubstr(m_url,0,path);
     }

   bool GetJson(const string url,string &body,string &reason)
     {
      char data[];
      ArrayResize(data,0);
      char result[];
      string result_headers="";
      ResetLastError();
      int status=WebRequest("GET",url,"",m_timeout_ms,data,result,result_headers);
      if(status<0)
        {
         reason="AI health request failed; check the local service and MT5 WebRequest allowlist. error="+
                IntegerToString(GetLastError());
         return false;
        }
      if(status!=200)
        {
         reason="AI health endpoint returned HTTP "+IntegerToString(status)+".";
         return false;
        }
      body=CharArrayToString(result,0,-1,CP_UTF8);
      return true;
     }

   bool CheckService(string &reason)
     {
      reason="";
      string root=EndpointRoot();
      if(root=="")
        {
         reason="AI endpoint URL is invalid.";
         return false;
        }
      string health="";
      if(!GetJson(root+"/health",health,reason)) return false;
      if(JsonString(health,"status")!="ok" ||
         JsonString(health,"schema_version")!=XH_API_SCHEMA)
        {
         reason="AI health response failed schema or readiness validation.";
         return false;
        }
      string info="";
      if(!GetJson(root+"/model/info",info,reason)) return false;
      if(JsonString(info,"schema_version")!=XH_API_SCHEMA ||
         JsonString(info,"feature_schema_version")!=XH_FEATURE_SCHEMA ||
         StringFind(info,"\"model_ready\":true")<0)
        {
         reason="AI model is not ready or its feature schema is incompatible.";
         return false;
        }
      m_service_model_version=JsonString(info,"model_version");
      if(m_service_model_version=="" ||
         (StringLen(m_expected_model_version)>0 &&
          m_service_model_version!=m_expected_model_version))
        {
         reason="AI model version is unavailable or does not match the configured version.";
         return false;
        }
      return true;
     }

   bool MockResponse(const string request_id,const XHFeatureVector &features,
                     XHAIResponse &response)
     {
      double score=0.30*features.trend_direction+
                   0.25*features.structure_break+
                   0.20*features.liquidity_sweep+
                   0.15*features.momentum+
                   0.10*(2.0*features.mtf_alignment-1.0);
      response.prediction_class="NO_TRADE";
      if(score>0.20) response.prediction_class="BUY_SETUP";
      else if(score< -0.20) response.prediction_class="SELL_SETUP";
      response.valid=true;
      response.mock=true;
      response.request_id=request_id;
      response.model_name="deterministic_mock";
      response.model_version="mock-v1";
      response.feature_schema_version=XH_FEATURE_SCHEMA;
      response.warning="Deterministic mock response; not a trained model.";
      response.inference_ms=0.0;
      return true;
     }

public:
   XHAIClient()
     {
      m_url="http://127.0.0.1:8765/v1/analyze";
      m_timeout_ms=1500;
      m_expected_model_version="";
      m_service_model_version="";
      m_sequence=0;
     }

   void Configure(const string url,const int timeout_ms,const string expected_model_version)
     {
      if(StringFind(url,"http://127.0.0.1:")==0 ||
         StringFind(url,"https://127.0.0.1:")==0)
         m_url=url;
      else
        {
         m_url="http://127.0.0.1:8765/v1/analyze";
         Print("XH: AI endpoint must use the local 127.0.0.1 address; default endpoint selected.");
        }
      m_timeout_ms=(int)MathMax(250,MathMin(timeout_ms,10000));
      m_expected_model_version="";
      for(int i=0;i<StringLen(expected_model_version);i++)
        {
         ushort ch=StringGetCharacter(expected_model_version,i);
         bool allowed=((ch>='a' && ch<='z') || (ch>='A' && ch<='Z') ||
                       (ch>='0' && ch<='9') || ch=='-' || ch=='_' || ch=='.');
         if(!allowed)
           {
            Print("XH: Expected model version contains unsupported characters; version pin disabled.");
            return;
           }
        }
      m_expected_model_version=expected_model_version;
     }

   bool Analyze(const string symbol,const string timeframe,const datetime source_candle_time,
                const XHFeatureVector &features,const bool use_mock,XHAIResponse &response)
     {
      response.valid=false;
      response.mock=false;
      response.warning="AI unavailable.";
      response.request_id="";
      if(!features.valid)
        {
         response.warning="Feature vector is invalid.";
         return false;
        }
      m_sequence++;
      string request_id=IntegerToString((long)TimeGMT())+"-"+IntegerToString((long)m_sequence);
      response.request_id=request_id;
      if(use_mock)
         return MockResponse(request_id,features,response);
      if(MQLInfoInteger(MQL_TESTER))
        {
         response.warning="WebRequest is unavailable in the Strategy Tester; enable deterministic mock mode.";
         return false;
        }
      string service_reason="";
      if(!CheckService(service_reason))
        {
         response.warning=service_reason;
         return false;
        }

      string expected="null";
      if(StringLen(m_expected_model_version)>0)
         expected="\""+m_expected_model_version+"\"";
      string payload="{"+
         "\"schema_version\":\""+XH_API_SCHEMA+"\","+
         "\"request_id\":\""+request_id+"\","+
         "\"symbol\":\""+symbol+"\","+
         "\"timeframe\":\""+timeframe+"\","+
         "\"source_candle_timestamp\":\""+TimestampServerISO(source_candle_time)+"\","+
         "\"requested_at\":\""+FormatISO(TimeGMT())+"\","+
         "\"feature_schema_version\":\""+XH_FEATURE_SCHEMA+"\","+
         "\"expected_model_version\":"+expected+","+
         "\"features\":{"+
         "\"trend_direction\":"+DoubleToString(features.trend_direction,8)+","+
         "\"mtf_alignment\":"+DoubleToString(features.mtf_alignment,8)+","+
         "\"structure_break\":"+DoubleToString(features.structure_break,8)+","+
         "\"liquidity_sweep\":"+DoubleToString(features.liquidity_sweep,8)+","+
         "\"sr_distance_atr\":"+DoubleToString(features.sr_distance_atr,8)+","+
         "\"candle_body_atr\":"+DoubleToString(features.candle_body_atr,8)+","+
         "\"volatility_atr\":"+DoubleToString(features.volatility_atr,8)+","+
         "\"momentum\":"+DoubleToString(features.momentum,8)+","+
         "\"spread_atr\":"+DoubleToString(features.spread_atr,8)+","+
         "\"session_code\":"+DoubleToString(features.session_code,0)+
         "}}";

      char data[];
      int count=StringToCharArray(payload,data,0,WHOLE_ARRAY,CP_UTF8);
      if(count<=1)
        {
         response.warning="JSON request serialization failed.";
         return false;
        }
      ArrayResize(data,count-1);
      char result[];
      string result_headers="";
      ResetLastError();
      ulong started=GetMicrosecondCount();
      int status=WebRequest("POST",m_url,"Content-Type: application/json\r\n",
                            m_timeout_ms,data,result,result_headers);
      response.inference_ms=(double)(GetMicrosecondCount()-started)/1000.0;
      if(status<0)
        {
         response.warning="WebRequest failed; allowlist http://127.0.0.1:8765 in MT5 Options. error="+
                          IntegerToString(GetLastError());
         return false;
        }
      if(status!=200)
        {
         response.warning="AI service returned HTTP "+IntegerToString(status)+".";
         return false;
        }
      string body=CharArrayToString(result,0,-1,CP_UTF8);
      string schema=JsonString(body,"schema_version");
      string response_id=JsonString(body,"request_id");
      string model=JsonString(body,"model_name");
      string model_version=JsonString(body,"model_version");
      string feature_schema=JsonString(body,"feature_schema_version");
      string prediction=JsonString(body,"prediction_class");
      string response_symbol=JsonString(body,"symbol");
      string response_timeframe=JsonString(body,"timeframe");
      string response_timestamp=JsonString(body,"source_candle_timestamp");
      string sent_timestamp=TimestampServerISO(source_candle_time);
      if(schema!=XH_API_SCHEMA || response_id!=request_id ||
         feature_schema!=XH_FEATURE_SCHEMA || model_version=="" || prediction=="" ||
         response_symbol!=symbol || response_timeframe!=timeframe)
        {
         response.warning="AI response schema, request id, model version, or feature schema validation failed.";
         return false;
        }
      if(StringLen(m_expected_model_version)>0 && model_version!=m_expected_model_version)
        {
         response.warning="AI response model version does not match the configured version.";
         return false;
        }
      if(model_version!=m_service_model_version)
        {
         response.warning="AI response model version changed after the health check.";
         return false;
        }
      if(StringSubstr(response_timestamp,0,19)!=StringSubstr(sent_timestamp,0,19))
        {
         response.warning="AI response candle timestamp does not match the request.";
         return false;
        }
      if(prediction!="BUY_SETUP" && prediction!="SELL_SETUP" && prediction!="NO_TRADE")
        {
         response.warning="AI returned an unsupported prediction class.";
         return false;
        }
      if(StringFind(body,"MODEL_UNAVAILABLE")>=0 || StringFind(body,"INFERENCE_ERROR")>=0)
        {
         response.warning="AI service has no usable model; response rejected.";
         return false;
        }
      response.valid=true;
      response.mock=false;
      response.model_name=model;
      response.model_version=model_version;
      response.feature_schema_version=feature_schema;
      response.prediction_class=prediction;
      response.warning="";
      return true;
     }
  };

#endif
