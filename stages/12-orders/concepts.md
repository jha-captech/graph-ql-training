# Stage 12: Orders and Transactions

## What This Stage Teaches

This stage introduces **multi-entity mutations** that span multiple database tables and must execute atomically. You'll learn how to handle transactional consistency, implement snapshot data patterns, compute derived fields, and apply complex authorization rules that involve multiple entities.

The key insight: Real-world mutations aren't simple CRUD operations. Placing an order involves creating an `Order` record, multiple `LineItem` records, checking inventory, snapshotting prices, and ensuring the entire operation succeeds or fails as a unit. This is where GraphQL meets database transactions.

## Why It Matters

E-commerce mutations demonstrate patterns found across all complex domains:

- **Transactional integrity**: All records must be created together, or none at all
- **Snapshot data**: Preserve historical data (unit prices) even when source data changes
- **Computed aggregations**: Order totals calculated from line items
- **Multi-level authorization**: Buyers, sellers, and admins all have different access patterns
- **Data consistency**: Ensure relationships are valid (products exist, inventory is sufficient)

These patterns apply beyond e-commerce: booking systems (reservations + payments), project management (tasks + assignments), healthcare (appointments + prescriptions), etc. The principles you learn here transfer to any domain with complex state changes.

## Mental Models

### The Snapshot Pattern

When an order is placed, we snapshot the product price at that moment:

```
Order placed on Jan 15:
  - Line item: Product A, qty 2, unitPrice: $99.99 (snapshotted)

Product A price updated on Jan 20:
  - New price: $129.99

Order history still shows:
  - Line item: Product A, qty 2, unitPrice: $99.99 (unchanged)
```

Why snapshot? Because the order represents a historical transaction. If the price changes later, the customer isn't retroactively charged more, and financial reports remain accurate.

**What to snapshot:**

- Prices (definitely)
- Product titles (maybe—if you need to show what the customer thought they were buying)
- Tax rates (if they can change)

**What NOT to snapshot:**

- Product IDs (they're immutable references)
- User IDs (ditto)
- Relationships (line items still point to the current Product record)

### The Aggregate Root Pattern

The `Order` is an **aggregate root**—it owns its `LineItem` children. You don't create line items independently; they only exist in the context of an order.

```graphql
# Good: Create order with line items atomically
placeOrder(input: {
  items: [
    { productId: "prod-001", quantity: 2 }
    { productId: "prod-005", quantity: 1 }
  ]
})

# Bad: Create order, then add items separately (race conditions, partial state)
createOrder(input: { ... })  # Returns orderId
addLineItem(orderId: "...", productId: "...", quantity: 2)  # Separate mutation
```

The aggregate pattern ensures orders are always in a valid state. You never have an order with zero items, or line items without an order.

### Transactional Boundaries

A transaction ensures atomicity. The `placeOrder` logic should:

1. Begin a transaction
1. Create the order record
1. For each item, look up the product and create a line item with the snapshotted price
1. Commit the transaction

If any step fails (product not found, database error), the entire transaction rolls back. No orphaned orders or line items.

## Key Concepts

### Multi-Entity Mutations

The `placeOrder` mutation touches three tables:

1. **orders**: Create the order record
1. **line_items**: Create one record per item
1. **products**: Read current prices for snapshotting

This is more complex than single-entity mutations like `createProduct`. It requires:

- Transaction management
- Validation across multiple entities
- Consistent error handling (union errors or top-level errors?)

### Computed Fields

`Order.total` is computed from line items by summing `quantity * unitPrice` across all line items for the order.

**Trade-offs:**

- **Compute on read**: Flexible, always accurate, but requires a query on every access
- **Compute on write**: Store `total` in the `orders` table, update on every mutation
- **Hybrid**: Store the total, recompute if stale (cached aggregate)

For this stage, compute on read. It's simpler and demonstrates resolver patterns. In production, you'd likely store it for performance.

### Authorization Patterns for Orders

Orders introduce multi-party authorization:

**Buyers (CUSTOMER):**

- Can place orders
- Can view their own orders
- Cannot view others' orders

**Sellers:**

- Can view orders that contain their products
- Can update order status (e.g., mark as shipped) for their products' orders
- Cannot place orders as others

**Admins:**

- Can view all orders
- Can update any order status
- Full visibility

This is more nuanced than "admin-only" or "owner-only" patterns from earlier stages.

### The Product-Seller Relationship

Stage 12 adds `Product.seller` (a `User`). This enables:

- Sellers to filter products by ownership
- Authorization checks (sellers can only update their own products)
- Order authorization (sellers see orders containing their products)

The database migration adds `seller_id` to the `products` table.

## Key Questions

1. **How do you ensure placeOrder is atomic?** What happens if creating an order succeeds but creating a line item fails?

1. **Why snapshot unitPrice instead of computing it from Product.price later?** What breaks if you don't snapshot?

1. **How do you validate that products exist and have sufficient inventory before creating line items?**

1. **Should validation errors in placeOrder return a union error or a top-level error?** What's the user experience difference?

1. **How do you compute Order.total efficiently?** Should you use a DataLoader? A database aggregate? Store it in the orders table?

1. **How does authorization work for orders?** How do you check if a user is allowed to view an order?

1. **What happens if a product is deleted after an order is placed?** Should LineItem.product return null, or should product deletion be prevented?

## Official Documentation

- [GraphQL Best Practices - Mutations](https://graphql.org/learn/best-practices/#mutations)
- [Database Transactions](https://en.wikipedia.org/wiki/Database_transaction)
- [Aggregate Pattern (DDD)](https://martinfowler.com/bliki/DDD_Aggregate.html)

## Common Pitfalls

1. **Forgetting transactions**: If you create an order and then fail to create line items, you have an orphaned order. Always use database transactions.

1. **Not snapshotting prices**: If you store `productId` but not `unitPrice`, historical orders show current prices, not what the customer actually paid.

1. **N+1 in computed fields**: If `Order.total` queries line items without DataLoader, paginating orders becomes O(n) queries.

1. **Exposing internal IDs in errors**: "Product prod-xyz not found" leaks that the product might have existed. Generic errors are safer.

1. **Allowing negative quantities**: Validate `quantity > 0` before creating line items.

1. **Not validating product existence**: Always check that `productId` references a real product before creating a line item.

1. **Authorization holes**: A seller shouldn't see orders just because one item is theirs—or should they? Define the business rule clearly.

## What Success Looks Like

After completing this stage:

- You can place an order with multiple line items atomically
- Unit prices are snapshotted at order creation time
- Order totals are computed correctly from line items
- Authorization prevents customers from seeing others' orders
- Sellers can update order status for their products
- Admins have full visibility into all orders
- `Product.seller` resolves correctly
- All operations are transactional—no partial writes

The test suite will verify transactional behavior, authorization rules, and computed fields. Your implementation should handle edge cases (invalid products, empty orders, concurrent updates) gracefully.

## Run Tests

From the repo root:

```bash
STAGE=12 bun run --cwd test-runner test:stage
```
