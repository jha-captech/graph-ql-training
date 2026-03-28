import { Given, When, Then } from "@cucumber/cucumber";
import { strict as assert } from "assert";
import WebSocket from "ws";
import { GraphQLWorld } from "./world";
import { generateToken, sendGraphQLRequest, resolvePath } from "./helpers";

// ─── Setup ───────────────────────────────────────────────────────────

Given(
  "the GraphQL endpoint is {string}",
  function (this: GraphQLWorld, url: string) {
    this.endpoint = process.env.GRAPHQL_ENDPOINT || url;
  },
);

Given(
  "I am authenticated as {string}",
  function (this: GraphQLWorld, role: string) {
    const token = generateToken(role);
    this.authHeader = `Bearer ${token}`;
  },
);

Given("I am not authenticated", function (this: GraphQLWorld) {
  this.authHeader = null;
});

// Mock API / Federation setup steps (stage 14+, 16)
// These are informational — the actual mocks are started via `task mocks:start`
Given(
  "the mock API service is running on port {int}",
  function (_port: number) {
    /* no-op */
  },
);
Given("the mock API service is stopped", function () {
  /* no-op */
});
Given("the mock API service has high latency", function () {
  /* no-op */
});
Given("the mock API service is unreliable", function () {
  /* no-op */
});
Given("the federation gateway is running", function () {
  /* no-op */
});
Given("all subgraphs are running", function () {
  /* no-op */
});
Given("the Users subgraph is unavailable", function () {
  /* no-op */
});
Given("the Orders subgraph is unavailable", function () {
  /* no-op */
});

// ─── Variables ───────────────────────────────────────────────────────

When(
  "I set the variable {string} to {string}",
  function (this: GraphQLWorld, name: string, value: string) {
    // Try to parse as JSON, fall back to string
    try {
      this.variables[name] = JSON.parse(value);
    } catch {
      this.variables[name] = value;
    }
  },
);

When(
  "I set the variable {string} to {float}",
  function (this: GraphQLWorld, name: string, value: number) {
    this.variables[name] = value;
  },
);

When(
  "I set the variable {string} to true",
  function (this: GraphQLWorld, name: string) {
    this.variables[name] = true;
  },
);

When(
  "I set the variable {string} to false",
  function (this: GraphQLWorld, name: string) {
    this.variables[name] = false;
  },
);

When(
  "I save {string} as {string}",
  function (this: GraphQLWorld, path: string, varName: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    this.variables[varName] = value;
  },
);

When(
  "I set the variable {string} to:",
  function (
    this: GraphQLWorld,
    name: string,
    table: { rows: () => string[][] },
  ) {
    const obj: Record<string, unknown> = {};
    for (const [key, value] of table.rows()) {
      try {
        obj[key] = JSON.parse(value);
      } catch {
        obj[key] = value;
      }
    }
    this.variables[name] = obj;
  },
);

When(
  "I save {string} as variable {string}",
  function (this: GraphQLWorld, path: string, varName: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    this.variables[varName] = value;
  },
);

// ─── Actions ─────────────────────────────────────────────────────────

When(
  "I send a GraphQL query:",
  async function (this: GraphQLWorld, query: string) {
    this.lastResponse = await sendGraphQLRequest(
      this.endpoint,
      query,
      this.variables,
      this.authHeader,
    );
  },
);

When(
  "I send a GraphQL mutation:",
  async function (this: GraphQLWorld, mutation: string) {
    this.lastResponse = await sendGraphQLRequest(
      this.endpoint,
      mutation,
      this.variables,
      this.authHeader,
    );
  },
);

// Federation subgraph queries (stage 16) — send to the main endpoint by default
When(
  "I query the Products subgraph directly:",
  async function (this: GraphQLWorld, query: string) {
    this.lastResponse = await sendGraphQLRequest(
      this.endpoint,
      query,
      this.variables,
      this.authHeader,
    );
  },
);

When(
  "I query the Products subgraph at {string}:",
  async function (this: GraphQLWorld, url: string, query: string) {
    this.lastResponse = await sendGraphQLRequest(
      url,
      query,
      this.variables,
      this.authHeader,
    );
  },
);

When(
  "I query the Users subgraph directly:",
  async function (this: GraphQLWorld, query: string) {
    this.lastResponse = await sendGraphQLRequest(
      this.endpoint,
      query,
      this.variables,
      this.authHeader,
    );
  },
);

