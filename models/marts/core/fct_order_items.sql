select
    order_id,
    line_number,
    product_id,
    location_id,
    order_date,
    channel,
    is_refunded,
    quantity,
    unit_price_inr,
    case when is_refunded then 0 else line_amount_inr end     as revenue_inr,
    case when is_refunded then 0 else ingredient_cost_inr end as ingredient_cost_inr
from {{ ref('int_order_items_costed') }}
