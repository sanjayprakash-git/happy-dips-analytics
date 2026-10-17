"""
Generate a synthetic dataset modelled on Happy Dips' growth story:
1 push cart (Dec 2023) -> 1 flagship branch -> 7 franchises (through 2025).

All figures are SYNTHETIC. Volumes, prices and patterns are plausible for a
Chennai dessert brand, but they are not the business's real numbers.

Writes CSVs to data/raw/. Deterministic (fixed seed). Stdlib only.

Deliberate data-quality issues (cleaned in the dbt staging layer):
  - ~0.4% of orders duplicated by the POS sync (same order_id, same values)
  - payment_method / channel casing and whitespace are inconsistent
  - some product names in the menu export have stray whitespace
  - ~1.5% of orders are refunds (status = 'refunded')
"""
import csv
import math
import random
from datetime import date, datetime, timedelta
from pathlib import Path

random.seed(2023)
OUT = Path(__file__).resolve().parent.parent / "data" / "raw"
OUT.mkdir(parents=True, exist_ok=True)

START, END = date(2023, 12, 1), date(2025, 12, 31)

# ── Locations ───────────────────────────────────────────────────────────────
# base = steady-state orders/day once ramped up
LOCATIONS = [
    # id,   name,                         type,        model,       city,         opened,            base, rent,   staff
    ("L01", "Besant Nagar Push Cart",     "cart",      "owned",     "Chennai",    date(2023, 12, 1),  38,  8000,  18000),
    ("L02", "Anna Nagar Flagship",        "branch",    "owned",     "Chennai",    date(2024, 3, 15), 125, 65000,  90000),
    ("L03", "T Nagar",                    "kiosk",     "franchise", "Chennai",    date(2024, 6, 1),   85, 45000,  55000),
    ("L04", "Velachery Mall",             "kiosk",     "franchise", "Chennai",    date(2024, 8, 15),  95, 60000,  55000),
    ("L05", "Adyar",                      "kiosk",     "franchise", "Chennai",    date(2024, 10, 1),  70, 40000,  50000),
    ("L06", "OMR Food Street",            "kiosk",     "franchise", "Chennai",    date(2024, 12, 1),  78, 42000,  50000),
    ("L07", "Tambaram",                   "kiosk",     "franchise", "Chennai",    date(2025, 2, 15),  52, 30000,  45000),
    ("L08", "Porur",                      "kiosk",     "franchise", "Chennai",    date(2025, 5, 1),   60, 35000,  45000),
    ("L09", "RS Puram",                   "kiosk",     "franchise", "Coimbatore", date(2025, 8, 1),   66, 38000,  48000),
]
ROYALTY_PCT, MARKETING_FUND_PCT = 0.06, 0.02

# ── Products (INR) ──────────────────────────────────────────────────────────
# id, name, category, price, launched, recipe {ingredient: qty per unit}
PRODUCTS = [
    ("P01", "Classic Milk Dip Cup",    "dip_cup",  149, date(2023, 12, 1), {"STRAW": 0.10, "MILK_CHOC": 0.050, "CUP": 1}),
    ("P02", "Dark Dip Cup",            "dip_cup",  159, date(2023, 12, 1), {"STRAW": 0.10, "DARK_CHOC": 0.050, "CUP": 1}),
    ("P03", "White Dip Cup",           "dip_cup",  159, date(2024, 3, 15), {"STRAW": 0.10, "WHITE_CHOC": 0.050, "CUP": 1}),
    ("P04", "Triple Choc Cup",         "dip_cup",  199, date(2024, 3, 15), {"STRAW": 0.11, "MILK_CHOC": 0.025, "DARK_CHOC": 0.025, "WHITE_CHOC": 0.020, "CUP": 1}),
    ("P05", "Nutella Drizzle Cup",     "premium",  219, date(2024, 6, 1),  {"STRAW": 0.11, "MILK_CHOC": 0.040, "NUTELLA": 0.030, "CUP": 1}),
    ("P06", "Biscoff Crunch Cup",      "premium",  229, date(2024, 9, 1),  {"STRAW": 0.11, "WHITE_CHOC": 0.040, "BISCOFF": 0.030, "CUP": 1}),
    ("P07", "Party Box (12 pc)",       "box",      349, date(2024, 3, 15), {"STRAW": 0.30, "MILK_CHOC": 0.080, "DARK_CHOC": 0.040, "BOX": 1}),
    ("P08", "Gift Box (24 pc)",        "box",      649, date(2024, 2, 1),  {"STRAW": 0.60, "MILK_CHOC": 0.140, "DARK_CHOC": 0.080, "WHITE_CHOC": 0.040, "BOX": 1}),
    ("P09", "Chocolate Strawberry Shake", "beverage", 129, date(2024, 4, 1), {"STRAW": 0.08, "MILK_CHOC": 0.030, "MILK": 0.25, "CUP": 1}),
    ("P10", "Extra Topping",           "add_on",    30, date(2023, 12, 1), {"SPRINKLES": 0.015}),
]
# base popularity weights
PRODUCT_WEIGHT = {"P01": 30, "P02": 18, "P03": 10, "P04": 12, "P05": 11, "P06": 9,
                  "P07": 5, "P08": 2, "P09": 8, "P10": 0}