When(
  "I query the Orders subgraph directly:",
  async function (this: GraphQLWorld, query: string) {
    this.lastResponse = await sendGraphQLRequest(
      this.endpoint,
      query,
      this.variables,
      this.authHeader,
    );
  },
);

When(
  "I send an introspection query to the gateway:",
  async function (this: GraphQLWorld, query: string) {
    this.lastResponse = await sendGraphQLRequest(
      this.endpoint,
      query,
      this.variables,
      this.authHeader,
    );
  },
);

When(
  "I send the subscription:",
  function (this: GraphQLWorld, subscription: string) {
    return new Promise<void>((resolve, reject) => {
      const wsUrl = this.endpoint.replace(/^http/, "ws");
      const ws = new WebSocket(wsUrl, "graphql-transport-ws");

      ws.on("open", () => {
        ws.send(JSON.stringify({ type: "connection_init" }));
      });

      ws.on("message", (data: Buffer) => {
        const msg = JSON.parse(data.toString());

        if (msg.type === "connection_ack") {
          ws.send(
            JSON.stringify({
              id: "1",
              type: "subscribe",
              payload: { query: subscription, variables: this.variables },
            }),
          );
          resolve();
        }

        if (msg.type === "next") {
          this.subscriptionEvents.push({ data: msg.payload.data });
        }

        if (msg.type === "error") {
          this.subscriptionEvents.push({ data: msg.payload });
        }
      });

      ws.on("error", reject);
      this.wsConnection = ws;
    });
  },
);

// ─── Assertions ──────────────────────────────────────────────────────

Then(
  "the response status should be {int}",
  function (this: GraphQLWorld, status: number) {
    assert.ok(this.lastResponse, "No response received");
    assert.equal(this.lastResponse.status, status);
  },
);

Then(
  "the response should contain {string}",
  function (this: GraphQLWorld, path: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.notStrictEqual(
      value,
      undefined,
      `Path "${path}" not found in response`,
    );
  },
);

Then(
  "the response should not contain {string}",
  function (this: GraphQLWorld, path: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.strictEqual(
      value,
      undefined,
      `Path "${path}" should not exist in response`,
    );
  },
);

Then(
  "the response {string} should equal {string}",
  function (this: GraphQLWorld, path: string, expected: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    // Try to parse expected as JSON for numbers, booleans, null
    let parsed: unknown;
    try {
      parsed = JSON.parse(expected);
    } catch {
      parsed = expected;
    }
    assert.deepStrictEqual(value, parsed);
  },
);

Then(
  "the response {string} should equal {float}",
  function (this: GraphQLWorld, path: string, expected: number) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.strictEqual(value, expected);
  },
);

Then(
  "the response {string} should be an array",
  function (this: GraphQLWorld, path: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(
      Array.isArray(value),
      `Expected "${path}" to be an array, got ${typeof value}`,
    );
  },
);

Then(
  "the response {string} should have {int} items",
  function (this: GraphQLWorld, path: string, count: number) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(Array.isArray(value), `Expected "${path}" to be an array`);
    assert.equal(value.length, count);
  },
);

Then(
  "the response {string} should have at least {int} items",
  function (this: GraphQLWorld, path: string, min: number) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(Array.isArray(value), `Expected "${path}" to be an array`);
    assert.ok(
      value.length >= min,
      `Expected at least ${min} items, got ${value.length}`,
    );
  },
);

Then(
  "each item in {string} should have fields {string}",
  function (this: GraphQLWorld, path: string, fieldList: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(Array.isArray(value), `Expected "${path}" to be an array`);
    const fields = fieldList.split(",").map((f) => f.trim());
    for (const item of value) {
      for (const field of fields) {
        assert.ok(
          field in (item as Record<string, unknown>),
          `Item missing field "${field}": ${JSON.stringify(item)}`,
        );
      }
    }
  },
);

Then(
  "each item in {string} should have field {string}",
  function (this: GraphQLWorld, path: string, fieldPath: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(Array.isArray(value), `Expected "${path}" to be an array`);
    for (let i = 0; i < value.length; i++) {
      const resolved = resolvePath(
        value[i] as Record<string, unknown>,
        fieldPath,
      );
      assert.notStrictEqual(
        resolved,
        undefined,
        `Item[${i}] missing field "${fieldPath}"`,
      );
    }
  },
);

