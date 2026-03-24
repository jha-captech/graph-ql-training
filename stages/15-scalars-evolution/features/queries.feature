@stage:15
Feature: Custom Scalars in Queries

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query product with new Pricing type
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          pricing {
            amount
            currency
            compareAtAmount
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.pricing.amount" should be a number
    Then the response "data.product.pricing.currency" should equal "USD"

  Scenario: Query product with deprecated price field still works
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          price
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.price" should be a number

  Scenario: Compare old price with new pricing
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          price
          pricing {
            amount
            currency
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.price" should equal "data.product.pricing.amount"

  Scenario: Query user with EmailAddress scalar
    When I send a GraphQL query:
      """
      {
        user(id: "user-001") {
          id
          name
          email
          role
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.user.email" should match email format

  Scenario: Query user with DateTime scalars
    When I send a GraphQL query:
      """
      {
        user(id: "user-001") {
          id
          name
          createdAt
          updatedAt
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.user.createdAt" should match ISO 8601 format
    Then the response "data.user.updatedAt" should match ISO 8601 format

  Scenario: Query product with DateTime scalars
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          createdAt
          updatedAt
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.createdAt" should match ISO 8601 format
    Then the response "data.product.updatedAt" should match ISO 8601 format

  Scenario: Query order with all typed fields
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        order(id: "ord-001") {
          id
          buyer {
            name
            email
            createdAt
          }
          items {
            product {
              title
              pricing {
                amount
                currency
              }
            }
            quantity
          }
          createdAt
          updatedAt
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.order.buyer.email" should match email format
    Then the response "data.order.buyer.createdAt" should match ISO 8601 format
    Then the response "data.order.createdAt" should match ISO 8601 format

  Scenario: Query review with DateTime scalars
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          reviews {
            id
            rating
            author {
              name
              email
            }
            createdAt
            updatedAt
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then each item in "data.product.reviews" should have field "createdAt" matching ISO 8601 format
    Then each item in "data.product.reviews" should have field "author.email" matching email format

  Scenario: Money scalar has correct precision
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          pricing {
            amount
            currency
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.pricing.amount" should have at most 2 decimal places

  Scenario: Pricing with compareAtAmount
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          pricing {
            amount
            compareAtAmount
            currency
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.pricing.amount" should be a number

  Scenario: ProductsConnection with typed fields
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 5) {
          edges {
            node {
              id
              title
              pricing {
                amount
                currency
              }
              createdAt
              updatedAt
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should have 5 items
    Then each item in "data.productsConnection.edges" should have field "node.createdAt" matching ISO 8601 format
    Then each item in "data.productsConnection.edges" should have field "node.pricing.amount"
