# Contract Testing

Validate API responses match your specification.

## What is Contract Testing?

Contract testing verifies that your API responses match a defined contract (schema). This catches:

- Missing required fields
- Wrong data types
- Unexpected fields
- Invalid formats
- Breaking changes

```
┌─────────────────┐      ┌─────────────────┐
│   API Spec      │      │   API Response  │
│   (Contract)    │  vs  │   (Actual)      │
│                 │      │                 │
│  - endpoints    │      │  - status       │
│  - schemas      │      │  - body         │
│  - types        │      │  - headers      │
└─────────────────┘      └─────────────────┘
         │                        │
         └────────┬───────────────┘
                  │
                  ▼
         ┌─────────────────┐
         │   Validation    │
         │   Pass / Fail   │
         └─────────────────┘
```

---

## OpenAPI Schema Validation

### Setup with AJV

```bash
npm install -D ajv ajv-formats @apidevtools/swagger-parser
```

### Load and Compile OpenAPI Spec

```typescript
// tests/helpers/schema-validator.ts
import Ajv from 'ajv';
import addFormats from 'ajv-formats';
import SwaggerParser from '@apidevtools/swagger-parser';
import { OpenAPIV3 } from 'openapi-types';

let ajv: Ajv;
let schemas: Record<string, object> = {};

export async function initSchemaValidator(specPath: string): Promise<void> {
  // Parse and dereference OpenAPI spec
  const spec = await SwaggerParser.dereference(specPath) as OpenAPIV3.Document;
  
  // Initialize AJV
  ajv = new Ajv({
    allErrors: true,
    strict: false,
    validateFormats: true,
  });
  addFormats(ajv);

  // Extract schemas from components
  if (spec.components?.schemas) {
    schemas = spec.components.schemas as Record<string, object>;
    
    // Add each schema to AJV
    for (const [name, schema] of Object.entries(schemas)) {
      ajv.addSchema(schema, name);
    }
  }
}

export function validateSchema(schemaName: string, data: unknown): {
  valid: boolean;
  errors: string[];
} {
  const validate = ajv.getSchema(schemaName);
  
  if (!validate) {
    return {
      valid: false,
      errors: [`Schema '${schemaName}' not found`],
    };
  }

  const valid = validate(data);
  
  return {
    valid: !!valid,
    errors: validate.errors?.map(e => 
      `${e.instancePath} ${e.message}`
    ) ?? [],
  };
}

export function getSchema(name: string): object | undefined {
  return schemas[name];
}
```

### Custom Matcher

```typescript
// tests/helpers/matchers/schema.ts
import { expect } from 'vitest';
import { validateSchema } from '../schema-validator';

expect.extend({
  toMatchSchema(received: unknown, schemaName: string) {
    const result = validateSchema(schemaName, received);
    
    return {
      pass: result.valid,
      message: () => result.valid
        ? `Expected not to match schema '${schemaName}'`
        : `Expected to match schema '${schemaName}':\n${result.errors.join('\n')}`,
    };
  },
});

// Type declaration
declare module 'vitest' {
  interface Assertion<T> {
    toMatchSchema(schemaName: string): void;
  }
}
```

### Contract Tests

```typescript
// tests/contracts/users.contract.test.ts
import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import { app } from '../../src/app';
import { initSchemaValidator } from '../helpers/schema-validator';
import { createUser } from '../helpers/factories';

describe('Users API Contract', () => {
  beforeAll(async () => {
    await initSchemaValidator('./openapi.yaml');
  });

  describe('GET /users', () => {
    it('returns response matching UserList schema', async () => {
      await createUser();
      await createUser();

      const response = await request(app)
        .get('/users')
        .expect(200);

      expect(response.body).toMatchSchema('UserList');
    });
  });

  describe('GET /users/:id', () => {
    it('returns response matching User schema', async () => {
      const user = await createUser();

      const response = await request(app)
        .get(`/users/${user.id}`)
        .expect(200);

      expect(response.body).toMatchSchema('User');
    });

    it('returns error matching Error schema for 404', async () => {
      const response = await request(app)
        .get('/users/non-existent')
        .expect(404);

      expect(response.body).toMatchSchema('Error');
    });
  });

  describe('POST /users', () => {
    it('returns response matching User schema on success', async () => {
      const response = await request(app)
        .post('/users')
        .send({
          email: 'new@example.com',
          name: 'New User',
          password: 'password123',
        })
        .expect(201);

      expect(response.body).toMatchSchema('User');
    });

    it('returns response matching ValidationError schema on 400', async () => {
      const response = await request(app)
        .post('/users')
        .send({ email: 'invalid' })
        .expect(400);

      expect(response.body).toMatchSchema('ValidationError');
    });
  });
});
```

