@stage:13
Feature: GraphQL Subscriptions

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Subscribe to order status changes for a specific order
    Given I am authenticated as "CUSTOMER"
    When I send the subscription:
      """
      subscription {
        orderStatusChanged(orderId: "ord-001") {
          id
          status
          buyer {
            id
            name
          }
          total
        }
      }
      """
    And I trigger the mutation:
      """
      mutation {
        updateOrderStatus(id: "ord-001", status: SHIPPED) {
          id
          status
        }
      }
      """
    Then the subscription should receive an event within 5 seconds
    Then the subscription event "data.orderStatusChanged.id" should equal "ord-001"
    Then the subscription event "data.orderStatusChanged.status" should equal "SHIPPED"
    Then the subscription event "data.orderStatusChanged.buyer.name" should equal "Alice Johnson"

  Scenario: Subscription only receives events for the specified order
    Given I am authenticated as "CUSTOMER"
    When I send the subscription:
      """
      subscription {
        orderStatusChanged(orderId: "ord-001") {
          id
          status
        }
      }
      """
    And I trigger the mutation:
      """
      mutation {
        updateOrderStatus(id: "ord-004", status: CONFIRMED) {
          id
          status
        }
      }
      """
    Then the subscription should not receive an event within 3 seconds

  Scenario: Multiple updates to the same order trigger multiple events
    Given I am authenticated as "CUSTOMER"
    When I send the subscription:
      """
      subscription {
        orderStatusChanged(orderId: "ord-001") {
          id
          status
        }
      }
      """
    And I trigger the mutation:
      """
      mutation {
        updateOrderStatus(id: "ord-001", status: CONFIRMED) {
          id
        }
      }
      """
    Then the subscription should receive an event within 5 seconds
    Then the subscription event "data.orderStatusChanged.status" should equal "CONFIRMED"
    When I trigger the mutation:
      """
      mutation {
        updateOrderStatus(id: "ord-001", status: SHIPPED) {
          id
        }
      }
      """
    Then the subscription should receive an event within 5 seconds
    Then the subscription event "data.orderStatusChanged.status" should equal "SHIPPED"

  Scenario: Subscribe to new product creation events
    Given I am authenticated as "SELLER"
    When I send the subscription:
      """
      subscription {
        productCreated {
          id
          title
          price
          status
          seller {
            name
          }
        }
      }
      """
    And I trigger the mutation:
      """
      mutation {
        createProduct(input: {
          title: "Subscription Test Product"
          description: "Created to test subscription"
          price: 9999
          categoryIds: ["cat-001"]
        }) {
          ... on CreateProductSuccess {
            product {
              id
              title
            }
          }
        }
      }
      """
    Then the subscription should receive an event within 5 seconds
    Then the subscription event "data.productCreated.title" should equal "Subscription Test Product"
    Then the subscription event "data.productCreated.price" should equal 9999
    Then the subscription event "data.productCreated.status" should equal "DRAFT"

  Scenario: Product creation subscription broadcasts to all subscribers
    Given I am authenticated as "SELLER"
    When I send the subscription:
      """
      subscription {
        productCreated {
          id
          title
        }
      }
      """
    And another client sends the subscription:
      """
      subscription {
        productCreated {
          id
          title
        }
      }
      """
    And I trigger the mutation:
      """
      mutation {
        createProduct(input: {
          title: "Broadcast Test Product"
          price: 4999
          categoryIds: ["cat-002"]
        }) {
          ... on CreateProductSuccess {
            product {
              id
            }
          }
        }
      }
      """
    Then both subscriptions should receive an event within 5 seconds
    Then the subscription event "data.productCreated.title" should equal "Broadcast Test Product"

  Scenario: Subscription connection can be cleanly closed
    Given I am authenticated as "CUSTOMER"
    When I send the subscription:
      """
      subscription {
        orderStatusChanged(orderId: "ord-001") {
          id
          status
        }
      }
      """
    Then the subscription connection should be open
    When I close the subscription connection
    Then the subscription connection should be closed

  Scenario: Subscription with nested fields resolves correctly
    Given I am authenticated as "CUSTOMER"
    When I send the subscription:
      """
      subscription {
        orderStatusChanged(orderId: "ord-001") {
          id
          status
          items {
            id
            product {
              id
              title
            }
            quantity
            unitPrice
          }
          buyer {
            id
            name
            email
          }
          total
        }
      }
      """
    And I trigger the mutation:
      """
      mutation {
        updateOrderStatus(id: "ord-001", status: DELIVERED) {
          id
        }
      }
      """
    Then the subscription should receive an event within 5 seconds
    Then the subscription event "data.orderStatusChanged.status" should equal "DELIVERED"
    Then the subscription event "data.orderStatusChanged.items" should be an array
    Then the subscription event "data.orderStatusChanged.buyer.name" should equal "Alice Johnson"

  Scenario: Unauthenticated subscription is rejected
    Given I am not authenticated
    When I send the subscription:
      """
      subscription {
        orderStatusChanged(orderId: "ord-001") {
          id
          status
        }
      }
      """
    Then the subscription should fail with an authentication error

  Scenario: Subscription to unauthorized order is rejected
    Given I am authenticated as "CUSTOMER"
    When I send the subscription:
      """
      subscription {
        orderStatusChanged(orderId: "ord-004") {
          id
          status
        }
      }
      """
    Then the subscription should fail with an authorization error
