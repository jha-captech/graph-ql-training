-- +goose Up
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);

-- +goose Down
DROP INDEX IF EXISTS idx_orders_status;
