select
    purchase_id,
    location_id,
    cast(week_start as date)                 as week_start,
    ingredient_id,
    cast(quantity as double)                 as quantity,
    cast(unit_cost_inr as double)            as unit_cost_inr,
    cast(quantity * unit_cost_inr as double) as purchase_cost_inr
from {{ source('pos', 'ingredient_purchases') }}
