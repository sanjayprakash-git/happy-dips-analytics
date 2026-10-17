-- Each order line with its theoretical ingredient cost:
-- recipe quantity x units sold x that week's purchase price at that site.
with items as (
    select
        i.*,
        o.location_id,
        o.order_date,
        date_trunc('week', o.order_date)::date as week_start,
        o.channel,
        o.is_refunded
    from {{ ref('stg_pos__order_items') }} i
    join {{ ref('stg_pos__orders') }} o using (order_id)
),

line_costs as (
    select
        items.order_id,
        items.line_number,
        sum(items.quantity * r.qty_per_unit * c.unit_cost_inr) as ingredient_cost_inr
    from items
    join {{ ref('stg_pos__recipes') }} r using (product_id)
    left join {{ ref('int_ingredient_unit_costs') }} c
        on  c.location_id   = items.location_id
        and c.week_start    = items.week_start
        and c.ingredient_id = r.ingredient_id
    group by 1, 2
)

select
    items.order_id,
    items.line_number,
    items.product_id,
    items.location_id,
    items.order_date,
    items.channel,
    items.is_refunded,
    items.quantity,
    items.unit_price_inr,
    items.line_amount_inr,
    round(coalesce(lc.ingredient_cost_inr, 0), 2) as ingredient_cost_inr
from items
left join line_costs lc using (order_id, line_number)
