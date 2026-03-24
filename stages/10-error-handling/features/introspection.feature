@stage:10
Feature: Stage 10 - Schema Introspection for Error Handling

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: CreateProductResult union exists
    When I send a GraphQL query:
      """
      {
        __type(name: "CreateProductResult") {
          name
          kind
          possibleTypes {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.name" should equal "CreateProductResult"
    Then the response "data.__type.kind" should equal "UNION"
    Then the response "data.__type.possibleTypes" should be an array
    Then the response "data.__type.possibleTypes" should have 2 items

  Scenario: CreateProductSuccess type exists with product field
    When I send a GraphQL query:
      """
      {
        __type(name: "CreateProductSuccess") {
          name
          kind
          fields {
            name
            type {
              name
              kind
              ofType {
                name
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.name" should equal "CreateProductSuccess"
    Then the response "data.__type.kind" should equal "OBJECT"
    Then the response should contain "data.__type.fields[?(@.name=='product')]"

  Scenario: ValidationError type exists with correct fields
    When I send a GraphQL query:
      """
      {
        __type(name: "ValidationError") {
          name
          kind
          fields {
            name
            type {
              name
              kind
              ofType {
                name
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.name" should equal "ValidationError"
    Then the response "data.__type.kind" should equal "OBJECT"
    Then the response should contain "data.__type.fields[?(@.name=='message')]"
    Then the response should contain "data.__type.fields[?(@.name=='field')]"
    Then the response should contain "data.__type.fields[?(@.name=='code')]"

  Scenario: createProduct mutation returns CreateProductResult union
    When I send a GraphQL query:
      """
      {
        __type(name: "Mutation") {
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
    Then the response should contain "data.__type.fields[?(@.name=='createProduct')]"
    Then the response "data.__type.fields[?(@.name=='createProduct')].type.name" should equal "CreateProductResult"
    Then the response "data.__type.fields[?(@.name=='createProduct')].type.kind" should equal "UNION"
