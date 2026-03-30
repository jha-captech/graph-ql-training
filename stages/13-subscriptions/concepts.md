# Stage 13: Subscriptions

## What This Stage Teaches

GraphQL subscriptions enable real-time, event-driven communication between server and client. Unlike queries (request-response) and mutations (request-response with side effects), subscriptions establish a persistent connection that pushes data to clients when specific events occur. This stage introduces the `Subscription` root type, WebSocket transport, the pub/sub pattern, and subscription filtering.

You'll implement two subscriptions: `orderStatusChanged` (filtered by order ID) and `productCreated` (broadcast to all subscribers). This demonstrates both targeted and broadcast subscription patterns, which are the foundation of real-time features in modern applications.

## Why It Matters

Subscriptions solve problems that polling cannot handle efficiently:

- **Order tracking**: Customers see status updates instantly without refreshing
- **Live dashboards**: Admins see new products as they're created
- **Chat and notifications**: Real-time communication without HTTP overhead
- **Collaborative editing**: Multiple users see changes as they happen

Without subscriptions, clients must poll the server repeatedly, wasting bandwidth and adding latency. Subscriptions invert the relationship: the server pushes updates only when data changes.

## Mental Models

### The Pub/Sub Pattern

Think of subscriptions as a newspaper subscription:

1. **Subscribe**: Client opens a long-lived connection and says "notify me when X happens"
1. **Publish**: When a mutation (or external event) changes data, the server publishes an event
1. **Deliver**: The subscription resolver filters/transforms the event and sends it to matching subscribers
1. **Unsubscribe**: Client closes the connection when done

The key insight: subscriptions are **reactive resolvers** triggered by events, not by client requests.

### WebSocket Transport

GraphQL subscriptions typically use WebSocket, a protocol that upgrades an HTTP connection to bidirectional, full-duplex communication:

- HTTP: Client asks, server responds, connection closes
- WebSocket: Connection stays open, both sides can send messages anytime