# ── Ingredients (INR per unit) ─────────────────────────────────────────────
INGREDIENTS = [
    # id,          name,                       unit,  base_price
    ("STRAW",      "Fresh strawberries (wholesale)", "kg", 240),
    ("MILK_CHOC",  "Milk compound chocolate",   "kg",   440),
    ("DARK_CHOC",  "Dark compound chocolate",   "kg",   500),
    ("WHITE_CHOC", "White compound chocolate",  "kg",   480),
    ("NUTELLA",    "Hazelnut spread",           "kg",   720),
    ("BISCOFF",    "Biscoff spread",            "kg",   900),
    ("MILK",       "Full-cream milk",           "l",     62),
    ("SPRINKLES",  "Toppings & sprinkles",      "kg",   600),
    ("CUP",        "Branded cup + fork",        "unit",   6),
    ("BOX",        "Gift / party box",          "unit",  28),
]
ING_PRICE = {i[0]: i[3] for i in INGREDIENTS}


def strawberry_price_factor(d: date) -> float:
    """Strawberry season in India is roughly Nov-Mar. Prices up to ~1.8x off-season."""
    return {1: 0.72, 2: 0.70, 3: 0.80, 4: 1.05, 5: 1.35, 6: 1.65,
            7: 1.80, 8: 1.75, 9: 1.50, 10: 1.20, 11: 0.90, 12: 0.78}[d.month]


def chocolate_price_factor(d: date) -> float:
    """Global cocoa prices surged through 2024 then eased slightly in late 2025."""
    months = (d.year - 2023) * 12 + d.month - 12
    return 1.0 + min(months, 14) * 0.035 - max(0, months - 22) * 0.01


def ingredient_price(ing: str, d: date) -> float:
    p = ING_PRICE[ing]
    if ing == "STRAW":
        p *= strawberry_price_factor(d)
    elif ing.endswith("CHOC") or ing in ("NUTELLA", "BISCOFF"):
        p *= chocolate_price_factor(d)
    return p * random.uniform(0.96, 1.04)


# ── Demand model ────────────────────────────────────────────────────────────
DIWALI = {date(2024, 10, 31), date(2025, 10, 20)}


def demand_factor(d: date) -> float:
    f = {0: 0.85, 1: 0.80, 2: 0.85, 3: 0.92, 4: 1.15, 5: 1.40, 6: 1.35}[d.weekday()]
    # weather / season: cool months up, peak summer down
    f *= {1: 1.15, 2: 1.20, 3: 1.05, 4: 0.85, 5: 0.75, 6: 0.85,
          7: 0.92, 8: 0.95, 9: 0.95, 10: 1.0, 11: 1.08, 12: 1.18}[d.month]
    if d.month == 2 and 7 <= d.day <= 13:
        f *= 1.6
    if d.month == 2 and d.day == 14:
        f *= 3.2
    if any(0 <= (x - d).days <= 4 for x in DIWALI):
        f *= 1.5
    if (d.month == 12 and d.day >= 24) or (d.month == 1 and d.day == 1):
        f *= 1.45
    if d.month == 10 and 20 <= d.day <= 31 and d.year == 2024:  # NE monsoon floods
        f *= 0.7
    return f


