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
2. **Publish**: When a mutation (or external event) changes data, the server publishes an event
3. **Deliver**: The subscription resolver filters/transforms the event and sends it to matching subscribers
4. **Unsubscribe**: Client closes the connection when done

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

## Implementation Notes

### graphql-js / Apollo Server (TypeScript/JavaScript)

- Use `graphql-subscriptions` package for in-memory pub/sub
- Subscription resolvers return an `AsyncIterator`
- `pubsub.publish('ORDER_STATUS_CHANGED', payload)` in mutation resolvers
- `pubsub.asyncIterator(['ORDER_STATUS_CHANGED'])` in subscription resolvers
- Filter using `withFilter()` wrapper

```javascript
const pubsub = new PubSub();

// In mutation resolver:
await updateOrderStatus(orderId, newStatus);
pubsub.publish('ORDER_STATUS_CHANGED', { orderStatusChanged: order });

// In subscription resolver:
Subscription: {
  orderStatusChanged: {
    subscribe: withFilter(
      () => pubsub.asyncIterator(['ORDER_STATUS_CHANGED']),
      (payload, variables) => payload.orderStatusChanged.id === variables.orderId
    )
  }
}
```

### gqlgen (Go)

- Define subscription resolvers as channel generators
- Use `go-channels` or a pub/sub library
- Filtering happens in the resolver logic

### Hot Chocolate (.NET)

- Use `[Subscribe]` attribute on subscription resolvers
- Return `IAsyncEnumerable<T>` or `IObservable<T>`
- Use `[Topic]` for pub/sub routing

### Strawberry (Python)

- Use `@strawberry.type` with subscription methods
- Return `AsyncGenerator` from subscription resolvers
- Integrate with Redis pub/sub for multi-instance deployments

### Scaling Subscriptions

In-memory pub/sub (like `PubSub` from `graphql-subscriptions`) only works for single-server deployments. For production:

- **Redis pub/sub**: `graphql-redis-subscriptions` shares events across server instances
- **Message queues**: RabbitMQ, Kafka for reliable event delivery
- **Managed services**: AWS AppSync, Hasura, Apollo Router handle subscription infrastructure

## Key Questions

1. **What transport protocol do subscriptions use, and why not HTTP?**
   WebSocket, because HTTP is request-response only. Subscriptions need bidirectional, persistent connections.

2. **Where does the pub/sub system fit in your architecture?**
   Between mutation resolvers (publishers) and subscription resolvers (subscribers). The mutation calls `pubsub.publish()`, the subscription calls `pubsub.asyncIterator()`.

3. **How do you filter subscription events?**
   Capture filter arguments (like `orderId`) when the subscription is created. In the resolver, compare the event payload to the captured arguments before sending to the client.

4. **What happens to subscriptions when the server restarts?**
   All WebSocket connections close. Clients must detect the disconnect and re-subscribe. In-memory pub/sub state is lost—events published during downtime are not delivered.

5. **How would you scale subscriptions horizontally?**
   Replace in-memory pub/sub with Redis, Kafka, or a message queue. Each server instance subscribes to the same event stream and pushes to its connected clients.

6. **Should all data updates be subscriptions?**
   No. Subscriptions add complexity. Use them for data that clients need **immediately** (order status, chat messages). For data that's fine to be stale (product catalog), stick with queries.

7. **How do you handle subscription authorization?**
   Same as queries/mutations: check the user's identity from the WebSocket connection context. A customer should only subscribe to their own order updates, not others'.

8. **What's the difference between `subscribe` and `resolve` in a subscription field?**
   - `subscribe`: Returns the async iterator (event source)
   - `resolve`: Transforms the event payload before sending (optional—defaults to identity function)

## Testing Subscriptions

The test runner uses a WebSocket client to:

1. Connect to the GraphQL endpoint (WebSocket URL, typically `ws://localhost:4000/graphql`)
2. Send a subscription operation
3. Trigger a mutation that publishes an event
4. Assert that the subscription receives the event within a timeout
5. Verify the event payload matches expectations

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

## Common Pitfalls

- **Forgetting to call `pubsub.publish()` in mutations**: Subscriptions won't fire if you don't publish events.
- **Not filtering events**: Broadcasting every event to every subscriber kills performance.
- **Holding connections open indefinitely**: Implement heartbeat/ping-pong to detect dead connections.
- **Blocking the event loop**: Subscription resolvers must be fast—don't do heavy computation in the filter function.
- **Ignoring authentication**: Always validate that the subscriber is authorized to receive the events they're subscribing to.