---

## OpenAPI Spec Example

```yaml
# openapi.yaml
openapi: 3.0.3
info:
  title: My API
  version: 1.0.0

paths:
  /users:
    get:
      summary: List users
      responses:
        '200':
          description: List of users
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'
    post:
      summary: Create user
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/CreateUserInput'
      responses:
        '201':
          description: Created user
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '400':
          description: Validation error
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/ValidationError'

  /users/{id}:
    get:
      summary: Get user by ID
      parameters:
        - name: id
          in: path
          required: true
          schema:
            type: string
            format: uuid
      responses:
        '200':
          description: User found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/User'
        '404':
          description: User not found
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/Error'

components:
  schemas:
    User:
      type: object
      required:
        - id
        - email
        - name
        - createdAt
      properties:
        id:
          type: string
          format: uuid
        email:
          type: string
          format: email
        name:
          type: string
          minLength: 1
        role:
          type: string
          enum: [admin, user, guest]
          default: user
        createdAt:
          type: string
          format: date-time
        updatedAt:
          type: string
          format: date-time

    UserList:
      type: object
      required:
        - data
        - meta
      properties:
        data:
          type: array
          items:
            $ref: '#/components/schemas/User'
        meta:
          type: object
          properties:
            total:
              type: integer
            page:
              type: integer
            perPage:
              type: integer

    CreateUserInput:
      type: object
      required:
        - email
        - name
        - password
      properties:
        email:
          type: string
          format: email
        name:
          type: string
          minLength: 1
        password:
          type: string
          minLength: 8

    Error:
      type: object
      required:
        - status
        - error
        - message
      properties:
        status:
          type: integer
        error:
          type: string
        message:
          type: string

    ValidationError:
      type: object
      required:
        - status
        - message
        - errors
      properties:
        status:
          type: integer
          enum: [400]
        message:
          type: string
        errors:
          type: array
          items:
            type: object
            required:
              - field
              - message
            properties:
              field:
                type: string
              message:
                type: string
```

---

## Zod Schema Validation

Alternative approach using Zod for runtime validation.

### Setup

```bash
npm install zod
```

### Define Schemas

```typescript
// src/schemas/user.ts
import { z } from 'zod';

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  name: z.string().min(1),
  role: z.enum(['admin', 'user', 'guest']).default('user'),
  createdAt: z.string().datetime(),
  updatedAt: z.string().datetime().optional(),
});

export const UserListSchema = z.object({
  data: z.array(UserSchema),
  meta: z.object({
    total: z.number().int(),
    page: z.number().int(),
    perPage: z.number().int(),
  }),
});

export const CreateUserInputSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
  password: z.string().min(8),
});

export const ErrorSchema = z.object({
  status: z.number().int(),
  error: z.string(),
  message: z.string(),
});

export const ValidationErrorSchema = z.object({
  status: z.literal(400),
  message: z.string(),
  errors: z.array(z.object({
    field: z.string(),
    message: z.string(),
  })),
});

export type User = z.infer<typeof UserSchema>;
export type UserList = z.infer<typeof UserListSchema>;
export type CreateUserInput = z.infer<typeof CreateUserInputSchema>;
```

### Contract Tests with Zod

