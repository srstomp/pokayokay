# Configuration and Public API Design

Configuration patterns, defaults, validation, barrel exports, and method signatures.

## Configuration Design

### Config Interface

```typescript
export interface ClientConfig {
  /** API base URL */
  baseUrl: string;

  /** API key or token */
  apiKey?: string;

  /** Request timeout in milliseconds (default: 30000) */
  timeout?: number;

  /** Retry configuration */
  retry?: RetryConfig;

  /** Custom fetch implementation */
  fetch?: typeof fetch;

  /** Custom headers for all requests */
  headers?: Record<string, string>;

  /** Called before each request */
  onRequest?: (request: Request) => Request | Promise<Request>;

  /** Called after each response */
  onResponse?: (response: Response) => Response | Promise<Response>;

  /** Called on errors */
  onError?: (error: SDKError) => void;
}

export interface RetryConfig {
  /** Number of retry attempts (default: 3) */
  attempts?: number;

  /** Initial delay in ms (default: 1000) */
  delay?: number;

  /** Delay multiplier for exponential backoff (default: 2) */
  backoff?: number;

  /** Maximum delay in ms (default: 30000) */
  maxDelay?: number;

  /** Status codes to retry (default: [408, 429, 500, 502, 503, 504]) */
  retryableStatuses?: number[];
}
```

### Defaults

```typescript
// internal/defaults.ts
export const DEFAULT_CONFIG: Required<Omit<ClientConfig, 'apiKey' | 'onRequest' | 'onResponse' | 'onError'>> = {
  baseUrl: '',
  timeout: 30000,
  retry: {
    attempts: 3,
    delay: 1000,
    backoff: 2,
    maxDelay: 30000,
    retryableStatuses: [408, 429, 500, 502, 503, 504],
  },
  fetch: globalThis.fetch,
  headers: {},
};

// In client
constructor(config: ClientConfig) {
  this.config = {
    ...DEFAULT_CONFIG,
    ...config,
    retry: { ...DEFAULT_CONFIG.retry, ...config.retry },
  };
}
```

### Validation

```typescript
// internal/validation.ts
export function validateConfig(config: ClientConfig): void {
  if (!config.baseUrl) {
    throw new ConfigurationError('baseUrl is required');
  }

  try {
    new URL(config.baseUrl);
  } catch {
    throw new ConfigurationError('baseUrl must be a valid URL');
  }

  if (config.timeout !== undefined && config.timeout <= 0) {
    throw new ConfigurationError('timeout must be positive');
  }
}
```

---

## Public API Design

### Barrel Exports (index.ts)

```typescript
// src/index.ts

// Main client
export { MyServiceClient } from './client';

// Factory function
export { createClient } from './client';

// Types (re-export for convenience)
export type {
  ClientConfig,
  RetryConfig,
  User,
  CreateUserInput,
  UpdateUserInput,
  Order,
  CreateOrderInput,
  PaginatedResponse,
  ListParams,
} from './types';

// Errors
export {
  SDKError,
  APIError,
  NetworkError,
  TimeoutError,
  ValidationError,
  AuthenticationError,
  RateLimitError,
} from './errors';

// Constants
export { SDK_VERSION, DEFAULT_TIMEOUT } from './constants';
```

### Type Exports

```typescript
// src/types.ts

// Configuration
export interface ClientConfig { ... }
export interface RetryConfig { ... }

// Domain models
export interface User {
  id: string;
  email: string;
  name: string;
  createdAt: string;
  updatedAt: string;
}

export interface Order {
  id: string;
  userId: string;
  status: OrderStatus;
  total: number;
  items: OrderItem[];
  createdAt: string;
}

export type OrderStatus = 'pending' | 'paid' | 'shipped' | 'delivered' | 'cancelled';

// Input types (for create/update)
export interface CreateUserInput {
  email: string;
  name: string;
  password: string;
}

export interface UpdateUserInput {
  email?: string;
  name?: string;
}

// Response types
export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    total: number;
    page: number;
    perPage: number;
    totalPages: number;
  };
}

export interface ListParams {
  page?: number;
  perPage?: number;
  sort?: string;
  filter?: Record<string, string>;
}
```

### Method Signatures

```typescript
// Clear, consistent method signatures

// GET single resource
async get(id: string): Promise<User>;
async get(id: string, options?: GetOptions): Promise<User>;

// GET list with pagination
async list(): Promise<PaginatedResponse<User>>;
async list(params: ListParams): Promise<PaginatedResponse<User>>;

// POST create
async create(input: CreateUserInput): Promise<User>;

// PUT/PATCH update
async update(id: string, input: UpdateUserInput): Promise<User>;

// DELETE
async delete(id: string): Promise<void>;

// Custom actions
async sendVerification(id: string): Promise<void>;
async resetPassword(email: string): Promise<void>;
```
