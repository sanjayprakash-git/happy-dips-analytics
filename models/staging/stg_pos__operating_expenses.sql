select
    location_id,
    cast(month as date)          as month,
    expense_type,
    cast(amount_inr as integer)  as amount_inr
from {{ source('pos', 'operating_expenses') }}
