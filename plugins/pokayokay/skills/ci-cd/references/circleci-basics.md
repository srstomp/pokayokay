# CircleCI: Config, Executors, Jobs, and Caching

Config structure, executors, jobs, commands, caching, artifacts, and workspaces.

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
