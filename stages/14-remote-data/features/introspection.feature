@stage:14
Feature: Stage 14 Schema Introspection

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: ShippingEstimate type exists
    When I send a GraphQL query:
      """
      {
        __type(name: "ShippingEstimate") {
          name
          kind
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
    Then the response "data.__type.name" should equal "ShippingEstimate"
    Then the response "data.__type.kind" should equal "OBJECT"

  Scenario: ShippingEstimate has required fields
    When I send a GraphQL query:
      """
      {
        __type(name: "ShippingEstimate") {
          fields {
            name
            type {
              kind
              name
              ofType {
                kind
                name
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the type "ShippingEstimate" should have field "provider" of type "String!"
    Then the type "ShippingEstimate" should have field "days" of type "Int!"
    Then the type "ShippingEstimate" should have field "cost" of type "Float!"

  Scenario: Product.shippingEstimate field exists
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
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
                kind
                name
                ofType {
                  kind
                  name
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the type "Product" should have field "shippingEstimate" of type "ShippingEstimate"
    Then the field "Product.shippingEstimate" should have argument "zipCode" of type "String!"

  Scenario: Product.shippingEstimate is nullable
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
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
    Then the response should not contain "errors"
    Then the field "Product.shippingEstimate" should be nullable

  Scenario: All types from stage 13 are still present
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
      | Product          |
      | Category         |
      | User             |
      | Review           |
      | Order            |
      | LineItem         |
      | Subscription     |
      | ShippingEstimate |

  Scenario: Subscription type is still present and functional
    When I send a GraphQL query:
      """
      {
        __type(name: "Subscription") {
          fields {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the subscription field "orderStatusChanged" should exist
    Then the subscription field "productCreated" should exist