```typescript
// tests/contracts/users.contract.test.ts
import { describe, it, expect } from 'vitest';
import request from 'supertest';
import { app } from '../../src/app';
import { 
  UserSchema, 
  UserListSchema, 
  ErrorSchema,
  ValidationErrorSchema 
} from '../../src/schemas/user';
import { createUser } from '../helpers/factories';

describe('Users API Contract (Zod)', () => {
  describe('GET /users', () => {
    it('returns valid UserList', async () => {
      await createUser();

      const response = await request(app)
        .get('/users')
        .expect(200);

      const result = UserListSchema.safeParse(response.body);
      
      expect(result.success).toBe(true);
      if (!result.success) {
        console.error(result.error.format());
      }
    });
  });

  describe('GET /users/:id', () => {
    it('returns valid User', async () => {
      const user = await createUser();

      const response = await request(app)
        .get(`/users/${user.id}`)
        .expect(200);

      expect(() => UserSchema.parse(response.body)).not.toThrow();
    });

    it('returns valid Error for 404', async () => {
      const response = await request(app)
        .get('/users/non-existent')
        .expect(404);

      expect(() => ErrorSchema.parse(response.body)).not.toThrow();
    });
  });

  describe('POST /users', () => {
    it('returns valid User on success', async () => {
      const response = await request(app)
        .post('/users')
        .send({
          email: 'new@example.com',
          name: 'New User',
          password: 'password123',
        })
        .expect(201);

      const result = UserSchema.safeParse(response.body);
      expect(result.success).toBe(true);
    });

    it('returns valid ValidationError on 400', async () => {
      const response = await request(app)
        .post('/users')
        .send({ email: 'invalid' })
        .expect(400);

      const result = ValidationErrorSchema.safeParse(response.body);
      expect(result.success).toBe(true);
    });
  });
});
```

### Zod Custom Matcher

```typescript
// tests/helpers/matchers/zod.ts
import { expect } from 'vitest';
import { ZodSchema, ZodError } from 'zod';

expect.extend({
  toMatchZodSchema(received: unknown, schema: ZodSchema) {
    const result = schema.safeParse(received);
    
    if (result.success) {
      return {
        pass: true,
        message: () => 'Expected not to match schema',
      };
    }

    const errors = result.error.errors
      .map(e => `${e.path.join('.')}: ${e.message}`)
      .join('\n');

    return {
      pass: false,
      message: () => `Schema validation failed:\n${errors}`,
    };
  },
});

declare module 'vitest' {
  interface Assertion<T> {
    toMatchZodSchema(schema: ZodSchema): void;
  }
}

// Usage
expect(response.body).toMatchZodSchema(UserSchema);
```

---

## Response Shape Testing

For simpler cases without full schema validation.

### Structure Matching

```typescript
describe('Response Structure', () => {
  it('returns expected shape for User', async () => {
    const user = await createUser();

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    // Check structure without exact values
    expect(response.body).toMatchObject({
      id: expect.any(String),
      email: expect.any(String),
      name: expect.any(String),
      createdAt: expect.any(String),
    });

    // Check specific field formats
    expect(response.body.id).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
    );
    expect(response.body.createdAt).toMatch(/^\d{4}-\d{2}-\d{2}T/);
  });

  it('does not include sensitive fields', async () => {
    const user = await createUser();

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    expect(response.body.password).toBeUndefined();
    expect(response.body.passwordHash).toBeUndefined();
  });

  it('includes all required fields', async () => {
    const user = await createUser();

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    const requiredFields = ['id', 'email', 'name', 'createdAt'];
    
    for (const field of requiredFields) {
      expect(response.body).toHaveProperty(field);
    }
  });
});
```

### Type Checking

```typescript
describe('Response Types', () => {
  it('returns correct types', async () => {
    const user = await createUser();

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    expect(typeof response.body.id).toBe('string');
    expect(typeof response.body.email).toBe('string');
    expect(typeof response.body.name).toBe('string');
    expect(['admin', 'user', 'guest']).toContain(response.body.role);
  });

  it('returns array for list endpoints', async () => {
    const response = await request(app)
      .get('/users')
      .expect(200);

    expect(Array.isArray(response.body.data)).toBe(true);
    expect(typeof response.body.meta.total).toBe('number');
  });
});
```

