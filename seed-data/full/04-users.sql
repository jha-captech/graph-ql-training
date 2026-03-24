-- 8 users: 4 CUSTOMER, 2 SELLER, 2 ADMIN.

INSERT INTO users (id, email, name, role, created_at, updated_at) VALUES
  ('user-001', 'alice@example.com',   'Alice Johnson',   'CUSTOMER', '2025-01-01T09:00:00.000Z', '2025-01-01T09:00:00.000Z'),
  ('user-002', 'bob@example.com',     'Bob Smith',       'CUSTOMER', '2025-01-02T10:00:00.000Z', '2025-01-02T10:00:00.000Z'),
  ('user-003', 'carol@example.com',   'Carol Williams',  'SELLER',   '2025-01-03T11:00:00.000Z', '2025-01-03T11:00:00.000Z'),
  ('user-004', 'dave@example.com',    'Dave Brown',      'SELLER',   '2025-01-04T12:00:00.000Z', '2025-01-04T12:00:00.000Z'),
  ('user-005', 'eve@example.com',     'Eve Davis',       'ADMIN',    '2025-01-05T08:00:00.000Z', '2025-01-05T08:00:00.000Z'),
  ('user-006', 'frank@example.com',   'Frank Miller',    'CUSTOMER', '2025-01-06T14:00:00.000Z', '2025-01-06T14:00:00.000Z'),
  ('user-007', 'grace@example.com',   'Grace Wilson',    'CUSTOMER', '2025-01-07T15:00:00.000Z', '2025-01-07T15:00:00.000Z'),
  ('user-008', 'hank@example.com',    'Hank Taylor',     'ADMIN',    '2025-01-08T09:30:00.000Z', '2025-01-08T09:30:00.000Z');
