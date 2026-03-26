-- +goose Up
CREATE TABLE IF NOT EXISTS pricing (
    product_id TEXT PRIMARY KEY REFERENCES products(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    compare_at_amount INTEGER
);

-- +goose Down
DROP TABLE IF EXISTS pricing;
