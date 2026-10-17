"""
Export dashboard-ready tables from the warehouse to dashboard/data/*.csv.
Run after `dbt build`. Upload the CSVs to Looker Studio / Google Sheets / Power BI.
"""
from pathlib import Path

import duckdb

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "dashboard" / "data"
OUT.mkdir(parents=True, exist_ok=True)

EXPORTS = {
    "brand_monthly": "select * from finance.mart_brand_monthly order by month",
    "site_monthly_pnl": """
        select p.*, l.location_name, l.city, l.location_type, l.opened_on
        from finance.fct_location_monthly_pnl p
        join core.dim_locations l using (location_id)
        order by month, location_id""",
    "product_monthly": "select * from growth.mart_product_performance order by month, revenue_rank",
    "customer_cohorts": """
        select * from growth.mart_customer_cohorts
        where months_since_first_order <= 12
        order by cohort_month, months_since_first_order""",
    "site_ramp_up": "select * from growth.mart_site_ramp_up order by location_id, month",
    "daily_sales": """
        select o.order_date, o.location_id, l.location_name, o.channel,
               count(*) filter (where not o.is_refunded) as orders,
               sum(o.revenue_inr)                        as revenue_inr,
               sum(o.aggregator_commission_inr)          as aggregator_commission_inr,
               sum(o.ingredient_cost_inr)                as ingredient_cost_inr
        from core.fct_orders o
        join core.dim_locations l using (location_id)
        group by all
        order by 1, 2, 4""",
}

con = duckdb.connect(str(ROOT / "happy_dips.duckdb"), read_only=True)
for name, sql in EXPORTS.items():
    rel = con.sql(sql)
    rel.write_csv(str(OUT / f"{name}.csv"))
    print(f"{name:<18} {rel.shape[0]:>7,} rows")