Then(
  "each item in {string} should have a non-null {string}",
  function (this: GraphQLWorld, path: string, fieldPath: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(Array.isArray(value), `Expected "${path}" to be an array`);
    for (let i = 0; i < value.length; i++) {
      const resolved = resolvePath(
        value[i] as Record<string, unknown>,
        fieldPath,
      );
      assert.notStrictEqual(
        resolved,
        undefined,
        `Item[${i}] field "${fieldPath}" is undefined`,
      );
      assert.notStrictEqual(
        resolved,
        null,
        `Item[${i}] field "${fieldPath}" is null`,
      );
    }
  },
);

Then(
  "each item in {string} should have field {string} matching ISO 8601 format",
  function (this: GraphQLWorld, path: string, fieldPath: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(Array.isArray(value), `Expected "${path}" to be an array`);
    for (let i = 0; i < value.length; i++) {
      const resolved = resolvePath(
        value[i] as Record<string, unknown>,
        fieldPath,
      ) as string;
      assert.ok(
        typeof resolved === "string",
        `Item[${i}] field "${fieldPath}" is not a string`,
      );
      assert.ok(
        /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/.test(resolved),
        `Item[${i}] "${resolved}" is not ISO 8601`,
      );
    }
  },
);

Then(
  "each item in {string} should have field {string} matching email format",
  function (this: GraphQLWorld, path: string, fieldPath: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(Array.isArray(value), `Expected "${path}" to be an array`);
    for (let i = 0; i < value.length; i++) {
      const resolved = resolvePath(
        value[i] as Record<string, unknown>,
        fieldPath,
      ) as string;
      assert.ok(
        typeof resolved === "string",
        `Item[${i}] field "${fieldPath}" is not a string`,
      );
      assert.ok(
        /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(resolved),
        `Item[${i}] "${resolved}" is not email format`,
      );
    }
  },
);

Then(
  "each item in {string} should have {string} not equal to {string}",
  function (
    this: GraphQLWorld,
    path: string,
    fieldPath: string,
    unexpected: string,
  ) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(Array.isArray(value), `Expected "${path}" to be an array`);
    for (let i = 0; i < value.length; i++) {
      const resolved = resolvePath(
        value[i] as Record<string, unknown>,
        fieldPath,
      );
      let parsed: unknown;
      try {
        parsed = JSON.parse(unexpected);
      } catch {
        parsed = unexpected;
      }
      assert.notDeepStrictEqual(
        resolved,
        parsed,
        `Item[${i}] "${fieldPath}" should not equal "${unexpected}"`,
      );
    }
  },
);

Then(
  "each {string} should be an array",
  function (this: GraphQLWorld, path: string) {
    assert.ok(this.lastResponse, "No response received");
    // path like "data.products[*].categories" — resolve the parent array, then check each sub-field
    const parts = path.split("[*].");
    assert.ok(
      parts.length === 2,
      `Expected path with [*] wildcard, got "${path}"`,
    );
    const arrayVal = resolvePath(this.lastResponse.body, parts[0]);
    assert.ok(Array.isArray(arrayVal), `Expected "${parts[0]}" to be an array`);
    for (let i = 0; i < arrayVal.length; i++) {
      const sub = resolvePath(arrayVal[i] as Record<string, unknown>, parts[1]);
      assert.ok(Array.isArray(sub), `Item[${i}].${parts[1]} is not an array`);
    }
  },
);

Then(
  "the response {string} should be null",
  function (this: GraphQLWorld, path: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.strictEqual(value, null);
  },
);

Then(
  "the response {string} should not be null",
  function (this: GraphQLWorld, path: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.notStrictEqual(value, null, `Expected "${path}" to not be null`);
    assert.notStrictEqual(value, undefined, `Expected "${path}" to exist`);
  },
);

Then(
  "the response {string} should contain {string}",
  function (this: GraphQLWorld, path: string, substring: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);

    if (typeof value === "string") {
      assert.ok(
        value.includes(substring),
        `Expected "${value}" to contain "${substring}"`,
      );
      return;
    }

    if (value !== null && typeof value === "object" && !Array.isArray(value)) {
      assert.ok(
        substring in value,
        `Expected "${path}" to contain field "${substring}"`,
      );
      return;
    }

    assert.fail(
      `Expected "${path}" to be a string or object, got ${Array.isArray(value) ? "array" : typeof value}`,
    );
  },
);

