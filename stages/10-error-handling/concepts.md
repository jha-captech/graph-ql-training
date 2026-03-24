# Stage 10: Error Handling

## What This Stage Teaches

This stage teaches GraphQL's **partial success model** and how to handle errors at multiple layers: validation errors as domain logic (union-based result types), unexpected errors as top-level `errors`, and null propagation for non-null fields.

The key insight: GraphQL doesn't follow REST's "all or nothing" approach. A single response can contain both successful data and errors. This is powerful but requires careful design—you must decide which errors are expected domain outcomes (e.g., "invalid email format") vs. unexpected failures (e.g., "database connection lost").

## Why It Matters

Production GraphQL APIs must handle errors gracefully and communicate failure modes clearly to clients. Poor error handling leads to:

- **Opaque failures**: Clients receive `null` without understanding why
- **Inconsistent behavior**: Some mutations throw, others return nulls, others use custom error fields
- **Information leaks**: Stack traces or database errors exposed to clients
- **Poor UX**: Generic "something went wrong" messages instead of actionable feedback

GraphQL's error model is more nuanced than HTTP status codes. A `200 OK` response can contain errors. A field can be `null` because of missing data _or_ because an error occurred. This stage teaches you to navigate these complexities.

## Mental Models

### Two Types of Errors

**1. Expected Errors (Domain Logic)**

These are validation failures, business rule violations, or predictable failure states. Examples:

- "Email already registered"
- "Price must be positive"
- "Product not found"
- "Insufficient inventory"

These should be **part of your schema as union result types**. They're not exceptional—they're expected outcomes that clients must handle.

```graphql
union CreateProductResult = CreateProductSuccess | ValidationError

type ValidationError {
  message: String!
  field: String
  code: String!
}
```

**2. Unexpected Errors (System Failures)**

These are crashes, bugs, network failures, or infrastructure problems. Examples:

- Database connection timeout
- Null pointer exception
- External API unreachable
- Resolver threw an exception

These go in the top-level `errors` array. They represent something going wrong that the client can't meaningfully handle beyond retrying or showing a generic error.

### The Partial Success Model

GraphQL executes queries field-by-field. If one field errors, the others can still succeed:

```graphql
{
  product(id: "prod-001") {
    title
    price
  } # Succeeds
  product(id: "invalid") {
    title
  } # Errors, returns null
  categories {
    name
  } # Succeeds
}
```

Response:

```json
{
  "data": {
    "product": null,
    "categories": [{ "name": "Electronics" }]
  },
  "errors": [
    {
      "message": "Product not found",
      "locations": [{ "line": 2, "column": 3 }],
      "path": ["product"]
    }
  ]
}
```

The `categories` field succeeded even though `product` failed. This is the partial success model in action.

### Null Propagation for Non-Null Fields

When a `String!` (non-null) field resolver throws or returns `null`, GraphQL can't return `null` for that field (it's non-null). Instead, it propagates the null up to the nearest nullable parent:

```graphql
type Product {
  id: ID!
  title: String! # Non-null
}
```

If `title` resolver throws, GraphQL sets the entire `Product` object to `null` (assuming `Product` itself is nullable in the parent field).

This is why careful nullability design matters. A single non-null field error can null out an entire object tree.

## Key Concepts

### Error Response Structure

Top-level errors follow the GraphQL spec:

```json
{
  "errors": [
    {
      "message": "Product not found",
      "locations": [{"line": 3, "column": 5}],
      "path": ["product"],
      "extensions": {
        "code": "NOT_FOUND",
        "timestamp": "2024-01-15T10:30:00Z"
      }
    }
  ],
  "data": { ... }
}
```

**Required fields:**

- `message` (string): Human-readable description

**Optional fields:**

- `locations` (array): Where in the query document the error occurred
- `path` (array): Which response field the error corresponds to
- `extensions` (object): Custom structured data (error codes, stack traces in dev, etc.)

### Union-Based Error Pattern

Instead of throwing in mutations, return a union:

```graphql
mutation CreateProduct($input: CreateProductInput!) {
  createProduct(input: $input) {
    __typename
    ... on CreateProductSuccess {
      product {
        id
        title
      }
    }
    ... on ValidationError {
      message
      field
      code
    }
  }
}
```

This forces clients to handle both success and failure explicitly. It's self-documenting—the schema says "this mutation can fail in these specific ways."

### Error Codes via Extensions

Don't rely solely on error messages (they're strings, not enums). Use structured error codes:

```json
{
  "errors": [
    {
      "message": "Title is required",
      "extensions": {
        "code": "VALIDATION_ERROR",
        "field": "title"
      }
    }
  ]
}
```

Clients can switch on `extensions.code` instead of parsing strings.

## Implementation Strategies

### Where to Throw vs. Return Errors

**Throw in resolvers when:**

- Unexpected system failures (database errors, network timeouts)
- Authorization failures (403-equivalent)
- Fatal bugs (null pointer, type errors)

**Return union errors when:**

