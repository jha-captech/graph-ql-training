# Stage 15: Custom Scalars, Directives, and Schema Evolution

## What This Stage Teaches

GraphQL's built-in scalars (`Int`, `Float`, `String`, `Boolean`, `ID`) are deliberately minimal. Real applications need domain-specific types like `DateTime`, `EmailAddress`, `Money`, and `URL`. Custom scalars provide **validation, serialization, and semantic clarity** at the type level, reducing boilerplate in resolvers and improving client safety.

This stage also introduces **custom directives** (`@auth`, `@cacheControl`) and teaches **versionless schema evolution**—how to add new types, deprecate old fields, and evolve your API without breaking existing clients.

You'll replace generic `String!` fields with typed scalars (`createdAt: DateTime!`, `email: EmailAddress!`), add a structured `Pricing` type to replace the deprecated `price: Float!` field, and apply directives to enforce authorization and caching policies declaratively.

## Why It Matters

### Custom Scalars

**Without custom scalars:**

- `price: Float!` — Is this dollars? Cents? Euros? What precision?
- `email: String!` — Clients must validate format, leading to inconsistent UX
- `createdAt: String!` — Is it ISO 8601? Unix timestamp? Timezone?

**With custom scalars:**

- `price: Money!` — Serialized as cents (integer), eliminating floating-point errors
- `email: EmailAddress!` — Server validates on input, rejects malformed emails
- `createdAt: DateTime!` — Always ISO 8601, timezone-aware

Custom scalars push validation and domain logic into the type system, where it belongs.

### Custom Directives

Directives are **executable metadata** attached to schema elements. They let you:

- Enforce policies: `@auth(requires: ADMIN)` on `users` query
- Optimize performance: `@cacheControl(maxAge: 3600)` on `shippingEstimate`
- Document behavior: `@deprecated(reason: "Use pricing instead")`
- Transform data: `@uppercase`, `@trim` (custom)

Directives reduce resolver boilerplate by declaratively specifying cross-cutting concerns.

### Versionless Schema Evolution

Unlike REST APIs with `/v1/` and `/v2/` endpoints, GraphQL schemas evolve without versions:

1. **Additive changes** (non-breaking): Add new types, fields, arguments
1. **Deprecation** (non-breaking): Mark fields with `@deprecated`, keep them functional
1. **Removal** (breaking): Only after all clients stop using deprecated fields

This stage demonstrates evolution: the old `price: Float!` field is deprecated in favor of `pricing: Pricing!`, which includes currency and compare-at pricing. Old clients keep working; new clients use the better type.

## Mental Models

### Custom Scalar Contract

Every custom scalar implements three functions:

1. **serialize**: Internal value → client-facing value (GraphQL response)

   - `DateTime`: `Date object → ISO 8601 string`
   - `Money`: `cents integer → dollars float` (or keep as cents)
   - `EmailAddress`: `string → string` (passthrough, validation happens on input)

1. **parseValue**: Variable value → internal value (from `variables` in request)

   - `DateTime`: `ISO 8601 string → Date object`
   - `Money`: `dollars float → cents integer`
   - `EmailAddress`: `string → validated string` (reject if invalid)

1. **parseLiteral**: AST literal → internal value (from hardcoded value in query)

   - `DateTime`: `StringValue node → Date object`
   - `Money`: `IntValue or FloatValue → cents integer`
   - `EmailAddress`: `StringValue → validated string`

```graphql
scalar DateTime
scalar Money

# In response (serialize):
{ "createdAt": "2024-01-15T10:30:00Z" }

# From variable (parseValue):
mutation($date: DateTime!) { ... }
variables: { "date": "2024-01-15T10:30:00Z" }

# From literal (parseLiteral):
query { product(createdAt: "2024-01-15T10:30:00Z") }
```

### Directive Execution

Directives can be **schema directives** (affect schema behavior) or **query directives** (affect execution, like `@include`, `@skip`).

Schema directives like `@auth` and `@cacheControl` are implemented via:

- **Executable schema transformation**: Wrap resolvers at schema-build time
- **Custom validation rules**: Check auth during validation phase
- **Middleware/plugins**: Intercept resolver execution

```graphql
type Query {
  users: [User!]! @auth(requires: ADMIN)
}
```

At runtime, the server intercepts field resolution for directives like `@auth`, checks the user's role from the request context, and rejects unauthorized access before the resolver executes.

### Schema Evolution Strategy

| Change Type       | Breaking? | Strategy                                 |
| ----------------- | --------- | ---------------------------------------- |
| Add field         | No        | Just add it                              |
| Add type          | No        | Just add it                              |
| Add enum value    | Maybe     | New values may surprise old clients      |
| Add argument      | No        | Make it optional                         |
| Deprecate field   | No        | Mark with `@deprecated`, keep functional |
| Remove field      | Yes       | Only after all clients stop using it     |
| Change field type | Yes       | Add new field, deprecate old             |
| Rename field      | Yes       | Add new field, deprecate old             |

This stage demonstrates the **change field type** pattern: `price: Float!` is deprecated, `pricing: Pricing!` is added.

## Key Questions