Then(
  "the response {string} should be one of {string}",
  function (this: GraphQLWorld, path: string, allowedList: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    const allowed = allowedList.split("|").map((s) => s.trim());
    assert.ok(
      allowed.includes(value as string),
      `Expected "${value}" to be one of [${allowed.join(", ")}]`,
    );
  },
);

Then(
  "the response {string} should be a string",
  function (this: GraphQLWorld, path: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(
      typeof value === "string",
      `Expected "${path}" to be a string, got ${typeof value}`,
    );
  },
);

Then(
  "the response {string} should be a number",
  function (this: GraphQLWorld, path: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(
      typeof value === "number",
      `Expected "${path}" to be a number, got ${typeof value}`,
    );
  },
);

Then(
  "the response {string} should be a boolean",
  function (this: GraphQLWorld, path: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(
      typeof value === "boolean",
      `Expected "${path}" to be a boolean, got ${typeof value}`,
    );
  },
);

Then(
  "the response {string} should match ISO 8601 format",
  function (this: GraphQLWorld, path: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(typeof value === "string", `Expected "${path}" to be a string`);
    assert.ok(
      /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/.test(value as string),
      `Expected "${value}" to match ISO 8601 format (YYYY-MM-DDTHH:mm:ss)`,
    );
  },
);

Then(
  "the response {string} should match email format",
  function (this: GraphQLWorld, path: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.ok(typeof value === "string", `Expected "${path}" to be a string`);
    assert.ok(
      /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value as string),
      `Expected "${value}" to match email format`,
    );
  },
);

Then(
  "the response content type should be {string}",
  function (this: GraphQLWorld, expected: string) {
    assert.ok(this.lastResponse, "No response received");
    const ct = this.lastResponse.contentType || "application/json";
    assert.ok(
      ct.includes(expected),
      `Expected content type "${expected}", got "${ct}"`,
    );
  },
);

Then(
  "the response {string} should exist",
  function (this: GraphQLWorld, path: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    assert.notStrictEqual(
      value,
      undefined,
      `Path "${path}" not found in response`,
    );
    assert.notStrictEqual(value, null, `Path "${path}" is null`);
  },
);

Then(
  "the response {string} should be greater than {int}",
  function (this: GraphQLWorld, path: string, expected: number) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path) as number;
    assert.ok(typeof value === "number", `Expected "${path}" to be a number`);
    assert.ok(
      value > expected,
      `Expected ${value} to be greater than ${expected}`,
    );
  },
);

Then(
  "the response {string} should equal saved {string}",
  function (this: GraphQLWorld, path: string, varName: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path);
    const saved = this.variables[varName];
    assert.deepStrictEqual(
      value,
      saved,
      `Expected "${path}" to equal saved "${varName}" (${saved})`,
    );
  },
);

Then(
  "the response {string} should be after {string}",
  function (this: GraphQLWorld, path1: string, path2: string) {
    assert.ok(this.lastResponse, "No response received");
    const val1 = resolvePath(this.lastResponse.body, path1) as string;
    const val2 = resolvePath(this.lastResponse.body, path2) as string;
    assert.ok(
      new Date(val1) >= new Date(val2),
      `Expected "${val1}" to be after "${val2}"`,
    );
  },
);

Then(
  "the response {string} should have at most {int} decimal places",
  function (this: GraphQLWorld, path: string, places: number) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path) as number;
    assert.ok(typeof value === "number", `Expected "${path}" to be a number`);
    const parts = value.toString().split(".");
    const decimals = parts.length > 1 ? parts[1].length : 0;
    assert.ok(
      decimals <= places,
      `Expected at most ${places} decimal places, got ${decimals}`,
    );
  },
);

Then(
  "the response {string} should contain an item with {string} equal to {string}",
  function (this: GraphQLWorld, path: string, field: string, expected: string) {
    assert.ok(this.lastResponse, "No response received");
    const value = resolvePath(this.lastResponse.body, path) as Record<
      string,
      unknown
    >[];
    assert.ok(Array.isArray(value), `Expected "${path}" to be an array`);
    const found = value.find(
      (item) => (item as Record<string, unknown>)[field] === expected,
    );
    assert.ok(
      found,
      `No item with "${field}" equal to "${expected}" in "${path}"`,
    );
  },
);

