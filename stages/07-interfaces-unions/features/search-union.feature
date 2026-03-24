@stage:07
Feature: SearchResult Union

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Search returns products with inline fragments
    When I send a GraphQL query:
      """
      query {
        search(term: "Mechanical Keyboard") {
          __typename
          ... on Product {
            id
            title
            price
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array
    Then the response "data.search[0].__typename" should equal "Product"
    Then the response "data.search[0].title" should equal "Mechanical Keyboard"

  Scenario: Search returns users
    When I send a GraphQL query:
      """
      query {
        search(term: "Alice") {
          __typename
          ... on User {
            id
            name
            email
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array
    Then the response "data.search[0].__typename" should equal "User"
    Then the response "data.search[0].name" should equal "Alice Johnson"

  Scenario: Search returns categories
    When I send a GraphQL query:
      """
      query {
        search(term: "Electronics") {
          __typename
          ... on Category {
            id
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array
    Then the response "data.search[0].__typename" should equal "Category"
    Then the response "data.search[0].name" should equal "Electronics"

  Scenario: Search with mixed results handles all types
    When I send a GraphQL query:
      """
      query {
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
          ... on User {
            id
            name
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array

  Scenario: Search with type-specific nested relationships
    When I send a GraphQL query:
      """
      query {
        search(term: "Mechanical") {
          __typename
          ... on Product {
            id
            title
            categories {
              name
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array

  Scenario: Search returns empty array for no matches
    When I send a GraphQL query:
      """
      query {
        search(term: "xyznonexistent123") {
          __typename
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array
    Then the response "data.search" should have 0 items

  Scenario: Search with multiple inline fragments for same type
    When I send a GraphQL query:
      """
      query {
        search(term: "Keyboard") {
          ... on Product {
            id
            title
          }
          ... on Product {
            price
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array

  Scenario: __typename is always available on union members
    When I send a GraphQL query:
      """
      query {
        search(term: "test") {
          __typename
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.search" should be an array