- Validation failures (missing fields, invalid formats)
- Business rule violations (insufficient inventory, duplicate email)
- Predictable failure states (not found, already exists)

### Validation Layer

Don't validate in resolvers—extract validation to a separate layer:

```typescript
// Bad: validation in resolver
async createProduct(parent, args, context) {
  if (!args.input.title) {
    throw new Error("Title required");
  }
  // ...
}

// Good: validation layer
async createProduct(parent, args, context) {
  const validation = validateProductInput(args.input);
  if (!validation.success) {
    return { __typename: "ValidationError", ...validation.error };
  }
  // ...
}
```

This keeps resolvers focused on orchestration, not business rules.

### Error Formatting Hook

Most GraphQL servers provide a hook to format errors before sending them to clients:

```typescript
const server = new ApolloServer({
  schema,
  formatError: (error) => {
    // Remove stack traces in production
    if (process.env.NODE_ENV === "production") {
      delete error.extensions.exception;
    }
    // Add error codes
    error.extensions.code = classifyError(error);
    return error;
  },
});
```

Use this to sanitize errors and add consistent structure.

## Key Questions

1. **When should an error go in the top-level `errors` array vs. a union result type?** What's the decision criteria?

2. **What happens when a non-null field's resolver throws?** Trace the null propagation through the response tree.

3. **How do you distinguish between "field is null because the data is null" vs. "field is null because an error occurred"?** Check the `errors` array and match by `path`.

4. **What information should you include in error `extensions` in development vs. production?** Stack traces? Database error messages?

5. **Why use error codes instead of just messages?** What happens when you need to change a message for i18n?

6. **How do you test error scenarios?** Do you trigger them with invalid inputs, or mock underlying layers to fail?

## Implementation Notes by Framework

### graphql-js (TypeScript/JavaScript)

Throw `GraphQLError` for top-level errors:

```typescript
import { GraphQLError } from "graphql";

throw new GraphQLError("Product not found", {
  extensions: { code: "NOT_FOUND" },
});
```

For union errors, return objects:

```typescript
if (!isValid) {
  return {
    __typename: "ValidationError",
    message: "Invalid input",
    field: "title",
    code: "REQUIRED_FIELD",
  };
}
return {
  __typename: "CreateProductSuccess",
  product: newProduct,
};
```

### gqlgen (Go)

Define error types that implement the error interface:

```go
type ValidationError struct {
    Message string
    Field   *string
    Code    string
}
```

Resolvers return these types directly. gqlgen handles the union discrimination.

### Strawberry (Python)

Use Python's union syntax:

```python
@strawberry.type
class ValidationError:
    message: str
    field: Optional[str]
    code: str

CreateProductResult = Union[CreateProductSuccess, ValidationError]

@strawberry.mutation
def create_product(self, input: CreateProductInput) -> CreateProductResult:
    if not input.title:
        return ValidationError(
            message="Title is required",
            field="title",
            code="REQUIRED_FIELD"
        )
    return CreateProductSuccess(product=new_product)
```

### Hot Chocolate (.NET)

Hot Chocolate has built-in error handling via exceptions with error filters:

```csharp
public class ValidationError {
    public string Message { get; set; }
    public string? Field { get; set; }
    public string Code { get; set; }
}

[UnionType("CreateProductResult")]
public interface ICreateProductResult { }

public class CreateProductSuccess : ICreateProductResult {
    public Product Product { get; set; }
}
```

### graphql-java (Java/Kotlin)

Throw `GraphQLException` or implement `GraphQLError` interface:

```java
throw new GraphQLException("Product not found",
    Map.of("code", "NOT_FOUND"));
```

For union returns, use inheritance and return the appropriate subtype.

## Official Documentation

- [GraphQL Response Format](https://graphql.org/learn/response/)
- [GraphQL Validation](https://graphql.org/learn/validation/)
- [Error Handling Best Practices](https://productionreadygraphql.com/)

## Common Pitfalls

1. **Exposing internal errors**: Never send raw database errors or stack traces to clients in production. Filter via `formatError`.

2. **Overusing top-level errors for validation**: Validation failures are not exceptional—use union result types instead.

3. **Inconsistent error codes**: Define error codes as constants/enums, not magic strings scattered through resolvers.

4. **Forgetting error paths**: Include `path` in errors so clients know which field failed in complex queries.

5. **Non-null fields causing cascade failures**: Be conservative with `!`. A single non-null field error nulls the entire parent.

6. **Poor error messages**: "Invalid input" is useless. "Email must be a valid email address" is actionable.

## What Success Looks Like

After completing this stage:

- You can distinguish between expected domain errors and unexpected system failures
- Union result types communicate validation failures clearly
- Top-level errors include structured error codes in `extensions`
- Null propagation is handled correctly for non-null fields
- Error messages are helpful without leaking sensitive information
- Both success and error paths are tested

The test suite will verify all of these behaviors through scenarios that trigger validation errors, system errors, and partial successes. Your implementation should handle each case according to GraphQL best practices.
