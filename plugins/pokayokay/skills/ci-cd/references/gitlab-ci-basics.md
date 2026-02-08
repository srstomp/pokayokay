# GitLab CI: Pipeline Structure and Configuration

Pipeline structure, triggers, job configuration, caching, artifacts, services, environments, and variables.

## Pipeline Structure

```yaml
# .gitlab-ci.yml

# Define stages (execution order)
stages:
  - build
  - test
  - deploy

# Global defaults
default:
  image: node:20-alpine
  before_script:
    - npm ci --cache .npm --prefer-offline
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - .npm/
      - node_modules/

# Variables
variables:
  NODE_ENV: production
  FF_USE_FASTZIP: "true"

# Jobs
build:
  stage: build
  script:
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 week
```

## Pipeline Triggers

### Branch/Tag Rules
```yaml
job:
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_TAG
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_PIPELINE_SOURCE == "web"        # Manual trigger
    - if: $CI_PIPELINE_SOURCE == "schedule"
```

### Path-Based Rules
```yaml
job:
  rules:
    - changes:
        - src/**/*
        - package.json
      when: always
    - when: never
```

### Legacy only/except (deprecated but common)
```yaml
job:
  only:
    - main
    - /^release-.*$/
  except:
    - schedules
```

### Merge Request Pipelines
```yaml
workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH && $CI_OPEN_MERGE_REQUESTS
      when: never
    - if: $CI_COMMIT_BRANCH
```

## Job Configuration

### Script Types
```yaml
job:
  before_script:
    - echo "Runs before main script"
  script:
    - echo "Main job commands"
    - npm test
  after_script:
    - echo "Always runs (even on failure)"
```

### Job Dependencies
```yaml
stages:
  - build
  - test
  - deploy

build:
  stage: build
  script: npm run build
  artifacts:
    paths: [dist/]

test:
  stage: test
  needs: [build]              # Download artifacts from build
  script: npm test

deploy:
  stage: deploy
  needs:
    - job: build
      artifacts: true
    - job: test
      artifacts: false        # Don't need test artifacts
```

### Parallel Jobs
```yaml
test:
  stage: test
  parallel: 4
  script:
    - npm test -- --shard=$CI_NODE_INDEX/$CI_NODE_TOTAL
```

### Matrix Builds
```yaml
test:
  stage: test
  parallel:
    matrix:
      - NODE_VERSION: ["18", "20", "22"]
        RUNNER: [linux, macos]
  image: node:${NODE_VERSION}
  tags: [$RUNNER]
  script: npm test
```

## Caching

### Basic Cache
```yaml
job:
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
      - .npm/
```

### Cache Policies
```yaml
# Only pull cache, don't update
job:
  cache:
    key: deps-$CI_COMMIT_REF_SLUG
    paths: [node_modules/]
    policy: pull

# Only push cache (use in dedicated job)
cache-warmer:
  cache:
    key: deps-main
    paths: [node_modules/]
    policy: push
  script: npm ci
```

### Multiple Caches
```yaml
job:
  cache:
    - key: npm-$CI_COMMIT_REF_SLUG
      paths: [node_modules/]
    - key: build-$CI_COMMIT_SHORT_SHA
      paths: [.next/cache/]
```

### Fallback Keys
```yaml
job:
  cache:
    key: npm-${CI_COMMIT_REF_SLUG}
    paths: [node_modules/]
    fallback_keys:
      - npm-main
      - npm-default
```

## Artifacts

```yaml
build:
  script: npm run build
  artifacts:
    paths:
      - dist/
      - coverage/
    exclude:
      - "**/*.map"
    expire_in: 1 week
    when: always              # Keep even on failure
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura.xml
```

## Services (Databases, etc.)

```yaml
test:
  services:
    - name: postgres:15
      alias: db
      variables:
        POSTGRES_USER: test
        POSTGRES_PASSWORD: test
        POSTGRES_DB: testdb
    - name: redis:7-alpine
  variables:
    DATABASE_URL: postgresql://test:test@db:5432/testdb
    REDIS_URL: redis://redis:6379
  script: npm test
```

## Environments and Deployments

```yaml
deploy_staging:
  stage: deploy
  environment:
    name: staging
    url: https://staging.example.com
    on_stop: stop_staging
  script: ./deploy.sh staging

stop_staging:
  stage: deploy
  environment:
    name: staging
    action: stop
  script: ./teardown.sh staging
  when: manual
  rules:
    - if: $CI_COMMIT_BRANCH
```

### Dynamic Environments
```yaml
deploy_review:
  stage: deploy
  environment:
    name: review/$CI_COMMIT_REF_SLUG
    url: https://$CI_COMMIT_REF_SLUG.review.example.com
    auto_stop_in: 1 week
  script: ./deploy-review.sh
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
```

## Variables

### Predefined Variables
```yaml
job:
  script:
    - echo "Project: $CI_PROJECT_NAME"
    - echo "Branch: $CI_COMMIT_BRANCH"
    - echo "SHA: $CI_COMMIT_SHA"
    - echo "Short SHA: $CI_COMMIT_SHORT_SHA"
    - echo "Tag: $CI_COMMIT_TAG"
    - echo "MR IID: $CI_MERGE_REQUEST_IID"
    - echo "Pipeline ID: $CI_PIPELINE_ID"
    - echo "Job ID: $CI_JOB_ID"
```

### Variable Scopes
```yaml
variables:
  GLOBAL_VAR: "available everywhere"

job1:
  variables:
    JOB_VAR: "only in this job"
  script:
    - echo "$GLOBAL_VAR $JOB_VAR"
```

### Protected and Masked Variables
Configure in Settings > CI/CD > Variables:
- **Protected**: Only available on protected branches
- **Masked**: Hidden in logs

### Variable Expansion
```yaml
variables:
  BASE_URL: "https://api.example.com"
  FULL_URL: "$BASE_URL/v1"        # Expands to https://api.example.com/v1
```
