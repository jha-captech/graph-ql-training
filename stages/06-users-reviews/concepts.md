# Stage 06: Users and Reviews

## What This Stage Teaches

This stage introduces two new entity types—**Users** and **Reviews**—and weaves them into the existing product catalog. You'll build N:1 relationships (each review has one author, one product) and 1:N relationships (each user has many reviews, each product has many reviews). The stage also introduces computed fields (average rating) and teaches you how to model user-generated content in GraphQL.

This is the first time the schema represents multiple actors in the system. Previously, products and categories existed in isolation. Now you have **users who write reviews about products**. This shift from static catalog data to user-generated content is a critical step toward building real-world applications.

## Why These Types Are Introduced Together

Users and reviews are introduced in the same stage because they're mutually dependent:

- **Users without reviews** are just rows in a database with no meaningful relationships to query.
- **Reviews without users** have no author, making them incomplete and unrealistic.

By introducing them together, you immediately have useful queries: `Product.reviews`, `Review.author`, `User.reviews`. All relationships are active from day one, avoiding the awkwardness of "User exists but you can't query anything useful yet."

This approach mirrors real domain modeling: new features often require multiple types to be useful.

## Mental Models

**Users as First-Class Entities:** Users are no longer implicit (e.g., auth tokens) but are queryable entities in your graph. A `User` type has an ID, name, email, and timestamps—it's a node in the graph just like Product or Category.

**Reviews as Join Entities with Content:** Reviews bridge users and products (N:M relationship), but they're not just a link table—they carry data (rating, body, timestamps). This pattern is common: many-to-many relationships often have attributes (e.g., orders have quantities, friendships have start dates).

**Computed Fields Are Resolver Logic:** `Product.averageRating` doesn't exist in the database as a stored column. It's computed on-the-fly by the resolver, either by querying the database for `AVG(rating)` or by calculating it in code. This is a key GraphQL pattern: the schema exposes fields that abstract away implementation details.

**User-Generated Content Requires Validation:** The `createReview` mutation must validate input (e.g., rating is 1-5, product exists, user is authenticated). Unlike product creation (admin action), reviews are created by end users, so validation and error handling are critical.

## Key Questions

- **How does the resolver for `Review.author` know which user to fetch?** Where does the user ID come from?
- **Should `Product.averageRating` be computed in the resolver or via a database aggregate?** What are the performance tradeoffs?
- **How would you enforce "one review per user per product"?** Database constraint, resolver logic, or both?
- **What happens if a product has no reviews?** Should `averageRating` return `null`, `0`, or something else?
- **How does the `createReview` mutation know which user is the author?** Should the user ID be in the input, or derived from authentication?
- **Why are `createdAt` and `updatedAt` stored as `String!` instead of a DateTime scalar?** What are the tradeoffs?

## Implementation Notes

### graphql-js (JavaScript/TypeScript)
The resolver for `Review.author` receives the review as the parent argument and can access `review.user_id` (or similar) to fetch the user. Use a DataLoader (introduced in Stage 08) to batch author fetches. Computed fields like `Product.averageRating` can use raw SQL (`SELECT AVG(rating)...`) or an ORM aggregate method. For timestamps, store them as ISO 8601 strings or convert from database timestamp types.

### gqlgen (Go)
Generated resolvers for `Review.Author(ctx, obj)` receive the review object. Map the `user_id` field from the database row to fetch the user. For `averageRating`, run a database query or compute in-memory. Use `time.Time` in Go structs and format as RFC3339 strings in resolvers.

### Hot Chocolate (.NET)
Use `[Parent]` attribute in resolvers to access the parent object. For `Review`, the author resolver receives the `Review` object and queries by `UserId`. Computed fields like `averageRating` can be resolver methods on the `Product` class. EF Core supports `.Average()` for aggregates. Timestamps can be `DateTime` in .NET and serialized as ISO 8601 strings.

### Strawberry (Python)
Use `strawberry.field(resolver=...)` for relationships. The resolver function receives the parent object (e.g., `review: Review`) and can access `review.user_id`. For computed fields, define a resolver that queries the database. Use `datetime` objects in Python and serialize them as ISO 8601 strings via `.isoformat()`.

### graphql-java (Java)
DataFetchers for `Review.author` receive the `Review` object via `DataFetchingEnvironment.getSource()`. Cast it to your `Review` class and access the `userId` field. For computed fields, query the database or compute from loaded data. Use `java.time.Instant` or `LocalDateTime` for timestamps and format as ISO 8601 strings.

## Official GraphQL Documentation

- [Schemas and Types - Object Types](https://graphql.org/learn/schema/#object-types)
- [Queries and Mutations - Fields](https://graphql.org/learn/queries/#fields)
- [Execution - Root fields & resolvers](https://graphql.org/learn/execution/)
- [Best Practices - Nullability](https://graphql.org/learn/best-practices/#nullability)

## What You're Building

You'll add two new types to your schema and implement resolvers for:

1. **User queries:** `user(id: ID!)` and `users` (return all users)
2. **User relationships:** `User.reviews` (all reviews written by a user)
3. **Product relationship:** `Product.reviews` (all reviews for a product)
4. **Review relationships:** `Review.author` and `Review.product`
5. **Computed field:** `Product.averageRating` (average of all review ratings)
6. **Mutation:** `createReview(input: CreateReviewInput!)` (create a new review)

Your database now has `users` and `reviews` tables. The seed data (`full.sql`) includes multiple users with different roles and 100+ reviews across 50+ products, giving you realistic data to query.

## Testing Approach

The feature files verify:

- Querying users and traversing to their reviews
- Querying products and traversing to reviews with author details
- Computing average ratings correctly (including edge cases like no reviews)
- Creating reviews and validating the relationships are set correctly
- Enforcing constraints (e.g., rating must be 1-5, product must exist)

This stage establishes the foundation for authentication (Stage 11), where reviews will require the user to be logged in.
