# Stage 16: Security & Federation

## What This Stage Teaches

This stage focuses on hardening your GraphQL API against malicious or inefficient queries and introduces the concepts of Apollo Federation for building distributed GraphQL architectures. You'll learn to implement query complexity analysis, depth limiting, persisted queries, and understand how federation enables microservice-based GraphQL implementations.

**Key topics:**

- Query depth limiting to prevent deeply nested attacks
- Query complexity analysis to prevent resource exhaustion
- Persisted queries for security and performance
- Rate limiting and request throttling
- Apollo Federation fundamentals (subgraphs, entities, gateway)
- Schema composition and entity resolution

## Why It Matters

**Security concerns:**
GraphQL's flexibility is powerful but can be exploited. Without proper safeguards, attackers can craft queries that overwhelm your server, leak data, or cause denial of service. A single deeply nested query can trigger thousands of database calls or consume excessive memory.

**Scale concerns:**
As your GraphQL API grows, a monolithic server becomes a bottleneck. Federation allows you to split your schema across multiple services, each owned by different teams, while maintaining a unified GraphQL interface.

**Production readiness:**
These patterns are essential for production GraphQL APIs. Major platforms (GitHub, Shopify, Netflix) use depth limiting, complexity analysis, and distributed architectures to serve millions of queries safely and efficiently.

## Mental Models

**Query Cost Budget**: Think of each query as having a "cost" based on nesting depth, fields requested, and list sizes. Set a budget (e.g., 1000 points) and reject queries that exceed it. Scalars cost 1, objects multiply by children, lists multiply by estimated size.

**Defense in Depth**: Layer multiple security mechanisms—depth limits catch nested attacks, complexity analysis catches expensive wide queries, timeouts catch runaway resolvers, rate limits catch brute force. No single mechanism is perfect; combine them.

**Federated Graph as Microservices**: Federation is to GraphQL what microservices are to REST. Each subgraph owns part of the schema and its data. The gateway stitches them together transparently. Clients see one unified API; services stay independent.

## Key Questions

1. **How do depth limits differ from complexity analysis?** Depth limits count nesting levels (e.g., max 7 deep). Complexity analysis assigns costs to fields and computes total cost. Depth is simpler but coarser; complexity is more precise but requires cost definitions for every field.

1. **What is a persisted query and how does it improve security?** A persisted query uses a hash/ID instead of sending the full query string. The server has a pre-approved whitelist of queries. This prevents arbitrary queries, reduces payload size, and enables aggressive caching. Clients send `{"queryId": "abc123"}` instead of the full query.

1. **How does Apollo Federation differ from schema stitching?** Schema stitching merges schemas at the gateway level using delegation. Federation uses a spec (`@key`, `@external`, `_entities` query) where subgraphs define their entities and the gateway resolves them automatically. Federation is more declarative and scales better.

1. **What is an entity in federation and how is it resolved?** An entity is a type shared across subgraphs, marked with `@key(fields: "id")`. The gateway can resolve an entity from any subgraph. When a subgraph needs data from another, the gateway calls `_entities` with the key, and the subgraph returns the extended data.

1. **When should you reject a query vs. just log and monitor it?** Reject queries that violate hard limits (depth > 10, complexity > 5000, timeout > 30s) to protect the server. Log and monitor queries near thresholds (depth 8-10, complexity 3000-5000) to identify legitimate use cases vs. potential attacks before tightening limits.

## Links to Official Documentation

- **Apollo Federation**: https://www.apollographql.com/docs/federation/
- **Query Complexity**: https://www.apollographql.com/blog/graphql/security/securing-your-graphql-api-from-malicious-queries/
- **Persisted Queries**: https://www.apollographql.com/docs/apollo-server/performance/apq/
- **graphql-depth-limit** (npm): https://github.com/stems/graphql-depth-limit
- **graphql-validation-complexity**: https://github.com/4Catalyzer/graphql-validation-complexity
- **Apollo Gateway**: https://www.apollographql.com/docs/apollo-server/using-federation/apollo-gateway-setup/
- **Subgraph Specification**: https://www.apollographql.com/docs/federation/subgraph-spec/

## What You're Building

In this stage, you're implementing security guardrails for the existing e-commerce API and learning federation concepts:

**Security hardening:**

- Reject queries deeper than 7-10 levels (configurable)
- Calculate query complexity and reject expensive queries (> 1000 cost)
- Block queries that would fetch more than 1000 items
- Add timeouts to prevent long-running resolvers
- Support persisted queries for production clients

**Federation concepts (conceptual tests):**

- Understand the `_service { sdl }` query that exposes subgraph schema
- Learn how `_entities` query resolves references across subgraphs
- See how the Product, User, and Order types could be split into:
  - **products-subgraph**: Product, Category
  - **users-subgraph**: User, authentication
  - **orders-subgraph**: Order, LineItem
- Each subgraph owns its data; the gateway composes the unified schema

**Schema stays the same** as stage 15—this stage is about operational concerns and architecture patterns, not schema changes.

**Testing approach:**

- Feature tests verify depth/complexity limits reject malicious queries
- Feature tests demonstrate the `_service` introspection for federation
- Conceptual tests explore how entity resolution would work (no full federation implementation required)

## Run Tests

From the repo root:

```bash
STAGE=16 bun run --cwd test-runner test:stage
```
