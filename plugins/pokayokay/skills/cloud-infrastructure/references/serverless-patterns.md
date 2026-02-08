# Serverless Patterns

Lambda, API Gateway, Step Functions, and event-driven architectures.

## Lambda Best Practices

### Function Structure

```typescript
// handler.ts — clean Lambda handler pattern
import { APIGatewayProxyEvent, APIGatewayProxyResult } from 'aws-lambda';

// Initialize outside handler (reused across invocations)
const dynamodb = new DynamoDB.DocumentClient();
const TABLE_NAME = process.env.TABLE_NAME!;

export const handler = async (
  event: APIGatewayProxyEvent
): Promise<APIGatewayProxyResult> => {
  try {
    const body = JSON.parse(event.body || '{}');
    const result = await processRequest(body);

    return {
      statusCode: 200,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(result),
    };
  } catch (error) {
    console.error('Request failed:', error);
    return {
      statusCode: error instanceof ValidationError ? 400 : 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
```

### Cold Start Optimization

| Strategy | Impact | Cost |
|----------|--------|------|
| Smaller bundles (tree-shake) | -50-80% cold start | Free |
| Initialize SDK outside handler | Reuse across invocations | Free |
| Provisioned concurrency | Eliminates cold start | $$$ |
| ARM64 (Graviton2) | -20% cost, similar perf | Savings |
| Increase memory | Proportional CPU increase | $ |

```typescript
// CDK: Provisioned concurrency for latency-sensitive endpoints
const alias = fn.addAlias('live');
const scaling = alias.addAutoScaling({ minCapacity: 2, maxCapacity: 50 });
scaling.scaleOnUtilization({ utilizationTarget: 0.7 });
```

### Lambda Layers

```typescript
// Share dependencies across functions
const depsLayer = new lambda.LayerVersion(this, 'DepsLayer', {
  code: lambda.Code.fromAsset('layers/deps'),
  compatibleRuntimes: [lambda.Runtime.NODEJS_20_X],
  description: 'Shared dependencies',
});

const fn = new lambda.Function(this, 'Fn', {
  layers: [depsLayer],
  // ...
});
```

## API Gateway Patterns

### REST API vs HTTP API

| Feature | REST API | HTTP API |
|---------|----------|----------|
| Cost | ~$3.50/million | ~$1.00/million |
| Auth | IAM, Cognito, Custom | IAM, JWT, OIDC |
| Throttling | Per-method | Per-route |
| WAF | Yes | No |
| Usage plans | Yes | No |
| WebSocket | No (use WebSocket API) | No |

**Use HTTP API** unless you need WAF, usage plans, or request validation.

### Request Validation

```typescript
// REST API: Model-based validation
const model = api.addModel('CreateUserModel', {
  schema: {
    type: apigateway.JsonSchemaType.OBJECT,
    required: ['email', 'name'],
    properties: {
      email: { type: apigateway.JsonSchemaType.STRING },
      name: { type: apigateway.JsonSchemaType.STRING },
    },
  },
});

resource.addMethod('POST', integration, {
  requestValidator: new apigateway.RequestValidator(this, 'Validator', {
    restApi: api,
    validateRequestBody: true,
  }),
  requestModels: { 'application/json': model },
});
```

## Step Functions

### When to Use

- Multi-step workflows with branching logic
- Long-running processes (up to 1 year)
- Saga pattern for distributed transactions
- Human approval workflows
- Retry and error handling orchestration

### Express vs Standard

| Feature | Standard | Express |
|---------|----------|---------|
| Duration | Up to 1 year | Up to 5 minutes |
| Pricing | Per state transition | Per execution + duration |
| Use case | Long-running workflows | High-volume, short processes |
| History | 90 days | CloudWatch Logs |

### Common Patterns

**Map pattern (parallel processing):**
```json
{
  "ProcessItems": {
    "Type": "Map",
    "ItemsPath": "$.items",
    "MaxConcurrency": 10,
    "Iterator": {
      "StartAt": "ProcessItem",
      "States": {
        "ProcessItem": {
          "Type": "Task",
          "Resource": "arn:aws:lambda:...",
          "End": true
        }
      }
    }
  }
}
```

**Saga pattern (compensating transactions):**
```
Book Hotel → Book Flight → Charge Payment
     ↓ fail      ↓ fail        ↓ fail
Cancel Hotel  Cancel Hotel   Cancel Hotel
              Cancel Flight  Cancel Flight
                             Refund Payment
```

## Event-Driven Patterns

### EventBridge Rules

```typescript
// Route events by pattern
const rule = new events.Rule(this, 'OrderRule', {
  eventPattern: {
    source: ['myapp.orders'],
    detailType: ['OrderCreated'],
    detail: {
      total: [{ numeric: ['>=', 100] }],
    },
  },
});
rule.addTarget(new targets.LambdaFunction(highValueOrderFn));
```

### Fan-Out (SNS + SQS)

```
API → SNS Topic ─┬→ SQS (email queue) → Lambda (send email)
                  ├→ SQS (analytics queue) → Lambda (track event)
                  └→ SQS (webhook queue) → Lambda (notify partners)
```

### Dead Letter Queues

Every async Lambda invocation should have a DLQ:

```typescript
const fn = new lambda.Function(this, 'Fn', {
  deadLetterQueue: dlq,
  deadLetterQueueEnabled: true,
  retryAttempts: 2,
  // ...
});
```

## Anti-Patterns

| Anti-Pattern | Problem | Better |
|-------------|---------|--------|
| Lambda calling Lambda | Tight coupling, double billing | Use SQS/EventBridge between |
| Synchronous fan-out | Timeout cascade | Async fan-out via SNS/EventBridge |
| Large Lambda bundles | Slow cold starts | Tree-shake, split per-function |
| Shared mutable state | Race conditions | DynamoDB with conditional writes |
| No DLQ on async | Silent message loss | Always configure DLQ |
