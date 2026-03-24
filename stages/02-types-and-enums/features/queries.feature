@stage:02
Feature: Product Queries

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query all products
    When I send a GraphQL query:
      """
      {
        products {
          id
          title
          description
          price
          inStock
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array
    Then the response "data.products" should have at least 1 items

  Scenario: Query products with selective fields
    When I send a GraphQL query:
      """
      {
        products {
          id
          title
          price
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array
    Then each item in "data.products" should have fields "id, title, price"

  Scenario: Query a specific product by ID
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          description
          price
          inStock
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-001"
    Then the response "data.product.title" should equal "Mechanical Keyboard"
    Then the response "data.product.price" should equal 12999

  Scenario: Query product with nullable description
    When I send a GraphQL query:
      """
      {
        product(id: "prod-008") {
          id
          title
          description
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-008"
    Then the response "data.product.description" should be null
    Then the response "data.product.status" should equal "DRAFT"

  Scenario: Query non-existent product returns null
    When I send a GraphQL query:
      """
      {
        product(id: "does-not-exist") {
          id
          title
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product" should be null

  Scenario: Enum field returns valid enum value
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.status" should be one of "DRAFT|ACTIVE|ARCHIVED"

  Scenario: Query product with variables
    When I set the variable "productId" to "prod-002"
    When I send a GraphQL query:
      """
      query GetProduct($productId: ID!) {
        product(id: $productId) {
          id
          title
          price
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-002"
    Then the response "data.product.title" should equal "Wireless Mouse"
    Then the response "data.product.price" should equal 4999

  Scenario: Query multiple products with aliases
    When I send a GraphQL query:
      """
      {
        first: product(id: "prod-001") {
          id
          title
          price
        }
        second: product(id: "prod-002") {
          id
          title
          price
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.first.id" should equal "prod-001"
    Then the response "data.second.id" should equal "prod-002"
    Then the response "data.first.price" should equal 12999
    Then the response "data.second.price" should equal 4999

  Scenario: Non-null fields are never null
    When I send a GraphQL query:
      """
      {
        products {
          id
          title
          price
          inStock
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then each item in "data.products" should have fields "id, title, price, inStock, status"

  Scenario: Query with __typename
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          __typename
          id
          title
        }
      }
      """
    Then the response status should be 200
    Then the response "data.product.__typename" should equal "Product"

  Scenario: Query with fragment
    When I send a GraphQL query:
      """
      {
        products {
          ...ProductFields
        }
      }

      fragment ProductFields on Product {
        id
        title
        price
        status
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array
    Then each item in "data.products" should have fields "id, title, price, status"
