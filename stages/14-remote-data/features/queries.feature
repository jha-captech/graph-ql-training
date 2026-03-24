@stage:14
Feature: Remote Data Integration

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"
    Given the mock API service is running on port 4010

  Scenario: Query product with shipping estimate
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          price
          shippingEstimate(zipCode: "10001") {
            provider
            days
            cost
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-001"
    Then the response "data.product.shippingEstimate" should not be null
    Then the response "data.product.shippingEstimate.provider" should be a string
    Then the response "data.product.shippingEstimate.days" should be a number
    Then the response "data.product.shippingEstimate.cost" should be a number

  Scenario: Query multiple products with shipping estimates
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 3) {
          edges {
            node {
              id
              title
              shippingEstimate(zipCode: "90210") {
                provider
                days
                cost
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should have 3 items
    Then each item in "data.productsConnection.edges" should have a non-null "node.shippingEstimate"

  Scenario: Different zip codes can produce different estimates
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          estimate1: shippingEstimate(zipCode: "10001") {
            provider
            days
            cost
          }
          estimate2: shippingEstimate(zipCode: "90001") {
            provider
            days
            cost
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.estimate1" should not be null
    Then the response "data.product.estimate2" should not be null

  Scenario: Shipping estimate with nested product data
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          price
          categories {
            name
          }
          seller {
            name
          }
          shippingEstimate(zipCode: "60601") {
            provider
            days
            cost
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.title" should not be null
    Then the response "data.product.categories" should be an array
    Then the response "data.product.shippingEstimate.provider" should not be null

  Scenario: Query product without requesting shipping estimate
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          price
          categories {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-001"
    Then the response should not contain "data.product.shippingEstimate"

  Scenario: Graceful degradation when external API is unavailable
    Given the mock API service is stopped
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          price
          shippingEstimate(zipCode: "10001") {
            provider
            days
            cost
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-001"
    Then the response "data.product.title" should not be null
    Then the response "data.product.shippingEstimate" should be null

  Scenario: Partial success when one field fails
    Given the mock API service is stopped
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          price
          averageRating
          categories {
            name
          }
          shippingEstimate(zipCode: "10001") {
            provider
            days
            cost
          }
          seller {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.title" should not be null
    Then the response "data.product.categories" should be an array
    Then the response "data.product.seller" should not be null
    Then the response "data.product.shippingEstimate" should be null

  Scenario: Multiple products handle mixed success gracefully
    Given the mock API service is unreliable
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 5) {
          edges {
            node {
              id
              title
              shippingEstimate(zipCode: "10001") {
                provider
                days
                cost
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should have 5 items
    Then each item in "data.productsConnection.edges" should have field "node.title"

  Scenario: External API timeout is handled gracefully
    Given the mock API service has high latency
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          shippingEstimate(zipCode: "10001") {
            provider
            days
            cost
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.product.id" should equal "prod-001"
    Then the response "data.product.title" should not be null

  Scenario: Authenticated user can access shipping estimates
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          shippingEstimate(zipCode: "10001") {
            provider
            days
            cost
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.shippingEstimate" should not be null

  Scenario: Unauthenticated user can access shipping estimates
    Given I am not authenticated
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          shippingEstimate(zipCode: "10001") {
            provider
            days
            cost
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.shippingEstimate" should not be null
