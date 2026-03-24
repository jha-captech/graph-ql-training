@stage:08
Feature: DataLoader Implementation

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: All previous queries still work correctly
    When I send a GraphQL query:
      """
      query {
        product(id: "prod-001") {
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
    Then the response "data.product.id" should equal "prod-001"
    Then the response "data.product.categories" should be an array
    Then the response "data.product.reviews" should be an array

  Scenario: Products with categories query returns correct data
    When I send a GraphQL query:
      """
      query {
        products {
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
    Then the response "data.products" should be an array
    Then the response "data.products" should have at least 10 items

  Scenario: Products with reviews and authors query returns correct data
    When I send a GraphQL query:
      """
      query {
        products {
          id
          title
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

  Scenario: Nested traversal works correctly
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

  Scenario: Same entity referenced multiple times is handled correctly
    When I send a GraphQL query:
      """
      query {
        first: product(id: "prod-001") {
          id
          title
          categories {
            id
            name
          }
        }
        second: product(id: "prod-001") {
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
    Then the response "data.first.id" should equal "prod-001"
    Then the response "data.second.id" should equal "prod-001"

  Scenario: Empty relationships handled correctly
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

  Scenario: Node interface queries work with DataLoader
    When I send a GraphQL query:
      """
      query {
        node(id: "prod-001") {
          id
          ... on Product {
            title
            reviews {
              author {
                name
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "prod-001"

  Scenario: Search union queries work with DataLoader
    When I send a GraphQL query:
      """
      query {
        search(term: "Mechanical") {
          __typename
          ... on Product {
            id
            title
            categories {
              name
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array
