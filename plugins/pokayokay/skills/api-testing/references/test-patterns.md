# Test Patterns

Integration, E2E, and authentication testing patterns.

## Integration Test Patterns

### CRUD Endpoint Tests

```typescript
// tests/integration/users.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import request from 'supertest';
import { app } from '../../src/app';
import { db } from '../helpers/db';
import { createUser, createUsers } from '../helpers/factories';

describe('Users API', () => {
  beforeEach(async () => {
    await db.clear('users');
  });

  describe('GET /users', () => {
    it('returns empty array when no users', async () => {
      const response = await request(app)
        .get('/users')
        .expect(200);

      expect(response.body).toEqual([]);
    });

    it('returns all users', async () => {
      await createUsers(3);

      const response = await request(app)
        .get('/users')
        .expect(200);

      expect(response.body).toHaveLength(3);
    });

    it('supports pagination', async () => {
      await createUsers(15);

      const page1 = await request(app)
        .get('/users?page=1&limit=10')
        .expect(200);

      expect(page1.body.data).toHaveLength(10);
      expect(page1.body.meta.total).toBe(15);
      expect(page1.body.meta.page).toBe(1);

      const page2 = await request(app)
        .get('/users?page=2&limit=10')
        .expect(200);

      expect(page2.body.data).toHaveLength(5);
    });

    it('supports filtering', async () => {
      await createUser({ role: 'admin' });
      await createUser({ role: 'user' });
      await createUser({ role: 'user' });

      const response = await request(app)
        .get('/users?role=admin')
        .expect(200);

      expect(response.body).toHaveLength(1);
      expect(response.body[0].role).toBe('admin');
    });

    it('supports sorting', async () => {
      await createUser({ name: 'Charlie' });
      await createUser({ name: 'Alice' });
      await createUser({ name: 'Bob' });

      const response = await request(app)
        .get('/users?sort=name&order=asc')
        .expect(200);

      expect(response.body.map((u: any) => u.name)).toEqual([
        'Alice', 'Bob', 'Charlie'
      ]);
    });
  });

  describe('GET /users/:id', () => {
    it('returns user by id', async () => {
      const user = await createUser({
        email: 'test@example.com',
        name: 'Test User',
      });

      const response = await request(app)
        .get(`/users/${user.id}`)
        .expect(200);

      expect(response.body).toMatchObject({
        id: user.id,
        email: 'test@example.com',
        name: 'Test User',
      });
    });

    it('returns 404 for non-existent user', async () => {
      const response = await request(app)
        .get('/users/non-existent-id')
        .expect(404);

      expect(response.body.error).toBe('User not found');
    });

    it('returns 400 for invalid id format', async () => {
      await request(app)
        .get('/users/invalid-uuid-format')
        .expect(400);
    });
  });

  describe('POST /users', () => {
    it('creates user with valid data', async () => {
      const response = await request(app)
        .post('/users')
        .send({
          email: 'new@example.com',
          name: 'New User',
          password: 'securePassword123',
        })
        .expect(201);

      expect(response.body).toMatchObject({
        email: 'new@example.com',
        name: 'New User',
      });
      expect(response.body.id).toBeDefined();
      expect(response.body.password).toBeUndefined(); // Not returned
    });

    it('returns 400 for missing required fields', async () => {
      const response = await request(app)
        .post('/users')
        .send({ name: 'No Email' })
        .expect(400);

      expect(response.body.errors).toContainEqual(
        expect.objectContaining({
          field: 'email',
          message: expect.any(String),
        })
      );
    });

    it('returns 400 for invalid email', async () => {
      const response = await request(app)
        .post('/users')
        .send({
          email: 'not-an-email',
          name: 'Test',
          password: 'password123',
        })
        .expect(400);

      expect(response.body.errors[0].field).toBe('email');
    });

    it('returns 409 for duplicate email', async () => {
      await createUser({ email: 'duplicate@example.com' });

      await request(app)
        .post('/users')
        .send({
          email: 'duplicate@example.com',
          name: 'Duplicate',
          password: 'password123',
        })
        .expect(409);
    });
  });

  describe('PUT /users/:id', () => {
    it('updates user with valid data', async () => {
      const user = await createUser({ name: 'Original' });

      const response = await request(app)
        .put(`/users/${user.id}`)
        .send({ name: 'Updated' })
        .expect(200);

      expect(response.body.name).toBe('Updated');
    });

    it('returns 404 for non-existent user', async () => {
      await request(app)
        .put('/users/non-existent')
        .send({ name: 'Test' })
        .expect(404);
    });

    it('validates update data', async () => {
      const user = await createUser();

      await request(app)
        .put(`/users/${user.id}`)
        .send({ email: 'invalid-email' })
        .expect(400);
    });
  });

  describe('DELETE /users/:id', () => {
    it('deletes user', async () => {
      const user = await createUser();

      await request(app)
        .delete(`/users/${user.id}`)
        .expect(204);

      // Verify deleted
      await request(app)
        .get(`/users/${user.id}`)
        .expect(404);
    });

    it('returns 404 for non-existent user', async () => {
      await request(app)
        .delete('/users/non-existent')
        .expect(404);
    });

    it('returns 204 for already deleted user (idempotent)', async () => {
      const user = await createUser();

      await request(app).delete(`/users/${user.id}`).expect(204);
      await request(app).delete(`/users/${user.id}`).expect(204);
    });
  });
});
```

