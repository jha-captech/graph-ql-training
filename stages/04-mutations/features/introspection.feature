@stage:04
Feature: Schema Introspection for Mutations and Input Types

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Mutation type exists
    When I send a GraphQL query:
      """
      {
        __schema {
          mutationType {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__schema.mutationType.name" should equal "Mutation"

  Scenario: Mutation type has createProduct and updateProduct fields
    When I send a GraphQL query:
      """
      {
        __type(name: "Mutation") {
          fields {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.fields" should be an array
    Then the response "data.__type.fields" should have 2 items
    Then the response "data.__type.fields[?(@.name=='createProduct')]" should exist
    Then the response "data.__type.fields[?(@.name=='updateProduct')]" should exist

  Scenario: CreateProductInput is an input type
    When I send a GraphQL query:
      """
      {
        __type(name: "CreateProductInput") {
          name
          kind
          inputFields {
            name
            type {
              kind
              name
              ofType {
                name
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.kind" should equal "INPUT_OBJECT"
    Then the response "data.__type.inputFields" should be an array
    Then the response "data.__type.inputFields" should have 4 items

  Scenario: CreateProductInput has required title field
    When I send a GraphQL query:
      """
      {
        __type(name: "CreateProductInput") {
          inputFields {
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
    Then the response "data.__type.inputFields[?(@.name=='title')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.inputFields[?(@.name=='title')].type.ofType.name" should equal "String"

  Scenario: CreateProductInput has required price field
    When I send a GraphQL query:
      """
      {
        __type(name: "CreateProductInput") {
          inputFields {
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
    Then the response "data.__type.inputFields[?(@.name=='price')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.inputFields[?(@.name=='price')].type.ofType.name" should equal "Float"

  Scenario: CreateProductInput has optional description field
    When I send a GraphQL query:
      """
      {
        __type(name: "CreateProductInput") {
          inputFields {
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
    Then the response "data.__type.inputFields[?(@.name=='description')].type.kind" should equal "SCALAR"
    Then the response "data.__type.inputFields[?(@.name=='description')].type.name" should equal "String"

  Scenario: CreateProductInput has optional categoryIds list
    When I send a GraphQL query:
      """
      {
        __type(name: "CreateProductInput") {
          inputFields {
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
    Then the response "data.__type.inputFields[?(@.name=='categoryIds')].type.kind" should equal "LIST"

  Scenario: UpdateProductInput is an input type with optional fields
    When I send a GraphQL query:
      """
      {
        __type(name: "UpdateProductInput") {
          name
          kind
          inputFields {
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
    Then the response should not contain "errors"
    Then the response "data.__type.kind" should equal "INPUT_OBJECT"
    Then the response "data.__type.inputFields" should have 4 items

  Scenario: UpdateProductInput fields are all optional
    When I send a GraphQL query:
      """
      {
        __type(name: "UpdateProductInput") {
          inputFields {
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
    Then each item in "data.__type.inputFields" should have "type.kind" not equal to "NON_NULL"

  Scenario: CreateProductPayload has product field
    When I send a GraphQL query:
      """
      {
        __type(name: "CreateProductPayload") {
          name
          kind
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
    Then the response should not contain "errors"
    Then the response "data.__type.kind" should equal "OBJECT"
    Then the response "data.__type.fields" should have 1 items
    Then the response "data.__type.fields[0].name" should equal "product"
    Then the response "data.__type.fields[0].type.name" should equal "Product"

  Scenario: UpdateProductPayload has product field
    When I send a GraphQL query:
      """
      {
        __type(name: "UpdateProductPayload") {
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
    Then the response "data.__type.fields" should have 1 items
    Then the response "data.__type.fields[0].name" should equal "product"
    Then the response "data.__type.fields[0].type.name" should equal "Product"

  Scenario: createProduct mutation signature is correct
    When I send a GraphQL query:
      """
      {
        __type(name: "Mutation") {
          fields {
            name
            args {
              name
              type {
                kind
                ofType {
                  name
                  kind
                }
              }
            }
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
    Then the response "data.__type.fields[?(@.name=='createProduct')].args" should have 1 items
    Then the response "data.__type.fields[?(@.name=='createProduct')].args[0].name" should equal "input"
    Then the response "data.__type.fields[?(@.name=='createProduct')].args[0].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='createProduct')].args[0].type.ofType.name" should equal "CreateProductInput"
    Then the response "data.__type.fields[?(@.name=='createProduct')].args[0].type.ofType.kind" should equal "INPUT_OBJECT"
    Then the response "data.__type.fields[?(@.name=='createProduct')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='createProduct')].type.ofType.name" should equal "CreateProductPayload"

  Scenario: updateProduct mutation signature is correct
    When I send a GraphQL query:
      """
      {
        __type(name: "Mutation") {
          fields {
            name
            args {
              name
              type {
                kind
                ofType {
                  name
                  kind
                }
              }
            }
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
    Then the response "data.__type.fields[?(@.name=='updateProduct')].args" should have 2 items
    Then the response "data.__type.fields[?(@.name=='updateProduct')].args[?(@.name=='id')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='updateProduct')].args[?(@.name=='id')].type.ofType.name" should equal "ID"
    Then the response "data.__type.fields[?(@.name=='updateProduct')].args[?(@.name=='input')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='updateProduct')].args[?(@.name=='input')].type.ofType.name" should equal "UpdateProductInput"
    Then the response "data.__type.fields[?(@.name=='updateProduct')].type.kind" should equal "NON_NULL"
    Then the response "data.__type.fields[?(@.name=='updateProduct')].type.ofType.name" should equal "UpdateProductPayload"
