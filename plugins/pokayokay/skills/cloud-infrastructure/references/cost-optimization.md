# Cost Optimization

Right-sizing, reserved capacity, cost estimation, and billing alerts.

## Cost Awareness Principles

1. **Measure before optimizing** — enable Cost Explorer, set budgets
2. **Right-size first** — most savings come from using smaller instances
3. **Use managed services** — ops cost > compute cost for small teams
4. **Scale to zero when possible** — Lambda, DynamoDB on-demand, Aurora Serverless v2

## Quick Wins

| Action | Savings | Effort |
|--------|---------|--------|
| ARM64/Graviton instances | 20% compute cost | Change instance type |
| S3 lifecycle rules (IA + Glacier) | 50-90% storage | One-time config |
| DynamoDB on-demand → provisioned | 30-50% (if stable traffic) | Monitor first |
| Reserved Instances (1yr) | 30-40% compute | Commitment |
| Savings Plans (1yr) | 25-35% flexible | Commitment |
| Delete unused EBS volumes | 100% of wasted storage | Audit |
| NAT Gateway → VPC endpoints | $32/mo per endpoint saved | Architecture change |
| CloudFront for S3 | Cheaper data transfer | Add distribution |

## Cost Estimation

### Monthly Cost Reference (us-east-1, 2024 pricing)

**Compute:**
| Service | Config | Monthly |
|---------|--------|---------|
| Lambda | 1M invocations, 128MB, 200ms | ~$0.42 |
| Lambda | 10M invocations, 256MB, 500ms | ~$21 |
| ECS Fargate | 0.25 vCPU, 0.5GB, 24/7 | ~$9 |
| ECS Fargate | 1 vCPU, 2GB, 24/7 | ~$36 |
| ECS Fargate (ARM) | 1 vCPU, 2GB, 24/7 | ~$29 |

**Database:**
| Service | Config | Monthly |
|---------|--------|---------|
| DynamoDB on-demand | 1M writes, 5M reads | ~$7 |
| DynamoDB provisioned | 25 WCU, 100 RCU | ~$14 |
| RDS t4g.micro (Postgres) | Single-AZ, 20GB | ~$15 |
| Aurora Serverless v2 | 0.5-4 ACU, 20GB | ~$45-180 |
| ElastiCache t4g.micro | Single node | ~$12 |

**Networking:**
| Service | Config | Monthly |
|---------|--------|---------|
| NAT Gateway | Per gateway + data | ~$32 + $0.045/GB |
| ALB | Per ALB + LCU | ~$16 + usage |
| CloudFront | 100GB transfer | ~$8.50 |
| VPC Endpoint (Interface) | Per endpoint per AZ | ~$7.30 |
| VPC Endpoint (Gateway) | S3/DynamoDB | Free |

## Budgets and Alerts

### CloudWatch Billing Alarm

```typescript
const alarm = new cloudwatch.Alarm(this, 'BillingAlarm', {
  metric: new cloudwatch.Metric({
    namespace: 'AWS/Billing',
    metricName: 'EstimatedCharges',
    dimensionsMap: { Currency: 'USD' },
    statistic: 'Maximum',
    period: cdk.Duration.hours(6),
  }),
  threshold: 100,  // $100
  evaluationPeriods: 1,
  comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
});

alarm.addAlarmAction(new cw_actions.SnsAction(alertTopic));
```

### AWS Budgets (Preferred)

```typescript
new budgets.CfnBudget(this, 'MonthlyBudget', {
  budget: {
    budgetName: 'MonthlySpend',
    budgetType: 'COST',
    timeUnit: 'MONTHLY',
    budgetLimit: { amount: 200, unit: 'USD' },
  },
  notificationsWithSubscribers: [
    {
      notification: {
        comparisonOperator: 'GREATER_THAN',
        threshold: 80,
        thresholdType: 'PERCENTAGE',
        notificationType: 'ACTUAL',
      },
      subscribers: [{ subscriptionType: 'EMAIL', address: 'team@example.com' }],
    },
  ],
});
```

## Right-Sizing

### Lambda Memory

```
Higher memory = proportionally more CPU
128MB = 0.08 vCPU
256MB = 0.16 vCPU
1024MB = 0.58 vCPU
1769MB = 1 full vCPU
```

Use AWS Lambda Power Tuning to find the cost-optimal memory setting.

### ECS Task Right-Sizing

1. Start with minimum (0.25 vCPU, 0.5GB)
2. Monitor CPU/memory utilization for 1 week
3. Target 60-70% average utilization
4. Scale horizontally, not vertically

### Reserved vs On-Demand vs Spot

| Option | Savings | Commitment | Use When |
|--------|---------|------------|----------|
| On-Demand | 0% | None | Variable, unpredictable |
| Savings Plans (Compute) | 25-35% | 1 year | Flexible, any compute |
| Reserved Instances | 30-40% | 1 year | Specific instance type |
| Spot (Fargate Spot) | 50-70% | None | Fault-tolerant workloads |

## Data Transfer Costs

### Common Traps

| Transfer | Cost |
|----------|------|
| Internet → AWS | Free |
| AWS → Internet | $0.09/GB (first 10TB) |
| Same AZ | Free |
| Cross AZ | $0.01/GB each way |
| Cross Region | $0.02/GB |
| NAT Gateway | $0.045/GB processed |

### Savings Strategies

1. **Use CloudFront** for outbound traffic ($0.085/GB vs $0.09/GB, with free tier)
2. **VPC Gateway endpoints** for S3/DynamoDB (free vs NAT Gateway)
3. **Keep services in same AZ** when possible
4. **Compress data** before transfer
5. **Use S3 Transfer Acceleration** only when speed matters

## Cost Review Checklist

- [ ] Budget alerts configured at 50%, 80%, 100%
- [ ] Cost Explorer enabled with daily granularity
- [ ] Resource tagging for cost allocation (Project, Environment, Team)
- [ ] No idle resources (stopped instances with EBS, unused EIPs, empty buckets)
- [ ] S3 lifecycle rules on all non-critical buckets
- [ ] VPC Gateway endpoints for S3 and DynamoDB
- [ ] ARM64/Graviton where supported
- [ ] Right-sized instances (check utilization monthly)