def ramp_up(days_open: int) -> float:
    """New sites reach ~95% of steady-state volume after ~4 months."""
    return 0.35 + 0.65 * (1 - math.exp(-days_open / 45))


HOUR_WEIGHTS = {11: 3, 12: 5, 13: 6, 14: 5, 15: 6, 16: 9, 17: 12, 18: 14, 19: 15, 20: 13, 21: 9, 22: 4}


def pick_channel(loc_type: str, d: date) -> str:
    if loc_type == "cart":
        return "walk_in"
    delivery_share = 0.18 if d < date(2024, 9, 1) else 0.32  # aggregators onboarded Sep 2024
    r = random.random()
    if r < delivery_share * 0.55:
        return "swiggy"
    if r < delivery_share:
        return "zomato"
    return "walk_in"


def messy(value: str) -> str:
    """Simulate inconsistent POS exports."""
    r = random.random()
    if r < 0.06:
        return value.upper()
    if r < 0.09:
        return f" {value} "
    if r < 0.11:
        return value.title()
    return value


# ── Generate ────────────────────────────────────────────────────────────────
products_live = lambda d: [p for p in PRODUCTS if p[4] <= d and p[0] != "P10"]

orders, items, purchases = [], [], []
customers = {}            # customer_id -> (first_location, first_seen)
loc_customers = {l[0]: [] for l in LOCATIONS}
order_seq, cust_seq = 0, 0

d = START
while d <= END:
    day_factor = demand_factor(d)
    for loc_id, _, loc_type, _, _, opened, base, *_ in LOCATIONS:
        if d < opened:
            continue
        # small structural growth for older sites; cart closes Mon (rest day)
        if loc_type == "cart" and d.weekday() == 0:
            continue
        n = base * ramp_up((d - opened).days) * day_factor * random.uniform(0.85, 1.15)
        n = max(0, int(random.gauss(n, n ** 0.5)))
        menu = products_live(d)
        weights = [PRODUCT_WEIGHT[p[0]] * (6 if p[0] == "P08" and d.month == 2 and 7 <= d.day <= 14 else 1)
                   for p in menu]
        for _ in range(n):
            order_seq += 1
            oid = f"HD{order_seq:07d}"
            hour = random.choices(list(HOUR_WEIGHTS), weights=HOUR_WEIGHTS.values())[0]
            ts = datetime(d.year, d.month, d.day, hour, random.randint(0, 59), random.randint(0, 59))
            channel = pick_channel(loc_type, d)
            payment = "aggregator" if channel != "walk_in" else random.choices(
                ["upi", "cash", "card"], weights=[68, 22, 10] if d.year == 2025 else [60, 32, 8])[0]

            # customer identification: loyalty via phone number on UPI / app orders
            cust_id = ""
            if channel != "walk_in" or random.random() < 0.38:
                pool = loc_customers[loc_id]
                if pool and random.random() < 0.52:
                    # repeat customer; recent customers more likely to return
                    cust_id = pool[min(len(pool) - 1, int(len(pool) * (1 - random.random() ** 2.2)))]
                else:
                    cust_seq += 1
                    cust_id = f"C{cust_seq:06d}"
                    customers[cust_id] = (loc_id, ts)
                    pool.append(cust_id)

            n_lines = random.choices([1, 2, 3], weights=[70, 24, 6])[0]
            chosen = random.choices(menu, weights=weights, k=n_lines)
            gross = 0
            line = 0
            for p in {p[0]: p for p in chosen}.values():  # unique products per order
                line += 1
                qty = random.choices([1, 2, 3], weights=[80, 16, 4])[0]
                price = p[3] + (10 if channel != "walk_in" else 0)  # app price uplift
                if d >= date(2025, 4, 1):
                    price = round(price * 1.08)  # price increase after cocoa spike
                items.append([oid, line, p[0], qty, price])
                gross += qty * price
                if random.random() < 0.18:
                    line += 1
                    items.append([oid, line, "P10", 1, 30])
                    gross += 30
            discount = round(gross * 0.10) if random.random() < 0.07 else 0
            status = "refunded" if random.random() < 0.015 else "completed"
            row = [oid, loc_id, ts.isoformat(sep=" "), messy(channel), messy(payment),
                   cust_id, gross, discount, status]
            orders.append(row)
            if random.random() < 0.004:
                orders.append(list(row))  # POS sync duplicate
    d += timedelta(days=1)

