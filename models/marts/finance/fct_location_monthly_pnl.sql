-- Monthly P&L per site.
-- Ingredient cost is ACTUAL supplier spend (includes waste); the theoretical
-- recipe cost is kept alongside so waste can be measured as the gap.
-- For franchise sites this is the franchisee's P&L; the royalty and marketing
-- fund they owe HQ are shown as separate lines.
with spine as (
    select l.location_id, cast(m as date) as month
    from {{ ref('dim_locations') }} l,
         range(date_trunc('month', l.opened_on), date '2026-01-01', interval 1 month) t(m)
),

sales as (
    select
        location_id,
        date_trunc('month', order_date)::date        as month,
        count(*) filter (where not is_refunded)      as orders,
        count(*) filter (where is_refunded)          as refunded_orders,
        sum(revenue_inr)                             as revenue_inr,
        sum(discount_inr) filter (where not is_refunded) as discounts_inr,
        sum(aggregator_commission_inr)               as aggregator_commission_inr,
        sum(ingredient_cost_inr)                     as theoretical_ingredient_cost_inr
    from {{ ref('fct_orders') }}
    group by 1, 2
),

purchases as (
    select
        location_id,
        date_trunc('month', week_start)::date as month,
        sum(purchase_cost_inr)                as actual_ingredient_cost_inr
    from {{ ref('stg_pos__ingredient_purchases') }}
    group by 1, 2
),

opex as (
    select
        location_id,
        month,
        sum(amount_inr) filter (where expense_type = 'rent')            as rent_inr,
        sum(amount_inr) filter (where expense_type = 'staff')           as staff_inr,
        sum(amount_inr) filter (where expense_type = 'utilities')       as utilities_inr,
        sum(amount_inr) filter (where expense_type = 'local_marketing') as local_marketing_inr
    from {{ ref('stg_pos__operating_expenses') }}
    group by 1, 2
),

joined as (
    select
        s.location_id,
        s.month,
        l.ownership_model,
        coalesce(sa.orders, 0)                           as orders,
        coalesce(sa.refunded_orders, 0)                  as refunded_orders,
        coalesce(sa.revenue_inr, 0)                      as revenue_inr,
        coalesce(sa.discounts_inr, 0)                    as discounts_inr,
        coalesce(sa.aggregator_commission_inr, 0)        as aggregator_commission_inr,
        coalesce(sa.theoretical_ingredient_cost_inr, 0)  as theoretical_ingredient_cost_inr,
        coalesce(p.actual_ingredient_cost_inr, 0)        as actual_ingredient_cost_inr,
        coalesce(o.rent_inr, 0)                          as rent_inr,
        coalesce(o.staff_inr, 0)                         as staff_inr,
        coalesce(o.utilities_inr, 0)                     as utilities_inr,
        coalesce(o.local_marketing_inr, 0)               as local_marketing_inr,
        coalesce(l.royalty_pct, 0)                       as royalty_pct,
        coalesce(l.marketing_fund_pct, 0)                as marketing_fund_pct
    from spine s
    join {{ ref('dim_locations') }} l using (location_id)
    left join sales sa using (location_id, month)
    left join purchases p using (location_id, month)
    left join opex o using (location_id, month)
)

select
    location_id,
    month,
    ownership_model,
    orders,
    refunded_orders,
    revenue_inr,
    discounts_inr,
    aggregator_commission_inr,
    round(theoretical_ingredient_cost_inr, 0)                                   as theoretical_ingredient_cost_inr,
    round(actual_ingredient_cost_inr, 0)                                        as actual_ingredient_cost_inr,
    round(actual_ingredient_cost_inr - theoretical_ingredient_cost_inr, 0)      as waste_cost_inr,
    round(revenue_inr - aggregator_commission_inr - actual_ingredient_cost_inr, 0) as gross_profit_inr,
    rent_inr,
    staff_inr,
    utilities_inr,
    local_marketing_inr,
    round(revenue_inr * royalty_pct, 0)                                         as royalty_to_hq_inr,
    round(revenue_inr * marketing_fund_pct, 0)                                  as marketing_fund_to_hq_inr,
    round(revenue_inr - aggregator_commission_inr - actual_ingredient_cost_inr
          - rent_inr - staff_inr - utilities_inr - local_marketing_inr
          - revenue_inr * (royalty_pct + marketing_fund_pct), 0)                as site_ebitda_inr,
    round(100.0 * (revenue_inr - aggregator_commission_inr - actual_ingredient_cost_inr)
          / nullif(revenue_inr, 0), 1)                                          as gross_margin_pct,
    round(100.0 * (actual_ingredient_cost_inr - theoretical_ingredient_cost_inr)
          / nullif(actual_ingredient_cost_inr, 0), 1)                           as waste_pct_of_ingredient_spend,
    round(100.0 * (revenue_inr - aggregator_commission_inr - actual_ingredient_cost_inr
          - rent_inr - staff_inr - utilities_inr - local_marketing_inr
          - revenue_inr * (royalty_pct + marketing_fund_pct)) / nullif(revenue_inr, 0), 1) as site_ebitda_margin_pct
from joined
