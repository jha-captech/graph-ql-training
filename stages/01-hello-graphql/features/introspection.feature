@stage:01
Feature: Schema Introspection for Hello GraphQL

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query type exists
    When I send a GraphQL query:
      """
      {
        __schema {
          queryType {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__schema.queryType.name" should equal "Query"

  Scenario: Query type has hello field
    When I send a GraphQL query:
      """
      {
        __type(name: "Query") {
          fields {
            name
            type {
              name
              kind
              ofType {
                name
                kind
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.fields" should be an array
    Then the response "data.__type.fields" should have 1 items

  Scenario: Hello field is non-null String
    When I send a GraphQL query:
      """
      {
        __type(name: "Query") {
          fields {
            name
            type {
              kind
              ofType {
                name
                kind
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.fields[0].name" should equal "hello"
    Then the response "data.__type.fields[0].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[0].type.ofType.name" should equal "String"
    Then the response "data.__type.fields[0].type.ofType.kind" should equal "SCALAR"
