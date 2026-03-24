@stage:11
Feature: Stage 11 - Schema Introspection for Authentication

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Role enum exists with correct values
    When I send a GraphQL query:
      """
      {
        __type(name: "Role") {
          name
          kind
          enumValues {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.name" should equal "Role"
    Then the response "data.__type.kind" should equal "ENUM"
    Then the response "data.__type.enumValues" should be an array
    Then the response "data.__type.enumValues" should have 3 items
    Then the response should contain "data.__type.enumValues[?(@.name=='CUSTOMER')]"
    Then the response should contain "data.__type.enumValues[?(@.name=='SELLER')]"
    Then the response should contain "data.__type.enumValues[?(@.name=='ADMIN')]"

  Scenario: User type has role field
    When I send a GraphQL query:
      """
      {
        __type(name: "User") {
          fields {
            name
            type {
              name
              kind
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "data.__type.fields[?(@.name=='role')]"
    Then the response "data.__type.fields[?(@.name=='role')].type.name" should equal "Role"
    Then the response "data.__type.fields[?(@.name=='role')].type.kind" should equal "ENUM"

  Scenario: Query type has me field
    When I send a GraphQL query:
      """
      {
        __type(name: "Query") {
          fields {
            name
            type {
              name
              kind
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "data.__type.fields[?(@.name=='me')]"
    Then the response "data.__type.fields[?(@.name=='me')].type.name" should equal "User"

  Scenario: me field returns nullable User
    When I send a GraphQL query:
      """
      {
        __type(name: "Query") {
          fields {
            name
            type {
              kind
              name
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.fields[?(@.name=='me')].type.kind" should equal "OBJECT"
    Then the response "data.__type.fields[?(@.name=='me')].type.name" should equal "User"
