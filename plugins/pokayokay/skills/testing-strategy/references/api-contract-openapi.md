# Contract Testing with OpenAPI

Validate API responses match your specification using OpenAPI and AJV.

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
