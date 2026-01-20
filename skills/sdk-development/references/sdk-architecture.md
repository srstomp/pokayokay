# SDK Architecture

SDK structure, patterns, and API design.

## Package Structure

### Standard SDK Layout

```
my-sdk/
├── src/
│   ├── index.ts              # Public exports (barrel)
│   ├── client.ts             # Main client class
│   ├── types.ts              # Public types/interfaces
│   ├── errors.ts             # Error classes
│   ├── constants.ts          # Public constants
│   │
│   ├── internal/             # Private implementation
│   │   ├── http.ts           # HTTP utilities
│   │   ├── retry.ts          # Retry logic
│   │   ├── validation.ts     # Input validation
│   │   └── utils.ts          # Internal helpers
│   │
│   └── modules/              # Feature modules (optional)
│       ├── auth/
│       │   ├── index.ts
│       │   ├── auth-client.ts
│       │   └── types.ts
│       └── users/
│           ├── index.ts
│           ├── users-client.ts
│           └── types.ts
│
├── tests/
│   ├── client.test.ts
│   ├── errors.test.ts
│   └── integration/
│       └── auth.integration.test.ts
│
├── examples/
│   ├── basic-usage.ts
│   ├── with-react/
│   └── with-node/
│
├── docs/
│   ├── getting-started.md
│   ├── api-reference.md
│   └── migration-guide.md
│
├── package.json
├── tsconfig.json
├── tsup.config.ts
├── vitest.config.ts
├── README.md
├── CHANGELOG.md
└── LICENSE
```

### Multi-Package SDK (Monorepo)

```
my-sdk/
├── packages/
│   ├── core/                 # @org/sdk-core
│   │   ├── src/
│   │   ├── package.json
│   │   └── tsconfig.json
│   │
│   ├── react/                # @org/sdk-react
│   │   ├── src/
│   │   ├── package.json      # depends on @org/sdk-core
│   │   └── tsconfig.json
│   │
│   └── node/                 # @org/sdk-node
│       ├── src/
│       ├── package.json      # depends on @org/sdk-core
│       └── tsconfig.json
│
├── examples/
├── docs/
├── package.json              # Workspace root
├── pnpm-workspace.yaml
└── turbo.json
```

---

## Client Patterns

### Single Client

```typescript
// Simple SDK with one main client
export class MyServiceClient {
  private config: ClientConfig;
  private http: HttpClient;
  
  constructor(config: ClientConfig) {
    this.config = { ...DEFAULT_CONFIG, ...config };
    this.http = new HttpClient(this.config);
  }
  
  // Resource methods directly on client
  async getUser(id: string): Promise<User> {
    return this.http.get(`/users/${id}`);
  }
  
  async listUsers(params?: ListParams): Promise<PaginatedResponse<User>> {
    return this.http.get('/users', { params });
  }
  
  async createUser(data: CreateUserInput): Promise<User> {
    return this.http.post('/users', data);
  }
}

// Usage
const client = new MyServiceClient({ apiKey: 'xxx' });
const user = await client.getUser('123');
```

### Modular Client

```typescript
// SDK with sub-clients for different resources
export class MyServiceClient {
  readonly users: UsersClient;
  readonly orders: OrdersClient;
  readonly products: ProductsClient;
  
  constructor(config: ClientConfig) {
    const http = new HttpClient(config);
    
    this.users = new UsersClient(http);
    this.orders = new OrdersClient(http);
    this.products = new ProductsClient(http);
  }
}

class UsersClient {
  constructor(private http: HttpClient) {}
  
  async get(id: string): Promise<User> {
    return this.http.get(`/users/${id}`);
  }
  
  async list(params?: ListParams): Promise<PaginatedResponse<User>> {
    return this.http.get('/users', { params });
  }
  
  async create(data: CreateUserInput): Promise<User> {
    return this.http.post('/users', data);
  }
}

// Usage
const client = new MyServiceClient({ apiKey: 'xxx' });
const user = await client.users.get('123');
const orders = await client.orders.list({ userId: '123' });
```

### Factory Function

