import { World, setWorldConstructor } from "@cucumber/cucumber";

export interface GraphQLResponse {
  status: number;
  body: Record<string, unknown>;
  responseTime: number;
  contentType: string;
}

export interface SubscriptionEvent {
  data: Record<string, unknown>;
}

export class GraphQLWorld extends World {
  endpoint: string = "http://localhost:4000/graphql";
  authHeader: string | null = null;
  variables: Record<string, unknown> = {};
  lastResponse: GraphQLResponse | null = null;
  subscriptionEvents: SubscriptionEvent[] = [];
  wsConnection: import("ws").WebSocket | null = null;
  secondWsConnection: import("ws").WebSocket | null = null;

  reset(): void {
    this.authHeader = null;
    this.variables = {};
    this.lastResponse = null;
    this.subscriptionEvents = [];
    this.wsConnection = null;
    this.secondWsConnection = null;
  }
}

setWorldConstructor(GraphQLWorld);
