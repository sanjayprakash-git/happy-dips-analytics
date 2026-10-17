-- Staffing: share of weekly orders by hour and weekday (last 6 months).
select
    order_hour,
    {% for d in ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'] -%}
    round(100.0 * count(*) filter (where strftime(order_date, '%a') = '{{ d }}')
          / sum(count(*)) over (), 2) as {{ d | lower }}{{ "," if not loop.last }}
    {% endfor %}
from {{ ref('fct_orders') }}
where order_date >= date '2025-07-01' and not is_refunded
group by 1
order by 1
