# Bitbucket Pipelines: Structure and Configuration

Pipeline structure, types, steps, caching, artifacts, and variables.

## Pipeline Structure

```yaml
# bitbucket-pipelines.yml
image: node:20

definitions:
  caches:
    npm: ~/.npm

  steps:
    - step: &build-step
        name: Build
        caches:
          - npm
          - node
        script:
          - npm ci
          - npm run build
        artifacts:
          - dist/**

pipelines:
  default:
    - step: *build-step
```

## Pipeline Types

### Default Pipeline
```yaml
pipelines:
  default:
    - step:
        name: Build and Test
        script:
          - npm ci
          - npm test
```

### Branch Pipelines
```yaml
pipelines:
  branches:
    main:
      - step:
          name: Build
          script:
            - npm run build
      - step:
          name: Deploy to Production
          deployment: production
          script:
            - ./deploy.sh prod

    'feature/*':
      - step:
          name: Build and Test
          script:
            - npm ci
            - npm test

    '{staging,develop}':
      - step:
          name: Deploy to Staging
          deployment: staging
          script:
            - ./deploy.sh staging
```

### Pull Request Pipelines
```yaml
pipelines:
  pull-requests:
    '**':
      - step:
          name: Build and Test
          script:
            - npm ci
            - npm test
            - npm run lint

    'feature/*':
      - step:
          name: Feature PR Checks
          script:
            - npm ci
            - npm test
```

### Tag Pipelines
```yaml
pipelines:
  tags:
    'v*':
      - step:
          name: Build Release
          script:
            - npm run build
      - step:
          name: Publish
          script:
            - npm publish

    'v*.*.*':
      - step:
          name: Semantic Version Release
          script:
            - ./release.sh
```

### Custom Pipelines (Manual)
```yaml
pipelines:
  custom:
    deploy-to-staging:
      - step:
          name: Deploy Staging
          deployment: staging
          script:
            - ./deploy.sh staging

    full-integration-test:
      - step:
          name: Integration Tests
          size: 2x
          script:
            - npm run test:integration
```

### Scheduled Pipelines
Configure in Repository Settings > Pipelines > Schedules

## Steps

### Basic Step
```yaml
- step:
    name: Build
    image: node:20                  # Optional: override default image
    script:
      - npm ci
      - npm run build
    artifacts:
      - dist/**
```

### Step with Services
```yaml
- step:
    name: Integration Tests
    services:
      - postgres
      - redis
    script:
      - npm ci
      - npm run test:integration

definitions:
  services:
    postgres:
      image: postgres:15
      variables:
        POSTGRES_USER: test
        POSTGRES_PASSWORD: test
        POSTGRES_DB: testdb
    redis:
      image: redis:7
```

### Parallel Steps
```yaml
- parallel:
    - step:
        name: Lint
        script:
          - npm run lint
    - step:
        name: Unit Tests
        script:
          - npm test
    - step:
        name: Type Check
        script:
          - npm run typecheck
```

### Step Size (Resources)
```yaml
- step:
    name: Heavy Build
    size: 2x                        # Double memory (8GB vs 4GB)
    script:
      - npm run build
```

Available sizes:
- `1x` (default): 4GB memory
- `2x`: 8GB memory
- `4x`: 16GB memory (Premium only)
- `8x`: 32GB memory (Premium only)

### Manual Steps
```yaml
- step:
    name: Deploy Production
    trigger: manual
    deployment: production
    script:
      - ./deploy.sh production
```

### Conditional Steps
```yaml
- step:
    name: Deploy
    script:
      - ./deploy.sh
    condition:
      changesets:
        includePaths:
          - "src/**"
          - "package.json"
```

## Caching

### Built-in Caches
```yaml
- step:
    caches:
      - node                        # node_modules
      - npm                         # ~/.npm
      - pip                         # ~/.cache/pip
      - maven                       # ~/.m2/repository
      - gradle                      # ~/.gradle/caches
      - composer                    # ~/.composer/cache
      - docker                      # Docker layer cache
```

### Custom Caches
```yaml
definitions:
  caches:
    custom-cache: ./path/to/cache
    build-cache: dist

pipelines:
  default:
    - step:
        caches:
          - custom-cache
          - build-cache
        script:
          - npm run build
```

## Artifacts

### Publish Artifacts
```yaml
- step:
    name: Build
    script:
      - npm run build
    artifacts:
      - dist/**
      - '*.zip'
```

### Download Artifacts (Automatic)
```yaml
pipelines:
  default:
    - step:
        name: Build
        artifacts:
          - dist/**
        script:
          - npm run build
    - step:
        name: Deploy
        # Automatically has access to dist/**
        script:
          - ls dist/
          - ./deploy.sh
```

### Artifacts with Parallel Steps
```yaml
- parallel:
    - step:
        name: Build A
        artifacts:
          - build-a/**
        script:
          - mkdir build-a
          - npm run build:a
    - step:
        name: Build B
        artifacts:
          - build-b/**
        script:
          - mkdir build-b
          - npm run build:b

- step:
    name: Combine
    # Has access to both build-a/** and build-b/**
    script:
      - ls build-a build-b
```

## Variables

### Repository Variables
```yaml
# Define in Repository Settings > Pipelines > Repository variables

- step:
    script:
      - echo "API Key is $API_KEY"
      - ./deploy.sh --token $DEPLOY_TOKEN
```

### Deployment Variables
```yaml
# Define in Repository Settings > Pipelines > Deployments

- step:
    deployment: production
    script:
      - echo "Prod URL: $PROD_URL"
```

### Secured Variables
Mark as "Secured" in UI - won't be printed in logs.

### Predefined Variables
```yaml
- step:
    script:
      - echo "Repo: $BITBUCKET_REPO_SLUG"
      - echo "Branch: $BITBUCKET_BRANCH"
      - echo "Commit: $BITBUCKET_COMMIT"
      - echo "Tag: $BITBUCKET_TAG"
      - echo "PR ID: $BITBUCKET_PR_ID"
      - echo "Build Number: $BITBUCKET_BUILD_NUMBER"
      - echo "Clone Dir: $BITBUCKET_CLONE_DIR"
```
