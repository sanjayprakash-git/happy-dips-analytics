with first_last as (
    select location_id, min(order_date) as first_order_date, max(order_date) as last_order_date
    from {{ ref('stg_pos__orders') }}
    group by 1
)

select
    l.location_id,
    l.location_name,
    l.location_type,
    l.ownership_model,
    l.is_franchise,
    l.city,
    l.opened_on,
    fl.first_order_date,
    fl.last_order_date,
    datediff('month', l.opened_on, fl.last_order_date)            as months_trading,
    row_number() over (order by l.opened_on)                       as opening_sequence,
    f.royalty_pct,
    f.marketing_fund_pct
from {{ ref('stg_pos__locations') }} l
left join first_last fl using (location_id)
left join {{ ref('stg_pos__franchise_terms') }} f using (location_id)
