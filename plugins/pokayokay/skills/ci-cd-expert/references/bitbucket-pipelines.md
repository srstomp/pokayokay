# Bitbucket Pipelines Reference

Comprehensive Bitbucket Pipelines patterns and syntax.

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
Configure in Repository Settings → Pipelines → Schedules

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
# Define in Repository Settings → Pipelines → Repository variables

- step:
    script:
      - echo "API Key is $API_KEY"
      - ./deploy.sh --token $DEPLOY_TOKEN
```

### Deployment Variables
```yaml
# Define in Repository Settings → Pipelines → Deployments

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

## Pipes

### Using Pipes
```yaml
- step:
    name: Deploy to S3
    script:
      - pipe: atlassian/aws-s3-deploy:1.1.0
        variables:
          AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
          AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
          AWS_DEFAULT_REGION: 'us-east-1'
          S3_BUCKET: 'my-bucket'
          LOCAL_PATH: 'dist'
```

### Common Pipes

| Pipe | Purpose |
|------|---------|
| `atlassian/aws-s3-deploy` | Deploy to S3 |
| `atlassian/aws-ecs-deploy` | Deploy to ECS |
| `atlassian/aws-lambda-deploy` | Deploy Lambda |
| `atlassian/azure-web-apps-deploy` | Deploy to Azure |
| `atlassian/google-cloud-storage-deploy` | Deploy to GCS |
| `atlassian/slack-notify` | Slack notifications |
| `atlassian/jira-create-deploy` | Create Jira deployment |
| `atlassian/npm-publish` | Publish to npm |
| `docker/docker-buildx` | Build multi-platform images |

### Pipe with Debug
```yaml
- pipe: atlassian/aws-s3-deploy:1.1.0
  variables:
    DEBUG: 'true'
    AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
    # ...
```

## Deployments

### Deployment Environments
```yaml
- step:
    name: Deploy to Staging
    deployment: staging              # Environment name
    script:
      - ./deploy.sh staging

- step:
    name: Deploy to Production
    deployment: production
    trigger: manual
    script:
      - ./deploy.sh production
```

### Environment Configuration
Configure in Repository Settings → Pipelines → Deployments:
- Variables specific to environment
- Deployment restrictions
- Required approvers

## Docker

### Docker Build and Push
```yaml
- step:
    name: Build and Push
    services:
      - docker
    script:
      - docker build -t myimage:$BITBUCKET_COMMIT .
      - docker login -u $DOCKER_USER -p $DOCKER_PASSWORD
      - docker push myimage:$BITBUCKET_COMMIT

definitions:
  services:
    docker:
      memory: 2048
```

### Docker Compose
```yaml
- step:
    name: Integration Test
    services:
      - docker
    script:
      - docker-compose up -d
      - npm run test:integration
      - docker-compose down

definitions:
  services:
    docker:
      memory: 3072
```

## YAML Anchors

### Reusable Step Definitions
```yaml
definitions:
  steps:
    - step: &build-step
        name: Build
        caches:
          - node
        script:
          - npm ci
          - npm run build
        artifacts:
          - dist/**
    
    - step: &test-step
        name: Test
        caches:
          - node
        script:
          - npm ci
          - npm test

pipelines:
  default:
    - step: *build-step
    - step: *test-step
  
  branches:
    main:
      - step: *build-step
      - step: *test-step
      - step:
          name: Deploy
          deployment: production
          script:
            - ./deploy.sh
```

### Override Anchored Values
```yaml
definitions:
  steps:
    - step: &base-step
        image: node:20
        caches:
          - node
        script:
          - npm ci

pipelines:
  default:
    - step:
        <<: *base-step
        name: Custom Build
        script:
          - npm ci
          - npm run build          # Override script
```

## Clone Options

```yaml
clone:
  enabled: true                    # Can disable for deploy-only steps
  depth: 50                        # Shallow clone (default: full)
  lfs: true                        # Enable Git LFS

pipelines:
  default:
    - step:
        script:
          - echo "Full repo available"
```

