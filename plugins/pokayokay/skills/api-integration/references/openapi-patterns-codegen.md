# OpenAPI Consumption: Patterns, Codegen & Informal Docs

Common OpenAPI patterns, client generation strategies, spec validation, GraphQL schemas, and informal documentation consumption.

## Handling Common OpenAPI Patterns

### Nullable Fields

```yaml
# OpenAPI 3.0
name:
  type: string
  nullable: true

# OpenAPI 3.1
name:
  type: ['string', 'null']
```

**TypeScript:**

```typescript
interface User {
  name: string | null;
}
```

### Enums

```yaml
status:
  type: string
  enum: [pending, active, suspended]
```

**TypeScript:**

```typescript
type UserStatus = 'pending' | 'active' | 'suspended';

// Or as const for runtime use
const UserStatus = {
  Pending: 'pending',
  Active: 'active',
  Suspended: 'suspended',
} as const;

type UserStatus = typeof UserStatus[keyof typeof UserStatus];
```

### Dates

OpenAPI uses `format: date-time` but returns strings.

```yaml
createdAt:
  type: string
  format: date-time
```

**TypeScript approach:**

```typescript
// Raw API type (string)
interface ApiUser {
  createdAt: string;
}

// Domain type (Date)
interface User {
  createdAt: Date;
}

// Transform at boundary
function toUser(api: ApiUser): User {
  return {
    ...api,
    createdAt: new Date(api.createdAt),
  };
}
```

### Pagination

```yaml
paths:
  /users:
    get:
      parameters:
        - name: page
          in: query
          schema:
            type: integer
        - name: per_page
          in: query
          schema:
            type: integer
      responses:
        '200':
          content:
            application/json:
              schema:
                type: object
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
                      totalPages:
                        type: integer
```

**TypeScript:**

```typescript
interface PaginationParams {
  page?: number;
  perPage?: number;
}

interface PaginatedResponse<T> {
  data: T[];
  meta: {
    total: number;
    page: number;
    totalPages: number;
  };
}

async function listUsers(
  params?: PaginationParams
): Promise<PaginatedResponse<User>> {
  return client.get('/users', { params });
}
```

### Polymorphic Types (oneOf/anyOf)

```yaml
components:
  schemas:
    Event:
      oneOf:
        - $ref: '#/components/schemas/UserCreatedEvent'
        - $ref: '#/components/schemas/UserDeletedEvent'
      discriminator:
        propertyName: type
```

**TypeScript:**

```typescript
interface UserCreatedEvent {
  type: 'user.created';
  user: User;
}

interface UserDeletedEvent {
  type: 'user.deleted';
  userId: string;
}

type Event = UserCreatedEvent | UserDeletedEvent;

// Type guard
function isUserCreated(event: Event): event is UserCreatedEvent {
  return event.type === 'user.created';
}
```

---

## Generating API Client

### Option 1: Types Only + Manual Client

Best for: Control, understanding, smaller APIs.

```typescript
// types.ts (generated)
export type { User, CreateUserInput, UserListResponse } from './generated';

// client.ts (manual)
import { ApiClient } from './base-client';
import type { User, CreateUserInput } from './types';

export class UserService {
  constructor(private client: ApiClient) {}

  async list(params?: { page?: number }): Promise<User[]> {
    const response = await this.client.get<UserListResponse>('/users', { params });
    return response.data;
  }

  async get(id: string): Promise<User> {
    return this.client.get<User>(`/users/${id}`);
  }

  async create(input: CreateUserInput): Promise<User> {
    return this.client.post<User>('/users', input);
  }
}
```

### Option 2: Full Client Generation

Best for: Large APIs, staying in sync with spec.

**Using openapi-generator:**

```bash
openapi-generator generate \
  -i api-spec.yaml \
  -g typescript-fetch \
  -o ./src/api/generated
```

**Wrapping generated client:**

