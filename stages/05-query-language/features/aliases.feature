@stage:05
Feature: GraphQL Aliases

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query the same field twice with different arguments using aliases
    When I send a GraphQL query:
      """
      query {
        first: product(id: "prod-001") {
          id
          title
          price
        }
        second: product(id: "prod-002") {
          id
          title
          price
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.first.id" should equal "prod-001"
    Then the response "data.first.title" should equal "Mechanical Keyboard"
    Then the response "data.second.id" should equal "prod-002"
    Then the response "data.second.title" should equal "Wireless Mouse"

  Scenario: Query multiple products with descriptive aliases
    When I send a GraphQL query:
      """
      query {
        keyboard: product(id: "prod-001") {
          id
          title
          price
        }
        mouse: product(id: "prod-002") {
          id
          title
          price
        }
        headphones: product(id: "prod-005") {
          id
          title
          price
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.keyboard"
    Then the response should contain "data.mouse"
    Then the response should contain "data.headphones"
    Then the response "data.keyboard.title" should equal "Mechanical Keyboard"
    Then the response "data.mouse.title" should equal "Wireless Mouse"
    Then the response "data.headphones.title" should equal "Noise Cancelling Headphones"

  Scenario: Alias nested fields to avoid confusion
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-001") {
          id
          title
          productCategories: categories {
            id
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.product.productCategories"
    Then the response "data.product.productCategories" should be an array

  Scenario: Aliases work with variables
    When I set the variable "id1" to "prod-001"
    When I set the variable "id2" to "prod-005"
    When I send a GraphQL query:
      """
      query GetTwoProducts($id1: ID!, $id2: ID!) {
        primary: product(id: $id1) {
          id
          title
        }
        secondary: product(id: $id2) {
          id
          title
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "data.primary"
    Then the response should contain "data.secondary"
    Then the response "data.primary.id" should equal "prod-001"
    Then the response "data.secondary.id" should equal "prod-005"

  Scenario: Aliases on list queries
    When I send a GraphQL query:
      """
      query {
        allProducts: products {
          id
          title
        }
        allCategories: categories {
          id
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.allProducts" should be an array
    Then the response "data.allCategories" should be an array
