# Coverage Gap Audit: Node.js REST API (Express + Prisma + PostgreSQL)

## Diagnosis: Why 45% Line Coverage Is Misleading

Your suspicion is correct. Line coverage is the weakest coverage metric -- it tells you code was *executed*, not that it was *tested*. The skill's coverage guide puts it plainly: "High Coverage != Quality Tests." A suite that hits 45% of lines but only exercises happy paths is arguably worse than 30% coverage of critical error paths, because it creates a false sense of safety.

For an API service, the skill recommends **80%+ line coverage and 75%+ branch coverage**. But more importantly, it recommends targeting coverage *by code type*, not as a flat number. Here is how to audit your gaps systematically.

---

## Step 1: Get the Real Numbers

Run coverage with branch reporting enabled. Line coverage alone hides the problem.

```bash
# If using Jest
npx jest --coverage --coverageReporters=text --coverageReporters=json-summary

# If using Vitest
npx vitest --coverage --reporter=text
```

Read the report columns carefully:

```
File                    | % Stmts | % Branch | % Funcs | % Lines | Uncovered Line #s
------------------------|---------|----------|---------|---------|------------------
```

**Branch coverage** is the number that exposes happy-path-only testing. If your line coverage is 45% but branch coverage is 20-30%, your tests are almost exclusively exercising the success path through conditionals.

### Find the worst offenders

```bash
# Files with coverage below 50% -- these are your critical gaps
npx jest --coverage | grep -E "^\s+src.*\|\s+[0-4][0-9]\."

# Or generate HTML report and open it
npx jest --coverage --coverageReporters=html
open coverage/index.html
```

---

## Step 2: Classify Your Code by Risk

Not all code deserves equal coverage attention. Audit your codebase against these tiers:

| Code Type | Target | What to Look For |
|-----------|--------|-----------------|
| **Business logic** (services, domain) | 85-95% | Pricing calculations, eligibility checks, state transitions |
| **API handlers** (controllers/routes) | 80-90% | Request validation, error responses, auth checks |
| **Middleware** (auth, error handling, rate limiting) | 90%+ | Every branch in auth middleware, every error type in error handler |
| **Utilities** (validators, formatters, parsers) | 90%+ | Pure functions -- easy to test, high reuse |
| **Prisma query wrappers** (repositories/data access) | 60-70% | Integration tests needed, harder to unit test |
| **Config/setup** (app bootstrap, DB connection) | 0-30% | Usually trivial, don't chase coverage here |

Map your source files to these categories. Focus the audit on the top three tiers.

---

## Step 3: The Seven Gap Categories

Based on the skill's error handling and edge case guidance, here are the specific gap categories to audit. For each, I provide what to look for and example test patterns.

### Gap 1: Validation Errors (Almost Certainly Untested)

Every endpoint that accepts input needs tests for invalid input. Check each route handler:

- Missing required fields
- Invalid field formats (bad email, negative numbers, strings where numbers expected)
- Empty strings vs. null vs. undefined vs. missing key
- Boundary values (field length limits, numeric ranges)

```typescript
describe('POST /api/resources', () => {
  it('returns 400 with structured errors for missing required fields', async () => {
    const response = await request(app)
      .post('/api/resources')
      .send({})  // empty body
      .expect(400);

    expect(response.body.errors).toContainEqual(
      expect.objectContaining({
        field: 'name',
        message: expect.any(String),
      })
    );
  });

  it('returns 400 for invalid email format', async () => {
    await request(app)
      .post('/api/resources')
      .send({ email: 'not-an-email', name: 'Test' })
      .expect(400);
  });

  it('returns all validation errors at once, not just the first', async () => {
    const response = await request(app)
      .post('/api/resources')
      .send({ email: 'bad', name: '' })
      .expect(400);

    expect(response.body.errors.length).toBeGreaterThan(1);
  });
});
```

**Audit action:** For every POST/PUT/PATCH route, verify there is at least one test per required field with bad input, plus one test with a completely empty body.

### Gap 2: Authentication and Authorization Paths

These are critical paths that the skill says need 100% coverage. Check for:

- Request with no token (401)
- Request with malformed token (401)
- Request with expired token (401)
- Request with valid token but wrong role (403)
- Resource ownership checks -- user A accessing user B's resource (403)
- Admin override paths

