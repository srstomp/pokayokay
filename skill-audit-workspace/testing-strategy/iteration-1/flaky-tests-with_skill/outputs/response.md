# Diagnosing and Fixing Flaky E2E Tests in CI

A 20% CI failure rate from flaky Playwright E2E tests is a serious productivity drain. The "passes locally, fails in CI" pattern narrows the root causes significantly. Here is a systematic approach to diagnose and fix.

---

## Phase 1: Diagnosis — Identify the Actual Failure Modes

Before fixing anything, you need data. Flaky tests fail for different reasons, and applying the wrong fix wastes time.

### 1.1 Enable Playwright Traces and Artifacts on Failure

If you have not already, configure Playwright to capture traces, screenshots, and video on the first retry. This is the single most important diagnostic step.

```typescript
// playwright.config.ts
export default defineConfig({
  retries: process.env.CI ? 2 : 0,
  use: {
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
});
```

Upload these as CI artifacts so you can inspect them after a failed run:

```yaml
- name: Upload Playwright artifacts
  uses: actions/upload-artifact@v4
  if: always()
  with:
    name: playwright-report
    path: playwright-report/
```

Then use `npx playwright show-trace trace.zip` locally to step through exactly what happened.

### 1.2 Categorize Your Failures

Go through your last 10-20 CI failures and bucket each one:

| Category | Symptoms | Typical Cause |
|----------|----------|---------------|
| **Timing** | Element not found, click intercepted, assertion too early | Waiting on time instead of conditions |
| **Database state** | Unexpected data, constraint violations, missing seed data | Tests sharing or leaking state |
| **Network** | Timeout waiting for API, connection refused | Server not ready, external service call |
| **Animation/rendering** | Screenshot diff, element not visible yet | CSS transitions, lazy loading |
| **Resource contention** | Sporadic timeouts, slow operations | CI has fewer resources than your laptop |

This categorization drives which fixes to apply.

---

## Phase 2: Fix Timing Issues

Timing problems are the most common source of flakiness, and the fix is always the same: **wait for conditions, never for time**.

### 2.1 Eliminate All Fixed Waits

Search your test codebase for `waitForTimeout`, `setTimeout`, and any hardcoded sleep. Every one of these is a flaky test waiting to happen.

```typescript
// WRONG: Arbitrary wait
await page.waitForTimeout(2000);

// RIGHT: Wait for the condition you actually care about
await expect(page.getByText('Dashboard')).toBeVisible();
```

```typescript
// WRONG: Assuming instant state change after click
await page.click('#submit');
const text = await page.textContent('.result');
expect(text).toBe('Submitted');

// RIGHT: Wait for the state change
await page.click('#submit');
await expect(page.getByText('Submitted')).toBeVisible();
```

### 2.2 Wait for Network Responses Before Asserting

When a click triggers an API call and you assert on the result, explicitly wait for the response:

```typescript
const responsePromise = page.waitForResponse('**/api/orders');
await page.click('#place-order');
await responsePromise;
await expect(page.getByText('Order confirmed')).toBeVisible();
```

### 2.3 Disable Animations in CI

Animations create timing windows where elements are technically present but not interactable. Disable them:

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    reducedMotion: 'reduce',
  },
});
```

Or inject a style tag as a belt-and-suspenders measure:

```typescript
test.beforeEach(async ({ page }) => {
  await page.addStyleTag({
    content: `
      *, *::before, *::after {
        animation-duration: 0s !important;
        transition-duration: 0s !important;
      }
    `,
  });
});
```

---

## Phase 3: Fix Database State Issues

Database state problems manifest as tests that pass in isolation but fail when run together, or fail differently on each run. The root cause is almost always **tests leaking state to each other**.

### 3.1 Isolate Every Test's Database State

Each test must start from a known state. There are three strategies, in order of preference:

**Strategy A: Transaction rollback (fastest)**

Wrap each test in a database transaction that rolls back at the end. This is the fastest option because no data ever hits disk.

```typescript
// Expose a test API endpoint that manages transactions
// POST /api/test/begin-transaction
// POST /api/test/rollback-transaction

test.beforeEach(async ({ request }) => {
  await request.post('/api/test/begin-transaction');
});

test.afterEach(async ({ request }) => {
  await request.post('/api/test/rollback-transaction');
});
```

**Strategy B: Truncate between tests**

If transaction rollback is not feasible (e.g., your app uses multiple database connections or commits mid-flow), truncate all tables before each test:

```typescript
test.beforeEach(async ({ request }) => {
  await request.post('/api/test/reset');
});
```

Where `/api/test/reset` does:

```typescript
async function resetDatabase() {
  const tables = await db.query(`
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public' AND tablename != 'migrations'
  `);
  for (const { tablename } of tables.rows) {
    await db.query(`TRUNCATE TABLE "${tablename}" CASCADE`);
  }
  await seedReferenceData(); // roles, categories, etc.
}
```

**Strategy C: Namespace isolation**

Tag all test-created data with a unique test ID and clean up by that ID:

```typescript
test.beforeEach(async ({ request }) => {
  const testId = `test-${Date.now()}-${Math.random().toString(36).slice(2)}`;
  // Pass testId to factories, clean up by testId in afterEach
});
```

This is the most complex approach. Prefer A or B.

### 3.2 Never Share Mutable Data Between Tests

A common pattern that causes flakiness:

```typescript
// WRONG: Shared mutable state
let sharedUser: User;
test.beforeAll(async ({ request }) => {
  sharedUser = await createUser();
});

