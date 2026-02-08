# Events, Storage, and Logging

Event emitter patterns, storage abstraction, and logging for SDKs.

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
