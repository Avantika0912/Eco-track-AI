-- ============================================================
-- CARBON FOOTPRINT PROJECT — DATABASE SCHEMA (Member 3)
-- Database: PostgreSQL 14+
-- Owner: Database & Emission Factors module
-- ============================================================

-- Clean slate (safe to re-run during development)
DROP TABLE IF EXISTS bill_items CASCADE;
DROP TABLE IF EXISTS bills CASCADE;
DROP TABLE IF EXISTS emission_factors CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;

-- Extension needed for fuzzy text search (used by an index below).
-- Must run BEFORE any CREATE INDEX that uses gin_trgm_ops.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- ------------------------------------------------------------
-- 1. CATEGORIES
-- High-level grouping used for emission factor lookup and
-- for Member 4's "category-wise emissions" breakdown.
-- ------------------------------------------------------------
CREATE TABLE categories (
    category_id     SERIAL PRIMARY KEY,
    category_name   VARCHAR(100) NOT NULL UNIQUE,
    description     TEXT,
    created_at      TIMESTAMP DEFAULT NOW()
);

-- ------------------------------------------------------------
-- 2. PRODUCTS
-- Master product list. Member 2 (AI Product Understanding)
-- will match OCR'd item names against this table (or insert
-- new products when no match is found).
-- ------------------------------------------------------------
CREATE TABLE products (
    product_id      SERIAL PRIMARY KEY,
    product_name    VARCHAR(200) NOT NULL,
    category_id     INTEGER REFERENCES categories(category_id) ON DELETE SET NULL,
    unit            VARCHAR(20) NOT NULL DEFAULT 'kg',  -- kg, litre, piece, etc.
    aliases         TEXT[],   -- alternate names OCR might extract, e.g. {'atta','wheat flour'}
    created_at      TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_name_trgm ON products USING gin (product_name gin_trgm_ops);
-- Note: idx_products_name_trgm requires the pg_trgm extension (see below)
-- for fast fuzzy/partial text search when Member 2 does semantic matching.

-- ------------------------------------------------------------
-- 3. EMISSION FACTORS
-- The core "science" table: kg CO2e emitted per unit of a
-- product/category. One product can have multiple factors
-- over time (emission factors get revised yearly) or from
-- different sources, so we keep history instead of overwriting.
-- ------------------------------------------------------------
CREATE TABLE emission_factors (
    factor_id           SERIAL PRIMARY KEY,
    product_id          INTEGER REFERENCES products(product_id) ON DELETE CASCADE,
    category_id         INTEGER REFERENCES categories(category_id) ON DELETE CASCADE,
    co2e_per_unit       NUMERIC(10,4) NOT NULL,  -- kg CO2e per unit
    unit                VARCHAR(20) NOT NULL DEFAULT 'kg',
    source              VARCHAR(200),             -- e.g. 'DEFRA 2024', 'IPCC'
    valid_from          DATE DEFAULT CURRENT_DATE,
    valid_to            DATE,                     -- NULL = still active
    created_at          TIMESTAMP DEFAULT NOW(),
    CONSTRAINT chk_product_or_category CHECK (
        product_id IS NOT NULL OR category_id IS NOT NULL
    )
);

CREATE INDEX idx_ef_product ON emission_factors(product_id);
CREATE INDEX idx_ef_category ON emission_factors(category_id);

-- ------------------------------------------------------------
-- 4. BILLS
-- One row per uploaded/scanned bill (Member 1's OCR pipeline
-- feeds this). Member 5 (frontend) queries this for the
-- dashboard/history view.
-- ------------------------------------------------------------
CREATE TABLE bills (
    bill_id         SERIAL PRIMARY KEY,
    user_id         INTEGER,                 -- FK to a users table if/when auth is added
    store_name      VARCHAR(200),
    bill_date       DATE,
    upload_date     TIMESTAMP DEFAULT NOW(),
    image_path      TEXT,                    -- where Member 1 stored the original image
    raw_ocr_text    TEXT,                    -- full raw OCR dump, for debugging/reprocessing
    total_amount    NUMERIC(10,2),
    total_emission_kg NUMERIC(10,4),         -- filled in by Member 4 after calculation
    status          VARCHAR(30) DEFAULT 'processing'  -- processing | processed | failed
);

CREATE INDEX idx_bills_user ON bills(user_id);
CREATE INDEX idx_bills_date ON bills(bill_date);

-- ------------------------------------------------------------
-- 5. BILL_ITEMS
-- Line items per bill: each product bought, its quantity,
-- and (later) the calculated emissions for that line.
-- This is the table Member 1 writes to after OCR extraction,
-- Member 2 enriches with product_id, and Member 4 fills in
-- emission_kg.
-- ------------------------------------------------------------
CREATE TABLE bill_items (
    item_id             SERIAL PRIMARY KEY,
    bill_id             INTEGER REFERENCES bills(bill_id) ON DELETE CASCADE,
    product_id          INTEGER REFERENCES products(product_id) ON DELETE SET NULL,
    raw_text            VARCHAR(300),        -- original OCR text before matching, e.g. "AMUL TAAZA 500ML"
    matched_confidence  NUMERIC(5,4),        -- Member 2's confidence score (0-1)
    quantity            NUMERIC(10,3) NOT NULL DEFAULT 1,
    unit                VARCHAR(20) DEFAULT 'kg',
    price               NUMERIC(10,2),
    emission_kg         NUMERIC(10,4),       -- quantity * emission_factor, filled by Member 4
    created_at          TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_bill_items_bill ON bill_items(bill_id);
CREATE INDEX idx_bill_items_product ON bill_items(product_id);

-- ============================================================
-- USEFUL VIEW: quick emissions summary per bill
-- Member 4 / Member 5 can query this directly instead of
-- writing joins themselves.
-- ============================================================
CREATE OR REPLACE VIEW bill_emission_summary AS
SELECT
    b.bill_id,
    b.store_name,
    b.bill_date,
    c.category_name,
    SUM(bi.emission_kg) AS category_emission_kg
FROM bills b
JOIN bill_items bi ON bi.bill_id = b.bill_id
JOIN products p ON p.product_id = bi.product_id
JOIN categories c ON c.category_id = p.category_id
GROUP BY b.bill_id, b.store_name, b.bill_date, c.category_name;