### Relationship Tests

```typescript
describe('Orders API', () => {
  describe('GET /users/:userId/orders', () => {
    it('returns orders for user', async () => {
      const user = await createUser();
      await createOrder({ userId: user.id });
      await createOrder({ userId: user.id });

      const response = await request(app)
        .get(`/users/${user.id}/orders`)
        .expect(200);

      expect(response.body).toHaveLength(2);
      response.body.forEach((order: any) => {
        expect(order.userId).toBe(user.id);
      });
    });

    it('returns empty array for user with no orders', async () => {
      const user = await createUser();

      const response = await request(app)
        .get(`/users/${user.id}/orders`)
        .expect(200);

      expect(response.body).toEqual([]);
    });

    it('returns 404 for non-existent user', async () => {
      await request(app)
        .get('/users/non-existent/orders')
        .expect(404);
    });
  });

  describe('POST /orders', () => {
    it('creates order with items', async () => {
      const user = await createUser();
      const product1 = await createProduct({ price: 100 });
      const product2 = await createProduct({ price: 200 });

      const response = await request(app)
        .post('/orders')
        .send({
          userId: user.id,
          items: [
            { productId: product1.id, quantity: 2 },
            { productId: product2.id, quantity: 1 },
          ],
        })
        .expect(201);

      expect(response.body.items).toHaveLength(2);
      expect(response.body.total).toBe(400); // 2*100 + 1*200
    });
  });
});
```

---

## Authentication Test Patterns

### Login/Logout Tests

