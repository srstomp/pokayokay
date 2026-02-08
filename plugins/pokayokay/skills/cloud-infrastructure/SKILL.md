---
name: cloud-infrastructure
agents: [yokay-implementer]
description: Use when provisioning cloud resources, choosing between AWS services (Lambda vs ECS vs EKS), writing CDK/IaC, designing serverless or container architectures, configuring IAM/security groups, or optimizing cloud costs.
---

# Cloud Infrastructure

Design and provision cloud infrastructure with AWS-primary patterns and cloud-agnostic naming for portability.

## Decision Framework

```
New service/workload?
├── Stateless, event-driven, <15min → Serverless (Lambda + API GW)
├── Long-running, stateful, predictable → Containers (ECS Fargate)
├── Kubernetes-native, multi-cloud → Orchestration (EKS)
└── Static content, CDN → Storage (S3 + CloudFront)

Database needs?
├── Key-value, <1ms, scale-to-zero → DynamoDB
├── Relational, complex queries → RDS/Aurora
├── Document store, flexible schema → DocumentDB
└── Cache, sessions, pub/sub → ElastiCache (Redis)

IaC approach?
├── AWS-only, type-safe → CDK (TypeScript)
├── Multi-cloud, declarative → Terraform
└── Simple, YAML → CloudFormation
```

## When NOT to Use

- **CI/CD pipelines**: Use `ci-cd` skill for pipeline config (CodePipeline, GitHub Actions)
- **Database schema design**: Use `database-design` skill for schema/migrations/queries
- **Application-level monitoring**: Use `observability` skill for application metrics/logs/traces

## References

| File | Use When |
|------|----------|
| `references/service-selection.md` | Choosing between AWS compute, database, or messaging services |
| `references/cdk-patterns.md` | Writing CDK constructs, organizing stacks, L1/L2/L3 patterns |
| `references/serverless-patterns.md` | Building Lambda functions, API Gateway, Step Functions, event-driven |
| `references/container-patterns.md` | ECS Fargate task definitions, service discovery, health checks |
| `references/iam-and-security.md` | IAM policies, security groups, VPC design, least privilege |
| `references/storage-and-cdn.md` | S3 configuration, CloudFront distributions, caching strategies |
| `references/database-selection.md` | DynamoDB patterns, RDS/Aurora configuration, managed DB comparison |
| `references/cost-optimization.md` | Right-sizing, reserved capacity, cost estimation, billing alerts |
