# OpenAPI Consumption: Specs & Type Generation

Parsing OpenAPI specs and strategies for generating TypeScript types.

## OpenAPI Spec Analysis

### Spec Structure Overview

```yaml
openapi: 3.0.0
info:
  title: API Name
  version: 1.0.0

servers:
  - url: https://api.example.com/v1
    description: Production

security:
  - bearerAuth: []

paths:
  /users:
    get:
      operationId: listUsers
      responses:
        '200':
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/UserList'

components:
  schemas:
    User:
      type: object
      properties:
        id:
          type: string
        email:
          type: string
          format: email
      required:
        - id
        - email

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
```

### Key Elements to Extract

| Section | What to Extract | Usage |
|---------|----------------|-------|
| `servers` | Base URLs by environment | Client configuration |
| `security` | Auth schemes | Auth implementation |
| `paths` | Endpoints, methods, params | API methods |
| `components/schemas` | Request/response types | TypeScript types |
| `components/securitySchemes` | Auth details | Auth flow |

---

## Type Generation Strategies

### Strategy 1: Generated Types (Recommended)

Use tooling to generate types from spec.

**Tools:**

| Tool | Language | Notes |
|------|----------|-------|
| `openapi-typescript` | TypeScript | Types only, no runtime |
| `openapi-generator` | Multiple | Full client generation |
| `orval` | TypeScript | React Query integration |
| `swagger-typescript-api` | TypeScript | Customizable templates |

**openapi-typescript example:**

```bash
npx openapi-typescript ./api-spec.yaml -o ./src/api/types.ts
```

**Output:**

```typescript
export interface paths {
  "/users": {
    get: operations["listUsers"];
    post: operations["createUser"];
  };
  "/users/{id}": {
    get: operations["getUser"];
    put: operations["updateUser"];
    delete: operations["deleteUser"];
  };
}

export interface components {
  schemas: {
    User: {
      id: string;
      email: string;
      name?: string;
      createdAt: string;
    };
    CreateUserInput: {
      email: string;
      name?: string;
    };
    UserList: {
      data: components["schemas"]["User"][];
      meta: {
        total: number;
        page: number;
      };
    };
  };
}
```

### Strategy 2: Manual Types

When spec is incomplete or you need customization.

```typescript
// types/api.ts

// Base response wrapper (if API uses consistent envelope)
interface ApiResponse<T> {
  data: T;
  meta?: {
    total?: number;
    page?: number;
    perPage?: number;
  };
}

// Domain types
interface User {
  id: string;
  email: string;
  name: string | null;
  createdAt: Date;
  updatedAt: Date;
}

// Input types (what we send)
interface CreateUserInput {
  email: string;
  name?: string;
}

interface UpdateUserInput {
  email?: string;
  name?: string;
}

// Response types (what API returns)
type UserResponse = ApiResponse<User>;
type UserListResponse = ApiResponse<User[]>;
```

### Strategy 3: Hybrid (Generated + Extended)

Generate base types, extend with transformations.

```typescript
// Generated types
import type { components } from './generated/api-types';

// Raw API types
type ApiUser = components['schemas']['User'];

// Domain types with transformations
interface User {
  id: string;
  email: string;
  name: string | null;
  createdAt: Date;  // Transformed from string
  updatedAt: Date;
}

// Transformer
function toUser(apiUser: ApiUser): User {
  return {
    ...apiUser,
    createdAt: new Date(apiUser.createdAt),
    updatedAt: new Date(apiUser.updatedAt),
  };
}
```
