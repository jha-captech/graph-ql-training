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

2. **What happens if a client passes an invalid or tampered cursor?** How should your resolver handle it?

3. **Why does the Connection spec include both `edges` and `nodes`?** When would you query just `nodes` vs. `edges`?

4. **How do you implement `hasPreviousPage` and `hasNextPage`?** Do you query for `limit + 1` items to check if more exist?

5. **What does `totalCount` represent?** Does it count all products in the database, or just those matching the filter?

6. **How do you handle backward pagination (`last` + `before`)?** Does your SQL query reverse the sort order?

## Implementation Notes by Framework

### graphql-js (TypeScript/JavaScript)

The `ProductConnection` type is just a regular GraphQL object type. Implement the `productsConnection` resolver to:

1. Decode the `after`/`before` cursor to get the reference item
2. Build a SQL query with `WHERE` and `LIMIT` clauses
3. Map results to `edges` (each with its own cursor)
4. Compute `pageInfo` fields by checking if more items exist
5. Compute `totalCount` with a separate `COUNT(*)` query

### gqlgen (Go)

Define resolver methods on `queryResolver` for `ProductsConnection`. Use a helper function to encode/decode cursors:

```go
func encodeCursor(id string) string {
    return base64.StdEncoding.EncodeToString([]byte(id))
}
```

Implement `hasNextPage` by fetching `first + 1` items and checking if you got more than requested.

### Strawberry (Python)

Use Strawberry's `@strawberry.type` for `ProductConnection`, `ProductEdge`, and `PageInfo`. The resolver can return a dictionary or a dataclass:

```python
@strawberry.field
def products_connection(
    self,
    first: Optional[int] = None,
    after: Optional[str] = None,
    filter: Optional[ProductFilterInput] = None
) -> ProductConnection:
    # Decode cursor, query database, build connection object
```

### Hot Chocolate (.NET)

Hot Chocolate has built-in pagination support via `[UsePaging]` attribute, but implementing Relay-style connections manually gives you more control:

```csharp
[GraphQLType("ProductConnection")]
public class ProductConnection {
    public List<ProductEdge> Edges { get; set; }
    public PageInfo PageInfo { get; set; }
    public int TotalCount { get; set; }
}
```

### graphql-java (Java/Kotlin)

Implement a `DataFetcher<ProductConnection>` that builds the connection object from database results. Use `CompletableFuture` for async database queries if using a reactive driver.

## Official Documentation

- [GraphQL Pagination Best Practices](https://graphql.org/learn/pagination/)
- [Relay Cursor Connections Specification](https://relay.dev/graphql/connections.htm)
- [Relay Global Object Identification](https://relay.dev/graphql/objectidentification.htm)

## Common Pitfalls

1. **Non-deterministic ordering**: If you sort by a non-unique column (like `price`) without a secondary sort, pagination results become unstable. Always include a unique field (like `id`) in your `ORDER BY` clause.

2. **Forgetting to filter totalCount**: The `totalCount` field must respect the `filter` input. Don't just return `SELECT COUNT(*) FROM products`.

3. **Exposing raw IDs as cursors**: Clients might be tempted to manipulate unencoded cursors. Always encode (at minimum) or encrypt them.

4. **Inefficient hasNextPage checks**: Don't run a separate query to check if more pages exist. Instead, fetch `limit + 1` items and check if you got the extra one.

5. **Breaking cursor format**: Once you ship a cursor encoding format, changing it breaks existing clients who bookmarked cursors. Version your cursor format if you need to change it.

## What Success Looks Like

After completing this stage:

- You can paginate through all 50 products without missing or duplicating items
- Cursors remain valid even if products are added or deleted
- Filters combine correctly with pagination
- `pageInfo` accurately reflects navigation state
- `totalCount` reflects the filtered set, not the entire database

The test suite will verify all of these behaviors. Your implementation should pass all scenarios before moving to the next stage.
