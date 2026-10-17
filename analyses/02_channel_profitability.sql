-- Are delivery-app orders worth it? Contribution per order by channel
-- after commission and ingredient cost (owned + franchise sites, aggregators live).
select
    channel,
    count(*)                                                            as orders,
    round(avg(revenue_inr), 0)                                          as avg_order_value,
    round(avg(aggregator_commission_inr), 0)                            as avg_commission,
    round(avg(revenue_inr - aggregator_commission_inr - ingredient_cost_inr), 0) as avg_contribution,
    round(100.0 * sum(revenue_inr - aggregator_commission_inr - ingredient_cost_inr)
          / sum(revenue_inr), 1)                                        as contribution_margin_pct
from {{ ref('fct_orders') }}
where not is_refunded
  and order_date >= date '2024-09-01'
  and location_id <> 'L01'   -- the push cart has no delivery
group by 1
order by orders desc
