# Stage 07: Interfaces and Unions

## What This Stage Teaches

This stage introduces **abstract types** in GraphQL: interfaces and unions. These features enable polymorphism—querying fields that can return multiple different types. You'll implement the `Node` interface (global object identification), the `Timestamped` interface (shared timestamp fields), and a `SearchResult` union that can return Products, Categories, or Users.

Abstract types are GraphQL's answer to "how do I query heterogeneous data?" When a field can return different types (e.g., search results that include products, users, and categories), unions let you model that explicitly. When multiple types share common fields (e.g., every entity has an `id`, several have timestamps), interfaces reduce duplication and enable generic queries.

## Why These Patterns Matter

**Interfaces enable code reuse and generic patterns.** The `Node` interface implements the [Relay Global Object Identification](https://relay.dev/graphql/objectidentification.htm) pattern: every entity has a globally unique ID, and you can fetch any entity by ID with a single query: `node(id: "...")`. This is powerful for caching, refetching, and building generic UI components.

**Unions enable heterogeneous result sets.** The `SearchResult` union lets a single `search(term: String!)` query return products, categories, and users—without forcing them into a shared interface. This models the real-world scenario where search results contain fundamentally different types that happen to match a query.

**Type narrowing with inline fragments.** When querying a union, you use inline fragments (`... on Product`) to request type-specific fields. This forces clients to handle all possible types, preventing runtime errors from unexpected types.

## Mental Models

**Interfaces as Contracts:** An interface declares "any type implementing me must have these fields." `Node` requires `id: ID!`. Any type implementing `Node` (Product, Category, User, Review) must provide that field. Interfaces enable writing resolvers that work generically across types.

**Unions as Enums of Types:** A union is like an enum, but for types instead of values. `SearchResult = Product | Category | User` means "a search result is one of these three types." Unlike interfaces, union members don't need shared fields—they're just alternatives.

**The `__typename` Meta-Field:** Every GraphQL type has a `__typename` field that returns the concrete type name. This is essential for clients to distinguish union members or interface implementations. In client code, you check `__typename` to know which type-specific fields are available.

**Global Object Identification:** The `node(id: ID!)` query is a Relay convention: encode the type in the ID (e.g., `base64("Product:123")`), parse it server-side, and dispatch to the correct resolver. This pattern enables refetching any object by ID without knowing its type upfront.

## Key Questions

- **What's the difference between an interface and a union?** When would you use each?
- **How does the `node(id: ID!)` resolver know which type to return?** How are IDs structured to support this?
- **Can a type implement multiple interfaces?** How do you query fields from multiple interfaces?
- **Why does `SearchResult` not have shared fields?** Could you use an interface instead?
- **What happens if you query a union without inline fragments?** Will it return anything?
- **How do you handle a new type being added to a union?** What breaks in existing queries?

## Implementation Notes

### graphql-js (JavaScript/TypeScript)

Interfaces require a `resolveType` function that returns the concrete type name (e.g., `"Product"`). Unions require the same. For `node(id)`, decode the ID to determine the type, then call the appropriate data loader or resolver. Use `GraphQLInterfaceType` and `GraphQLUnionType` in schema definitions.

### gqlgen (Go)

In the schema, declare interfaces and unions in SDL. gqlgen generates `Is<InterfaceName>()` methods on each implementing type. For `resolveType`, return the type name string. For `node(id)`, parse the ID and dispatch to the correct resolver. Use type assertions to distinguish union members.

### Hot Chocolate (.NET)

Interfaces are defined via classes or interfaces annotated with `[InterfaceType]`. Unions use `[UnionType]`. Implement `Resolve` methods for abstract types to return the correct concrete instance. For `node(id)`, decode the ID and call the appropriate repository method. Hot Chocolate handles `__typename` automatically.

### Strawberry (Python)

Define interfaces with `@strawberry.interface` and unions with `strawberry.union`. Implement `resolve_type` for interfaces and unions to return the concrete type. For `node(id)`, decode the ID and dispatch to the correct data loader. Use `typing.Union` for union types.

### graphql-java (Java)

Use `GraphQLInterfaceType` and `GraphQLUnionType`. Implement `TypeResolver` to return the correct `GraphQLObjectType` for interfaces and unions. For `node(id)`, parse the global ID and call the appropriate service method. Use `instanceof` checks to handle union types.

## Official GraphQL Documentation

- [Schemas - Interfaces](https://graphql.org/learn/schema/#interfaces)
- [Schemas - Union Types](https://graphql.org/learn/schema/#union-types)
- [Queries - Inline Fragments](https://graphql.org/learn/queries/#inline-fragments)
- [Global Object Identification Specification](https://relay.dev/graphql/objectidentification.htm)
- [GraphQL Specification - Interfaces](https://spec.graphql.org/October2021/#sec-Interfaces)
- [GraphQL Specification - Unions](https://spec.graphql.org/October2021/#sec-Unions)

## What You're Building

You'll modify existing types to implement interfaces and add two new query fields:

1. **Node interface:** Applied to Product, Category, User, Review—all have `id: ID!`
2. **Timestamped interface:** Applied to Product, User, Review—all have `createdAt` and `updatedAt`
3. **SearchResult union:** `Product | Category | User`
4. **node(id: ID!)** query: Fetch any entity by global ID
5. **search(term: String!)** query: Full-text search returning mixed types

Your schema is now more expressive: clients can fetch "anything with an ID" via `node`, or search across multiple entity types with `search`. The type system enforces correct usage—clients must use inline fragments to access type-specific fields on unions.

## Testing Approach

The feature files verify:

- Querying interface fields without type-specific fragments works
- Querying type-specific fields requires inline fragments
- `node(id)` returns the correct type for each entity
- `__typename` resolves correctly for all types
- `search(term)` returns mixed types, and inline fragments select correct fields
- A type implementing multiple interfaces exposes all interface fields

This stage tests your GraphQL execution engine's handling of abstract types, a critical feature for advanced schemas.
