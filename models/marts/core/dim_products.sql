select
    p.product_id,
    p.product_name,
    p.category,
    p.list_price_inr,
    p.launched_on,
    count(r.ingredient_id) as ingredient_count
from {{ ref('stg_pos__products') }} p
left join {{ ref('stg_pos__recipes') }} r using (product_id)
group by all
