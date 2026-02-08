# Package Structure and Client Patterns

SDK layout, client design patterns, and project organization.

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
