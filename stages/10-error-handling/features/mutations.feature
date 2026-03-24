@stage:10
Feature: Stage 10 - Error Handling in Mutations

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Successful product creation returns CreateProductSuccess
    When I send a GraphQL query:
      """
      mutation {
        createProduct(
          input: {
            title: "Test Product"
            description: "A valid test product"
            price: 9999
            categoryIds: ["cat-001"]
          }
        ) {
          __typename
          ... on CreateProductSuccess {
            product {
              id
              title
              price
            }
          }
          ... on ValidationError {
            message
            field
            code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.__typename" should equal "CreateProductSuccess"
    Then the response "data.createProduct.product.title" should equal "Test Product"
    Then the response "data.createProduct.product.price" should equal 9999

  Scenario: Missing title returns ValidationError
    When I send a GraphQL query:
      """
      mutation {
        createProduct(
          input: {
            title: ""
            price: 9999
          }
        ) {
          __typename
          ... on CreateProductSuccess {
            product {
              id
            }
          }
          ... on ValidationError {
            message
            field
            code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.__typename" should equal "ValidationError"
    Then the response "data.createProduct.field" should equal "title"
    Then the response "data.createProduct.code" should not be null

  Scenario: Negative price returns ValidationError
    When I send a GraphQL query:
      """
      mutation {
        createProduct(
          input: {
            title: "Invalid Product"
            price: -100
          }
        ) {
          __typename
          ... on CreateProductSuccess {
            product {
              id
            }
          }
          ... on ValidationError {
            message
            field
            code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.__typename" should equal "ValidationError"
    Then the response "data.createProduct.field" should equal "price"

  Scenario: Zero price returns ValidationError
    When I send a GraphQL query:
      """
      mutation {
        createProduct(
          input: {
            title: "Zero Price Product"
            price: 0
          }
        ) {
          __typename
          ... on CreateProductSuccess {
            product {
              id
            }
          }
          ... on ValidationError {
            message
            field
            code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.__typename" should equal "ValidationError"

  Scenario: Invalid category ID returns ValidationError
    When I send a GraphQL query:
      """
      mutation {
        createProduct(
          input: {
            title: "Test Product"
            price: 9999
            categoryIds: ["invalid-category-id"]
          }
        ) {
          __typename
          ... on CreateProductSuccess {
            product {
              id
            }
          }
          ... on ValidationError {
            message
            field
            code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.createProduct.__typename" should equal "ValidationError"

  Scenario: Multiple validation errors return first error
    When I send a GraphQL query:
      """
      mutation {
        createProduct(
          input: {
            title: ""
            price: -500
          }
        ) {
          __typename
          ... on CreateProductSuccess {
            product {
              id
            }
          }
          ... on ValidationError {
            message
            field
            code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.createProduct.__typename" should equal "ValidationError"
    Then the response "data.createProduct.code" should not be null

  Scenario: Update product with valid data succeeds
    When I send a GraphQL query:
      """
      mutation {
        updateProduct(
          id: "prod-001"
          input: {
            title: "Updated Title"
            price: 15999
          }
        ) {
          product {
            id
            title
            price
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.updateProduct.product.title" should equal "Updated Title"
    Then the response "data.updateProduct.product.price" should equal 15999

  Scenario: Update non-existent product returns top-level error
    When I send a GraphQL query:
      """
      mutation {
        updateProduct(
          id: "non-existent-product"
          input: {
            title: "New Title"
          }
        ) {
          product {
            id
            title
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "data.updateProduct" should be null

  Scenario: Update product with invalid data returns error
    When I send a GraphQL query:
      """
      mutation {
        updateProduct(
          id: "prod-001"
          input: {
            price: -500
          }
        ) {
          product {
            id
            price
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Create review with valid data succeeds
    When I send a GraphQL query:
      """
      mutation {
        createReview(
          input: {
            productId: "prod-002"
            rating: 5
            body: "Excellent product!"
          }
        ) {
          review {
            id
            rating
            body
            author {
              name
            }
            product {
              title
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createReview.review.rating" should equal 5
    Then the response "data.createReview.review.body" should equal "Excellent product!"

  Scenario: Create review with invalid rating returns error
    When I send a GraphQL query:
      """
      mutation {
        createReview(
          input: {
            productId: "prod-001"
            rating: 6
            body: "Great!"
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
    Then the response should contain "errors"

  Scenario: Create review for non-existent product returns error
    When I send a GraphQL query:
      """
      mutation {
        createReview(
          input: {
            productId: "invalid-product-id"
            rating: 5
            body: "Good"
          }
        ) {
          review {
            id
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "data.createReview" should be null

  Scenario: Multiple mutations with mixed success and failure
    When I send a GraphQL query:
      """
      mutation {
        success: createProduct(
          input: {
            title: "Valid Product"
            price: 10000
          }
        ) {
          __typename
          ... on CreateProductSuccess {
            product { id title }
          }
          ... on ValidationError {
            message code
          }
        }

        failure: createProduct(
          input: {
            title: ""
            price: 5000
          }
        ) {
          __typename
          ... on CreateProductSuccess {
            product { id }
          }
          ... on ValidationError {
            message field code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.success.__typename" should equal "CreateProductSuccess"
    Then the response "data.failure.__typename" should equal "ValidationError"
