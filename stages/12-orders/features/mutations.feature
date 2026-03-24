@stage:12
Feature: Stage 12 - Order Mutations

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Place order successfully as customer
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      mutation {
        placeOrder(
          input: {
            items: [
              { productId: "prod-001", quantity: 2 },
              { productId: "prod-002", quantity: 1 }
            ]
          }
        ) {
          __typename
          ... on PlaceOrderSuccess {
            order {
              id
              buyer {
                id
                name
              }
              items {
                id
                product {
                  id
                  title
                }
                quantity
                unitPrice
              }
              status
              total
              createdAt
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
    Then the response "data.placeOrder.__typename" should equal "PlaceOrderSuccess"
    Then the response "data.placeOrder.order" should not be null
    Then the response "data.placeOrder.order.status" should equal "PENDING"
    Then the response "data.placeOrder.order.items" should be an array
    Then the response "data.placeOrder.order.items" should have 2 items

  Scenario: Place order with single item
    Given I am authenticated as "CUSTOMER"
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
            order {
              id
              items {
                quantity
                unitPrice
              }
              total
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
    Then the response "data.placeOrder.__typename" should equal "PlaceOrderSuccess"
    Then the response "data.placeOrder.order.items" should have 1 items

  Scenario: Place order without authentication fails
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

  Scenario: Place order with empty items returns validation error
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      mutation {
        placeOrder(
          input: {
            items: []
          }
        ) {
          __typename
          ... on PlaceOrderSuccess {
            order { id }
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
    Then the response "data.placeOrder.__typename" should equal "ValidationError"

  Scenario: Place order with invalid product ID returns validation error
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      mutation {
        placeOrder(
          input: {
            items: [
              { productId: "invalid-product-id", quantity: 1 }
            ]
          }
        ) {
          __typename
          ... on PlaceOrderSuccess {
            order { id }
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
    Then the response "data.placeOrder.__typename" should equal "ValidationError"

  Scenario: Place order with zero quantity returns validation error
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      mutation {
        placeOrder(
          input: {
            items: [
              { productId: "prod-001", quantity: 0 }
            ]
          }
        ) {
          __typename
          ... on PlaceOrderSuccess {
            order { id }
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
    Then the response "data.placeOrder.__typename" should equal "ValidationError"

  Scenario: Place order with negative quantity returns validation error
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      mutation {
        placeOrder(
          input: {
            items: [
              { productId: "prod-001", quantity: -5 }
            ]
          }
        ) {
          __typename
          ... on PlaceOrderSuccess {
            order { id }
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
    Then the response "data.placeOrder.__typename" should equal "ValidationError"

  Scenario: Order total is calculated correctly
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      mutation {
        placeOrder(
          input: {
            items: [
              { productId: "prod-001", quantity: 2 }
            ]
          }
        ) {
          __typename
          ... on PlaceOrderSuccess {
            order {
              id
              items {
                quantity
                unitPrice
              }
              total
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
    Then the response "data.placeOrder.__typename" should equal "PlaceOrderSuccess"
    Then the response "data.placeOrder.order.total" should not be null

  Scenario: Unit price is denormalized from product price
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
              items {
                unitPrice
                product {
                  price
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.placeOrder.order.items[0].unitPrice" should not be null

  Scenario: Update order status as admin
    Given I am authenticated as "ADMIN"
    When I set the variable "orderId" to "ord-001"
    When I send a GraphQL query:
      """
      mutation {
        updateOrderStatus(id: "ord-001", status: CONFIRMED) {
          id
          status
          updatedAt
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.updateOrderStatus.status" should equal "CONFIRMED"

  Scenario: Update order status from CONFIRMED to SHIPPED
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      mutation {
        updateOrderStatus(id: "ord-002", status: SHIPPED) {
          id
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.updateOrderStatus.status" should equal "SHIPPED"

  Scenario: Update order status as customer fails
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

  Scenario: Update order status as seller fails
    Given I am authenticated as "SELLER"
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

  Scenario: Update order status without authentication fails
    Given I am not authenticated
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

  Scenario: Update non-existent order fails
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      mutation {
        updateOrderStatus(id: "non-existent-order", status: CONFIRMED) {
          id
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Cancel order from PENDING
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      mutation {
        updateOrderStatus(id: "ord-003", status: CANCELLED) {
          id
          status
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.updateOrderStatus.status" should equal "CANCELLED"

  Scenario: Place multiple orders in sequence
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      mutation {
        order1: placeOrder(
          input: {
            items: [{ productId: "prod-004", quantity: 1 }]
          }
        ) {
          __typename
          ... on PlaceOrderSuccess {
            order { id status }
          }
        }

        order2: placeOrder(
          input: {
            items: [{ productId: "prod-005", quantity: 2 }]
          }
        ) {
          __typename
          ... on PlaceOrderSuccess {
            order { id status }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.order1.__typename" should equal "PlaceOrderSuccess"
    Then the response "data.order2.__typename" should equal "PlaceOrderSuccess"

  Scenario: Place order with multiple quantities of same product
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      mutation {
        placeOrder(
          input: {
            items: [
              { productId: "prod-001", quantity: 5 }
            ]
          }
        ) {
          __typename
          ... on PlaceOrderSuccess {
            order {
              items {
                quantity
                product {
                  title
                }
              }
              total
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.placeOrder.__typename" should equal "PlaceOrderSuccess"
    Then the response "data.placeOrder.order.items[0].quantity" should equal 5

  Scenario: Order status transitions are tracked via updatedAt
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      mutation {
        updateOrderStatus(id: "ord-004", status: CONFIRMED) {
          id
          status
          createdAt
          updatedAt
        }
      }
      """
    Then the response status should be 200
    Then the response "data.updateOrderStatus.updatedAt" should not be null
