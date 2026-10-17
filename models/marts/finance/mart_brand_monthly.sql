-- Brand-level monthly view: system-wide sales vs what HQ actually earns.
-- HQ earns site EBITDA from owned sites plus royalty + marketing fund from franchises.
select
    month,
    count(*) filter (where orders > 0)                                            as trading_sites,
    count(*) filter (where orders > 0 and ownership_model = 'franchise')          as franchise_sites,
    sum(orders)                                                                   as orders,
    sum(revenue_inr)                                                              as system_wide_sales_inr,
    sum(revenue_inr) filter (where ownership_model = 'owned')                     as owned_site_sales_inr,
    sum(site_ebitda_inr) filter (where ownership_model = 'owned')                 as owned_site_ebitda_inr,
    sum(royalty_to_hq_inr + marketing_fund_to_hq_inr)                             as franchise_fee_income_inr,
    sum(site_ebitda_inr) filter (where ownership_model = 'owned')
        + sum(royalty_to_hq_inr + marketing_fund_to_hq_inr)                       as hq_contribution_inr,
    -- FILTER returns NULL when no franchise was trading yet; that month's share is 0%
    round(100.0 * coalesce(sum(revenue_inr) filter (where ownership_model = 'franchise'), 0)
          / nullif(sum(revenue_inr), 0), 1)                                       as franchise_share_of_sales_pct,
    round(100.0 * (sum(revenue_inr) / lag(sum(revenue_inr), 12) over (order by month) - 1), 1)
                                                                                  as sales_yoy_growth_pct,
    sum(sum(revenue_inr)) over (order by month)                                   as cumulative_sales_inr
from {{ ref('fct_location_monthly_pnl') }}
group by month
order by month
