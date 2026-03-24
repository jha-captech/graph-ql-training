@stage:06
Feature: Create Review Mutation

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Create a review with all fields
    When I send a GraphQL mutation:
      """
      mutation {
        createReview(
          input: {
            productId: "prod-002"
            rating: 5
            body: "Excellent product! Works perfectly."
          }
        ) {
          review {
            id
            rating
            body
            author {
              id
              name
            }
            product {
              id
              title
            }
            createdAt
            updatedAt
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.createReview.review.id"
    Then the response "data.createReview.review.rating" should equal 5
    Then the response "data.createReview.review.body" should equal "Excellent product! Works perfectly."
    Then the response "data.createReview.review.product.id" should equal "prod-002"
    Then the response should contain "data.createReview.review.author.id"

  Scenario: Create a review without body (optional field)
    When I send a GraphQL mutation:
      """
      mutation {
        createReview(
          input: {
            productId: "prod-005"
            rating: 4
          }
        ) {
          review {
            id
            rating
            body
            product {
              title
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createReview.review.rating" should equal 4
    Then the response "data.createReview.review.body" should be null

  Scenario: Create review with minimum rating
    When I send a GraphQL mutation:
      """
      mutation {
        createReview(
          input: {
            productId: "prod-001"
            rating: 1
            body: "Not satisfied"
          }
        ) {
          review {
            id
            rating
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createReview.review.rating" should equal 1

  Scenario: Create review with maximum rating
    When I send a GraphQL mutation:
      """
      mutation {
        createReview(
          input: {
            productId: "prod-001"
            rating: 5
            body: "Perfect!"
          }
        ) {
          review {
            id
            rating
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createReview.review.rating" should equal 5

  Scenario: Created review appears in product's reviews
    When I send a GraphQL mutation:
      """
      mutation {
        createReview(
          input: {
            productId: "prod-002"
            rating: 5
            body: "New review for testing"
          }
        ) {
          review {
            id
            product {
              reviews {
                id
                body
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createReview.review.product.reviews" should be an array

  Scenario: Created review appears in user's reviews
    When I send a GraphQL mutation:
      """
      mutation {
        createReview(
          input: {
            productId: "prod-005"
            rating: 4
          }
        ) {
          review {
            id
            author {
              reviews {
                id
                product {
                  id
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createReview.review.author.reviews" should be an array

  Scenario: Timestamps are set on creation
    When I send a GraphQL mutation:
      """
      mutation {
        createReview(
          input: {
            productId: "prod-001"
            rating: 3
          }
        ) {
          review {
            createdAt
            updatedAt
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.createReview.review.createdAt"
    Then the response should contain "data.createReview.review.updatedAt"
