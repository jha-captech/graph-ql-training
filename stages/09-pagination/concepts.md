# Stage 09: Pagination

## What This Stage Teaches

This stage introduces **cursor-based pagination** following the Relay Connection specification. You'll learn why traditional offset/limit pagination breaks in distributed systems and how cursor-based pagination provides stable, consistent results even as data changes underneath.

The key insight: pagination isn't just about splitting large lists into pages—it's about creating a stable window into a dataset that may be constantly changing. Cursors act as bookmarks that remain valid even when items are inserted or deleted.

## Why It Matters

Real production GraphQL APIs rarely return entire collections. The 50 products in our seed data are tiny compared to real-world catalogs with thousands or millions of items. Without pagination:

- Clients download massive payloads they don't need
- Servers waste memory assembling huge result sets
- Network bandwidth is consumed unnecessarily
- Response times become unpredictable

More importantly, **offset pagination breaks** in the presence of concurrent writes. If a client requests page 2 (items 11-20) and someone deletes item 5 while that request is in flight, the client sees duplicate or missing items. Cursor-based pagination is immune to this problem because cursors are tied to specific items, not positions.

## Mental Models

### The Bookmark Analogy

Think of cursors as bookmarks in a physical book. If someone tears out a page before your bookmark, your bookmark still points to the right spot—it doesn't suddenly jump backward. Similarly, if pages are added, your bookmark doesn't move. Cursors work the same way: they reference specific items, not positions.

### The Connection Pattern

The Relay Connection spec wraps paginated data in a structured envelope:

```
ProductConnection
├── edges: [ProductEdge!]!         # The actual data + cursors
│   └── node: Product!             # The product itself
│   └── cursor: String!            # Opaque bookmark for this item
├── pageInfo: PageInfo!            # Navigation metadata
│   ├── hasNextPage: Boolean!      # Can we go forward?
│   ├── hasPreviousPage: Boolean!  # Can we go backward?
│   ├── startCursor: String        # First item's cursor
│   └── endCursor: String          # Last item's cursor
└── totalCount: Int!               # Total items matching filter
```

Why the `edges` layer? It allows each item to carry its own cursor. This becomes essential for bidirectional pagination—you need to know which cursor to use for the `before` or `after` arguments.

## Key Concepts

### Cursor Encoding

Cursors must be **opaque** (clients should not parse or construct them). Common implementations:

- **Base64-encoded ID**: `base64("Product:prod-025")` → `"UHJvZHVjdDpwcm9kLTAyNQ=="`
- **Compound keys**: `base64(JSON.stringify({id: "prod-025", createdAt: "2024-01-15T10:30:00Z"}))`
- **Encrypted tokens**: For additional security, encrypt the cursor contents

The test suite expects cursors to be strings. Beyond that, the implementation is up to you.

### Forward vs. Backward Pagination

- **Forward**: `first: 10, after: "cursor_X"` → "Give me 10 items after X"
- **Backward**: `last: 10, before: "cursor_Y"` → "Give me 10 items before Y"

Most applications only need forward pagination. Backward pagination is useful for "scroll to bottom" use cases or when building infinite scroll that works in both directions.

### Filtering + Pagination

The `filter` argument applies **before** pagination. The `totalCount` reflects the filtered set, not the entire table. This means:

```graphql
productsConnection(
  first: 10
  filter: { categoryId: "cat-001", minPrice: 1000 }
) {
  totalCount  # Number of products in category cat-001 with price >= 1000
  edges { node { title } }
}
```

Filters must be stable across pagination requests. If a client passes `minPrice: 1000` for page 1, they must pass the same filter for page 2.

## Database Implementation Notes

**Cursor-based pagination with SQL:**

If your cursor is the product ID and you're sorting by `createdAt DESC`:

```sql
SELECT * FROM products
WHERE created_at < :cursor_created_at
   OR (created_at = :cursor_created_at AND id < :cursor_id)
ORDER BY created_at DESC, id DESC
LIMIT :limit
```

You need a compound sort (timestamp + ID) to ensure deterministic ordering when multiple items have the same timestamp. Without the secondary sort on `id`, pagination results become unstable.

**Indexes matter:**

For efficient cursor pagination, create an index on your sort columns:

```sql
CREATE INDEX idx_products_pagination ON products(created_at DESC, id DESC);
```

Without this index, the database performs a full table scan for every page request.

## Key Questions

1. **Why are cursors better than offset/limit pagination?** What happens when items are inserted or deleted between page requests?

1. **What happens if a client passes an invalid or tampered cursor?** How should your resolver handle it?

1. **Why does the Connection spec include both `edges` and `nodes`?** When would you query just `nodes` vs. `edges`?

1. **How do you implement `hasPreviousPage` and `hasNextPage`?** Do you query for `limit + 1` items to check if more exist?

1. **What does `totalCount` represent?** Does it count all products in the database, or just those matching the filter?

1. **How do you handle backward pagination (`last` + `before`)?** Does your SQL query reverse the sort order?

## Official Documentation

- [GraphQL Pagination Best Practices](https://graphql.org/learn/pagination/)
- [Relay Cursor Connections Specification](https://relay.dev/graphql/connections.htm)
- [Relay Global Object Identification](https://relay.dev/graphql/objectidentification.htm)

## Common Pitfalls

1. **Non-deterministic ordering**: If you sort by a non-unique column (like `price`) without a secondary sort, pagination results become unstable. Always include a unique field (like `id`) in your `ORDER BY` clause.

1. **Forgetting to filter totalCount**: The `totalCount` field must respect the `filter` input. Don't just return `SELECT COUNT(*) FROM products`.

1. **Exposing raw IDs as cursors**: Clients might be tempted to manipulate unencoded cursors. Always encode (at minimum) or encrypt them.

1. **Inefficient hasNextPage checks**: Don't run a separate query to check if more pages exist. Instead, fetch `limit + 1` items and check if you got the extra one.

1. **Breaking cursor format**: Once you ship a cursor encoding format, changing it breaks existing clients who bookmarked cursors. Version your cursor format if you need to change it.

## What Success Looks Like

After completing this stage:

- You can paginate through all 50 products without missing or duplicating items
- Cursors remain valid even if products are added or deleted
- Filters combine correctly with pagination
- `pageInfo` accurately reflects navigation state
- `totalCount` reflects the filtered set, not the entire database

The test suite will verify all of these behaviors. Your implementation should pass all scenarios before moving to the next stage.

## Run Tests

From the repo root:

```bash
STAGE=09 bun run --cwd test-runner test:stage
```