test('test 1 modifies user', async () => { /* mutates sharedUser */ });
test('test 2 reads user', async () => { /* sees mutations from test 1 */ });
```

Each test should create its own data:

```typescript
// RIGHT: Each test owns its data
test('test 1', async ({ request }) => {
  const user = await createUser(request);
  // ...
});
test('test 2', async ({ request }) => {
  const user = await createUser(request);
  // ...
});
```

### 3.3 Use Docker tmpfs for the CI Database

If your CI database is slow, use an in-memory filesystem:

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
    tmpfs:
      - /var/lib/postgresql/data
    options: >-
      --health-cmd pg_isready
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
```

The `tmpfs` mount makes database operations significantly faster in CI.

---

## Phase 4: Fix CI-Specific Environment Issues

### 4.1 Ensure the Server Is Actually Ready

CI runners are slower than your machine. The app may not be fully ready when tests start. Use Playwright's built-in web server configuration with a health check:

```typescript
// playwright.config.ts
export default defineConfig({
  webServer: {
    command: 'npm run start',
    url: 'http://localhost:3000/health',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000, // 2 minutes to start
  },
});
```

### 4.2 Block External Network Requests

If any test hits a real external service, it will be flaky. Block everything that is not localhost:

```typescript
test.beforeEach(async ({ page }) => {
  await page.route('**/*', (route) => {
    const url = route.request().url();
    if (!url.includes('localhost') && !url.includes('127.0.0.1')) {
      return route.abort('blockedbyclient');
    }
    return route.continue();
  });
});
```

If your app legitimately calls external services, mock them with `page.route()`:

```typescript
await page.route('**/api.stripe.com/**', async (route) => {
  await route.fulfill({
    status: 200,
    contentType: 'application/json',
    body: JSON.stringify({ id: 'pi_mock', status: 'succeeded' }),
  });
});
```

### 4.3 Reduce Parallelism in CI

Your local machine likely has more resources than a CI runner. Running Playwright tests in parallel in CI can cause resource contention:

```typescript
// playwright.config.ts
export default defineConfig({
  workers: process.env.CI ? 1 : undefined,
  fullyParallel: !process.env.CI,
});
```

Start with `workers: 1` in CI. If tests pass reliably, you can increase to 2 and use sharding across multiple CI machines instead:

```yaml
strategy:
  matrix:
    shard: [1, 2, 3]
steps:
  - run: npx playwright test --shard=${{ matrix.shard }}/3
```

This gives you parallelism without resource contention.

---

## Phase 5: Structural Prevention

### 5.1 Reduce E2E Test Count

The testing pyramid recommends E2E tests comprise only 5-10% of your suite, covering critical user journeys only. If you have dozens of E2E tests covering edge cases that could be integration or unit tests, push them down the pyramid:

| E2E test for... | Push down to... |
|-----------------|-----------------|
| Form validation errors | Unit test on validation logic |
| API error states | Integration test with mocked HTTP |
| Authorization (can/can't access) | Integration test on middleware |
| Complex data transformations | Unit test on the transformer |
| Happy-path critical flows | Keep as E2E |

Fewer E2E tests means fewer opportunities for flakiness and faster CI.

### 5.2 Add Console and Network Logging for Debug

When a test fails in CI, you need context. Add structured logging:

```typescript
test.beforeEach(async ({ page }) => {
  if (process.env.CI) {
    page.on('console', (msg) => {
      if (msg.type() === 'error') {
        console.log(`[BROWSER ERROR] ${msg.text()}`);
      }
    });

    page.on('response', (response) => {
      if (response.status() >= 400) {
        console.log(`[HTTP ${response.status()}] ${response.url()}`);
      }
    });
  }
});
```

### 5.3 Use test.step() for Structured Traces

Break complex tests into named steps so traces show exactly where failure occurred:

```typescript
test('complete checkout', async ({ page }) => {
  await test.step('Add item to cart', async () => {
    await page.goto('/products');
    await page.click('[data-testid="add-to-cart"]');
    await expect(page.getByText('Added to cart')).toBeVisible();
  });

  await test.step('Proceed to checkout', async () => {
    await page.click('[data-testid="checkout"]');
    await expect(page).toHaveURL('/checkout');
  });

  await test.step('Complete payment', async () => {
    await page.fill('#card-number', '4242424242424242');
    await page.click('#pay');
    await expect(page.getByText('Order confirmed')).toBeVisible();
  });
});
```

---

## Recommended Action Plan

Work through these in order. Each step should produce measurable improvement before moving to the next.

1. **Enable traces and artifacts** (30 min) — Get the data you need.
2. **Categorize your last 20 failures** (1-2 hours) — Know what you are actually fixing.
3. **Eliminate fixed waits** (1-2 hours) — Search for `waitForTimeout`, replace with condition waits. Likely fixes your timing-related failures immediately.
4. **Add database reset in beforeEach** (2-4 hours) — Implement truncate-and-reseed. Fixes state leakage.
5. **Set workers to 1 in CI** (5 min) — Eliminates resource contention as a variable.
6. **Block external network requests** (30 min) — Eliminates external service flakiness.
7. **Disable animations** (5 min) — Eliminates rendering timing issues.
8. **Audit test count** (ongoing) — Push non-critical-path tests down the pyramid.

After steps 1-7, re-run your CI suite 10 times. If the failure rate drops below 2%, you are in good shape. If specific tests still fail, the trace data from step 1 will tell you exactly why.
