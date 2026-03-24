# GraphQL Training Path: From Zero to Production

A progressive, language-agnostic GraphQL curriculum. Students receive schemas, test specifications, and conceptual guidance at each stage. They implement the server in whatever language/framework they choose.

---

## Table of Contents

1. [Philosophy & Design Principles](#philosophy--design-principles)
2. [Domain Model](#domain-model)
3. [Project Structure](#project-structure)
4. [Testing Architecture](#testing-architecture)
5. [Stage Breakdown](#stage-breakdown)
6. [Schema Evolution Across Stages](#schema-evolution-across-stages)
7. [What Each Stage Delivers to the Student](#what-each-stage-delivers-to-the-student)
8. [Reference Links](#reference-links)

---

## Philosophy & Design Principles

### Why This Exists

Existing GraphQL tutorials fall into two traps: they're either vendor-locked to a specific ecosystem (Apollo, Hasura, Prisma) or they hand-hold through copy-paste steps that don't build real understanding. Almost none cover testing, security, or schema evolution -- the things that separate a tutorial app from production code.

This curriculum fills those gaps:

- **Language-agnostic** -- the SDL schema and HTTP-based tests are the contract. Implement in Go, TypeScript, Python, .NET, Rust, Java, or anything that speaks HTTP + JSON.
- **Test-driven** -- each stage has Gherkin feature files that define what "done" looks like. Students implement until tests pass. No hand-holding, no step-by-step copy-paste.
- **Progressive single domain** -- one domain model that grows in complexity. Each stage adds a real capability, not a disconnected exercise.
- **Production-oriented** -- the later stages cover what tutorials ignore: DataLoader, auth patterns, security hardening, schema evolution, federation.

### The Balance: Guidance vs. Discovery

Each stage provides:

- The **target schema** (SDL) -- students know what types and fields to implement
- **Gherkin feature files** -- behavioral specs that double as test suite and requirements doc
- A **concepts brief** -- 1-2 paragraphs explaining the "why" with links to official docs for deep dives
- **Key questions** -- prompts that push students to think about design decisions

Each stage does NOT provide:

- Line-by-line implementation instructions
- Framework-specific setup guides
- Resolver code (except for illustrative pseudocode where the concept is genuinely novel)

---

## Domain Model

### Why E-Commerce (Simplified Marketplace)

After evaluating Todo apps, blogs, social media, and library systems, a **simplified marketplace** wins because it naturally demonstrates every GraphQL concept without forcing contrived examples:

| Concept                       | Natural Fit                                                                  |
| ----------------------------- | ---------------------------------------------------------------------------- |
| Object types & scalars        | Products, Users, Orders                                                      |
| Relationships (1:1, 1:N, N:M) | User -> Orders -> LineItems -> Products; Products <-> Categories             |
| Interfaces                    | `Node` (global ID), `Timestamped`                                            |
| Unions                        | `SearchResult = Product \| Category \| User`                                 |
| Enums                         | `OrderStatus`, `Role`, `SortDirection`                                       |
| Input types                   | `CreateProductInput`, `PlaceOrderInput`                                      |
| Pagination                    | Product catalog, order history, reviews                                      |
| Auth                          | Customers see own orders; sellers manage own products; admins see everything |
| Subscriptions                 | Order status changes, inventory alerts                                       |
| Filtering & sorting           | Products by price/category/rating                                            |
| DataLoader                    | Products in an order, reviews for a list of products                         |
| Remote data sources           | Shipping rates from external API, payment processing                         |
| Federation                    | Products subgraph, Orders subgraph, Users subgraph                           |

### Core Entities (Final State)

```
User (id, email, name, role)
Product (id, title, description, price, inventory, seller, categories, reviews)
Category (id, name, products)
Review (id, rating, body, author, product)
Order (id, buyer, items, status, total, createdAt)
LineItem (id, product, quantity, unitPrice)
```

These entities are introduced gradually across stages -- not all at once.

---

## Project Structure

```
/
├── stages/
│   ├── 01-hello-graphql/
│   │   ├── schema.graphql          # Target SDL for this stage
│   │   ├── concepts.md             # Brief explanation + links
│   │   ├── features/               # Gherkin test specs
│   │   │   ├── introspection.feature
│   │   │   └── queries.feature
│   │   └── (no seed data -- just a hello resolver)
│   ├── 02-types-and-enums/
│   ├── 03-relationships/
│   ├── ...
│   └── 16-federation/
├── migrations/                      # Single folder, all stages
│   ├── 000001_create_products.up.sql
│   ├── 000001_create_products.down.sql
│   ├── ...
├── seed-data/                       # Cumulative SQL seed data (shared across stages)
│   ├── base.sql                     # Products + categories (stages 02-05)
│   ├── full.sql                     # Above + users + reviews, scaled up (stages 06+)
│   └── orders.sql                   # Additive: orders + line_items (stage 12+)
├── test-runner/                     # Cucumber step definitions (one language)
│   ├── package.json                 # or pyproject.toml, go.mod, etc.
│   ├── steps/
│   │   ├── graphql.steps.ts         # HTTP-based step definitions
│   │   └── helpers.ts
│   └── cucumber.config.ts
├── mocks/                           # Mockoon environment files (external API mocks)
│   ├── shipping.json                # Shipping estimate API (stage 14)
│   ├── tax.json                     # Tax calculation API (stage 10)
│   └── currency.json                # Currency conversion API (stage 15)
├── tools/
│   ├── schema-lint.config.json      # graphql-schema-linter config
│   └── introspect.sh                # Helper to export schema from running server
├── implementations/                 # Reference implementations (optional, per-language)
│   ├── typescript/
│   ├── python/
│   └── go/
├── DATA_DESIGN.md                   # Database schema, ERD, and design decisions
└── PLAN.md                          # This document
```

### Database & Migrations

**Database:** [SQLite](https://sqlite.org/) from stage 02 onward.

SQLite is a file — zero infrastructure, no Docker, no connection strings, no server process. Every language has SQLite bindings. Students focus on GraphQL from day one, not on database setup. golang-migrate supports SQLite natively.

**Migration tool:** [golang-migrate/migrate](https://github.com/golang-migrate/migrate) (18.3k stars, MIT, standalone CLI binary)

**Why golang-migrate:**

- Language-agnostic standalone binary — no runtime dependency on Go, Node, Java, etc.
- Plain SQL up/down migration files — no DSL, no ORM coupling
- Supports 20+ databases (SQLite, Postgres, MySQL, MongoDB, CockroachDB, Spanner, etc.)
- `goto V` command lets us target a specific migration version, which maps perfectly to our staged curriculum
- Also usable as a Go library if needed later

**Alternatives considered:**
| Tool | Stars | Why not |
|------|-------|---------|
| Flyway | 9.6k | Java dependency, commercial tiers |
| Liquibase | 5.5k | Java dependency, FSL license, XML/YAML overhead |
| Atlas | 8.2k | Declarative approach is powerful but adds complexity we don't need — our stages are inherently sequential/versioned |
| dbmate | 6.8k | Great tool, but fewer DB drivers and no `goto V` equivalent |
| goose | 10.4k | Go-centric, less separation between tool and language ecosystem |

Migrations are numbered sequentially. Each stage in the curriculum maps to a range of migration versions:

| Stage | Migrations | Description                               |
| ----- | ---------- | ----------------------------------------- |
| 01    | —          | No database (just `{ hello }`)            |
| 02-05 | 1–3        | Products, categories, product_categories  |
| 06    | 4–5        | Users, reviews tables                     |
| 09    | 6          | Pagination indexes on products            |
| 12    | 7–10       | Orders, line_items, seller_id on products |
| 15    | 11         | Pricing table (schema evolution)          |

_(Numbers are illustrative — actual counts will vary as we build out each stage.)_

**Environment configuration:**

We use two env files:

- **`local.env`** — checked into git. Contains default/example values for all required environment variables. This is the template.
- **`.env`** — git-ignored (already in `.gitignore`). Contains the developer's actual local overrides. Created from `local.env` via a task command.

```bash
# local.env (committed)
DB_FILE=graphql_training.db
SERVER_PORT=4000
NODE_ENV=development
SHIPPING_API_URL=http://localhost:4010
TAX_API_URL=http://localhost:4011
CURRENCY_API_URL=http://localhost:4012
```

The `.env` file is the source of truth at runtime. All task commands load from `.env` via Taskfile's `dotenv` support.

**Taskfile integration:**

A `Taskfile.yml` at the project root provides ergonomic commands for environment setup, migrations, and database management:

```yaml
version: "3"

dotenv: [".env"]

vars:
  MIGRATIONS_DIR: ./migrations
  SEED_DIR: ./seed-data

tasks:
  env:init:
    desc: Create .env from local.env (will not overwrite existing .env)
    cmds:
      - cp -n local.env .env
      - echo ".env created from local.env — edit as needed."
    status:
      - test -f .env

  env:reset:
    desc: Overwrite .env with local.env defaults
    cmds:
      - cp local.env .env
      - echo ".env reset to local.env defaults."

  migrate:up:
    desc: Run all pending migrations
    cmds:
      - migrate -source file://{{.MIGRATIONS_DIR}} -database "sqlite3://{{.DB_FILE}}" up

  migrate:down:
    desc: Roll back N migrations (default 1)
    cmds:
      - migrate -source file://{{.MIGRATIONS_DIR}} -database "sqlite3://{{.DB_FILE}}" down {{.N | default "1"}}

  migrate:goto:
    desc: Migrate to a specific version (e.g. task migrate:goto V=6)
    cmds:
      - migrate -source file://{{.MIGRATIONS_DIR}} -database "sqlite3://{{.DB_FILE}}" goto {{.V}}

  migrate:version:
    desc: Print current migration version
    cmds:
      - migrate -source file://{{.MIGRATIONS_DIR}} -database "sqlite3://{{.DB_FILE}}" version

  migrate:force:
    desc: Force set version without running migration (fixes dirty state)
    cmds:
      - migrate -source file://{{.MIGRATIONS_DIR}} -database "sqlite3://{{.DB_FILE}}" force {{.V}}

  migrate:create:
    desc: Create a new migration pair (e.g. task migrate:create NAME=create_users)
    cmds:
      - migrate create -ext sql -dir {{.MIGRATIONS_DIR}} -seq {{.NAME}}

  db:reset:
    desc: Reset DB to clean state for a given stage (e.g. task db:reset STAGE=03)
    vars:
      STAGE_MAP:
        sh: |
          case "{{.STAGE}}" in
            01) echo 0 ;;
            02|03|04|05) echo 3 ;;
            06|07|08) echo 5 ;;
            09|10|11) echo 6 ;;
            12) echo 10 ;;
            13) echo 10 ;;
            14) echo 10 ;;
            15) echo 11 ;;
            16) echo 11 ;;
            *) echo "unknown" ;;
          esac
      SEED_FILE:
        sh: |
          case "{{.STAGE}}" in
            01) echo "none" ;;
            02|03|04|05) echo "base.sql" ;;
            06|07|08|09|10|11) echo "full.sql" ;;
            12|13|14|15|16) echo "full_with_orders.sql" ;;
            *) echo "unknown" ;;
          esac
    cmds:
      - |
        if [ "{{.STAGE_MAP}}" = "unknown" ]; then
          echo "Unknown stage: {{.STAGE}}. Valid stages: 01-16."
          exit 1
        fi
        rm -f {{.DB_FILE}}
        if [ "{{.STAGE_MAP}}" != "0" ]; then
          migrate -source file://{{.MIGRATIONS_DIR}} -database "sqlite3://{{.DB_FILE}}" goto {{.STAGE_MAP}}
          if [ "{{.SEED_FILE}}" != "none" ]; then
            sqlite3 {{.DB_FILE}} < {{.SEED_DIR}}/{{.SEED_FILE}}
          fi
        fi
        echo "DB reset for stage {{.STAGE}} (migration v{{.STAGE_MAP}}, seed: {{.SEED_FILE}})"

  mocks:start:
    desc: Start all mock external services
    cmds:
      - mockoon-cli start --data ./mocks/shipping.json --port 4010 &
      - mockoon-cli start --data ./mocks/tax.json --port 4011 &
      - mockoon-cli start --data ./mocks/currency.json --port 4012 &
      - echo "Mock services started on ports 4010, 4011, 4012"

  mocks:stop:
    desc: Stop all mock external services
    cmds:
      - mockoon-cli stop all
```

**Usage examples:**

```bash
# First time setup — create .env from local.env
task env:init

# Reset DB for a specific stage (deletes DB file, migrates, seeds)
task db:reset STAGE=03

# Run all migrations
task migrate:up

# Migrate to version 6
task migrate:goto V=6

# Roll back 1 migration
task migrate:down

# Roll back 3 migrations
task migrate:down N=3

# Check current version
task migrate:version

# Create a new migration
task migrate:create NAME=create_orders

# Start mock API servers (for stages 14+)
task mocks:start
```

### External API Mocks

**Tool:** [Mockoon](https://github.com/mockoon/mockoon) (8.2k stars, MIT, standalone CLI)

**Why Mockoon:**

- **Zero code** — mocks are defined as JSON config files, not code in any language
- **Language-agnostic** — runs as a separate HTTP server on a port, exactly like a real external API would. Works regardless of what language the student's server is written in
- **Built-in features we need:** response templating, latency simulation, sequential responses (first call succeeds, second fails), rules-based routing, error/5xx responses
- **Git-friendly** — `.json` environment files checked into the repo under `mocks/`
- **No heavyweight dependencies** — runs via `npx @mockoon/cli`, global npm install, or Docker

**Alternatives considered:**
| Tool | Stars | Why not |
|------|-------|---------|
| WireMock | 7.2k | Requires Java runtime |
| Prism (Stoplight) | 4.9k | Requires OpenAPI specs first, limited failure simulation |
| MSW | 17.8k | In-process interceptor — only works if student uses Node.js, breaks language-agnostic requirement |
| nock | 13.1k | Same — Node.js in-process only |
| DIY Express mock | — | We'd be writing and maintaining mock server code; Mockoon does it better with zero code |

**Mock services:**

| Mock                | Port | Stage | Purpose                                                                                                |
| ------------------- | ---- | ----- | ------------------------------------------------------------------------------------------------------ |
| Shipping estimates  | 4010 | 14    | `GET /estimate?zip=...` — teaches read-path external calls, graceful degradation                       |
| Tax calculation     | 4011 | 10    | `GET /tax-rate?state=...` — teaches write-path external dependency (mutations fail if service is down) |
| Currency conversion | 4012 | 15    | `GET /rates?base=USD` — teaches cached external data, TTL                                              |

Each mock includes routes for success responses, error responses (5xx), and latency simulation, so students can test graceful degradation and timeout handling.

---

### Why This Structure

- **`stages/` is the curriculum.** Students work through them in order. Each stage is self-contained with its schema, tests, and concepts doc.
- **`test-runner/` is written once** in a single language (likely TypeScript or Python). It makes HTTP calls to the student's server -- the student never touches these files.
- **`implementations/` is optional.** Reference implementations help if students get stuck, but they're not the point. The schema + tests are the point.
- **No git branch gymnastics.** Everything is in one tree. Students can see what's coming and reference earlier stages.

### How a Student Works

1. Read `stages/03-relationships/concepts.md`
2. Read `stages/03-relationships/schema.graphql` -- this is their target
3. Read `stages/03-relationships/features/*.feature` -- this is their test spec
4. Reset the database: `task db:reset STAGE=03`
5. Implement in their language of choice
6. Start their server on a configurable port
7. Run: `cd test-runner && npm test -- --stage 03` (or equivalent)
8. Iterate until all scenarios pass

---

## Testing Architecture

### The HTTP Boundary

GraphQL is served over HTTP with a specified request/response format ([spec](https://graphql.org/learn/serving-over-http/)). This is the language-agnostic testing boundary:

```
[Gherkin Feature Files]
        |
        v
[Step Definitions] -- HTTP POST --> [Student's Server (any language)]
        |                                       |
        v                                       v
[Assert on JSON response]            [GraphQL execution engine]
```

### Database Reset

The test runner assumes the database is in a known state before tests run. This is handled outside the HTTP boundary via the Taskfile:

```bash
# Before running tests for a stage
task db:reset STAGE=03
```

This deletes the SQLite file, runs migrations to the correct version, and loads the appropriate seed SQL. The student's server connects to the same SQLite file. No custom seed endpoints needed.

### Three Testing Layers

**Layer 1: Schema Linting (static, no server needed)**

- Tool: `graphql-schema-linter` against the stage's target SDL
- Validates: naming conventions, descriptions, deprecation reasons, Relay conventions
- Students export their schema as SDL; linter checks it matches conventions
- Run: `graphql-schema-linter stages/05-pagination/schema.graphql`

**Layer 2: Introspection Tests (server must be running)**

- Gherkin scenarios that send introspection queries
- Verify: types exist, fields have correct types, interfaces are implemented, enums have expected values
- These test the schema structure at runtime, catching mismatches between what the student thinks they defined and what the server actually exposes

**Layer 3: Behavioral Tests (server must be running, with seed data)**

- Gherkin scenarios that send real queries/mutations and verify responses
- Verify: data resolution, relationships, error handling, auth, pagination, subscriptions
- Progressive -- each stage adds new feature files

### Gherkin Step Definition Vocabulary

The test runner needs a small, reusable set of step definitions:

```gherkin
# Setup
Given the GraphQL endpoint is "{url}"
Given I am authenticated as "{role}"          # Sets Authorization header
Given I am not authenticated                  # Clears Authorization header

# Actions
When I send a GraphQL query:
  """
  { products { id title } }
  """
When I send a GraphQL mutation:
  """
  mutation { ... }
  """
When I set the variable "{name}" to "{value}"
When I set the variable "{name}" to:           # For complex objects
  | key   | value |
  | title | Foo   |
When I send the subscription:
  """
  subscription { orderStatusChanged(orderId: "...") { status } }
  """

# Assertions
Then the response status should be {int}
Then the response should contain "data.{path}"
Then the response "data.{path}" should equal {value}
Then the response "data.{path}" should be an array
Then the response "data.{path}" should have {int} items
Then each item in "data.{path}" should have fields "{field_list}"
Then the response should contain "errors"
Then the response should not contain "errors"
Then the response "errors[0].message" should contain "{text}"
Then the response "errors[0].extensions.code" should equal "{code}"
Then the response "data.{path}" should be null
Then the subscription should receive an event within {int} seconds
Then the subscription event "data.{path}" should equal {value}
```

This vocabulary covers every stage. New stages don't need new step definitions -- just new feature files.

### Example Feature File (Stage 03: Relationships)

```gherkin
Feature: Product-Category Relationships

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query a product with its categories
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-1") {
          title
          categories {
            id
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.title" should equal "Mechanical Keyboard"
    Then the response "data.product.categories" should be an array
    Then each item in "data.product.categories" should have fields "id, name"

  Scenario: Query a category with its products
    When I send a GraphQL query:
      """
      query {
        category(id: "cat-1") {
          name
          products {
            id
            title
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.category.products" should be an array

  Scenario: Nested traversal (product -> categories -> products)
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-1") {
          categories {
            products {
              id
              title
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "data.product.categories[0].products"
```

### Seed Data Strategy

Seed data is **cumulative SQL files**, not per-stage. Three files in `seed-data/` grow with the curriculum:

| File                   | Contents                                                                                | Used by stages | Records      |
| ---------------------- | --------------------------------------------------------------------------------------- | -------------- | ------------ |
| `base.sql`             | Products (5-10), categories (3-5), product-category links                               | 02-05          | ~20 records  |
| `full.sql`             | Everything in base + users (5-10, mixed roles) + reviews (100+), scaled to 50+ products | 06-11          | ~200 records |
| `full_with_orders.sql` | Everything in full + orders (10+) + line_items (30+)                                    | 12+            | ~240 records |

**Why cumulative:** Most stages add zero new data -- they build new GraphQL features on top of existing data. Maintaining 16 copies of growing seed data would be a nightmare.

**Why SQL (not JSON):** The database exists from stage 02. SQL seed files are loaded directly via `sqlite3 $DB_FILE < seed-data/base.sql`. No custom endpoint needed, no `POST /seed` handler for students to build, no JSON-to-SQL mapping code. Students focus on GraphQL, not data-loading plumbing.

**How it works:** The `task db:reset STAGE=XX` command handles everything — deletes the SQLite file, runs migrations to the correct version, and loads the right seed file. The test runner calls this before running tests (or students run it manually).

```bash
# Reset for stage 03 — creates DB, migrates to v3, loads base.sql
task db:reset STAGE=03

# Reset for stage 08 — migrates to v5, loads full.sql
task db:reset STAGE=08

# Reset for stage 12 — migrates to v10, loads full_with_orders.sql
task db:reset STAGE=12
```

---

## Stage Breakdown

### Stage 01: Hello GraphQL

**Concepts:** What GraphQL is. The single endpoint. Schema-first thinking. The SDL. Root Query type.

**Data:** None. No database.

**Schema:**

```graphql
type Query {
  hello: String!
}
```

**What the student builds:** A server that exposes `/graphql` and resolves a single field.

**Tests verify:**

- Server responds on `/graphql`
- Introspection works (Query type exists)
- `{ hello }` returns `{ "data": { "hello": "..." } }`
- Response content-type is JSON

**Key questions:**

- What happens if you query a field that doesn't exist?
- What does the error response look like?

**Links:** [Introduction to GraphQL](https://graphql.org/learn/), [Serving over HTTP](https://graphql.org/learn/serving-over-http/)

---

### Stage 02: Types, Enums, and Your First Real Type

**Concepts:** The five built-in scalars. Object types. Non-null (`!`) and list (`[]`) modifiers. Enums. Field arguments. Connecting to SQLite.

**Data:** `seed-data/base.sql` — 5-10 products loaded into SQLite via `task db:reset STAGE=02`.

**Why SQLite from the start:** SQLite is a file — zero infrastructure. Every language has bindings. Students set up their database connection once and build on it for the rest of the curriculum. No throwaway in-memory code, no "migrate to a real DB" busywork later.

**DB tables created:** `products`, `categories`, `product_categories` (via migrations 1-3).

**Schema:**

```graphql
type Query {
  product(id: ID!): Product
  products: [Product!]!
}

type Product {
  id: ID!
  title: String!
  description: String
  price: Float!
  inStock: Boolean!
  status: ProductStatus!
}

enum ProductStatus {
  DRAFT
  ACTIVE
  ARCHIVED
}
```

**What the student builds:** SQLite database connection. Resolvers for the Query fields that read from the DB.

**Tests verify:**

- Introspection: `Product` type has correct fields with correct types and nullability
- `ProductStatus` enum has expected values
- `products` returns a non-empty array
- `product(id: "...")` returns a single product or null
- Non-null fields are never null
- Enum field returns a valid enum value

**Key questions:**

- What's the difference between `String` and `String!`?
- What happens when you return `null` for a `String!` field?
- Why is `description` nullable but `title` isn't?
- Why is `ID` a separate scalar from `String`?
- What goes in the context object and why? (DB connection)

**Links:** [Schemas and Types](https://graphql.org/learn/schema/)

---

### Stage 03: Relationships

**Concepts:** Object types referencing other object types. The parent/root argument in resolvers. 1:N and M:N relationships. Nested query resolution.

**Data:** Same `seed-data/base.sql` — includes categories + product-category links.

**New schema additions:**

```graphql
type Query {
  # ... existing
  category(id: ID!): Category
  categories: [Category!]!
}

type Product {
  # ... existing fields
  categories: [Category!]!
}

type Category {
  id: ID!
  name: String!
  products: [Product!]!
}
```

**What the student builds:** A second type (`Category`) with bidirectional relationships to `Product`. The `Product.categories` resolver receives the parent product and must look up its categories.

**Tests verify:**

- Product -> Categories resolution
- Category -> Products resolution
- Nested traversal (product -> categories -> products)
- Empty relationships return empty arrays (not null)

**Key questions:**

- How does the resolver for `Product.categories` know which product it's resolving for?
- What are the four arguments a resolver receives? (parent, args, context, info)
- If you query `{ products { categories { products { title } } } }`, how many resolver calls happen?

**Links:** [Queries and Mutations](https://graphql.org/learn/queries/), [Execution](https://graphql.org/learn/execution/)

---

### Stage 04: Mutations and Input Types

**Concepts:** Mutations vs queries. Input types. Why mutations have dedicated input/payload types. Serial execution of top-level mutation fields.

**Data:** Same `seed-data/base.sql`. Mutations modify this data.

**New schema additions:**

```graphql
type Mutation {
  createProduct(input: CreateProductInput!): CreateProductPayload!
  updateProduct(id: ID!, input: UpdateProductInput!): UpdateProductPayload!
}

input CreateProductInput {
  title: String!
  description: String
  price: Float!
  categoryIds: [ID!]
}

input UpdateProductInput {
  title: String
  description: String
  price: Float
  status: ProductStatus
}

type CreateProductPayload {
  product: Product
}

type UpdateProductPayload {
  product: Product
}
```

**What the student builds:** Two mutations -- create and update. (Delete is left as an optional exercise, not a test requirement. Two mutations are enough to teach the pattern without boilerplate fatigue.)

**Tests verify:**

- Create a product, query it back
- Update a product, verify changes
- Input validation (missing required fields produce errors)
- Payload types return the expected data
- Creating a product with categoryIds links them correctly

**Key questions:**

- Why use `CreateProductInput` instead of individual arguments?
- Why do mutations return payload types instead of the entity directly?
- Why are `UpdateProductInput` fields all optional?
- What's the difference between `input` and `type` in SDL?

**Links:** [Mutations](https://graphql.org/learn/queries/#mutations)

---

### Stage 05: Query Language Features

**Concepts:** Variables, aliases, fragments (named and inline), directives (`@include`, `@skip`), operation names.

**Data:** Same. No new data needed.

**No schema changes.** This stage is about the query language, not the server schema. A breather stage after mutations.

**Tests verify:**

- Variables work: `query GetProduct($id: ID!) { product(id: $id) { title } }`
- Aliases work: `{ first: product(id: "1") { title } second: product(id: "2") { title } }`
- Named fragments work: `fragment ProductFields on Product { id title price }`
- `@include(if: $bool)` conditionally includes fields
- `@skip(if: $bool)` conditionally skips fields
- Operation names are accepted

**Key questions:**

- When would you use aliases in a real application?
- Why use variables instead of string interpolation?
- What's the difference between named and inline fragments?

**Links:** [Queries - Variables](https://graphql.org/learn/queries/#variables), [Queries - Fragments](https://graphql.org/learn/queries/#fragments), [Queries - Directives](https://graphql.org/learn/queries/#directives)

---

### Stage 06: Users and Reviews

**Concepts:** Adding multiple related types at once. N:1 relationships (review -> author, review -> product). Expanding the data model with real purpose.

**Data:** Switch to `seed-data/full.sql` — scales up to 50+ products, adds 5-10 users (mixed roles), 100+ reviews.

**Why these two together:** Users without reviews are inert (nothing references them). Reviews without users have no author. Introducing them together means both types are immediately useful: `Product.reviews`, `Review.author`, `User.reviews` are all queryable from day one.

**New DB tables:** `users`, `reviews`

**New schema additions:**

```graphql
type Query {
  # ... existing
  user(id: ID!): User
  users: [User!]!
}

type User {
  id: ID!
  email: String!
  name: String!
  reviews: [Review!]!
  createdAt: String!
  updatedAt: String!
}

type Review {
  id: ID!
  rating: Int!
  body: String
  author: User!
  product: Product!
  createdAt: String!
  updatedAt: String!
}

type Product {
  # ... existing fields
  reviews: [Review!]!
  averageRating: Float
}

type Mutation {
  # ... existing
  createReview(input: CreateReviewInput!): CreateReviewPayload!
}

input CreateReviewInput {
  productId: ID!
  rating: Int!
  body: String
}

type CreateReviewPayload {
  review: Review
}
```

**Tests verify:**

- `product.reviews` returns reviews for that product
- `review.author` resolves to the correct user
- `user.reviews` returns reviews written by that user
- `product.averageRating` computes correctly
- `createReview` creates a review and links it to product + author
- One review per user per product (unique constraint)

**Key questions:**

- How is the N:1 relationship (review -> author) different from the M:N (product <-> categories)?
- What resolver pattern do you use for `Product.averageRating` -- compute in resolver, or database aggregate?
- How does adding reviews change the shape of your product queries?

---

### Stage 07: Interfaces and Unions

**Concepts:** Abstract types. Polymorphism in GraphQL. `__typename`. Inline fragments for type narrowing.

**Data:** Same `seed-data/full.sql`. No new data -- this is a schema/resolver concept stage.

**Why now (not earlier):** We now have 4 entity types (Product, Category, User, Review) which makes interfaces and unions meaningful. `SearchResult = Product | Category | User` returns genuinely different types. The `Node` interface applies to all entities. Previously with only Product + Category, the examples would have been thin.

**New schema additions:**

```graphql
interface Node {
  id: ID!
}

interface Timestamped {
  createdAt: String!
  updatedAt: String!
}

type Product implements Node & Timestamped { ... }
type Category implements Node { ... }
type User implements Node & Timestamped { ... }
type Review implements Node & Timestamped { ... }

union SearchResult = Product | Category | User

type Query {
  node(id: ID!): Node
  search(term: String!): [SearchResult!]!
  # ... existing fields
}
```

**Tests verify:**

- `node(id: "...")` returns the correct type based on the ID
- `__typename` resolves correctly on each concrete type
- Inline fragments resolve type-specific fields: `... on Product { price }`
- `search(term: "...")` returns mixed types
- Querying interface fields works without fragments
- Querying union members requires inline fragments (no shared fields)

**Key questions:**

- When do you use an interface vs. a union?
- How does `node(id: ID!)` know which type to resolve? (Global Object Identification pattern)
- Why does `Node` only have `id`? Why not add more shared fields?

**Links:** [Schemas - Interfaces](https://graphql.org/learn/schema/#interfaces), [Schemas - Union Types](https://graphql.org/learn/schema/#union-types), [Global Object Identification](https://graphql.org/learn/global-object-identification/)

---

### Stage 08: The N+1 Problem and DataLoader

**Concepts:** What N+1 is. Why it appears naturally in GraphQL. The DataLoader pattern (batching + per-request memoization).

**Data:** Same `seed-data/full.sql`. The 50+ products and 100+ reviews are specifically sized to make N+1 visible.

**No schema changes.** This stage adds a performance optimization layer.

**Tests verify:**

- All previous tests still pass
- Performance test: query all products with their reviews and categories -- response time should be under a threshold
- Query that triggers the same entity multiple times returns consistent data (memoization)

**Feature file approach for N+1:**

```gherkin
Scenario: Products with reviews resolves efficiently
  When I send a GraphQL query:
    """
    query {
      products {
        id
        title
        reviews { id rating author { name } }
        categories { id name }
      }
    }
    """
  Then the response status should be 200
  Then the response "data.products" should have at least 50 items
  Then the response time should be less than 500 milliseconds
```

**Key questions:**

- How many database queries does your products-with-reviews query execute? Count them.
- What's the difference between DataLoader's per-request cache and a shared cache?
- Why must DataLoaders be created per-request, not globally?
- What does the batch function's contract look like? (Keys in, values out, same order, same length)

**Links:** [DataLoader GitHub](https://github.com/graphql/dataloader)

---

### Stage 09: Pagination

**Concepts:** Why offset pagination breaks. Cursor-based pagination. The Relay Connection specification (Connections, Edges, Nodes, PageInfo).

**Data:** Same `seed-data/full.sql`. 50+ products make pagination meaningful.

**New schema additions:**

```graphql
type Query {
  productsConnection(
    first: Int
    after: String
    last: Int
    before: String
    filter: ProductFilterInput
  ): ProductConnection!
  # Keep products: [Product!]! for backwards compat, marked deprecated
  products: [Product!]! @deprecated(reason: "Use productsConnection instead")
}

input ProductFilterInput {
  categoryId: ID
  minPrice: Float
  maxPrice: Float
  status: ProductStatus
}

type ProductConnection {
  edges: [ProductEdge!]!
  pageInfo: PageInfo!
  totalCount: Int!
}

type ProductEdge {
  node: Product!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  hasPreviousPage: Boolean!
  startCursor: String
  endCursor: String
}
```

**Tests verify:**

- `first: 5` returns exactly 5 items
- `after` cursor returns the next page
- `pageInfo.hasNextPage` is true when more items exist
- `pageInfo.endCursor` matches the last edge's cursor
- Forward pagination walks through all items without duplicates or gaps
- Filtering works in combination with pagination
- `totalCount` reflects filter, not total dataset
- Cursors are opaque (not plain integers)

**Key questions:**

- Why are cursors better than page numbers?
- What encoding do you use for cursors? What happens if a client tries to tamper with one?
- Why does the Connection spec have an `edges` layer instead of returning nodes directly?
- How does your cursor implementation handle items being inserted/deleted between pages?

**Links:** [Pagination](https://graphql.org/learn/pagination/)

---

### Stage 10: Error Handling

**Concepts:** GraphQL's partial success model. The `errors` array. Error extensions. Null propagation for non-null fields. Union-based errors as an alternative pattern.

**Data:** Same `seed-data/full.sql`.

**New schema additions:**

```graphql
type Mutation {
  createProduct(input: CreateProductInput!): CreateProductResult!
  # ... existing mutations updated to use result unions
}

union CreateProductResult = CreateProductSuccess | ValidationError

type CreateProductSuccess {
  product: Product!
}

type ValidationError {
  message: String!
  field: String
  code: String!
}
```

**Tests verify:**

- Invalid input returns a `ValidationError` union member (not a top-level error)
- System errors (resolver throws) appear in the top-level `errors` array
- Partial success: query two fields, one errors, the other still returns data
- Non-null field error propagates to nullable parent
- Error objects have `message`, `locations`, `path`
- Error `extensions` contain structured error codes

**Key questions:**

- When should errors be top-level `errors` vs. union-based result types?
- What happens when a `String!` field's resolver throws? Trace the null propagation.
- How does a client distinguish between "the field is null because the data is null" vs. "the field is null because an error occurred"?
- What error information should you expose in production vs. development?

**Links:** [Response Format](https://graphql.org/learn/response/), [Validation](https://graphql.org/learn/validation/)

---

### Stage 11: Authentication and Authorization

**Concepts:** Auth at the HTTP layer. Context-based auth. Field-level authorization. The business logic layer as the single source of truth for auth rules.

**Data:** Same `seed-data/full.sql`. Users already have roles from stage 06. No new data -- this stage adds access control logic on top of existing data.

**New schema additions:**

```graphql
enum Role {
  CUSTOMER
  SELLER
  ADMIN
}

type User implements Node & Timestamped {
  id: ID!
  email: String! # Only visible to self and admins
  name: String!
  role: Role!
  createdAt: String!
  updatedAt: String!
}

type Query {
  me: User # Returns the authenticated user, or null
  # users: [User!]!   # Now admin-only (existed since stage 06)
}
```

**What the student builds:** Auth middleware that extracts user identity from headers. Field-level access rules. Role checks on mutations. This stage modifies existing resolvers, not new entity types -- the focus is purely on the auth layer.

**Tests verify:**

- `me` returns the authenticated user or null when unauthenticated
- `users` returns data for admins, errors for non-admins
- `User.email` is visible to self and admins, null/error for others
- Product mutations require SELLER or ADMIN role
- Auth token passed via `Authorization: Bearer <token>` header

**Auth testing approach:** The test runner provides pre-configured tokens for different roles (CUSTOMER, SELLER, ADMIN). The student's server validates these tokens. Simple approach: JWT with a shared secret, or the test runner sends `X-User-Id: user-1` and the student's server looks up that user.

**Key questions:**

- Where does authentication happen -- in GraphQL or before it?
- Where should authorization logic live? In resolvers? In a separate layer?
- How do you handle field-level auth without making every resolver an auth check?
- What's the difference between returning `null` vs. throwing an error for unauthorized fields?

**Links:** [Authorization](https://graphql.org/learn/authorization/)

---

### Stage 12: Orders and Transactions

**Concepts:** Multi-entity mutations. Transactional consistency. Computed fields. Snapshot data (unit_price at order time).

**Data:** Load `seed-data/full_with_orders.sql` which includes everything from full.sql plus orders with line items for existing users/products. Also adds `seller_id` to products.

**New DB tables:** `orders`, `line_items`. **Modified:** `products` (add `seller_id`).

**New schema additions:**

```graphql
type Order implements Node & Timestamped {
  id: ID!
  buyer: User!
  items: [LineItem!]!
  status: OrderStatus!
  total: Float!
  createdAt: String!
  updatedAt: String!
}

type LineItem {
  id: ID!
  product: Product!
  quantity: Int!
  unitPrice: Float!
}

enum OrderStatus {
  PENDING
  CONFIRMED
  SHIPPED
  DELIVERED
  CANCELLED
}

type Product {
  # ... existing fields
  seller: User # New -- who sells this product
}

type Query {
  order(id: ID!): Order # Buyer or admin only
  orders: [Order!]! # Own orders, or all for admin
}

type Mutation {
  placeOrder(input: PlaceOrderInput!): PlaceOrderResult!
  updateOrderStatus(id: ID!, status: OrderStatus!): Order! # Seller/admin only
}

input PlaceOrderInput {
  items: [OrderItemInput!]!
}

input OrderItemInput {
  productId: ID!
  quantity: Int!
}

union PlaceOrderResult = PlaceOrderSuccess | ValidationError

type PlaceOrderSuccess {
  order: Order!
}
```

**Tests verify:**

- Place an order, query it back with items and product details
- `Order.total` is computed correctly from line items
- `LineItem.unitPrice` is a snapshot (doesn't change if product price changes later)
- Order queries respect auth (buyer sees own, admin sees all)
- `updateOrderStatus` works for sellers/admins, rejected for customers
- `Product.seller` resolves correctly

**Key questions:**

- How do you ensure `placeOrder` is atomic (all line items or none)?
- Why snapshot `unitPrice` instead of joining to the current product price?
- How does auth interact with orders? (buyer sees own, seller sees orders for their products, admin sees all)

---

### Stage 13: Subscriptions

**Concepts:** Real-time data with GraphQL. WebSocket transport. The pub/sub pattern. Subscription filtering.

**Data:** Same. Subscriptions are triggered by mutations on existing data.

**New schema additions:**

```graphql
type Subscription {
  orderStatusChanged(orderId: ID!): Order!
  productCreated: Product!
}
```

**Tests verify:**

- WebSocket connection establishes to the GraphQL endpoint
- `orderStatusChanged` fires when an order's status is updated via mutation
- Subscription only fires for the specified `orderId` (filtering)
- `productCreated` fires when a new product is created
- Subscription events have the correct data shape
- Connection closes cleanly

**Key questions:**

- What transport does your subscription implementation use? (WebSocket, SSE, etc.)
- How does the pub/sub system work in your implementation?
- What happens to subscriptions when the server restarts?
- How would you scale subscriptions horizontally across multiple server instances?

**Links:** [Subscriptions](https://graphql.org/learn/queries/#subscriptions)

---

### Stage 14: Remote Data Sources

**Concepts:** GraphQL as a gateway. Resolvers that call external APIs. Mocking external services. Graceful degradation.

**Data:** Same. External data comes from Mockoon mock servers.

**New schema additions:**

```graphql
type Product {
  # ... existing fields
  shippingEstimate(zipCode: String!): ShippingEstimate
}

type ShippingEstimate {
  provider: String!
  days: Int!
  cost: Float!
}
```

**What the student builds:**

1. A resolver that calls the Mockoon shipping API (`$SHIPPING_API_URL`)
2. Configuration to point at the mock via environment variable

**Tests verify:**

- `shippingEstimate` returns data from the mock service
- When the mock service is down, the field returns null (not a server crash) -- graceful degradation
- The rest of the product query still resolves even if shipping estimate fails (partial success)

**Key questions:**

- How do you pass HTTP clients or API configuration through context?
- How do you handle timeout and failure from external services?
- What's the difference between a field returning null due to an error vs. due to no data?
- How would you cache external API responses?

---

### Stage 15: Custom Scalars, Directives, and Schema Evolution

**Concepts:** Custom scalar types with serialization/parsing logic. Custom directives. Versionless API evolution. Deprecation workflow.

**Data:** Adds pricing records for existing products. **New DB table:** `pricing`.

**New schema additions:**

```graphql
scalar DateTime
scalar EmailAddress
scalar Money

directive @auth(requires: Role!) on FIELD_DEFINITION
directive @cacheControl(maxAge: Int!) on FIELD_DEFINITION | OBJECT

# Type changes (evolution):
type User {
  email: EmailAddress! # Was String!, now validated
  createdAt: DateTime! # Was String!, now typed
}

type Product {
  price: Money! @deprecated(reason: "Use pricing { amount currency } instead")
  pricing: Pricing!
  shippingEstimate(zipCode: String!): ShippingEstimate
    @cacheControl(maxAge: 3600)
}

type Pricing {
  amount: Money!
  currency: String!
  compareAtAmount: Money
}
```

**Why combined:** Custom scalars and schema evolution are naturally linked -- the scalars (DateTime, Money, EmailAddress) are the mechanism for evolving `String!` and `Float!` fields into proper typed fields. Teaching them together shows the full workflow: define the scalar, migrate the field type, deprecate the old approach.

**Tests verify:**

- `DateTime` serializes to ISO 8601 format
- `EmailAddress` rejects invalid email formats on input
- `Money` serializes correctly (cents-based)
- `@auth` directive on a field enforces authorization
- Deprecated `price` field still works (backwards compat)
- `pricing` returns the new structured pricing
- Introspection shows deprecation reasons
- Invalid scalar input produces clear error messages

**Key questions:**

- What three functions define a custom scalar? (serialize, parseValue, parseLiteral)
- When would you use a custom scalar vs. input validation in the resolver?
- GraphQL doesn't have API versions. How do you evolve your schema without breaking clients?
- What constitutes a breaking change vs. a non-breaking change?

**Links:** [Schema Design Best Practices](https://graphql.org/learn/schema-design/)

---

### Stage 16: Security, Performance, and Federation (Capstone)

**Concepts:** Query depth limiting. Query complexity analysis. Persisted queries. Splitting a monolith into subgraphs.

**Data:** Same. This stage is about server configuration and architecture.

**Part A: Security and Performance Hardening**

**Tests verify:**

- Deeply nested query (depth > 10) is rejected
- Expensive query is rejected or cost-limited
- Introspection can be disabled via configuration
- Persisted queries: server accepts a query by hash/ID

**Part B: Federation**

**Architecture change:** The monolithic server is split into 3 subgraphs:

- **Products subgraph:** Product, Category, Review types
- **Users subgraph:** User type, authentication
- **Orders subgraph:** Order, LineItem types

```graphql
# Products subgraph
type Product @key(fields: "id") {
  id: ID!
  title: String!
  price: Money!
}

# Orders subgraph
type Product @key(fields: "id") {
  id: ID!
  purchaseCount: Int!
}
```

**Tests verify:**

- Queries that span subgraphs resolve correctly
- Each subgraph can be introspected independently
- Entity references resolve across subgraph boundaries

**Key questions:**

- How do you calculate the cost of a query before executing it?
- Should you disable introspection in production? What are the tradeoffs?
- When is federation worth the complexity vs. a monolithic schema?
- How does the gateway know which subgraph to ask for which fields?

**Links:** [Security Best Practices](https://graphql.org/learn/security/), [Performance](https://graphql.org/learn/performance/), [Federation](https://graphql.org/learn/federation/)

---

## Schema Evolution Across Stages

| Stage | New Types                              | New Fields                                                        | Key Concepts                                 | Data Change       |
| ----- | -------------------------------------- | ----------------------------------------------------------------- | -------------------------------------------- | ----------------- |
| 01    | Query                                  | hello                                                             | SDL basics, HTTP endpoint                    | None              |
| 02    | Product, ProductStatus                 | product, products                                                 | Scalars, enums, nullability, SQLite          | base.sql          |
| 03    | Category                               | categories, Product.categories                                    | Relationships, resolver chaining             | Same              |
| 04    | Mutation, *Input, *Payload             | createProduct, updateProduct                                      | Mutations, input types                       | Same              |
| 05    | (none)                                 | (none)                                                            | Variables, fragments, aliases, directives    | Same              |
| 06    | User, Review                           | user, users, Product.reviews, Product.averageRating, createReview | New entity types, N:1 relationships          | full.sql (scaled) |
| 07    | Node, Timestamped, SearchResult        | node, search                                                      | Interfaces, unions, global IDs               | Same              |
| 08    | (none -- optimization)                 | (none)                                                            | DataLoader, N+1                              | Same              |
| 09    | *Connection, *Edge, PageInfo           | productsConnection                                                | Cursor pagination, filtering                 | Same              |
| 10    | \*Result unions, ValidationError       | (updated mutations)                                               | Error handling patterns                      | Same              |
| 11    | Role enum                              | me, User.role                                                     | Auth middleware, field-level permissions     | Same              |
| 12    | Order, LineItem, OrderStatus           | placeOrder, orders, Product.seller                                | Transactions, computed fields, snapshots     | + orders.sql      |
| 13    | Subscription                           | orderStatusChanged, productCreated                                | WebSocket, pub/sub                           | Same              |
| 14    | ShippingEstimate                       | Product.shippingEstimate                                          | External APIs, graceful degradation          | Same (mock API)   |
| 15    | DateTime, EmailAddress, Money, Pricing | Product.pricing, @auth, @cacheControl                             | Custom scalars, directives, schema evolution | + pricing records |
| 16    | (subgraph splits)                      | purchaseCount                                                     | Security hardening, federation               | Same              |

---

## What Each Stage Delivers to the Student

Every stage directory contains:

1. **`schema.graphql`** -- The complete SDL for this stage (cumulative, not just the diff). This is the source of truth.

2. **`concepts.md`** -- A brief (500-1000 word) explanation covering:

   - What concept this stage teaches and why it matters
   - 1-2 key mental models or analogies
   - Links to official GraphQL docs for deep dives
   - "Key questions" that the student should be able to answer after completing the stage
   - "Implementation notes" with pointers for common frameworks (graphql-js, gqlgen, Hot Chocolate, Strawberry, graphql-java) -- not instructions, just "in X, this concept maps to Y"

3. **`features/*.feature`** -- Gherkin test specifications:

   - `introspection.feature` -- schema structure tests (every stage)
   - `queries.feature` / `mutations.feature` / `subscriptions.feature` -- behavioral tests
   - `errors.feature` -- error handling tests (from stage 10 onward)
   - `auth.feature` -- authorization tests (from stage 11 onward)
   - `performance.feature` -- performance/security tests (stage 16)

4. **`operations.graphql`** -- Sample queries/mutations the student can use to manually explore with GraphiQL or Postman (not part of the test suite, just convenience).

Note: Stages do NOT have individual seed-data files. All seed data lives in `seed-data/` at the project root as SQL files. See [Seed Data Strategy](#seed-data-strategy) above.

---

## Reference Links

### Official Specifications and Documentation

- [GraphQL Specification (October 2021)](https://spec.graphql.org/October2021/)
- [GraphQL.org Learn](https://graphql.org/learn/)
- [GraphQL over HTTP Specification](https://graphql.github.io/graphql-over-http/)
- [Relay Server Specification](https://relay.dev/docs/guides/graphql-server-specification/)

### Key Concepts

- [Thinking in Graphs](https://graphql.org/learn/thinking-in-graphs/)
- [Schemas and Types](https://graphql.org/learn/schema/)
- [Queries and Mutations](https://graphql.org/learn/queries/)
- [Execution](https://graphql.org/learn/execution/)
- [Introspection](https://graphql.org/learn/introspection/)
- [Validation](https://graphql.org/learn/validation/)
- [Response Format](https://graphql.org/learn/response/)

### Best Practices

- [Serving over HTTP](https://graphql.org/learn/serving-over-http/)
- [Authorization](https://graphql.org/learn/authorization/)
- [Pagination](https://graphql.org/learn/pagination/)
- [Global Object Identification](https://graphql.org/learn/global-object-identification/)
- [Caching](https://graphql.org/learn/caching/)
- [Schema Design](https://graphql.org/learn/schema-design/)
- [Performance](https://graphql.org/learn/performance/)
- [Security](https://graphql.org/learn/security/)

### Tools

- [DataLoader](https://github.com/graphql/dataloader) -- Reference implementation of the batching/caching pattern
- [graphql-schema-linter](https://github.com/cjoudrey/graphql-schema-linter) -- Static schema linting
- [GraphQL Inspector](https://the-guild.dev/graphql/inspector) -- Schema diffing and breaking change detection
- [Cucumber / Gherkin](https://cucumber.io/docs/gherkin/reference/) -- BDD test specification language

### Server Libraries by Language

- **TypeScript/JavaScript:** graphql-js (reference), Apollo Server, GraphQL Yoga, Mercurius
- **Go:** gqlgen, graph-gophers/graphql-go
- **Python:** Strawberry (code-first), Ariadne (schema-first), Graphene
- **Java/Kotlin:** graphql-java, Netflix DGS, GraphQL Kotlin
- **.NET:** Hot Chocolate, GraphQL.NET
- **Rust:** async-graphql, Juniper
- **Ruby:** graphql-ruby
- **Elixir:** Absinthe
