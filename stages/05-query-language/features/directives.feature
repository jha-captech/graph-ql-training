@stage:05
Feature: GraphQL Directives (@include and @skip)

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: @include directive with true condition includes field
    When I set the variable "includeCategories" to true
    When I send a GraphQL query:
      """
      query GetProduct($includeCategories: Boolean!) {
        product(id: "prod-001") {
          id
          title
          price
          categories @include(if: $includeCategories) {
            id
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.product.categories"
    Then the response "data.product.categories" should be an array

  Scenario: @include directive with false condition excludes field
    When I set the variable "includeCategories" to false
    When I send a GraphQL query:
      """
      query GetProduct($includeCategories: Boolean!) {
        product(id: "prod-001") {
          id
          title
          price
          categories @include(if: $includeCategories) {
            id
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should not contain "data.product.categories"

  Scenario: @skip directive with true condition excludes field
    When I set the variable "skipDescription" to true
    When I send a GraphQL query:
      """
      query GetProduct($skipDescription: Boolean!) {
        product(id: "prod-001") {
          id
          title
          price
          description @skip(if: $skipDescription)
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should not contain "data.product.description"

  Scenario: @skip directive with false condition includes field
    When I set the variable "skipDescription" to false
    When I send a GraphQL query:
      """
      query GetProduct($skipDescription: Boolean!) {
        product(id: "prod-001") {
          id
          title
          price
          description @skip(if: $skipDescription)
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.product.description"

  Scenario: Multiple directives on different fields
    When I set the variable "includeCategories" to true
    When I set the variable "skipDescription" to true
    When I send a GraphQL query:
      """
      query GetProduct($includeCategories: Boolean!, $skipDescription: Boolean!) {
        product(id: "prod-001") {
          id
          title
          price
          description @skip(if: $skipDescription)
          categories @include(if: $includeCategories) {
            id
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.product.categories"
    Then the response should not contain "data.product.description"

  Scenario: Directives on nested fields
    When I set the variable "includeProducts" to true
    When I send a GraphQL query:
      """
      query GetCategories($includeProducts: Boolean!) {
        categories {
          id
          name
          products @include(if: $includeProducts) {
            id
            title
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.categories" should be an array
    Then the response "data.categories[0]" should contain "products"

  Scenario: Directives work with fragments
    When I set the variable "includePrice" to true
    When I send a GraphQL query:
      """
      fragment ProductBasicInfo on Product {
        id
        title
        price @include(if: $includePrice)
      }

      query GetProduct($includePrice: Boolean!) {
        product(id: "prod-001") {
          ...ProductBasicInfo
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.product.price"

  Scenario: Directives on list queries
    When I set the variable "skipStatus" to false
    When I send a GraphQL query:
      """
      query GetProducts($skipStatus: Boolean!) {
        products {
          id
          title
          status @skip(if: $skipStatus)
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array
    Then the response "data.products[0]" should contain "status"

  Scenario: @include and @skip on the same query with different fields
    When I set the variable "includeCategories" to true
    When I set the variable "skipInStock" to true
    When I send a GraphQL query:
      """
      query GetProduct($includeCategories: Boolean!, $skipInStock: Boolean!) {
        product(id: "prod-001") {
          id
          title
          inStock @skip(if: $skipInStock)
          categories @include(if: $includeCategories) {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.product.categories"
    Then the response should not contain "data.product.inStock"

  Scenario: Directives work with aliases
    When I set the variable "includeSecond" to false
    When I send a GraphQL query:
      """
      query GetProducts($includeSecond: Boolean!) {
        first: product(id: "prod-001") {
          id
          title
        }
        second: product(id: "prod-002") @include(if: $includeSecond) {
          id
          title
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.first"
    Then the response should not contain "data.second"
