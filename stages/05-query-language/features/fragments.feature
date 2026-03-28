@stage:05
Feature: GraphQL Fragments

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Named fragment on a single query
    When I send a GraphQL query:
      """
      fragment ProductBasicInfo on Product {
        id
        title
        price
        status
      }

      query {
        product(id: "prod-001") {
          ...ProductBasicInfo
          description
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-001"
    Then the response "data.product.title" should equal "Mechanical Keyboard"
    Then the response "data.product.price" should equal 12999
    Then the response should contain "data.product.status"
    Then the response should contain "data.product.description"

  Scenario: Reuse fragment multiple times
    When I send a GraphQL query:
      """
      fragment ProductBasicInfo on Product {
        id
        title
        price
      }

      query {
        first: product(id: "prod-001") {
          ...ProductBasicInfo
        }
        second: product(id: "prod-002") {
          ...ProductBasicInfo
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.first.id" should equal "prod-001"
    Then the response "data.second.id" should equal "prod-002"
    Then the response should contain "data.first"
    Then the response should contain "data.second"

  Scenario: Nested fragments
    When I send a GraphQL query:
      """
      fragment ProductBasicInfo on Product {
        id
        title
        price
      }

      fragment ProductWithCategories on Product {
        ...ProductBasicInfo
        categories {
          id
          name
        }
      }

      query {
        product(id: "prod-001") {
          ...ProductWithCategories
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-001"
    Then the response "data.product.categories" should be an array

  Scenario: Multiple fragments on the same field
    When I send a GraphQL query:
      """
      fragment ProductPricing on Product {
        price
        inStock
      }

      fragment ProductMeta on Product {
        id
        title
        status
      }

      query {
        product(id: "prod-001") {
          ...ProductPricing
          ...ProductMeta
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.product.id"
    Then the response should contain "data.product.title"
    Then the response should contain "data.product.price"
    Then the response should contain "data.product.inStock"
    Then the response should contain "data.product.status"

  Scenario: Fragment in a list query
    When I send a GraphQL query:
      """
      fragment ProductBasicInfo on Product {
        id
        title
        price
      }

      query {
        products {
          ...ProductBasicInfo
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array
    Then each item in "data.products" should have fields "id, title, price, status"

  Scenario: Inline fragment on type
    When I send a GraphQL query:
      """
      query {
        products {
          id
          title
          ... on Product {
            price
            categories {
              name
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array
    Then the response "data.products[0]" should contain "id"
    Then the response "data.products[0]" should contain "title"
    Then the response "data.products[0]" should contain "price"

  Scenario: Fragment with variables
    When I set the variable "productId" to "prod-001"
    When I send a GraphQL query:
      """
      fragment ProductBasicInfo on Product {
        id
        title
        price
      }

      query GetProduct($productId: ID!) {
        product(id: $productId) {
          ...ProductBasicInfo
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-001"

  Scenario: Fragment spread on list with nested relationships
    When I send a GraphQL query:
      """
      fragment CategoryInfo on Category {
        id
        name
      }

      query {
        products {
          id
          title
          categories {
            ...CategoryInfo
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array
