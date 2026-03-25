# Stage 03: Relationships

## What This Stage Teaches

This stage introduces object-to-object relationships in GraphQL: how one type references another, how resolvers chain together, and how the parent argument works. You'll add a `Category` type and connect it to `Product` in a many-to-many relationship. This is where GraphQL's graph nature becomes clear—you're no longer returning flat data, but a connected graph of entities.

## Why It Matters

**GraphQL is named after graphs for a reason.** In REST, relationships require multiple endpoints or embedded data that may or may not be what the client needs. In GraphQL, relationships are first-class: a field's type can be another object, and the query determines how deeply to traverse. A client can ask for `products { title }` or `products { categories { name } }` or even `products { categories { products { title } } }`—it's the same schema, just different queries.

Understanding the parent argument is crucial. When you query `product(id: "123") { categories { name } }`, GraphQL:

1. Calls `Query.product` resolver with `args.id = "123"`, returns a product object
1. For each `Product.categories` field requested, calls the `Product.categories` resolver with the **parent product object** as the first argument
1. That resolver knows which product it's resolving for, and can look up that product's categories

This resolver chaining is how GraphQL builds the response tree. Each resolver is focused and composable—`Product.categories` doesn't care how the product was fetched, it just needs the product object.

## Mental Models

**Resolvers as a Tree Walk**: Imagine your GraphQL query as a tree. Each level of nesting is a new resolver call. The parent argument is how data flows down the tree. The root Query resolver fetches the top-level data. Each field resolver receives its parent's result and fetches the next level.

**The N+1 Problem Preview**: If you query 100 products each with their categories, and your `Product.categories` resolver runs a database query per product, you just made 1 query for products + 100 queries for categories = 101 queries. This is the N+1 problem. For now, just notice it. Stage 08 teaches the solution (DataLoader). Understanding the problem first is key.

**Bidirectional Relationships**: `Product.categories` returns categories for a product. `Category.products` returns products in a category. These are two separate resolvers. GraphQL doesn't automatically infer the inverse—you implement both sides. This is intentional: the schema is explicit, not magic.

## Key Questions

After completing this stage, you should be able to answer:

1. **What are the four arguments every resolver receives, and what is each used for?**

   - `parent`/`root`: The result from the parent field's resolver
   - `args`: Arguments passed to this field in the query
   - `context`: Shared state (DB connection, auth, etc.)
   - `info`: Metadata about the query (rarely used in basic resolvers)

1. **How does the `Product.categories` resolver know which product it's resolving for?** (It receives the product object as the parent argument)

1. **If you query `{ products { categories { products { title } } } }`, how many times is each resolver called?** (Count it: 1x for `Query.products`, N times for `Product.categories` where N = number of products, M times for `Category.products` where M = total number of category relationships)

1. **What should `Product.categories` return if a product has no categories?** (An empty array `[]`, not null—because the field type is `[Category!]!`, a non-null list)

1. **Why is the many-to-many relationship stored in a join table in the database?** (Because SQL databases don't have native many-to-many relationships; GraphQL doesn't care how you store it, only what you return)

1. **What happens if you query a relationship field but don't implement its resolver?** (Some frameworks default-resolve by property name; others return null or error)

## Implementation Notes by Framework

**graphql-js (TypeScript/JavaScript)**:

- Resolvers are functions in a resolver map or passed to the schema
- The parent argument is typically called `parent` or `source`
- For `Product.categories`, add: `Product: { categories: (parent, args, context) => fetchCategoriesForProduct(parent.id, context.db) }`
- Default behavior: if no resolver is provided, GraphQL returns the property with the same name from parent

**gqlgen (Go)**:

- Field resolvers are methods: `func (r *productResolver) Categories(ctx context.Context, obj *model.Product) ([]*model.Category, error)`
- `obj` is the parent product; `ctx` contains context including DB
- Use dataloaders pattern: `r.CategoryLoader.LoadMany(ctx, obj.CategoryIDs)`
- Join tables: query the join table in your resolver

**Hot Chocolate (.NET)**:

- Resolvers can be methods on the parent type or separate resolver classes
- Use `[Parent]` attribute to receive the parent object explicitly
- For many-to-many: query the join table or use EF Core navigation properties
- Example: `public async Task<List<Category>> GetCategories([Parent] Product product, [Service] IDbContextFactory factory)`

**Strawberry (Python)**:

- Define resolver methods on your type class: `@strawberry.field`
- First param is `self` (the parent object), then `info: strawberry.types.Info`
- Access context via `info.context`
- For many-to-many: query join table in resolver or use SQLAlchemy relationships

**graphql-java (Java)**:

- Field resolvers are `DataFetcher` implementations
- The parent is in `DataFetchingEnvironment.getSource()`
- Example: `DataFetcher<List<Category>> categoriesResolver = env -> fetchCategories(env.getSource().getId())`
- Use DataLoader for batching (Stage 08)

## Links to Official Documentation

- [Execution](https://graphql.org/learn/execution/) — How resolvers chain and the resolver signature
- [Thinking in Graphs](https://graphql.org/learn/thinking-in-graphs/) — Why GraphQL is about connected data
- [Queries and Mutations](https://graphql.org/learn/queries/#fields) — How nested fields work from the client perspective
- [Best Practices - Resolver Design](https://graphql.org/learn/best-practices/#resolver-design) — Keep resolvers focused and composable

## What You're Building

A server that:

1. Adds a `Category` type with fields: `id`, `name`, `products`
1. Adds `categories: [Category!]!` to the `Product` type
1. Adds `category(id: ID!)` and `categories: [Category!]!` to the root `Query`
1. Implements resolvers for:
   - `Query.category` and `Query.categories` — fetch categories from the database
   - `Product.categories` — given a product (parent), fetch its categories via the join table
   - `Category.products` — given a category (parent), fetch its products via the join table
1. Handles nested queries like `products { categories { products { title } } }`

The database already has a `product_categories` join table connecting products to categories. Your job is to query it in your resolvers. This is the pattern for all relationships: parent object → query database → return related objects.

Remember: each resolver is independent. `Product.categories` doesn't know if the product came from `Query.products` or `Query.product` or a nested query—it just receives a product object and returns categories. This composability is GraphQL's strength.

## Run Tests

From the repo root:

```bash
bunx --cwd test-runner cucumber-js --tags @stage:03
```
