# Eco-track-AI
Backend of Eco track AI
# Eco-Track AI — Member 3: Database & Emission Factors

## About this project

**Eco-Track AI** estimates the carbon footprint of a household's grocery
shopping directly from a photo of the bill. The pipeline:

1. **Upload a bill** — user takes a photo or uploads an image
2. **OCR extraction** (Member 1) — text is pulled from the image using
   PaddleOCR, cleaned, and split into individual line items
3. **Product identification** (Member 2) — each OCR'd item name is matched
   against a master product list (using this database's `products` table
   and aliases) via classification, semantic matching, and confidence scoring
4. **Emission calculation** (Member 4) — for each matched product, its
   emission factor (kg CO2e per unit) is looked up and multiplied by
   quantity: `Carbon Footprint = Σ(Quantity × Emission Factor)`
5. **Results & dashboard** (Member 5) — total emissions, a category-wise
   breakdown, a sustainability score, and suggestions are shown to the user

This repository holds **Member 3's part**: the PostgreSQL database (hosted
on Supabase) that stores products, categories, emission factors, and bill
records, plus the Python layer (`database.py`, `models.py`, `crud.py`) the
rest of the team builds on top of.

## Database setup (Supabase / PostgreSQL)

Set up to run on **Supabase** (a free hosted PostgreSQL database) — no
local PostgreSQL install needed.

## What you're building

| Table | Purpose | Who else uses it |
|---|---|---|
| `categories` | Product groupings (Dairy, Grains, etc.) | Member 4 (category-wise emissions) |
| `products` | Master product list with aliases | Member 2 (matching OCR text to products) |
| `emission_factors` | kg CO2e per unit, per product or category | Member 4 (carbon calc engine) |
| `bills` | One row per uploaded bill | Member 1 (writes), Member 5 (reads for dashboard) |
| `bill_items` | Line items per bill | Member 1 writes raw text -> Member 2 fills product_id -> Member 4 fills emission_kg |

## Step 1 — Create your Supabase project

1. Go to **supabase.com**, sign up (GitHub or email).
2. Click **New project**.
3. Name it, set a **database password** (save it somewhere safe), pick a region, leave plan on **Free**.
4. Click **Create new project** and wait ~1-2 minutes.

## Step 2 — Run the schema

1. In the left sidebar, open **SQL Editor**.
2. Click **New query**.
3. Paste the entire contents of `schema.sql`, click **Run**.
4. Confirm: go to **Table Editor** — you should see `categories`, `products`,
   `emission_factors`, `bills`, `bill_items`.

## Step 3 — Load sample data

1. New query in the SQL Editor.
2. Paste the entire contents of `seed_data.sql`, click **Run**.
3. Confirm: open the `products` table in Table Editor — you should see
   Milk, Rice, Tomato, etc.

## Step 4 — Get your connection string

1. Click the **Connect** button near the top of the dashboard.
2. Choose the **Session pooler** connection string. It looks like:

```
postgresql://postgres.xxxxxxxxxxxx:[YOUR-PASSWORD]@aws-0-<region>.pooler.supabase.com:5432/postgres
```

3. Copy it and replace `[YOUR-PASSWORD]` with your actual database password.

## Step 5 — Install Python packages

```bash
pip install sqlalchemy psycopg2-binary
```

(Everything else needed is in `requirements.txt` — `pip install -r requirements.txt` works too.)

## Step 6 — Set your connection string

Open `database.py` and either:

- **Quick way**: paste your real connection string directly into the
  fallback value inside `os.getenv(...)`, or
- **Safer way** (recommended, especially before pushing to GitHub):
  set it as an environment variable instead of hardcoding it:

```bash
# Mac/Linux
export DATABASE_URL="postgresql://postgres.xxxx:yourpassword@aws-0-ap-south-1.pooler.supabase.com:5432/postgres"

# Windows PowerShell
$env:DATABASE_URL="postgresql://postgres.xxxx:yourpassword@aws-0-ap-south-1.pooler.supabase.com:5432/postgres"
```

Supabase requires SSL for connections — `database.py` already sets
`sslmode="require"` for you, so you don't need to add that yourself.

## Step 7 — Test it

```bash
python test_connection.py
```

You should see the seeded categories, products, a successful alias
lookup (`atta` -> Wheat Flour), the emission factor for rice, and the
sample bill with its 3 items printed out.

## Step 8 — Share access with your team

Since the database lives in the cloud, give your teammates the same
**connection string** from Step 4 (treat it like a password — don't
post it in a public repo or open group chat). Each of them pastes it
into their own copy of `database.py`, so everyone's code reads and
writes to the same shared database.

## Step 9 — Hand off to your teammates

Give Members 1, 2, 4, and 5 `database.py`, `models.py`, and `crud.py`.
They just need:

```python
from database import SessionLocal
import crud

db = SessionLocal()
product = crud.find_product_by_name(db, "milk")
```

- **Member 1 (OCR)**: `crud.create_bill()` then `crud.add_bill_item()`
  for each line extracted from the bill image.
- **Member 2 (AI matching)**: `crud.find_product_by_name()` first; if
  `None`, do semantic matching against `crud.get_all_products()`, then
  update `bill_item.product_id`, or `crud.create_product()` for a new one.
- **Member 4 (Carbon calc)**: `crud.get_emission_factor_for_product()`
  (fall back to `crud.get_emission_factor_for_category()`), multiply by
  `quantity`, save with `crud.update_item_emission()`, then
  `crud.update_bill_total_emission()`.
- **Member 5 (Frontend/API)**: `crud.get_bill_with_items()`, or query the
  `bill_emission_summary` SQL view directly for dashboard charts.

## Step 10 — Expand the emission factor data (important for grading)

The values in `seed_data.sql` are placeholders. Before final submission,
replace them with real cited figures from:
- DEFRA UK Greenhouse Gas Conversion Factors
- Our World in Data — Environmental Impacts of Food
- Poore & Nemecek (2018), *Science* — food emissions dataset

Add rows to `emission_factors` the same way as the seed file, and cite
the `source` column.

## Troubleshooting

| Problem | Fix |
|---|---|
| `password authentication failed` | Recheck the password in your connection string — no stray brackets/spaces |
| `could not translate host name` | Make sure you copied the **Session pooler** string, not a different one |
| `ModuleNotFoundError: No module named 'psycopg2'` | Re-run `pip install psycopg2-binary` in the same environment you run scripts with |
| SQL Editor shows a red error | You probably pasted only part of `schema.sql` — copy the whole file again |
| Table Editor looks empty after running SQL | Refresh the page |

## Files in this package

- `schema.sql` — table definitions, indexes, view (run in Supabase SQL Editor)
- `seed_data.sql` — sample data to develop against (run in Supabase SQL Editor)
- `database.py` — SQLAlchemy engine/session setup, configured for Supabase
- `models.py` — ORM models matching the schema
- `crud.py` — ready-made functions for the other members to call
- `test_connection.py` — quick script to confirm everything works
- `requirements.txt` — Python dependencies

