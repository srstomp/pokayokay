# CircleCI Reference

Comprehensive CircleCI patterns and syntax.

## Config Structure

```yaml
# .circleci/config.yml
version: 2.1

# Reusable commands
commands:
  install_deps:
    description: Install npm dependencies
    steps:
      - restore_cache:
          keys:
            - deps-{{ checksum "package-lock.json" }}
      - run: npm ci
      - save_cache:
          key: deps-{{ checksum "package-lock.json" }}
          paths:
            - node_modules

# Reusable executors
executors:
  node:
    docker:
      - image: cimg/node:20.10

# Jobs
jobs:
  build:
    executor: node
    steps:
      - checkout
      - install_deps
      - run: npm run build

# Workflows
workflows:
  main:
    jobs:
      - build
```

## Executors

### Docker Executor
```yaml
executors:
  node:
    docker:
      - image: cimg/node:20.10
        auth:
          username: $DOCKERHUB_USER
          password: $DOCKERHUB_PASSWORD
    working_directory: ~/project
    resource_class: medium
```

### Machine Executor
```yaml
executors:
  linux:
    machine:
      image: ubuntu-2204:current
    resource_class: medium
```

### macOS Executor
```yaml
executors:
  macos:
    macos:
      xcode: "15.0"
    resource_class: macos.m1.medium.gen1
```

### Windows Executor
```yaml
executors:
  windows:
    machine:
      image: windows-server-2022-gui:current
    resource_class: windows.medium
    shell: powershell.exe -ExecutionPolicy Bypass
```

### Resource Classes
```yaml
# Docker resource classes
resource_class: small      # 1 CPU, 2GB RAM
resource_class: medium     # 2 CPU, 4GB RAM (default)
resource_class: medium+    # 3 CPU, 6GB RAM
resource_class: large      # 4 CPU, 8GB RAM
resource_class: xlarge     # 8 CPU, 16GB RAM
resource_class: 2xlarge    # 16 CPU, 32GB RAM
```

## Jobs

### Basic Job
```yaml
jobs:
  test:
    docker:
      - image: cimg/node:20.10
    steps:
      - checkout
      - run:
          name: Install dependencies
          command: npm ci
      - run:
          name: Run tests
          command: npm test
```

### Job with Services
```yaml
jobs:
  integration_test:
    docker:
      - image: cimg/node:20.10
      - image: cimg/postgres:15.0
        environment:
          POSTGRES_USER: test
          POSTGRES_DB: test_db
          POSTGRES_PASSWORD: test
      - image: cimg/redis:7.0
    steps:
      - checkout
      - run:
          name: Wait for DB
          command: dockerize -wait tcp://localhost:5432 -timeout 1m
      - run:
          name: Run tests
          command: npm test
          environment:
            DATABASE_URL: postgresql://test:test@localhost:5432/test_db
            REDIS_URL: redis://localhost:6379
```

### Parallelism
```yaml
jobs:
  test:
    parallelism: 4
    docker:
      - image: cimg/node:20.10
    steps:
      - checkout
      - run:
          name: Split tests
          command: |
            circleci tests glob "tests/**/*.test.ts" | \
            circleci tests split --split-by=timings | \
            xargs npm test --
```

## Commands (Reusable Steps)

```yaml
commands:
  setup:
    description: Setup project
    parameters:
      node_version:
        type: string
        default: "20"
    steps:
      - checkout
      - run:
          name: Install Node << parameters.node_version >>
          command: |
            curl -fsSL https://deb.nodesource.com/setup_<< parameters.node_version >>.x | sudo -E bash -
            sudo apt-get install -y nodejs
      - restore_cache:
          keys:
            - deps-v1-{{ checksum "package-lock.json" }}
      - run: npm ci
      - save_cache:
          key: deps-v1-{{ checksum "package-lock.json" }}
          paths:
            - node_modules

jobs:
  build:
    docker:
      - image: cimg/base:current
    steps:
      - setup:
          node_version: "20"
      - run: npm run build
```

## Caching

### Basic Cache
```yaml
steps:
  - restore_cache:
      keys:
        - deps-v1-{{ checksum "package-lock.json" }}
        - deps-v1-
  
  - run: npm ci
  
  - save_cache:
      key: deps-v1-{{ checksum "package-lock.json" }}
      paths:
        - node_modules
        - ~/.npm
```

### Multiple Caches
```yaml
steps:
  - restore_cache:
      name: Restore npm cache
      keys:
        - npm-v1-{{ checksum "package-lock.json" }}
  
  - restore_cache:
      name: Restore build cache
      keys:
        - build-v1-{{ .Branch }}-{{ checksum "src/**" }}
        - build-v1-{{ .Branch }}-
        - build-v1-
```

