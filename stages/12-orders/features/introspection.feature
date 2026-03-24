@stage:12
Feature: Stage 12 - Schema Introspection for Orders

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Order type exists with correct fields
    When I send a GraphQL query:
      """
      {
        __type(name: "Order") {
          name
          kind
          fields {
            name
            type {
              name
              kind
              ofType {
                name
                kind
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.name" should equal "Order"
    Then the response "data.__type.kind" should equal "OBJECT"
    Then the response should contain "data.__type.fields[?(@.name=='id')]"
    Then the response should contain "data.__type.fields[?(@.name=='buyer')]"
    Then the response should contain "data.__type.fields[?(@.name=='items')]"
    Then the response should contain "data.__type.fields[?(@.name=='status')]"
    Then the response should contain "data.__type.fields[?(@.name=='total')]"

  Scenario: LineItem type exists with correct fields
    When I send a GraphQL query:
      """
      {
        __type(name: "LineItem") {
          name
          kind
          fields {
            name
            type {
              name
              kind
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.name" should equal "LineItem"
    Then the response "data.__type.kind" should equal "OBJECT"
    Then the response should contain "data.__type.fields[?(@.name=='id')]"
    Then the response should contain "data.__type.fields[?(@.name=='product')]"
    Then the response should contain "data.__type.fields[?(@.name=='quantity')]"
    Then the response should contain "data.__type.fields[?(@.name=='unitPrice')]"

  Scenario: OrderStatus enum exists with correct values
    When I send a GraphQL query:
      """
      {
        __type(name: "OrderStatus") {
          name
          kind
          enumValues {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.name" should equal "OrderStatus"
    Then the response "data.__type.kind" should equal "ENUM"
    Then the response "data.__type.enumValues" should be an array
    Then the response "data.__type.enumValues" should have 5 items
    Then the response should contain "data.__type.enumValues[?(@.name=='PENDING')]"
    Then the response should contain "data.__type.enumValues[?(@.name=='CONFIRMED')]"
    Then the response should contain "data.__type.enumValues[?(@.name=='SHIPPED')]"
    Then the response should contain "data.__type.enumValues[?(@.name=='DELIVERED')]"
    Then the response should contain "data.__type.enumValues[?(@.name=='CANCELLED')]"

  Scenario: PlaceOrderInput input type exists
    When I send a GraphQL query:
      """
      {
        __type(name: "PlaceOrderInput") {
          name
          kind
          inputFields {
            name
            type {
              name
              kind
              ofType {
                name
                kind
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.name" should equal "PlaceOrderInput"
    Then the response "data.__type.kind" should equal "INPUT_OBJECT"
    Then the response should contain "data.__type.inputFields[?(@.name=='items')]"

  Scenario: OrderItemInput input type exists
    When I send a GraphQL query:
      """
      {
        __type(name: "OrderItemInput") {
          name
          kind
          inputFields {
            name
            type {
              name
              kind
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.name" should equal "OrderItemInput"
    Then the response "data.__type.kind" should equal "INPUT_OBJECT"
    Then the response should contain "data.__type.inputFields[?(@.name=='productId')]"
    Then the response should contain "data.__type.inputFields[?(@.name=='quantity')]"

  Scenario: PlaceOrderResult union exists
    When I send a GraphQL query:
      """
      {
        __type(name: "PlaceOrderResult") {
          name
          kind
          possibleTypes {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.name" should equal "PlaceOrderResult"
    Then the response "data.__type.kind" should equal "UNION"
    Then the response "data.__type.possibleTypes" should be an array
    Then the response "data.__type.possibleTypes" should have 2 items
    Then the response should contain "data.__type.possibleTypes[?(@.name=='PlaceOrderSuccess')]"
    Then the response should contain "data.__type.possibleTypes[?(@.name=='ValidationError')]"

  Scenario: PlaceOrderSuccess type exists
    When I send a GraphQL query:
      """
      {
        __type(name: "PlaceOrderSuccess") {
          name
          kind
          fields {
            name
            type {
              name
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.name" should equal "PlaceOrderSuccess"
    Then the response "data.__type.kind" should equal "OBJECT"
    Then the response should contain "data.__type.fields[?(@.name=='order')]"

  Scenario: Query type has order and orders fields
    When I send a GraphQL query:
      """
      {
        __type(name: "Query") {
          fields {
            name
            type {
              name
              kind
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "data.__type.fields[?(@.name=='order')]"
    Then the response should contain "data.__type.fields[?(@.name=='orders')]"

  Scenario: Mutation type has placeOrder and updateOrderStatus
    When I send a GraphQL query:
      """
      {
        __type(name: "Mutation") {
          fields {
            name
            type {
              name
              kind
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "data.__type.fields[?(@.name=='placeOrder')]"
    Then the response should contain "data.__type.fields[?(@.name=='updateOrderStatus')]"
    Then the response "data.__type.fields[?(@.name=='placeOrder')].type.name" should equal "PlaceOrderResult"
    Then the response "data.__type.fields[?(@.name=='placeOrder')].type.kind" should equal "UNION"

  Scenario: Product type has seller field
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
          fields {
            name
            type {
              name
              kind
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "data.__type.fields[?(@.name=='seller')]"
    Then the response "data.__type.fields[?(@.name=='seller')].type.name" should equal "User"

  Scenario: Order implements Node and Timestamped interfaces
    When I send a GraphQL query:
      """
      {
        __type(name: "Order") {
          interfaces {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.interfaces" should be an array
    Then the response should contain "data.__type.interfaces[?(@.name=='Node')]"
    Then the response should contain "data.__type.interfaces[?(@.name=='Timestamped')]"
