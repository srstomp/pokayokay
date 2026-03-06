# Diagnosing and Fixing Flaky Playwright E2E Tests in CI

## Diagnosis Strategy

### Step 1: Categorize the Failures

Start by collecting data. You need to know which tests fail, how often, and whether they cluster around specific patterns. Run your CI suite 10-20 times and log every failure with the test name, error message, and any screenshots or traces.

Sort failures into buckets:

- **Timing/race conditions** - Elements not found, clicks hitting the wrong target, assertions firing before the page is ready.
- **Database state leakage** - Tests that pass in isolation but fail when run after other tests, or fail when run in parallel.
- **Resource contention** - Port conflicts, file locks, shared browser instances.
- **Environment differences** - CI has less CPU/memory, different screen resolution, or different network characteristics than your local machine.

### Step 2: Enable Playwright Traces and Artifacts

If you haven't already, enable trace collection on failure in your Playwright config:

```typescript
// playwright.config.ts
export default defineConfig({
  retries: 0, // disable retries during diagnosis
  use: {
    trace: 'on-first-retry', // or 'retain-on-failure' for diagnosis
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
});
```

Upload these artifacts from CI so you can inspect them with `npx playwright show-trace trace.zip`. The trace viewer shows every network request, DOM snapshot, and action timeline -- this alone will identify most timing issues.

### Step 3: Check for Parallel Execution Issues

Determine whether your CI runs tests in parallel (Playwright workers) and whether your local runs do the same. A common pattern: tests pass locally with `workers: 1` but CI uses the default (number of CPU cores). Try:

```bash
npx playwright test --workers=1
```

If this eliminates flakiness, your tests have shared state problems.

---

## Fixing Timing-Related Flakiness

### Replace Fixed Waits with Assertions

Never do this:

```typescript
await page.waitForTimeout(2000);
await page.click('#submit');
```

Instead, wait for the actual condition:

```typescript
await page.locator('#submit').waitFor({ state: 'visible' });
await page.locator('#submit').click();
```

Or use `expect` with auto-retry:

```typescript
await expect(page.locator('#submit')).toBeVisible();
await page.locator('#submit').click();
```

### Use Web-First Assertions

Playwright's `expect` assertions auto-retry by default (5 seconds). Use them instead of manually checking DOM state:

```typescript
// Bad - single check, no retry
const text = await page.locator('.status').textContent();
expect(text).toBe('Complete');

// Good - auto-retries until timeout
await expect(page.locator('.status')).toHaveText('Complete');
```

### Wait for Network Idle or Specific Responses

If a page transition depends on an API call completing:

```typescript
await Promise.all([
  page.waitForResponse(resp => resp.url().includes('/api/data') && resp.status() === 200),
  page.click('#load-data'),
]);
await expect(page.locator('.results')).toBeVisible();
```

### Increase Action Timeout for CI

CI machines are slower. Set a more generous action timeout without inflating your test timeout:

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    actionTimeout: 10_000, // 10s for individual actions (click, fill, etc.)
  },
  expect: {
    timeout: 10_000, // 10s for expect assertions
  },
  timeout: 60_000, // 60s overall test timeout
});
```

---

## Fixing Database State Issues

### Isolate Test Data Per Test

Every test should create its own data and not depend on data from other tests or seed scripts that assume a clean database.

```typescript
test('user can update their profile', async ({ page, request }) => {
  // Create a unique user for this test
  const user = await createTestUser(request, {
    email: `test-${Date.now()}@example.com`,
  });

  await page.goto(`/profile/${user.id}`);
  // ... test logic
});
```

### Reset Database State Between Tests

Use a `beforeEach` or global setup to reset relevant state:

```typescript
// Option A: Truncate tables before each test
test.beforeEach(async ({ request }) => {
  await request.post('/api/test/reset-db');
});