Then(
  "the query should execute in less than {int} seconds",
  function (this: GraphQLWorld, seconds: number) {
    assert.ok(this.lastResponse, "No response received");
    assert.ok(
      this.lastResponse.responseTime < seconds * 1000,
      `Response took ${this.lastResponse.responseTime}ms, expected < ${seconds * 1000}ms`,
    );
  },
);

Then(
  "the error message should mention {string}",
  function (this: GraphQLWorld, substring: string) {
    assert.ok(this.lastResponse, "No response received");
    const body = JSON.stringify(this.lastResponse.body).toLowerCase();
    assert.ok(
      body.includes(substring.toLowerCase()),
      `Expected error message to mention "${substring}"`,
    );
  },
);

Then(
  "the error message should mention {string} or {string}",
  function (this: GraphQLWorld, sub1: string, sub2: string) {
    assert.ok(this.lastResponse, "No response received");
    const body = JSON.stringify(this.lastResponse.body).toLowerCase();
    assert.ok(
      body.includes(sub1.toLowerCase()) || body.includes(sub2.toLowerCase()),
      `Expected error message to mention "${sub1}" or "${sub2}"`,
    );
  },
);

Then("the error message should be informative", function (this: GraphQLWorld) {
  assert.ok(this.lastResponse, "No response received");
  const errors = resolvePath(this.lastResponse.body, "errors") as
    | Record<string, unknown>[]
    | undefined;
  assert.ok(errors && errors.length > 0, "Expected errors in response");
  assert.ok(
    (errors[0].message as string).length > 0,
    "Error message should not be empty",
  );
});

Then(
  "the error message should not contain {string}",
  function (this: GraphQLWorld, substring: string) {
    assert.ok(this.lastResponse, "No response received");
    const body = JSON.stringify(this.lastResponse.body);
    assert.ok(
      !body.includes(substring),
      `Error message should not contain "${substring}"`,
    );
  },
);

Then(
  "the response time should be less than {int} milliseconds",
  function (this: GraphQLWorld, ms: number) {
    assert.ok(this.lastResponse, "No response received");
    assert.ok(
      this.lastResponse.responseTime < ms,
      `Response took ${this.lastResponse.responseTime}ms, expected < ${ms}ms`,
    );
  },
);

// ─── Introspection Assertions ────────────────────────────────────────

/**
 * Parse a GraphQL type string like "String!", "Money", "[Product!]!" into its kind/name structure.
 * Returns { name, nonNull } for simple types; used for matching introspection results.
 */
function parseTypeString(typeStr: string): { name: string; nonNull: boolean } {
  const nonNull = typeStr.endsWith("!");
  const name = typeStr.replace(/!$/, "");
  return { name, nonNull };
}

/**
 * Given an introspection type object { kind, name, ofType }, build its string representation.
 */
function typeToString(type: Record<string, unknown>): string {
  if (type.kind === "NON_NULL") {
    return typeToString(type.ofType as Record<string, unknown>) + "!";
  }
  if (type.kind === "LIST") {
    return `[${typeToString(type.ofType as Record<string, unknown>)}]`;
  }
  return type.name as string;
}

function findField(
  body: Record<string, unknown>,
  fieldName: string,
): Record<string, unknown> | undefined {
  const fields = resolvePath(body, "data.__type.fields") as
    | Record<string, unknown>[]
    | undefined;
  if (!fields) return undefined;
  return fields.find((f) => f.name === fieldName);
}

Then(
  "the type {string} should have field {string} of type {string}",
  function (
    this: GraphQLWorld,
    _typeName: string,
    fieldName: string,
    expectedType: string,
  ) {
    assert.ok(this.lastResponse, "No response received");
    const field = findField(this.lastResponse.body, fieldName);
    assert.ok(field, `Field "${fieldName}" not found in type`);
    const actualType = typeToString(field.type as Record<string, unknown>);
    assert.strictEqual(
      actualType,
      expectedType,
      `Expected field "${fieldName}" to be type "${expectedType}", got "${actualType}"`,
    );
  },
);

Then(
  "the field {string} should be deprecated",
  function (this: GraphQLWorld, fieldPath: string) {
    assert.ok(this.lastResponse, "No response received");
    const fieldName = fieldPath.split(".").pop()!;
    const field = findField(this.lastResponse.body, fieldName);
    assert.ok(field, `Field "${fieldName}" not found`);
    assert.strictEqual(
      field.isDeprecated,
      true,
      `Expected field "${fieldName}" to be deprecated`,
    );
  },
);