# ── Ingredient purchases: weekly per location, driven by consumption + waste ──
recipe = {p[0]: p[5] for p in PRODUCTS}
order_loc_week = {o[0]: (o[1], datetime.fromisoformat(o[2]).date()) for o in orders}
usage = {}
for oid, _, pid, qty, _ in items:
    loc, od = order_loc_week[oid]
    wk = od - timedelta(days=od.weekday())
    for ing, q in recipe[pid].items():
        usage[(loc, wk, ing)] = usage.get((loc, wk, ing), 0) + q * qty

po_seq = 0
for (loc, wk, ing), used in sorted(usage.items()):
    # strawberries are perishable: higher waste in hot months and at the cart
    if ing == "STRAW":
        waste = 0.10 + (0.08 if wk.month in (4, 5, 6) else 0) + (0.05 if loc == "L01" else 0)
    elif ing in ("CUP", "BOX"):
        waste = 0.02
    else:
        waste = 0.04
    qty = used * (1 + waste * random.uniform(0.7, 1.3))
    po_seq += 1
    purchases.append([f"PO{po_seq:06d}", loc, wk.isoformat(), ing,
                      round(qty, 3), round(ingredient_price(ing, wk), 2)])

# ── Monthly operating expenses (company-owned and franchise sites) ───────────
expenses = []
for loc_id, _, _, _, _, opened, _, rent, staff in LOCATIONS:
    m = date(opened.year, opened.month, 1)
    while m <= END:
        yrs = (m - date(2023, 12, 1)).days / 365
        expenses.append([loc_id, m.isoformat(), "rent", round(rent * (1.05 ** int(yrs)))])
        expenses.append([loc_id, m.isoformat(), "staff", round(staff * (1.08 ** yrs) * random.uniform(0.95, 1.05))])
        expenses.append([loc_id, m.isoformat(), "utilities", round(random.uniform(0.08, 0.14) * rent + 1500)])
        expenses.append([loc_id, m.isoformat(), "local_marketing", round(random.uniform(3000, 9000))])
        m = date(m.year + (m.month == 12), m.month % 12 + 1, 1)


def write(name, header, rows):
    with open(OUT / f"{name}.csv", "w", newline="") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)
    print(f"{name:<22} {len(rows):>9,} rows")


write("locations", ["location_id", "location_name", "location_type", "ownership_model", "city", "opened_on"],
      [[l[0], l[1], l[2], l[3], l[4], l[5].isoformat()] for l in LOCATIONS])
write("products", ["product_id", "product_name", "category", "list_price_inr", "launched_on"],
      [[p[0], (f"  {p[1]}" if random.random() < 0.3 else p[1]), p[2], p[3], p[4].isoformat()] for p in PRODUCTS])
write("recipes", ["product_id", "ingredient_id", "qty_per_unit"],
      [[p[0], ing, q] for p in PRODUCTS for ing, q in p[5].items()])
write("ingredients", ["ingredient_id", "ingredient_name", "unit"], [[i[0], i[1], i[2]] for i in INGREDIENTS])
write("customers", ["customer_id", "first_location_id", "first_seen_at"],
      [[c, v[0], v[1].isoformat(sep=" ")] for c, v in customers.items()])
write("orders", ["order_id", "location_id", "ordered_at", "channel", "payment_method",
                 "customer_id", "gross_amount_inr", "discount_inr", "status"], orders)
write("order_items", ["order_id", "line_number", "product_id", "quantity", "unit_price_inr"], items)
write("ingredient_purchases", ["purchase_id", "location_id", "week_start", "ingredient_id",
                               "quantity", "unit_cost_inr"], purchases)
write("operating_expenses", ["location_id", "month", "expense_type", "amount_inr"], expenses)
write("franchise_terms", ["location_id", "royalty_pct", "marketing_fund_pct"],
      [[l[0], ROYALTY_PCT, MARKETING_FUND_PCT] for l in LOCATIONS if l[3] == "franchise"])
