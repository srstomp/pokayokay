# Client Architecture

Patterns for building robust, maintainable API clients.

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    APPLICATION CODE                         │
│                  (uses domain types)                        │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    SERVICE LAYER                            │
│           (domain methods, type transformation)             │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    API CLIENT                               │
│        (HTTP handling, auth, retries, logging)              │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    HTTP LAYER                               │
│              (fetch, axios, got, etc.)                      │
└─────────────────────────────────────────────────────────────┘
```

---

## Base Client Implementation

### Minimal Typed Client

```typescript
// api-client.ts

interface RequestConfig {
  params?: Record<string, string | number | boolean | undefined>;
  headers?: Record<string, string>;
  signal?: AbortSignal;
}

interface ApiClientConfig {
  baseUrl: string;
  headers?: Record<string, string>;
  onRequest?: (config: RequestConfig) => RequestConfig;
  onResponse?: (response: Response) => void;
  onError?: (error: ApiError) => void;
}

class ApiClient {
  constructor(private config: ApiClientConfig) {}

  async get<T>(path: string, options?: RequestConfig): Promise<T> {
    return this.request<T>('GET', path, undefined, options);
  }

  async post<T>(path: string, body?: unknown, options?: RequestConfig): Promise<T> {
    return this.request<T>('POST', path, body, options);
  }

  async put<T>(path: string, body?: unknown, options?: RequestConfig): Promise<T> {
    return this.request<T>('PUT', path, body, options);
  }

  async patch<T>(path: string, body?: unknown, options?: RequestConfig): Promise<T> {
    return this.request<T>('PATCH', path, body, options);
  }

  async delete<T>(path: string, options?: RequestConfig): Promise<T> {
    return this.request<T>('DELETE', path, undefined, options);
  }

  private async request<T>(
    method: string,
    path: string,
    body?: unknown,
    options?: RequestConfig
  ): Promise<T> {
    const url = this.buildUrl(path, options?.params);

    const config: RequestInit = {
      method,
      headers: {
        'Content-Type': 'application/json',
        ...this.config.headers,
        ...options?.headers,
      },
      body: body ? JSON.stringify(body) : undefined,
      signal: options?.signal,
    };

    // Pre-request hook
    const finalConfig = this.config.onRequest?.(config) ?? config;

    const response = await fetch(url, finalConfig);

    // Post-response hook
    this.config.onResponse?.(response);

    if (!response.ok) {
      const error = await ApiError.fromResponse(response);
      this.config.onError?.(error);
      throw error;
    }

    // Handle empty responses
    const text = await response.text();
    return text ? JSON.parse(text) : undefined;
  }

  private buildUrl(path: string, params?: Record<string, unknown>): string {
    const url = new URL(path, this.config.baseUrl);

    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        if (value !== undefined) {
          url.searchParams.set(key, String(value));
        }
      });
    }

    return url.toString();
  }
}
```

### Enhanced Client with Interceptors

```typescript
type RequestInterceptor = (config: RequestInit) => RequestInit | Promise<RequestInit>;
type ResponseInterceptor = (response: Response) => Response | Promise<Response>;
type ErrorInterceptor = (error: ApiError) => ApiError | Promise<ApiError>;

class ApiClient {
  private requestInterceptors: RequestInterceptor[] = [];
  private responseInterceptors: ResponseInterceptor[] = [];
  private errorInterceptors: ErrorInterceptor[] = [];

  addRequestInterceptor(interceptor: RequestInterceptor) {
    this.requestInterceptors.push(interceptor);
    return () => {
      const index = this.requestInterceptors.indexOf(interceptor);
      if (index > -1) this.requestInterceptors.splice(index, 1);
    };
  }

  addResponseInterceptor(interceptor: ResponseInterceptor) {
    this.responseInterceptors.push(interceptor);
    return () => {
      const index = this.responseInterceptors.indexOf(interceptor);
      if (index > -1) this.responseInterceptors.splice(index, 1);
    };
  }

  addErrorInterceptor(interceptor: ErrorInterceptor) {
    this.errorInterceptors.push(interceptor);
    return () => {
      const index = this.errorInterceptors.indexOf(interceptor);
      if (index > -1) this.errorInterceptors.splice(index, 1);
    };
  }

  private async runRequestInterceptors(config: RequestInit): Promise<RequestInit> {
    let result = config;
    for (const interceptor of this.requestInterceptors) {
      result = await interceptor(result);
    }
    return result;
  }

  // ... similar for response and error interceptors
}
```

---

## Service Layer Pattern

### Service Class

```typescript
// services/user-service.ts

import type { User, CreateUserInput, UpdateUserInput } from '../types';
import type { ApiClient } from '../api-client';

export class UserService {
  constructor(private client: ApiClient) {}

  /**
   * List all users with optional pagination
   */
  async list(options?: {
    page?: number;
    perPage?: number;
    search?: string;
  }): Promise<{ users: User[]; total: number }> {
    const response = await this.client.get<ApiUserListResponse>('/users', {
      params: options,
    });

    return {
      users: response.data.map(toUser),
      total: response.meta.total,
    };
  }