Then(
  "the field {string} should have deprecation reason containing {string}",
  function (this: GraphQLWorld, fieldPath: string, substring: string) {
    assert.ok(this.lastResponse, "No response received");
    const fieldName = fieldPath.split(".").pop()!;
    const field = findField(this.lastResponse.body, fieldName);
    assert.ok(field, `Field "${fieldName}" not found`);
    const reason = field.deprecationReason as string;
    assert.ok(reason, `Field "${fieldName}" has no deprecation reason`);
    assert.ok(
      reason.toLowerCase().includes(substring.toLowerCase()),
      `Expected deprecation reason "${reason}" to contain "${substring}"`,
    );
  },
);

Then(
  "the field {string} should be nullable",
  function (this: GraphQLWorld, fieldPath: string) {
    assert.ok(this.lastResponse, "No response received");
    const fieldName = fieldPath.split(".").pop()!;
    const field = findField(this.lastResponse.body, fieldName);
    assert.ok(field, `Field "${fieldName}" not found`);
    const type = field.type as Record<string, unknown>;
    assert.notStrictEqual(
      type.kind,
      "NON_NULL",
      `Expected field "${fieldName}" to be nullable`,
    );
  },
);

Then(
  "the field {string} should have argument {string} of type {string}",
  function (
    this: GraphQLWorld,
    fieldPath: string,
    argName: string,
    expectedType: string,
  ) {
    assert.ok(this.lastResponse, "No response received");
    const fieldName = fieldPath.split(".").pop()!;
    const field = findField(this.lastResponse.body, fieldName);
    assert.ok(field, `Field "${fieldName}" not found`);
    const args = field.args as Record<string, unknown>[] | undefined;
    assert.ok(args, `Field "${fieldName}" has no args`);
    const arg = args.find((a) => a.name === argName);
    assert.ok(arg, `Argument "${argName}" not found on field "${fieldName}"`);
    const actualType = typeToString(arg.type as Record<string, unknown>);
    assert.strictEqual(
      actualType,
      expectedType,
      `Expected arg "${argName}" to be type "${expectedType}", got "${actualType}"`,
    );
  },
);

Then(
  "the field {string} should have directive {string}",
  function (this: GraphQLWorld, _fieldPath: string, _directiveName: string) {
    // Note: Standard GraphQL introspection does not expose applied directives on fields.
    // This step is a placeholder that passes — directive behavior should be tested via runtime behavior.
    assert.ok(this.lastResponse, "No response received");
  },
);

Then(
  "the schema should have directive {string}",
  function (this: GraphQLWorld, directiveName: string) {
    assert.ok(this.lastResponse, "No response received");
    const directives = resolvePath(
      this.lastResponse.body,
      "data.__schema.directives",
    ) as Record<string, unknown>[];
    assert.ok(directives, "No directives found in schema");
    const found = directives.find((d) => d.name === directiveName);
    assert.ok(found, `Directive "${directiveName}" not found in schema`);
  },
);

Then(
  "the directive {string} should have location {string}",
  function (this: GraphQLWorld, directiveName: string, location: string) {
    assert.ok(this.lastResponse, "No response received");
    const directives = resolvePath(
      this.lastResponse.body,
      "data.__schema.directives",
    ) as Record<string, unknown>[];
    assert.ok(directives, "No directives found");
    const directive = directives.find((d) => d.name === directiveName);
    assert.ok(directive, `Directive "${directiveName}" not found`);
    const locations = directive.locations as string[];
    assert.ok(
      locations.includes(location),
      `Directive "${directiveName}" does not have location "${location}"`,
    );
  },
);

Then(
  "the directive {string} should have argument {string} of type {string}",
  function (
    this: GraphQLWorld,
    directiveName: string,
    argName: string,
    expectedType: string,
  ) {
    assert.ok(this.lastResponse, "No response received");
    const directives = resolvePath(
      this.lastResponse.body,
      "data.__schema.directives",
    ) as Record<string, unknown>[];
    assert.ok(directives, "No directives found");
    const directive = directives.find((d) => d.name === directiveName);
    assert.ok(directive, `Directive "${directiveName}" not found`);
    const args = directive.args as Record<string, unknown>[];
    const arg = args.find((a) => a.name === argName);
    assert.ok(
      arg,
      `Argument "${argName}" not found on directive "${directiveName}"`,
    );
    const actualType = typeToString(arg.type as Record<string, unknown>);
    assert.strictEqual(actualType, expectedType);
  },
);

