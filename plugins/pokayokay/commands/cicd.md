---
description: Create, debug, or optimize CI/CD pipelines
argument-hint: <pipeline-task>
skill: ci-cd
---

# CI/CD Pipeline Workflow

Create, debug, or optimize CI/CD for: `$ARGUMENTS`

## Steps

### 1. Detect Platform
Identify CI/CD platform from existing config:
- `.github/workflows/` → GitHub Actions
- `.gitlab-ci.yml` → GitLab CI
- `.circleci/config.yml` → CircleCI
- `Jenkinsfile` → Jenkins
- `azure-pipelines.yml` → Azure DevOps

If no config exists, ask which platform to use.

### 2. Identify Task Type
From `$ARGUMENTS`, determine the goal:
- **Create**: Generate new pipeline configuration
- **Debug**: Diagnose and fix pipeline failures
- **Optimize**: Improve build times and efficiency
- **Deploy**: Add deployment stages
- **Review**: Audit for best practices

### 3. Execute Task

**For Creation:**
- Design pipeline stages (build, test, deploy)
- Configure caching for dependencies
- Set up environment variables
- Add branch protection rules

**For Debugging:**
- Analyze failure logs
- Identify root cause
- Apply fix and test

**For Optimization:**
- Profile build times
- Add parallelization
- Configure caching
- Remove redundant steps

### 4. Create Implementation Tasks
```bash
npx @stevestomp/ohno-cli create "CI/CD: [specific improvement]" -t chore
```

## Covers
- Pipeline creation and configuration
- Build optimization and caching
- Test parallelization
- Deployment strategies (rolling, blue-green, canary)
- Environment management
- Secret handling

## Related Commands

- `/pokayokay:work` - Implement pipeline changes
- `/pokayokay:security` - Audit pipeline security
- `/pokayokay:observe` - Add pipeline monitoring

## Skill Integration

When CI/CD work involves:
- **Security scanning** → Also load `security-audit` skill
- **Deployment monitoring** → Also load `observability` skill
- **Database migrations** → Also load `database-design` skill
- **Test optimization** → Also load `testing-strategy` skill
