-- RFM segmentation of loyalty customers (recency, frequency, monetary quintiles).
with scored as (
    select
        customer_id,
        days_since_last_order,
        lifetime_orders,
        lifetime_revenue_inr,
        ntile(5) over (order by days_since_last_order desc) as r,
        ntile(5) over (order by lifetime_orders)            as f,
        ntile(5) over (order by lifetime_revenue_inr)       as m
    from {{ ref('dim_customers') }}
),
segmented as (
    select *,
        case
            when r >= 4 and f >= 4 then 'Champions'
            when r >= 3 and f >= 3 then 'Loyal'
            when r >= 4 and f <= 2 then 'New / promising'
            when r <= 2 and f >= 3 then 'At risk'
            else 'Lapsed'
        end as segment
    from scored
)
select
    segment,
    count(*)                                                    as customers,
    round(100.0 * count(*) / sum(count(*)) over (), 1)          as pct_customers,
    round(100.0 * sum(lifetime_revenue_inr) / sum(sum(lifetime_revenue_inr)) over (), 1) as pct_revenue,
    round(avg(lifetime_orders), 1)                              as avg_orders,
    round(avg(days_since_last_order))                           as avg_days_since_last
from segmented
group by 1
order by pct_revenue desc
