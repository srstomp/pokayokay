# Client Architecture: Base Client & Service Layer

Architecture layers, base client implementation, interceptors, and service layer patterns.

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
