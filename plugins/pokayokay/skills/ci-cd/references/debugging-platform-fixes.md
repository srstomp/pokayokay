# CI/CD Debugging: Platform-Specific Debugging and Common Fixes

Platform-specific debugging techniques, common fix patterns, and quick reference.

## Platform-Specific Debugging

### GitHub Actions

```yaml
# Enable debug logging
# Set repository secret: ACTIONS_STEP_DEBUG = true

# Or per-workflow
- name: Debug
  run: echo "test"
  env:
    ACTIONS_STEP_DEBUG: true

# SSH into runner
- uses: mxschmitt/action-tmate@v3
  if: failure()

# Print GitHub context
- name: Print context
  run: |
    echo '${{ toJSON(github) }}'
    echo '${{ toJSON(env) }}'
    echo '${{ toJSON(secrets) }}' # Won't show values
```

### GitLab CI

```yaml
# Enable debug
variables:
  CI_DEBUG_TRACE: "true"

# Debug job
debug_job:
  script:
    - echo "Job info:"
    - env | grep CI_
    - echo "Files:"
    - ls -la
```

### CircleCI

```yaml
# SSH debug
# Rerun job with "Rerun with SSH" button

# Verbose output
- run:
    name: Debug
    command: |
      set -x
      npm test
    environment:
      DEBUG: "*"
```

### Azure DevOps

```yaml
# System debug
variables:
  System.Debug: true

# Verbose logging
steps:
  - script: |
      echo "##vso[task.setvariable variable=system.debug]true"
```

## Common Fix Patterns

### Flaky Tests

```yaml
# Retry flaky tests
- name: Tests with retry
  uses: nick-fields/retry@v2
  with:
    timeout_minutes: 10
    max_attempts: 3
    command: npm test

# Or in test framework
# jest.config.js
module.exports = {
  retryTimes: 2,
};
```

### Dependency Issues

```yaml
# Clear and reinstall
- name: Clean install
  run: |
    rm -rf node_modules
    rm -rf ~/.npm
    npm cache clean --force
    npm ci

# Pin exact versions
- run: npm ci --ignore-scripts  # Skip postinstall
```

### Secret Issues

```yaml
# Verify secret exists (safe way)
- name: Check secrets
  run: |
    if [ -z "${{ secrets.API_KEY }}" ]; then
      echo "::error::API_KEY secret is not set"
      exit 1
    fi
    echo "Secret is configured"

# Debug secret scope
- name: Check token
  run: |
    curl -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
      https://api.github.com/user \
      -o /dev/null -w "%{http_code}"
```

### Checkout Issues

```yaml
# Full clone with submodules
- uses: actions/checkout@v4
  with:
    fetch-depth: 0
    submodules: recursive
    token: ${{ secrets.PAT }}  # For private submodules

# Debug checkout
- run: |
    git status
    git log --oneline -5
    git submodule status
```

## Debugging Checklist

```markdown
## Pre-Debug
- [ ] Read full error message (scroll up!)
- [ ] Check if issue is new or existing
- [ ] Try reproducing locally
- [ ] Check recent changes (git diff)

## Environment
- [ ] Correct runtime versions?
- [ ] Required tools installed?
- [ ] Environment variables set?
- [ ] Secrets accessible?

## Dependencies
- [ ] Lock file committed?
- [ ] Cache invalidated if needed?
- [ ] Versions compatible?

## Network
- [ ] Services healthy?
- [ ] Correct URLs/ports?
- [ ] Auth tokens valid?

## Resources
- [ ] Enough memory?
- [ ] Enough disk space?
- [ ] Reasonable timeout?

## Post-Debug
- [ ] Document the fix
- [ ] Add tests to prevent regression
- [ ] Update monitoring/alerts
```

## Quick Reference

| Error Pattern | First Check | Quick Fix |
|---------------|-------------|-----------|
| `ENOENT: no such file` | Path exists? | Fix path, check checkout |
| `EACCES: permission denied` | File permissions? | `chmod +x`, check user |
| `ETIMEDOUT` | Service running? | Wait/retry, check URL |
| `OOMKilled` | Memory limit? | Increase resources |
| `exit code 1` | Script error? | Run locally, add `-x` |
| `authentication failed` | Token valid? | Refresh secret, check scope |
| `disk quota exceeded` | Disk space? | Clean up, prune Docker |
| `rate limit exceeded` | Too many requests? | Add delay, use token |
