@stage:16
Feature: GraphQL Security Measures

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  # ============================================================================
  # DEPTH LIMITING
  # ============================================================================

  Scenario: Safe query with reasonable depth passes (depth: 4)
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          pricing {
            amount
            currency
          }
          seller {
            name
            email
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product.id" should equal "prod-001"

  Scenario: Medium depth query is accepted (depth: 5)
    When I send a GraphQL query:
      """
      {
        order(id: "order-001") {
          id
          buyer {
            name
            reviews {
              rating
              product {
                title
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.order.id" should equal "order-001"

  Scenario: Deeply nested query exceeds depth limit (depth: 11)
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          seller {
            reviews {
              product {
                seller {
                  reviews {
                    product {
                      seller {
                        reviews {
                          product {
                            seller {
                              name
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 400
    Then the response should contain "errors"
    Then the error message should mention "depth limit"

  Scenario: Circular relationship query is blocked by depth limit
    When I send a GraphQL query:
      """
      {
        user(id: "user-001") {
          reviews {
            product {
              reviews {
                author {
                  reviews {
                    product {
                      reviews {
                        author {
                          reviews {
                            product {
                              title
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 400
    Then the response should contain "errors"

  # ============================================================================
  # QUERY COMPLEXITY
  # ============================================================================

  Scenario: Simple query with low complexity passes
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          pricing {
            amount
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"

  Scenario: Wide query with reasonable complexity passes
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 10) {
          edges {
            node {
              id
              title
              pricing {
                amount
                currency
              }
              categories {
                name
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should have at least 1 items

  Scenario: High complexity query with large lists is rejected
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 100) {
          edges {
            node {
              id
              title
              description
              pricing {
                amount
                currency
                compareAtAmount
              }
              categories {
                id
                name
                products {
                  id
                  title
                  pricing {
                    amount
                  }
                }
              }
              reviews {
                id
                rating
                body
                author {
                  id
                  name
                  email
                  reviews {
                    rating
                    product {
                      title
                    }
                  }
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 400
    Then the response should contain "errors"
    Then the error message should mention "complexity"

  Scenario: Query requesting too many nested fields is rejected
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 50) {
          edges {
            node {
              id
              title
              reviews {
                author {
                  reviews {
                    product {
                      reviews {
                        author {
                          name
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 400
    Then the response should contain "errors"

  # ============================================================================
  # PAGINATION LIMITS
  # ============================================================================

  Scenario: Request for reasonable page size is accepted
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 20) {
          edges {
            node {
              id
              title
            }
          }
          pageInfo {
            hasNextPage
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"

  Scenario: Request for excessive page size is rejected or capped
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 1000) {
          edges {
            node {
              id
              title
            }
          }
        }
      }
      """
    Then the response status should be 400
    Then the response should contain "errors"
    Then the error message should mention "limit" or "maximum"

  # ============================================================================
  # BATCH QUERIES
  # ============================================================================

  Scenario: Small batch query is accepted
    When I send a GraphQL query:
      """
      {
        p1: product(id: "prod-001") { id title }
        p2: product(id: "prod-002") { id title }
        p3: product(id: "prod-003") { id title }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.p1.id" should equal "prod-001"
    Then the response "data.p2.id" should equal "prod-002"

  Scenario: Large batch query with complexity is monitored
    When I send a GraphQL query:
      """
      {
        p1: product(id: "prod-001") { ...Details }
        p2: product(id: "prod-002") { ...Details }
        p3: product(id: "prod-003") { ...Details }
        p4: product(id: "prod-004") { ...Details }
        p5: product(id: "prod-005") { ...Details }
      }

      fragment Details on Product {
        id
        title
        pricing { amount currency }
        categories { name }
        reviews { rating body }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"

  # ============================================================================
  # TIMEOUT PROTECTION
  # ============================================================================

  Scenario: Normal query completes within timeout
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 10) {
          edges {
            node {
              id
              title
              reviews {
                rating
              }
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response time should be less than 5000 milliseconds

  Scenario: Query with moderate data completes successfully
    When I send a GraphQL query:
      """
      {
        orders {
          id
          buyer {
            name
          }
          items {
            product {
              title
            }
            quantity
          }
          total
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response time should be less than 3000 milliseconds

  # ============================================================================
  # COMBINING SECURITY WITH AUTH
  # ============================================================================

  Scenario: Authenticated user can run complex queries within limits
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        me {
          id
          name
          reviews {
            id
            rating
            product {
              title
              pricing {
                amount
              }
            }
          }
        }
        orders {
          id
          status
          total
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.me" should not be null

  Scenario: Admin query within complexity limits succeeds
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        users {
          id
          name
          email
          role
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.users" should be an array

  Scenario: Admin query exceeding complexity fails
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        users {
          id
          name
          email
          role
          reviews {
            product {
              title
              reviews {
                author {
                  reviews {
                    product {
                      title
                    }
                  }
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 400
    Then the response should contain "errors"

  # ============================================================================
  # INTROSPECTION SECURITY
  # ============================================================================

  Scenario: Introspection query is allowed in development
    When I send a GraphQL query:
      """
      {
        __schema {
          types {
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__schema.types" should be an array

  Scenario: Introspection respects depth limits
    When I send a GraphQL query:
      """
      {
        __schema {
          types {
            name
            fields {
              name
              type {
                name
                ofType {
                  name
                  ofType {
                    name
                    ofType {
                      name
                      ofType {
                        name
                        ofType {
                          name
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 200

  # ============================================================================
  # ERROR HANDLING
  # ============================================================================

  Scenario: Security error messages don't leak implementation details
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          seller {
            reviews {
              product {
                seller {
                  reviews {
                    product {
                      seller {
                        reviews {
                          product {
                            seller {
                              name
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 400
    Then the response should contain "errors"
    Then the error message should not contain "SQL"
    Then the error message should not contain "database"
    Then the error message should not contain "stack trace"

  Scenario: Complexity rejection provides helpful message
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 200) {
          edges {
            node {
              reviews {
                author {
                  reviews {
                    product {
                      title
                    }
                  }
                }
              }
            }
          }
        }
      }
      """
    Then the response status should be 400
    Then the response should contain "errors"
    Then the error message should be informative