```typescript
// Function-based creation (tree-shakeable)
export function createClient(config: ClientConfig) {
  const http = new HttpClient(config);
  
  return {
    users: {
      get: (id: string) => http.get<User>(`/users/${id}`),
      list: (params?: ListParams) => http.get<User[]>('/users', { params }),
      create: (data: CreateUserInput) => http.post<User>('/users', data),
    },
    
    orders: {
      get: (id: string) => http.get<Order>(`/orders/${id}`),
      list: (params?: ListParams) => http.get<Order[]>('/orders', { params }),
    },
  };
}

// Usage
const client = createClient({ apiKey: 'xxx' });
const user = await client.users.get('123');
```

### Builder Pattern

```typescript
// Fluent configuration
export class ClientBuilder {
  private config: Partial<ClientConfig> = {};
  
  baseUrl(url: string): this {
    this.config.baseUrl = url;
    return this;
  }
  
  apiKey(key: string): this {
    this.config.apiKey = key;
    return this;
  }
  
  timeout(ms: number): this {
    this.config.timeout = ms;
    return this;
  }
  
  retry(options: RetryOptions): this {
    this.config.retry = options;
    return this;
  }
  
  build(): MyServiceClient {
    if (!this.config.baseUrl) {
      throw new Error('baseUrl is required');
    }
    return new MyServiceClient(this.config as ClientConfig);
  }
}

// Usage
const client = new ClientBuilder()
  .baseUrl('https://api.example.com')
  .apiKey('xxx')
  .timeout(30000)
  .retry({ attempts: 3 })
  .build();
```

---

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

---

## Internal Architecture

### HTTP Client

```typescript
// internal/http.ts
export class HttpClient {
  private config: ClientConfig;
  
  constructor(config: ClientConfig) {
    this.config = config;
  }
  
  async get<T>(path: string, options?: RequestOptions): Promise<T> {
    return this.request<T>('GET', path, options);
  }
  
  async post<T>(path: string, data?: unknown, options?: RequestOptions): Promise<T> {
    return this.request<T>('POST', path, { ...options, body: data });
  }
  
  async put<T>(path: string, data?: unknown, options?: RequestOptions): Promise<T> {
    return this.request<T>('PUT', path, { ...options, body: data });
  }
  
  async patch<T>(path: string, data?: unknown, options?: RequestOptions): Promise<T> {
    return this.request<T>('PATCH', path, { ...options, body: data });
  }
  
  async delete<T>(path: string, options?: RequestOptions): Promise<T> {
    return this.request<T>('DELETE', path, options);
  }
  
  private async request<T>(
    method: string,
    path: string,
    options?: RequestOptions
  ): Promise<T> {
    const url = this.buildUrl(path, options?.params);
    const headers = this.buildHeaders(options?.headers);
    
    let request = new Request(url, {
      method,
      headers,
      body: options?.body ? JSON.stringify(options.body) : undefined,
    });
    
    // Apply request interceptor
    if (this.config.onRequest) {
      request = await this.config.onRequest(request);
    }
    
    // Execute with retry
    const response = await this.executeWithRetry(request);
    
    // Apply response interceptor
    const finalResponse = this.config.onResponse
      ? await this.config.onResponse(response)
      : response;
    
    // Handle response
    return this.handleResponse<T>(finalResponse);
  }
  
  private async executeWithRetry(request: Request): Promise<Response> {
    const { attempts, delay, backoff, maxDelay, retryableStatuses } = 
      this.config.retry ?? {};
    
    let lastError: Error | undefined;
    
    for (let attempt = 0; attempt < (attempts ?? 3); attempt++) {
      try {
        const controller = new AbortController();
        const timeoutId = setTimeout(
          () => controller.abort(),
          this.config.timeout
        );
        
        const response = await this.config.fetch!(request.clone(), {
          signal: controller.signal,
        });
        
        clearTimeout(timeoutId);
        
        if (retryableStatuses?.includes(response.status) && attempt < (attempts ?? 3) - 1) {
          await this.sleep(this.calculateDelay(attempt, delay, backoff, maxDelay));
          continue;
        }
        
        return response;
      } catch (error) {
        lastError = error as Error;
        
        if (attempt < (attempts ?? 3) - 1) {
          await this.sleep(this.calculateDelay(attempt, delay, backoff, maxDelay));
        }
      }
    }
    
    throw new NetworkError('Request failed after retries', { cause: lastError });
  }
  
  private calculateDelay(
    attempt: number,
    baseDelay = 1000,
    backoff = 2,
    maxDelay = 30000
  ): number {
    const delay = baseDelay * Math.pow(backoff, attempt);
    return Math.min(delay, maxDelay);
  }
  
  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
  
  private buildUrl(path: string, params?: Record<string, string>): URL {
    const url = new URL(path, this.config.baseUrl);
    
    if (params) {
      for (const [key, value] of Object.entries(params)) {
        if (value !== undefined) {
          url.searchParams.set(key, value);
        }
      }
    }
    
    return url;
  }
  
  private buildHeaders(custom?: Record<string, string>): Headers {
    const headers = new Headers({
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...this.config.headers,
      ...custom,
    });
    
    if (this.config.apiKey) {
      headers.set('Authorization', `Bearer ${this.config.apiKey}`);
    }
    
    return headers;
  }
  
  private async handleResponse<T>(response: Response): Promise<T> {
    if (!response.ok) {
      throw await APIError.fromResponse(response);
    }
    
    if (response.status === 204) {
      return undefined as T;
    }
    
    return response.json();
  }
}
```