The [graphql-ws](https://github.com/enisdenjo/graphql-ws) protocol is the modern standard (replacing the older `subscriptions-transport-ws`).

### Subscription Lifecycle

```
Client                          Server
  |                               |
  |-- WebSocket handshake ------->|
  |<-------- Upgrade OK -----------|
  |                               |
  |-- subscribe { orderStatusChanged(orderId: "ord-001") } -->|
  |                               |
  |                     [Event fires: order ord-001 updated]
  |                               |
  |<---- { data: { orderStatusChanged: {...} } } -------------|
  |                               |
  |                     [Event fires: order ord-002 updated]
  |                      (no message sent - wrong orderId)
  |                               |
  |-- complete (unsubscribe) ---->|
  |<-------- connection closed ----|
```

### Filtering vs. Broadcast

- **Broadcast** (`productCreated`): Every subscriber gets every event. Simple, but can overwhelm clients.
- **Filtered** (`orderStatusChanged(orderId: ID!)`): Subscribers only receive events matching their filter. Efficient, but requires server-side filtering logic.

Most production subscriptions use filtering. The argument (`orderId`) is captured when the subscription is created and used to filter published events.

## Scaling Subscriptions

In-memory pub/sub only works for single-server deployments. For production:

- **Redis pub/sub**: Shares events across server instances
- **Message queues**: RabbitMQ, Kafka for reliable event delivery
- **Managed services**: AWS AppSync, Hasura, Apollo Router handle subscription infrastructure

## Key Questions

1. **What transport protocol do subscriptions use, and why not HTTP?**
   WebSocket, because HTTP is request-response only. Subscriptions need bidirectional, persistent connections.

1. **Where does the pub/sub system fit in your architecture?**
   Between mutation resolvers (publishers) and subscription resolvers (subscribers). The mutation publishes an event to a topic, and the subscription listens on that topic via an async iterator or channel.

1. **How do you filter subscription events?**
   Capture filter arguments (like `orderId`) when the subscription is created. In the resolver, compare the event payload to the captured arguments before sending to the client.

1. **What happens to subscriptions when the server restarts?**
   All WebSocket connections close. Clients must detect the disconnect and re-subscribe. In-memory pub/sub state is lost—events published during downtime are not delivered.

1. **How would you scale subscriptions horizontally?**
   Replace in-memory pub/sub with Redis, Kafka, or a message queue. Each server instance subscribes to the same event stream and pushes to its connected clients.

1. **Should all data updates be subscriptions?**
   No. Subscriptions add complexity. Use them for data that clients need **immediately** (order status, chat messages). For data that's fine to be stale (product catalog), stick with queries.

1. **How do you handle subscription authorization?**
   Same as queries/mutations: check the user's identity from the WebSocket connection context. A customer should only subscribe to their own order updates, not others'.

1. **What's the difference between `subscribe` and `resolve` in a subscription field?**

   - `subscribe`: Returns the async iterator (event source)
   - `resolve`: Transforms the event payload before sending (optional—defaults to identity function)

## Testing Subscriptions

The test runner uses a WebSocket client to:

1. Connect to the GraphQL endpoint (WebSocket URL, typically `ws://localhost:4000/graphql`)
1. Send a subscription operation
1. Trigger a mutation that publishes an event
1. Assert that the subscription receives the event within a timeout
1. Verify the event payload matches expectations

Gherkin steps:

```gherkin
When I send the subscription:
  """
  subscription {
    orderStatusChanged(orderId: "ord-001") {
      id
      status
    }
  }
  """
Then the subscription should receive an event within 5 seconds
Then the subscription event "data.orderStatusChanged.status" should equal "SHIPPED"
```

## Links

- [GraphQL Subscriptions (Official)](https://graphql.org/learn/queries/#subscriptions)
- [GraphQL over WebSocket Protocol](https://github.com/enisdenjo/graphql-ws/blob/master/PROTOCOL.md)
- [graphql-subscriptions (npm)](https://github.com/apollographql/graphql-subscriptions)
- [Apollo Server Subscriptions Guide](https://www.apollographql.com/docs/apollo-server/data/subscriptions/)
- [Scaling GraphQL Subscriptions](https://www.apollographql.com/blog/backend/scaling-graphql-subscriptions/)

## What You're Building

A server that:

1. Adds a `Subscription` root type with two subscriptions:
   - `orderStatusChanged(orderId: ID!): Order!` — filtered by order ID, only delivers events for the specified order
   - `productCreated: Product!` — broadcast to all subscribers when any product is created
1. Implements WebSocket support using the [graphql-ws](https://github.com/enisdenjo/graphql-ws) protocol (`graphql-transport-ws` subprotocol)
1. Sets up an in-memory pub/sub system:
   - `updateOrderStatus` mutation publishes to `orderStatusChanged` subscribers
   - `createProduct` mutation publishes to `productCreated` subscribers
1. Filters `orderStatusChanged` events so subscribers only receive events matching their `orderId` argument
1. Broadcasts `productCreated` events to all connected subscribers
1. Enforces authentication on subscriptions — unauthenticated users cannot subscribe
1. Enforces authorization — customers can only subscribe to their own orders' status changes
1. Resolves nested fields on subscription payloads (e.g., `Order.buyer`, `Order.items`, `Product.seller`)

The WebSocket endpoint should be at the same URL as your GraphQL HTTP endpoint (`ws://localhost:4000/graphql`). The test runner connects via WebSocket, sends a subscription, triggers a mutation via HTTP, and asserts that the subscription receives the correct event.

## Common Pitfalls

- **Forgetting to call `pubsub.publish()` in mutations**: Subscriptions won't fire if you don't publish events.
- **Not filtering events**: Broadcasting every event to every subscriber kills performance.
- **Holding connections open indefinitely**: Implement heartbeat/ping-pong to detect dead connections.
- **Blocking the event loop**: Subscription resolvers must be fast—don't do heavy computation in the filter function.
- **Ignoring authentication**: Always validate that the subscriber is authorized to receive the events they're subscribing to.

## Run Tests

From the repo root:

```bash
STAGE=13 bun run --cwd test-runner test:stage
```
