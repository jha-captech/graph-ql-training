@stage:03
Feature: Schema Introspection for Relationships

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Category type exists with correct fields
    When I send a GraphQL query:
      """
      {
        __type(name: "Category") {
          name
          kind
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
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.name" should equal "Category"
    Then the response "data.__type.kind" should equal "OBJECT"
    Then the response "data.__type.fields" should have 3 items

  Scenario: Category id field is non-null ID
    When I send a GraphQL query:
      """
      {
        __type(name: "Category") {
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
    Then the response "data.__type.fields[?(@.name=='id')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='id')].type.ofType.name" should equal "ID"

  Scenario: Category name field is non-null String
    When I send a GraphQL query:
      """
      {
        __type(name: "Category") {
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
    Then the response "data.__type.fields[?(@.name=='name')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='name')].type.ofType.name" should equal "String"

  Scenario: Category products field is non-null list of non-null Products
    When I send a GraphQL query:
      """
      {
        __type(name: "Category") {
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
    Then the response "data.__type.fields[?(@.name=='products')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='products')].type.ofType.kind" should equal "LIST"
    Then the response "data.__type.fields[?(@.name=='products')].type.ofType.ofType.name" should equal "Product"

  Scenario: Product categories field is non-null list of non-null Categories
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
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
    Then the response "data.__type.fields[?(@.name=='categories')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='categories')].type.ofType.kind" should equal "LIST"
    Then the response "data.__type.fields[?(@.name=='categories')].type.ofType.ofType.name" should equal "Category"

  Scenario: Query type has category and categories fields
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
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.fields[?(@.name=='category')]" should exist
    Then the response "data.__type.fields[?(@.name=='categories')]" should exist
    Then the response "data.__type.fields[?(@.name=='product')]" should exist
    Then the response "data.__type.fields[?(@.name=='products')]" should exist

  Scenario: Query.category field takes ID argument
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
    Then the response "data.__type.fields[?(@.name=='category')].args" should have 1 items
    Then the response "data.__type.fields[?(@.name=='category')].args[0].name" should equal "id"
    Then the response "data.__type.fields[?(@.name=='category')].args[0].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='category')].args[0].type.ofType.name" should equal "ID"

  Scenario: Query.categories returns non-null list of non-null Categories
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
                  name
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.fields[?(@.name=='categories')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='categories')].type.ofType.kind" should equal "LIST"
    Then the response "data.__type.fields[?(@.name=='categories')].type.ofType.ofType.name" should equal "Category"

  Scenario: Product type has 7 fields (including categories)
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
          fields {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.__type.fields" should have 7 items