// Option B: Use database transactions that roll back
// (requires app support - wrap each test's DB operations in a transaction)
```

### Use Separate Databases for Parallel Workers

If tests run in parallel, give each worker its own database:

```typescript
// playwright.config.ts
export default defineConfig({
  use: {
    baseURL: process.env.BASE_URL,
  },
});

// global-setup.ts
async function globalSetup(config: FullConfig) {
  const workerDatabases = [];
  for (let i = 0; i < config.workers; i++) {
    const dbName = `test_db_worker_${i}`;
    await createDatabase(dbName);
    await runMigrations(dbName);
    workerDatabases.push(dbName);
  }
}
```

Alternatively, use a test database per project or shard rather than per worker, depending on your setup cost.

### Ensure Deterministic Ordering

If tests depend on sort order, always include an explicit `ORDER BY` in the query and sort assertions in the test. Default database ordering is not guaranteed and varies between environments.

---

## CI-Specific Fixes

### Resource Constraints

CI containers often have limited CPU and memory. Playwright spawns browser processes that are resource-hungry. Mitigations:

```typescript
// playwright.config.ts
export default defineConfig({
  workers: process.env.CI ? 2 : undefined, // limit parallelism in CI
  use: {
    launchOptions: {
      args: ['--disable-gpu', '--disable-dev-shm-usage'], // for Chromium in Docker
    },
  },
});
```

The `--disable-dev-shm-usage` flag is critical if your CI runs in Docker -- the default `/dev/shm` is often too small (64MB) and causes browser crashes.

### Use Retries Strategically (Not as a Fix)

Retries mask problems. Use them as a safety net, not a solution:

```typescript
// playwright.config.ts
export default defineConfig({
  retries: process.env.CI ? 2 : 0, // retry in CI only
});
```

If a test needs retries to pass, it should also be flagged for investigation. Track your retry rate -- if it's above 5%, you have underlying problems.

### Run Flaky Tests in a Separate Job

Tag known-flaky tests and run them separately so they don't block the main pipeline:

```typescript
// flaky.spec.ts
test('known flaky - dashboard chart renders', {
  tag: '@flaky',
}, async ({ page }) => {
  // ...
});
```

```bash
# CI pipeline
# Main job (must pass):
npx playwright test --grep-invert @flaky

# Flaky job (informational):
npx playwright test --grep @flaky || true
```

This is a triage measure, not a long-term solution.

---

## Systematic Prevention

### Add a Flaky Test Detector to CI

Run each new or modified test N times before merging:

```bash
# In your PR CI job
CHANGED_TESTS=$(git diff --name-only origin/main | grep '\.spec\.ts$')
if [ -n "$CHANGED_TESTS" ]; then
  npx playwright test $CHANGED_TESTS --repeat-each=5
fi
```

### Common Patterns That Cause Flakiness

| Pattern | Problem | Fix |
|---------|---------|-----|
| `page.waitForTimeout()` | Arbitrary delay, too short or too long | Use web-first assertions |
| Shared test user/data | Tests interfere with each other | Create unique data per test |
| `page.click()` without waiting | Element not yet interactive | `await expect(locator).toBeVisible()` first |
| Testing time-dependent features | Different timezone/clock speed in CI | Mock `Date.now()` or use `page.clock` |
| Global `beforeAll` setup | Shared state across tests | Prefer `beforeEach` for isolation |
| Seeded auto-increment IDs | IDs differ between environments | Query by content, not by ID |
| Browser caching | Stale assets from previous test | Clear storage in `beforeEach` or use new context |

### Recommended Investigation Order

1. Enable traces on all CI runs for one week. Collect every failure.
2. Group by test file. If one file has most failures, focus there.
3. Run the worst offenders with `--repeat-each=20` locally. If they pass, the problem is environmental (CI resources, database setup). If they fail, you can debug locally.
4. For database issues: add logging to your test setup/teardown to verify state is clean before each test.
5. For timing issues: review the Playwright trace timeline. Look for gaps between "action started" and "action completed" -- these reveal slow responses or missing waits.
6. Fix the top 3-5 offenders. This typically eliminates 80% of flakiness.
