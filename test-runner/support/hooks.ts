import { After, BeforeAll } from '@cucumber/cucumber';
import { GraphQLWorld } from '../steps/world';

BeforeAll(function () {
  // Verify the GraphQL endpoint is configured
  const endpoint = process.env.GRAPHQL_ENDPOINT || 'http://localhost:4000/graphql';
  console.log(`Test runner targeting: ${endpoint}`);
});

After(async function (this: GraphQLWorld) {
  // Close any open WebSocket connections
  if (this.wsConnection) {
    this.wsConnection.close();
    this.wsConnection = null;
  }
  if (this.secondWsConnection) {
    this.secondWsConnection.close();
    this.secondWsConnection = null;
  }

  // Reset state for next scenario
  this.reset();
});
