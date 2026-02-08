# TDD Patterns: API Design

## Test-First Workflow for REST Endpoints

1. Write supertest integration test for the endpoint
2. Define expected request/response shapes in the test
3. Run test — confirm it fails (404 or not implemented)
4. Implement route, handler, validation
5. Run test — confirm it passes
6. Add edge case tests (bad input, auth, not found)

## What to Test for Every Endpoint

| Test Case | HTTP Status | Example |
|-----------|-------------|---------|
| Success response | 200/201 | Valid request returns expected body |
| Validation error | 400 | Missing required field |
| Authentication failure | 401 | No token / expired token |
| Authorization failure | 403 | Valid user, wrong role |
| Resource not found | 404 | Valid ID format, no record |
| Conflict | 409 | Duplicate unique constraint |
| Server error | 500 | Forced error (mock DB failure) |

## Supertest Integration Test Template

```typescript
describe('POST /api/users', () => {
  it('creates user with valid data', async () => {
    const res = await request(app)
      .post('/api/users')
      .send({ name: 'Test', email: 'test@example.com' })
      .expect(201);

    expect(res.body).toMatchObject({
      id: expect.any(String),
      name: 'Test',
      email: 'test@example.com',
    });
  });

  it('rejects missing email', async () => {
    await request(app)
      .post('/api/users')
      .send({ name: 'Test' })
      .expect(400);
  });
});
```

## Contract Test Pattern

```typescript
import { OpenAPIValidator } from 'express-openapi-validator';

it('response matches OpenAPI schema', async () => {
  const res = await request(app).get('/api/users/1').expect(200);
  // Validate against spec
  expect(() => validator.validate(res.body, 'User')).not.toThrow();
});
```

## Pagination Test Pattern

```typescript
it('paginates results', async () => {
  // Seed 25 items
  const res = await request(app)
    .get('/api/items?page=2&limit=10')
    .expect(200);

  expect(res.body.data).toHaveLength(10);
  expect(res.body.meta.total).toBe(25);
  expect(res.body.meta.page).toBe(2);
});
```
