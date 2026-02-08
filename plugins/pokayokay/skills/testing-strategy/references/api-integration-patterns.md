# API Integration Test Patterns

Integration and relationship testing patterns for API endpoints.

## CRUD Endpoint Tests

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

## Relationship Tests

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
