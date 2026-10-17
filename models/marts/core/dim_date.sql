-- Calendar spine covering the full trading history.
-- Indian financial year runs April-March (FY2025 = Apr 2024 - Mar 2025).
with days as (
    select cast(d as date) as date_day
    from range(date '2023-12-01', date '2026-01-01', interval 1 day) t(d)
)

select
    date_day,
    extract(year from date_day)                              as calendar_year,
    extract(month from date_day)                             as month_number,
    strftime(date_day, '%b')                                 as month_name,
    date_trunc('month', date_day)::date                      as month_start,
    date_trunc('week', date_day)::date                       as week_start,
    strftime(date_day, '%a')                                 as day_name,
    extract(isodow from date_day) in (6, 7)                  as is_weekend,
    'FY' || (extract(year from date_day) + case when extract(month from date_day) >= 4 then 1 else 0 end)
                                                             as fiscal_year,
    extract(month from date_day) = 2
        and extract(day from date_day) between 7 and 14      as is_valentines_week,
    extract(month from date_day) in (11, 12, 1, 2, 3)        as is_strawberry_season
from days
