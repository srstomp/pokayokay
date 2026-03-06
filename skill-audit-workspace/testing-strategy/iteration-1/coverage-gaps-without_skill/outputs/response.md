# Coverage Gap Audit: Node.js REST API (Express + Prisma + PostgreSQL)

## Assessment Summary

45% line coverage with suspected happy-path bias is a common pattern in Express/Prisma projects. Line coverage alone is misleading -- it measures which lines executed, not which behaviors were verified. A test that calls an endpoint and checks `status === 200` will "cover" the entire handler including error branches that happen not to fire, inflating the number without actually testing anything.

Below is a systematic audit framework and the specific gap categories most likely present in your stack.

---

## Phase 1: Quantify the Happy-Path Bias

Before writing new tests, confirm the hypothesis with data.

### 1.1 Branch Coverage vs. Line Coverage

Run your test suite with branch coverage enabled:

```bash
# If using Jest
npx jest --coverage --coverageReporters=json-summary --coverageReporters=lcov

# If using c8/vitest
npx c8 --branches --reporter=lcov npm test
```

Compare the `lines` percentage against `branches`. A large gap (e.g., 45% lines but 18% branches) confirms that tests are executing code paths without actually exercising conditional logic. Branch coverage is the real metric for error-handling adequacy.

### 1.2 Identify Uncovered Branches

Open the HTML coverage report (`coverage/lcov-report/index.html`) and sort by branch coverage ascending. The files with the worst branch coverage are your highest-priority targets. Focus on files that are both low-branch-coverage and high-importance (auth, payments, data mutations).

### 1.3 Mutation Testing (Optional but Revealing)

```bash
npx stryker init
npx stryker run
```

Mutation testing modifies your source code (e.g., flips `===` to `!==`, removes `throw` statements) and checks if tests catch the change. A mutation score below 30% on a file with 80% line coverage proves the tests are superficial.

---

## Phase 2: Critical Gap Categories

These are the specific categories of untested behavior most likely missing in an Express/Prisma/PostgreSQL API at 45% coverage.

### 2.1 Input Validation and Malformed Requests

**What is probably untested:**
- Missing required fields in request bodies
- Wrong data types (string where number expected, nested object where string expected)
- Boundary values (empty strings, zero, negative numbers, extremely long strings)
- Array fields with zero elements, duplicate elements, or excessive elements
- Malformed JSON bodies (`Content-Type: application/json` with invalid JSON)
- Query parameter injection (arrays where scalar expected, special characters)
- Path parameter edge cases (non-numeric IDs, UUIDs vs. integers, URL-encoded values)

**What to write:**
```typescript
// Example: test that missing required field returns 400, not 500
describe('POST /api/resources', () => {
  it('returns 400 when name is missing', async () => {
    const res = await request(app).post('/api/resources').send({ /* no name */ });
    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/name/i);
  });

  it('returns 400 when name is empty string', async () => {
    const res = await request(app).post('/api/resources').send({ name: '' });
    expect(res.status).toBe(400);
  });

  it('returns 400 on malformed JSON body', async () => {
    const res = await request(app)
      .post('/api/resources')
      .set('Content-Type', 'application/json')
      .send('{"name": broken}');
    expect(res.status).toBe(400);
  });
});
```

**Priority: HIGH** -- Input validation gaps are the most common source of both 500 errors in production and security vulnerabilities.

### 2.2 Prisma Error Handling

**What is probably untested:**
- Unique constraint violations (`P2002`) -- e.g., duplicate email on registration
- Foreign key constraint failures (`P2003`) -- e.g., referencing a deleted parent record
- Record not found (`P2025`) -- e.g., updating/deleting a nonexistent row
- Connection failures / timeouts -- Prisma client throws when PostgreSQL is unreachable
- Transaction rollback behavior -- partial failure in `prisma.$transaction()`
- Concurrent modification -- two requests updating the same row simultaneously

**What to write:**
```typescript
describe('POST /api/users', () => {
  it('returns 409 on duplicate email', async () => {
    await createUser({ email: 'taken@example.com' });
    const res = await request(app)
      .post('/api/users')
      .send({ email: 'taken@example.com', name: 'Duplicate' });
    expect(res.status).toBe(409);
    expect(res.body.error).toMatch(/already exists/i);
  });
});

describe('DELETE /api/teams/:id', () => {
  it('returns 404 when team does not exist', async () => {
    const res = await request(app).delete('/api/teams/nonexistent-id');
    expect(res.status).toBe(404);
  });

  it('returns 409 when team has active members (FK constraint)', async () => {
    const team = await createTeamWithMembers();
    const res = await request(app).delete(`/api/teams/${team.id}`);
    expect(res.status).toBe(409);
  });
});
```

