@stage:05
Feature: GraphQL Variables

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query with a single variable
    When I set the variable "productId" to "prod-001"
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
    Then the response "data.product.id" should equal "prod-001"
    Then the response "data.product.title" should equal "Mechanical Keyboard"

  Scenario: Query with multiple variables
    When I set the variable "id1" to "prod-001"
    When I set the variable "id2" to "prod-002"
    When I send a GraphQL query:
      """
      query GetTwoProducts($id1: ID!, $id2: ID!) {
        first: product(id: $id1) {
          id
          title
        }
        second: product(id: $id2) {
          id
          title
        }
      }
      """
    Then the response status should be 200
    Then the response "data.first.id" should equal "prod-001"
    Then the response "data.second.id" should equal "prod-002"

  Scenario: Mutation with input variable
    When I set the variable "input" to:
      | key         | value                |
      | title       | Variable Test Product |
      | price       | 9999                 |
      | description | Created with variables |
    When I send a GraphQL mutation:
      """
      mutation CreateProduct($input: CreateProductInput!) {
        createProduct(input: $input) {
          product {
            id
            title
            price
            description
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.product.title" should equal "Variable Test Product"
    Then the response "data.createProduct.product.price" should equal 9999

  Scenario: Variable type validation - missing required variable
    When I send a GraphQL query:
      """
      query GetProduct($productId: ID!) {
        product(id: $productId) {
          id
          title
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "errors[0].message" should contain "Variable"

  Scenario: Variable type validation - wrong type
    When I set the variable "productId" to 12345
    When I send a GraphQL query:
      """
      query GetProduct($productId: ID!) {
        product(id: $productId) {
          id
          title
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product" should be null

  Scenario: Optional variable with default value
    When I send a GraphQL query:
      """
      query GetProducts {
        products {
          id
          title
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array
