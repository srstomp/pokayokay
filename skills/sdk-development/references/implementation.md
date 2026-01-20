# Implementation

TypeScript patterns, types, and error handling for SDKs.

## Type Design

### Strict Types

```typescript
// ✅ Good: Strict, specific types
interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'user' | 'guest';
  createdAt: string;  // ISO date string
}

// ❌ Bad: Loose types
interface User {
  id: any;
  email: any;
  name: any;
  role: string;      // Could be anything
  createdAt: any;
}
```

### Input vs Output Types

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

### Branded Types

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

getUser(userId);   // ✅ OK
getUser(orderId);  // ❌ Type error!
```

### Generic Types

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

### Discriminated Unions

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

### Type Guards

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

---

## Error Handling

### Error Class Hierarchy

```typescript
// src/errors.ts

/**
 * Base error for all SDK errors
 */
export class SDKError extends Error {
  constructor(
    message: string,
    public code: string,
    public cause?: Error,
  ) {
    super(message);
    this.name = 'SDKError';
    
    // Maintains proper stack trace
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, this.constructor);
    }
  }
  
  toJSON() {
    return {
      name: this.name,
      message: this.message,
      code: this.code,
    };
  }
}

/**
 * API returned an error response
 */
export class APIError extends SDKError {
  constructor(
    message: string,
    code: string,
    public statusCode: number,
    public response?: unknown,
  ) {
    super(message, code);
    this.name = 'APIError';
  }
  
  static async fromResponse(response: Response): Promise<APIError> {
    let body: unknown;
    let message = `Request failed with status ${response.status}`;
    let code = 'API_ERROR';
    
    try {
      body = await response.json();
      if (typeof body === 'object' && body !== null) {
        const error = (body as any).error ?? body;
        message = error.message ?? message;
        code = error.code ?? code;
      }
    } catch {
      // Body not JSON, use default message
    }
    
    return new APIError(message, code, response.status, body);
  }
  
  get isRetryable(): boolean {
    return [408, 429, 500, 502, 503, 504].includes(this.statusCode);
  }
}

/**
 * Network/connection error
 */
export class NetworkError extends SDKError {
  constructor(message: string, options?: { cause?: Error }) {
    super(message, 'NETWORK_ERROR', options?.cause);
    this.name = 'NetworkError';
  }
}

/**
 * Request timed out
 */
export class TimeoutError extends SDKError {
  constructor(public timeoutMs: number) {
    super(`Request timed out after ${timeoutMs}ms`, 'TIMEOUT');
    this.name = 'TimeoutError';
  }
}

/**
 * Input validation failed
 */
export class ValidationError extends SDKError {
  constructor(
    message: string,
    public fields: Array<{ field: string; message: string }>,
  ) {
    super(message, 'VALIDATION_ERROR');
    this.name = 'ValidationError';
  }
}

/**
 * Authentication failed (401)
 */
export class AuthenticationError extends APIError {
  constructor(message: string = 'Authentication required') {
    super(message, 'UNAUTHENTICATED', 401);
    this.name = 'AuthenticationError';
  }
}

/**
 * Authorization failed (403)
 */
export class AuthorizationError extends APIError {
  constructor(message: string = 'Permission denied') {
    super(message, 'FORBIDDEN', 403);
    this.name = 'AuthorizationError';
  }
}

/**
 * Resource not found (404)
 */
export class NotFoundError extends APIError {
  constructor(resource: string, id?: string) {
    const message = id
      ? `${resource} with id '${id}' not found`
      : `${resource} not found`;
    super(message, 'NOT_FOUND', 404);
    this.name = 'NotFoundError';
  }
}

/**
 * Rate limit exceeded (429)
 */
export class RateLimitError extends APIError {
  constructor(
    public retryAfter?: number,
    message: string = 'Rate limit exceeded',
  ) {
    super(message, 'RATE_LIMITED', 429);
    this.name = 'RateLimitError';
  }
}

/**
 * Configuration error
 */
export class ConfigurationError extends SDKError {
  constructor(message: string) {
    super(message, 'CONFIGURATION_ERROR');
    this.name = 'ConfigurationError';
  }
}
```

### Error Handling in Client

```typescript
class MyClient {
  async getUser(id: string): Promise<User> {
    try {
      return await this.http.get<User>(`/users/${id}`);
    } catch (error) {
      // Transform to specific error types
      if (error instanceof APIError) {
        if (error.statusCode === 404) {
          throw new NotFoundError('User', id);
        }
        if (error.statusCode === 401) {
          throw new AuthenticationError();
        }
      }
      throw error;
    }
  }
}
```

### Error Type Checking

```typescript
// User code
try {
  const user = await client.getUser('123');
} catch (error) {
  if (error instanceof NotFoundError) {
    console.log('User not found');
  } else if (error instanceof AuthenticationError) {
    console.log('Need to login');
  } else if (error instanceof RateLimitError) {
    console.log(`Rate limited, retry after ${error.retryAfter}s`);
  } else if (error instanceof SDKError) {
    console.log(`SDK error: ${error.code} - ${error.message}`);
  } else {
    console.log('Unknown error:', error);
  }
}
```

---

## Async Patterns

### Async Method Patterns

```typescript
// Standard async method
async getUser(id: string): Promise<User> {
  const response = await this.http.get<User>(`/users/${id}`);
  return response;
}

