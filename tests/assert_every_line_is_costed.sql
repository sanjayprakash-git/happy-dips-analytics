-- Every sold line (except refunds) must pick up an ingredient cost; a zero cost
-- means a missing recipe or a week with no supplier purchase recorded.
select order_id, line_number, product_id
from {{ ref('fct_order_items') }}
where not is_refunded and ingredient_cost_inr <= 0
