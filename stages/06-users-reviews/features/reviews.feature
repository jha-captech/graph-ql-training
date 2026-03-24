@stage:06
Feature: Review Queries and Relationships

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Product has reviews relationship
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-001") {
          id
          title
          reviews {
            id
            rating
            body
            createdAt
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.reviews" should be an array
    Then the response "data.product.reviews" should have at least 3 items
    Then each item in "data.product.reviews" should have fields "id, rating, createdAt"

  Scenario: Review has author relationship
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-001") {
          reviews {
            id
            rating
            author {
              id
              name
              email
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.reviews[0].author" should contain "id"
    Then the response "data.product.reviews[0].author" should contain "name"
    Then the response "data.product.reviews[0].author.id" should equal "user-001"

  Scenario: Review has product relationship
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-001") {
          reviews {
            id
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
    Then the response "data.product.reviews[0].product.id" should equal "prod-001"

  Scenario: Product with no reviews returns empty array
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-008") {
          id
          title
          reviews {
            id
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.reviews" should be an array
    Then the response "data.product.reviews" should have 0 items

  Scenario: Review body is optional
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-001") {
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
    Then the response "data.product.reviews" should be an array

  Scenario: Review rating is an integer
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-001") {
          reviews {
            rating
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.reviews[0].rating" should equal 5

  Scenario: Nested traversal - User -> Reviews -> Product -> Reviews
    When I send a GraphQL query:
      """
      query {
        user(id: "user-001") {
          reviews {
            id
            product {
              id
              title
              reviews {
                id
                rating
                author {
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
    Then the response "data.user.reviews" should be an array
    Then the response "data.user.reviews[0].product.reviews" should be an array
