# CI/CD Integration

Pipeline setup, environment management, and test reporting.

## Pipeline Strategy

```
┌─────────────────────────────────────────────────────────────┐
│                      CI PIPELINE                            │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐    │
│  │  Lint   │ → │  Unit   │ → │ Integ   │ → │Contract │    │
│  │         │   │  Tests  │   │  Tests  │   │  Tests  │    │
│  └─────────┘   └─────────┘   └─────────┘   └─────────┘    │
│       │             │             │             │          │
│       ▼             ▼             ▼             ▼          │
│     Fast         Fast         Medium         Fast          │
│    (<30s)       (<1m)        (<5m)         (<1m)          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    E2E Tests                         │   │
│  │              (Staging environment)                   │   │
│  │                    Slow (<15m)                       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## GitHub Actions

### Basic Test Workflow

```yaml
# .github/workflows/test.yml
name: Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - name: Install dependencies
        run: npm ci
      
      - name: Run migrations
        run: npm run db:migrate
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test_db
      
      - name: Run tests
        run: npm test
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test_db
          JWT_SECRET: test-secret
          NODE_ENV: test
```

### Full Pipeline with Coverage

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  NODE_VERSION: '20'

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      - run: npm ci
      - run: npm run lint
      - run: npm run typecheck

  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      - run: npm ci
      - run: npm run test:unit -- --coverage
      - uses: codecov/codecov-action@v4
        with:
          files: ./coverage/lcov.info
          flags: unit

  integration-tests:
    runs-on: ubuntu-latest
    needs: [lint]
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
      
      redis:
        image: redis:7
        ports:
          - 6379:6379
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - run: npm ci
      
      - name: Run migrations
        run: npm run db:migrate
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test_db
      
      - name: Run integration tests
        run: npm run test:integration -- --coverage
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test_db
          REDIS_URL: redis://localhost:6379
          JWT_SECRET: test-secret
          NODE_ENV: test
      
      - uses: codecov/codecov-action@v4
        with:
          files: ./coverage/lcov.info
          flags: integration

  contract-tests:
    runs-on: ubuntu-latest
    needs: [lint]
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - run: npm ci
      
      - name: Validate OpenAPI spec
        run: npx @redocly/cli lint openapi.yaml
      
      - name: Run migrations
        run: npm run db:migrate
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test_db
      
      - name: Run contract tests
        run: npm run test:contracts
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test_db
          JWT_SECRET: test-secret
          NODE_ENV: test

  e2e-tests:
    runs-on: ubuntu-latest
    needs: [integration-tests, contract-tests]
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - run: npm ci
      
      - name: Run E2E tests against staging
        run: npm run test:e2e
        env:
          API_URL: ${{ secrets.STAGING_API_URL }}
          TEST_USER_EMAIL: ${{ secrets.TEST_USER_EMAIL }}
          TEST_USER_PASSWORD: ${{ secrets.TEST_USER_PASSWORD }}
```

### Parallel Test Execution

```yaml
# .github/workflows/parallel-tests.yml
name: Parallel Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        shard: [1, 2, 3, 4]
    
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: test_db
        ports:
          - 5432:5432
    
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - run: npm ci
      - run: npm run db:migrate
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test_db
      
      - name: Run tests (shard ${{ matrix.shard }}/4)
        run: npm test -- --shard=${{ matrix.shard }}/4
        env:
          DATABASE_URL: postgresql://test:test@localhost:5432/test_db
```

---

## Environment Configuration

### Environment Files

```bash
# .env.test (committed)
NODE_ENV=test
LOG_LEVEL=error
JWT_SECRET=test-secret-do-not-use-in-production
JWT_EXPIRES_IN=1h

# Database (overridden in CI)
DATABASE_URL=postgresql://test:test@localhost:5432/test_db

# Redis (overridden in CI)
REDIS_URL=redis://localhost:6379

# External services (mocked by default)
MOCK_EXTERNAL_SERVICES=true
```