### State Management (if needed)

```typescript
// internal/state.ts
type Listener<T> = (state: T) => void;

export class StateManager<T> {
  private state: T;
  private listeners: Set<Listener<T>> = new Set();
  
  constructor(initialState: T) {
    this.state = initialState;
  }
  
  getState(): T {
    return this.state;
  }
  
  setState(updater: T | ((prev: T) => T)): void {
    const newState = typeof updater === 'function'
      ? (updater as (prev: T) => T)(this.state)
      : updater;
    
    this.state = newState;
    this.notify();
  }
  
  subscribe(listener: Listener<T>): () => void {
    this.listeners.add(listener);
    return () => this.listeners.delete(listener);
  }
  
  private notify(): void {
    for (const listener of this.listeners) {
      listener(this.state);
    }
  }
}
```

---

## Best Practices

### Minimize Dependencies

```typescript
// ✅ Good: No runtime dependencies
// package.json
{
  "dependencies": {}  // Empty!
}

// ✅ Acceptable: Minimal, essential deps
{
  "dependencies": {
    "zod": "^3.0.0"  // For validation
  }
}

// ❌ Bad: Heavy dependencies
{
  "dependencies": {
    "axios": "^1.0.0",      // Use fetch
    "lodash": "^4.0.0",     // Use native
    "moment": "^2.0.0"      // Use Intl/Date
  }
}
```

### Tree-Shakeable Exports

```typescript
// ✅ Good: Named exports (tree-shakeable)
export { Client } from './client';
export { createClient } from './client';
export type { ClientConfig } from './types';

// ❌ Bad: Default export of everything
export default {
  Client,
  createClient,
  // ...
};

// ❌ Bad: Re-export all (pulls in everything)
export * from './internal';
```

### Environment Agnostic

```typescript
// ✅ Good: Works in Node and browser
constructor(config: ClientConfig) {
  this.fetch = config.fetch ?? globalThis.fetch;
}

// ✅ Good: Optional polyfill
if (typeof globalThis.fetch === 'undefined') {
  console.warn('fetch not available. Provide custom fetch implementation.');
}

// ❌ Bad: Node-specific
import nodeFetch from 'node-fetch';
```

### Composable Design

```typescript
// ✅ Good: Extensible through composition
class MyClient extends BaseClient {
  constructor(config: Config) {
    super(config);
  }
  
  // Add custom methods
  async customOperation() { ... }
}

// ✅ Good: Plugin system
client.use(loggingPlugin);
client.use(cachingPlugin);

// ✅ Good: Middleware/interceptors
client.onRequest((req) => addTracingHeaders(req));
client.onResponse((res) => logResponse(res));
```
