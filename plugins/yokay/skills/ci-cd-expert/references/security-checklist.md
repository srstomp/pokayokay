# CI/CD Security Checklist

Comprehensive security guide based on OWASP CI/CD security guidelines.

## Security Priorities

```
┌─────────────────────────────────────────────────────────────────┐
│                  CI/CD SECURITY LAYERS                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  1. SECRETS        →  Never exposed, properly scoped            │
│         ↓                                                       │
│  2. DEPENDENCIES   →  Pinned, scanned, minimal                  │
│         ↓                                                       │
│  3. BUILD PROCESS  →  Reproducible, verified, isolated          │
│         ↓                                                       │
│  4. PERMISSIONS    →  Least privilege, audited                  │
│         ↓                                                       │
│  5. ARTIFACTS      →  Signed, validated, immutable              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 1. Secret Management

### ❌ Anti-Patterns

```yaml
# NEVER: Hardcoded secrets
env:
  API_KEY: "sk-abc123..."  # Exposed in repo!

# NEVER: Secrets in logs
- run: echo "Deploying with $API_KEY"

# NEVER: Secrets in URLs
- run: curl "https://api.com?key=$API_KEY"

# NEVER: Secrets in error messages
- run: ./deploy.sh || echo "Failed with key $API_KEY"
```

### ✅ Best Practices

```yaml
# GitHub Actions
- name: Deploy
  run: ./deploy.sh
  env:
    API_KEY: ${{ secrets.API_KEY }}

# Mask dynamic secrets
- name: Generate token
  run: |
    TOKEN=$(./get-token.sh)
    echo "::add-mask::$TOKEN"
    echo "TOKEN=$TOKEN" >> $GITHUB_ENV
```

### Secret Rotation

```yaml
# Verify secrets before deploy
- name: Validate secrets
  run: |
    # Check token validity
    curl -f -H "Authorization: Bearer ${{ secrets.DEPLOY_TOKEN }}" \
      https://api.example.com/validate \
      || { echo "Token invalid"; exit 1; }
```

### Scope Secrets Properly

| Scope | Use Case | Platform Setting |
|-------|----------|------------------|
| Repository | Single repo needs | Repository secrets |
| Environment | Stage-specific | Environment secrets |
| Organization | Shared services | Organization secrets |

## 2. Dependency Security

### Pin Dependencies

```yaml
# ✅ Pinned versions
uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1

# ❌ Mutable tags (vulnerable to supply chain attacks)
uses: actions/checkout@v4
uses: actions/checkout@main
```

### Lock Files

```yaml
# Always use lock files
- run: npm ci                 # Uses package-lock.json
- run: pip install -r requirements.txt --require-hashes
- run: bundle install --frozen
```

### Dependency Scanning

```yaml
# GitHub Actions - Dependabot
# .github/dependabot.yml
version: 2
updates:
  - package-ecosystem: "npm"
    directory: "/"
    schedule:
      interval: "weekly"
    commit-message:
      prefix: "deps"

# Manual scanning
- name: Audit dependencies
  run: |
    npm audit --audit-level=high
    # Or
    npx better-npm-audit audit
```

### Supply Chain Security

```yaml
# Verify package integrity
- name: Verify checksums
  run: |
    npm ci --ignore-scripts  # Don't run postinstall
    npm audit signatures     # Verify npm signatures (npm 8.5+)

# Use SLSA provenance
- uses: slsa-framework/slsa-github-generator/.github/workflows/builder_nodejs_slsa3.yml@v1.9.0
```

## 3. Build Security

### Reproducible Builds

```yaml
# Pin everything
- uses: actions/setup-node@v4
  with:
    node-version: '20.10.0'  # Exact version

# Verify build outputs
- name: Build
  run: npm run build

- name: Verify build hash
  run: |
    EXPECTED_HASH="sha256:abc123..."
    ACTUAL_HASH=$(sha256sum dist/bundle.js | cut -d' ' -f1)
    if [ "$EXPECTED_HASH" != "$ACTUAL_HASH" ]; then
      echo "Build output mismatch!"
      exit 1
    fi
```

### Isolated Build Environment

```yaml
# Use fresh environment
- uses: actions/checkout@v4
  with:
    clean: true

# Don't trust cached executables
- name: Clean rebuild
  run: |
    rm -rf node_modules
    npm ci
```

### Build-Time Secrets

```yaml
# ✅ Pass secrets at runtime, not build time
- name: Build
  run: docker build --secret id=api_key,src=/tmp/api_key .

# Dockerfile
RUN --mount=type=secret,id=api_key \
    API_KEY=$(cat /run/secrets/api_key) ./build.sh
```

## 4. Permission Management

### Least Privilege

```yaml
# GitHub Actions - Minimal permissions
permissions:
  contents: read
  
jobs:
  build:
    permissions:
      contents: read
      
  deploy:
    permissions:
      contents: read
      deployments: write
```

### Token Scoping

```yaml
# Use fine-grained PATs
# Settings → Developer settings → Fine-grained tokens

# OIDC instead of long-lived tokens
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/github-actions
    aws-region: us-east-1
    # No static credentials!
```

### Protected Branches

```yaml
# Require status checks
# Settings → Branches → Add rule
# ✓ Require status checks
# ✓ Require branches to be up to date
# ✓ Require signed commits
# ✓ Require approvals
```

## 5. Artifact Security

### Sign Artifacts

```yaml
# Sign container images
- name: Sign image
  uses: sigstore/cosign-installer@v3

