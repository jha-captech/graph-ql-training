import jwt from 'jsonwebtoken';
import type { GraphQLResponse } from './world';

const JWT_SECRET = 'graphql-training-secret';

// Pre-configured user mappings for each role
const ROLE_USERS: Record<string, { sub: string; role: string; email: string; name: string }> = {
  CUSTOMER: { sub: 'user-001', role: 'CUSTOMER', email: 'alice@example.com', name: 'Alice Johnson' },
  SELLER:   { sub: 'user-003', role: 'SELLER',   email: 'carol@example.com', name: 'Carol Williams' },
  ADMIN:    { sub: 'user-005', role: 'ADMIN',     email: 'eve@example.com',   name: 'Eve Davis' },
};

export function generateToken(role: string): string {
  const user = ROLE_USERS[role];
  if (!user) {
    throw new Error(`Unknown role: ${role}. Valid roles: ${Object.keys(ROLE_USERS).join(', ')}`);
  }
  return jwt.sign(user, JWT_SECRET, { expiresIn: '1h' });
}

export async function sendGraphQLRequest(
  endpoint: string,
  query: string,
  variables: Record<string, unknown>,
  authHeader: string | null,
): Promise<GraphQLResponse> {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
  };
  if (authHeader) {
    headers['Authorization'] = authHeader;
  }

  const start = Date.now();
  const response = await fetch(endpoint, {
    method: 'POST',
    headers,
    body: JSON.stringify({ query, variables }),
  });
  const responseTime = Date.now() - start;

  const body = await response.json() as Record<string, unknown>;

  return {
    status: response.status,
    body,
    responseTime,
    contentType: response.headers.get('content-type') || '',
  };
}

/**
 * Resolve a dot-notation path on an object.
 * Supports array indexing: "data.products[0].title"
 * Supports JSONPath filter: "data.__type.fields[?(@.name=='title')].type.name"
 */
export function resolvePath(obj: unknown, path: string): unknown {
  // Split on dots but preserve bracket expressions
  const tokens: string[] = [];
  let current = '';
  for (let i = 0; i < path.length; i++) {
    if (path[i] === '.' && !current.includes('[?')) {
      if (current) tokens.push(current);
      current = '';
    } else if (path[i] === '[' && path[i + 1] === '?' && current) {
      tokens.push(current);
      current = '[';
    } else if (path[i] === ']' && current.startsWith('[?')) {
      tokens.push(current + ']');
      current = '';
      if (path[i + 1] === '.') i++; // skip the dot after ]
    } else {
      current += path[i];
    }
  }
  if (current) tokens.push(current);

  let value: unknown = obj;
  for (const token of tokens) {
    if (value === null || value === undefined) return undefined;

    // Handle array index: [0], [1], etc.
    const indexMatch = token.match(/^(\d+)$/);
    if (indexMatch) {
      if (Array.isArray(value)) {
        value = value[parseInt(indexMatch[1])];
        continue;
      }
    }

    // Handle combined key[index]: "items[0]"
    const keyIndexMatch = token.match(/^(\w+)\[(\d+)\]$/);
    if (keyIndexMatch) {
      value = (value as Record<string, unknown>)[keyIndexMatch[1]];
      if (Array.isArray(value)) {
        value = value[parseInt(keyIndexMatch[2])];
      } else {
        return undefined;
      }
      continue;
    }

    // Handle JSONPath filter: [?(@.name=='value')]
    const filterMatch = token.match(/^\[\?\(@\.(\w+)==['"](.*)['"]\)\]$/);
    if (filterMatch) {
      if (!Array.isArray(value)) return undefined;
      const [, filterKey, filterValue] = filterMatch;
      value = value.find((item: Record<string, unknown>) => item[filterKey] === filterValue);
      continue;
    }

    // Regular property access
    if (typeof value === 'object' && value !== null) {
      value = (value as Record<string, unknown>)[token];
    } else {
      return undefined;
    }
  }
  return value;
}
