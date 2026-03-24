@stage:04
Feature: Query Operations for Mutations Stage

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query products still works after adding mutations
    When I send a GraphQL query:
      """
      {
        products {
          id
          title
          price
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array

  Scenario: Query product with categories still works
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          categories {
            id
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-001"

  Scenario: Query categories still works
    When I send a GraphQL query:
      """
      {
        categories {
          id
          name
          products {
            id
            title
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.categories" should be an array
