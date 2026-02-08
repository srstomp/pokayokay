# IAM and Security

Least-privilege IAM, security groups, VPC design, and security best practices.

## IAM Principles

### Least Privilege

**Start with zero permissions, add only what's needed.**

```typescript
// BAD: Wildcard permissions
handler.addToRolePolicy(new iam.PolicyStatement({
  actions: ['dynamodb:*'],
  resources: ['*'],
}));

// GOOD: Scoped permissions via grant methods
table.grantReadWriteData(handler);     // Only this table
bucket.grantRead(handler);              // Read-only on this bucket
queue.grantSendMessages(handler);       // Send-only on this queue
```

### CDK Grant Methods (Preferred)

| Method | Permissions | Use When |
|--------|------------|----------|
| `table.grantReadData(fn)` | GetItem, Query, Scan | Read-only access |
| `table.grantWriteData(fn)` | PutItem, UpdateItem, DeleteItem | Write-only access |
| `table.grantReadWriteData(fn)` | All CRUD | Full table access |
| `bucket.grantRead(fn)` | GetObject, ListBucket | Reading files |
| `bucket.grantPut(fn)` | PutObject | Uploading files |
| `queue.grantConsumeMessages(fn)` | ReceiveMessage, DeleteMessage | Queue consumer |
| `secret.grantRead(fn)` | GetSecretValue | Reading secrets |

### Custom Policies (When Grants Aren't Enough)

```typescript
handler.addToRolePolicy(new iam.PolicyStatement({
  effect: iam.Effect.ALLOW,
  actions: ['ses:SendEmail', 'ses:SendRawEmail'],
  resources: [`arn:aws:ses:${this.region}:${this.account}:identity/*`],
  conditions: {
    StringEquals: { 'ses:FromAddress': 'noreply@example.com' },
  },
}));
```

### Service Roles

```typescript
// ECS task role (permissions for the application)
const taskRole = new iam.Role(this, 'TaskRole', {
  assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
});
table.grantReadWriteData(taskRole);

// ECS execution role (permissions for ECS itself: pull images, write logs)
// Usually handled automatically by CDK
```

## Security Groups

### Pattern: Tiered Access

```typescript
// ALB security group — public internet access
const albSg = new ec2.SecurityGroup(this, 'AlbSg', { vpc });
albSg.addIngressRule(ec2.Peer.anyIpv4(), ec2.Port.tcp(443), 'HTTPS');

// App security group — only from ALB
const appSg = new ec2.SecurityGroup(this, 'AppSg', { vpc });
appSg.addIngressRule(albSg, ec2.Port.tcp(3000), 'From ALB');

// DB security group — only from app
const dbSg = new ec2.SecurityGroup(this, 'DbSg', { vpc });
dbSg.addIngressRule(appSg, ec2.Port.tcp(5432), 'From App');
```

### Rules

1. **No 0.0.0.0/0 on non-ALB resources** — only ALBs face the internet
2. **Reference security groups, not CIDRs** — `appSg` not `10.0.10.0/24`
3. **Minimize port ranges** — specific ports, never `0-65535`
4. **No SSH to production** — use SSM Session Manager instead

## Secrets Management

### Secrets Manager (Recommended)

```typescript
// Create secret
const dbSecret = new secretsmanager.Secret(this, 'DbSecret', {
  generateSecretString: {
    secretStringTemplate: JSON.stringify({ username: 'admin' }),
    generateStringKey: 'password',
    excludePunctuation: true,
  },
});

// Use in ECS
taskDef.addContainer('App', {
  secrets: {
    DB_PASSWORD: ecs.Secret.fromSecretsManager(dbSecret, 'password'),
  },
});

// Use in Lambda
dbSecret.grantRead(handler);
// handler reads: await secretsManager.getSecretValue({ SecretId: 'arn:...' })
```

### SSM Parameter Store (Config, Not Secrets)

```typescript
// For non-sensitive configuration
const param = new ssm.StringParameter(this, 'Config', {
  parameterName: '/myapp/prod/feature-flag',
  stringValue: 'true',
});
param.grantRead(handler);
```

## WAF (Web Application Firewall)

```typescript
const webAcl = new wafv2.CfnWebACL(this, 'WebAcl', {
  scope: 'REGIONAL',
  defaultAction: { allow: {} },
  rules: [
    {
      name: 'RateLimit',
      priority: 1,
      action: { block: {} },
      statement: {
        rateBasedStatement: {
          limit: 2000,
          aggregateKeyType: 'IP',
        },
      },
      visibilityConfig: { /* ... */ },
    },
    {
      name: 'AWSManagedRulesCommonRuleSet',
      priority: 2,
      overrideAction: { none: {} },
      statement: {
        managedRuleGroupStatement: {
          vendorName: 'AWS',
          name: 'AWSManagedRulesCommonRuleSet',
        },
      },
      visibilityConfig: { /* ... */ },
    },
  ],
  visibilityConfig: {
    cloudWatchMetricsEnabled: true,
    metricName: 'WebAclMetric',
    sampledRequestsEnabled: true,
  },
});
```

## Security Checklist

- [ ] All IAM using least privilege (grant methods, not wildcards)
- [ ] No hardcoded credentials (use Secrets Manager)
- [ ] Security groups reference other SGs, not CIDRs
- [ ] No public access to databases or app tier
- [ ] VPC endpoints for AWS services (avoid NAT for S3/DynamoDB)
- [ ] Encryption at rest enabled (S3, RDS, DynamoDB, EBS)
- [ ] Encryption in transit (TLS/HTTPS everywhere)
- [ ] WAF on public-facing ALBs
- [ ] CloudTrail enabled for audit logging
- [ ] No SSH — use SSM Session Manager
