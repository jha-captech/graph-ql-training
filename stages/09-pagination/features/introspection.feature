@stage:09
Feature: Stage 09 - Schema Introspection for Pagination

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: ProductConnection type exists with correct structure
    When I send a GraphQL query:
      """
      {
        __type(name: "ProductConnection") {
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
                ofType {
                  name
                  kind
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.name" should equal "ProductConnection"
    Then the response "data.__type.kind" should equal "OBJECT"

  Scenario: ProductConnection has required fields
    When I send a GraphQL query:
      """
      {
        __type(name: "ProductConnection") {
          fields {
            name
            type {
              kind
              ofType { kind }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.fields" should be an array
    Then the response should contain "data.__type.fields[?(@.name=='edges')]"
    Then the response should contain "data.__type.fields[?(@.name=='pageInfo')]"
    Then the response should contain "data.__type.fields[?(@.name=='totalCount')]"

  Scenario: ProductEdge type has node and cursor
    When I send a GraphQL query:
      """
      {
        __type(name: "ProductEdge") {
          name
          kind
          fields {
            name
            type {
              name
              kind
              ofType {
                name
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.name" should equal "ProductEdge"
    Then the response should contain "data.__type.fields[?(@.name=='node')]"
    Then the response should contain "data.__type.fields[?(@.name=='cursor')]"

  Scenario: PageInfo type has correct structure
    When I send a GraphQL query:
      """
      {
        __type(name: "PageInfo") {
          name
          kind
          fields {
            name
            type {
              name
              kind
              ofType {
                name
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.name" should equal "PageInfo"
    Then the response should contain "data.__type.fields[?(@.name=='hasNextPage')]"
    Then the response should contain "data.__type.fields[?(@.name=='hasPreviousPage')]"
    Then the response should contain "data.__type.fields[?(@.name=='startCursor')]"
    Then the response should contain "data.__type.fields[?(@.name=='endCursor')]"

  Scenario: Query has productsConnection field with correct arguments
    When I send a GraphQL query:
      """
      {
        __type(name: "Query") {
          fields {
            name
            args {
              name
              type {
                name
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
    Then the response should contain "data.__type.fields[?(@.name=='productsConnection')]"

  Scenario: ProductFilterInput exists with correct fields
    When I send a GraphQL query:
      """
      {
        __type(name: "ProductFilterInput") {
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
    Then the response "data.__type.name" should equal "ProductFilterInput"
    Then the response "data.__type.kind" should equal "INPUT_OBJECT"
    Then the response should contain "data.__type.inputFields[?(@.name=='categoryId')]"
    Then the response should contain "data.__type.inputFields[?(@.name=='minPrice')]"
    Then the response should contain "data.__type.inputFields[?(@.name=='maxPrice')]"
    Then the response should contain "data.__type.inputFields[?(@.name=='status')]"

  Scenario: products field is deprecated
    When I send a GraphQL query:
      """
      {
        __type(name: "Query") {
          fields(includeDeprecated: true) {
            name
            isDeprecated
            deprecationReason
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "data.__type.fields[?(@.name=='products')]"
    Then the response "data.__type.fields[?(@.name=='products')].isDeprecated" should equal "true"
    Then the response "data.__type.fields[?(@.name=='products')].deprecationReason" should contain "Use productsConnection instead"
