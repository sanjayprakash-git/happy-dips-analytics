-- One row per order. Refunded orders are kept (for refund-rate analysis)
-- but carry zero recognised revenue.
with item_totals as (
    select
        order_id,
        sum(quantity)            as units,
        count(*)                 as line_count,
        sum(ingredient_cost_inr) as ingredient_cost_inr
    from {{ ref('int_order_items_costed') }}
    group by 1
)

select
    o.order_id,
    o.location_id,
    o.customer_id,
    o.ordered_at,
    o.order_date,
    extract(hour from o.ordered_at)                                  as order_hour,
    o.channel,
    o.payment_method,
    o.status,
    o.is_refunded,
    i.units,
    i.line_count,
    o.gross_amount_inr,
    o.discount_inr,
    case when o.is_refunded then 0 else o.net_amount_inr end         as revenue_inr,
    case when o.is_refunded then 0
         else round(o.net_amount_inr * ac.commission_pct, 2) end     as aggregator_commission_inr,
    case when o.is_refunded then 0 else i.ingredient_cost_inr end    as ingredient_cost_inr
from {{ ref('stg_pos__orders') }} o
join item_totals i using (order_id)
left join {{ ref('aggregator_commission') }} ac using (channel)
