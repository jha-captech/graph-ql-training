@stage:13
Feature: Stage 13 Schema Introspection

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Subscription type exists
    When I send a GraphQL query:
      """
      {
        __schema {
          subscriptionType {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__schema.subscriptionType.name" should equal "Subscription"

  Scenario: orderStatusChanged subscription field exists
    When I send a GraphQL query:
      """
      {
        __type(name: "Subscription") {
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
            args {
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
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.fields" should be an array
    Then the response should contain "data.__type.fields"
    # Verify orderStatusChanged field
    Then the subscription field "orderStatusChanged" should exist with return type "Order"
    Then the subscription field "orderStatusChanged" should have argument "orderId" of type "ID!"

  Scenario: productCreated subscription field exists
    When I send a GraphQL query:
      """
      {
        __type(name: "Subscription") {
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
    Then the subscription field "productCreated" should exist with return type "Product"

  Scenario: All required types from stage 12 are still present
    When I send a GraphQL query:
      """
      {
        __schema {
          types {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the schema should include these types:
      | Product       |
      | Category      |
      | User          |
      | Review        |
      | Order         |
      | LineItem      |
      | Subscription  |
