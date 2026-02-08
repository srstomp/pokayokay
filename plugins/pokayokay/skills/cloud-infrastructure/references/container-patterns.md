# Container Patterns

ECS Fargate task definitions, service discovery, health checks, and deployment strategies.

## ECS Fargate Fundamentals

### Architecture

```
ECS Cluster
├── Service (maintains desired count)
│   ├── Task (running container group)
│   │   ├── Container (app)
│   │   └── Container (sidecar - optional)
│   └── Task Definition (blueprint)
└── Capacity Provider (FARGATE or FARGATE_SPOT)
```

### Task Definition

```typescript
const taskDef = new ecs.FargateTaskDefinition(this, 'TaskDef', {
  cpu: 256,        // 0.25 vCPU
  memoryLimitMiB: 512,
  runtimePlatform: {
    cpuArchitecture: ecs.CpuArchitecture.ARM64,      // Graviton = cheaper
    operatingSystemFamily: ecs.OperatingSystemFamily.LINUX,
  },
});

const container = taskDef.addContainer('App', {
  image: ecs.ContainerImage.fromEcrRepository(repo, 'latest'),
  logging: ecs.LogDrivers.awsLogs({
    streamPrefix: 'app',
    logRetention: logs.RetentionDays.TWO_WEEKS,
  }),
  environment: {
    NODE_ENV: 'production',
    PORT: '3000',
  },
  secrets: {
    DB_URL: ecs.Secret.fromSecretsManager(dbSecret),
  },
  healthCheck: {
    command: ['CMD-SHELL', 'curl -f http://localhost:3000/health || exit 1'],
    interval: cdk.Duration.seconds(30),
    timeout: cdk.Duration.seconds(5),
    retries: 3,
    startPeriod: cdk.Duration.seconds(60),
  },
});

container.addPortMappings({ containerPort: 3000 });
```

### CPU/Memory Combinations

| CPU (vCPU) | Memory Options |
|-----------|----------------|
| 0.25 | 0.5, 1, 2 GB |
| 0.5 | 1, 2, 3, 4 GB |
| 1 | 2, 3, 4, 5, 6, 7, 8 GB |
| 2 | 4-16 GB (1 GB increments) |
| 4 | 8-30 GB (1 GB increments) |

**Start small.** Most web services work fine with 0.5 vCPU / 1 GB.

## Service Configuration

### ALB-Backed Service

```typescript
const service = new ecs_patterns.ApplicationLoadBalancedFargateService(this, 'Service', {
  cluster,
  taskDefinition: taskDef,
  desiredCount: 2,
  minHealthyPercent: 100,
  maxHealthyPercent: 200,
  healthCheckGracePeriod: cdk.Duration.seconds(60),
  circuitBreaker: { rollback: true },  // Auto-rollback on deployment failure
  assignPublicIp: false,               // Private subnet
});

// Auto-scaling
const scaling = service.service.autoScaleTaskCount({
  minCapacity: 2,
  maxCapacity: 20,
});
scaling.scaleOnCpuUtilization('CpuScaling', {
  targetUtilizationPercent: 70,
  scaleInCooldown: cdk.Duration.seconds(60),
  scaleOutCooldown: cdk.Duration.seconds(30),
});
```

### Health Check Configuration

```typescript
service.targetGroup.configureHealthCheck({
  path: '/health',
  healthyThresholdCount: 2,
  unhealthyThresholdCount: 3,
  interval: cdk.Duration.seconds(30),
  timeout: cdk.Duration.seconds(10),
});
```

## Service Discovery

### AWS Cloud Map

```typescript
const namespace = new servicediscovery.PrivateDnsNamespace(this, 'Namespace', {
  name: 'internal',
  vpc,
});

const service = new ecs.FargateService(this, 'Service', {
  cluster,
  taskDefinition: taskDef,
  cloudMapOptions: {
    name: 'api',
    dnsRecordType: servicediscovery.DnsRecordType.A,
  },
});

// Other services can reach this at: api.internal
```

## Deployment Strategies

| Strategy | Downtime | Rollback | Use When |
|----------|----------|----------|----------|
| Rolling | None | Slow | Default, most cases |
| Blue/Green | None | Fast | Critical services |
| Canary | None | Fast | High-risk changes |

### Rolling (Default)

```typescript
// Controlled by minHealthyPercent and maxHealthyPercent
{
  minHealthyPercent: 100,  // Never below desired count
  maxHealthyPercent: 200,  // Allow 2x during deploy
}
```

### Circuit Breaker

```typescript
// Auto-rollback if deployment fails
circuitBreaker: { rollback: true }
```

## Sidecar Patterns

| Sidecar | Purpose | Example |
|---------|---------|---------|
| Log router | Ship logs to external service | Fluent Bit → Datadog |
| Service mesh | mTLS, traffic management | Envoy (App Mesh) |
| Reverse proxy | TLS termination, routing | Nginx |
| Monitoring | Metrics collection | CloudWatch agent |

```typescript
// Add sidecar container
taskDef.addContainer('FluentBit', {
  image: ecs.ContainerImage.fromRegistry('amazon/aws-for-fluent-bit:latest'),
  logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'fluentbit' }),
  essential: false,  // Don't kill task if sidecar crashes
});
```

## Anti-Patterns

| Anti-Pattern | Problem | Better |
|-------------|---------|--------|
| Latest tag | Non-deterministic deploys | Immutable tags (git SHA, semver) |
| No health checks | Silent failures | Container + ALB health checks |
| No circuit breaker | Bad deploys stay up | Enable circuit breaker rollback |
| Over-provisioned | Wasted cost | Start small, scale on metrics |
| Secrets in env vars | Visible in console | Use ECS secrets from Secrets Manager |
