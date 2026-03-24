ALTER TABLE products ADD COLUMN seller_id TEXT REFERENCES users(id);

CREATE INDEX IF NOT EXISTS idx_products_seller_id ON products(seller_id);
