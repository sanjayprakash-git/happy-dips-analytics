select
    location_id,
    trim(location_name)         as location_name,
    location_type,
    ownership_model,
    ownership_model = 'franchise' as is_franchise,
    city,
    cast(opened_on as date)     as opened_on
from {{ source('pos', 'locations') }}
