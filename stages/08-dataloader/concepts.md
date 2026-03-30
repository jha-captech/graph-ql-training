# Stage 08: The N+1 Problem and DataLoader

## What This Stage Teaches

This stage introduces **DataLoader**, the batching and caching pattern that solves GraphQL's notorious N+1 query problem. You won't add new schema types or fields—instead, you'll optimize how your resolvers fetch data. This is a pure performance optimization stage that teaches you how to build production-ready GraphQL servers.

The N+1 problem appears naturally in GraphQL because of its nested resolution model. When you query a list of products with their reviews, a naive implementation queries the database once for products, then once per product for reviews—1 + N queries. DataLoader collapses these into 2 queries: one for products, one batch query for all reviews.

## Why This Problem Exists in GraphQL

GraphQL resolvers are **independent and composable**. The resolver for `Product.reviews` doesn't know if it's being called once or 100 times. It just knows "I'm resolving reviews for this product." When you query 50 products, each with reviews, the `Product.reviews` resolver runs 50 times, each executing a database query.

This is elegant for developer experience—resolvers are simple, single-purpose functions. But it's a performance disaster. DataLoader bridges the gap: resolvers stay simple, but DataLoader batches their work behind the scenes.

## Mental Models

**DataLoader as an Intelligent Deduplicator:** DataLoader collects all the IDs requested within a single tick of the event loop, deduplicates them, and makes a single batch query. It then distributes results back to the original callers in the correct order.

**Per-Request Caching:** DataLoaders are created per-request, not globally. This ensures that within a single GraphQL query, if the same entity is requested multiple times (e.g., two products have the same category), it's fetched once and cached for the remainder of the request. Across requests, no caching occurs (avoiding stale data).

**Batch Functions are Contracts:** The batch function receives an array of keys and must return an array of values in the same order, with the same length. If a key doesn't exist, return `null` in that position. DataLoader trusts this contract—breaking it causes hard-to-debug errors.

**Coalescing, Not Lazy Loading:** DataLoader doesn't delay execution to be lazy. It coalesces requests within a single event loop tick. This is why it must be in the context object, not globally scoped—it needs request-level lifecycle.

## Key Questions

- **How many database queries does `{ products { reviews { author { name } } } }` execute without DataLoader?** Count them.
- **How many queries does the same operation execute with DataLoader?** What changed?
- **Why must DataLoaders be created per-request, not globally?** What breaks if you use a singleton DataLoader?
- **What does the batch function's signature look like?** What are the constraints on its return value?
- **Where do you create DataLoaders?** How do they get passed to resolvers?
- **What's the difference between DataLoader's cache and a shared cache like Redis?** When would you use each?

## Official GraphQL Documentation

- [DataLoader GitHub Repository](https://github.com/graphql/dataloader) - Reference implementation with detailed explanation
- [GraphQL Best Practices - DataLoader](https://graphql.org/learn/best-practices/#dataloader)
- [Solving the N+1 Problem](https://shopify.engineering/solving-the-n-1-problem-for-graphql-through-batching)

## What You're Building

You'll refactor your existing resolvers to use DataLoader for:

1. **Product-to-Category relationships:** Batch load categories for products
1. **Product-to-Review relationships:** Batch load reviews for products
1. **Review-to-User relationships:** Batch load authors for reviews
1. **Review-to-Product relationships:** Batch load products for reviews (if needed)

Your schema remains identical to Stage 07. All tests from previous stages must still pass. The difference is performance: queries that previously executed dozens or hundreds of database queries now execute a handful.

## Testing Approach

The feature files include a **performance test**: a query that fetches all products with reviews and authors must complete within a time threshold (e.g., 500ms for 50+ products). This is only achievable with batching.

Without DataLoader:

- Query 50 products: 1 query
- Query reviews for each: 50 queries
- Query authors for reviews: ~200 queries (if each product has ~4 reviews)
- Total: ~251 queries

With DataLoader:

- Query 50 products: 1 query
- Batch query reviews by product IDs: 1 query
- Batch query authors by user IDs: 1 query
- Total: 3 queries

This is the difference between a timeout and sub-second response.

## Common Pitfalls

- **Creating DataLoaders globally:** Causes cross-request caching and stale data. Always create per-request.
- **Wrong batch function signature:** Must return an array with the same length and order as keys. Forgetting to handle missing keys causes errors.
- **Forgetting to use loaders consistently:** If some resolvers use DataLoader and others don't, you still have N+1 issues.
- **Not awaiting DataLoader promises:** In async runtimes, forgetting `await` breaks batching.

This stage is critical for production readiness. A GraphQL server without DataLoader is a prototype, not a product.

## Run Tests

From the repo root:

```bash
STAGE=08 bun run --cwd test-runner test:stage
```
