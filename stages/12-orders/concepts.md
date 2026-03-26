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

A transaction ensures atomicity:

```typescript
async function placeOrder(input, context) {
  return context.db.transaction(async (tx) => {
    // All of these must succeed, or all fail
    const order = await tx.orders.create({ buyerId: context.user.id });
    for (const item of input.items) {
      const product = await tx.products.findById(item.productId);
      if (!product) throw new Error("Product not found");
      await tx.lineItems.create({
        orderId: order.id,
        productId: product.id,
        quantity: item.quantity,
        unitPrice: product.price, // Snapshot
      });
    }
    return order;
  });
}
```

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

`Order.total` is computed from line items:

```typescript
Order: {
  total: async (order, args, context) => {
    const items = await context.dataloaders.lineItemsByOrderId.load(order.id);
    return items.reduce((sum, item) => sum + item.quantity * item.unitPrice, 0);
  };
}
```

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

## Implementation Notes by Framework

### graphql-js (TypeScript/JavaScript)

Use your database client's transaction API:

```typescript
// Prisma example
const order = await prisma.$transaction(async (tx) => {
  const order = await tx.order.create({
    data: { buyerId: context.user.id, status: "PENDING" },
  });

  for (const item of input.items) {
    const product = await tx.product.findUnique({
      where: { id: item.productId },
    });
    if (!product) throw new Error("Product not found");

    await tx.lineItem.create({
      data: {
        orderId: order.id,
        productId: product.id,
        quantity: item.quantity,
        unitPrice: product.price,
      },
    });
  }

  return order;
});
```

For SQLite with raw SQL:

```typescript
await db.run("BEGIN TRANSACTION");
try {
  // Insert order
  // Insert line items
  await db.run("COMMIT");
} catch (err) {
  await db.run("ROLLBACK");
  throw err;
}
```

### gqlgen (Go)

Use `database/sql` transactions:

```go
tx, err := db.Begin()
if err != nil {
    return nil, err
}
defer tx.Rollback()

// Create order
result, err := tx.Exec("INSERT INTO orders (buyer_id, status) VALUES (?, ?)", userID, "PENDING")
if err != nil {
    return nil, err
}
orderID, _ := result.LastInsertId()

// Create line items
for _, item := range input.Items {
    _, err := tx.Exec("INSERT INTO line_items (order_id, product_id, quantity, unit_price) VALUES (?, ?, ?, ?)",
        orderID, item.ProductID, item.Quantity, unitPrice)
    if err != nil {
        return nil, err
    }
}

if err := tx.Commit(); err != nil {
    return nil, err
}
```

### Strawberry (Python)

Use your ORM's transaction support:

```python
@strawberry.mutation
async def place_order(
    self,
    input: PlaceOrderInput,
    info: strawberry.Info
) -> PlaceOrderResult:
    async with info.context.db.transaction():
        order = await Order.create(
            buyer_id=info.context.user.id,
            status=OrderStatus.PENDING
        )

        for item in input.items:
            product = await Product.get(id=item.product_id)
            if not product:
                return ValidationError(
                    message="Product not found",
                    field="productId",
                    code="NOT_FOUND"
                )

            await LineItem.create(
                order_id=order.id,
                product_id=product.id,
                quantity=item.quantity,
                unit_price=product.price
            )

        return PlaceOrderSuccess(order=order)
```

### Hot Chocolate (.NET)

Use Entity Framework transactions:

```csharp
using (var transaction = await context.Database.BeginTransactionAsync()) {
    try {
        var order = new Order {
            BuyerId = user.Id,
            Status = OrderStatus.Pending
        };
        context.Orders.Add(order);
        await context.SaveChangesAsync();

        foreach (var item in input.Items) {
            var product = await context.Products.FindAsync(item.ProductId);
            if (product == null) {
                throw new GraphQLException("Product not found");
            }

            context.LineItems.Add(new LineItem {
                OrderId = order.Id,
                ProductId = product.Id,
                Quantity = item.Quantity,
                UnitPrice = product.Price
            });
        }

        await context.SaveChangesAsync();
        await transaction.CommitAsync();
        return new PlaceOrderSuccess { Order = order };
    } catch {
        await transaction.RollbackAsync();
        throw;
    }
}
```

### graphql-java (Java/Kotlin)

Use JDBC transactions:

```java
Connection conn = dataSource.getConnection();
conn.setAutoCommit(false);
try {
    // Insert order
    PreparedStatement orderStmt = conn.prepareStatement(
        "INSERT INTO orders (buyer_id, status) VALUES (?, ?)",
        Statement.RETURN_GENERATED_KEYS
    );
    orderStmt.setString(1, userId);
    orderStmt.setString(2, "PENDING");
    orderStmt.executeUpdate();

    ResultSet rs = orderStmt.getGeneratedKeys();
    rs.next();
    long orderId = rs.getLong(1);

    // Insert line items
    PreparedStatement itemStmt = conn.prepareStatement(
        "INSERT INTO line_items (order_id, product_id, quantity, unit_price) VALUES (?, ?, ?, ?)"
    );
    for (OrderItemInput item : input.getItems()) {
        itemStmt.setLong(1, orderId);
        itemStmt.setString(2, item.getProductId());
        itemStmt.setInt(3, item.getQuantity());
        itemStmt.setDouble(4, getProductPrice(item.getProductId()));
        itemStmt.executeUpdate();
    }

    conn.commit();
    return findOrderById(orderId);
} catch (Exception e) {
    conn.rollback();
    throw e;
} finally {
    conn.setAutoCommit(true);
}
```

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
