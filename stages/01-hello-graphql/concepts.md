# Stage 01: Hello GraphQL

## What This Stage Teaches

This stage introduces the fundamental concepts of GraphQL: what it is, why it exists, and how it differs from REST. You'll build your first GraphQL server with a single field that returns a string. This minimal setup forces you to understand the core machinery—the HTTP endpoint, the schema definition language (SDL), and the execution model—without the distraction of databases, complex types, or business logic.

## Why It Matters

GraphQL is a **specification**, not a library or framework. Understanding this distinction is crucial. The spec defines how clients send queries over HTTP, how servers parse and validate those queries against a schema, and how responses are formatted. Any language can implement a GraphQL server as long as it follows the spec.

Starting with a single `hello` field teaches you to think **schema-first**. In GraphQL, the schema is the contract between client and server. You write SDL (Schema Definition Language) to define what data is queryable, then implement resolvers to fulfill those queries. This is the opposite of REST, where endpoints emerge organically and documentation is an afterthought.

## Mental Models

**GraphQL as a Query Language for Your API**: Think of GraphQL like SQL for your HTTP API. Just as SQL lets you query exactly the columns you need from a database, GraphQL lets clients specify exactly which fields they want from your API. The schema is your database schema, and resolvers are your query execution engine.

**The Single Endpoint**: Unlike REST's proliferation of endpoints (`/products`, `/products/:id`, `/users`, etc.), GraphQL serves everything through a single HTTP POST endpoint (typically `/graphql`). The query itself—sent in the request body—determines what data is fetched and how it's shaped.

**The Type System**: GraphQL is strongly typed. Every field has a declared type. The `!` modifier means non-null (required). This enables powerful tooling: IDEs can autocomplete queries, clients can generate type-safe code, and the server validates queries before execution.

## Key Questions

After completing this stage, you should be able to answer:

1. **What is the difference between a GraphQL query and a REST request?** (Hint: think about what determines the response shape)
2. **What happens when a client sends a query for a field that doesn't exist in the schema?** (Try it and observe the error)
3. **Where is the schema defined, and how does the server know what fields are queryable?**
4. **What is a resolver, and what does the `hello` field's resolver do?**
5. **Why does GraphQL serve over HTTP POST instead of GET?** (Consider: queries can be large and contain variables)

## Implementation Notes by Framework

**graphql-js (TypeScript/JavaScript)**:
- Schema is defined using `GraphQLSchema` and `GraphQLObjectType` (code-first), or `buildSchema()` from SDL (schema-first)
- Resolvers are functions passed to the schema or in a separate resolver map
- Use `express-graphql` or `apollo-server` to serve over HTTP

**gqlgen (Go)**:
- Schema-first: write `schema.graphql`, run `go generate` to generate resolver stubs
- Implement the `Resolver` interface in `resolver.go`
- The `hello` field maps to a `Hello()` method on your resolver

**Hot Chocolate (.NET)**:
- Code-first: define a `Query` class with a `GetHello()` method
- Schema-first: write SDL and implement resolvers separately
- Use `AddGraphQLServer()` in your ASP.NET Core startup

**Strawberry (Python)**:
- Code-first: define a `@strawberry.type` class with a `hello` field
- Schema-first: use `strawberry.Schema.from_type_defs()` with SDL
- Resolvers are methods on your type classes or standalone functions

**graphql-java (Java)**:
- Use `SchemaGenerator` with SDL, or build schema programmatically with `GraphQLObjectType`
- Resolvers are `DataFetcher` instances
- Serve with Spring Boot GraphQL or `graphql-java-kickstart`

## Links to Official Documentation

- [Introduction to GraphQL](https://graphql.org/learn/) — Start here for the "why"
- [Queries and Mutations](https://graphql.org/learn/queries/) — How clients send queries
- [Schemas and Types](https://graphql.org/learn/schema/) — The SDL and type system
- [Serving GraphQL over HTTP](https://graphql.org/learn/serving-over-http/) — The transport layer spec
- [Execution](https://graphql.org/learn/execution/) — How GraphQL resolves queries

## What You're Building

A server that:
1. Listens on an HTTP endpoint (typically `http://localhost:4000/graphql`)
2. Defines a schema with a single `Query` type containing a `hello` field
3. Implements a resolver for `hello` that returns any string (e.g., `"Hello, GraphQL!"`)
4. Responds to POST requests with JSON in the format `{ "data": { "hello": "..." } }`

No database, no authentication, no complex types—just the foundational machinery. Once you have this working, you understand the core loop: schema → resolver → response.