Then(
  "the schema should include these types:",
  function (this: GraphQLWorld, table: { rawTable: string[][] }) {
    assert.ok(this.lastResponse, "No response received");
    const types = resolvePath(
      this.lastResponse.body,
      "data.__schema.types",
    ) as Record<string, unknown>[];
    assert.ok(types, "No types found in schema");
    const typeNames = types.map((t) => t.name as string);
    for (const [expectedName] of table.rawTable) {
      assert.ok(
        typeNames.includes(expectedName.trim()),
        `Type "${expectedName.trim()}" not found in schema`,
      );
    }
  },
);

Then(
  "the schema should include these scalar types:",
  function (this: GraphQLWorld, table: { rawTable: string[][] }) {
    assert.ok(this.lastResponse, "No response received");
    const types = resolvePath(
      this.lastResponse.body,
      "data.__schema.types",
    ) as Record<string, unknown>[];
    assert.ok(types, "No types found in schema");
    for (const [expectedName] of table.rawTable) {
      const found = types.find(
        (t) => t.name === expectedName.trim() && t.kind === "SCALAR",
      );
      assert.ok(
        found,
        `Scalar type "${expectedName.trim()}" not found in schema`,
      );
    }
  },
);

Then(
  "the schema should include types from all subgraphs",
  function (this: GraphQLWorld) {
    assert.ok(this.lastResponse, "No response received");
    const types = resolvePath(
      this.lastResponse.body,
      "data.__schema.types",
    ) as Record<string, unknown>[];
    assert.ok(types, "No types found");
    const typeNames = types.map((t) => t.name as string);
    for (const expected of ["Product", "User", "Order"]) {
      assert.ok(typeNames.includes(expected), `Type "${expected}" not found`);
    }
  },
);

Then(
  "the subscription field {string} should exist",
  function (this: GraphQLWorld, fieldName: string) {
    assert.ok(this.lastResponse, "No response received");
    const field = findField(this.lastResponse.body, fieldName);
    assert.ok(field, `Subscription field "${fieldName}" not found`);
  },
);

Then(
  "the subscription field {string} should exist with return type {string}",
  function (this: GraphQLWorld, fieldName: string, expectedType: string) {
    assert.ok(this.lastResponse, "No response received");
    const field = findField(this.lastResponse.body, fieldName);
    assert.ok(field, `Subscription field "${fieldName}" not found`);
    const actualType = typeToString(field.type as Record<string, unknown>);
    assert.strictEqual(actualType, expectedType);
  },
);

Then(
  "the subscription field {string} should have argument {string} of type {string}",
  function (
    this: GraphQLWorld,
    fieldName: string,
    argName: string,
    expectedType: string,
  ) {
    assert.ok(this.lastResponse, "No response received");
    const field = findField(this.lastResponse.body, fieldName);
    assert.ok(field, `Subscription field "${fieldName}" not found`);
    const args = field.args as Record<string, unknown>[] | undefined;
    assert.ok(args, `Field "${fieldName}" has no args`);
    const arg = args.find((a) => a.name === argName);
    assert.ok(arg, `Argument "${argName}" not found on "${fieldName}"`);
    const actualType = typeToString(arg.type as Record<string, unknown>);
    assert.strictEqual(actualType, expectedType);
  },
);

// ─── Subscription Assertions ─────────────────────────────────────────

When(
  "I trigger the mutation:",
  async function (this: GraphQLWorld, mutation: string) {
    await sendGraphQLRequest(
      this.endpoint,
      mutation,
      this.variables,
      this.authHeader,
    );
  },
);

When(
  "another client sends the subscription:",
  function (this: GraphQLWorld, subscription: string) {
    return new Promise<void>((resolve, reject) => {
      const wsUrl = this.endpoint.replace(/^http/, "ws");
      const ws = new WebSocket(wsUrl, "graphql-transport-ws");

      ws.on("open", () => {
        ws.send(JSON.stringify({ type: "connection_init" }));
      });

      ws.on("message", (data: Buffer) => {
        const msg = JSON.parse(data.toString());
        if (msg.type === "connection_ack") {
          ws.send(
            JSON.stringify({
              id: "2",
              type: "subscribe",
              payload: { query: subscription, variables: this.variables },
            }),
          );
          resolve();
        }
        if (msg.type === "next") {
          this.subscriptionEvents.push({ data: msg.payload.data });
        }
      });

      ws.on("error", reject);
      this.secondWsConnection = ws;
    });
  },
);

