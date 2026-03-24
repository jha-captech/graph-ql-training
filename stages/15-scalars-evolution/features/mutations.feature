@stage:15
Feature: Custom Scalars in Mutations

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Create product returns typed fields
    Given I am authenticated as "SELLER"
    When I send a GraphQL mutation:
      """
      mutation {
        createProduct(input: {
          title: "Test Product with Custom Scalars"
          description: "Testing Money and DateTime scalars"
          price: 149.99
          categoryIds: ["cat-001"]
        }) {
          ... on CreateProductSuccess {
            product {
              id
              title
              pricing {
                amount
                currency
                compareAtAmount
              }
              createdAt
              updatedAt
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
    Then the response "data.createProduct.product.pricing.amount" should equal 149.99
    Then the response "data.createProduct.product.pricing.currency" should equal "USD"
    Then the response "data.createProduct.product.createdAt" should match ISO 8601 format
    Then the response "data.createProduct.product.updatedAt" should match ISO 8601 format

  Scenario: Create review returns DateTime scalars
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL mutation:
      """
      mutation {
        createReview(input: {
          productId: "prod-001"
          rating: 5
          body: "Great product!"
        }) {
          review {
            id
            rating
            body
            author {
              email
              createdAt
            }
            createdAt
            updatedAt
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createReview.review.author.email" should match email format
    Then the response "data.createReview.review.createdAt" should match ISO 8601 format
    Then the response "data.createReview.review.updatedAt" should match ISO 8601 format

  Scenario: Update product preserves typed fields
    Given I am authenticated as "SELLER"
    When I send a GraphQL mutation:
      """
      mutation {
        updateProduct(id: "prod-001", input: {
          title: "Updated Product Title"
          price: 199.99
        }) {
          product {
            id
            title
            pricing {
              amount
              currency
            }
            updatedAt
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.updateProduct.product.pricing.amount" should equal 199.99
    Then the response "data.updateProduct.product.updatedAt" should match ISO 8601 format

  Scenario: Place order returns typed fields
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL mutation:
      """
      mutation {
        placeOrder(input: {
          items: [
            { productId: "prod-001", quantity: 2 }
          ]
        }) {
          ... on PlaceOrderSuccess {
            order {
              id
              buyer {
                email
                createdAt
              }
              items {
                product {
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
          ... on ValidationError {
            message
            code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.placeOrder.order.buyer.email" should match email format
    Then the response "data.placeOrder.order.createdAt" should match ISO 8601 format

  Scenario: Invalid email address is rejected
    Given I am authenticated as "ADMIN"
    When I send a GraphQL mutation:
      """
      mutation {
        createUser(input: {
          email: "not-an-email"
          name: "Test User"
          password: "password123"
        }) {
          user {
            id
            email
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "errors[0].message" should contain "email"

  Scenario: Money scalar handles decimal precision correctly
    Given I am authenticated as "SELLER"
    When I send a GraphQL mutation:
      """
      mutation {
        createProduct(input: {
          title: "Precise Price Product"
          price: 99.95
          categoryIds: ["cat-001"]
        }) {
          ... on CreateProductSuccess {
            product {
              id
              pricing {
                amount
                currency
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.product.pricing.amount" should equal 99.95

  Scenario: Money scalar handles whole numbers correctly
    Given I am authenticated as "SELLER"
    When I send a GraphQL mutation:
      """
      mutation {
        createProduct(input: {
          title: "Whole Price Product"
          price: 100
          categoryIds: ["cat-001"]
        }) {
          ... on CreateProductSuccess {
            product {
              pricing {
                amount
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.product.pricing.amount" should equal 100.00

  Scenario: Created entities have valid DateTime timestamps
    Given I am authenticated as "SELLER"
    When I send a GraphQL mutation:
      """
      mutation {
        createProduct(input: {
          title: "Timestamp Test Product"
          price: 50.00
          categoryIds: ["cat-001"]
        }) {
          ... on CreateProductSuccess {
            product {
              createdAt
              updatedAt
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.product.createdAt" should match ISO 8601 format
    Then the response "data.createProduct.product.updatedAt" should match ISO 8601 format
    Then the response "data.createProduct.product.createdAt" should equal "data.createProduct.product.updatedAt"

  Scenario: Update changes updatedAt timestamp
    Given I am authenticated as "SELLER"
    When I send a GraphQL mutation:
      """
      mutation {
        updateProduct(id: "prod-001", input: {
          title: "Updated Title"
        }) {
          product {
            createdAt
            updatedAt
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.updateProduct.product.updatedAt" should be after "data.updateProduct.product.createdAt"
