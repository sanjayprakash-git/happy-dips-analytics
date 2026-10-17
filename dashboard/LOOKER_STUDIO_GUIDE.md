# Looker Studio build guide

A 3-page dashboard built from the CSVs in `dashboard/data/`. Plan for 60–90 minutes.
Every chart answers one business question. Put that question in the chart title, not a field name.

## 0. Setup (10 min)

1. Go to [lookerstudio.google.com](https://lookerstudio.google.com) → **Blank report**.
2. Add data → **File Upload** → upload all six CSVs from `dashboard/data/`. Each becomes its own data source.
3. In each data source, check field types:
   - `month`, `order_date`, `cohort_month`, `opened_on` → **Date (YYYY-MM-DD)**
   - every `*_inr` field → **Currency (INR)**
   - every `*_pct` field → **Number** (values are already ×100, so don't format them as Percent)
4. **Theme:** Theme and layout → pick a light theme, then set the primary colour to a chocolate brown (`#5B3A29`) with a strawberry red accent (`#D7263D`). Use these two consistently.
5. Page size: 1280 × 900 (Page → Current page settings).

## Page 1: Executive overview *(source: `brand_monthly`)*

| Element | Chart type | Setup |
|---|---|---|
| Header text | Text | "Happy Dips: from 1 push cart to 9 sites" + subtitle "Synthetic data modelled on the real business" |
| KPI: System-wide sales | Scorecard | Metric `system_wide_sales_inr` (SUM). Comparison: previous period. |
| KPI: HQ contribution | Scorecard | Metric `hq_contribution_inr` (SUM) |
| KPI: Orders | Scorecard | Metric `orders` (SUM) |
| KPI: Trading sites | Scorecard | Metric `trading_sites` (MAX) |
| "How fast did the brand grow?" | Combo chart | Dimension `month`. Bars: `system_wide_sales_inr`. Line (right axis): `trading_sites`. |
| "What does HQ actually earn?" | Stacked column | Dimension `month`. Metrics: `owned_site_ebitda_inr`, `franchise_fee_income_inr` |
| "How much of the brand is franchised?" | Line | Dimension `month`. Metric `franchise_share_of_sales_pct` (AVG) |
| Date control | Date range control | Top right of the page, default: auto (all dates) |

**Takeaway text box** (bottom): *"By Dec 2025, HQ earned ₹15.1L/month on ₹92.7L system sales. Franchise fees grew to ~40% of HQ contribution, which is income with no site-level operating risk."*

## Page 2: Site performance *(source: `site_monthly_pnl`, plus `site_ramp_up`)*

| Element | Chart type | Setup |
|---|---|---|
| Filter | Drop-down list | Control field `location_name`; add a second one on `ownership_model` |
| "Which sites make money?" | Table with heatmap | Dimension `location_name`. Metrics: `revenue_inr` (SUM), `gross_margin_pct` (AVG), `waste_pct_of_ingredient_spend` (AVG), `site_ebitda_margin_pct` (AVG). Heatmap on the margin columns. Sort by revenue descending. |
| "Where does each rupee go?" | 100% stacked bar | Dimension `location_name`. Metrics: `actual_ingredient_cost_inr`, `aggregator_commission_inr`, `rent_inr`, `staff_inr`, `royalty_to_hq_inr`, `site_ebitda_inr` |
| "How much stock is wasted?" | Line | Dimension `month`, breakdown `location_name`. Metric `waste_pct_of_ingredient_spend` (AVG) |
| "How quickly do new sites ramp up?" | Line *(source: `site_ramp_up`)* | Dimension `months_since_open`, breakdown `location_name`. Metric `revenue_inr` (SUM). Filter: `months_since_open` ≤ 12. |

**Takeaway text box:** *"The push cart runs the best EBITDA margin (41%), with no delivery commission and minimal rent. Waste runs at 5–9% of ingredient spend across sites; the cart alone writes off about ₹14k a month in spoiled stock (it has no cold storage), so any cooling fix that halves that pays for itself fast."*

## Page 3: Products & customers *(sources: `product_monthly`, `customer_cohorts`, `daily_sales`)*

| Element | Chart type | Setup |
|---|---|---|
| "What sells?" | Treemap *(product_monthly)* | Dimension `product_name`. Metric `revenue_inr` (SUM) |
| "How did cocoa & strawberry prices hit margins?" | Line *(product_monthly)* | Dimension `month`, breakdown `product_name`. Metric `ingredient_margin_pct` (AVG). Filter out "Extra Topping". |
| "Do customers come back?" | Pivot table with heatmap *(customer_cohorts)* | Row dimension `cohort_month`. Column dimension `months_since_first_order`. Metric `retention_pct` (AVG). Heatmap colouring. |
| "Are delivery apps worth it?" | Bar *(daily_sales)* | Dimension `channel`. Metric: calculated field **Contribution margin %** (below) |
| "When do people buy?" | Column *(daily_sales)* | Dimension `order_date` with type **Day of week**. Metric `orders` (SUM) |

**Calculated field** (in the `daily_sales` source → Add a field):
```
Contribution margin % =
(SUM(revenue_inr) - SUM(aggregator_commission_inr) - SUM(ingredient_cost_inr)) / SUM(revenue_inr)
```
Set its type to **Percent**.

**Takeaway text box:** *"A delivery order earns ₹119–126 vs ₹185 for walk-in. One in four loyalty customers returns the month after their first order; the 'at risk' segment holds 33% of loyalty revenue and is the first target for a win-back offer."*

## Finish (10 min)

- Add a small footer on every page: "Data: synthetic, modelled on Happy Dips · Built with dbt + DuckDB · github.com/sanjayprakash-git/happy-dips-analytics"
- **Share** → Manage access → "Anyone with the link can view".
- **File → Download → PDF** for a static copy. Take one screenshot per page, save them to `dashboard/screenshots/`, and send them to me: I'll add them to the README.

## Power BI (when you're on Windows)

The same CSVs work in Power BI Desktop: Get Data → Text/CSV. Build the same 3 pages. For PL-300 practice, also:
- create a proper **star schema** (relate the site tables on `location_id`, add a date table with `CALENDAR()`)
- write the KPIs as **DAX measures**, e.g. `Contribution Margin % = DIVIDE([Revenue] - [Commission] - [Ingredient Cost], [Revenue])`
