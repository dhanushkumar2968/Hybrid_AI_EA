#ifndef XAUUSD_HYBRID_STRATEGY_MODULE_BASE_MQH
#define XAUUSD_HYBRID_STRATEGY_MODULE_BASE_MQH

#include "CoreTypes.mqh"

void XHInitStrategy(XHStrategyResult &result,const string name,const int group,
                   const datetime signal_time,const bool enabled)
  {
   result.name=name;
   result.enabled=enabled;
   result.buy_points=0.0;
   result.sell_points=0.0;
   result.max_points=1.0;
   result.buy_confirmed=false;
   result.sell_confirmed=false;
   result.relevant_price=0.0;
   result.zone_high=0.0;
   result.zone_low=0.0;
   result.signal_time=signal_time;
   result.invalidation=0.0;
   result.correlation_group=group;
   result.reason="No qualifying evidence on completed candles.";
  }

void XHStrategyBuy(XHStrategyResult &result,const MqlRates &bar,const double relevant,
                  const double zone_high,const double zone_low,const double invalidation,
                  const string reason)
  {
   result.buy_points=1.0;
   result.buy_confirmed=true;
   result.relevant_price=relevant;
   result.zone_high=zone_high;
   result.zone_low=zone_low;
   result.invalidation=invalidation;
   result.signal_time=bar.time;
   result.reason=reason;
  }

void XHStrategySell(XHStrategyResult &result,const MqlRates &bar,const double relevant,
                   const double zone_high,const double zone_low,const double invalidation,
                   const string reason)
  {
   result.sell_points=1.0;
   result.sell_confirmed=true;
   result.relevant_price=relevant;
   result.zone_high=zone_high;
   result.zone_low=zone_low;
   result.invalidation=invalidation;
   result.signal_time=bar.time;
   result.reason=reason;
  }

#endif
