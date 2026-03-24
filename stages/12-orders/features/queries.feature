@stage:12
Feature: Stage 12 - Order Queries

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query all orders as admin
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        orders {
          id
          buyer {
            id
            name
          }
          status
          total
          items {
            id
            product {
              id
              title
            }
            quantity
            unitPrice
          }
          createdAt
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.orders" should be an array
    Then the response "data.orders" should have at least 5 items

  Scenario: Query orders as customer (sees only own orders)
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        orders {
          id
          buyer {
            id
            name
          }
          status
          total
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.orders" should be an array
    Then the response "data.orders[0].buyer.id" should equal "user-001"

  Scenario: Query orders without authentication fails
    Given I am not authenticated
    When I send a GraphQL query:
      """
      {
        orders {
          id
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Query specific order by ID as buyer
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        order(id: "ord-001") {
          id
          buyer {
            id
            name
            email
          }
          items {
            id
            product {
              id
              title
              price
            }
            quantity
            unitPrice
          }
          status
          total
          createdAt
          updatedAt
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.order" should not be null
    Then the response "data.order.id" should equal "ord-001"
    Then the response "data.order.items" should be an array

  Scenario: Query specific order by ID as admin
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        order(id: "ord-002") {
          id
          buyer {
            id
            name
          }
          status
          total
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.order" should not be null

  Scenario: Query order with line items details
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        order(id: "ord-001") {
          id
          items {
            id
            product {
              id
              title
              description
              price
            }
            quantity
            unitPrice
          }
          total
        }
      }
      """
    Then the response status should be 200
    Then the response "data.order.items" should be an array
    Then the response "data.order.items" should have at least 1 items
    Then the response "data.order.items[0].product.title" should not be null
    Then the response "data.order.items[0].unitPrice" should not be null

  Scenario: Query order non-existent order
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        order(id: "non-existent-order") {
          id
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "data.order" should be null

  Scenario: Order total matches sum of line items
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        order(id: "ord-001") {
          id
          total
          items {
            quantity
            unitPrice
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.order.total" should not be null

  Scenario: Query orders filtered by status
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        orders {
          id
          status
          buyer {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.orders" should be an array

  Scenario: Product seller field is visible
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          seller {
            id
            name
            role
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.product.seller" should not be null

  Scenario: Order buyer relationship resolves correctly
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        orders {
          id
          buyer {
            id
            name
            email
            role
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.orders[0].buyer" should not be null
    Then the response "data.orders[0].buyer.role" should not be null

  Scenario: Line item product relationship resolves correctly
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        order(id: "ord-001") {
          items {
            product {
              id
              title
              price
              categories {
                name
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.order.items[0].product" should not be null

  Scenario: Complex nested order query
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        orders {
          id
          buyer {
            id
            name
            reviews {
              rating
            }
          }
          items {
            product {
              id
              title
              seller {
                name
              }
              reviews {
                rating
                author {
                  name
                }
              }
            }
            quantity
            unitPrice
          }
          status
          total
        }
      }
      """
    Then the response status should be 200
    Then the response "data.orders" should be an array

  Scenario: Query order via node interface
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        node(id: "ord-001") {
          id
          ... on Order {
            buyer {
              name
            }
            status
            total
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.node" should not be null

  Scenario: Orders have timestamps
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        orders {
          id
          createdAt
          updatedAt
        }
      }
      """
    Then the response status should be 200
    Then the response "data.orders[0].createdAt" should not be null
    Then the response "data.orders[0].updatedAt" should not be null