1. **What three functions define a custom scalar?**
   `serialize` (output), `parseValue` (variable input), `parseLiteral` (literal input).

1. **When would you use a custom scalar vs. input validation in the resolver?**
   Scalar: Validation applies everywhere the type is used (DRY). Resolver: Validation is context-specific (e.g., "this email must not already exist").

1. **How do you handle money without floating-point errors?**
   Store as integer cents, use `Money` scalar to convert to/from dollars at the API boundary.

1. **What constitutes a breaking change in GraphQL?**
   Removing fields, changing field types, making nullable fields non-null, removing enum values that clients depend on.

1. **How do you deprecate a field without breaking clients?**
   Add `@deprecated(reason: "Use newField instead")` to the old field. Keep it functional. Monitor usage. Remove after clients migrate.

1. **Why use `DateTime` instead of `String` for timestamps?**
   Guarantees format (ISO 8601), timezone handling, prevents clients from guessing the format.

1. **How do schema directives differ from query directives?**
   Schema directives (`@auth`, `@cacheControl`) affect resolver behavior and are implemented server-side. Query directives (`@include`, `@skip`) affect response shape and are part of the GraphQL spec.

1. **Should `Money` serialize as cents or dollars?**
   Depends. Cents (integer) eliminates precision issues but surprises clients expecting dollars. Dollars (float) is intuitive but can accumulate rounding errors. Document your choice clearly.

## Schema Evolution Example

```graphql
# Old schema (stage 12)
type Product {
  price: Float!
}

# New schema (stage 15) - evolved, not versioned
type Product {
  price: Money! @deprecated(reason: "Use pricing { amount currency } instead")
  pricing: Pricing!
}

type Pricing {
  amount: Money!
  currency: String!
  compareAtAmount: Money
}

scalar Money
```

Old clients using `price` still work. New clients use `pricing` for structured data.

## Key Questions

1. **How do you migrate existing data when introducing a new scalar type?**
   Database stays the same (strings, integers). The scalar conversion happens at the GraphQL layer (serialize/parse functions). No database migration needed unless you're changing storage format.

1. **Can a scalar reject invalid input?**
   Yes. Throw an error in `parseValue` or `parseLiteral`. The GraphQL executor will catch it and return a validation error to the client.

1. **How do you document custom scalars for clients?**
   Use the `description` field in the scalar definition. Introspection exposes it. Also document in API docs with examples.

## Links

- [GraphQL Scalars (Official)](https://graphql.org/learn/schema/#scalar-types)
- [graphql-scalars Package](https://github.com/Urigo/graphql-scalars) — 40+ common scalars
- [Custom Directives Guide](https://www.apollographql.com/docs/apollo-server/schema/directives/)
- [Schema Evolution Best Practices](https://graphql.org/learn/best-practices/#versioning)
- [Deprecation in GraphQL](https://spec.graphql.org/October2021/#sec--deprecated)

## What You're Building

A server that:

1. Defines three custom scalars:
   - `DateTime` — serializes to/from ISO 8601 strings (e.g., `"2025-01-15T10:00:00.000Z"`)
   - `EmailAddress` — validates email format on input, rejects malformed emails
   - `Money` — represents monetary amounts (stored as integer cents internally, serialized as needed)
1. Replaces `String!` timestamps with `DateTime!` on all `createdAt` and `updatedAt` fields
1. Replaces `String!` email with `EmailAddress!` on `User.email`
1. Adds a `Pricing` type (`amount: Money!`, `currency: String!`, `compareAtAmount: Money`) to `Product`
1. Deprecates `Product.price` in favor of `Product.pricing`
1. Defines two custom directives:
   - `@auth(requires: Role!)` on `FIELD_DEFINITION` — declares which role is needed to access a field
   - `@cacheControl(maxAge: Int!)` on `FIELD_DEFINITION | OBJECT` — declares cache TTL
1. Implements the `@auth` directive so it enforces role-based access (e.g., `users: [User!]! @auth(requires: ADMIN)`)
1. Populates `Pricing` data from the `pricing` database table (added by migration 11)
1. Keeps deprecated fields functional — old queries using `price` still work

The key evolution pattern: add new fields/types, deprecate old ones, but never break existing clients. The test suite verifies both the new typed fields and the deprecated fields still function.

## Common Pitfalls

- **Floating-point money**: Storing prices as `Float` causes rounding errors. Use cents (integer) and convert at the boundary.
- **Inconsistent date formats**: Using `String` for dates leads to format ambiguity. Use `DateTime` scalar for consistency.
- **Weak email validation**: Custom `EmailAddress` scalar should validate format, but not existence (checking existence requires DB lookup, which is too expensive for a scalar).
- **Breaking old clients**: Removing deprecated fields before clients migrate causes outages. Monitor usage before removing.
- **Directive scope confusion**: Not all directives execute at runtime. `@deprecated` is metadata-only. `@auth` must be implemented.
- **Over-engineering**: Don't create custom scalars for every string. Use them when validation or semantic meaning is important.

## Run Tests

From the repo root:

```bash
STAGE=15 bun run --cwd test-runner test:stage
```
