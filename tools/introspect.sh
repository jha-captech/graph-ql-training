#!/usr/bin/env bash
# Export the schema from a running GraphQL server via introspection.
# Usage: ./tools/introspect.sh [endpoint]
# Default endpoint: http://localhost:4000/graphql

ENDPOINT="${1:-http://localhost:4000/graphql}"

curl -s -X POST "$ENDPOINT" \
  -H "Content-Type: application/json" \
  -d '{"query":"{ __schema { queryType { name } mutationType { name } subscriptionType { name } types { kind name description fields(includeDeprecated: true) { name description args { name description type { kind name ofType { kind name ofType { kind name ofType { kind name } } } } } type { kind name ofType { kind name ofType { kind name ofType { kind name } } } } isDeprecated deprecationReason } inputFields { name description type { kind name ofType { kind name ofType { kind name ofType { kind name } } } } } interfaces { kind name ofType { kind name } } enumValues(includeDeprecated: true) { name description isDeprecated deprecationReason } possibleTypes { kind name } } directives { name description locations args { name description type { kind name ofType { kind name ofType { kind name } } } } } } }"}' | python3 -m json.tool
