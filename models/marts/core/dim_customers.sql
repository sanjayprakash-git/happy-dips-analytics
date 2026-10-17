with orders as (
    select * from {{ ref('fct_orders') }}
    where customer_id is not null and not is_refunded
),

dataset_end as (
    select max(order_date) as as_of from {{ ref('fct_orders') }}
)

select
    o.customer_id,
    arg_min(o.location_id, o.ordered_at)                      as first_location_id,
    min(o.order_date)                                          as first_order_date,
    date_trunc('month', min(o.order_date))::date              as cohort_month,
    max(o.order_date)                                          as last_order_date,
    count(*)                                                   as lifetime_orders,
    sum(o.revenue_inr)                                         as lifetime_revenue_inr,
    round(avg(o.revenue_inr), 1)                               as avg_order_value_inr,
    count(*) > 1                                               as is_repeat_customer,
    datediff('day', max(o.order_date), any_value(d.as_of))    as days_since_last_order
from orders o
cross join dataset_end d
group by o.customer_id
