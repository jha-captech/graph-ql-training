@stage:02
Feature: Schema Introspection for Types and Enums

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Product type exists with correct fields
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
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
    Then the response "data.__type.name" should equal "Product"
    Then the response "data.__type.kind" should equal "OBJECT"
    Then the response "data.__type.fields" should be an array
    Then the response "data.__type.fields" should have 6 items

  Scenario: Product id field is non-null ID
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
          fields {
            name
            type {
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
    Then the response "data.__type.fields[?(@.name=='id')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='id')].type.ofType.name" should equal "ID"

  Scenario: Product title is non-null String
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
          fields {
            name
            type {
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
    Then the response "data.__type.fields[?(@.name=='title')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='title')].type.ofType.name" should equal "String"

  Scenario: Product description is nullable String
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
          fields {
            name
            type {
              kind
              name
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.fields[?(@.name=='description')].type.kind" should equal "SCALAR"
    Then the response "data.__type.fields[?(@.name=='description')].type.name" should equal "String"

  Scenario: Product price is non-null Float
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
          fields {
            name
            type {
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
    Then the response "data.__type.fields[?(@.name=='price')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='price')].type.ofType.name" should equal "Float"

  Scenario: Product inStock is non-null Boolean
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
          fields {
            name
            type {
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
    Then the response "data.__type.fields[?(@.name=='inStock')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='inStock')].type.ofType.name" should equal "Boolean"

  Scenario: Product status is non-null ProductStatus enum
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
          fields {
            name
            type {
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
    Then the response "data.__type.fields[?(@.name=='status')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='status')].type.ofType.name" should equal "ProductStatus"
    Then the response "data.__type.fields[?(@.name=='status')].type.ofType.kind" should equal "ENUM"

  Scenario: ProductStatus enum has correct values
    When I send a GraphQL query:
      """
      {
        __type(name: "ProductStatus") {
          name
          kind
          enumValues {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.kind" should equal "ENUM"
    Then the response "data.__type.enumValues" should be an array
    Then the response "data.__type.enumValues" should have 3 items

  Scenario: Query type has product and products fields
    When I send a GraphQL query:
      """
      {
        __type(name: "Query") {
          fields {
            name
            type {
              kind
              name
              ofType {
                kind
                name
                ofType {
                  name
                }
              }
            }
            args {
              name
              type {
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
    Then the response "data.__type.fields[?(@.name=='product')]" should exist
    Then the response "data.__type.fields[?(@.name=='products')]" should exist

  Scenario: Query.product field takes ID argument
    When I send a GraphQL query:
      """
      {
        __type(name: "Query") {
          fields {
            name
            args {
              name
              type {
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
    Then the response "data.__type.fields[?(@.name=='product')].args" should have 1 items
    Then the response "data.__type.fields[?(@.name=='product')].args[0].name" should equal "id"
    Then the response "data.__type.fields[?(@.name=='product')].args[0].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='product')].args[0].type.ofType.name" should equal "ID"

  Scenario: Query.products returns non-null list of non-null Products
    When I send a GraphQL query:
      """
      {
        __type(name: "Query") {
          fields {
            name
            type {
              kind
              ofType {
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
      }
      """
    Then the response status should be 200
    Then the response "data.__type.fields[?(@.name=='products')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='products')].type.ofType.kind" should equal "LIST"
    Then the response "data.__type.fields[?(@.name=='products')].type.ofType.ofType.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='products')].type.ofType.ofType.ofType.name" should equal "Product"
