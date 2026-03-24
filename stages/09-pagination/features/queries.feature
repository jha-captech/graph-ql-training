@stage:09
Feature: Stage 09 - Pagination Queries

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query first page of products
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 5) {
          edges {
            node {
              id
              title
            }
            cursor
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
            startCursor
            endCursor
          }
          totalCount
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should be an array
    Then the response "data.productsConnection.edges" should have 5 items
    Then each item in "data.productsConnection.edges" should have fields "node, cursor"
    Then the response "data.productsConnection.pageInfo.hasNextPage" should equal "true"
    Then the response "data.productsConnection.pageInfo.hasPreviousPage" should equal "false"
    Then the response "data.productsConnection.pageInfo.startCursor" should not be null
    Then the response "data.productsConnection.pageInfo.endCursor" should not be null
    Then the response "data.productsConnection.totalCount" should equal 50

  Scenario: Query products with forward pagination using after cursor
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 10) {
          edges {
            cursor
          }
          pageInfo {
            endCursor
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 10, after: "${data.productsConnection.pageInfo.endCursor}") {
          edges {
            node {
              id
            }
            cursor
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
          }
          totalCount
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should have 10 items
    Then the response "data.productsConnection.pageInfo.hasPreviousPage" should equal "true"
    Then the response "data.productsConnection.totalCount" should equal 50

  Scenario: Paginate through all products without gaps or duplicates
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 25) {
          edges {
            node {
              id
            }
            cursor
          }
          pageInfo {
            endCursor
            hasNextPage
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.productsConnection.edges" should have 25 items
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 25, after: "${data.productsConnection.pageInfo.endCursor}") {
          edges {
            node {
              id
            }
          }
          pageInfo {
            hasNextPage
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.productsConnection.edges" should have 25 items
    Then the response "data.productsConnection.pageInfo.hasNextPage" should equal "false"

  Scenario: Request more items than available
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 100) {
          edges {
            node {
              id
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
          }
          totalCount
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should have 50 items
    Then the response "data.productsConnection.pageInfo.hasNextPage" should equal "false"
    Then the response "data.productsConnection.totalCount" should equal 50

  Scenario: Filter products by category with pagination
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 5, filter: { categoryId: "cat-001" }) {
          edges {
            node {
              id
              title
              categories {
                id
              }
            }
          }
          pageInfo {
            hasNextPage
          }
          totalCount
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should be an array

  Scenario: Filter products by price range with pagination
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 10, filter: { minPrice: 10000, maxPrice: 20000 }) {
          edges {
            node {
              id
              title
              price
            }
          }
          pageInfo {
            hasNextPage
          }
          totalCount
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should be an array

  Scenario: Filter products by status with pagination
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 10, filter: { status: ACTIVE }) {
          edges {
            node {
              id
              title
              status
            }
          }
          totalCount
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should be an array
    Then the response "data.productsConnection.totalCount" should be greater than 0

  Scenario: Multiple filters combined with pagination
    When I send a GraphQL query:
      """
      {
        productsConnection(
          first: 5
          filter: {
            categoryId: "cat-001"
            minPrice: 5000
            status: ACTIVE
          }
        ) {
          edges {
            node {
              id
              title
              price
              status
            }
          }
          pageInfo {
            hasNextPage
          }
          totalCount
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should be an array

  Scenario: Cursors are opaque strings
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 3) {
          edges {
            cursor
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then each item in "data.productsConnection.edges" should have fields "cursor"

  Scenario: StartCursor and endCursor match first and last edge cursors
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 5) {
          edges {
            cursor
          }
          pageInfo {
            startCursor
            endCursor
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.pageInfo.startCursor" should equal "${data.productsConnection.edges[0].cursor}"
    Then the response "data.productsConnection.pageInfo.endCursor" should equal "${data.productsConnection.edges[4].cursor}"

  Scenario: Empty result set with filter returns empty edges
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 10, filter: { minPrice: 999999 }) {
          edges {
            node {
              id
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
          }
          totalCount
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should have 0 items
    Then the response "data.productsConnection.pageInfo.hasNextPage" should equal "false"
    Then the response "data.productsConnection.pageInfo.hasPreviousPage" should equal "false"
    Then the response "data.productsConnection.totalCount" should equal 0

  Scenario: Backward pagination with last and before
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 20) {
          edges {
            cursor
          }
          pageInfo {
            endCursor
          }
        }
      }
      """
    Then the response status should be 200
    When I send a GraphQL query:
      """
      {
        productsConnection(last: 10, before: "${data.productsConnection.pageInfo.endCursor}") {
          edges {
            node {
              id
            }
          }
          pageInfo {
            hasNextPage
            hasPreviousPage
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should have 10 items

  Scenario: TotalCount reflects filtered results
    When I send a GraphQL query:
      """
      {
        all: productsConnection(first: 1) {
          totalCount
        }
        activeOnly: productsConnection(first: 1, filter: { status: ACTIVE }) {
          totalCount
        }
        draftOnly: productsConnection(first: 1, filter: { status: DRAFT }) {
          totalCount
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.all.totalCount" should equal 50
    Then the response "data.activeOnly.totalCount" should be greater than 0
    Then the response "data.draftOnly.totalCount" should equal 1

  Scenario: Deprecated products field still works
    When I send a GraphQL query:
      """
      {
        products {
          id
          title
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array
    Then the response "data.products" should have at least 1 items

  Scenario: Rich nested data in paginated results
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 3) {
          edges {
            node {
              id
              title
              price
              averageRating
              categories {
                id
                name
              }
              reviews {
                rating
                author {
                  name
                }
              }
            }
            cursor
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.productsConnection.edges" should have 3 items
    Then each item in "data.productsConnection.edges" should have fields "node, cursor"
