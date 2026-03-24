@stage:16
Feature: GraphQL Federation

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"
    Given the federation gateway is running
    Given all subgraphs are running

  # ============================================================
  # SUBGRAPH ISOLATION
  # ============================================================

  Scenario: Products subgraph serves product data
    When I query the Products subgraph directly:
      """
      {
        product(id: "prod-001") {
          id
          title
          pricing {
            amount
            currency
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-001"

  Scenario: Users subgraph serves user data
    When I query the Users subgraph directly:
      """
      {
        user(id: "user-001") {
          id
          name
          email
          role
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.user.id" should equal "user-001"

  Scenario: Orders subgraph serves order data
    Given I am authenticated as "CUSTOMER"
    When I query the Orders subgraph directly:
      """
      {
        order(id: "ord-001") {
          id
          status
          total
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.order.id" should equal "ord-001"

  # ============================================================
  # CROSS-SUBGRAPH QUERIES (via Gateway)
  # ============================================================

  Scenario: Query spanning Products and Users subgraphs
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          pricing {
            amount
          }
          seller {
            id
            name
            email
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.title" should not be null
    Then the response "data.product.seller.name" should not be null

  Scenario: Query spanning all three subgraphs
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        order(id: "ord-001") {
          id
          status
          total
          buyer {
            id
            name
            email
          }
          items {
            product {
              id
              title
              pricing {
                amount
                currency
              }
            }
            quantity
            unitPrice
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.order.buyer.name" should equal "Alice"
    Then the response "data.order.items" should be an array
    Then the response "data.order.items[0].product.title" should not be null

  Scenario: Query with entity reference resolution
    When I send a GraphQL query:
      """
      {
        user(id: "user-003") {
          id
          name
          reviews {
            rating
            product {
              id
              title
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.user.reviews" should be an array
    Then the response "data.user.reviews[0].product.title" should not be null

  # ============================================================
  # ENTITY EXTENSIONS
  # ============================================================

  Scenario: Product extended with purchaseCount from Orders subgraph
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          pricing {
            amount
          }
          purchaseCount
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.title" should not be null
    Then the response "data.product.purchaseCount" should be a number

  Scenario: User extended with order statistics from Orders subgraph
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        me {
          id
          name
          orders {
            id
            status
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.me.name" should equal "Alice"
    Then the response "data.me.orders" should be an array

  # ============================================================
  # FEDERATION GATEWAY BEHAVIOR
  # ============================================================

  Scenario: Gateway composes subgraph schemas correctly
    When I send an introspection query to the gateway:
      """
      {
        __schema {
          types {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the schema should include types from all subgraphs

  Scenario: Gateway routes queries to correct subgraphs
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
        }
        user(id: "user-001") {
          id
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.title" should not be null
    Then the response "data.user.name" should not be null

  # ============================================================
  # PARTIAL FAILURE HANDLING
  # ============================================================

  Scenario: Gateway handles subgraph failure gracefully
    Given the Orders subgraph is unavailable
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          pricing {
            amount
          }
        }
        order(id: "ord-001") {
          id
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "data.product.title" should not be null
    Then the response "data.order" should be null

  Scenario: Entity reference fails gracefully when subgraph is down
    Given the Users subgraph is unavailable
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          seller {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "data.product.title" should not be null
    Then the response "data.product.seller" should be null

  # ============================================================
  # PERFORMANCE
  # ============================================================

  Scenario: Gateway batches entity resolution across subgraphs
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 5) {
          edges {
            node {
              id
              title
              seller {
                name
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the query should execute in less than 2 seconds

  Scenario: Complex cross-subgraph query completes efficiently
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        me {
          id
          name
          orders {
            id
            items {
              product {
                title
                seller {
                  name
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the query should execute in less than 3 seconds

  # ============================================================
  # FEDERATION-SPECIFIC FEATURES
  # ============================================================

  Scenario: Subgraph can be queried independently
    When I query the Products subgraph at "http://localhost:4001/graphql":
      """
      {
        product(id: "prod-001") {
          id
          title
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"

  Scenario: Gateway merges results from multiple subgraphs correctly
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          pricing {
            amount
          }
          seller {
            name
            email
          }
          reviews {
            author {
              name
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.title" should not be null
    Then the response "data.product.seller.name" should not be null
    Then the response "data.product.reviews" should be an array

  Scenario: Subgraph authentication is enforced
    Given I am not authenticated
    When I send a GraphQL query:
      """
      {
        order(id: "ord-001") {
          id
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "errors[0].message" should contain "Unauthorized"

  Scenario: Federation supports mutations across subgraphs
    Given I am authenticated as "SELLER"
    When I send a GraphQL mutation:
      """
      mutation {
        createProduct(input: {
          title: "Federation Test Product"
          price: 99.99
          categoryIds: ["cat-001"]
        }) {
          ... on CreateProductSuccess {
            product {
              id
              title
              seller {
                name
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.product.title" should equal "Federation Test Product"
    Then the response "data.createProduct.product.seller.name" should not be null
