@stage:01
Feature: Hello Query

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: Query hello field
    When I send a GraphQL query:
      """
      {
        hello
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.hello" should equal "Hello, GraphQL!"

  Scenario: Query hello field with operation name
    When I send a GraphQL query:
      """
      query HelloWorld {
        hello
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.hello" should equal "Hello, GraphQL!"

  Scenario: Query non-existent field returns error
    When I send a GraphQL query:
      """
      {
        goodbye
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"
    Then the response "errors[0].message" should contain "Cannot query field"

  Scenario: Response has correct content type
    When I send a GraphQL query:
      """
      {
        hello
      }
      """
    Then the response status should be 200
    Then the response content type should be "application/json"

  Scenario: Query with __typename
    When I send a GraphQL query:
      """
      {
        hello
        __typename
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.__typename" should equal "Query"
    Then the response should contain "data.hello"
