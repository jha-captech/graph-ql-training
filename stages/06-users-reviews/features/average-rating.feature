@stage:06
Feature: Product Average Rating (Computed Field)

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Product with reviews has correct average rating
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-001") {
          id
          title
          averageRating
          reviews {
            rating
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.product.averageRating"
    Then the response "data.product.averageRating" should equal 4.5

  Scenario: Product with no reviews has null average rating
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-008") {
          id
          title
          averageRating
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.averageRating" should be null

  Scenario: Product average rating is a Float
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-005") {
          id
          title
          averageRating
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.product.averageRating"
    Then the response "data.product.averageRating" should equal 4.75

  Scenario: Average rating can be queried without reviews field
    When I send a GraphQL query:
      """
      query {
        products {
          id
          title
          averageRating
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array

  Scenario: Average rating updates correctly conceptually
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-001") {
          averageRating
          reviews {
            rating
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.reviews" should be an array
    Then the response "data.product.reviews" should have 4 items