```typescript
describe('Protected Routes', () => {
  it('returns 401 without token', async () => {
    await request(app).get('/api/protected').expect(401);
  });

  it('returns 401 with expired token', async () => {
    const expiredToken = jwt.sign({ userId: '1' }, SECRET, { expiresIn: '-1h' });
    await request(app)
      .get('/api/protected')
      .set('Authorization', `Bearer ${expiredToken}`)
      .expect(401);
  });

  it('returns 403 when user accesses another user resource', async () => {
    const userAToken = await getAuthToken(userA);
    await request(app)
      .get(`/api/users/${userB.id}/orders`)
      .set('Authorization', `Bearer ${userAToken}`)
      .expect(403);
  });
});
```

**Audit action:** List every middleware that checks auth. For each, verify tests exist for all rejection paths (no token, bad token, expired token, wrong role, wrong owner).

### Gap 3: Database/Prisma Error Handling

Prisma operations can fail in several ways that are almost never tested:

- Unique constraint violations (duplicate email, duplicate key)
- Foreign key constraint violations (referencing non-existent parent)
- Record not found (`findUniqueOrThrow` throwing)
- Connection failures / timeouts
- Transaction rollback on partial failure

```typescript
describe('UserService.create', () => {
  it('returns 409 for duplicate email', async () => {
    await createUser({ email: 'exists@example.com' });

    await request(app)
      .post('/api/users')
      .send({ email: 'exists@example.com', name: 'Duplicate' })
      .expect(409);
  });

  it('handles Prisma not-found errors as 404', async () => {
    await request(app)
      .get('/api/users/nonexistent-uuid')
      .expect(404);
  });

  it('returns 400 for invalid UUID format in path param', async () => {
    await request(app)
      .get('/api/users/not-a-uuid')
      .expect(400);
  });
});
```

**Audit action:** Search your error handling middleware for how Prisma errors are caught and transformed. Verify each Prisma error code (`P2002` unique violation, `P2025` not found, `P2003` foreign key) has a test that triggers it through an endpoint.

### Gap 4: Error Response Format Consistency

Your API should return consistent error shapes. This is rarely tested:

```typescript
describe('Error Response Format', () => {
  const errorCases = [
    { method: 'post', path: '/api/users', body: {}, expectedStatus: 400 },
    { method: 'get', path: '/api/users/me', body: null, expectedStatus: 401 },
    { method: 'get', path: '/api/users/nonexistent', body: null, expectedStatus: 404 },
  ];

  test.each(errorCases)(
    'returns consistent format for $expectedStatus',
    async ({ method, path, body, expectedStatus }) => {
      const req = request(app)[method](path);
      if (body) req.send(body);

      const response = await req.expect(expectedStatus);

      expect(response.body).toMatchObject({
        status: expectedStatus,
        error: expect.any(String),
        message: expect.any(String),
      });
      // Must not expose stack traces
      expect(response.body.stack).toBeUndefined();
    }
  );
});
```

**Audit action:** Hit every error status code your API can return (400, 401, 403, 404, 409, 422, 429, 500) and verify the response body shape is consistent.

### Gap 5: Edge Cases in Data Handling

These are the bugs that ship to production. Check for:

- Empty string vs null in optional fields
- Unicode and special characters in text fields
- Very large payloads (413 handling)
- Pagination edge cases (page 0, page beyond max, negative limit)
- Sort/filter with invalid column names (SQL injection vector)
- Concurrent mutations (optimistic locking, race conditions)

```typescript
describe('Edge Cases', () => {
  it('handles unicode in text fields', async () => {
    const response = await request(app)
      .post('/api/users')
      .send({ name: 'Taro Yamada', email: 'taro@example.com' })
      .expect(201);

    expect(response.body.name).toBe('Taro Yamada');
  });

  it('rejects oversized request body', async () => {
    await request(app)
      .post('/api/users')
      .send({ name: 'x'.repeat(1_000_000) })
      .expect(413);
  });

  it('handles page=0 gracefully', async () => {
    const response = await request(app)
      .get('/api/resources?page=0&limit=10')
      .expect(200);  // or 400, depending on your API contract

    // Should not crash or return weird results
  });

  it('handles concurrent stock decrements correctly', async () => {
    const product = await createProduct({ stock: 5 });

    const results = await Promise.all([
      request(app).post(`/api/products/${product.id}/purchase`).send({ quantity: 3 }),
      request(app).post(`/api/products/${product.id}/purchase`).send({ quantity: 3 }),
    ]);

    // At least one should fail -- can't sell 6 from stock of 5
    const failed = results.filter(r => r.status !== 200);
    expect(failed.length).toBeGreaterThan(0);
  });
});
```

