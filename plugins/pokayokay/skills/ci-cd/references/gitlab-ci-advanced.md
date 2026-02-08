# GitLab CI: Templates, Rules, and Advanced Patterns

Includes, templates, runners, rules, manual jobs, Docker-in-Docker, security scanning, and complete examples.

## Includes and Templates

### Include Types
```yaml
include:
  # Local file
  - local: '/.gitlab/ci/build.yml'

  # From another project
  - project: 'group/project'
    file: '/templates/ci.yml'
    ref: main

  # Remote URL
  - remote: 'https://example.com/ci-template.yml'

  # Template from GitLab
  - template: Security/SAST.gitlab-ci.yml
```

### Extending Jobs
```yaml
.base_job:
  image: node:20
  before_script:
    - npm ci

build:
  extends: .base_job
  script: npm run build

test:
  extends: .base_job
  script: npm test
```

### Reference and Override
```yaml
.defaults:
  image: node:20
  cache:
    paths: [node_modules/]

job:
  extends: .defaults
  script: npm test
  cache:
    !reference [.defaults, cache]
    policy: pull               # Add to referenced config
```

## Runners and Tags

```yaml
job:
  tags:
    - linux
    - docker
    - high-memory

# Specific runner
gpu_job:
  tags:
    - gpu
    - cuda
```

## Rules and Conditions

### Complex Rules
```yaml
job:
  rules:
    # Run on main branch pushes
    - if: $CI_COMMIT_BRANCH == "main"
      when: always

    # Run on tags
    - if: $CI_COMMIT_TAG
      when: always

    # Run on MRs, but only manual
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
      when: manual
      allow_failure: true

    # Never run otherwise
    - when: never
```

### Workflow Rules (Pipeline-Level)
```yaml
workflow:
  rules:
    - if: $CI_COMMIT_MESSAGE =~ /\[skip ci\]/
      when: never
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"
    - when: never
```

## Manual Jobs and Gates

```yaml
deploy_prod:
  stage: deploy
  script: ./deploy.sh production
  when: manual
  allow_failure: false         # Pipeline waits for manual action

  # Add protection
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
      when: manual
```

## Retry and Timeout

```yaml
job:
  script: ./flaky-test.sh
  retry:
    max: 2
    when:
      - runner_system_failure
      - stuck_or_timeout_failure
      - script_failure
  timeout: 30 minutes
```

## Docker-in-Docker

```yaml
build_image:
  image: docker:24
  services:
    - docker:24-dind
  variables:
    DOCKER_TLS_CERTDIR: "/certs"
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
```

## Security Scanning (Built-in Templates)

```yaml
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml
  - template: Security/Dependency-Scanning.gitlab-ci.yml
  - template: Security/Container-Scanning.gitlab-ci.yml

# Override settings
sast:
  variables:
    SAST_EXCLUDED_PATHS: "spec, test, tests"
```

## Auto DevOps

Enable in Settings > CI/CD > Auto DevOps for automatic:
- Build
- Test
- Code Quality
- SAST/DAST
- Container Scanning
- Deploy to Kubernetes

## Debugging

### Debug Mode
```yaml
job:
  variables:
    CI_DEBUG_TRACE: "true"    # Verbose output
  script: ./script.sh
```

### Interactive Debug Session
Enable in Settings > CI/CD > General pipelines > Enable Debug logging

## Complete Example: Full Pipeline

```yaml
stages:
  - build
  - test
  - security
  - deploy

default:
  image: node:20-alpine
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
      - .npm/

variables:
  npm_config_cache: ".npm"

workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == "main"
    - if: $CI_COMMIT_TAG

# Build
build:
  stage: build
  script:
    - npm ci
    - npm run build
  artifacts:
    paths:
      - dist/
    expire_in: 1 day

# Tests
lint:
  stage: test
  script:
    - npm ci
    - npm run lint

unit_test:
  stage: test
  script:
    - npm ci
    - npm test -- --coverage
  coverage: '/Lines\s*:\s*(\d+\.?\d*)%/'
  artifacts:
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage/cobertura.xml

integration_test:
  stage: test
  services:
    - postgres:15
  variables:
    POSTGRES_DB: test
    POSTGRES_USER: test
    POSTGRES_PASSWORD: test
    DATABASE_URL: postgresql://test:test@postgres:5432/test
  script:
    - npm ci
    - npm run test:integration

# Security
include:
  - template: Security/SAST.gitlab-ci.yml
  - template: Security/Secret-Detection.gitlab-ci.yml

# Deploy
deploy_staging:
  stage: deploy
  environment:
    name: staging
    url: https://staging.example.com
  script:
    - ./deploy.sh staging
  rules:
    - if: $CI_COMMIT_BRANCH == "main"

deploy_production:
  stage: deploy
  environment:
    name: production
    url: https://example.com
  script:
    - ./deploy.sh production
  rules:
    - if: $CI_COMMIT_TAG
  when: manual
```

## Validation

```bash
# Validate .gitlab-ci.yml syntax
# In GitLab: CI/CD > Editor > Validate

# Using the API
curl --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  --header "Content-Type: application/json" \
  "$GITLAB_URL/api/v4/ci/lint" \
  --data '{"content": "'"$(cat .gitlab-ci.yml)"'"}'
```
