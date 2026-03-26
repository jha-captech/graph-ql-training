# Stage 05: Query Language Features

## What This Stage Teaches

This stage is a conceptual breather—no new types, no new database schema. Instead, you'll explore the **GraphQL query language itself**: variables, aliases, fragments, and directives. These features transform GraphQL from a simple request-response protocol into a powerful, expressive query language that clients can use to optimize their data fetching.

While the server schema remains unchanged from Stage 04, your resolver implementation must correctly handle these advanced query structures. This stage tests your GraphQL execution engine's fidelity to the specification, not your domain modeling skills.

## Why These Features Matter

**Variables** eliminate string interpolation security risks and enable query reuse. Instead of embedding user input directly into query strings (a vector for injection attacks in other contexts), GraphQL queries declare typed variables that the server validates before execution.

**Aliases** allow clients to request the same field multiple times with different arguments in a single query, or to rename fields in the response to avoid naming collisions. This is critical for batch queries: fetching multiple products by ID in one request instead of N separate requests.

**Fragments** are GraphQL's reusability mechanism. Named fragments let you define a set of fields once and reuse them across multiple queries. Inline fragments enable type-specific field selection on interfaces and unions. Together, they reduce duplication and make large queries maintainable.

**Directives** (`@include` and `@skip`) provide runtime conditional field inclusion. This lets a single query adapt to different contexts (e.g., "include author details only if the user is authenticated") without maintaining multiple query versions.

## Mental Models

**Variables as Prepared Statements:** Think of GraphQL variables like parameterized SQL queries. The query structure is fixed; only the input values change. The server parses the query once, validates the variable types, then executes with the provided values.

**Aliases as Response Shape Control:** The schema defines what _can_ be queried; aliases let clients define what the response _looks like_. If you need two products in one query, you can't ask for `product` twice—but you can alias them: `first: product(id: "1")` and `second: product(id: "2")`.

**Fragments as Field Templates:** Fragments are similar to functions in programming—define once, invoke many times. When multiple queries need the same 15 product fields, extract them into a `ProductFields` fragment. Change the fragment, and all queries using it are updated.

**Directives as Inline Logic:** Instead of client-side field filtering after receiving data, directives push the conditional logic to the query. The server only resolves and transmits fields that pass the directive's condition.

## Key Questions

- **When would you use variables instead of hardcoding values in a query?** What are the security and performance implications?
- **How do aliases enable batch queries?** Construct a query that fetches three specific products in a single request.
- **What's the difference between named fragments and inline fragments?** When would you use each?
- **How do `@include` and `@skip` differ?** Can you use both on the same field?
- **Do directives affect the schema, or only the query execution?** Can you define custom directives?

## Official GraphQL Documentation

- [Queries and Mutations - Variables](https://graphql.org/learn/queries/#variables)
- [Queries and Mutations - Aliases](https://graphql.org/learn/queries/#aliases)
- [Queries and Mutations - Fragments](https://graphql.org/learn/queries/#fragments)
- [Queries and Mutations - Directives](https://graphql.org/learn/queries/#directives)
- [GraphQL Specification - Variables](https://spec.graphql.org/October2021/#sec-Language.Variables)
- [GraphQL Specification - Directives](https://spec.graphql.org/October2021/#sec-Language.Directives)

## What You're Building

You're not adding new resolvers or schema types. Instead, you're verifying that your GraphQL server correctly implements the query language specification. Your test suite will send queries with variables, aliases, fragments, and directives, and verify that the server:

1. Validates variable types before execution
1. Returns correctly aliased fields in the response
1. Resolves both named and inline fragments
1. Conditionally includes/excludes fields based on directives

This stage tests the _execution engine_, not your domain logic.

## Run Tests

From the repo root:

```bash
STAGE=05 bun run --cwd test-runner test:stage
```
