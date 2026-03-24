@stage:07
Feature: Node Interface - Global Object Identification

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query a product via node interface
    When I send a GraphQL query:
      """
      query {
        node(id: "prod-001") {
          id
          __typename
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "prod-001"
    Then the response "data.node.__typename" should equal "Product"

  Scenario: Query a user via node interface
    When I send a GraphQL query:
      """
      query {
        node(id: "user-001") {
          id
          __typename
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "user-001"
    Then the response "data.node.__typename" should equal "User"

  Scenario: Query a category via node interface
    When I send a GraphQL query:
      """
      query {
        node(id: "cat-001") {
          id
          __typename
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "cat-001"
    Then the response "data.node.__typename" should equal "Category"

  Scenario: Query type-specific fields using inline fragments
    When I send a GraphQL query:
      """
      query {
        node(id: "prod-001") {
          id
          ... on Product {
            title
            price
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "prod-001"
    Then the response "data.node.title" should equal "Mechanical Keyboard"
    Then the response "data.node.price" should equal 12999

  Scenario: Query multiple nodes with aliases
    When I send a GraphQL query:
      """
      query {
        product: node(id: "prod-001") {
          id
          ... on Product {
            title
          }
        }
        user: node(id: "user-001") {
          id
          ... on User {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-001"
    Then the response "data.user.id" should equal "user-001"

  Scenario: Query non-existent node returns null
    When I send a GraphQL query:
      """
      query {
        node(id: "invalid-999") {
          id
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node" should be null

  Scenario: Node interface with nested relationships
    When I send a GraphQL query:
      """
      query {
        node(id: "prod-001") {
          id
          ... on Product {
            title
            categories {
              id
              name
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.categories" should be an array

  Scenario: All implementing types have id field
    When I send a GraphQL query:
      """
      query {
        products {
          id
        }
        categories {
          id
        }
        users {
          id
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array
    Then the response "data.categories" should be an array
    Then the response "data.users" should be an array
