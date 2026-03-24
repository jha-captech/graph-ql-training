@stage:07
Feature: Introspection of Interfaces and Unions

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Node interface exists in schema
    When I send a GraphQL query:
      """
      query {
        __type(name: "Node") {
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
    Then the response should not contain "errors"
    Then the response "data.__type.name" should equal "Node"
    Then the response "data.__type.kind" should equal "INTERFACE"
    Then the response "data.__type.fields" should be an array
    Then the response "data.__type.fields" should have 1 items

  Scenario: Node interface lists all implementing types
    When I send a GraphQL query:
      """
      query {
        __type(name: "Node") {
          name
          possibleTypes {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.possibleTypes" should be an array
    Then the response "data.__type.possibleTypes" should have at least 4 items

  Scenario: Timestamped interface exists in schema
    When I send a GraphQL query:
      """
      query {
        __type(name: "Timestamped") {
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
    Then the response should not contain "errors"
    Then the response "data.__type.name" should equal "Timestamped"
    Then the response "data.__type.kind" should equal "INTERFACE"
    Then the response "data.__type.fields" should be an array
    Then the response "data.__type.fields" should have 2 items

  Scenario: Timestamped interface has createdAt and updatedAt fields
    When I send a GraphQL query:
      """
      query {
        __type(name: "Timestamped") {
          fields {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.fields" should be an array

  Scenario: SearchResult union exists in schema
    When I send a GraphQL query:
      """
      query {
        __type(name: "SearchResult") {
          name
          kind
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.name" should equal "SearchResult"
    Then the response "data.__type.kind" should equal "UNION"

  Scenario: SearchResult union lists all possible types
    When I send a GraphQL query:
      """
      query {
        __type(name: "SearchResult") {
          name
          possibleTypes {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.possibleTypes" should be an array
    Then the response "data.__type.possibleTypes" should have 3 items

  Scenario: Product implements Node interface
    When I send a GraphQL query:
      """
      query {
        __type(name: "Product") {
          name
          interfaces {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.interfaces" should be an array
    Then the response "data.__type.interfaces" should have at least 2 items

  Scenario: Product implements Timestamped interface
    When I send a GraphQL query:
      """
      query {
        __type(name: "Product") {
          interfaces {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.interfaces" should be an array

  Scenario: Category implements Node interface only
    When I send a GraphQL query:
      """
      query {
        __type(name: "Category") {
          interfaces {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.interfaces" should be an array
    Then the response "data.__type.interfaces" should have 1 items

  Scenario: User implements both Node and Timestamped
    When I send a GraphQL query:
      """
      query {
        __type(name: "User") {
          interfaces {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.interfaces" should be an array
    Then the response "data.__type.interfaces" should have 2 items

  Scenario: Review implements both Node and Timestamped
    When I send a GraphQL query:
      """
      query {
        __type(name: "Review") {
          interfaces {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.interfaces" should be an array
    Then the response "data.__type.interfaces" should have 2 items

  Scenario: Query root has node field
    When I send a GraphQL query:
      """
      query {
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
    Then the response should not contain "errors"
    Then the response "data.__type.fields" should be an array

  Scenario: Query root has search field
    When I send a GraphQL query:
      """
      query {
        __type(name: "Query") {
          fields {
            name
            type {
              kind
              ofType {
                kind
                ofType {
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
    Then the response "data.__type.fields" should be an array

  Scenario: node query returns Node interface type
    When I send a GraphQL query:
      """
      query {
        __type(name: "Query") {
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
    Then the response should not contain "errors"
    Then the response "data.__type.fields" should be an array
