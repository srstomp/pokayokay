# Internal Architecture and Best Practices

HTTP client implementation, state management, and SDK design best practices.

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
// Good: No runtime dependencies
// package.json
{
  "dependencies": {}  // Empty!
}

// Acceptable: Minimal, essential deps
{
  "dependencies": {
    "zod": "^3.0.0"  // For validation
  }
}

// Bad: Heavy dependencies
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
// Good: Named exports (tree-shakeable)
export { Client } from './client';
export { createClient } from './client';
export type { ClientConfig } from './types';

// Bad: Default export of everything
export default {
  Client,
  createClient,
  // ...
};

// Bad: Re-export all (pulls in everything)
export * from './internal';
```

### Environment Agnostic

```typescript
// Good: Works in Node and browser
constructor(config: ClientConfig) {
  this.fetch = config.fetch ?? globalThis.fetch;
}

// Good: Optional polyfill
if (typeof globalThis.fetch === 'undefined') {
  console.warn('fetch not available. Provide custom fetch implementation.');
}

// Bad: Node-specific
import nodeFetch from 'node-fetch';
```

### Composable Design

```typescript
// Good: Extensible through composition
class MyClient extends BaseClient {
  constructor(config: Config) {
    super(config);
  }

  // Add custom methods
  async customOperation() { ... }
}

// Good: Plugin system
client.use(loggingPlugin);
client.use(cachingPlugin);

// Good: Middleware/interceptors
client.onRequest((req) => addTracingHeaders(req));
client.onResponse((res) => logResponse(res));
```
