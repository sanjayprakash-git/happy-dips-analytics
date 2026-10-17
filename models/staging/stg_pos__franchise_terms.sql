select
    location_id,
    cast(royalty_pct as double)        as royalty_pct,
    cast(marketing_fund_pct as double) as marketing_fund_pct
from {{ source('pos', 'franchise_terms') }}
