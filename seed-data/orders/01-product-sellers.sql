-- Assign seller_id to products (requires migration 009_add_seller_id).
-- prod-001..025 → user-003 (Carol), prod-026..050 → user-004 (Dave).

UPDATE products SET seller_id = 'user-003' WHERE id IN (
  'prod-001', 'prod-002', 'prod-003', 'prod-004', 'prod-005',
  'prod-006', 'prod-007', 'prod-008', 'prod-009', 'prod-010',
  'prod-011', 'prod-012', 'prod-013', 'prod-014', 'prod-015',
  'prod-016', 'prod-017', 'prod-018', 'prod-019', 'prod-020',
  'prod-021', 'prod-022', 'prod-023', 'prod-024', 'prod-025'
);

UPDATE products SET seller_id = 'user-004' WHERE id IN (
  'prod-026', 'prod-027', 'prod-028', 'prod-029', 'prod-030',
  'prod-031', 'prod-032', 'prod-033', 'prod-034', 'prod-035',
  'prod-036', 'prod-037', 'prod-038', 'prod-039', 'prod-040',
  'prod-041', 'prod-042', 'prod-043', 'prod-044', 'prod-045',
  'prod-046', 'prod-047', 'prod-048', 'prod-049', 'prod-050'
);
