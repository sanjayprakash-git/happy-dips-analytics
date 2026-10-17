-- Monthly retention cohorts for identified (loyalty) customers.
-- retention_pct = share of the cohort that ordered again N months after their first month.
with activity as (
    select distinct
        o.customer_id,
        c.cohort_month,
        date_trunc('month', o.order_date)::date as active_month
    from {{ ref('fct_orders') }} o
    join {{ ref('dim_customers') }} c using (customer_id)
    where not o.is_refunded
),

cohort_sizes as (
    select cohort_month, count(*) as cohort_size
    from {{ ref('dim_customers') }}
    group by 1
)

select
    a.cohort_month,
    datediff('month', a.cohort_month, a.active_month)          as months_since_first_order,
    cs.cohort_size,
    count(*)                                                    as active_customers,
    round(100.0 * count(*) / cs.cohort_size, 1)                 as retention_pct
from activity a
join cohort_sizes cs using (cohort_month)
group by 1, 2, 3
order by 1, 2
