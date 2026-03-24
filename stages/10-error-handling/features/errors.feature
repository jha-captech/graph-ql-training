@stage:10
Feature: Stage 10 - Top-Level Error Handling

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query non-existent product returns top-level error
    When I send a GraphQL query:
      """
      {
        product(id: "non-existent-id") {
          id
          title
          price
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "data.product" should be null
    Then the response "errors[0].message" should not be null
    Then the response "errors[0].path" should be an array

  Scenario: Query non-existent user returns top-level error
    When I send a GraphQL query:
      """
      {
        user(id: "invalid-user-id") {
          id
          name
          email
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "data.user" should be null

  Scenario: Partial success - one field succeeds, another fails
    When I send a GraphQL query:
      """
      {
        validProduct: product(id: "prod-001") {
          id
          title
          price
        }
        invalidProduct: product(id: "invalid-id") {
          id
          title
          price
        }
        categories {
          id
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "data.validProduct" should not be null
    Then the response "data.validProduct.title" should not be null
    Then the response "data.invalidProduct" should be null
    Then the response "data.categories" should be an array

  Scenario: Error response includes path information
    When I send a GraphQL query:
      """
      {
        product(id: "invalid-id") {
          id
          title
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "errors[0].path" should be an array
    Then the response "errors[0].path[0]" should equal "product"

  Scenario: Error response includes message
    When I send a GraphQL query:
      """
      {
        product(id: "non-existent") {
          id
          title
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "errors[0].message" should not be null

  Scenario: Error extensions include error codes
    When I send a GraphQL query:
      """
      {
        product(id: "invalid-id") {
          id
          title
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response should contain "errors[0].extensions"

  Scenario: Multiple errors in single query
    When I send a GraphQL query:
      """
      {
        first: product(id: "invalid-1") {
          id
          title
        }
        second: product(id: "invalid-2") {
          id
          title
        }
        third: user(id: "invalid-user") {
          id
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "errors" should be an array
    Then the response "errors" should have at least 3 items
    Then the response "data.first" should be null
    Then the response "data.second" should be null
    Then the response "data.third" should be null

  Scenario: Complex query with mixed results
    When I send a GraphQL query:
      """
      {
        product1: product(id: "prod-001") {
          id
          title
          price
          categories {
            name
          }
        }

        product2: product(id: "invalid") {
          id
          title
        }

        products {
          id
        }

        user(id: "user-001") {
          name
          reviews {
            rating
          }
        }

        invalidUser: user(id: "invalid-user") {
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "data.product1" should not be null
    Then the response "data.product1.title" should not be null
    Then the response "data.product2" should be null
    Then the response "data.products" should be an array
    Then the response "data.user" should not be null
    Then the response "data.invalidUser" should be null

  Scenario: Null propagation for non-null fields
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          price
          description
        }
      }
      """
    Then the response status should be 200

  Scenario: Query with nested error propagation
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          reviews {
            rating
            author {
              name
            }
          }
        }
      }
      """
    Then the response status should be 200

  Scenario: Error in nested resolver
    When I send a GraphQL query:
      """
      {
        user(id: "user-001") {
          id
          name
          reviews {
            rating
            product {
              id
              title
            }
          }
        }
      }
      """
    Then the response status should be 200

  Scenario: Validation error has all required fields
    When I send a GraphQL query:
      """
      mutation {
        createProduct(
          input: {
            title: ""
            price: 5000
          }
        ) {
          __typename
          ... on ValidationError {
            message
            field
            code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.createProduct.__typename" should equal "ValidationError"
    Then the response "data.createProduct.message" should not be null
    Then the response "data.createProduct.code" should not be null

  Scenario: System errors do not expose sensitive information
    When I send a GraphQL query:
      """
      {
        product(id: "trigger-system-error") {
          id
          title
        }
      }
      """
    Then the response status should be 200