```typescript
describe('Auth API', () => {
  describe('POST /auth/login', () => {
    it('returns tokens for valid credentials', async () => {
      await createUser({
        email: 'user@example.com',
        password: 'correctpassword',
      });

      const response = await request(app)
        .post('/auth/login')
        .send({
          email: 'user@example.com',
          password: 'correctpassword',
        })
        .expect(200);

      expect(response.body).toMatchObject({
        accessToken: expect.any(String),
        refreshToken: expect.any(String),
        expiresIn: expect.any(Number),
      });
    });

    it('returns 401 for wrong password', async () => {
      await createUser({
        email: 'user@example.com',
        password: 'correctpassword',
      });

      await request(app)
        .post('/auth/login')
        .send({
          email: 'user@example.com',
          password: 'wrongpassword',
        })
        .expect(401);
    });

    it('returns 401 for non-existent user', async () => {
      await request(app)
        .post('/auth/login')
        .send({
          email: 'nonexistent@example.com',
          password: 'anypassword',
        })
        .expect(401);
    });

    it('rate limits after multiple failures', async () => {
      await createUser({ email: 'user@example.com', password: 'password' });

      // Fail 5 times
      for (let i = 0; i < 5; i++) {
        await request(app)
          .post('/auth/login')
          .send({ email: 'user@example.com', password: 'wrong' });
      }

      // 6th attempt should be rate limited
      await request(app)
        .post('/auth/login')
        .send({ email: 'user@example.com', password: 'password' })
        .expect(429);
    });
  });

  describe('POST /auth/refresh', () => {
    it('returns new tokens for valid refresh token', async () => {
      const user = await createUser();
      const { refreshToken } = await loginAs(user);

      const response = await request(app)
        .post('/auth/refresh')
        .send({ refreshToken })
        .expect(200);

      expect(response.body.accessToken).toBeDefined();
      expect(response.body.accessToken).not.toBe(refreshToken);
    });

    it('returns 401 for invalid refresh token', async () => {
      await request(app)
        .post('/auth/refresh')
        .send({ refreshToken: 'invalid-token' })
        .expect(401);
    });

    it('returns 401 for expired refresh token', async () => {
      const expiredToken = await createExpiredRefreshToken();

      await request(app)
        .post('/auth/refresh')
        .send({ refreshToken: expiredToken })
        .expect(401);
    });
  });

  describe('POST /auth/logout', () => {
    it('invalidates refresh token', async () => {
      const user = await createUser();
      const { accessToken, refreshToken } = await loginAs(user);

      // Logout
      await request(app)
        .post('/auth/logout')
        .set('Authorization', `Bearer ${accessToken}`)
        .expect(204);

      // Refresh should fail
      await request(app)
        .post('/auth/refresh')
        .send({ refreshToken })
        .expect(401);
    });
  });
});
```

### Protected Route Tests

```typescript
describe('Protected Routes', () => {
  describe('GET /users/me', () => {
    it('returns current user with valid token', async () => {
      const user = await createUser({ name: 'Current User' });
      const token = await getAuthToken(user);

      const response = await request(app)
        .get('/users/me')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(response.body.name).toBe('Current User');
    });

    it('returns 401 without token', async () => {
      await request(app)
        .get('/users/me')
        .expect(401);
    });

    it('returns 401 with invalid token', async () => {
      await request(app)
        .get('/users/me')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });

    it('returns 401 with expired token', async () => {
      const expiredToken = await createExpiredToken();

      await request(app)
        .get('/users/me')
        .set('Authorization', `Bearer ${expiredToken}`)
        .expect(401);
    });

    it('returns 401 with malformed authorization header', async () => {
      await request(app)
        .get('/users/me')
        .set('Authorization', 'InvalidFormat token')
        .expect(401);
    });
  });
});
```

### Authorization (Roles) Tests

