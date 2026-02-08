# Database Selection

DynamoDB patterns, RDS/Aurora configuration, and managed database comparison.

## Decision Matrix

| Factor | DynamoDB | RDS PostgreSQL | Aurora | ElastiCache Redis |
|--------|----------|----------------|--------|-------------------|
| Query pattern | Key-value, known access | Complex joins, ad-hoc | Complex joins, ad-hoc | Cache, sessions, pub/sub |
| Scaling | Automatic, infinite | Vertical + read replicas | Auto-scaling storage | Cluster mode |
| Latency | <10ms | <10ms | <10ms | <1ms |
| Schema | Schemaless | Strict schema | Strict schema | Key-value |
| Cost model | Per-request or provisioned | Instance-hours | Instance-hours + IO | Instance-hours |
| Ops burden | None | Medium | Low | Low |
| Multi-AZ | Built-in | Optional ($) | Built-in | Optional ($) |

### Decision Flow

```
Do you know ALL access patterns upfront?
├── YES: Is it key-value or simple queries?
│   ├── YES → DynamoDB
│   └── NO: Need complex joins/aggregations?
│       ├── YES → Aurora PostgreSQL
│       └── NO → DynamoDB (with GSIs)
└── NO: Flexible querying needed?
    ├── YES → Aurora PostgreSQL
    └── NO → Start with DynamoDB, migrate if needed
```

## DynamoDB Patterns

### Single-Table Design

```typescript
// CDK: Table with GSI
const table = new dynamodb.Table(this, 'MainTable', {
  partitionKey: { name: 'PK', type: dynamodb.AttributeType.STRING },
  sortKey: { name: 'SK', type: dynamodb.AttributeType.STRING },
  billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
  pointInTimeRecovery: true,
  removalPolicy: cdk.RemovalPolicy.RETAIN,
});

// GSI for inverted access pattern
table.addGlobalSecondaryIndex({
  indexName: 'GSI1',
  partitionKey: { name: 'GSI1PK', type: dynamodb.AttributeType.STRING },
  sortKey: { name: 'GSI1SK', type: dynamodb.AttributeType.STRING },
  projectionType: dynamodb.ProjectionType.ALL,
});
```

### Access Patterns

```
Entity     | PK              | SK              | GSI1PK          | GSI1SK
-----------|-----------------|-----------------|-----------------|----------------
User       | USER#123        | PROFILE         | EMAIL#a@b.com   | USER#123
Order      | USER#123        | ORDER#456       | ORDER#456       | STATUS#pending
OrderItem  | ORDER#456       | ITEM#789        | PRODUCT#abc     | ORDER#456
```

### Conditional Writes

```typescript
// Prevent overwrite
await dynamodb.put({
  TableName: TABLE_NAME,
  Item: { PK: 'USER#123', SK: 'PROFILE', email, name },
  ConditionExpression: 'attribute_not_exists(PK)',
}).promise();

// Optimistic locking
await dynamodb.update({
  TableName: TABLE_NAME,
  Key: { PK: 'ORDER#456', SK: 'STATUS' },
  UpdateExpression: 'SET #status = :new, #version = :newV',
  ConditionExpression: '#version = :oldV',
  ExpressionAttributeValues: {
    ':new': 'shipped',
    ':newV': version + 1,
    ':oldV': version,
  },
}).promise();
```

### Billing Modes

| Mode | Use When | Pricing |
|------|----------|---------|
| PAY_PER_REQUEST (on-demand) | Variable traffic, new workloads | $1.25/million writes, $0.25/million reads |
| PROVISIONED | Predictable traffic | $0.00065/WCU/hr, $0.00013/RCU/hr |
| PROVISIONED + autoscaling | Predictable with spikes | Base + scaling |

**Start with on-demand**, switch to provisioned when traffic patterns are clear.

## RDS / Aurora

### Aurora PostgreSQL (Recommended for Relational)

```typescript
const cluster = new rds.DatabaseCluster(this, 'Database', {
  engine: rds.DatabaseClusterEngine.auroraPostgres({
    version: rds.AuroraPostgresEngineVersion.VER_15_4,
  }),
  credentials: rds.Credentials.fromGeneratedSecret('admin'),
  instanceProps: {
    vpc,
    vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },
    instanceType: ec2.InstanceType.of(ec2.InstanceClass.T4G, ec2.InstanceSize.MEDIUM),
    securityGroups: [dbSg],
  },
  instances: 2,  // Writer + 1 reader
  backup: { retention: cdk.Duration.days(14) },
  storageEncrypted: true,
  deletionProtection: true,
  removalPolicy: cdk.RemovalPolicy.RETAIN,
});
```

### Aurora Serverless v2

```typescript
const cluster = new rds.DatabaseCluster(this, 'Database', {
  engine: rds.DatabaseClusterEngine.auroraPostgres({
    version: rds.AuroraPostgresEngineVersion.VER_15_4,
  }),
  serverlessV2MinCapacity: 0.5,   // Scale to near-zero
  serverlessV2MaxCapacity: 16,
  writer: rds.ClusterInstance.serverlessV2('Writer'),
  readers: [rds.ClusterInstance.serverlessV2('Reader', { scaleWithWriter: true })],
  vpc,
  vpcSubnets: { subnetType: ec2.SubnetType.PRIVATE_ISOLATED },
});
```

### Connection Management

```typescript
// Use RDS Proxy for Lambda → RDS connections
const proxy = new rds.DatabaseProxy(this, 'Proxy', {
  proxyTarget: rds.ProxyTarget.fromCluster(cluster),
  secrets: [cluster.secret!],
  vpc,
  securityGroups: [proxySg],
  requireTLS: true,
});

proxy.grantConnect(handler, 'admin');
```

## ElastiCache Redis

### Use Cases

| Use Case | Pattern | TTL |
|----------|---------|-----|
| Session store | SET session:{id} data | 24h |
| API cache | SET cache:{endpoint}:{params} | 5-60min |
| Rate limiting | INCR ratelimit:{ip}:{window} | Window duration |
| Leaderboard | ZADD leaderboard score user | Persistent |
| Pub/Sub | PUBLISH channel message | N/A |

```typescript
const redis = new elasticache.CfnReplicationGroup(this, 'Redis', {
  replicationGroupDescription: 'App cache',
  engine: 'redis',
  cacheNodeType: 'cache.t4g.micro',
  numCacheClusters: 2,              // Multi-AZ
  automaticFailoverEnabled: true,
  atRestEncryptionEnabled: true,
  transitEncryptionEnabled: true,
  securityGroupIds: [redisSg.securityGroupId],
  cacheSubnetGroupName: subnetGroup.ref,
});
```

## Anti-Patterns

| Anti-Pattern | Problem | Better |
|-------------|---------|--------|
| DynamoDB for ad-hoc queries | Expensive scans | Aurora for flexible querying |
| RDS without proxy for Lambda | Connection exhaustion | Use RDS Proxy |
| No point-in-time recovery | Can't recover from bad writes | Enable PITR |
| Public database endpoint | Security risk | Private subnet + VPC only |
| Single-AZ database | No failover | Multi-AZ for production |
