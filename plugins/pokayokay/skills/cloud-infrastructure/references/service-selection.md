# Service Selection Guide

Decision trees for choosing the right AWS service for common workloads.

## Compute Selection

### Decision Matrix

| Factor | Lambda | ECS Fargate | EKS | EC2 |
|--------|--------|-------------|-----|-----|
| Startup time | Cold start (100ms-10s) | 30-60s | Pod scheduling | Instant (running) |
| Max duration | 15 min | Unlimited | Unlimited | Unlimited |
| State | Stateless | Stateful ok | Stateful ok | Full control |
| Scaling | Per-request | Per-task | Per-pod | Per-instance |
| Min cost | $0 (idle) | ~$10/mo | ~$72/mo (control plane) | Instance cost |
| Ops burden | None | Low | High | Highest |

### When to Use Lambda

- Event-driven workloads (API calls, S3 events, SQS messages)
- Execution time < 15 minutes
- No persistent connections needed
- Variable/unpredictable traffic (scale to zero)
- Low-moderate throughput (<1000 concurrent)

```typescript
// CDK: Basic Lambda with API Gateway
const handler = new lambda.Function(this, 'Handler', {
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: 'index.handler',
  code: lambda.Code.fromAsset('lambda'),
  memorySize: 256,
  timeout: cdk.Duration.seconds(30),
  environment: {
    TABLE_NAME: table.tableName,
  },
});

const api = new apigateway.RestApi(this, 'Api');
api.root.addMethod('GET', new apigateway.LambdaIntegration(handler));
```

### When to Use ECS Fargate

- Long-running services (web servers, workers)
- Needs persistent connections (WebSockets, gRPC)
- Predictable, steady traffic
- Container-native application
- Need sidecar containers (observability, proxies)

### When to Use EKS

- Already Kubernetes-native
- Multi-cloud portability requirement
- Complex service mesh needs
- Team has Kubernetes expertise
- Need custom operators/controllers

### Decision Flow

```
Is execution time < 15 min?
├── YES: Is it event-driven?
│   ├── YES → Lambda
│   └── NO: Is traffic predictable?
│       ├── YES → ECS Fargate
│       └── NO → Lambda (with provisioned concurrency)
└── NO: Need Kubernetes?
    ├── YES → EKS
    └── NO → ECS Fargate
```

## Messaging & Event Services

| Service | Pattern | Ordering | Throughput | Use When |
|---------|---------|----------|------------|----------|
| SQS | Queue | FIFO optional | Very high | Decoupling, work queues, buffering |
| SNS | Pub/Sub | No | Very high | Fan-out, notifications, multi-subscriber |
| EventBridge | Event bus | Partial | High | Event routing, schema registry, cross-account |
| Kinesis | Stream | Per-shard | Very high | Real-time analytics, ordered log processing |
| Step Functions | Orchestration | Sequential | Moderate | Workflow coordination, saga patterns |

### Messaging Decision Flow

```
Need guaranteed ordering?
├── YES: High throughput?
│   ├── YES → Kinesis
│   └── NO → SQS FIFO
└── NO: Multiple consumers?
    ├── YES: Need content-based routing?
    │   ├── YES → EventBridge
    │   └── NO → SNS + SQS
    └── NO → SQS Standard
```

## Networking

### VPC Design Patterns

**Standard 3-tier:**
```
VPC (10.0.0.0/16)
├── Public subnets (10.0.0.0/24, 10.0.1.0/24)
│   └── ALB, NAT Gateway, Bastion
├── Private subnets (10.0.10.0/24, 10.0.11.0/24)
│   └── Application tier (ECS, Lambda in VPC)
└── Isolated subnets (10.0.20.0/24, 10.0.21.0/24)
    └── Database tier (RDS, ElastiCache)
```

**Serverless (no VPC):**
- Lambda without VPC access is simpler and faster (no ENI cold start)
- Only put Lambda in VPC if it needs to access VPC resources (RDS, ElastiCache)
- Use VPC endpoints for S3, DynamoDB, Secrets Manager

### When to Use VPC Endpoints

| Service | Endpoint Type | When |
|---------|--------------|------|
| S3 | Gateway (free) | Always in VPC |
| DynamoDB | Gateway (free) | Always in VPC |
| Secrets Manager | Interface ($) | Lambda in VPC accessing secrets |
| SQS | Interface ($) | Lambda in VPC with SQS |
| ECR | Interface ($) | ECS pulling images without NAT |

## Anti-Patterns

| Anti-Pattern | Problem | Better Approach |
|-------------|---------|-----------------|
| Lambda for everything | Cold starts, 15min limit, cost at scale | ECS for steady, long-running workloads |
| EC2 for everything | Ops overhead, patching, scaling | Serverless/Fargate for managed compute |
| VPC for Lambda | ENI cold start penalty (+1-10s) | No VPC unless accessing VPC resources |
| Single AZ | No fault tolerance | Always multi-AZ for production |
| Monolithic CDK stack | Slow deploys, blast radius | Split by domain/lifecycle |
