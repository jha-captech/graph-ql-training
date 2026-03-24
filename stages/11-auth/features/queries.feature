@stage:11
Feature: Stage 11 - Authentication Queries

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query me as authenticated customer
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        me {
          id
          name
          email
          role
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.me" should not be null
    Then the response "data.me.id" should equal "user-001"
    Then the response "data.me.role" should equal "CUSTOMER"
    Then the response "data.me.email" should not be null

  Scenario: Query me as authenticated seller
    Given I am authenticated as "SELLER"
    When I send a GraphQL query:
      """
      {
        me {
          id
          name
          email
          role
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.me" should not be null
    Then the response "data.me.id" should equal "user-003"
    Then the response "data.me.role" should equal "SELLER"

  Scenario: Query me as authenticated admin
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        me {
          id
          name
          email
          role
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.me" should not be null
    Then the response "data.me.id" should equal "user-005"
    Then the response "data.me.role" should equal "ADMIN"

  Scenario: Query me without authentication
    Given I am not authenticated
    When I send a GraphQL query:
      """
      {
        me {
          id
          name
          email
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.me" should be null

  Scenario: Query users as admin
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
    Then the response "data.users" should have at least 5 items

  Scenario: Query users as customer (should fail)
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        users {
          id
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "data.users" should be null

  Scenario: Query users as seller (should fail)
    Given I am authenticated as "SELLER"
    When I send a GraphQL query:
      """
      {
        users {
          id
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "data.users" should be null

  Scenario: Query users without authentication (should fail)
    Given I am not authenticated
    When I send a GraphQL query:
      """
      {
        users {
          id
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Products query is public (no auth required)
    Given I am not authenticated
    When I send a GraphQL query:
      """
      {
        products {
          id
          title
          price
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.products" should be an array

  Scenario: Product details query is public
    Given I am not authenticated
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          id
          title
          description
          price
          averageRating
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.product" should not be null

  Scenario: Pagination is public
    Given I am not authenticated
    When I send a GraphQL query:
      """
      {
        productsConnection(first: 5) {
          edges {
            node {
              id
              title
            }
          }
          totalCount
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"

  Scenario: Categories query is public
    Given I am not authenticated
    When I send a GraphQL query:
      """
      {
        categories {
          id
          name
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"

  Scenario: Search is public
    Given I am not authenticated
    When I send a GraphQL query:
      """
      {
        search(term: "test") {
          __typename
          ... on Product {
            id
            title
          }
          ... on Category {
            id
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"

  Scenario: User roles are visible
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        users {
          id
          name
          role
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.users[0].role" should not be null

  Scenario: Complex query with mixed auth levels
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        me {
          id
          name
        }
        products {
          id
          title
        }
        product(id: "prod-001") {
          title
        }
      }
      """
    Then the response status should be 200
    Then the response "data.me" should not be null
    Then the response "data.products" should be an array
    Then the response "data.product" should not be null
