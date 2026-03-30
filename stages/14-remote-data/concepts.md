# Stage 14: Remote Data Sources

## What This Stage Teaches

GraphQL excels as a **data aggregation layer** that unifies multiple data sources behind a single API. This stage introduces resolvers that call external REST APIs, teaching you how to integrate third-party services, handle network failures gracefully, and maintain partial success semantics when remote data is unavailable.

You'll add a `shippingEstimate` field to `Product` that calls a mock shipping API (Mockoon on port 4010). The field returns shipping cost and delivery time based on the customer's zip code—data that exists outside your database. This demonstrates GraphQL's power as a gateway that hides backend complexity from clients.

## Why It Matters

Real-world GraphQL servers rarely own all the data they expose. Common integration scenarios:

- **Third-party APIs**: Payment processors (Stripe), shipping services (FedEx, UPS), geolocation (Google Maps)
- **Legacy systems**: REST APIs, SOAP services, mainframes
- **Microservices**: Internal services with their own APIs
- **External databases**: Read replicas, analytics warehouses, search engines (Elasticsearch)

GraphQL's resolver model makes integration straightforward: each field can fetch data from anywhere. The client sees a unified graph, unaware of the underlying complexity.

## Mental Models

### GraphQL as a Gateway

```
Client                 GraphQL Server              Data Sources
  |                          |                           |
  |-- query { product { ---->|                           |
  |     shippingEstimate     |------ DB query --------->|
  |   } }                    |<------ Product data ------|
  |                          |                           |
  |                          |---- HTTP GET ------------>| Shipping API
  |                          |<----- Estimate ----------|
  |                          |                           |
  |<--- { product: {         |                           |
  |       shippingEstimate   |                           |
  |     } } -----------------|                           |
```

The GraphQL layer orchestrates multiple data sources and presents them as a single, cohesive API.

### Graceful Degradation

When an external API is unavailable, you have choices:

1. **Fail the entire query**: Return an error, set the field to `null`, propagate null upward if non-null
1. **Return null for that field only**: Use a nullable field, return partial data
1. **Return a default/cached value**: Provide stale data with a flag indicating it's not fresh
1. **Log and continue**: Record the failure for monitoring, but don't surface it to the client

This stage uses **option 2**: `shippingEstimate` is nullable (`ShippingEstimate` not `ShippingEstimate!`). If the API call fails, the field returns `null`, but the rest of the product data still resolves. This is GraphQL's partial success model in action.

### Context-Driven Configuration

External API clients (HTTP clients, API keys, base URLs) are passed through the GraphQL context. This allows:

- **Dependency injection**: Resolvers receive configured clients, not hardcoded URLs
- **Per-request configuration**: Authentication tokens, request IDs, tracing headers
- **Testability**: Mock clients for unit tests, real clients for integration tests

The general pattern is to create an HTTP client configured with the external service's base URL, pass it through context, and use it in resolvers. On failure, catch the error and return `null` for graceful degradation.

## Key Questions

1. **Where does the external API client live in your architecture?**
   In the GraphQL context, created per-request. This allows request-scoped configuration (auth tokens, tracing headers) and testability (mock clients).

1. **How do you handle timeouts?**
   Set aggressive timeouts on HTTP clients (2-5 seconds). GraphQL queries should be fast. If an external API is slow, it shouldn't block the entire query.

1. **How do you handle failures?**
   Return `null` for nullable fields (graceful degradation). Log the error for monitoring. Never let external API failures crash your GraphQL server.

1. **What's the difference between returning `null` due to an error vs. due to no data?**
   Semantically, there's no difference in the response. For monitoring, log errors. For clients, document when `null` means "unavailable" vs. "doesn't exist".

1. **How would you cache external API responses?**

   - In-memory cache (TTL-based): `node-cache`, `memory-cache`
   - Redis: Shared cache across server instances
   - HTTP cache headers: `Cache-Control`, `ETag`
   - DataLoader: Already batches and caches per-request

1. **Should you use DataLoader for external API calls?**
   Yes, if the API supports batch requests (e.g., `/estimate?ids=1,2,3`). DataLoader batches individual calls into one HTTP request, reducing latency.

1. **How do you test resolvers that call external APIs?**

   - **Unit tests**: Mock the HTTP client, return fake responses
   - **Integration tests**: Use Mockoon or WireMock to simulate the API
   - **Contract tests**: Verify your mocks match the real API's behavior

1. **When should external data be nullable vs. non-null?**

   - Nullable: Data from unreliable sources (third-party APIs, optional features)
   - Non-null: Core data that's required for the query to make sense

## Testing with Mockoon

Mockoon is a mock API server configured via JSON files. For this stage:

- **Mock file**: `mocks/shipping.json` (in the project root)
- **Port**: 4010
- **Endpoint**: `GET /estimate?productId={id}&zip={code}`
- **Success response**: `{ provider: "USPS", days: 5, cost: 8.99 }`
- **Error response**: 500 Internal Server Error (test graceful degradation)

Start the mock:

```bash
task mocks:start
```

Your resolver should call `http://localhost:4010/estimate`. The test runner will stop the mock mid-test to verify graceful degradation.

## Links

- [GraphQL as a Gateway (Apollo Blog)](https://www.apollographql.com/blog/backend/architecture/graphql-as-a-gateway/)
- [Resolver Best Practices](https://www.apollographql.com/docs/apollo-server/data/resolvers/)
- [Error Handling in GraphQL](https://www.apollographql.com/docs/apollo-server/data/errors/)
- [Mockoon Documentation](https://mockoon.com/docs/latest/about/)
- [Partial Success in GraphQL](https://spec.graphql.org/October2021/#sec-Errors)

## What You're Building

A server that:

1. Adds a `ShippingEstimate` type with fields: `provider` (String!), `days` (Int!), `cost` (Float!)
1. Adds a `shippingEstimate(zipCode: String!)` field on the `Product` type — this field is **nullable** (returns `null` on API failure)
1. Implements a resolver for `Product.shippingEstimate` that:
   - Makes an HTTP GET request to the shipping mock API: `${SHIPPING_API_URL}/estimate?zip={zipCode}`
   - Returns the parsed response on success
   - Returns `null` on any failure (network error, timeout, non-200 status)
1. Reads the shipping API base URL from the `SHIPPING_API_URL` environment variable (defaults to `http://localhost:4010`)
1. Sets a reasonable timeout on the HTTP client (2-5 seconds)
1. Handles graceful degradation — the rest of the product data resolves even when the shipping API is down

Start the mock APIs before running tests:

```bash
task mocks:start
```

The test suite will verify both successful API calls and graceful degradation when the API is unavailable.

## Common Pitfalls

- **Not handling errors**: External API failure crashes your GraphQL server. Always wrap HTTP calls in try/catch.
- **Blocking resolvers**: Synchronous HTTP calls block the event loop. Use async HTTP clients.
- **Hardcoding URLs**: Use environment variables for API base URLs. Enables testing and environment-specific config.
- **No timeouts**: External APIs can hang. Set aggressive timeouts (2-5 seconds).
- **Over-fetching**: Don't call the external API if the client didn't request the field. Check `info.fieldNodes` or rely on resolver lazy evaluation.
- **Ignoring caching**: External API calls are expensive. Cache responses with TTL or use DataLoader for per-request caching.

## Run Tests

From the repo root:

```bash
STAGE=14 bun run --cwd test-runner test:stage
```
