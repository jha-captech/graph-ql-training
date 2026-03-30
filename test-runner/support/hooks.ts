import { After, Before, BeforeAll } from "@cucumber/cucumber";
import Database from "better-sqlite3";
import { readdirSync, readFileSync } from "fs";
import { join, resolve } from "path";
import { GraphQLWorld } from "../steps/world";

// Project root is one level above test-runner/
const PROJECT_ROOT = resolve(__dirname, "../..");

/**
 * Maps a stage number to its seed tier.
 */
function getSeedTier(stage: string): "none" | "base" | "full" | "orders" {
  const n = parseInt(stage, 10);
  if (n === 1) return "none";
  if (n <= 5) return "base";
  if (n <= 11) return "full";
  if (n <= 16) return "orders";
  return "none";
}

// Tables in foreign-key-safe delete order (children before parents).
const DELETE_ORDER = [
  "line_items",
  "orders",
  "pricing",
  "reviews",
  "product_categories",
  "products",
  "categories",
  "users",
];

/**
 * Deletes all seed data from tables that exist, in FK-safe order.
 */
function cleanupDatabase(db: Database.Database): void {
  const existing = new Set(
    db
      .prepare("SELECT name FROM sqlite_master WHERE type='table'")
      .all()
      .map((r: any) => r.name),
  );
  for (const table of DELETE_ORDER) {
    if (existing.has(table)) {
      db.exec(`DELETE FROM ${table}`);
    }
  }
}

/**
 * Runs all .sql files in a directory in sorted order.
 */
function seedFromDir(db: Database.Database, dirPath: string): void {
  const files = readdirSync(dirPath)
    .filter((f) => f.endsWith(".sql"))
    .sort();
  for (const file of files) {
    db.exec(readFileSync(join(dirPath, file), "utf-8"));
  }
}

/**
 * Resets the database to clean seed state for the given stage.
 * Opens its own connection, runs cleanup + re-seed, then closes.
 */
function resetDatabase(): void {
  const dbFile = join(
    PROJECT_ROOT,
    process.env.DB_FILE || "graphql_training.db",
  );
  const stage = process.env.STAGE || "01";
  const tier = getSeedTier(stage);

  const db = new Database(dbFile);
  try {
    cleanupDatabase(db);

    // Re-seed based on tier
    const seedDir = join(PROJECT_ROOT, "seed-data");
    if (tier !== "none") {
      seedFromDir(db, join(seedDir, "base"));
      if (tier === "full" || tier === "orders") {
        seedFromDir(db, join(seedDir, "full"));
      }
      if (tier === "orders") {
        seedFromDir(db, join(seedDir, "orders"));
      }
    }
  } finally {
    db.close();
  }
}

BeforeAll(function () {
  // Verify the GraphQL endpoint is configured
  const endpoint =
    process.env.GRAPHQL_ENDPOINT || "http://localhost:4000/graphql";
  console.log(`Test runner targeting: ${endpoint}`);
});

/**
 * Reset the database to clean seed state before scenarios tagged @db:reset.
 * Opens the DB file directly via better-sqlite3, runs cleanup.sql, and re-seeds.
 * The running server sees the changes immediately (same file, no replacement).
 */
Before({ tags: "@db:reset" }, function () {
  resetDatabase();
});

After(async function (this: GraphQLWorld) {
  // Close any open WebSocket connections
  if (this.wsConnection) {
    this.wsConnection.close();
    this.wsConnection = null;
  }
  if (this.secondWsConnection) {
    this.secondWsConnection.close();
    this.secondWsConnection = null;
  }

  // Reset state for next scenario
  this.reset();
});