- name: Sign
  run: |
    cosign sign --yes $IMAGE_URL@$IMAGE_DIGEST

# Verify signature
- name: Verify
  run: |
    cosign verify $IMAGE_URL
```

### Immutable Tags

```yaml
# Use SHA, not mutable tags
- name: Tag with SHA
  run: |
    docker tag myapp:latest myapp:${{ github.sha }}
    docker push myapp:${{ github.sha }}

# Prevent tag overwrites (registry setting)
```

### SBOM Generation

```yaml
# Generate Software Bill of Materials
- name: Generate SBOM
  uses: anchore/sbom-action@v0
  with:
    artifact-name: sbom.spdx.json
    
- name: Upload SBOM
  uses: actions/upload-artifact@v4
  with:
    name: sbom
    path: sbom.spdx.json
```

## 6. Pipeline Security

### Prevent Script Injection

```yaml
# ❌ Vulnerable to injection
- run: echo "${{ github.event.issue.title }}"

# ✅ Use environment variable
- run: echo "$TITLE"
  env:
    TITLE: ${{ github.event.issue.title }}
```

### Pull Request Safety

```yaml
# Don't run untrusted PR code with secrets
on:
  pull_request:
    # Secrets NOT available here for forked PRs
    
  pull_request_target:
    # Secrets available - DANGEROUS for untrusted PRs
    # Only use for labeling, commenting - not building PR code

# Safe pattern for PR checks
jobs:
  check:
    if: github.event.pull_request.head.repo.full_name == github.repository
    # Only runs for same-repo PRs
```

### Workflow Permissions

```yaml
# Prevent workflow modifications
# Settings → Actions → General → Workflow permissions
# ✓ Read repository contents
# ✗ Allow GitHub Actions to create PRs
```

## 7. Runtime Security

### Container Security

```yaml
# Scan containers
- name: Scan image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:${{ github.sha }}
    exit-code: '1'
    severity: 'CRITICAL,HIGH'

# Use minimal base images
FROM gcr.io/distroless/nodejs:18
# Instead of
FROM node:18
```

### Non-Root Containers

```dockerfile
# Dockerfile
FROM node:20-alpine

# Create non-root user
RUN addgroup -g 1001 app && \
    adduser -u 1001 -G app -s /bin/sh -D app

WORKDIR /app
COPY --chown=app:app . .

USER app
CMD ["node", "server.js"]
```

## 8. Monitoring and Audit

### Pipeline Audit Logging

```yaml
# Log all deployments
- name: Log deployment
  run: |
    curl -X POST $AUDIT_WEBHOOK \
      -H "Content-Type: application/json" \
      -d '{
        "event": "deployment",
        "sha": "${{ github.sha }}",
        "actor": "${{ github.actor }}",
        "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
      }'
```

### Security Scanning in Pipeline

```yaml
jobs:
  security:
    steps:
      # SAST
      - uses: github/codeql-action/init@v2
      - uses: github/codeql-action/analyze@v2
      
      # Secrets scanning
      - uses: trufflesecurity/trufflehog@main
        with:
          extra_args: --only-verified
      
      # Dependency scanning
      - run: npm audit --audit-level=high
```

## Security Checklist

### Secrets
- [ ] No hardcoded secrets in code/config
- [ ] Secrets stored in platform secret store
- [ ] Secrets scoped to minimum required
- [ ] Secrets masked in logs
- [ ] Rotation procedure documented

### Dependencies
- [ ] All actions/images pinned to SHA
- [ ] Lock files committed
- [ ] Dependency scanning enabled
- [ ] Regular dependency updates
- [ ] SBOM generated

### Permissions
- [ ] Minimal permissions declared
- [ ] OIDC used instead of static tokens
- [ ] Protected branches configured
- [ ] Required reviews enabled
- [ ] Signed commits required

### Build Process
- [ ] Reproducible builds
- [ ] Build environment isolated
- [ ] Artifacts signed
- [ ] Container scanning enabled
- [ ] Non-root containers

### Pipeline
- [ ] Script injection prevented
- [ ] PR security considered
- [ ] Audit logging enabled
- [ ] Alert on security findings

## Quick Security Audit

```bash
#!/bin/bash
# security-audit.sh

echo "=== CI/CD Security Audit ==="

# Check for hardcoded secrets
echo "Checking for potential secrets..."
grep -r "password\|secret\|api_key\|token" .github/ --include="*.yml" | \
  grep -v "\${{" | grep -v "#" || echo "✓ No obvious hardcoded secrets"

# Check for unpinned actions
echo "Checking for unpinned actions..."
grep "uses:" .github/workflows/*.yml | \
  grep -v "@[a-f0-9]\{40\}" | \
  grep -v "@v[0-9]" || echo "⚠ Some actions may be unpinned"

# Check permissions
echo "Checking permissions..."
grep -l "permissions:" .github/workflows/*.yml > /dev/null && \
  echo "✓ Permissions declared" || \
  echo "⚠ No explicit permissions (using defaults)"

# Check for dangerous patterns
echo "Checking for injection risks..."
grep -r "\${{ github.event" .github/workflows/*.yml | \
  grep "run:" && echo "⚠ Potential injection risk" || \
  echo "✓ No obvious injection risks"

echo "=== Audit Complete ==="
```

## Resources

- [OWASP CI/CD Security](https://owasp.org/www-project-top-10-ci-cd-security-risks/)
- [GitHub Security Hardening](https://docs.github.com/en/actions/security-guides)
- [SLSA Framework](https://slsa.dev/)
- [Sigstore](https://www.sigstore.dev/)
