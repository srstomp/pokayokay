# CDK Patterns

AWS CDK (TypeScript) patterns for infrastructure as code.

## Construct Levels

| Level | What | When | Example |
|-------|------|------|---------|
| L1 | CloudFormation resources (Cfn*) | Escape hatch, new features | `CfnBucket` |
| L2 | Opinionated defaults, methods | Most cases | `Bucket`, `Function` |
| L3 | Multi-resource patterns | Common architectures | `LambdaRestApi` |

**Prefer L2 constructs.** Use L1 only when L2 doesn't expose a property. Use L3 for standard patterns.

## Stack Organization

### By Domain (Recommended)

```
lib/
├── networking-stack.ts      # VPC, subnets, security groups
├── database-stack.ts        # RDS, DynamoDB tables
├── api-stack.ts             # Lambda, API Gateway
├── auth-stack.ts            # Cognito, IAM roles
├── monitoring-stack.ts      # CloudWatch, alarms
└── app.ts                   # Stack composition
```

### Cross-Stack References

```typescript
// database-stack.ts
export class DatabaseStack extends cdk.Stack {
  public readonly table: dynamodb.Table;

  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);
    this.table = new dynamodb.Table(this, 'MainTable', {
      partitionKey: { name: 'PK', type: dynamodb.AttributeType.STRING },
      sortKey: { name: 'SK', type: dynamodb.AttributeType.STRING },
      billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
  }
}

// api-stack.ts
interface ApiStackProps extends cdk.StackProps {
  table: dynamodb.Table;
}

export class ApiStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props: ApiStackProps) {
    super(scope, id, props);
    const handler = new lambda.Function(this, 'Handler', {
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'index.handler',
      code: lambda.Code.fromAsset('lambda'),
      environment: { TABLE_NAME: props.table.tableName },
    });
    props.table.grantReadWriteData(handler);
  }
}

// app.ts
const db = new DatabaseStack(app, 'Database');
new ApiStack(app, 'Api', { table: db.table });
```

## Common Patterns

### Lambda with Environment Config

```typescript
const fn = new lambda.Function(this, 'Fn', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'index.handler',
  code: lambda.Code.fromAsset('lambda/my-function'),
  memorySize: 256,
  timeout: cdk.Duration.seconds(30),
  tracing: lambda.Tracing.ACTIVE,        // X-Ray
  logRetention: logs.RetentionDays.TWO_WEEKS,
  environment: {
    NODE_OPTIONS: '--enable-source-maps',
    TABLE_NAME: table.tableName,
    STAGE: props.stage,
  },
});
```

### API Gateway with CORS

```typescript
const api = new apigateway.RestApi(this, 'Api', {
  restApiName: 'MyService',
  defaultCorsPreflightOptions: {
    allowOrigins: apigateway.Cors.ALL_ORIGINS,
    allowMethods: apigateway.Cors.ALL_METHODS,
    allowHeaders: ['Content-Type', 'Authorization'],
  },
  deployOptions: {
    stageName: props.stage,
    tracingEnabled: true,
    throttlingRateLimit: 1000,
    throttlingBurstLimit: 500,
  },
});
```

### SQS Queue with DLQ

```typescript
const dlq = new sqs.Queue(this, 'DLQ', {
  retentionPeriod: cdk.Duration.days(14),
});

const queue = new sqs.Queue(this, 'Queue', {
  visibilityTimeout: cdk.Duration.seconds(300),
  deadLetterQueue: {
    queue: dlq,
    maxReceiveCount: 3,
  },
});

// Lambda consumer
const consumer = new lambda.Function(this, 'Consumer', { /* ... */ });
consumer.addEventSource(new SqsEventSource(queue, {
  batchSize: 10,
  maxBatchingWindow: cdk.Duration.seconds(5),
}));
```

### Scheduled Lambda (Cron)

```typescript
const rule = new events.Rule(this, 'Schedule', {
  schedule: events.Schedule.cron({ minute: '0', hour: '*/6' }),
});
rule.addTarget(new targets.LambdaFunction(cleanupFn));
```

## Environment Management

### Stage-Aware Configuration

```typescript
interface StageConfig {
  stage: string;
  account: string;
  region: string;
  domainName?: string;
}

const stages: Record<string, StageConfig> = {
  dev: { stage: 'dev', account: '111111111111', region: 'us-east-1' },
  staging: { stage: 'staging', account: '222222222222', region: 'us-east-1' },
  prod: { stage: 'prod', account: '333333333333', region: 'us-east-1',
           domainName: 'api.example.com' },
};
```

## Testing CDK

```typescript
import { Template } from 'aws-cdk-lib/assertions';

test('creates DynamoDB table', () => {
  const app = new cdk.App();
  const stack = new DatabaseStack(app, 'Test');
  const template = Template.fromStack(stack);

  template.hasResourceProperties('AWS::DynamoDB::Table', {
    KeySchema: [
      { AttributeName: 'PK', KeyType: 'HASH' },
      { AttributeName: 'SK', KeyType: 'RANGE' },
    ],
    BillingMode: 'PAY_PER_REQUEST',
  });
});
```

## Best Practices

1. **Tag everything**: Use `cdk.Tags.of(this).add('Project', 'MyApp')`
2. **RemovalPolicy**: RETAIN for databases, DESTROY for dev-only resources
3. **Outputs**: Export values other stacks or humans need
4. **Aspects**: Use for cross-cutting concerns (tagging, compliance)
5. **Context**: Use `cdk.json` context for environment-specific values
6. **Escape hatches**: `(construct.node.defaultChild as CfnResource).addPropertyOverride()`
