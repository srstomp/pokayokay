# Type Design

TypeScript type patterns for SDKs: strict types, branded types, generics, and type guards.

## Strict Types

```typescript
// Good: Strict, specific types
interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'user' | 'guest';
  createdAt: string;  // ISO date string
}

// Bad: Loose types
interface User {
  id: any;
  email: any;
  name: any;
  role: string;      // Could be anything
  createdAt: any;
}
```

## Input vs Output Types

```typescript
// Output type (from API)
interface User {
  id: string;
  email: string;
  name: string;
  createdAt: string;
  updatedAt: string;
}

// Input type for creation
interface CreateUserInput {
  email: string;
  name: string;
  password: string;  // Only on create
}

// Input type for update (all optional)
interface UpdateUserInput {
  email?: string;
  name?: string;
}

// Partial type for patches
type PatchUserInput = Partial<UpdateUserInput>;
```

## Branded Types

```typescript
// Prevent mixing up IDs
declare const brand: unique symbol;

type Brand<T, B> = T & { [brand]: B };

type UserId = Brand<string, 'UserId'>;
type OrderId = Brand<string, 'OrderId'>;

// Usage
function getUser(id: UserId): Promise<User>;
function getOrder(id: OrderId): Promise<Order>;

// Creating branded types
const userId = 'usr_123' as UserId;
const orderId = 'ord_456' as OrderId;

getUser(userId);   // OK
getUser(orderId);  // Type error!
```

## Generic Types

```typescript
// Paginated response
interface PaginatedResponse<T> {
  data: T[];
  meta: {
    total: number;
    page: number;
    perPage: number;
    totalPages: number;
    hasNext: boolean;
    hasPrev: boolean;
  };
  links: {
    self: string;
    first: string;
    last: string;
    next?: string;
    prev?: string;
  };
}

// API response wrapper
interface APIResponse<T> {
  data: T;
  meta?: Record<string, unknown>;
}

// Usage
async function listUsers(): Promise<PaginatedResponse<User>>;
async function getUser(id: string): Promise<APIResponse<User>>;
```

## Discriminated Unions

```typescript
// Event types
type AuthEvent =
  | { type: 'login'; user: User }
  | { type: 'logout' }
  | { type: 'token_refresh'; token: string }
  | { type: 'error'; error: AuthError };

// Handle with exhaustive switch
function handleEvent(event: AuthEvent) {
  switch (event.type) {
    case 'login':
      console.log('Logged in:', event.user.email);
      break;
    case 'logout':
      console.log('Logged out');
      break;
    case 'token_refresh':
      console.log('Token refreshed');
      break;
    case 'error':
      console.error('Auth error:', event.error);
      break;
    default:
      const _exhaustive: never = event;
      throw new Error(`Unknown event: ${_exhaustive}`);
  }
}
```

## Type Guards

```typescript
// Type guard function
function isUser(value: unknown): value is User {
  return (
    typeof value === 'object' &&
    value !== null &&
    'id' in value &&
    'email' in value &&
    typeof (value as User).id === 'string' &&
    typeof (value as User).email === 'string'
  );
}

// With Zod
import { z } from 'zod';

const UserSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  name: z.string(),
  role: z.enum(['admin', 'user', 'guest']),
  createdAt: z.string().datetime(),
});

type User = z.infer<typeof UserSchema>;

function parseUser(data: unknown): User {
  return UserSchema.parse(data);
}
```
