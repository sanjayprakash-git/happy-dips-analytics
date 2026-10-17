-- How quickly does a new site reach steady-state sales?
-- Indexes every site by months since opening so launches can be compared directly.
with monthly as (
    select
        p.location_id,
        l.location_name,
        l.ownership_model,
        l.opening_sequence,
        p.month,
        datediff('month', date_trunc('month', l.opened_on), p.month) as months_since_open,
        p.orders,
        p.revenue_inr,
        p.site_ebitda_inr
    from {{ ref('fct_location_monthly_pnl') }} p
    join {{ ref('dim_locations') }} l using (location_id)
    where p.month >= date_trunc('month', l.opened_on)
)

select
    *,
    sum(revenue_inr) over (partition by location_id order by month)          as cumulative_revenue_inr,
    sum(site_ebitda_inr) over (partition by location_id order by month)      as cumulative_ebitda_inr,
    -- first month the site's monthly EBITDA turned positive
    min(case when site_ebitda_inr > 0 then months_since_open end)
        over (partition by location_id)                                       as first_profitable_month,
    round(100.0 * revenue_inr / nullif(max(revenue_inr) over (partition by location_id), 0), 1)
                                                                              as pct_of_best_month,
    rank() over (partition by months_since_open order by revenue_inr desc)   as rank_among_sites_same_age
from monthly
