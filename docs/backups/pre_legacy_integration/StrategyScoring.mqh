#ifndef XAUUSD_HYBRID_STRATEGY_SCORING_MQH
#define XAUUSD_HYBRID_STRATEGY_SCORING_MQH

#include "CoreTypes.mqh"

class XHStrategyScoring
  {
public:
   void Score(const XHStrategyResult &results[],XHAnalysisSnapshot &context)
     {
      double group_buy[5]={0.0,0.0,0.0,0.0,0.0};
      double group_sell[5]={0.0,0.0,0.0,0.0,0.0};
      double group_max[5]={0.0,0.0,0.0,0.0,0.0};
      context.enabled_strategy_count=0;
      context.buy_score=0.0;
      context.sell_score=0.0;
      context.score_denominator=0.0;
      for(int i=0;i<XH_STRATEGY_COUNT;i++)
        {
         if(!results[i].enabled) continue;
         context.enabled_strategy_count++;
         int group=results[i].correlation_group;
         if(group<0 || group>=5) continue;
         group_max[group]=MathMax(group_max[group],results[i].max_points);
         group_buy[group]=MathMax(group_buy[group],results[i].buy_points);
         group_sell[group]=MathMax(group_sell[group],results[i].sell_points);
        }
      for(int group=0;group<5;group++)
        {
         context.score_denominator+=group_max[group];
         context.buy_score+=group_buy[group];
         context.sell_score+=group_sell[group];
        }
      if(context.score_denominator>0.0)
        {
         context.buy_score=100.0*context.buy_score/context.score_denominator;
         context.sell_score=100.0*context.sell_score/context.score_denominator;
        }
     }
  };

#endif
