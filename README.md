# GraphQL Training Path: From Zero to Production

A progressive, language-agnostic GraphQL curriculum. You receive schemas, Gherkin test specs, and conceptual guidance at each stage. You implement the server in whatever language/framework you choose.

## Prerequisites

Install these tools before starting:

| Tool                                                        | Purpose             | Install                        |
| ----------------------------------------------------------- | ------------------- | ------------------------------ |
| [Bun](https://bun.sh/) 1.0+                                 | Test runner         | `brew install oven-sh/bun/bun` |
| [SQLite](https://sqlite.org/) 3.35+                         | Database            | `brew install sqlite3`         |
| [golang-migrate](https://github.com/golang-migrate/migrate) | Database migrations | `brew install golang-migrate`  |
| [go-task](https://taskfile.dev/)                            | Task runner         | `brew install go-task`         |
| [Mockoon CLI](https://mockoon.com/cli/) (stage 14+)         | External API mocks  | `bun install -g @mockoon/cli`  |

## Getting Your Own Copy

You need your own copy of this repository so you can commit your server implementation without affecting the shared curriculum. There are three options — pick whichever fits your situation.

### Option 1: Use this template (recommended)

This repository is set up as a GitHub template. Click the **"Use this template"** button at the top of the GitHub page to create a fresh copy under your own account in seconds. You get a clean repo with no fork relationship, which means:

- No "X commits ahead/behind" noise in the GitHub UI
- Your `main` branch starts clean with only the curriculum files
- You can open pull requests within your own copy if you want code review

After creating your copy (replace `<your-username>` with your GitHub username):
```bash
git clone https://github.com/<your-username>/graph-ql-training && cd graph-ql-training
./setup.sh
```

### Option 2: Clone and push to a new remote

If the template button isn't available, create a blank repo on GitHub (do **not** initialize it with a README), then (replace `<your-username>` with your GitHub username):

```bash
# Clone the original
git clone https://github.com/jha-captech/graph-ql-training && cd graph-ql-training

# Point origin at your new repo
git remote set-url origin https://github.com/<your-username>/graph-ql-training

# Push all branches and tags
git push -u origin main

# Continue with setup
./setup.sh
```

### Option 3: Work on branches in the original repo

If you have write access to this repo and don't need your own copy, the branch-based workflow described below works fine. Your `stage/*` branches are isolated from `main` — just never push server code to `main`.

---

## Quick Start

```bash
# 1. Clone the repo (or your copy from Option 1/2 above)
git clone <repo-url> && cd graph-ql-training

# 2. Run the setup script (checks prerequisites, creates .env, installs test runner)
./setup.sh

# 3. Create your first stage branch
git checkout -b stage/01

# 4. Read the stage materials
cat stages/01-hello-graphql/concepts.md
cat stages/01-hello-graphql/schema.graphql

# 5. Build your GraphQL server in a server/ directory (any language/framework)
mkdir server && cd server
# ... initialize your project (npm init, go mod init, etc.)

# 6. Run your server at http://localhost:4000/graphql, then run the tests
cd test-runner && bunx cucumber-js --tags @stage:01
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

## Working on a Stage

Every stage follows the same workflow. Here's the full checklist:

```bash
# 1. Branch from your current stage (or main for stage 01)
git checkout -b stage/XX

# 2. Set up the database (skip for stage 01 — it has no database)
task db:reset STAGE=XX

# 3. Read the concepts and schema
cat stages/XX-name/concepts.md
cat stages/XX-name/schema.graphql

# 4. Explore the sample queries (optional — handy for manual testing)
cat stages/XX-name/operations.graphql

# 5. Implement your server to match the schema

# 6. Run the tests until they all pass
cd test-runner && bunx cucumber-js --tags @stage:XX

# 7. Commit your work and move to the next stage
git add -A && git commit -m "stage XX complete"
```

Each stage builds on the previous one. Schemas are cumulative — stage 06's schema includes everything from stages 01-05 plus new additions. Each stage provides a `concepts.md` with the "why", a `schema.graphql` with the target SDL, `features/*.feature` with test specs, and `operations.graphql` with sample queries for manual exploration.

## Your Server Code

Put your implementation in a `server/` directory at the project root:

```
graph-ql-training/
├── server/          <-- your code goes here
│   ├── package.json (or go.mod, requirements.txt, etc.)
│   └── ...
├── stages/          <-- read-only curriculum materials
├── migrations/
└── ...
```

This keeps your implementation cleanly separated from the curriculum files. Initialize it with whatever framework you choose — `bun init`, `go mod init`, `dotnet new web`, etc. Your server must listen on `http://localhost:4000/graphql` (configurable via `.env`).

## Environment Variables

The `.env` file (created by `setup.sh` from `local.env`) controls shared configuration:

| Variable           | Default                   | Purpose                             |
| ------------------ | ------------------------- | ----------------------------------- |
| `DB_FILE`          | `graphql_training.db`     | SQLite database file path           |
| `SERVER_PORT`      | `4000`                    | Port your GraphQL server should use |
| `JWT_SECRET`       | `graphql-training-secret` | JWT signing secret (stages 11+)     |
| `SHIPPING_API_URL` | `http://localhost:4010`   | Shipping mock API (stage 14+)       |
| `TAX_API_URL`      | `http://localhost:4011`   | Tax mock API (stage 14+)            |
| `CURRENCY_API_URL` | `http://localhost:4012`   | Currency mock API (stage 14+)       |

Your server should read from these variables rather than hardcoding values. The test runner uses the same `.env` file, so everything stays in sync.

## Stage Overview

| Stage | Topic                      | Database        | Seed Tier |
| ----- | -------------------------- | --------------- | --------- |
| 01    | Hello GraphQL              | None            | None      |
| 02    | Types & Enums              | Migrations 1-3  | `base`    |
| 03    | Relationships              | Migrations 1-3  | `base`    |
| 04    | Mutations                  | Migrations 1-3  | `base`    |
| 05    | Query Language             | Migrations 1-3  | `base`    |
| 06    | Users & Reviews            | Migrations 1-5  | `full`    |
| 07    | Interfaces & Unions        | Migrations 1-5  | `full`    |
| 08    | DataLoader                 | Migrations 1-5  | `full`    |
| 09    | Pagination                 | Migrations 1-6  | `full`    |
| 10    | Error Handling             | Migrations 1-6  | `full`    |
| 11    | Authentication             | Migrations 1-6  | `full`    |
| 12    | Orders                     | Migrations 1-10 | `orders`  |
| 13    | Subscriptions              | Migrations 1-10 | `orders`  |
| 14    | Remote Data Sources        | Migrations 1-10 | `orders`  |
| 15    | Custom Scalars & Evolution | Migrations 1-11 | `orders`  |
| 16    | Security & Federation      | Migrations 1-11 | `orders`  |

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
bunx cucumber-js --tags @stage:02

# Run all tests up to a stage
bunx cucumber-js --tags "@stage:01 or @stage:02 or @stage:03"

# Dry run (check feature files parse without executing)
bunx cucumber-js --dry-run --tags @stage:02
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
├── seed-data/               # Layered SQL seed data (additive tiers)
│   ├── base/                # Products + categories (stages 02-05)
│   ├── full/                # + users + reviews (stages 06-11)
│   └── orders/              # + seller assignment, orders + line items (stages 12+)
├── test-runner/             # Cucumber.js + TypeScript
├── mocks/                   # Mockoon configs for external APIs
└── tools/                   # Schema linting, introspection helpers
```

## Design Decisions

### Why E-Commerce

After evaluating todo apps, blogs, social media, and library systems, a simplified marketplace wins because it naturally covers every GraphQL concept without contrived examples: object types (Products, Users, Orders), relationships of all cardinalities (User->Orders->LineItems, Products<->Categories), interfaces (`Node`, `Timestamped`), unions (`SearchResult`), enums (`OrderStatus`, `Role`), pagination (product catalog), auth (role-based access), subscriptions (order status changes), DataLoader (reviews for a list of products), and federation (subgraph splits).

### Why SQLite

SQLite is a file — zero infrastructure, no Docker, no connection strings, no server process. Every language has bindings. Students focus on GraphQL from day one, not database setup.

### Why golang-migrate

Language-agnostic standalone binary — no runtime dependency on Go, Node, or Java. Plain SQL up/down files with no DSL or ORM coupling. The `goto V` command maps perfectly to our staged curriculum. Alternatives like Flyway (Java dependency), dbmate (no `goto`), or Atlas (declarative complexity we don't need) were considered.

### Why Mockoon for External API Mocks

Mocks are JSON config files, not code in any language. Runs as a separate HTTP server — works regardless of the student's server language. Built-in response templating, latency simulation, and error responses. Alternatives like WireMock (Java), MSW/nock (Node-only), or DIY Express mocks all break the language-agnostic requirement or add maintenance burden.

### Why Gherkin/Cucumber Tests

The HTTP boundary is the language-agnostic testing contract. Step definitions send HTTP POST requests to `localhost:4000/graphql` and assert on JSON responses. The student never touches test files — they just implement until tests pass. A small, reusable step vocabulary covers all 16 stages without needing new step definitions.

### Database Schema Conventions

- **Money as INTEGER (cents):** Floats have rounding errors. Cents as integers are exact and match what Stripe uses. The `Money` custom scalar (stage 15) handles display formatting.
- **Enums as TEXT + CHECK:** Postgres `CREATE TYPE ... AS ENUM` is painful to alter. TEXT + CHECK is easy to migrate, portable across databases, and still enforced at the DB level.
- **UUIDs, not serial integers:** Work naturally as global IDs for `node(id: ID!)`, are safe to expose publicly (no enumeration), and work across federated subgraphs without collision.
- **Timestamps from migration 1:** `created_at`/`updated_at` exist from the start even though the `Timestamped` interface isn't exposed until stage 07. Adding them retroactively via ALTER TABLE is messy.
- **unit_price snapshot on line_items:** Captures the price at order time. Products change price; historical orders should not retroactively change totals.
- **Hard deletes, no soft delete:** `ON DELETE CASCADE` where appropriate. This is a training project — simplicity wins.

### Seed Data: Layered Tiers

Seed data uses additive tiers (`base/` → `full/` → `orders/`) instead of monolithic files. Each tier adds data without duplicating anything from previous tiers. The `orders/` tier uses `UPDATE` for seller assignment since the column is added by a later migration after products already exist. See [seed-data/](seed-data/) for the full structure.

## Supported Frameworks

This curriculum works with any GraphQL server implementation. Some popular choices:

| Language   | Framework                   | Getting Started                  |
| ---------- | --------------------------- | -------------------------------- |
| TypeScript | Apollo Server, graphql-yoga | `bun init`                       |
| Go         | gqlgen                      | `go mod init`                    |
| Python     | Strawberry, Ariadne         | `pip install strawberry-graphql` |
| .NET       | Hot Chocolate               | `dotnet new web`                 |
| Java       | graphql-java, DGS           | Spring Boot starter              |
| Rust       | async-graphql, Juniper      | `cargo init`                     |

Pick any framework. The tests don't care how you build it — only that it serves the right schema at the right endpoint.
