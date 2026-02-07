---
name: ci-cd
description: Create, review, debug, and optimize CI/CD pipelines across platforms. Covers GitHub Actions, GitLab CI, CircleCI, Azure DevOps, and Bitbucket Pipelines. Use this skill when creating new pipelines, debugging failing builds, implementing deployment strategies (blue-green, canary, rolling), reviewing pipelines for security and efficiency, or optimizing build times.
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
| [github-actions.md](references/github-actions.md) | Workflows, actions, matrix builds, reusable workflows |
| [gitlab-ci.md](references/gitlab-ci.md) | .gitlab-ci.yml, stages, environments, Auto DevOps |
| [circleci.md](references/circleci.md) | Orbs, workflows, parallelism |
| [azure-devops.md](references/azure-devops.md) | YAML pipelines, templates, environments |
| [bitbucket-pipelines.md](references/bitbucket-pipelines.md) | Pipes, deployments, Jira integration |
| [deployment-strategies.md](references/deployment-strategies.md) | Blue-green, canary, rolling deployments |
| [debugging-guide.md](references/debugging-guide.md) | Common failures, debugging techniques |
| [security-checklist.md](references/security-checklist.md) | Secrets, permissions, supply chain security |