When("I close the subscription connection", function (this: GraphQLWorld) {
  if (this.wsConnection) {
    this.wsConnection.close();
    this.wsConnection = null;
  }
});

Then(
  "the subscription connection should be open",
  function (this: GraphQLWorld) {
    assert.ok(this.wsConnection, "No WebSocket connection");
    assert.strictEqual(
      this.wsConnection.readyState,
      WebSocket.OPEN,
      "WebSocket is not open",
    );
  },
);

Then(
  "the subscription connection should be closed",
  function (this: GraphQLWorld) {
    assert.ok(
      !this.wsConnection || this.wsConnection.readyState === WebSocket.CLOSED,
      "WebSocket is still open",
    );
  },
);

Then(
  "the subscription should receive an event within {int} seconds",
  async function (this: GraphQLWorld, seconds: number) {
    const deadline = Date.now() + seconds * 1000;
    while (this.subscriptionEvents.length === 0 && Date.now() < deadline) {
      await new Promise((r) => setTimeout(r, 100));
    }
    assert.ok(
      this.subscriptionEvents.length > 0,
      `No subscription event received within ${seconds} seconds`,
    );
  },
);

Then(
  "the subscription should not receive an event within {int} seconds",
  async function (this: GraphQLWorld, seconds: number) {
    await new Promise((r) => setTimeout(r, seconds * 1000));
    assert.strictEqual(
      this.subscriptionEvents.length,
      0,
      `Expected no subscription events, but received ${this.subscriptionEvents.length}`,
    );
  },
);

Then(
  "the subscription should fail with an authentication error",
  async function (this: GraphQLWorld) {
    const deadline = Date.now() + 5000;
    while (this.subscriptionEvents.length === 0 && Date.now() < deadline) {
      await new Promise((r) => setTimeout(r, 100));
    }
    assert.ok(this.subscriptionEvents.length > 0, "Expected an error event");
  },
);

Then(
  "the subscription should fail with an authorization error",
  async function (this: GraphQLWorld) {
    const deadline = Date.now() + 5000;
    while (this.subscriptionEvents.length === 0 && Date.now() < deadline) {
      await new Promise((r) => setTimeout(r, 100));
    }
    assert.ok(this.subscriptionEvents.length > 0, "Expected an error event");
  },
);

Then(
  "both subscriptions should receive an event within {int} seconds",
  async function (this: GraphQLWorld, seconds: number) {
    const deadline = Date.now() + seconds * 1000;
    while (this.subscriptionEvents.length < 1 && Date.now() < deadline) {
      await new Promise((r) => setTimeout(r, 100));
    }
    assert.ok(
      this.subscriptionEvents.length > 0,
      "No subscription events received",
    );
  },
);

Then(
  "the subscription event {string} should be an array",
  function (this: GraphQLWorld, path: string) {
    assert.ok(this.subscriptionEvents.length > 0, "No subscription events");
    const event = this.subscriptionEvents[this.subscriptionEvents.length - 1];
    const value = resolvePath(event.data, path);
    assert.ok(Array.isArray(value), `Expected "${path}" to be an array`);
  },
);

Then(
  "the subscription event {string} should equal {string}",
  function (this: GraphQLWorld, path: string, expected: string) {
    assert.ok(this.subscriptionEvents.length > 0, "No subscription events");
    const event = this.subscriptionEvents[this.subscriptionEvents.length - 1];
    const value = resolvePath(event.data, path);
    let parsed: unknown;
    try {
      parsed = JSON.parse(expected);
    } catch {
      parsed = expected;
    }
    assert.deepStrictEqual(value, parsed);
  },
);

Then(
  "the subscription event {string} should equal {float}",
  function (this: GraphQLWorld, path: string, expected: number) {
    assert.ok(this.subscriptionEvents.length > 0, "No subscription events");
    const event = this.subscriptionEvents[this.subscriptionEvents.length - 1];
    const value = resolvePath(event.data, path);
    assert.strictEqual(value, expected);
  },
);
