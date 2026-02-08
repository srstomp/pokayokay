# GitHub Actions: Workflows, Triggers, Jobs, and Steps

Workflow structure, trigger patterns, job configuration, step patterns, and services.

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
