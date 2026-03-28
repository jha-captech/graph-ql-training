@stage:04
Feature: Mutation Operations

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Create a product with minimal fields
    When I send a GraphQL mutation:
      """
      mutation {
        createProduct(input: {
          title: "Test Product"
          price: 9999
        }) {
          product {
            id
            title
            price
            status
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.product" should not be null
    Then the response "data.createProduct.product.title" should equal "Test Product"
    Then the response "data.createProduct.product.price" should equal 9999

  Scenario: Create a product with description
    When I send a GraphQL mutation:
      """
      mutation {
        createProduct(input: {
          title: "Product With Description"
          description: "This is a test product description"
          price: 4999
        }) {
          product {
            id
            title
            description
            price
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.product.description" should equal "This is a test product description"

  Scenario: Create a product without description (nullable field)
    When I send a GraphQL mutation:
      """
      mutation {
        createProduct(input: {
          title: "Product Without Description"
          price: 2999
        }) {
          product {
            id
            title
            description
            price
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.product.description" should be null

  Scenario: Create a product with category associations
    When I send a GraphQL mutation:
      """
      mutation {
        createProduct(input: {
          title: "Product With Categories"
          price: 7999
          categoryIds: ["cat-001", "cat-002"]
        }) {
          product {
            id
            title
            price
            categories {
              id
              name
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.product.categories" should be an array
    Then the response "data.createProduct.product.categories" should have 2 items

  Scenario: Create a product with single category
    When I send a GraphQL mutation:
      """
      mutation {
        createProduct(input: {
          title: "Single Category Product"
          price: 3999
          categoryIds: ["cat-001"]
        }) {
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
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.product.categories" should have 1 items
    Then the response "data.createProduct.product.categories[0].id" should equal "cat-001"

  Scenario: Create product with variables
    When I set the variable "input" to:
      | key         | value                  |
      | title       | Variable Product       |
      | description | Created with variables |
      | price       | 5999                   |
    When I send a GraphQL mutation:
      """
      mutation CreateProduct($input: CreateProductInput!) {
        createProduct(input: $input) {
          product {
            id
            title
            description
            price
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.product.title" should equal "Variable Product"

  Scenario: Update a product's title
    When I send a GraphQL mutation:
      """
      mutation {
        updateProduct(id: "prod-001", input: {
          title: "Updated Keyboard Title"
        }) {
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
    Then the response "data.updateProduct.product.id" should equal "prod-001"
    Then the response "data.updateProduct.product.title" should equal "Updated Keyboard Title"

  Scenario: Update a product's price
    When I send a GraphQL mutation:
      """
      mutation {
        updateProduct(id: "prod-002", input: {
          price: 5999
        }) {
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
    Then the response "data.updateProduct.product.id" should equal "prod-002"
    Then the response "data.updateProduct.product.price" should equal 5999

  Scenario: Update a product's status
    When I send a GraphQL mutation:
      """
      mutation {
        updateProduct(id: "prod-008", input: {
          status: ACTIVE
        }) {
          product {
            id
            status
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.updateProduct.product.status" should equal "ACTIVE"

  Scenario: Update multiple fields at once
    When I send a GraphQL mutation:
      """
      mutation {
        updateProduct(id: "prod-001", input: {
          title: "Multi-field Update"
          description: "Updated description"
          price: 11999
          status: ARCHIVED
        }) {
          product {
            id
            title
            description
            price
            status
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.updateProduct.product.title" should equal "Multi-field Update"
    Then the response "data.updateProduct.product.description" should equal "Updated description"
    Then the response "data.updateProduct.product.price" should equal 11999
    Then the response "data.updateProduct.product.status" should equal "ARCHIVED"

  Scenario: Update product with variables
    When I set the variable "productId" to "prod-002"
    When I set the variable "input" to:
      | key   | value                 |
      | title | Variable Update Title |
      | price | 6999                  |
    When I send a GraphQL mutation:
      """
      mutation UpdateProduct($productId: ID!, $input: UpdateProductInput!) {
        updateProduct(id: $productId, input: $input) {
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
    Then the response "data.updateProduct.product.title" should equal "Variable Update Title"

  Scenario: Update non-existent product returns null
    When I send a GraphQL mutation:
      """
      mutation {
        updateProduct(id: "does-not-exist", input: {
          title: "Should Not Work"
        }) {
          product {
            id
            title
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.updateProduct.product" should be null

  Scenario: Create product then query it back
    When I send a GraphQL mutation:
      """
      mutation {
        createProduct(input: {
          title: "Queryable Product"
          price: 8888
        }) {
          product {
            id
            title
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    When I save "data.createProduct.product.id" as variable "id"
    When I send a GraphQL query:
      """
      query GetCreatedProduct($id: ID!) {
        product(id: $id) {
          id
          title
          price
        }
      }
      """
    Then the response status should be 200
    Then the response "data.product.id" should equal saved "id"
    Then the response "data.product.title" should equal "Queryable Product"

  Scenario: Multiple mutations execute serially
    When I send a GraphQL mutation:
      """
      mutation {
        first: createProduct(input: {
          title: "First Product"
          price: 1000
        }) {
          product {
            id
            title
          }
        }
        second: createProduct(input: {
          title: "Second Product"
          price: 2000
        }) {
          product {
            id
            title
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.first.product.title" should equal "First Product"
    Then the response "data.second.product.title" should equal "Second Product"

  Scenario: Create product with nested category query
    When I send a GraphQL mutation:
      """
      mutation {
        createProduct(input: {
          title: "Nested Query Product"
          price: 4444
          categoryIds: ["cat-001"]
        }) {
          product {
            id
            title
            categories {
              id
              name
              products {
                id
                title
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.product.categories[0].products" should be an array

  Scenario: Update product and verify with query
    When I send a GraphQL mutation:
      """
      mutation {
        updateProduct(id: "prod-001", input: {
          title: "Verification Test Product"
        }) {
          product {
            id
          }
        }
      }
      """
    Then the response status should be 200
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          title
        }
      }
      """
    Then the response status should be 200
    Then the response "data.product.title" should equal "Verification Test Product"

  Scenario: Created product has default values
    When I send a GraphQL mutation:
      """
      mutation {
        createProduct(input: {
          title: "Default Values Product"
          price: 1999
        }) {
          product {
            id
            title
            inStock
            status
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.product.inStock" should be a boolean
    Then the response "data.createProduct.product.status" should be one of "DRAFT|ACTIVE|ARCHIVED"
