-- ============================================================
-- SEED DATA — sample categories, products, emission factors
-- Replace/extend with real data from a proper source such as
-- DEFRA, IPCC, or a published lifecycle-assessment dataset.
-- ============================================================

-- Categories
INSERT INTO categories (category_name, description) VALUES
('Dairy',        'Milk, curd, cheese, paneer, ghee'),
('Grains & Staples', 'Rice, wheat, flour, pulses'),
('Vegetables',   'Fresh vegetables'),
('Fruits',       'Fresh fruits'),
('Meat & Poultry', 'Chicken, mutton, eggs'),
('Beverages',    'Tea, coffee, soft drinks, juices'),
('Packaged Snacks', 'Chips, biscuits, namkeen'),
('Household',    'Cleaning and personal care products');

-- Products (linked to categories)
INSERT INTO products (product_name, category_id, unit, aliases) VALUES
('Milk',       (SELECT category_id FROM categories WHERE category_name='Dairy'), 'litre', ARRAY['toned milk','full cream milk']),
('Paneer',     (SELECT category_id FROM categories WHERE category_name='Dairy'), 'kg', ARRAY['cottage cheese']),
('Rice',       (SELECT category_id FROM categories WHERE category_name='Grains & Staples'), 'kg', ARRAY['basmati rice','chawal']),
('Wheat Flour',(SELECT category_id FROM categories WHERE category_name='Grains & Staples'), 'kg', ARRAY['atta']),
('Tomato',     (SELECT category_id FROM categories WHERE category_name='Vegetables'), 'kg', ARRAY['tamatar']),
('Potato',     (SELECT category_id FROM categories WHERE category_name='Vegetables'), 'kg', ARRAY['aloo']),
('Banana',     (SELECT category_id FROM categories WHERE category_name='Fruits'), 'kg', ARRAY['kela']),
('Chicken',    (SELECT category_id FROM categories WHERE category_name='Meat & Poultry'), 'kg', ARRAY['chicken breast']),
('Eggs',       (SELECT category_id FROM categories WHERE category_name='Meat & Poultry'), 'piece', ARRAY['anda']),
('Tea',        (SELECT category_id FROM categories WHERE category_name='Beverages'), 'kg', ARRAY['chai patti']);

-- Emission factors (kg CO2e per unit) — illustrative example values.
-- Swap these for values from a cited real dataset before final submission.
INSERT INTO emission_factors (product_id, co2e_per_unit, unit, source) VALUES
((SELECT product_id FROM products WHERE product_name='Milk'),        1.30, 'litre', 'Sample/DEFRA-style'),
((SELECT product_id FROM products WHERE product_name='Paneer'),      8.60, 'kg',    'Sample/DEFRA-style'),
((SELECT product_id FROM products WHERE product_name='Rice'),        2.70, 'kg',    'Sample/DEFRA-style'),
((SELECT product_id FROM products WHERE product_name='Wheat Flour'), 0.90, 'kg',    'Sample/DEFRA-style'),
((SELECT product_id FROM products WHERE product_name='Tomato'),      0.40, 'kg',    'Sample/DEFRA-style'),
((SELECT product_id FROM products WHERE product_name='Potato'),      0.30, 'kg',    'Sample/DEFRA-style'),
((SELECT product_id FROM products WHERE product_name='Banana'),      0.70, 'kg',    'Sample/DEFRA-style'),
((SELECT product_id FROM products WHERE product_name='Chicken'),     6.90, 'kg',    'Sample/DEFRA-style'),
((SELECT product_id FROM products WHERE product_name='Eggs'),        0.24, 'piece', 'Sample/DEFRA-style'),
((SELECT product_id FROM products WHERE product_name='Tea'),         3.50, 'kg',    'Sample/DEFRA-style');

-- Fallback category-level emission factors (used when Member 2 can't
-- match a specific product but does know the category)
INSERT INTO emission_factors (category_id, co2e_per_unit, unit, source) VALUES
((SELECT category_id FROM categories WHERE category_name='Packaged Snacks'), 2.00, 'kg', 'Category average estimate'),
((SELECT category_id FROM categories WHERE category_name='Household'),       1.50, 'kg', 'Category average estimate');

-- A sample bill + items, so Members 4 and 5 have something to test against
INSERT INTO bills (store_name, bill_date, total_amount, status) VALUES
('Sample Mart', CURRENT_DATE, 450.00, 'processed');

INSERT INTO bill_items (bill_id, product_id, raw_text, matched_confidence, quantity, unit, price) VALUES
((SELECT bill_id FROM bills WHERE store_name='Sample Mart'),
 (SELECT product_id FROM products WHERE product_name='Milk'), 'AMUL MILK 1L', 0.95, 2, 'litre', 60.00),
((SELECT bill_id FROM bills WHERE store_name='Sample Mart'),
 (SELECT product_id FROM products WHERE product_name='Rice'), 'INDIA GATE RICE 5KG', 0.90, 5, 'kg', 350.00),
((SELECT bill_id FROM bills WHERE store_name='Sample Mart'),
 (SELECT product_id FROM products WHERE product_name='Eggs'), 'FARM EGGS 12PC', 0.88, 12, 'piece', 84.00);
