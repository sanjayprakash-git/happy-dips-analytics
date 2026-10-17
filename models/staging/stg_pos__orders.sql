-- Cleans the raw POS order export:
--   1. removes duplicate rows written by the POS sync (keeps one per order_id)
--   2. normalises channel / payment_method casing and whitespace
--   3. derives net revenue and a refund flag
with source as (
    select * from {{ source('pos', 'orders') }}
),

deduplicated as (
    select *
    from source
    qualify row_number() over (partition by order_id order by ordered_at) = 1
)

select
    order_id,
    location_id,
    cast(ordered_at as timestamp)               as ordered_at,
    cast(ordered_at as date)                    as order_date,
    lower(trim(channel))                        as channel,
    lower(trim(payment_method))                 as payment_method,
    nullif(trim(customer_id), '')               as customer_id,
    cast(gross_amount_inr as integer)           as gross_amount_inr,
    cast(discount_inr as integer)               as discount_inr,
    cast(gross_amount_inr - discount_inr as integer) as net_amount_inr,
    status,
    status = 'refunded'                         as is_refunded
from deduplicated
