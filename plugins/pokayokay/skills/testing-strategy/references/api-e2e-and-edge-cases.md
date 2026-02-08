# API E2E Flow and Edge Case Tests

Multi-step workflow tests, error response validation, and edge case patterns.

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
