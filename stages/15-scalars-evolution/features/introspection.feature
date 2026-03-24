@stage:15
Feature: Stage 15 Schema Introspection

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Custom scalar types exist
    When I send a GraphQL query:
      """
      {
        __schema {
          types {
            name
            kind
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the schema should include these scalar types:
      | DateTime      |
      | EmailAddress  |
      | Money         |

  Scenario: DateTime scalar is defined
    When I send a GraphQL query:
      """
      {
        __type(name: "DateTime") {
          name
          kind
          description
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.name" should equal "DateTime"
    Then the response "data.__type.kind" should equal "SCALAR"

  Scenario: EmailAddress scalar is defined
    When I send a GraphQL query:
      """
      {
        __type(name: "EmailAddress") {
          name
          kind
          description
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.name" should equal "EmailAddress"
    Then the response "data.__type.kind" should equal "SCALAR"

  Scenario: Money scalar is defined
    When I send a GraphQL query:
      """
      {
        __type(name: "Money") {
          name
          kind
          description
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__type.name" should equal "Money"
    Then the response "data.__type.kind" should equal "SCALAR"

  Scenario: Pricing type exists with correct fields
    When I send a GraphQL query:
      """
      {
        __type(name: "Pricing") {
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
    Then the response "data.__type.name" should equal "Pricing"
    Then the response "data.__type.kind" should equal "OBJECT"
    Then the type "Pricing" should have field "amount" of type "Money!"
    Then the type "Pricing" should have field "currency" of type "String!"
    Then the type "Pricing" should have field "compareAtAmount" of type "Money"

  Scenario: Product.price is deprecated
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
          fields(includeDeprecated: true) {
            name
            isDeprecated
            deprecationReason
            type {
              name
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the field "Product.price" should be deprecated
    Then the field "Product.price" should have deprecation reason containing "pricing"

  Scenario: Product.pricing field exists
    When I send a GraphQL query:
      """
      {
        __type(name: "Product") {
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
    Then the response should not contain "errors"
    Then the type "Product" should have field "pricing" of type "Pricing!"

  Scenario: User.email is EmailAddress scalar
    When I send a GraphQL query:
      """
      {
        __type(name: "User") {
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
    Then the response should not contain "errors"
    Then the type "User" should have field "email" of type "EmailAddress!"

  Scenario: Timestamped interface uses DateTime scalar
    When I send a GraphQL query:
      """
      {
        __type(name: "Timestamped") {
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
    Then the response should not contain "errors"
    Then the response "data.__type.kind" should equal "INTERFACE"
    Then the type "Timestamped" should have field "createdAt" of type "DateTime!"
    Then the type "Timestamped" should have field "updatedAt" of type "DateTime!"

  Scenario: Custom directives are defined
    When I send a GraphQL query:
      """
      {
        __schema {
          directives {
            name
            locations
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
    Then the response should not contain "errors"
    Then the schema should have directive "auth"
    Then the schema should have directive "cacheControl"

  Scenario: auth directive has correct signature
    When I send a GraphQL query:
      """
      {
        __schema {
          directives {
            name
            locations
            args {
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
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the directive "auth" should have location "FIELD_DEFINITION"
    Then the directive "auth" should have argument "requires" of type "Role!"

  Scenario: cacheControl directive has correct signature
    When I send a GraphQL query:
      """
      {
        __schema {
          directives {
            name
            locations
            args {
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
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the directive "cacheControl" should have location "FIELD_DEFINITION"
    Then the directive "cacheControl" should have argument "maxAge" of type "Int!"

  Scenario: Query.users has auth directive
    When I send a GraphQL query:
      """
      {
        __type(name: "Query") {
          fields {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the field "Query.users" should have directive "auth"

  Scenario: Product.shippingEstimate has cacheControl directive
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
    Then the response should not contain "errors"
    Then the field "Product.shippingEstimate" should have directive "cacheControl"
