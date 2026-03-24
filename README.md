# GraphQL Training Path: From Zero to Production

A progressive, language-agnostic GraphQL curriculum. You receive schemas, Gherkin test specs, and conceptual guidance at each stage. You implement the server in whatever language/framework you choose.

## Prerequisites

Install these tools before starting:

| Tool                                                        | Purpose             | Install                       |
| ----------------------------------------------------------- | ------------------- | ----------------------------- |
| [Node.js](https://nodejs.org/) 18+                          | Test runner         | `brew install node`           |
| [SQLite](https://sqlite.org/) 3.35+                         | Database            | `brew install sqlite3`        |
| [golang-migrate](https://github.com/golang-migrate/migrate) | Database migrations | `brew install golang-migrate` |
| [go-task](https://taskfile.dev/)                            | Task runner         | `brew install go-task`        |
| [Mockoon CLI](https://mockoon.com/cli/) (stage 14+)         | External API mocks  | `npm install -g @mockoon/cli` |

## Quick Start

```bash
# 1. Clone the repo
git clone <repo-url> && cd graph-ql-training

# 2. Run the setup script (checks prerequisites, creates .env, installs test runner)
./setup.sh

# 3. Create your first stage branch and set up the database
git checkout -b stage/01
task db:reset STAGE=02   # stage 01 has no database

# 4. Read the stage materials
cat stages/01-hello-graphql/concepts.md
cat stages/01-hello-graphql/schema.graphql

# 5. Build your GraphQL server (in your language of choice)
#    targeting http://localhost:4000/graphql

# 6. Run the tests for your stage
cd test-runner && npx cucumber-js --tags @stage:01
```

You can also pass a stage number to do steps 2 and 3 at once:

```bash
./setup.sh 02
```

## Branching Strategy

Each stage builds on the previous one — your branches should too. Create a new branch from your current stage when you're ready to move on:

```bash
# Starting stage 01 (branch from main)
git checkout main
git checkout -b stage/01
# ... implement, test, commit ...

# Moving to stage 02 (branch from stage/01)
git checkout -b stage/02
task db:reset STAGE=02
# ... implement, test, commit ...

# Moving to stage 03 (branch from stage/02)
git checkout -b stage/03
task db:reset STAGE=03
# ... implement, test, commit ...
```

This gives you:

- **Cumulative progress** — your server implementation carries forward naturally, just like the schemas do.
- **Clean checkpoints** — if stage 05 goes sideways, go back to `stage/04` and re-branch.
- **Full history** — you can diff between stages to see exactly what you added.

> **Keep `main` clean.** The `main` branch contains the curriculum materials (stages, migrations, seed data, tests). Never commit your server implementation to `main` — always work on a `stage/*` branch.

We recommend putting your server implementation in a `server/` directory at the project root to keep it separate from the curriculum materials.

## How It Works

1. **Read** the stage's `concepts.md` for the "what" and "why"
2. **Study** the stage's `schema.graphql` — this is the contract your server must fulfill
3. **Explore** `operations.graphql` for example queries you can test manually
4. **Implement** your server to match the schema
5. **Test** with `npx cucumber-js --tags @stage:XX` until all scenarios pass
6. **Move on** to the next stage

Each stage builds on the previous one. Schemas are cumulative — stage 06's schema includes everything from stages 01-05 plus new additions.

## Stage Overview

| Stage | Topic                      | Database        | Seed Data              |
| ----- | -------------------------- | --------------- | ---------------------- |
| 01    | Hello GraphQL              | None            | None                   |
| 02    | Types & Enums              | Migrations 1-3  | `base.sql`             |
| 03    | Relationships              | Migrations 1-3  | `base.sql`             |
| 04    | Mutations                  | Migrations 1-3  | `base.sql`             |
| 05    | Query Language             | Migrations 1-3  | `base.sql`             |
| 06    | Users & Reviews            | Migrations 1-5  | `full.sql`             |
| 07    | Interfaces & Unions        | Migrations 1-5  | `full.sql`             |
| 08    | DataLoader                 | Migrations 1-5  | `full.sql`             |
| 09    | Pagination                 | Migrations 1-6  | `full.sql`             |
| 10    | Error Handling             | Migrations 1-6  | `full.sql`             |
| 11    | Authentication             | Migrations 1-6  | `full.sql`             |
| 12    | Orders                     | Migrations 1-10 | `full_with_orders.sql` |
| 13    | Subscriptions              | Migrations 1-10 | `full_with_orders.sql` |
| 14    | Remote Data Sources        | Migrations 1-10 | `full_with_orders.sql` |
| 15    | Custom Scalars & Evolution | Migrations 1-11 | `full_with_orders.sql` |
| 16    | Security & Federation      | Migrations 1-11 | `full_with_orders.sql` |

## Task Commands

All commands use [go-task](https://taskfile.dev/). Run `task --list` to see all available tasks.

```bash
# Environment
task env:init              # Create .env from local.env
task env:reset             # Reset .env to defaults

# Database
task db:reset STAGE=06     # Reset DB for a specific stage (drops + migrates + seeds)
task migrate:up            # Run all pending migrations
task migrate:down N=1      # Roll back N migrations
task migrate:goto V=5      # Migrate to specific version
task migrate:version       # Print current version

# Mock APIs (stage 14+)
task mocks:start           # Start shipping, tax, currency mocks
task mocks:stop            # Stop all mocks
```

## Testing

Tests are Cucumber.js feature files that send HTTP requests to your running GraphQL server. They're completely language-agnostic — they only care that your server responds correctly at `http://localhost:4000/graphql`.

```bash
cd test-runner

# Run tests for a specific stage
npx cucumber-js --tags @stage:02

# Run all tests up to a stage
npx cucumber-js --tags "@stage:01 or @stage:02 or @stage:03"

# Dry run (check feature files parse without executing)
npx cucumber-js --dry-run --tags @stage:02
```

### Authentication (Stages 11+)

Tests that require auth use JWT tokens signed with the secret `graphql-training-secret`. The test runner generates tokens for three roles:

| Role     | User ID  | Name           | Email             |
| -------- | -------- | -------------- | ----------------- |
| CUSTOMER | user-001 | Alice Johnson  | alice@example.com |
| SELLER   | user-003 | Carol Williams | carol@example.com |
| ADMIN    | user-005 | Eve Davis      | eve@example.com   |

Your server should validate JWT tokens from the `Authorization: Bearer <token>` header using the same secret.

## Project Structure

```
├── stages/                  # One directory per stage
│   └── XX-name/
│       ├── schema.graphql   # Target SDL (cumulative)
│       ├── concepts.md      # Explanation + links
│       ├── operations.graphql # Sample queries for exploration
│       └── features/        # Gherkin test specs
├── migrations/              # Sequential SQL migrations (all stages)
├── seed-data/               # SQL seed data files
│   ├── base.sql             # Products + categories (stages 02-05)
│   ├── full.sql             # + users + reviews (stages 06-11)
│   └── full_with_orders.sql # + orders + line items (stages 12+)
├── test-runner/             # Cucumber.js + TypeScript
├── mocks/                   # Mockoon configs for external APIs
├── tools/                   # Schema linting, introspection helpers
├── PLAN.md                  # Full curriculum design document
└── DATA_DESIGN.md           # Database schema and design decisions
```

## Supported Frameworks

This curriculum works with any GraphQL server implementation. Some popular choices:

| Language   | Framework                   | Getting Started                  |
| ---------- | --------------------------- | -------------------------------- |
| TypeScript | Apollo Server, graphql-yoga | `npm init`                       |
| Go         | gqlgen                      | `go mod init`                    |
| Python     | Strawberry, Ariadne         | `pip install strawberry-graphql` |
| .NET       | Hot Chocolate               | `dotnet new web`                 |
| Java       | graphql-java, DGS           | Spring Boot starter              |
| Rust       | async-graphql, Juniper      | `cargo init`                     |

Pick any framework. The tests don't care how you build it — only that it serves the right schema at the right endpoint.