**Priority: HIGH** -- Unhandled Prisma errors typically bubble up as raw 500 responses with stack traces, leaking internal details.

### 2.3 Authentication and Authorization

**What is probably untested:**
- Requests with no auth token at all (missing `Authorization` header)
- Expired tokens
- Malformed tokens (not valid JWT, truncated, wrong algorithm)
- Valid token but insufficient permissions (role-based access)
- Token for a deleted or deactivated user
- Cross-tenant access (user A accessing user B's resources)
- Auth on every protected endpoint (not just the ones you remembered to test)

**What to write:**
```typescript
describe('GET /api/admin/users', () => {
  it('returns 401 with no token', async () => {
    const res = await request(app).get('/api/admin/users');
    expect(res.status).toBe(401);
  });

  it('returns 403 for non-admin user', async () => {
    const token = await getTokenForRole('viewer');
    const res = await request(app)
      .get('/api/admin/users')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(403);
  });

  it('returns 401 for expired token', async () => {
    const token = createExpiredToken();
    const res = await request(app)
      .get('/api/admin/users')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(401);
  });
});
```

**Priority: CRITICAL** -- Authorization gaps are security vulnerabilities, not just bugs.

### 2.4 Error Middleware and Global Error Handler

**What is probably untested:**
- The global Express error handler (`app.use((err, req, res, next) => { ... })`)
- That it returns a consistent error response shape (not raw stack traces)
- That it logs errors properly
- That it handles non-Error throws (string throws, undefined throws)
- 404 handler for undefined routes
- Behavior when middleware throws before reaching a route handler

**What to write:**
```typescript
describe('Global error handling', () => {
  it('returns 404 for undefined routes', async () => {
    const res = await request(app).get('/api/nonexistent');
    expect(res.status).toBe(404);
    expect(res.body).toHaveProperty('error');
  });

  it('does not leak stack traces in production', async () => {
    // Trigger a known error path
    const res = await request(app).get('/api/resources/trigger-error');
    expect(res.body).not.toHaveProperty('stack');
  });
});
```

**Priority: HIGH** -- If the global error handler is untested, you do not know what users see when things break.

### 2.5 Pagination, Filtering, and Query Edge Cases

**What is probably untested:**
- Page 0, page -1, page with non-numeric value
- Page beyond total results (should return empty array, not error)
- Very large page size (e.g., `?limit=999999`)
- Sort by nonexistent column
- Filter with SQL injection attempts (Prisma parameterizes, but does your API reject or silently ignore bad filters?)
- Combination of multiple filters that result in zero rows
- Empty collection responses (first request to a new tenant)

**Priority: MEDIUM** -- These rarely cause outages but produce confusing behavior and poor API ergonomics.

### 2.6 Concurrency and Race Conditions

**What is probably untested:**
- Two simultaneous updates to the same resource (last-write-wins vs. optimistic locking)
- Creating a resource that depends on another resource being deleted concurrently
- Rate limiting behavior under concurrent requests
- Database connection pool exhaustion under load

**Priority: MEDIUM** -- Hard to test but responsible for the most confusing production bugs. At minimum, test that concurrent duplicate creation does not produce two records.

### 2.7 File Upload and External Service Failures

**What is probably untested (if applicable):**
- Uploading a file exceeding size limit
- Uploading a file with wrong MIME type
- Upload with no file attached
- External service (email, S3, payment gateway) returning an error
- External service timing out
- External service returning unexpected response shape

**Priority: MEDIUM-HIGH** -- External service failures are guaranteed to happen in production.

### 2.8 Response Shape Consistency

**What is probably untested:**
- That error responses follow a consistent schema (`{ error: string, code?: string, details?: object }`)
- That success responses include all documented fields
- That responses do not leak internal fields (password hashes, internal IDs, soft-delete flags)
- That list endpoints return arrays (not null, not undefined) when empty

**Priority: MEDIUM** -- Inconsistent response shapes break frontend consumers in subtle ways.

---

## Phase 3: Prioritized Action Plan

### Immediate (Week 1) -- Highest Impact

1. **Add branch coverage to CI.** Change your coverage config to report branches. Set a baseline and prevent regression.

2. **Audit auth on every endpoint.** Write a meta-test that iterates over all registered routes and confirms each protected endpoint returns 401 without a token. This is a force-multiplier test.

   ```typescript
   // Pseudocode for route-level auth audit
   import { getRegisteredRoutes } from './test-utils';

   const protectedRoutes = getRegisteredRoutes().filter(r => !r.isPublic);
   for (const route of protectedRoutes) {
     it(`${route.method} ${route.path} returns 401 without auth`, async () => {
       const res = await request(app)[route.method](route.path);
       expect(res.status).toBe(401);
     });
   }
   ```

3. **Test every Prisma catch block.** Search for `catch` blocks in your service/repository layer. Each one represents an error path that should have a dedicated test. If there are no catch blocks around Prisma calls, that itself is a critical finding -- it means errors are bubbling unhandled.

   ```bash
   # Find Prisma error handling (or lack thereof)
   grep -rn "catch" src/services/ src/repositories/ --include="*.ts"
   grep -rn "prisma\." src/ --include="*.ts" -l  # files using Prisma
   ```

### Short-Term (Weeks 2-3)

4. **Input validation tests for every POST/PUT/PATCH endpoint.** For each endpoint, test: missing required fields, wrong types, boundary values, empty body.

5. **Global error handler tests.** Confirm the error handler returns consistent shapes and does not leak stack traces.

6. **404 and not-found tests for every parameterized route.** Every `/:id` route should return 404 (not 500) for a nonexistent ID.

### Medium-Term (Weeks 4-6)

7. **Transaction failure tests.** For every `$transaction` call, test what happens when one operation in the transaction fails.

8. **External service mock-failure tests.** For every integration point, test the failure path with a mocked error response.

9. **Pagination edge case tests.** Cover zero results, beyond-last-page, invalid parameters.

---

## Phase 4: Structural Recommendations

### Centralize Error Handling

If you do not already have a pattern like this, adopt one:

```typescript
// src/errors.ts
export class AppError extends Error {
  constructor(
    public statusCode: number,
    public code: string,
    message: string,
    public details?: Record<string, unknown>
  ) {
    super(message);
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id: string) {
    super(404, 'NOT_FOUND', `${resource} with id ${id} not found`);
  }
}

export class ConflictError extends AppError {
  constructor(message: string) {
    super(409, 'CONFLICT', message);
  }
}
```

Centralized errors make testing predictable -- you know every 404 uses the same class, so you can test the class once and then just verify the status code in endpoint tests.

### Prisma Error Mapping

Create a utility that translates Prisma error codes to your application errors:

```typescript
export function handlePrismaError(error: unknown): never {
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    switch (error.code) {
      case 'P2002':
        throw new ConflictError(`Unique constraint violation on ${error.meta?.target}`);
      case 'P2003':
        throw new ConflictError('Referenced record does not exist');
      case 'P2025':
        throw new NotFoundError('Record', 'unknown');
      default:
        throw new AppError(500, 'DATABASE_ERROR', 'Unexpected database error');
    }
  }
  throw error;
}
```

This is both good architecture and makes testing easier -- you test the mapper once thoroughly, then verify each endpoint delegates to it.

### Test Helpers

Build a small set of test utilities to reduce friction for writing error-path tests:

```typescript
// test/helpers.ts
export async function expectValidationError(
  method: 'get' | 'post' | 'put' | 'patch' | 'delete',
  path: string,
  body: unknown,
  expectedField: string
) {
  const res = await request(app)[method](path)
    .set('Authorization', `Bearer ${validToken}`)
    .send(body);
  expect(res.status).toBe(400);
  expect(res.body.error).toMatch(new RegExp(expectedField, 'i'));
}
```

---

## Coverage Target Recommendations

| Metric | Current (est.) | 3-Month Target | Notes |
|--------|----------------|----------------|-------|
| Line coverage | 45% | 70% | Secondary metric |
| Branch coverage | ~18% (est.) | 55% | Primary metric |
| Auth endpoint coverage | Unknown | 100% | Every protected route tested for 401/403 |
| Error handler coverage | ~10% (est.) | 80% | Every catch block should have a test |
| Prisma error path coverage | ~5% (est.) | 70% | P2002, P2003, P2025 at minimum |

The goal is not a coverage number. The goal is that when something breaks in production, a test should have caught it. Error-path and edge-case tests are what get you there. Happy-path tests just confirm you shipped the feature.
