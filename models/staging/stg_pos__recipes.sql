select
    product_id,
    ingredient_id,
    cast(qty_per_unit as double) as qty_per_unit
from {{ source('pos', 'recipes') }}
