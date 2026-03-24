CREATE TABLE IF NOT EXISTS product_categories (
    product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    category_id TEXT NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    PRIMARY KEY (product_id, category_id)
);
