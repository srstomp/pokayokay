# API Authentication Test Patterns

Authentication, authorization, and protected route testing patterns.

## Login/Logout Tests

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

## Protected Route Tests

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

## Authorization (Roles) Tests

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

## Auth Helper Functions

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
