-- A site cannot take orders before its opening date.
select o.order_id, o.order_date, l.opened_on
from {{ ref('fct_orders') }} o
join {{ ref('dim_locations') }} l using (location_id)
where o.order_date < l.opened_on