### Skip Clone
```yaml
- step:
    name: Notify
    clone:
      enabled: false
    script:
      - pipe: atlassian/slack-notify:2.0.0
        variables:
          WEBHOOK_URL: $SLACK_WEBHOOK
          MESSAGE: 'Deployment complete!'
```

## Fail-Fast and Max Time

```yaml
options:
  max-time: 60                     # Pipeline timeout (minutes)

pipelines:
  default:
    - parallel:
        fail-fast: true            # Stop all on first failure
        steps:
          - step:
              name: Test A
              script:
                - npm run test:a
          - step:
              name: Test B
              script:
                - npm run test:b
```

## Complete Example

```yaml
image: node:20

options:
  max-time: 60

definitions:
  caches:
    npm: ~/.npm
  
  services:
    postgres:
      image: postgres:15
      variables:
        POSTGRES_USER: test
        POSTGRES_PASSWORD: test
        POSTGRES_DB: testdb
    redis:
      image: redis:7
    docker:
      memory: 2048
  
  steps:
    - step: &install
        name: Install Dependencies
        caches:
          - npm
          - node
        script:
          - npm ci
    
    - step: &lint
        name: Lint
        caches:
          - node
        script:
          - npm run lint
    
    - step: &test
        name: Unit Tests
        caches:
          - node
        script:
          - npm test -- --coverage
        artifacts:
          - coverage/**
    
    - step: &build
        name: Build
        caches:
          - node
        script:
          - npm run build
        artifacts:
          - dist/**

pipelines:
  default:
    - step: *install
    - parallel:
        - step: *lint
        - step: *test
    - step: *build
  
  pull-requests:
    '**':
      - step: *install
      - parallel:
          fail-fast: true
          steps:
            - step: *lint
            - step: *test
      - step: *build
  
  branches:
    main:
      - step: *install
      - parallel:
          - step: *lint
          - step: *test
      - step: *build
      - step:
          name: Integration Tests
          size: 2x
          services:
            - postgres
            - redis
          script:
            - npm ci
            - npm run test:integration
          artifacts:
            - test-results/**
      - step:
          name: Build Docker Image
          services:
            - docker
          script:
            - docker build -t myapp:$BITBUCKET_COMMIT .
            - docker login -u $DOCKER_USER -p $DOCKER_PASSWORD
            - docker push myapp:$BITBUCKET_COMMIT
      - step:
          name: Deploy to Staging
          deployment: staging
          script:
            - pipe: atlassian/aws-ecs-deploy:2.0.0
              variables:
                AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
                AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
                AWS_DEFAULT_REGION: $AWS_REGION
                CLUSTER_NAME: 'staging-cluster'
                SERVICE_NAME: 'myapp-staging'
                TASK_DEFINITION: 'task-definition.json'
      - step:
          name: Deploy to Production
          deployment: production
          trigger: manual
          script:
            - pipe: atlassian/aws-ecs-deploy:2.0.0
              variables:
                AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID
                AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY
                AWS_DEFAULT_REGION: $AWS_REGION
                CLUSTER_NAME: 'production-cluster'
                SERVICE_NAME: 'myapp'
                TASK_DEFINITION: 'task-definition.json'
  
  tags:
    'v*.*.*':
      - step: *install
      - step: *build
      - step:
          name: Publish to npm
          script:
            - pipe: atlassian/npm-publish:0.3.0
              variables:
                NPM_TOKEN: $NPM_TOKEN
  
  custom:
    run-all-tests:
      - step: *install
      - parallel:
          - step: *lint
          - step: *test
          - step:
              name: Integration Tests
              size: 2x
              services:
                - postgres
                - redis
              script:
                - npm ci
                - npm run test:integration
```

## Validation

```bash
# Use Bitbucket's online validator
# Repository → Pipelines → ... → Validate bitbucket-pipelines.yml

# Or use the REST API
curl -X POST \
  -u "$BB_USER:$BB_APP_PASSWORD" \
  -H "Content-Type: application/json" \
  -d @bitbucket-pipelines.yml \
  "https://api.bitbucket.org/2.0/repositories/$WORKSPACE/$REPO/pipelines/validate"
```
