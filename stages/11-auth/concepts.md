# Stage 11: Authentication and Authorization

## What This Stage Teaches

This stage introduces **authentication** (proving who you are) and **authorization** (what you're allowed to do) in GraphQL. You'll learn how to extract user identity from HTTP headers, enforce role-based access control, and implement field-level authorization—all while keeping your business logic separate from your GraphQL layer.

The key insight: Auth happens at the **HTTP boundary** (authentication) and **business logic layer** (authorization), not in your GraphQL resolvers. Resolvers should orchestrate, not enforce. This separation keeps your code testable and maintainable.

## Why It Matters

Every production GraphQL API needs auth. Without proper access control:

- Users see data they shouldn't (PII leaks, competitive information)
- Malicious actors modify or delete resources
- Business rules are violated (customers marking orders as shipped)
- Compliance requirements are violated (GDPR, HIPAA, PCI)

GraphQL's flexible nature makes auth more nuanced than REST. A single query can request data from multiple resources with different access rules. Field-level authorization means some fields in a type may be visible while others aren't. This stage teaches you to handle these complexities correctly.

## Mental Models

### Authentication vs. Authorization

**Authentication (AuthN)**: "Who are you?"

- Happens at the **HTTP layer** before GraphQL execution
- Validates tokens, sessions, API keys
- Extracts user identity and adds it to GraphQL context
- Unauthenticated requests are valid—they just have `context.user = null`

**Authorization (AuthZ)**: "What are you allowed to do?"

- Happens in **business logic** during GraphQL execution
- Checks roles, permissions, resource ownership
- Can be entity-level ("can you see any orders?") or field-level ("can you see this user's email?")
- Unauthorized requests return errors or null fields

### The Context Object Pattern

GraphQL's `context` is a per-request object available to all resolvers. It's the perfect place for auth state:

```typescript
type Context = {
  user: User | null; // Authenticated user, or null
  db: Database; // Database connection
  dataloaders: DataLoaders; // DataLoader instances
};
```

Your authentication middleware populates `context.user`:

```typescript
app.use("/graphql", async (req, res, next) => {
  const token = req.headers.authorization?.replace("Bearer ", "");
  const user = token ? await verifyToken(token) : null;
  req.context = { user, db, dataloaders };
  next();
});
```

Resolvers then check `context.user`:

```typescript
const Query = {
  me: (parent, args, context) => {
    return context.user; // null if not authenticated
  },

  users: (parent, args, context) => {
    if (!context.user || context.user.role !== "ADMIN") {
      throw new Error("Unauthorized");
    }
    return context.db.users.findAll();
  },
};
```

### Three Authorization Patterns

**1. Query/Mutation-Level**: Entire operation requires auth

```typescript
// "Only admins can list all users"
users: (parent, args, context) => {
  requireRole(context.user, "ADMIN");
  return db.users.findAll();
};
```

**2. Entity-Level**: Filter results based on ownership

```typescript
// "Users see their own orders, admins see all orders"
orders: (parent, args, context) => {
  if (!context.user) throw new Error("Unauthenticated");

  if (context.user.role === "ADMIN") {
    return db.orders.findAll();
  }
  return db.orders.findByBuyerId(context.user.id);
};
```

**3. Field-Level**: Specific fields have access rules

```typescript
// User.email is only visible to self and admins
User: {
  email: (user, args, context) => {
    const isSelf = context.user?.id === user.id;
    const isAdmin = context.user?.role === "ADMIN";

    if (!isSelf && !isAdmin) {
      return null; // or throw an error
    }
    return user.email;
  };
}
```

## Key Concepts

### The `me` Query

The `me` query is a GraphQL convention for "get the authenticated user":

```graphql
type Query {
  me: User # Returns null if not authenticated
}
```

This is cleaner than `user(id: "me")` because:

- It's self-documenting
- It doesn't require the client to know their own ID
- It cleanly returns `null` when unauthenticated (no error)

### Role-Based Access Control (RBAC)

Our domain has three roles:

- **CUSTOMER**: Can view products, place orders, review products
- **SELLER**: Can create/update their own products, see orders for their products
- **ADMIN**: Can do everything

Roles are stored in the database (`users.role`) and checked in business logic:

```typescript
function requireRole(user: User | null, allowedRoles: Role[]): void {
  if (!user) throw new Error("Authentication required");
  if (!allowedRoles.includes(user.role)) {
    throw new Error("Insufficient permissions");
  }
}
```

### Token-Based Auth (JWT)

Most modern GraphQL APIs use JWTs (JSON Web Tokens):

1. Client authenticates (login mutation, OAuth flow)
1. Server returns a signed JWT containing user ID and role
1. Client includes JWT in `Authorization: Bearer <token>` header
1. Server verifies signature and extracts user identity

For this stage, the test runner signs JWTs with a shared secret. Your server must verify tokens using the same secret and extract the user identity from the payload.

**JWT configuration:**

- **Secret**: Read from the `JWT_SECRET` environment variable (default: `graphql-training-secret`)
- **Algorithm**: HS256 (HMAC-SHA256)

**Token payload structure:**

```json
{
  "sub": "user-001",
  "email": "alice@example.com",
  "name": "Alice Johnson",
  "role": "CUSTOMER",
  "iat": 1700000000,
  "exp": 1700003600
}
```

The test runner generates tokens for three pre-seeded users:

| Role     | `sub`    | `email`           | `name`         |
| -------- | -------- | ----------------- | -------------- |
| CUSTOMER | user-001 | alice@example.com | Alice Johnson  |
| SELLER   | user-003 | carol@example.com | Carol Williams |
| ADMIN    | user-005 | eve@example.com   | Eve Davis      |

Your authentication middleware should:

1. Extract the token from the `Authorization: Bearer <token>` header
1. Verify the signature using `JWT_SECRET`
1. Decode the payload and populate `context.user` with `{ id: sub, email, name, role }`
1. Set `context.user = null` if no token is present or verification fails (don't throw — let resolvers decide)

In production, use asymmetric keys (RS256) or a dedicated auth service.

### Field-Level Authorization

Some fields have different visibility rules than their parent type:

```graphql
type User {
  id: ID!
  name: String! # Public
  email: String! # Only visible to self and admins
  role: Role! # Public
}
```

Implement this in the field resolver:

```typescript
User: {
  email: (user, args, context) => {
    if (canViewEmail(context.user, user)) {
      return user.email;
    }
    return null; // Hide the email
  };
}
```

**Trade-off**: Returning `null` vs. throwing an error. Both are valid:

- **Return null**: Field is hidden but doesn't break the query
- **Throw error**: Client knows auth failed, but adds to `errors` array

Choose based on your API's semantics. If the field is `String!` (non-null), you _must_ throw (null would violate the schema).

## Key Questions

1. **Where should authentication happen—before GraphQL or inside resolvers?** What are the trade-offs?

1. **When should unauthorized access return `null` vs. throw an error?** How does this interact with nullable vs. non-nullable fields?

1. **How do you test auth logic?** Do you test it via GraphQL queries, or unit test the auth functions separately?

1. **What goes in the JWT payload?** User ID? Role? Permissions? What are the security implications of including sensitive data?

1. **How do you handle token expiration?** Should expired tokens return 401, or just treat the user as unauthenticated?

1. **How do you implement field-level auth efficiently?** Do you check permissions in every field resolver?

1. **What's the difference between authentication errors and authorization errors?** Should they have different error codes?

## Implementation Notes by Framework

### graphql-js (TypeScript/JavaScript)

Set up context in your server:

```typescript
const server = new ApolloServer({
  schema,
  context: async ({ req }) => {
    const token = req.headers.authorization?.replace("Bearer ", "");
    const user = token ? await verifyToken(token) : null;
    return { user, db, dataloaders };
  },
});
```

Check auth in resolvers:

```typescript
const Query = {
  me: (parent, args, context) => context.user,

  users: (parent, args, context) => {
    if (context.user?.role !== "ADMIN") {
      throw new GraphQLError("Unauthorized", {
        extensions: { code: "FORBIDDEN" },
      });
    }
    return db.users.findAll();
  },
};
```

### gqlgen (Go)

Define a context struct:

```go
type Context struct {
    User *User
    DB   *Database
}
```

Populate it in middleware:

```go
func AuthMiddleware(next http.Handler) http.Handler {
    return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
        user := extractUser(r.Header.Get("Authorization"))
        ctx := context.WithValue(r.Context(), "auth", &Context{User: user})
        next.ServeHTTP(w, r.WithContext(ctx))
    })
}
```

Access in resolvers:

```go
func (r *queryResolver) Me(ctx context.Context) (*User, error) {
    authCtx := ctx.Value("auth").(*Context)
    return authCtx.User, nil
}
```

### Strawberry (Python)

Use dependency injection for context:

```python
@strawberry.type
class Query:
    @strawberry.field
    def me(self, info: strawberry.Info) -> Optional[User]:
        return info.context.user

    @strawberry.field
    def users(self, info: strawberry.Info) -> List[User]:
        if not info.context.user or info.context.user.role != Role.ADMIN:
            raise PermissionError("Unauthorized")
        return get_all_users(info.context.db)
```

### Hot Chocolate (.NET)

Use `[Authorize]` attributes or custom auth directives:

```csharp
public class Query {
    public User? Me([Service] IHttpContextAccessor accessor) {
        return accessor.HttpContext?.User?.Identity?.IsAuthenticated == true
            ? GetCurrentUser(accessor)
            : null;
    }

    [Authorize(Roles = "ADMIN")]
    public List<User> GetUsers([Service] IUserRepository repo) {
        return repo.GetAll();
    }
}
```

### graphql-java (Java/Kotlin)

Populate context in `DataFetchingEnvironment`:

```java
GraphQL graphQL = GraphQL.newGraphQL(schema)
    .defaultDataFetcherExceptionHandler(...)
    .build();

ExecutionInput input = ExecutionInput.newExecutionInput()
    .context(new Context(user, db))
    .query(query)
    .build();
```

Access in data fetchers:

```java
DataFetcher<User> meDataFetcher = environment -> {
    Context ctx = environment.getContext();
    return ctx.getUser();
};
```

## Official Documentation

- [GraphQL Authorization](https://graphql.org/learn/authorization/)
- [Authentication and Authorization Best Practices](https://productionreadygraphql.com/)
- [JWT.io](https://jwt.io/) - Learn about JSON Web Tokens

## Common Pitfalls

1. **Putting auth logic in resolvers**: Resolvers should call business logic functions that do auth. Don't inline permission checks everywhere.

1. **Not handling unauthenticated vs. unauthorized**: `401 Unauthorized` means "not authenticated." `403 Forbidden` means "authenticated but not authorized."

1. **Leaking existence via error messages**: Don't say "Order not found" vs. "Unauthorized to view order." Both should return the same error to avoid leaking information.

1. **Overly permissive default**: Make the default "deny access" and explicitly allow operations. Never default to "allow."

1. **Ignoring field-level auth**: Just because a user can query `Product` doesn't mean they can see `Product.seller.email`.

1. **Hard-coding roles in resolvers**: Extract role checks to reusable functions or decorators.

1. **Not testing unauthenticated state**: Most tests authenticate by default. Explicitly test what happens when `context.user` is null.

## What Success Looks Like

After completing this stage:

- The `me` query returns the authenticated user or null
- Role-based access control prevents unauthorized operations
- Field-level auth hides sensitive data (like `User.email`) from unauthorized users
- Authentication middleware extracts user identity from JWT tokens
- Authorization logic lives in business logic, not GraphQL resolvers
- Error messages don't leak information about resources users can't access

The test suite will verify these behaviors by making authenticated and unauthenticated requests, testing different roles, and attempting to access restricted fields. Your implementation should enforce all auth rules consistently.

## Run Tests

From the repo root:

```bash
bunx --cwd test-runner cucumber-js --tags @stage:11
```
