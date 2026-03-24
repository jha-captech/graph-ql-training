@stage:07
Feature: Timestamped Interface

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Product implements Timestamped interface
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-001") {
          id
          createdAt
          updatedAt
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.product.createdAt"
    Then the response should contain "data.product.updatedAt"

  Scenario: User implements Timestamped interface
    When I send a GraphQL query:
      """
      query {
        user(id: "user-001") {
          id
          createdAt
          updatedAt
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.user.createdAt"
    Then the response should contain "data.user.updatedAt"

  Scenario: Review implements Timestamped interface
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-001") {
          reviews {
            id
            createdAt
            updatedAt
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.reviews" should be an array
    Then the response "data.product.reviews[0]" should contain "createdAt"
    Then the response "data.product.reviews[0]" should contain "updatedAt"

  Scenario: Category does not implement Timestamped
    When I send a GraphQL query:
      """
      query {
        category(id: "cat-001") {
          id
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.category" should contain "id"

  Scenario: Query Timestamped via Node interface
    When I send a GraphQL query:
      """
      query {
        node(id: "prod-001") {
          id
          ... on Timestamped {
            createdAt
            updatedAt
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.node.createdAt"
    Then the response should contain "data.node.updatedAt"

  Scenario: Type implements both Node and Timestamped
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-001") {
          # Node interface
          id
          # Timestamped interface
          createdAt
          updatedAt
          # Product-specific
          title
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.product.id"
    Then the response should contain "data.product.createdAt"
    Then the response should contain "data.product.title"