**Audit action:** For each entity's CRUD endpoints, write at least one test with empty strings, one with null, one with boundary values (0, MAX_INT, max-length string).

### Gap 6: External Dependency Failures

If your API calls external services (email, payment, third-party APIs), test what happens when they fail:

- Timeout from external service
- 500 from external service
- Network error (DNS failure, connection refused)
- Malformed response from external service
- Graceful degradation (e.g., user still created even if welcome email fails)

```typescript
describe('External dependency failures', () => {
  it('creates user even if email service fails', async () => {
    // Mock email service to fail
    jest.spyOn(emailService, 'send').mockRejectedValue(new Error('SMTP error'));

    const response = await request(app)
      .post('/api/users')
      .send(validUserData)
      .expect(201);  // Still succeeds

    expect(response.body.id).toBeDefined();
  });

  it('returns 502 when payment gateway is unreachable', async () => {
    jest.spyOn(paymentGateway, 'charge').mockRejectedValue(new Error('Timeout'));

    await request(app)
      .post('/api/orders/123/pay')
      .send({ cardToken: 'tok_test' })
      .expect(502);
  });
});
```

**Audit action:** List every external integration. For each, verify at least one failure test exists.

### Gap 7: State Transition Violations

If your domain has state machines (order status, user lifecycle, approval workflows), test invalid transitions:

```typescript
describe('Order state machine', () => {
  it('cannot ship an unpaid order', async () => {
    const order = await createOrder({ status: 'pending' });

    await request(app)
      .post(`/api/orders/${order.id}/ship`)
      .expect(400);
  });

  it('cannot cancel a shipped order', async () => {
    const order = await createOrder({ status: 'shipped' });

    await request(app)
      .post(`/api/orders/${order.id}/cancel`)
      .expect(400);
  });
});
```

**Audit action:** For every status field in your Prisma schema, enumerate valid transitions. Test at least one invalid transition per state.

---

## Step 4: Prioritized Action Plan

Work through these in order. Each step builds coverage in the highest-risk areas first.

### Phase 1: Critical Path Coverage (Target: 60% overall, 100% critical paths)

1. **Audit and test your global error handler middleware.** This single piece of code handles every unhandled error in your API. If it has bugs, every error is broken. Test it with each Prisma error type, generic errors, and ensure it never leaks stack traces.

2. **Test auth middleware exhaustively.** Every rejection path: no token, bad token, expired token, wrong role, wrong owner. This is your security boundary.

3. **Add validation error tests for every POST/PUT endpoint.** Use table-driven tests (`test.each`) with arrays of invalid inputs. This is the fastest way to boost both coverage and quality.

### Phase 2: Error Path Coverage (Target: 70% overall, 75% branch)

4. **Test database constraint violations** through your endpoints. Duplicate keys, foreign key failures, not-found cases.

5. **Test external dependency failures.** Mock each external service to throw and verify your API degrades gracefully.

6. **Test error response format consistency** across all status codes.

### Phase 3: Edge Case Coverage (Target: 80%+ overall, 75%+ branch)

7. **Add boundary value tests** for numeric inputs, string lengths, pagination parameters.

8. **Add concurrency tests** for any endpoints that modify shared state (inventory, balances, counters).

9. **Add state transition tests** for any domain objects with status fields.

### Phase 4: Quality Validation

10. **Run mutation testing** to verify your tests actually catch bugs, not just execute code:

```bash
npx stryker run
```

A high mutation score (85%+) means your assertions are meaningful. A low score with high coverage confirms the "tests execute code but verify nothing" problem.

---

## Step 5: Set Up Coverage Gates

Once you have a baseline, enforce it so coverage never regresses.

### Jest configuration with per-directory thresholds

