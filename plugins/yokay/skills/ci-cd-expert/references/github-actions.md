# GitHub Actions Reference

Comprehensive GitHub Actions patterns and syntax.

## Workflow Structure

```yaml
name: CI                          # Workflow name (displayed in UI)

on:                               # Triggers
  push:
    branches: [main, develop]
    paths:
      - 'src/**'
      - 'package.json'
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * *'           # Daily at 2 AM UTC
  workflow_dispatch:              # Manual trigger
    inputs:
      environment:
        description: 'Target environment'
        required: true
        default: 'staging'
        type: choice
        options:
          - staging
          - production

env:                              # Workflow-level env vars
  NODE_VERSION: '20'

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      version: ${{ steps.version.outputs.version }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set version
        id: version
        run: echo "version=$(cat VERSION)" >> $GITHUB_OUTPUT
```

## Trigger Patterns

### Branch Filtering
```yaml
on:
  push:
    branches:
      - main
      - 'release/**'        # Glob pattern
      - '!release/**-beta'  # Exclude pattern
    branches-ignore:
      - 'feature/**'
```

### Path Filtering
```yaml
on:
  push:
    paths:
      - 'src/**'
      - '!src/**/*.test.ts'  # Ignore test files
    paths-ignore:
      - '**.md'
      - 'docs/**'
```

### Tag Triggers
```yaml
on:
  push:
    tags:
      - 'v*.*.*'            # Semantic versions
      - 'v[0-9]+.[0-9]+.[0-9]+'  # More precise
```

### Pull Request Events
```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
  pull_request_target:       # For fork PRs (careful with secrets!)
    types: [opened]
```

### Manual Dispatch with Inputs
```yaml
on:
  workflow_dispatch:
    inputs:
      deploy_env:
        description: 'Environment to deploy'
        required: true
        type: environment
      debug_enabled:
        description: 'Enable debug logging'
        type: boolean
        default: false
```

## Job Configuration

### Runner Selection
```yaml
jobs:
  linux:
    runs-on: ubuntu-latest       # Latest Ubuntu LTS
  macos:
    runs-on: macos-latest        # Latest macOS
  windows:
    runs-on: windows-latest      # Latest Windows
  self-hosted:
    runs-on: [self-hosted, linux, x64]
  large-runner:
    runs-on: ubuntu-latest-4-cores  # Larger runners (paid)
```

### Job Dependencies
```yaml
jobs:
  build:
    runs-on: ubuntu-latest
    
  test:
    needs: build                  # Wait for build
    runs-on: ubuntu-latest
    
  deploy:
    needs: [build, test]          # Wait for both
    runs-on: ubuntu-latest
```

### Conditional Execution
```yaml
jobs:
  deploy:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    
  notify:
    if: always()                  # Run even if previous failed
    
  skip-drafts:
    if: github.event.pull_request.draft == false
```

### Matrix Builds
```yaml
jobs:
  test:
    strategy:
      matrix:
        node: [18, 20, 22]
        os: [ubuntu-latest, windows-latest]
        include:
          - node: 20
            os: ubuntu-latest
            coverage: true
        exclude:
          - node: 18
            os: windows-latest
      fail-fast: false           # Don't cancel others on failure
      max-parallel: 4            # Limit concurrent jobs
    
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node }}
      
      - run: npm test
      
      - if: matrix.coverage
        run: npm run coverage
```

## Step Patterns

### Checkout Options
```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0               # Full history (for versioning)
    submodules: recursive        # Include submodules
    token: ${{ secrets.PAT }}    # For private submodules
    ref: ${{ github.head_ref }}  # PR branch
```

### Caching
```yaml
# Node.js
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: npm-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      npm-${{ runner.os }}-

# Multiple paths
- uses: actions/cache@v4
  with:
    path: |
      ~/.npm
      node_modules
      .next/cache
    key: deps-${{ hashFiles('**/package-lock.json') }}
```

### Artifacts
```yaml
# Upload
- uses: actions/upload-artifact@v4
  with:
    name: build-output
    path: |
      dist/
      !dist/**/*.map
    retention-days: 5
    if-no-files-found: error

# Download
- uses: actions/download-artifact@v4
  with:
    name: build-output
    path: ./dist
```

### Environment Variables
```yaml
steps:
  - name: Set env from file
    run: |
      echo "VERSION=$(cat VERSION)" >> $GITHUB_ENV
      echo "BUILD_TIME=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> $GITHUB_ENV
  
  - name: Use env
    run: echo "Building version $VERSION at $BUILD_TIME"
```

### Outputs Between Steps
```yaml
steps:
  - name: Generate output
    id: generate
    run: |
      echo "sha_short=$(git rev-parse --short HEAD)" >> $GITHUB_OUTPUT
      echo "version=1.2.3" >> $GITHUB_OUTPUT

  - name: Use output
    run: echo "SHA: ${{ steps.generate.outputs.sha_short }}"
```

### Multi-line Scripts
```yaml
- name: Complex script
  run: |
    set -euo pipefail
    
    echo "Step 1: Building..."
    npm run build
    
    echo "Step 2: Testing..."
    npm test
  shell: bash
```

## Services (Databases, etc.)

```yaml
jobs:
  test:
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: testdb
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:7-alpine
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
    
    steps:
      - run: npm test
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/testdb
          REDIS_URL: redis://localhost:6379
```

## Reusable Workflows

