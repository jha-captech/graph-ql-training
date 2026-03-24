@stage:03
Feature: Relationship Queries

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query all categories
    When I send a GraphQL query:
      """
      {
        categories {
          id
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.categories" should be an array
    Then the response "data.categories" should have at least 1 items

  Scenario: Query a specific category by ID
    When I send a GraphQL query:
      """
      {
        category(id: "cat-001") {
          id
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.category.id" should equal "cat-001"
    Then the response "data.category.name" should equal "Electronics"

  Scenario: Query non-existent category returns null
    When I send a GraphQL query:
      """
      {
        category(id: "does-not-exist") {
          id
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.category" should be null

  Scenario: Query product with its categories
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
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
    Then the response "data.product.id" should equal "prod-001"
    Then the response "data.product.categories" should be an array
    Then the response "data.product.categories" should have at least 1 items
    Then each item in "data.product.categories" should have fields "id, name"

  Scenario: Product belongs to multiple categories
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
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
    Then the response "data.product.categories" should be an array
    Then the response "data.product.categories" should have at least 2 items

  Scenario: Query category with its products
    When I send a GraphQL query:
      """
      {
        category(id: "cat-001") {
          id
          name
          products {
            id
            title
            price
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.category.id" should equal "cat-001"
    Then the response "data.category.products" should be an array
    Then the response "data.category.products" should have at least 1 items
    Then each item in "data.category.products" should have fields "id, title, price"

  Scenario: Query all products with their categories
    When I send a GraphQL query:
      """
      {
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
    Then each item in "data.products" should have field "categories"
    Then each "data.products[*].categories" should be an array

  Scenario: Query all categories with their products
    When I send a GraphQL query:
      """
      {
        categories {
          id
          name
          products {
            id
            title
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.categories" should be an array
    Then each item in "data.categories" should have field "products"
    Then each "data.categories[*].products" should be an array

  Scenario: Nested traversal - product to categories to products
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          title
          categories {
            name
            products {
              id
              title
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response should contain "data.product.categories[0].products"
    Then the response "data.product.categories[0].products" should be an array

  Scenario: Nested traversal - category to products to categories
    When I send a GraphQL query:
      """
      {
        category(id: "cat-001") {
          name
          products {
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
    Then the response should contain "data.category.products[0].categories"
    Then the response "data.category.products[0].categories" should be an array

  Scenario: Empty relationship returns empty array
    When I send a GraphQL query:
      """
      {
        category(id: "cat-002") {
          id
          name
          products {
            id
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.category.products" should be an array

  Scenario: Query with variables for category
    When I set the variable "categoryId" to "cat-001"
    When I send a GraphQL query:
      """
      query GetCategoryWithProducts($categoryId: ID!) {
        category(id: $categoryId) {
          id
          name
          products {
            id
            title
            price
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.category.id" should equal "cat-001"
    Then the response "data.category.products" should be an array

  Scenario: Multiple queries with aliases
    When I send a GraphQL query:
      """
      {
        electronics: category(id: "cat-001") {
          name
          products {
            title
          }
        }
        homeOffice: category(id: "cat-002") {
          name
          products {
            title
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.electronics.name" should equal "Electronics"
    Then the response "data.homeOffice.name" should equal "Home & Office"

  Scenario: Query with fragment for categories
    When I send a GraphQL query:
      """
      {
        products {
          id
          title
          categories {
            ...CategoryFields
          }
        }
      }

      fragment CategoryFields on Category {
        id
        name
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array
    Then each item in "data.products[*].categories[*]" should have fields "id, name"

  Scenario: Product categories relationship is bidirectional
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          categories {
            id
            products {
              id
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.categories[0].products" should be an array
    Then the response "data.product.categories[0].products" should contain an item with "id" equal to "prod-001"
