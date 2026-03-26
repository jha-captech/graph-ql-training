# Stage 04: Mutations and Input Types

## What This Stage Teaches

This stage introduces mutations: how to modify data in GraphQL. You'll learn about input types (the mutation equivalent of query arguments), payload types (structured mutation responses), and why mutations are executed serially at the top level. This is where GraphQL becomes a full CRUD API—not just reading data, but creating, updating, and deleting it.

## Why It Matters

**Mutations are semantically different from queries.** While queries are read-only and can be executed in parallel, mutations have side effects and must execute in a guaranteed order. If a client sends `mutation { createProduct(...) updateProduct(...) }`, those operations run serially, left to right. This prevents race conditions and gives clients predictable behavior.

**Input types are GraphQL's way of grouping mutation arguments.** Instead of `createProduct(title: String!, price: Float!, description: String)` with a dozen arguments, you write `createProduct(input: CreateProductInput!)` where the input is a structured object. This is cleaner, extensible (you can add fields to the input without changing the mutation signature), and plays nicely with GraphQL's type system.

**Payload types wrap mutation results.** Instead of returning the entity directly (`createProduct(...): Product`), best practice is to return a payload type (`CreateProductPayload { product: Product }`). This gives you room to evolve: add validation errors, metadata, or related data without breaking clients. Stage 10 expands this pattern with union-based error handling.

## Mental Models

**Mutations as Commands**: Think of mutations like commands in CQRS or methods in an OOP service layer. Each mutation is a named operation that does one thing. `createProduct`, `updateProduct`, `deleteProduct`—each is explicit and focused. This contrasts with REST's overloaded POST/PUT/PATCH where the semantics are implicit.

**Input Types as DTOs**: In traditional backend architecture, DTOs (Data Transfer Objects) carry data across boundaries. Input types are GraphQL's DTOs. They're validated by the GraphQL engine before your resolver runs. If a client sends `createProduct(input: { title: 123 })`, they get a validation error immediately—your resolver never sees invalid data.

**Payload Types as Response Envelopes**: The payload is an envelope around the result. Right now it's simple: `{ product: Product }`. Later you'll add `{ product: Product, errors: [Error] }` or `{ product: Product, userErrors: [UserError] }`. The pattern scales as your API evolves.

## Key Questions

After completing this stage, you should be able to answer:

1. **What's the difference between a query and a mutation?** (Queries are read-only and can run in parallel; mutations have side effects and run serially at the top level)

1. **Why use `CreateProductInput` instead of individual arguments like `title: String!`, `price: Float!`?** (Grouping arguments into input types is cleaner, extensible, and easier to validate)

1. **What's the difference between `input` and `type` in SDL?** (Input types can only contain scalars, enums, and other input types—no object types or interfaces. They're for input, not output)

1. **Why are all fields in `UpdateProductInput` optional?** (Because you want partial updates—clients only send fields they're changing)

1. **Why do mutations return payload types instead of the entity directly?** (Room to evolve: add errors, metadata, or related data without breaking clients)

1. **What should happen if a client tries to create a product with invalid data?** (Return an error—either in the top-level `errors` array, or as a union member in the payload. Stage 10 covers this pattern)

1. **How do you link a product to categories in `createProduct`?** (The `categoryIds` field in the input; your resolver inserts rows into the join table)

1. **If a mutation fails halfway through (e.g., database error), what should the response look like?** (Return an error in the `errors` array; optionally roll back the transaction)

## Links to Official Documentation

- [Mutations](https://graphql.org/learn/queries/#mutations) — How mutations work from the client side
- [Input Types](https://graphql.org/graphql-js/mutations-and-input-types/) — Defining input types for mutations
- [Schemas and Types](https://graphql.org/learn/schema/#input-types) — Input types vs. object types
- [Best Practices - Mutations](https://graphql.org/learn/best-practices/#mutations) — Mutation design patterns

## What You're Building

A server that:

1. Adds a `Mutation` root type with two mutations: `createProduct` and `updateProduct`
1. Defines input types:
   - `CreateProductInput` with required fields: `title`, `price`, and optional: `description`, `categoryIds`
   - `UpdateProductInput` with all optional fields: `title`, `description`, `price`, `status`
1. Defines payload types:
   - `CreateProductPayload { product: Product }`
   - `UpdateProductPayload { product: Product }`
1. Implements mutation resolvers:
   - `createProduct`: inserts a new product, links it to categories if `categoryIds` provided, returns the created product
   - `updateProduct`: updates an existing product by ID, returns the updated product
1. Handles errors gracefully (non-existent IDs, validation failures)

The database is set up with migrations and seed data from stage 03. Your mutations modify this data. Remember to handle the many-to-many relationship: when creating/updating a product with `categoryIds`, insert/update rows in the `product_categories` join table.

You're NOT required to implement `deleteProduct` for this stage—two mutations are enough to teach the pattern. But feel free to add it as an exercise!

## Run Tests

From the repo root:

```bash
STAGE=04 bun run --cwd test-runner test:stage
```
