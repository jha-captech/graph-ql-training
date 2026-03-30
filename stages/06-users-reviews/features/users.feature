@stage:06 @db:reset
Feature: User Queries and Relationships

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query a single user by ID
    When I send a GraphQL query:
      """
      query {
        user(id: "user-001") {
          id
          name
          email
          createdAt
          updatedAt
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.user.id" should equal "user-001"
    Then the response "data.user.name" should equal "Alice Johnson"
    Then the response "data.user.email" should equal "alice@example.com"
    Then the response should contain "data.user.createdAt"
    Then the response should contain "data.user.updatedAt"

  Scenario: Query all users
    When I send a GraphQL query:
      """
      query {
        users {
          id
          name
          email
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.users" should be an array
    Then the response "data.users" should have at least 3 items

  Scenario: Query non-existent user returns null
    When I send a GraphQL query:
      """
      query {
        user(id: "user-999") {
          id
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.user" should be null

  Scenario: User has reviews relationship
    When I send a GraphQL query:
      """
      query {
        user(id: "user-001") {
          id
          name
          reviews {
            id
            rating
            body
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.user.reviews" should be an array
    Then the response "data.user.reviews" should have at least 1 items
    Then each item in "data.user.reviews" should have fields "id, rating"

  Scenario: User with no reviews returns empty array
    When I send a GraphQL query:
      """
      query {
        user(id: "user-003") {
          id
          name
          reviews {
            id
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.user.reviews" should be an array
    Then the response "data.user.reviews" should have 0 items

  Scenario: User reviews include product relationship
    When I send a GraphQL query:
      """
      query {
        user(id: "user-001") {
          id
          name
          reviews {
            id
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
    Then the response should not contain "errors"
    Then the response "data.user.reviews" should be an array
    Then the response should contain "data.user.reviews[0].product.id"
    Then the response should contain "data.user.reviews[0].product.title"

  Scenario: Timestamps are ISO 8601 formatted strings
    When I send a GraphQL query:
      """
      query {
        user(id: "user-001") {
          createdAt
          updatedAt
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.user.createdAt" should contain "T"
    Then the response "data.user.updatedAt" should contain "T"