  /**
   * Get a single user by ID
   * @throws {NotFoundError} if user doesn't exist
   */
  async get(id: string): Promise<User> {
    const response = await this.client.get<ApiUser>(`/users/${id}`);
    return toUser(response);
  }

  /**
   * Create a new user
   * @throws {ValidationError} if input is invalid
   */
  async create(input: CreateUserInput): Promise<User> {
    const response = await this.client.post<ApiUser>('/users', input);
    return toUser(response);
  }

  /**
   * Update an existing user
   * @throws {NotFoundError} if user doesn't exist
   * @throws {ValidationError} if input is invalid
   */
  async update(id: string, input: UpdateUserInput): Promise<User> {
    const response = await this.client.put<ApiUser>(`/users/${id}`, input);
    return toUser(response);
  }

  /**
   * Delete a user
   * @throws {NotFoundError} if user doesn't exist
   */
  async delete(id: string): Promise<void> {
    await this.client.delete(`/users/${id}`);
  }
}

// Transformer
function toUser(apiUser: ApiUser): User {
  return {
    id: apiUser.id,
    email: apiUser.email,
    name: apiUser.name,
    createdAt: new Date(apiUser.created_at),
    updatedAt: new Date(apiUser.updated_at),
  };
}
```

### Service Factory

```typescript
// services/index.ts

import { ApiClient } from '../api-client';
import { UserService } from './user-service';
import { OrderService } from './order-service';
import { ProductService } from './product-service';

export interface ApiServices {
  users: UserService;
  orders: OrderService;
  products: ProductService;
}

export function createServices(client: ApiClient): ApiServices {
  return {
    users: new UserService(client),
    orders: new OrderService(client),
    products: new ProductService(client),
  };
}

// Usage
const client = new ApiClient({ baseUrl: 'https://api.example.com' });
const services = createServices(client);

const user = await services.users.get('123');
```

---

## Request Configuration

### Timeout Handling

```typescript
async function fetchWithTimeout<T>(
  url: string,
  options: RequestInit & { timeout?: number }
): Promise<T> {
  const { timeout = 30000, ...fetchOptions } = options;

  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeout);

  try {
    const response = await fetch(url, {
      ...fetchOptions,
      signal: controller.signal,
    });
    return response.json();
  } finally {
    clearTimeout(timeoutId);
  }
}

// Usage
const user = await fetchWithTimeout<User>('/users/1', { timeout: 5000 });
```

### Request Cancellation

```typescript
class UserService {
  private abortController: AbortController | null = null;

  async search(query: string): Promise<User[]> {
    // Cancel previous request
    this.abortController?.abort();
    this.abortController = new AbortController();

    try {
      return await this.client.get<User[]>('/users/search', {
        params: { q: query },
        signal: this.abortController.signal,
      });
    } catch (error) {
      if (error.name === 'AbortError') {
        // Request was cancelled, return empty or previous results
        return [];
      }
      throw error;
    }
  }
}
```

### Request Deduplication

```typescript
class RequestDeduplicator {
  private pending = new Map<string, Promise<unknown>>();

  async dedupe<T>(key: string, request: () => Promise<T>): Promise<T> {
    // Return existing request if pending
    if (this.pending.has(key)) {
      return this.pending.get(key) as Promise<T>;
    }

    // Create new request
    const promise = request().finally(() => {
      this.pending.delete(key);
    });

    this.pending.set(key, promise);
    return promise;
  }
}

// Usage in service
class UserService {
  private deduplicator = new RequestDeduplicator();

  async get(id: string): Promise<User> {
    return this.deduplicator.dedupe(`user:${id}`, () =>
      this.client.get<User>(`/users/${id}`)
    );
  }
}
```

---

## Response Handling

### Type-Safe Response Parsing

```typescript
import { z } from 'zod';

// Define schema
const UserSchema = z.object({
  id: z.string(),
  email: z.string().email(),
  name: z.string().nullable(),
  createdAt: z.string().transform(s => new Date(s)),
});

type User = z.infer<typeof UserSchema>;

// Parse with validation
async function getUser(id: string): Promise<User> {
  const response = await fetch(`/users/${id}`);
  const data = await response.json();

  // Throws if response doesn't match schema
  return UserSchema.parse(data);
}

// Or with safe parsing
async function getUserSafe(id: string): Promise<User | null> {
  const response = await fetch(`/users/${id}`);
  const data = await response.json();

  const result = UserSchema.safeParse(data);
  if (!result.success) {
    console.error('Invalid response:', result.error);
    return null;
  }

  return result.data;
}
```

### Response Envelope Unwrapping

```typescript
// API returns: { data: T, meta: {...} }
interface ApiEnvelope<T> {
  data: T;
  meta: {
    requestId: string;
    timestamp: string;
  };
}