// With loading/result pattern (for React)
interface AsyncResult<T> {
  data?: T;
  error?: SDKError;
  isLoading: boolean;
}

// With cancellation
async getUser(id: string, signal?: AbortSignal): Promise<User> {
  return this.http.get<User>(`/users/${id}`, { signal });
}
```

### Retry Logic

```typescript
// internal/retry.ts
interface RetryOptions {
  attempts: number;
  delay: number;
  backoff: number;
  maxDelay: number;
  shouldRetry?: (error: Error) => boolean;
}

async function withRetry<T>(
  fn: () => Promise<T>,
  options: RetryOptions
): Promise<T> {
  let lastError: Error | undefined;
  
  for (let attempt = 0; attempt < options.attempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;
      
      const shouldRetry = options.shouldRetry?.(lastError) ?? true;
      
      if (!shouldRetry || attempt >= options.attempts - 1) {
        throw lastError;
      }
      
      const delay = Math.min(
        options.delay * Math.pow(options.backoff, attempt),
        options.maxDelay
      );
      
      await sleep(delay);
    }
  }
  
  throw lastError;
}

function sleep(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}
```

### Request Queue

```typescript
// internal/queue.ts
class RequestQueue {
  private queue: Array<() => Promise<void>> = [];
  private running = 0;
  private maxConcurrent: number;
  
  constructor(maxConcurrent = 5) {
    this.maxConcurrent = maxConcurrent;
  }
  
  async add<T>(fn: () => Promise<T>): Promise<T> {
    return new Promise((resolve, reject) => {
      const execute = async () => {
        this.running++;
        try {
          const result = await fn();
          resolve(result);
        } catch (error) {
          reject(error);
        } finally {
          this.running--;
          this.processNext();
        }
      };
      
      if (this.running < this.maxConcurrent) {
        execute();
      } else {
        this.queue.push(execute);
      }
    });
  }
  
  private processNext(): void {
    if (this.queue.length > 0 && this.running < this.maxConcurrent) {
      const next = this.queue.shift()!;
      next();
    }
  }
}
```

### Token Refresh Queue

```typescript
// Deduplicate concurrent refresh requests
class TokenManager {
  private refreshPromise: Promise<string> | null = null;
  
  async getValidToken(): Promise<string> {
    const token = this.getStoredToken();
    
    if (token && !this.isExpired(token)) {
      return token;
    }
    
    // Deduplicate refresh requests
    if (!this.refreshPromise) {
      this.refreshPromise = this.refreshToken();
      
      this.refreshPromise.finally(() => {
        this.refreshPromise = null;
      });
    }
    
    return this.refreshPromise;
  }
  
  private async refreshToken(): Promise<string> {
    const refreshToken = this.getRefreshToken();
    
    if (!refreshToken) {
      throw new AuthenticationError('No refresh token');
    }
    
    const response = await fetch('/auth/refresh', {
      method: 'POST',
      body: JSON.stringify({ refreshToken }),
    });
    
    if (!response.ok) {
      throw new AuthenticationError('Token refresh failed');
    }
    
    const { accessToken } = await response.json();
    this.storeToken(accessToken);
    
    return accessToken;
  }
}
```

---

## Event System

### Event Emitter

```typescript
// internal/events.ts
type EventHandler<T = unknown> = (data: T) => void;

export class EventEmitter<Events extends Record<string, unknown>> {
  private handlers = new Map<keyof Events, Set<EventHandler>>();
  
  on<K extends keyof Events>(
    event: K,
    handler: EventHandler<Events[K]>
  ): () => void {
    if (!this.handlers.has(event)) {
      this.handlers.set(event, new Set());
    }
    
    this.handlers.get(event)!.add(handler as EventHandler);
    
    // Return unsubscribe function
    return () => {
      this.handlers.get(event)?.delete(handler as EventHandler);
    };
  }
  
  once<K extends keyof Events>(
    event: K,
    handler: EventHandler<Events[K]>
  ): () => void {
    const unsubscribe = this.on(event, (data) => {
      unsubscribe();
      handler(data);
    });
    
    return unsubscribe;
  }
  
