-- base.sql: Products, categories, and product-category links.
-- Used by stages 02-05. Loaded after migrations 1-3.

DELETE FROM product_categories;
DELETE FROM categories;
DELETE FROM products;

-- Categories
INSERT INTO categories (id, name) VALUES
  ('cat-001', 'Electronics'),
  ('cat-002', 'Home & Office'),
  ('cat-003', 'Audio'),
  ('cat-004', 'Accessories');

-- Products (8 items, prices in cents)
INSERT INTO products (id, title, description, price, in_stock, status, created_at, updated_at) VALUES
  ('prod-001', 'Mechanical Keyboard', 'Cherry MX Blue switches, full-size layout with RGB backlighting', 12999, 1, 'ACTIVE', '2025-01-15T10:00:00.000Z', '2025-01-15T10:00:00.000Z'),
  ('prod-002', 'Wireless Mouse', 'Ergonomic design with 6 programmable buttons and USB-C charging', 4999, 1, 'ACTIVE', '2025-01-16T11:30:00.000Z', '2025-01-16T11:30:00.000Z'),
  ('prod-003', 'USB-C Hub', '7-in-1 hub with HDMI, USB-A, SD card reader, and ethernet', 3499, 1, 'ACTIVE', '2025-01-17T09:15:00.000Z', '2025-01-17T09:15:00.000Z'),
  ('prod-004', 'Standing Desk Mat', 'Anti-fatigue comfort mat, 20x34 inches', 4500, 1, 'ACTIVE', '2025-01-18T14:00:00.000Z', '2025-01-18T14:00:00.000Z'),
  ('prod-005', 'Noise Cancelling Headphones', 'Over-ear, 30-hour battery life, active noise cancellation', 24999, 1, 'ACTIVE', '2025-01-19T08:45:00.000Z', '2025-01-19T08:45:00.000Z'),
  ('prod-006', 'Webcam HD 1080p', 'Auto-focus, built-in microphone, privacy shutter', 7999, 0, 'ACTIVE', '2025-01-20T16:20:00.000Z', '2025-01-20T16:20:00.000Z'),
  ('prod-007', 'Monitor Light Bar', 'LED screen light bar, adjustable color temperature', 5999, 1, 'ACTIVE', '2025-01-21T12:00:00.000Z', '2025-01-21T12:00:00.000Z'),
  ('prod-008', 'Cable Management Kit', NULL, 1999, 1, 'DRAFT', '2025-01-22T10:30:00.000Z', '2025-01-22T10:30:00.000Z');

-- Product-Category links
INSERT INTO product_categories (product_id, category_id) VALUES
  ('prod-001', 'cat-001'),
  ('prod-001', 'cat-004'),
  ('prod-002', 'cat-001'),
  ('prod-002', 'cat-004'),
  ('prod-003', 'cat-001'),
  ('prod-003', 'cat-004'),
  ('prod-004', 'cat-002'),
  ('prod-005', 'cat-001'),
  ('prod-005', 'cat-003'),
  ('prod-006', 'cat-001'),
  ('prod-007', 'cat-002'),
  ('prod-008', 'cat-004');
