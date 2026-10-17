select
    product_id,
    trim(product_name)              as product_name,
    category,
    cast(list_price_inr as integer) as list_price_inr,
    cast(launched_on as date)       as launched_on
from {{ source('pos', 'products') }}
