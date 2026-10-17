-- Every order's gross amount must equal the sum of its line items.
select o.order_id, o.gross_amount_inr, sum(i.line_amount_inr) as items_total
from {{ ref('stg_pos__orders') }} o
join {{ ref('stg_pos__order_items') }} i using (order_id)
group by 1, 2
having o.gross_amount_inr <> sum(i.line_amount_inr)