```javascript
// jest.config.js
module.exports = {
  collectCoverageFrom: [
    'src/**/*.{ts,js}',
    '!src/**/*.d.ts',
    '!src/types/**',
    '!src/**/index.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 75,
      functions: 80,
      lines: 80,
      statements: 80,
    },
    'src/services/**': {
      branches: 85,
      functions: 90,
      lines: 90,
    },
    'src/middleware/**': {
      branches: 90,
      lines: 90,
    },
    'src/routes/**': {
      branches: 75,
      lines: 80,
    },
  },
  coverageReporters: ['text', 'lcov', 'json-summary'],
};
```

### CI gate (GitHub Actions)

```yaml
- name: Check coverage thresholds
  run: |
    COVERAGE=$(cat coverage/coverage-summary.json | jq '.total.lines.pct')
    if (( $(echo "$COVERAGE < 80" | bc -l) )); then
      echo "Coverage $COVERAGE% is below 80% threshold"
      exit 1
    fi
```

---

## Step 6: Infrastructure You Need

Before writing tests, set up these foundations. Skipping them leads to flaky, slow, entangled tests.

### Test database isolation

Use transaction rollback for speed (the skill's recommended approach):

```typescript
// tests/setup.ts
let testClient: PoolClient;

beforeEach(async () => {
  testClient = await db.pool.connect();
  await testClient.query('BEGIN');
});

afterEach(async () => {
  await testClient.query('ROLLBACK');
  testClient.release();
});
```

Or with Prisma specifically, use `@quramy/prisma-fabbrica` or manual factories:

```typescript
// tests/helpers/factories.ts
let counter = 0;

export async function createUser(overrides: Partial<User> = {}) {
  counter++;
  return prisma.user.create({
    data: {
      email: overrides.email ?? `user${counter}@test.com`,
      name: overrides.name ?? `Test User ${counter}`,
      password: overrides.password ?? await hash('password123'),
      role: overrides.role ?? 'USER',
      ...overrides,
    },
  });
}
```

### Database cleanup between tests

```typescript
// tests/helpers/db.ts
export async function cleanDatabase() {
  const tablenames = await prisma.$queryRaw<Array<{ tablename: string }>>`
    SELECT tablename FROM pg_tables WHERE schemaname='public'
    AND tablename != '_prisma_migrations'
  `;

  for (const { tablename } of tablenames) {
    await prisma.$executeRawUnsafe(`TRUNCATE TABLE "${tablename}" CASCADE`);
  }
}
```

---

## Anti-Rationalization Checkpoint

Before you start writing tests, internalize the skill's Iron Law:

> **NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST.**

And specifically for your coverage audit, watch for these rationalizations that will derail you:

| You might think... | Reality |
|---|---|
| "I'll test the happy path now and add error tests later" | You won't. Error tests written "later" prove nothing -- they are written to pass. |
| "The error handler is just glue code, it doesn't need tests" | Glue code has the most integration bugs. Your global error handler is the most critical untested code. |
| "Prisma handles validation for us" | Prisma throws raw errors. YOUR code must catch and transform them. That transformation logic needs tests. |
| "The type system catches this" | Types catch type errors. They do not catch logic errors, race conditions, or edge cases. |
| "Testing this would require too much setup" | Complex setup is a design smell. Simplify the interface, then test. |
| "45% is fine for now, we'll improve incrementally" | 45% with happy-path-only tests means your error handling is 0% covered. Your API is unprotected. |

---

## Summary

Your 45% line coverage with suspected happy-path-only tests means:

- **Validation paths**: Likely 0-10% covered. Every malformed request is an untested path.
- **Auth rejection paths**: Likely partially covered (maybe the "no token" case) but missing expired tokens, wrong roles, ownership checks.
- **Database error paths**: Likely 0% covered. Unique violations, not-found, constraint failures all untested.
- **External dependency failures**: Likely 0% covered.
- **Edge cases**: Likely 0% covered. Empty strings, nulls, Unicode, large payloads, concurrency.

The fix is not to "add more tests" generically. It is to systematically audit each of the seven gap categories above against every endpoint, then work through the four phases in priority order. Start with your global error handler and auth middleware -- those two files protect your entire API surface.
