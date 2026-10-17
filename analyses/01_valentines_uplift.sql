-- How much does Valentine's week lift sales vs a normal February week?
-- Compares each site's Feb 7-14 daily average to its Feb 15-28 daily average.
with daily as (
    select o.location_id, o.order_date, d.is_valentines_week, sum(o.revenue_inr) as revenue
    from {{ ref('fct_orders') }} o
    join {{ ref('dim_date') }} d on d.date_day = o.order_date
    where d.month_number = 2 and extract(day from o.order_date) >= 7
    group by all
)
select
    extract(year from order_date)                                         as year,
    round(avg(revenue) filter (where is_valentines_week))                 as avg_daily_valentines_week,
    round(avg(revenue) filter (where not is_valentines_week))             as avg_daily_rest_of_feb,
    round(100.0 * (avg(revenue) filter (where is_valentines_week)
                   / avg(revenue) filter (where not is_valentines_week) - 1), 1) as uplift_pct
from daily
group by 1
order by 1
