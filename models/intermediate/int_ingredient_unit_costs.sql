-- Weighted average purchase price per location, week and ingredient.
-- Used to cost each sale at what the site actually paid that week.
select
    location_id,
    week_start,
    ingredient_id,
    sum(purchase_cost_inr) / nullif(sum(quantity), 0) as unit_cost_inr
from {{ ref('stg_pos__ingredient_purchases') }}
group by 1, 2, 3
