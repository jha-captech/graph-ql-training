@stage:11
Feature: Stage 11 - Field-Level Authorization

  Background:
    Given the GraphQL endpoint is "http://localhost:4000/graphql"

  Scenario: User can view their own email
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        me {
          id
          email
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.me.email" should not be null

  Scenario: User cannot view another user's email
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        user(id: "user-002") {
          id
          name
          email
        }
      }
      """
    Then the response status should be 200
    Then the response "data.user.email" should be null

  Scenario: Admin can view any user's email
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        user(id: "user-001") {
          id
          name
          email
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.user.email" should not be null

  Scenario: Admin can view all emails in users query
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        users {
          id
          name
          email
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.users[0].email" should not be null
    Then the response "data.users[1].email" should not be null

  Scenario: Unauthenticated user cannot view any email
    Given I am not authenticated
    When I send a GraphQL query:
      """
      {
        user(id: "user-001") {
          id
          name
          email
        }
      }
      """
    Then the response status should be 200
    Then the response "data.user.email" should be null

  Scenario: Customer can create product (should fail)
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      mutation {
        createProduct(
          input: {
            title: "Customer Product"
            price: 9999
          }
        ) {
          __typename
          ... on CreateProductSuccess {
            product {
              id
            }
          }
          ... on ValidationError {
            message
            code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Seller can create product
    Given I am authenticated as "SELLER"
    When I send a GraphQL query:
      """
      mutation {
        createProduct(
          input: {
            title: "Seller Product"
            description: "Created by seller"
            price: 15999
            categoryIds: ["cat-001"]
          }
        ) {
          __typename
          ... on CreateProductSuccess {
            product {
              id
              title
              price
            }
          }
          ... on ValidationError {
            message
            code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.__typename" should equal "CreateProductSuccess"

  Scenario: Admin can create product
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      mutation {
        createProduct(
          input: {
            title: "Admin Product"
            price: 12999
          }
        ) {
          __typename
          ... on CreateProductSuccess {
            product {
              id
              title
            }
          }
          ... on ValidationError {
            message
            code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createProduct.__typename" should equal "CreateProductSuccess"

  Scenario: Unauthenticated user cannot create product
    Given I am not authenticated
    When I send a GraphQL query:
      """
      mutation {
        createProduct(
          input: {
            title: "Unauth Product"
            price: 9999
          }
        ) {
          __typename
          ... on CreateProductSuccess {
            product {
              id
            }
          }
          ... on ValidationError {
            message
            code
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Customer can update product (should fail)
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      mutation {
        updateProduct(
          id: "prod-001"
          input: {
            title: "Customer Update"
          }
        ) {
          product {
            id
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Seller can update product
    Given I am authenticated as "SELLER"
    When I send a GraphQL query:
      """
      mutation {
        updateProduct(
          id: "prod-001"
          input: {
            title: "Seller Updated Title"
            price: 17999
          }
        ) {
          product {
            id
            title
            price
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.updateProduct.product.title" should equal "Seller Updated Title"

  Scenario: Admin can update any product
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      mutation {
        updateProduct(
          id: "prod-001"
          input: {
            title: "Admin Updated Title"
          }
        ) {
          product {
            id
            title
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"

  Scenario: Customer can create review
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      mutation {
        createReview(
          input: {
            productId: "prod-003"
            rating: 5
            body: "Great product!"
          }
        ) {
          review {
            id
            rating
            body
            author {
              id
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should not contain "errors"
    Then the response "data.createReview.review.rating" should equal 5

  Scenario: Unauthenticated user cannot create review
    Given I am not authenticated
    When I send a GraphQL query:
      """
      mutation {
        createReview(
          input: {
            productId: "prod-001"
            rating: 5
            body: "Unauth review"
          }
        ) {
          review {
            id
          }
        }
      }
      """
    Then the response status should be 200
    Then the response should contain "errors"

  Scenario: Email field hidden in nested queries
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          title
          reviews {
            rating
            author {
              id
              name
              email
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.product.reviews[0].author.email" should be null

  Scenario: Admin sees emails in nested queries
    Given I am authenticated as "ADMIN"
    When I send a GraphQL query:
      """
      {
        product(id: "prod-001") {
          title
          reviews {
            rating
            author {
              id
              name
              email
            }
          }
        }
      }
      """
    Then the response status should be 200
    Then the response "data.product.reviews[0].author.email" should not be null

  Scenario: User sees own email in search results
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
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

  Scenario: Multiple users queried with field-level auth
    Given I am authenticated as "CUSTOMER"
    When I send a GraphQL query:
      """
      {
        me {
          id
          email
        }
        user1: user(id: "user-002") {
          id
          email
        }
        user2: user(id: "user-003") {
          id
          email
        }
      }
      """
    Then the response status should be 200
    Then the response "data.me.email" should not be null
    Then the response "data.user1.email" should be null
    Then the response "data.user2.email" should be null

  Scenario: Role field is publicly visible
    Given I am not authenticated
    When I send a GraphQL query:
      """
      {
        user(id: "user-001") {
          id
          name
          role
        }
      }
      """
    Then the response status should be 200
    Then the response "data.user.role" should not be null
