select
    ingredient_id,
    ingredient_name,
    unit
from {{ source('pos', 'ingredients') }}
