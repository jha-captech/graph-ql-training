@stage:07
Feature: Querying Interfaces and Unions

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  # ============================================================================
  # NODE INTERFACE QUERIES
  # ============================================================================

  Scenario: Query product via node interface
    When I send a GraphQL query:
      """
      query {
        node(id: "prod-001") {
          id
          __typename
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "prod-001"
    Then the response "data.node.__typename" should equal "Product"

  Scenario: Query category via node interface
    When I send a GraphQL query:
      """
      query {
        node(id: "cat-001") {
          id
          __typename
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "cat-001"
    Then the response "data.node.__typename" should equal "Category"

  Scenario: Query user via node interface
    When I send a GraphQL query:
      """
      query {
        node(id: "user-001") {
          id
          __typename
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "user-001"
    Then the response "data.node.__typename" should equal "User"

  Scenario: Query review via node interface
    When I send a GraphQL query:
      """
      query {
        node(id: "rev-001") {
          id
          __typename
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "rev-001"
    Then the response "data.node.__typename" should equal "Review"

  Scenario: Query non-existent node returns null
    When I send a GraphQL query:
      """
      query {
        node(id: "invalid-999") {
          id
          __typename
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node" should be null

  # ============================================================================
  # INLINE FRAGMENTS ON NODE INTERFACE
  # ============================================================================

  Scenario: Query product-specific fields with inline fragment
    When I send a GraphQL query:
      """
      query {
        node(id: "prod-001") {
          id
          __typename
          ... on Product {
            title
            price
            inStock
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "prod-001"
    Then the response "data.node.title" should equal "Mechanical Keyboard"
    Then the response "data.node.price" should equal 12999

  Scenario: Query category-specific fields with inline fragment
    When I send a GraphQL query:
      """
      query {
        node(id: "cat-001") {
          id
          __typename
          ... on Category {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "cat-001"
    Then the response "data.node.name" should equal "Electronics"

  Scenario: Query user-specific fields with inline fragment
    When I send a GraphQL query:
      """
      query {
        node(id: "user-001") {
          id
          __typename
          ... on User {
            name
            email
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "user-001"
    Then the response "data.node.name" should equal "Alice Johnson"
    Then the response "data.node.email" should equal "alice@example.com"

  Scenario: Query multiple nodes with different types
    When I send a GraphQL query:
      """
      query {
        product: node(id: "prod-001") {
          id
          __typename
          ... on Product {
            title
          }
        }
        user: node(id: "user-001") {
          id
          __typename
          ... on User {
            name
          }
        }
        category: node(id: "cat-001") {
          id
          __typename
          ... on Category {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-001"
    Then the response "data.user.id" should equal "user-001"
    Then the response "data.category.id" should equal "cat-001"

  # ============================================================================
  # TIMESTAMPED INTERFACE QUERIES
  # ============================================================================

  Scenario: Query timestamped fields on Product
    When I send a GraphQL query:
      """
      query {
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
    Then the response "data.product.id" should equal "prod-001"
    Then the response "data.product.createdAt" should not be null
    Then the response "data.product.updatedAt" should not be null

  Scenario: Query timestamped fields on User
    When I send a GraphQL query:
      """
      query {
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
    Then the response "data.user.id" should equal "user-001"
    Then the response "data.user.createdAt" should not be null
    Then the response "data.user.updatedAt" should not be null

  Scenario: Query timestamped fields via node interface
    When I send a GraphQL query:
      """
      query {
        node(id: "prod-001") {
          id
          ... on Timestamped {
            createdAt
            updatedAt
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "prod-001"
    Then the response "data.node.createdAt" should not be null
    Then the response "data.node.updatedAt" should not be null

  # ============================================================================
  # SEARCH UNION QUERIES
  # ============================================================================

  Scenario: Search returns mixed types with __typename
    When I send a GraphQL query:
      """
      query {
        search(term: "e") {
          __typename
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array
    Then the response "data.search" should have at least 1 items

  Scenario: Search for product by title
    When I send a GraphQL query:
      """
      query {
        search(term: "Keyboard") {
          __typename
          ... on Product {
            id
            title
            price
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array
    Then the response "data.search" should have at least 1 items

  Scenario: Search for category by name
    When I send a GraphQL query:
      """
      query {
        search(term: "Electronics") {
          __typename
          ... on Category {
            id
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array
    Then the response "data.search" should have at least 1 items

  Scenario: Search for user by name
    When I send a GraphQL query:
      """
      query {
        search(term: "Alice") {
          __typename
          ... on User {
            id
            name
            email
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array
    Then the response "data.search" should have at least 1 items

  Scenario: Search with all inline fragments
    When I send a GraphQL query:
      """
      query {
        search(term: "e") {
          __typename
          ... on Product {
            id
            title
            price
          }
          ... on Category {
            id
            name
          }
          ... on User {
            id
            name
            email
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array
    Then the response "data.search" should have at least 1 items

  Scenario: Search with Node interface fragment
    When I send a GraphQL query:
      """
      query {
        search(term: "e") {
          __typename
          ... on Node {
            id
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array

  Scenario: Search returns empty array for no matches
    When I send a GraphQL query:
      """
      query {
        search(term: "xyznonexistent123") {
          __typename
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array
    Then the response "data.search" should have 0 items

  # ============================================================================
  # COMBINED INTERFACE AND UNION QUERIES
  # ============================================================================

  Scenario: Search with nested relationships
    When I send a GraphQL query:
      """
      query {
        search(term: "Keyboard") {
          __typename
          ... on Product {
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
    Then the response "data.search" should be an array

  Scenario: Node query with nested relationships
    When I send a GraphQL query:
      """
      query {
        node(id: "prod-001") {
          id
          ... on Product {
            title
            categories {
              id
              name
            }
            reviews {
              id
              rating
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "prod-001"
    Then the response "data.node.categories" should be an array
    Then the response "data.node.reviews" should be an array

  Scenario: Query combining Node and Timestamped interfaces
    When I send a GraphQL query:
      """
      query {
        node(id: "user-001") {
          id
          __typename
          ... on Timestamped {
            createdAt
            updatedAt
          }
          ... on User {
            name
            email
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.node.id" should equal "user-001"
    Then the response "data.node.__typename" should equal "User"
    Then the response "data.node.createdAt" should not be null
    Then the response "data.node.name" should equal "Alice Johnson"