```typescript
// tests/config.ts
export const testConfig = {
  database: {
    url: process.env.DATABASE_URL || 'postgresql://test:test@localhost:5432/test_db',
  },
  redis: {
    url: process.env.REDIS_URL || 'redis://localhost:6379',
  },
  api: {
    baseUrl: process.env.API_URL || 'http://localhost:3000',
  },
  auth: {
    jwtSecret: process.env.JWT_SECRET || 'test-secret',
  },
  external: {
    mockServices: process.env.MOCK_EXTERNAL_SERVICES !== 'false',
  },
};
```

### Environment Isolation

```typescript
// tests/setup.ts
import { beforeAll, afterAll } from 'vitest';

beforeAll(async () => {
  // Verify test environment
  if (process.env.NODE_ENV !== 'test') {
    throw new Error('Tests must run in test environment');
  }
  
  // Verify not running against production
  if (process.env.DATABASE_URL?.includes('production')) {
    throw new Error('Cannot run tests against production database');
  }
});
```

### Secrets Management

```yaml
# GitHub Actions secrets
# Settings → Secrets → Actions

# Required for integration tests
DATABASE_URL: postgresql://...
JWT_SECRET: ...

# Required for E2E tests
STAGING_API_URL: https://staging-api.example.com
TEST_USER_EMAIL: e2e-test@example.com
TEST_USER_PASSWORD: ...

# Optional
CODECOV_TOKEN: ...
SLACK_WEBHOOK_URL: ...
```

---

## Test Reporting

### Vitest Reporter Configuration

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    reporters: [
      'default',
      'html',
      'junit',
    ],
    outputFile: {
      junit: './reports/junit.xml',
      html: './reports/index.html',
    },
  },
});
```

### Jest Reporter Configuration

```javascript
// jest.config.js
module.exports = {
  reporters: [
    'default',
    ['jest-junit', {
      outputDirectory: './reports',
      outputName: 'junit.xml',
    }],
    ['jest-html-reporter', {
      outputPath: './reports/index.html',
      pageTitle: 'Test Report',
    }],
  ],
};
```

### GitHub Actions with Reports

```yaml
- name: Run tests
  run: npm test -- --reporter=junit --outputFile=reports/junit.xml

- name: Upload test results
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: test-results
    path: reports/

- name: Publish test results
  uses: dorny/test-reporter@v1
  if: always()
  with:
    name: Test Results
    path: reports/junit.xml
    reporter: jest-junit
```

### Coverage Reporting

```yaml
# .github/workflows/coverage.yml
- name: Run tests with coverage
  run: npm test -- --coverage

- name: Upload to Codecov
  uses: codecov/codecov-action@v4
  with:
    token: ${{ secrets.CODECOV_TOKEN }}
    files: ./coverage/lcov.info
    fail_ci_if_error: true

# Or SonarCloud
- name: SonarCloud Scan
  uses: SonarSource/sonarcloud-github-action@master
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
```

### Slack Notification

```yaml
- name: Notify Slack on failure
  if: failure()
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "❌ Tests failed on ${{ github.ref }}",
        "blocks": [
          {
            "type": "section",
            "text": {
              "type": "mrkdwn",
              "text": "*Test Failure*\nBranch: `${{ github.ref }}`\nCommit: `${{ github.sha }}`\n<${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}|View Run>"
            }
          }
        ]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

## Database Management in CI

### PostgreSQL Service

```yaml
services:
  postgres:
    image: postgres:15-alpine
    env:
      POSTGRES_USER: test
      POSTGRES_PASSWORD: test
      POSTGRES_DB: test_db
    ports:
      - 5432:5432
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

### MySQL Service

```yaml
services:
  mysql:
    image: mysql:8
    env:
      MYSQL_ROOT_PASSWORD: test
      MYSQL_DATABASE: test_db
    ports:
      - 3306:3306
    options: >-
      --health-cmd "mysqladmin ping"
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

### MongoDB Service

```yaml
services:
  mongodb:
    image: mongo:7
    ports:
      - 27017:27017
    options: >-
      --health-cmd "mongosh --eval 'db.runCommand(\"ping\").ok'"
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

### Database Migrations in CI

```yaml
- name: Run migrations
  run: npm run db:migrate
  env:
    DATABASE_URL: postgresql://test:test@localhost:5432/test_db

# Or with Prisma
- name: Generate Prisma client
  run: npx prisma generate

- name: Run migrations
  run: npx prisma migrate deploy
  env:
    DATABASE_URL: postgresql://test:test@localhost:5432/test_db
