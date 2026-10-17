-- Monthly P&L revenue must reconcile to order-level revenue (to the rupee).
select
    (select sum(revenue_inr) from {{ ref('fct_location_monthly_pnl') }}) as pnl_revenue,
    (select sum(revenue_inr) from {{ ref('fct_orders') }})               as order_revenue
where abs(
    (select sum(revenue_inr) from {{ ref('fct_location_monthly_pnl') }})
  - (select sum(revenue_inr) from {{ ref('fct_orders') }})
) > 0
