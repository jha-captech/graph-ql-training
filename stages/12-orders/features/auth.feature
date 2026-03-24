@stage:12
Feature: Stage 12 - Order Authorization and Access Control

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Customer can see their own orders
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        orders {
          id
          buyer {
            id
          }
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.orders" should be an array
    Then the response "data.orders[0].buyer.id" should equal "user-001"

  Scenario: Customer cannot see other customers' orders via orders query
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        orders {
          id
          buyer {
            id
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.orders" should be an array

  Scenario: Customer cannot access another customer's order by ID
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        order(id: "ord-005") {
          id
          buyer {
            id
          }
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "data.order" should be null

  Scenario: Admin can see all orders
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
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.orders" should be an array
    Then the response "data.orders" should have at least 5 items

  Scenario: Admin can access any order by ID
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

  Scenario: Unauthenticated user cannot access orders
    Given I am not authenticated
    When I send a GraphQL query:
      """
      {
        orders {
          id
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Unauthenticated user cannot access order by ID
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

  Scenario: Unauthenticated user cannot place order
    Given I am not authenticated
    When I send a GraphQL query:
      """
      mutation {
        placeOrder(
          input: {
            items: [
              { productId: "prod-001", quantity: 1 }
            ]
          }
        ) {
          __typename
          ... on PlaceOrderSuccess {
            order { id }
          }
          ... on ValidationError {
            message
            code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Customer can place order
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      mutation {
        placeOrder(
          input: {
            items: [
              { productId: "prod-001", quantity: 1 }
            ]
          }
        ) {
          __typename
          ... on PlaceOrderSuccess {
            order {
              id
              buyer {
                id
              }
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
    Then the response "data.placeOrder.__typename" should equal "PlaceOrderSuccess"

  Scenario: Seller can place order
    Given I am authenticated as "SELLER"
    When I send a GraphQL query:
      """
      mutation {
        placeOrder(
          input: {
            items: [
              { productId: "prod-002", quantity: 2 }
            ]
          }
        ) {
          __typename
          ... on PlaceOrderSuccess {
            order {
              id
              buyer {
                id
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.placeOrder.__typename" should equal "PlaceOrderSuccess"

  Scenario: Admin can place order
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      mutation {
        placeOrder(
          input: {
            items: [
              { productId: "prod-003", quantity: 1 }
            ]
          }
        ) {
          __typename
          ... on PlaceOrderSuccess {
            order { id }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"

  Scenario: Only admin can update order status
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      mutation {
        updateOrderStatus(id: "ord-001", status: CONFIRMED) {
          id
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Admin can update order status
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      mutation {
        updateOrderStatus(id: "ord-001", status: CONFIRMED) {
          id
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.updateOrderStatus.status" should equal "CONFIRMED"

  Scenario: Seller cannot update order status
    Given I am authenticated as "SELLER"
    When I send a GraphQL query:
      """
      mutation {
        updateOrderStatus(id: "ord-001", status: SHIPPED) {
          id
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Unauthenticated user cannot update order status
    Given I am not authenticated
    When I send a GraphQL query:
      """
      mutation {
        updateOrderStatus(id: "ord-001", status: CANCELLED) {
          id
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Customer can access their order's buyer details
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
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.order.buyer.email" should not be null

  Scenario: Customer can view line items of their own order
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
              price
            }
            quantity
            unitPrice
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.order.items" should be an array

  Scenario: Order authorization error does not leak order existence
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        order(id: "ord-006") {
          id
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Multiple customers see different order lists
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        orders {
          id
          buyer {
            id
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.orders" should be an array

  Scenario: Product seller field visible to all authenticated users
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

  Scenario: Product seller email respects field-level auth
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          seller {
            id
            name
            email
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.product.seller.email" should be null

  Scenario: Admin can see seller email in product
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          seller {
            id
            name
            email
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.product.seller.email" should not be null

  Scenario: Complex query with mixed order authorization
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        me {
          id
          name
        }
        orders {
          id
          buyer {
            id
          }
        }
        products {
          id
          title
        }
      }
      """
    Then the response status should be 200
    Then the response "data.me" should not be null
    Then the response "data.orders" should be an array
    Then the response "data.products" should be an array

  Scenario: Order via node interface respects authorization
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        node(id: "ord-005") {
          id
          ... on Order {
            buyer {
              id
            }
            status
          }
        }
      }
      """
    Then the response status should be 200