```typescript
import { UsersApi, Configuration } from './generated';

// Wrap to add custom behavior
class UserService {
  private api: UsersApi;

  constructor(config: { baseUrl: string; token: string }) {
    this.api = new UsersApi(new Configuration({
      basePath: config.baseUrl,
      accessToken: config.token,
    }));
  }

  async getUser(id: string): Promise<User> {
    const response = await this.api.getUser({ id });
    return toUser(response);  // Transform to domain type
  }
}
```

### Option 3: React Query + Orval

Best for: React apps with caching needs.

**orval.config.js:**

```javascript
module.exports = {
  petstore: {
    input: './api-spec.yaml',
    output: {
      target: './src/api/generated.ts',
      client: 'react-query',
      mode: 'tags-split',
    },
  },
};
```

**Usage:**

```typescript
import { useGetUser, useCreateUser } from './api/generated';

function UserProfile({ id }: { id: string }) {
  const { data: user, isLoading } = useGetUser(id);

  if (isLoading) return <Loading />;
  return <div>{user.name}</div>;
}
```

---

## Spec Validation

### Validate Before Generating

```bash
# Using swagger-cli
npx swagger-cli validate api-spec.yaml

# Using spectral (with linting)
npx spectral lint api-spec.yaml
```

### Common Spec Issues

| Issue | Problem | Fix |
|-------|---------|-----|
| Missing `operationId` | Generated method names unpredictable | Add unique operationId to each endpoint |
| Missing `required` | All fields optional | Mark required fields |
| No error schemas | Can't type errors | Add error response schemas |
| Inline schemas | Poor reusability | Extract to `components/schemas` |
| Missing examples | Harder to understand | Add examples |

### Fixing Incomplete Specs

If you can't modify the spec, create an overlay:

```typescript
// spec-overrides.ts
import type { components } from './generated';

// Add missing required fields
interface User extends components['schemas']['User'] {
  id: string;  // Make required
  email: string;  // Make required
}

// Add missing error types
interface ApiError {
  code: string;
  message: string;
  details?: Record<string, string[]>;
}
```

---

## GraphQL Schema Consumption

### Schema Introspection

```bash
# Download schema
npx graphql-codegen --config codegen.yml
```

**codegen.yml:**

```yaml
schema: https://api.example.com/graphql
documents: './src/**/*.graphql'
generates:
  ./src/api/types.ts:
    plugins:
      - typescript
      - typescript-operations
      - typescript-react-query
```

### Type Generation

```graphql
# user.graphql
query GetUser($id: ID!) {
  user(id: $id) {
    id
    email
    name
  }
}

mutation CreateUser($input: CreateUserInput!) {
  createUser(input: $input) {
    id
    email
  }
}
```

**Generated types:**

```typescript
export type GetUserQuery = {
  user: {
    id: string;
    email: string;
    name: string | null;
  } | null;
};

export type GetUserQueryVariables = {
  id: string;
};

export function useGetUserQuery(variables: GetUserQueryVariables) {
  // Generated hook
}
```

---

## Informal Documentation Consumption

When no spec exists, create types from documentation and examples.

### Process

1. **Document endpoints** observed in docs
2. **Collect examples** from docs, Postman, cURL
3. **Infer types** from examples
4. **Test edge cases** to discover optionality
5. **Document assumptions**

### Template

```typescript
/**
 * User API
 *
 * Documented at: https://docs.example.com/api/users
 * Last verified: 2024-01-15
 *
 * Assumptions:
 * - id is always present (not documented but observed)
 * - name can be null (tested with new users)
 * - deletedAt only present for soft-deleted users
 */

interface User {
  id: string;
  email: string;
  name: string | null;
  createdAt: string;
  deletedAt?: string;
}

// Endpoints
// GET /users - List users (paginated)
// GET /users/:id - Get single user
// POST /users - Create user
// PUT /users/:id - Update user
// DELETE /users/:id - Soft delete user
```

### Documenting Undocumented Behavior

```typescript
/**
 * Get user by ID
 *
 * Undocumented behaviors (discovered through testing):
 * - Returns 404 for deleted users (not 200 with deletedAt)
 * - Returns 403 if user belongs to different org
 * - Rate limited to 100 req/min (observed 429 responses)
 */
async function getUser(id: string): Promise<User> {
  // ...
}
```