### Cache Key Templates
```yaml
# Available templates
{{ .Branch }}              # Current branch
{{ .Revision }}            # Git SHA
{{ checksum "file" }}      # File checksum
{{ epoch }}                # Unix timestamp
{{ arch }}                 # CPU architecture
```

## Artifacts and Workspaces

### Artifacts (Persist Beyond Job)
```yaml
jobs:
  build:
    steps:
      - run: npm run build
      - store_artifacts:
          path: dist
          destination: build-output
      - store_test_results:
          path: test-results
```

### Workspaces (Share Between Jobs)
```yaml
jobs:
  build:
    steps:
      - run: npm run build
      - persist_to_workspace:
          root: .
          paths:
            - dist
            - node_modules

  deploy:
    steps:
      - attach_workspace:
          at: .
      - run: ./deploy.sh
```

## Workflows

### Basic Workflow
```yaml
workflows:
  build-test-deploy:
    jobs:
      - build
      - test:
          requires:
            - build
      - deploy:
          requires:
            - test
```

### Branch Filters
```yaml
workflows:
  main:
    jobs:
      - build:
          filters:
            branches:
              only:
                - main
                - /feature\/.*/
              ignore:
                - /wip-.*/
      
      - deploy:
          filters:
            branches:
              only: main
            tags:
              only: /^v.*/
```

### Matrix Jobs
```yaml
jobs:
  test:
    parameters:
      node_version:
        type: string
      os:
        type: executor
    executor: << parameters.os >>
    steps:
      - run: echo "Testing on << parameters.os >> with Node << parameters.node_version >>"

workflows:
  test-matrix:
    jobs:
      - test:
          matrix:
            parameters:
              node_version: ["18", "20", "22"]
              os: [linux, macos]
```

### Scheduled Workflows
```yaml
workflows:
  nightly:
    triggers:
      - schedule:
          cron: "0 2 * * *"           # 2 AM UTC daily
          filters:
            branches:
              only: main
    jobs:
      - build
      - integration_test
```

### Manual Approval
```yaml
workflows:
  deploy:
    jobs:
      - build
      - test
      - hold_for_approval:
          type: approval
          requires:
            - test
      - deploy_production:
          requires:
            - hold_for_approval
```

## Orbs

### Using Orbs
```yaml
version: 2.1

orbs:
  node: circleci/node@5.1.0
  aws-cli: circleci/aws-cli@4.1.0
  docker: circleci/docker@2.4.0
  slack: circleci/slack@4.12.5

jobs:
  build:
    executor: node/default
    steps:
      - checkout
      - node/install-packages
      - run: npm run build
```

### Common Orbs

| Orb | Purpose |
|-----|---------|
| `circleci/node` | Node.js setup, caching |
| `circleci/python` | Python setup, pip caching |
| `circleci/docker` | Docker build/push |
| `circleci/aws-cli` | AWS CLI setup |
| `circleci/gcp-cli` | GCP CLI setup |
| `circleci/slack` | Slack notifications |
| `circleci/browser-tools` | Chrome/Firefox for E2E |

### Orb Commands
```yaml
orbs:
  node: circleci/node@5.1.0

jobs:
  test:
    executor: node/default
    steps:
      - checkout
      - node/install-packages:
          pkg-manager: npm
          cache-version: v1
      - run: npm test
```

## Environment Variables

### Job-Level Variables
```yaml
jobs:
  test:
    environment:
      NODE_ENV: test
      DATABASE_URL: postgresql://localhost/test
    steps:
      - run: npm test
```

### Step-Level Variables
```yaml
steps:
  - run:
      name: Deploy
      command: ./deploy.sh
      environment:
        DEPLOY_ENV: production
```

### Context Variables
```yaml
# Define in CircleCI UI: Organization Settings → Contexts

workflows:
  deploy:
    jobs:
      - deploy:
          context:
            - aws-credentials
            - slack-notifications
```

## Conditional Logic

### When/Unless
```yaml
steps:
  - when:
      condition:
        equal: [main, << pipeline.git.branch >>]
      steps:
        - run: echo "On main branch"
  
  - unless:
      condition: << pipeline.parameters.skip_tests >>
      steps:
        - run: npm test
```

