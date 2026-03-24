# Stage 02: Types, Enums, and Your First Real Type

## What This Stage Teaches

This stage introduces GraphQL's type system: the five built-in scalars, object types, enums, and the non-null/list modifiers. You'll connect to a SQLite database and build a real entity—`Product`—with multiple fields of different types. This is where GraphQL becomes practical: you're no longer returning hardcoded strings, but actual data from persistent storage.

## Why It Matters

**The type system is GraphQL's superpower.** Every field has a declared type, and the server validates queries before execution. This eliminates entire classes of runtime errors. If a client tries to query a field that doesn't exist or passes the wrong type for an argument, they get a clear error before any resolver runs.

Enums are GraphQL's way of representing finite sets of values. Unlike strings (which can be anything), an enum field can only be one of the declared values. This makes your API self-documenting and prevents invalid state at the type level.

SQLite from day one teaches you the real-world pattern: GraphQL resolvers fetch data from a database. The context object (one of the four resolver arguments) is where you store shared resources like database connections. This architecture scales from SQLite to Postgres to microservices—the resolver pattern stays the same.

## Mental Models

**Object Types as Entities**: Think of each `type` in GraphQL as a table in a database or a domain entity in your application. The `Product` type represents the product entity. Its fields are the columns or properties. But unlike REST, clients can request only the fields they need—no overfetching.

**Non-Null as a Promise**: The `!` modifier means "I promise this field will never be null." If a resolver returns null for a `String!` field, GraphQL propagates that error upward to the nearest nullable parent. This forces you to think explicitly about what can and cannot be absent.

**Enums as State Machines**: The `ProductStatus` enum defines the valid states a product can be in: `DRAFT`, `ACTIVE`, or `ARCHIVED`. This isn't just documentation—the GraphQL engine enforces it. If you try to return `"DELETED"` for a `ProductStatus!` field, you get a validation error.

## Key Questions

After completing this stage, you should be able to answer:

1. **What are the five built-in scalar types in GraphQL?** (ID, String, Int, Float, Boolean)
2. **What's the difference between `String` and `String!`?** What happens if a resolver returns null for each?
3. **Why is `description` nullable but `title` non-null?** (Hint: think about what's essential vs. optional)
4. **What's the difference between the `ID` and `String` scalars?** (They serialize the same way, but ID has semantic meaning)
5. **What are the four arguments every resolver receives?** (parent/root, args, context, info)
6. **Where should the database connection live?** (In the context object, not global state)
7. **What happens when a client queries `product(id: "nonexistent")`?** (Should return null, not an error)
8. **What's the difference between returning `null` and throwing an error in a resolver?**

## Implementation Notes by Framework

**graphql-js (TypeScript/JavaScript)**:
- Enums are defined with `GraphQLEnumType` or in SDL with `enum ProductStatus { ... }`
- Resolvers receive `(parent, args, context, info)` as arguments
- Put your database connection in context: `context: { db: sqliteConnection }`
- Non-null is `new GraphQLNonNull(GraphQLString)` or `String!` in SDL

**gqlgen (Go)**:
- Enums in SDL generate Go `const` declarations
- Resolvers are methods on your resolver struct
- Store DB in resolver struct: `type Resolver struct { DB *sql.DB }`
- Use `sql.NullString` for nullable fields like `description`

**Hot Chocolate (.NET)**:
- Enums are C# enums with `[GraphQLType]` attribute
- Resolvers are methods on your query class or separate resolver classes
- Inject dependencies (like DB context) via constructor or `[Service]` parameters
- Nullable fields: use `string?` in C# 8+

**Strawberry (Python)**:
- Enums are `strawberry.enum` wrapping Python `Enum` classes
- Resolvers are methods on your type class or standalone functions with `@strawberry.field`
- Pass DB connection via `strawberry.types.Info.context`
- Nullable fields: use `Optional[str]` type hints

**graphql-java (Java)**:
- Enums: `GraphQLEnumType.newEnum().name("ProductStatus").value("DRAFT")...build()`
- Resolvers are `DataFetcher<Product>` implementations
- Store DB connection in `DataFetchingEnvironment.getContext()`
- Nullable fields: use nullable types or Optional<String>

## Links to Official Documentation

- [Schemas and Types](https://graphql.org/learn/schema/) — Core type system concepts
- [Queries and Mutations](https://graphql.org/learn/queries/) — How field arguments work
- [Execution](https://graphql.org/learn/execution/) — Resolver signature and behavior
- [GraphQL Scalars](https://graphql.org/learn/schema/#scalar-types) — The five built-in types
- [Enums](https://graphql.org/learn/schema/#enumeration-types) — Finite value sets

## Connecting to the Database

Your server needs to connect to a SQLite database file. The file path is set by the `DB_FILE` environment variable (default: `graphql_training.db` in the project root). Run `task db:reset STAGE=02` to create and seed it.

Pass the database connection through GraphQL's **context object** so all resolvers can access it:

```typescript
// TypeScript/JavaScript example
import Database from 'better-sqlite3';
const db = new Database(process.env.DB_FILE || 'graphql_training.db');

// Pass db via context to all resolvers
const server = new ApolloServer({
  schema,
  context: () => ({ db })
});
```

```go
// Go example
db, _ := sql.Open("sqlite3", os.Getenv("DB_FILE"))
```

```python
# Python example
import sqlite3
db = sqlite3.connect(os.environ.get("DB_FILE", "graphql_training.db"))
```

**Important**: Prices in the database are stored as **integers in cents** (e.g., `12999` = $129.99). The schema defines `price: Float!`, so your resolver returns the raw integer value. Don't convert to dollars — the test suite expects cent values.

## What You're Building

A server that:
1. Connects to a SQLite database (created and seeded via `task db:reset STAGE=02`)
2. Reads the database path from the `DB_FILE` environment variable
3. Defines a `Product` type with fields: `id`, `title`, `description`, `price`, `inStock`, `status`
4. Defines a `ProductStatus` enum with values: `DRAFT`, `ACTIVE`, `ARCHIVED`
5. Implements resolvers for:
   - `Query.products: [Product!]!` — returns all products from the database
   - `Query.product(id: ID!): Product` — returns a single product by ID, or null if not found
6. Handles nullable fields correctly (e.g., `description` can be null, but `title` cannot)

The database is already set up with migrations and seed data. Your job is to read from it and expose it through GraphQL. This is the pattern you'll use for every stage: database → resolver → GraphQL response.