  emit<K extends keyof Events>(event: K, data: Events[K]): void {
    const handlers = this.handlers.get(event);
    
    if (handlers) {
      for (const handler of handlers) {
        try {
          handler(data);
        } catch (error) {
          console.error(`Error in event handler for ${String(event)}:`, error);
        }
      }
    }
  }
  
  off<K extends keyof Events>(
    event: K,
    handler?: EventHandler<Events[K]>
  ): void {
    if (handler) {
      this.handlers.get(event)?.delete(handler as EventHandler);
    } else {
      this.handlers.delete(event);
    }
  }
  
  removeAllListeners(): void {
    this.handlers.clear();
  }
}
```

### Using Events in Client

```typescript
// Define event types
interface ClientEvents {
  'auth:login': { user: User };
  'auth:logout': undefined;
  'auth:token_refresh': { token: string };
  'request:start': { url: string; method: string };
  'request:end': { url: string; method: string; duration: number };
  'error': { error: SDKError };
}

// Client with events
class AuthClient extends EventEmitter<ClientEvents> {
  async login(email: string, password: string): Promise<Session> {
    const session = await this.http.post<Session>('/auth/login', {
      email,
      password,
    });
    
    this.emit('auth:login', { user: session.user });
    
    return session;
  }
  
  async logout(): Promise<void> {
    await this.http.post('/auth/logout');
    this.emit('auth:logout', undefined);
  }
}

// Usage
const client = new AuthClient({ baseUrl: '...' });

const unsubscribe = client.on('auth:login', ({ user }) => {
  console.log('User logged in:', user.email);
});

// Later
unsubscribe();
```

---

## Storage Abstraction

### Storage Interface

```typescript
// types.ts
export interface Storage {
  get(key: string): string | null;
  set(key: string, value: string): void;
  remove(key: string): void;
}
```

### Browser Storage

```typescript
// internal/storage/browser.ts
export class BrowserStorage implements Storage {
  constructor(private storage: globalThis.Storage = localStorage) {}
  
  get(key: string): string | null {
    try {
      return this.storage.getItem(key);
    } catch {
      return null;
    }
  }
  
  set(key: string, value: string): void {
    try {
      this.storage.setItem(key, value);
    } catch {
      // Storage full or not available
    }
  }
  
  remove(key: string): void {
    try {
      this.storage.removeItem(key);
    } catch {
      // Storage not available
    }
  }
}
```

### Memory Storage

```typescript
// internal/storage/memory.ts
export class MemoryStorage implements Storage {
  private store = new Map<string, string>();
  
  get(key: string): string | null {
    return this.store.get(key) ?? null;
  }
  
  set(key: string, value: string): void {
    this.store.set(key, value);
  }
  
  remove(key: string): void {
    this.store.delete(key);
  }
  
  clear(): void {
    this.store.clear();
  }
}
```

### Auto-Detect Storage

```typescript
// internal/storage/index.ts
export function createStorage(): Storage {
  // Check for localStorage
  if (typeof localStorage !== 'undefined') {
    try {
      localStorage.setItem('__test__', '__test__');
      localStorage.removeItem('__test__');
      return new BrowserStorage(localStorage);
    } catch {
      // localStorage not available
    }
  }
  
  // Fallback to memory
  return new MemoryStorage();
}
```

---

## Logging

### Logger Interface

```typescript
export interface Logger {
  debug(message: string, data?: unknown): void;
  info(message: string, data?: unknown): void;
  warn(message: string, data?: unknown): void;
  error(message: string, data?: unknown): void;
}

export const noopLogger: Logger = {
  debug: () => {},
  info: () => {},
  warn: () => {},
  error: () => {},
};

export const consoleLogger: Logger = {
  debug: (msg, data) => console.debug(`[SDK] ${msg}`, data ?? ''),
  info: (msg, data) => console.info(`[SDK] ${msg}`, data ?? ''),
  warn: (msg, data) => console.warn(`[SDK] ${msg}`, data ?? ''),
  error: (msg, data) => console.error(`[SDK] ${msg}`, data ?? ''),
};
```

### Using Logger

```typescript
class MyClient {
  private logger: Logger;
  
  constructor(config: ClientConfig) {
    this.logger = config.logger ?? noopLogger;
  }
  
  async getUser(id: string): Promise<User> {
    this.logger.debug('Getting user', { id });
    
    try {
      const user = await this.http.get<User>(`/users/${id}`);
      this.logger.info('Got user', { id, email: user.email });
      return user;
    } catch (error) {
      this.logger.error('Failed to get user', { id, error });
      throw error;
    }
  }
}
```