### Pipeline Parameters
```yaml
parameters:
  run_integration_tests:
    type: boolean
    default: true
  deploy_environment:
    type: enum
    enum: ["staging", "production"]
    default: "staging"

jobs:
  integration_test:
    steps:
      - when:
          condition: << pipeline.parameters.run_integration_tests >>
          steps:
            - run: npm run test:integration
```

## Docker Builds

```yaml
jobs:
  build_and_push:
    docker:
      - image: cimg/base:current
    steps:
      - checkout
      - setup_remote_docker:
          docker_layer_caching: true
      - run:
          name: Build and push
          command: |
            echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USER" --password-stdin
            docker build -t myapp:$CIRCLE_SHA1 .
            docker push myapp:$CIRCLE_SHA1
```

## SSH and Debugging

### Enable SSH Access
```yaml
jobs:
  test:
    steps:
      - checkout
      - run: npm test
      # Add this for SSH debugging
      - add_ssh_keys:
          fingerprints:
            - "SO:ME:FI:NG:ER:PR:IN:T"
```

### Rerun with SSH
In CircleCI UI: Click "Rerun" → "Rerun Job with SSH"

## Test Splitting

```yaml
jobs:
  test:
    parallelism: 4
    steps:
      - checkout
      - run:
          name: Run tests
          command: |
            # Split by timing data
            TESTS=$(circleci tests glob "tests/**/*.test.ts" | circleci tests split --split-by=timings)
            npm test -- $TESTS
      
      - store_test_results:
          path: test-results
```

## Complete Example

```yaml
version: 2.1

orbs:
  node: circleci/node@5.1.0
  docker: circleci/docker@2.4.0
  slack: circleci/slack@4.12.5

parameters:
  deploy_environment:
    type: enum
    enum: ["none", "staging", "production"]
    default: "none"

executors:
  node:
    docker:
      - image: cimg/node:20.10
    resource_class: medium

commands:
  setup:
    steps:
      - checkout
      - node/install-packages:
          pkg-manager: npm
          cache-version: v1

jobs:
  lint:
    executor: node
    steps:
      - setup
      - run: npm run lint
      - run: npm run typecheck

  test:
    executor: node
    parallelism: 4
    docker:
      - image: cimg/node:20.10
      - image: cimg/postgres:15.0
        environment:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test
    steps:
      - setup
      - run:
          name: Wait for DB
          command: dockerize -wait tcp://localhost:5432 -timeout 1m
      - run:
          name: Run tests
          command: |
            TESTS=$(circleci tests glob "tests/**/*.test.ts" | circleci tests split --split-by=timings)
            npm test -- $TESTS
          environment:
            DATABASE_URL: postgresql://test:test@localhost:5432/test
      - store_test_results:
          path: test-results
      - store_artifacts:
          path: coverage

  build:
    executor: node
    steps:
      - setup
      - run: npm run build
      - persist_to_workspace:
          root: .
          paths:
            - dist

  build_docker:
    executor: docker/docker
    steps:
      - checkout
      - attach_workspace:
          at: .
      - setup_remote_docker:
          docker_layer_caching: true
      - docker/check
      - docker/build:
          image: myorg/myapp
          tag: $CIRCLE_SHA1
      - docker/push:
          image: myorg/myapp
          tag: $CIRCLE_SHA1

  deploy:
    parameters:
      environment:
        type: string
    executor: node
    steps:
      - checkout
      - attach_workspace:
          at: .
      - run:
          name: Deploy to << parameters.environment >>
          command: ./scripts/deploy.sh << parameters.environment >>
      - slack/notify:
          event: pass
          template: success_tagged_deployment

workflows:
  build-test-deploy:
    jobs:
      - lint
      - test
      - build:
          requires:
            - lint
            - test
      - build_docker:
          requires:
            - build
          filters:
            branches:
              only: main
      - hold_staging:
          type: approval
          requires:
            - build_docker
      - deploy:
          name: deploy_staging
          environment: staging
          context: aws-staging
          requires:
            - hold_staging
      - hold_production:
          type: approval
          requires:
            - deploy_staging
      - deploy:
          name: deploy_production
          environment: production
          context: aws-production
          requires:
            - hold_production

  nightly:
    triggers:
      - schedule:
          cron: "0 2 * * *"
          filters:
            branches:
              only: main
    jobs:
      - test
      - build

# Validate config
# circleci config validate
```

## Validation

```bash
# Install CircleCI CLI
curl -fLSs https://raw.githubusercontent.com/CircleCI-Public/circleci-cli/master/install.sh | bash

# Validate config
circleci config validate

# Process config (expand orbs, parameters)
circleci config process .circleci/config.yml

# Run job locally
circleci local execute --job test
```