class ApiClient {
  async get<T>(path: string): Promise<T> {
    const response = await fetch(`${this.baseUrl}${path}`);
    const envelope: ApiEnvelope<T> = await response.json();

    // Log meta for debugging
    console.debug('Request ID:', envelope.meta.requestId);

    // Return unwrapped data
    return envelope.data;
  }
}
```

### Handling Different Content Types

```typescript
async function request<T>(url: string): Promise<T> {
  const response = await fetch(url);

  const contentType = response.headers.get('content-type');

  if (contentType?.includes('application/json')) {
    return response.json();
  }

  if (contentType?.includes('text/')) {
    return response.text() as unknown as T;
  }

  if (contentType?.includes('application/octet-stream')) {
    return response.blob() as unknown as T;
  }

  throw new Error(`Unsupported content type: ${contentType}`);
}
```

---

## Caching

### Simple In-Memory Cache

```typescript
interface CacheEntry<T> {
  data: T;
  expiresAt: number;
}

class CacheClient {
  private cache = new Map<string, CacheEntry<unknown>>();

  async get<T>(
    key: string,
    fetcher: () => Promise<T>,
    ttlMs: number = 60000
  ): Promise<T> {
    const cached = this.cache.get(key) as CacheEntry<T> | undefined;

    if (cached && cached.expiresAt > Date.now()) {
      return cached.data;
    }

    const data = await fetcher();
    this.cache.set(key, {
      data,
      expiresAt: Date.now() + ttlMs,
    });

    return data;
  }

  invalidate(key: string) {
    this.cache.delete(key);
  }

  invalidatePrefix(prefix: string) {
    for (const key of this.cache.keys()) {
      if (key.startsWith(prefix)) {
        this.cache.delete(key);
      }
    }
  }
}

// Usage
class UserService {
  constructor(
    private client: ApiClient,
    private cache: CacheClient
  ) {}

  async get(id: string): Promise<User> {
    return this.cache.get(
      `user:${id}`,
      () => this.client.get<User>(`/users/${id}`),
      5 * 60 * 1000 // 5 minutes
    );
  }

  async update(id: string, input: UpdateUserInput): Promise<User> {
    const user = await this.client.put<User>(`/users/${id}`, input);
    this.cache.invalidate(`user:${id}`);
    return user;
  }
}
```

### Stale-While-Revalidate Pattern

```typescript
async function swrFetch<T>(
  key: string,
  fetcher: () => Promise<T>,
  cache: Map<string, { data: T; timestamp: number }>,
  maxAge: number
): Promise<T> {
  const cached = cache.get(key);
  const now = Date.now();

  if (cached) {
    // Return stale data immediately
    const isStale = now - cached.timestamp > maxAge;

    if (isStale) {
      // Revalidate in background
      fetcher().then(data => {
        cache.set(key, { data, timestamp: now });
      });
    }

    return cached.data;
  }

  // No cache, fetch and cache
  const data = await fetcher();
  cache.set(key, { data, timestamp: now });
  return data;
}
```

---

## Logging & Debugging

### Request/Response Logging

```typescript
function createLoggingClient(client: ApiClient): ApiClient {
  client.addRequestInterceptor((config) => {
    console.log('→ Request:', {
      method: config.method,
      url: config.url,
      // Don't log sensitive headers
      headers: redactHeaders(config.headers),
    });
    return config;
  });

  client.addResponseInterceptor((response) => {
    console.log('← Response:', {
      status: response.status,
      url: response.url,
    });
    return response;
  });

  client.addErrorInterceptor((error) => {
    console.error('✕ Error:', {
      status: error.status,
      code: error.code,
      message: error.message,
    });
    return error;
  });

  return client;
}

function redactHeaders(headers?: Record<string, string>): Record<string, string> {
  if (!headers) return {};

  const redacted = { ...headers };
  const sensitiveKeys = ['authorization', 'x-api-key', 'cookie'];

  for (const key of Object.keys(redacted)) {
    if (sensitiveKeys.includes(key.toLowerCase())) {
      redacted[key] = '[REDACTED]';
    }
  }

  return redacted;
}
```

### Request Tracing

```typescript
function addRequestTracing(client: ApiClient): void {
  client.addRequestInterceptor((config) => {
    const requestId = crypto.randomUUID();

    return {
      ...config,
      headers: {
        ...config.headers,
        'X-Request-ID': requestId,
      },
    };
  });
}
```

---

## Environment Configuration

```typescript
// config/api.ts

interface ApiConfig {
  baseUrl: string;
  timeout: number;
  retryAttempts: number;
}

const configs: Record<string, ApiConfig> = {
  development: {
    baseUrl: 'http://localhost:3000/api',
    timeout: 30000,
    retryAttempts: 0, // No retries in dev
  },
  staging: {
    baseUrl: 'https://staging-api.example.com',
    timeout: 15000,
    retryAttempts: 2,
  },
  production: {
    baseUrl: 'https://api.example.com',
    timeout: 10000,
    retryAttempts: 3,
  },
};

export function getApiConfig(): ApiConfig {
  const env = process.env.NODE_ENV || 'development';
  return configs[env] || configs.development;
}

// Usage
const config = getApiConfig();
const client = new ApiClient({
  baseUrl: config.baseUrl,
  timeout: config.timeout,
});
```
