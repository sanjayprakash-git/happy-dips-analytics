select
    customer_id,
    first_location_id,
    cast(first_seen_at as timestamp) as first_seen_at
from {{ source('pos', 'customers') }}