### Defining a Reusable Workflow
```yaml
# .github/workflows/reusable-deploy.yml
name: Reusable Deploy

on:
  workflow_call:
    inputs:
      environment:
        required: true
        type: string
      version:
        required: true
        type: string
    secrets:
      deploy_token:
        required: true
    outputs:
      deployed_url:
        value: ${{ jobs.deploy.outputs.url }}

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    outputs:
      url: ${{ steps.deploy.outputs.url }}
    
    steps:
      - name: Deploy
        id: deploy
        run: |
          echo "Deploying ${{ inputs.version }} to ${{ inputs.environment }}"
          echo "url=https://${{ inputs.environment }}.example.com" >> $GITHUB_OUTPUT
```

### Calling a Reusable Workflow
```yaml
jobs:
  deploy-staging:
    uses: ./.github/workflows/reusable-deploy.yml
    with:
      environment: staging
      version: ${{ needs.build.outputs.version }}
    secrets:
      deploy_token: ${{ secrets.DEPLOY_TOKEN }}
```

## Composite Actions

```yaml
# .github/actions/setup-project/action.yml
name: Setup Project
description: Install dependencies and setup environment

inputs:
  node-version:
    description: Node.js version
    default: '20'

runs:
  using: composite
  steps:
    - uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
    
    - uses: actions/cache@v4
      with:
        path: node_modules
        key: deps-${{ hashFiles('package-lock.json') }}
    
    - run: npm ci
      shell: bash
```

## Environments and Deployments

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
    
    steps:
      - name: Deploy
        run: ./deploy.sh
        env:
          API_KEY: ${{ secrets.PROD_API_KEY }}
```

### Environment Protection Rules
Configure in repo Settings → Environments:
- Required reviewers
- Wait timer
- Branch restrictions
- Secret scoping

## Concurrency Control

```yaml
# Cancel in-progress runs for same ref
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true

# Or per-job
jobs:
  deploy:
    concurrency:
      group: deploy-${{ github.ref }}
      cancel-in-progress: false  # Queue instead
```

## Security Patterns

### Minimum Permissions
```yaml
permissions:
  contents: read
  
jobs:
  deploy:
    permissions:
      contents: read
      id-token: write          # For OIDC
```

### OIDC with Cloud Providers
```yaml
# AWS
- uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: arn:aws:iam::123456789:role/github-actions
    aws-region: us-east-1

# GCP
- uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: projects/123/locations/global/workloadIdentityPools/...
    service_account: sa@project.iam.gserviceaccount.com
```

### Pin Third-Party Actions
```yaml
# ❌ Mutable
uses: actions/checkout@main

# ✅ Pinned to commit SHA
uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```

## Common Actions

| Action | Purpose |
|--------|---------|
| `actions/checkout@v4` | Clone repo |
| `actions/setup-node@v4` | Setup Node.js |
| `actions/cache@v4` | Cache dependencies |
| `actions/upload-artifact@v4` | Upload build outputs |
| `actions/download-artifact@v4` | Download artifacts |
| `docker/build-push-action@v5` | Build/push Docker |
| `aws-actions/configure-aws-credentials@v4` | AWS auth |
| `google-github-actions/auth@v2` | GCP auth |
| `azure/login@v2` | Azure auth |

## Debugging

### Enable Debug Logging
Set repository secret `ACTIONS_STEP_DEBUG` to `true`.

### SSH Debug Session
```yaml
- uses: mxschmitt/action-tmate@v3
  if: failure()
  timeout-minutes: 15
```

### Print Context
```yaml
- name: Debug context
  run: |
    echo "Event: ${{ github.event_name }}"
    echo "Ref: ${{ github.ref }}"
    echo "SHA: ${{ github.sha }}"
    echo "Actor: ${{ github.actor }}"
    cat $GITHUB_EVENT_PATH | jq .
```

## Workflow Syntax Validation

```bash
# Install actionlint
brew install actionlint  # macOS
# Or download from: https://github.com/rhysd/actionlint

# Validate
actionlint .github/workflows/*.yml

# With specific checks
actionlint -ignore 'SC2086' .github/workflows/ci.yml
```

## Complete Example: Full CI/CD Pipeline

```yaml
name: CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

permissions:
  contents: read
  packages: write

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck

  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test
        ports: ['5432:5432']
        options: --health-cmd pg_isready --health-interval 10s
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      - run: npm ci
      - run: npm test -- --coverage
        env:
          DATABASE_URL: postgresql://postgres:test@localhost:5432/postgres
      - uses: codecov/codecov-action@v4

  build:
    needs: [lint, test]
    runs-on: ubuntu-latest
    outputs:
      tags: ${{ steps.meta.outputs.tags }}
    steps:
      - uses: actions/checkout@v4
      
      - uses: docker/setup-buildx-action@v3
      
      - uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - uses: docker/metadata-action@v5
        id: meta
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha,prefix=
            type=ref,event=branch
      
      - uses: docker/build-push-action@v5
        with:
          push: ${{ github.event_name == 'push' }}
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  deploy-staging:
    needs: build
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment:
      name: staging
      url: https://staging.example.com
    steps:
      - name: Deploy to staging
        run: |
          echo "Deploying ${{ needs.build.outputs.tags }}"

  deploy-production:
    needs: deploy-staging
    runs-on: ubuntu-latest
    environment:
      name: production
      url: https://example.com
    steps:
      - name: Deploy to production
        run: |
          echo "Deploying to production"
```
