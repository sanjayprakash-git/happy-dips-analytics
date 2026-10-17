-- Monthly product economics: volume, revenue share and margin after ingredient cost.
-- Shows how cocoa and strawberry price swings moved each product's margin.
with monthly as (
    select
        date_trunc('month', i.order_date)::date as month,
        i.product_id,
        sum(i.quantity) filter (where not i.is_refunded) as units,
        sum(i.revenue_inr)                                as revenue_inr,
        sum(i.ingredient_cost_inr)                        as ingredient_cost_inr
    from {{ ref('fct_order_items') }} i
    group by 1, 2
)

select
    m.month,
    m.product_id,
    p.product_name,
    p.category,
    m.units,
    m.revenue_inr,
    round(m.ingredient_cost_inr, 0)                                              as ingredient_cost_inr,
    round(100.0 * (m.revenue_inr - m.ingredient_cost_inr) / nullif(m.revenue_inr, 0), 1)
                                                                                 as ingredient_margin_pct,
    round(100.0 * m.revenue_inr / sum(m.revenue_inr) over (partition by m.month), 1)
                                                                                 as revenue_share_pct,
    rank() over (partition by m.month order by m.revenue_inr desc)               as revenue_rank,
    round(100.0 * (m.revenue_inr - m.ingredient_cost_inr) / nullif(m.revenue_inr, 0), 1)
      - lag(round(100.0 * (m.revenue_inr - m.ingredient_cost_inr) / nullif(m.revenue_inr, 0), 1), 12)
          over (partition by m.product_id order by m.month)                      as margin_change_vs_last_year_pts
from monthly m
join {{ ref('dim_products') }} p using (product_id)
