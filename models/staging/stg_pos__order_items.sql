select
    order_id,
    cast(line_number as integer)            as line_number,
    product_id,
    cast(quantity as integer)               as quantity,
    cast(unit_price_inr as integer)         as unit_price_inr,
    cast(quantity * unit_price_inr as integer) as line_amount_inr
from {{ source('pos', 'order_items') }}
