---
name: ci-cd
description: Use when creating or debugging CI/CD pipelines, implementing deployment strategies (blue-green, canary, rolling), optimizing build times, reviewing pipeline security, or working with GitHub Actions, GitLab CI, CircleCI, Azure DevOps, or Bitbucket Pipelines.
---

# CI/CD Expert

Create, debug, and optimize CI/CD pipelines across platforms.

## Platform Selection

| Platform | Best For | Key Strength |
|----------|----------|--------------|
| GitHub Actions | GitHub repos, open source | Marketplace, native integration |
| GitLab CI | GitLab repos, self-hosted | Built-in registry, Auto DevOps |
| CircleCI | Complex workflows, speed | Parallelism, orbs |
| Azure DevOps | Microsoft/enterprise | Azure integration, YAML templates |
| Bitbucket | Atlassian stack | Jira integration, pipes |

## Key Principles

- **Security first**: Never expose secrets in logs, use environment-specific secrets
- **Reliability**: Idempotent steps, deterministic builds, pinned dependency versions
- **Efficiency**: Cache aggressively, parallelize independent jobs, skip unchanged paths
- **Maintainability**: DRY with reusable workflows/templates, clear naming

## Quick Start Checklist

1. Choose platform based on repository hosting
2. Create pipeline with lint → test → build → deploy stages
3. Configure secrets and environment variables
4. Set up caching for dependencies and build artifacts
5. Add deployment strategy (blue-green recommended for production)
6. Review security checklist before going live

## References

| Reference | Description |
|-----------|-------------|
| [deployment-strategies-blue-green-canary.md](references/deployment-strategies-blue-green-canary.md) | Blue-green and canary deployments with K8s and AWS examples |
| [deployment-strategies-rolling-flags-rollback.md](references/deployment-strategies-rolling-flags-rollback.md) | Rolling deploys, feature flags, rollback, health checks |
| [security-checklist.md](references/security-checklist.md) | Secrets, permissions, supply chain security |