```

---

## E2E Test Environment

### Staging Environment Tests

```yaml
# .github/workflows/e2e-staging.yml
name: E2E Tests (Staging)

on:
  push:
    branches: [main]
  schedule:
    - cron: '0 */4 * * *'  # Every 4 hours

jobs:
  e2e:
    runs-on: ubuntu-latest
    environment: staging
    
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - run: npm ci
      
      - name: Wait for staging deployment
        run: |
          until curl -s ${{ secrets.STAGING_API_URL }}/health | grep -q "ok"; do
            echo "Waiting for staging..."
            sleep 10
          done
      
      - name: Run E2E tests
        run: npm run test:e2e
        env:
          API_BASE_URL: ${{ secrets.STAGING_API_URL }}
          TEST_USER_EMAIL: ${{ secrets.TEST_USER_EMAIL }}
          TEST_USER_PASSWORD: ${{ secrets.TEST_USER_PASSWORD }}
      
      - name: Upload screenshots on failure
        if: failure()
        uses: actions/upload-artifact@v4
        with:
          name: e2e-screenshots
          path: tests/e2e/screenshots/
```

### Test User Setup

```typescript
// tests/e2e/setup.ts
import { beforeAll } from 'vitest';

let testUserToken: string;

beforeAll(async () => {
  // Login or create test user
  const response = await fetch(`${process.env.API_BASE_URL}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      email: process.env.TEST_USER_EMAIL,
      password: process.env.TEST_USER_PASSWORD,
    }),
  });

  if (!response.ok) {
    throw new Error('Failed to authenticate test user');
  }

  const data = await response.json();
  testUserToken = data.accessToken;
});

export function getTestUserToken(): string {
  return testUserToken;
}
```

---

## Performance Considerations

### Test Timeouts

```typescript
// vitest.config.ts
export default defineConfig({
  test: {
    testTimeout: 10000,      // 10s per test
    hookTimeout: 30000,      // 30s for setup/teardown
    teardownTimeout: 10000,  // 10s for cleanup
  },
});
```

### Failing Fast

```yaml
- name: Run tests
  run: npm test -- --bail  # Stop on first failure
```

### Caching Dependencies

```yaml
- uses: actions/setup-node@v4
  with:
    node-version: '20'
    cache: 'npm'

# Or more aggressive caching
- name: Cache node_modules
  uses: actions/cache@v4
  with:
    path: node_modules
    key: ${{ runner.os }}-node-${{ hashFiles('package-lock.json') }}
```

### Docker Layer Caching

```yaml
- name: Set up Docker Buildx
  uses: docker/setup-buildx-action@v3

- name: Build with cache
  uses: docker/build-push-action@v5
  with:
    context: .
    push: false
    load: true
    tags: myapp:test
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

---

## Package.json Scripts

```json
{
  "scripts": {
    "test": "vitest",
    "test:watch": "vitest --watch",
    "test:coverage": "vitest --coverage",
    "test:unit": "vitest tests/unit",
    "test:integration": "vitest tests/integration",
    "test:contracts": "vitest tests/contracts",
    "test:e2e": "vitest tests/e2e",
    "test:ci": "vitest --reporter=junit --outputFile=reports/junit.xml",
    "db:migrate": "prisma migrate deploy",
    "db:reset": "prisma migrate reset --force"
  }
}
```

---

## Troubleshooting CI Failures

### Common Issues

**Database connection failures:**
```yaml
# Ensure service is healthy before running tests
options: >-
  --health-cmd pg_isready
  --health-interval 10s
  --health-timeout 5s
  --health-retries 5
```

**Flaky tests:**
```yaml
# Add retry for flaky tests
- name: Run tests with retry
  uses: nick-fields/retry@v2
  with:
    max_attempts: 3
    command: npm test
```

**Timeout issues:**
```yaml
# Increase timeout
- name: Run tests
  run: npm test
  timeout-minutes: 15
```

**Port conflicts:**
```yaml
# Use dynamic ports
services:
  postgres:
    ports:
      - 5432  # Random host port
```

### Debug Mode

```yaml
- name: Run tests with debug
  run: DEBUG=* npm test
  env:
    CI: true
```
