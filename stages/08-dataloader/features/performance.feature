@stage:08
Feature: DataLoader Performance

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Large query with nested relationships completes efficiently
    When I send a GraphQL query:
      """
      query {
        products {
          id
          title
          price
          categories {
            id
            name
          }
          reviews {
            id
            rating
            author {
              id
              name
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array
    Then the response "data.products" should have at least 50 items
    Then the response time should be less than 500 milliseconds

  Scenario: Deep nesting query completes efficiently
    When I send a GraphQL query:
      """
      query {
        users {
          id
          name
          reviews {
            id
            rating
            product {
              id
              title
              categories {
                id
                name
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.users" should be an array
    Then the response time should be less than 500 milliseconds

  Scenario: Query with average rating computation performs well
    When I send a GraphQL query:
      """
      query {
        products {
          id
          title
          averageRating
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
    Then the response should not contain "errors"
    Then the response "data.products" should be an array
    Then the response time should be less than 1000 milliseconds

  Scenario: Multiple product queries with aliases perform well
    When I send a GraphQL query:
      """
      query {
        p1: product(id: "prod-001") {
          id
          reviews { author { name } }
        }
        p2: product(id: "prod-002") {
          id
          reviews { author { name } }
        }
        p3: product(id: "prod-005") {
          id
          reviews { author { name } }
        }
        p4: product(id: "prod-008") {
          id
          reviews { author { name } }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response time should be less than 200 milliseconds

  Scenario: Search query with relationships performs well
    When I send a GraphQL query:
      """
      query {
        search(term: "test") {
          __typename
          ... on Product {
            id
            categories { name }
            reviews { author { name } }
          }
          ... on User {
            id
            reviews { product { title } }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response time should be less than 500 milliseconds