```typescript
describe('Authorization', () => {
  describe('Admin-only routes', () => {
    it('allows admin users', async () => {
      const admin = await createUser({ role: 'admin' });
      const token = await getAuthToken(admin);

      await request(app)
        .get('/admin/users')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
    });

    it('denies non-admin users', async () => {
      const user = await createUser({ role: 'user' });
      const token = await getAuthToken(user);

      await request(app)
        .get('/admin/users')
        .set('Authorization', `Bearer ${token}`)
        .expect(403);
    });
  });

  describe('Resource ownership', () => {
    it('allows users to access their own resources', async () => {
      const user = await createUser();
      const order = await createOrder({ userId: user.id });
      const token = await getAuthToken(user);

      await request(app)
        .get(`/orders/${order.id}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
    });

    it('denies access to other users resources', async () => {
      const user1 = await createUser();
      const user2 = await createUser();
      const order = await createOrder({ userId: user1.id });
      const token = await getAuthToken(user2);

      await request(app)
        .get(`/orders/${order.id}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(403);
    });

    it('allows admins to access any resource', async () => {
      const user = await createUser();
      const admin = await createUser({ role: 'admin' });
      const order = await createOrder({ userId: user.id });
      const token = await getAuthToken(admin);

      await request(app)
        .get(`/orders/${order.id}`)
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
    });
  });
});
```

### Auth Helper Functions

```typescript
// tests/helpers/auth.ts
import jwt from 'jsonwebtoken';
import { User } from '../../src/types';
import { db } from './db';

const JWT_SECRET = process.env.JWT_SECRET || 'test-secret';

export async function getAuthToken(user: User): Promise<string> {
  return jwt.sign(
    { userId: user.id, role: user.role },
    JWT_SECRET,
    { expiresIn: '1h' }
  );
}

export async function loginAs(user: User): Promise<{
  accessToken: string;
  refreshToken: string;
}> {
  // Use actual login endpoint for more realistic test
  const response = await request(app)
    .post('/auth/login')
    .send({ email: user.email, password: 'password' });
  
  return response.body;
}

export async function createExpiredToken(): Promise<string> {
  const user = await createUser();
  return jwt.sign(
    { userId: user.id },
    JWT_SECRET,
    { expiresIn: '-1h' } // Already expired
  );
}

export async function createTokenForRole(role: string): Promise<string> {
  const user = await createUser({ role });
  return getAuthToken(user);
}

// For tests that need multiple roles
export async function createTestUsers(): Promise<{
  admin: { user: User; token: string };
  user: { user: User; token: string };
  guest: { user: User; token: string };
}> {
  const admin = await createUser({ role: 'admin', email: 'admin@test.com' });
  const user = await createUser({ role: 'user', email: 'user@test.com' });
  const guest = await createUser({ role: 'guest', email: 'guest@test.com' });

  return {
    admin: { user: admin, token: await getAuthToken(admin) },
    user: { user: user, token: await getAuthToken(user) },
    guest: { user: guest, token: await getAuthToken(guest) },
  };
}
```

---

## E2E Flow Tests

### Multi-Step Workflows

```typescript
describe('E2E: Checkout Flow', () => {
  it('completes full checkout process', async () => {
    // Setup
    const user = await createUser();
    const token = await getAuthToken(user);
    const product = await createProduct({ price: 99.99, stock: 10 });

    // 1. Add to cart
    const addToCartRes = await request(app)
      .post('/cart/items')
      .set('Authorization', `Bearer ${token}`)
      .send({ productId: product.id, quantity: 2 })
      .expect(201);

    expect(addToCartRes.body.items).toHaveLength(1);
    expect(addToCartRes.body.total).toBe(199.98);

    // 2. Get cart
    const cartRes = await request(app)
      .get('/cart')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(cartRes.body.items[0].productId).toBe(product.id);

    // 3. Create order from cart
    const orderRes = await request(app)
      .post('/orders')
      .set('Authorization', `Bearer ${token}`)
      .send({
        shippingAddress: {
          street: '123 Main St',
          city: 'Test City',
          zip: '12345',
        },
      })
      .expect(201);

    expect(orderRes.body.status).toBe('pending');
    expect(orderRes.body.total).toBe(199.98);

    // 4. Process payment
    const paymentRes = await request(app)
      .post(`/orders/${orderRes.body.id}/pay`)
      .set('Authorization', `Bearer ${token}`)
      .send({
        paymentMethod: 'card',
        cardToken: 'tok_test_123',
      })
      .expect(200);

    expect(paymentRes.body.status).toBe('paid');

    // 5. Verify order status
    const finalOrderRes = await request(app)
      .get(`/orders/${orderRes.body.id}`)
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(finalOrderRes.body.status).toBe('paid');

    // 6. Verify stock was reduced
    const updatedProduct = await request(app)
      .get(`/products/${product.id}`)
      .expect(200);

    expect(updatedProduct.body.stock).toBe(8);

    // 7. Verify cart was cleared
    const emptyCartRes = await request(app)
      .get('/cart')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(emptyCartRes.body.items).toHaveLength(0);
  });
});
```

### User Registration Flow

```typescript
describe('E2E: User Registration', () => {
  it('registers, verifies email, and logs in', async () => {
    // 1. Register
    const registerRes = await request(app)
      .post('/auth/register')
      .send({
        email: 'newuser@example.com',
        password: 'SecurePass123!',
        name: 'New User',
      })
      .expect(201);

    expect(registerRes.body.message).toContain('verification email');

    // 2. Get verification token (in real app, this would come from email)
    const verificationToken = await getVerificationTokenFromDB('newuser@example.com');

    // 3. Verify email
    await request(app)
      .post('/auth/verify-email')
      .send({ token: verificationToken })
      .expect(200);

    // 4. Login
    const loginRes = await request(app)
      .post('/auth/login')
      .send({
        email: 'newuser@example.com',
        password: 'SecurePass123!',
      })
      .expect(200);

    expect(loginRes.body.accessToken).toBeDefined();

    // 5. Access protected resource
    await request(app)
      .get('/users/me')
      .set('Authorization', `Bearer ${loginRes.body.accessToken}`)
      .expect(200);
  });

  it('cannot login without email verification', async () => {
    // Register but don't verify
    await request(app)
      .post('/auth/register')
      .send({
        email: 'unverified@example.com',
        password: 'SecurePass123!',
        name: 'Unverified User',
      })
      .expect(201);

    // Try to login
    const response = await request(app)
      .post('/auth/login')
      .send({
        email: 'unverified@example.com',
        password: 'SecurePass123!',
      })
      .expect(403);

    expect(response.body.error).toContain('verify');
  });
});
```

### Password Reset Flow

```typescript
describe('E2E: Password Reset', () => {
  it('resets password via email token', async () => {
    const user = await createUser({
      email: 'reset@example.com',
      password: 'oldPassword123',
    });

    // 1. Request password reset
    await request(app)
      .post('/auth/forgot-password')
      .send({ email: 'reset@example.com' })
      .expect(200);

    // 2. Get reset token (from DB in tests)
    const resetToken = await getPasswordResetToken('reset@example.com');

    // 3. Reset password
    await request(app)
      .post('/auth/reset-password')
      .send({
        token: resetToken,
        password: 'newPassword456',
      })
      .expect(200);

    // 4. Old password no longer works
    await request(app)
      .post('/auth/login')
      .send({
        email: 'reset@example.com',
        password: 'oldPassword123',
      })
      .expect(401);

    // 5. New password works
    await request(app)
      .post('/auth/login')
      .send({
        email: 'reset@example.com',
        password: 'newPassword456',
      })
      .expect(200);
  });
});
```

---

## Error Response Tests

### Validation Error Testing

```typescript
describe('Validation Errors', () => {
  it('returns structured validation errors', async () => {
    const response = await request(app)
      .post('/users')
      .send({
        email: 'invalid',
        name: '', // Empty
        age: -5, // Invalid
      })
      .expect(400);

    expect(response.body).toMatchObject({
      status: 400,
      message: 'Validation failed',
      errors: expect.arrayContaining([
        expect.objectContaining({
          field: 'email',
          message: expect.any(String),
        }),
        expect.objectContaining({
          field: 'name',
          message: expect.any(String),
        }),
        expect.objectContaining({
          field: 'age',
          message: expect.any(String),
        }),
      ]),
    });
  });

  it('returns all validation errors at once', async () => {
    const response = await request(app)
      .post('/users')
      .send({}) // Missing everything
      .expect(400);

    // Should return all errors, not just first
    expect(response.body.errors.length).toBeGreaterThan(1);
  });
});
```

### Error Response Format

```typescript
describe('Error Response Format', () => {
  it('returns consistent error format for 400', async () => {
    const response = await request(app)
      .post('/users')
      .send({})
      .expect(400);

    expect(response.body).toMatchObject({
      status: 400,
      error: expect.any(String),
      message: expect.any(String),
    });
  });

  it('returns consistent error format for 401', async () => {
    const response = await request(app)
      .get('/users/me')
      .expect(401);

    expect(response.body).toMatchObject({
      status: 401,
      error: 'Unauthorized',
      message: expect.any(String),
    });
  });

  it('returns consistent error format for 404', async () => {
    const response = await request(app)
      .get('/users/non-existent')
      .expect(404);

    expect(response.body).toMatchObject({
      status: 404,
      error: 'Not Found',
      message: expect.any(String),
    });
  });

  it('returns consistent error format for 500', async () => {
    // Trigger internal error (e.g., via test route)
    const response = await request(app)
      .get('/test/trigger-error')
      .expect(500);

    expect(response.body).toMatchObject({
      status: 500,
      error: 'Internal Server Error',
      message: expect.any(String),
    });
    // Should not expose stack trace in production
    expect(response.body.stack).toBeUndefined();
  });
});
```

---

## Edge Case Tests

```typescript
describe('Edge Cases', () => {
  describe('Empty and null values', () => {
    it('handles empty string', async () => {
      const response = await request(app)
        .post('/users')
        .send({ email: '', name: '' })
        .expect(400);

      expect(response.body.errors).toBeDefined();
    });

    it('handles null values', async () => {
      const response = await request(app)
        .post('/users')
        .send({ email: null, name: null })
        .expect(400);
    });

    it('handles undefined values', async () => {
      const response = await request(app)
        .post('/users')
        .send({})
        .expect(400);
    });
  });

  describe('Large data', () => {
    it('rejects oversized request body', async () => {
      const largeString = 'x'.repeat(1_000_000); // 1MB

      await request(app)
        .post('/users')
        .send({ name: largeString })
        .expect(413); // Payload Too Large
    });

    it('handles pagination with large dataset', async () => {
      await createUsers(1000);

      const response = await request(app)
        .get('/users?limit=100')
        .expect(200);

      expect(response.body.data).toHaveLength(100);
    });
  });

  describe('Special characters', () => {
    it('handles unicode in names', async () => {
      const response = await request(app)
        .post('/users')
        .send({
          email: 'unicode@example.com',
          name: '日本語 名前 🎉',
          password: 'password123',
        })
        .expect(201);

      expect(response.body.name).toBe('日本語 名前 🎉');
    });

    it('escapes HTML in responses', async () => {
      const user = await createUser({
        name: '<script>alert("xss")</script>',
      });

      const response = await request(app)
        .get(`/users/${user.id}`)
        .expect(200);

      // Response should not contain raw HTML
      expect(response.text).not.toContain('<script>');
    });
  });

  describe('Concurrent requests', () => {
    it('handles concurrent updates correctly', async () => {
      const product = await createProduct({ stock: 10 });

      // Simulate concurrent purchases
      const results = await Promise.all([
        request(app).post(`/products/${product.id}/purchase`).send({ quantity: 3 }),
        request(app).post(`/products/${product.id}/purchase`).send({ quantity: 4 }),
        request(app).post(`/products/${product.id}/purchase`).send({ quantity: 5 }),
      ]);

      // At least one should fail (not enough stock)
      const failed = results.filter(r => r.status === 400);
      expect(failed.length).toBeGreaterThan(0);

      // Final stock should be consistent
      const finalProduct = await request(app).get(`/products/${product.id}`);
      expect(finalProduct.body.stock).toBeGreaterThanOrEqual(0);
    });
  });
});
```
