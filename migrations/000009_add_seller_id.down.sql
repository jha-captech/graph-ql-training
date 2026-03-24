-- SQLite does not support DROP COLUMN before 3.35.0.
-- For broad compatibility, recreate the table without seller_id.
CREATE TABLE products_backup (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT,
    price INTEGER NOT NULL,
    in_stock INTEGER NOT NULL DEFAULT 1,
    status TEXT NOT NULL DEFAULT 'DRAFT' CHECK (status IN ('DRAFT', 'ACTIVE', 'ARCHIVED')),
    created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now')),
    updated_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%fZ', 'now'))
);

INSERT INTO products_backup SELECT id, title, description, price, in_stock, status, created_at, updated_at FROM products;
DROP TABLE products;
ALTER TABLE products_backup RENAME TO products;

CREATE INDEX IF NOT EXISTS idx_products_status ON products(status);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at);
CREATE INDEX IF NOT EXISTS idx_products_price ON products(price);

DROP INDEX IF EXISTS idx_products_seller_id;