---

## Breaking Change Detection

### Snapshot Contract Testing

```typescript
// tests/contracts/snapshots.test.ts
describe('API Contract Snapshots', () => {
  it('User response shape', async () => {
    const user = await createUser({
      email: 'snapshot@test.com',
      name: 'Snapshot User',
    });

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    // Snapshot with dynamic fields masked
    expect(response.body).toMatchSnapshot({
      id: expect.any(String),
      createdAt: expect.any(String),
      updatedAt: expect.any(String),
    });
  });

  it('Error response shape', async () => {
    const response = await request(app)
      .get('/users/non-existent')
      .expect(404);

    expect(response.body).toMatchInlineSnapshot(`
      {
        "error": "Not Found",
        "message": "User not found",
        "status": 404,
      }
    `);
  });
});
```

### Field Presence Tests

```typescript
// Catch accidental field removal
describe('Backward Compatibility', () => {
  const v1RequiredFields = ['id', 'email', 'name', 'createdAt'];
  const v1OptionalFields = ['role', 'updatedAt', 'avatar'];

  it('includes all v1 required fields', async () => {
    const user = await createUser();

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    for (const field of v1RequiredFields) {
      expect(response.body).toHaveProperty(field);
      expect(response.body[field]).not.toBeNull();
    }
  });

  it('supports all v1 optional fields', async () => {
    const user = await createUser({ role: 'admin' });

    const response = await request(app)
      .get(`/users/${user.id}`)
      .expect(200);

    // Optional fields can be present or absent, but not renamed
    for (const field of v1OptionalFields) {
      if (response.body[field] !== undefined) {
        expect(typeof response.body[field]).not.toBe('undefined');
      }
    }
  });
});
```

---

## Request Validation Testing

### Input Schema Tests

```typescript
describe('Request Validation', () => {
  describe('POST /users input validation', () => {
    it('accepts valid input', async () => {
      await request(app)
        .post('/users')
        .send({
          email: 'valid@example.com',
          name: 'Valid Name',
          password: 'securePassword123',
        })
        .expect(201);
    });

    it('rejects missing required fields', async () => {
      const response = await request(app)
        .post('/users')
        .send({})
        .expect(400);

      expect(response.body.errors).toEqual(
        expect.arrayContaining([
          expect.objectContaining({ field: 'email' }),
          expect.objectContaining({ field: 'name' }),
          expect.objectContaining({ field: 'password' }),
        ])
      );
    });

    it('rejects invalid email format', async () => {
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

    it('rejects password too short', async () => {
      const response = await request(app)
        .post('/users')
        .send({
          email: 'test@example.com',
          name: 'Test',
          password: '123', // Too short
        })
        .expect(400);

      expect(response.body.errors[0].field).toBe('password');
    });

    it('ignores unknown fields', async () => {
      const response = await request(app)
        .post('/users')
        .send({
          email: 'test@example.com',
          name: 'Test',
          password: 'password123',
          unknownField: 'should be ignored',
          anotherUnknown: 123,
        })
        .expect(201);

      expect(response.body.unknownField).toBeUndefined();
    });
  });
});
```

---

## CI Integration for Contract Tests

```yaml
# .github/workflows/contract-tests.yml
name: Contract Tests

on:
  push:
    paths:
      - 'openapi.yaml'
      - 'src/**'
      - 'tests/contracts/**'

jobs:
  contract-tests:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          
      - name: Install dependencies
        run: npm ci
        
      - name: Validate OpenAPI spec
        run: npx @redocly/cli lint openapi.yaml
        
      - name: Run contract tests
        run: npm run test:contracts
        
      - name: Check for breaking changes
        run: npx @redocly/cli diff openapi.yaml origin/main:openapi.yaml
```
