# Recovery Patterns

Retry logic, circuit breakers, fallbacks, and graceful degradation strategies.

## Retry Patterns

### Exponential Backoff with Jitter

```typescript
interface RetryOptions {
  maxAttempts: number;        // Maximum retry attempts
  baseDelay: number;          // Initial delay in ms
  maxDelay: number;           // Maximum delay cap
  factor: number;             // Exponential factor (usually 2)
  jitter: boolean;            // Add randomness
  shouldRetry: (error: Error, attempt: number) => boolean;
  onRetry?: (error: Error, attempt: number, delay: number) => void;
}

const defaultOptions: RetryOptions = {
  maxAttempts: 3,
  baseDelay: 1000,
  maxDelay: 30000,
  factor: 2,
  jitter: true,
  shouldRetry: (error) => {
    // Only retry transient errors
    if (error instanceof AppError) {
      return error.statusCode >= 500 || error.statusCode === 429;
    }
    return error.message.includes('ECONNREFUSED') ||
           error.message.includes('ETIMEDOUT');
  },
};

async function withRetry<T>(
  fn: () => Promise<T>,
  options: Partial<RetryOptions> = {}
): Promise<T> {
  const opts = { ...defaultOptions, ...options };
  let lastError: Error;
  
  for (let attempt = 1; attempt <= opts.maxAttempts; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error as Error;
      
      if (attempt === opts.maxAttempts) {
        throw lastError;
      }
      
      if (!opts.shouldRetry(lastError, attempt)) {
        throw lastError;
      }
      
      // Calculate delay with exponential backoff
      let delay = Math.min(
        opts.baseDelay * Math.pow(opts.factor, attempt - 1),
        opts.maxDelay
      );
      
      // Add jitter (±10%)
      if (opts.jitter) {
        const jitterRange = delay * 0.1;
        delay += Math.random() * jitterRange * 2 - jitterRange;
      }
      
      opts.onRetry?.(lastError, attempt, delay);
      
      await sleep(delay);
    }
  }
  
  throw lastError!;
}

// Usage
const result = await withRetry(
  () => fetchExternalAPI(url),
  {
    maxAttempts: 5,
    onRetry: (error, attempt, delay) => {
      logger.warn({ error, attempt, delay }, 'Retrying request');
    },
  }
);
```

### Retry Strategies by Error Type

```typescript
// Immediately retryable (transient)
const TRANSIENT_ERRORS = [
  'ECONNRESET',
  'ETIMEDOUT',
  'ECONNREFUSED',
  'EAI_AGAIN', // DNS lookup timeout
];

// Retryable after delay (rate limited)
const RATE_LIMITED_ERRORS = [429];

// Never retry (client errors)
const NON_RETRYABLE_ERRORS = [400, 401, 403, 404, 422];

function createShouldRetry(config: RetryConfig) {
  return (error: Error, attempt: number): boolean => {
    // Check for transient network errors
    if (TRANSIENT_ERRORS.some(code => error.message.includes(code))) {
      return true;
    }
    
    // Check HTTP status
    if (error instanceof AppError) {
      if (NON_RETRYABLE_ERRORS.includes(error.statusCode)) {
        return false;
      }
      if (error.statusCode === 429) {
        return true; // Will use longer backoff
      }
      if (error.statusCode >= 500) {
        return true;
      }
    }
    
    return false;
  };
}
```

### Retry with Timeout

```typescript
async function withRetryAndTimeout<T>(
  fn: () => Promise<T>,
  options: {
    timeout: number;
    retries: RetryOptions;
  }
): Promise<T> {
  const timeoutFn = () => withTimeout(fn(), options.timeout);
  return withRetry(timeoutFn, options.retries);
}

async function withTimeout<T>(
  promise: Promise<T>,
  ms: number
): Promise<T> {
  const timeout = new Promise<never>((_, reject) =>
    setTimeout(() => reject(new TimeoutError(`Timeout after ${ms}ms`)), ms)
  );
  return Promise.race([promise, timeout]);
}
```

## Circuit Breaker

### Full Implementation

```typescript
type CircuitState = 'closed' | 'open' | 'half-open';

interface CircuitBreakerOptions {
  failureThreshold: number;    // Failures before opening
  successThreshold: number;    // Successes in half-open to close
  timeout: number;             // Time in open state before half-open
  volumeThreshold: number;     // Min requests before evaluating
  errorFilter?: (error: Error) => boolean; // Which errors trip the circuit
}

class CircuitBreaker {
  private state: CircuitState = 'closed';
  private failures = 0;
  private successes = 0;
  private requests = 0;
  private lastFailureTime?: number;
  private nextAttemptTime?: number;

  constructor(
    private readonly name: string,
    private readonly options: CircuitBreakerOptions = {
      failureThreshold: 5,
      successThreshold: 3,
      timeout: 60000,
      volumeThreshold: 10,
      errorFilter: () => true,
    }
  ) {}

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    // Check if circuit allows request
    if (!this.canExecute()) {
      throw new CircuitOpenError(
        `Circuit ${this.name} is open. Retry after ${this.getRetryDelay()}ms`
      );
    }

    this.requests++;

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure(error as Error);
      throw error;
    }
  }

  private canExecute(): boolean {
    if (this.state === 'closed') {
      return true;
    }

    if (this.state === 'open') {
      if (Date.now() >= (this.nextAttemptTime ?? 0)) {
        this.state = 'half-open';
        this.successes = 0;
        logger.info({ circuit: this.name }, 'Circuit entering half-open state');
        return true;
      }
      return false;
    }

    // half-open: allow limited requests
    return true;
  }

  private onSuccess(): void {
    if (this.state === 'half-open') {
      this.successes++;
      if (this.successes >= this.options.successThreshold) {
        this.close();
      }
    } else {
      this.failures = 0;
    }
  }

  private onFailure(error: Error): void {
    // Check if this error should trip the circuit
    if (!this.options.errorFilter!(error)) {
      return;
    }

    this.failures++;
    this.lastFailureTime = Date.now();

    if (this.state === 'half-open') {
      this.open();
    } else if (
      this.state === 'closed' &&
      this.requests >= this.options.volumeThreshold &&
      this.failures >= this.options.failureThreshold
    ) {
      this.open();
    }
  }

  private open(): void {
    this.state = 'open';
    this.nextAttemptTime = Date.now() + this.options.timeout;
    logger.warn({ circuit: this.name }, 'Circuit opened');
    
    // Emit event for monitoring
    circuitEvents.emit('open', { name: this.name, failures: this.failures });
  }

  private close(): void {
    this.state = 'closed';
    this.failures = 0;
    this.successes = 0;
    this.requests = 0;
    logger.info({ circuit: this.name }, 'Circuit closed');
    
    circuitEvents.emit('close', { name: this.name });
  }

  getState(): CircuitState {
    return this.state;
  }

  getRetryDelay(): number {
    return Math.max(0, (this.nextAttemptTime ?? 0) - Date.now());
  }

  // Manual controls for testing/admin
  forceOpen(): void {
    this.open();
  }

  forceClose(): void {
    this.close();
  }
}

// Usage
const paymentCircuit = new CircuitBreaker('payment-service', {
  failureThreshold: 5,
  timeout: 30000,
  errorFilter: (error) => {
    // Only trip on service errors, not validation
    return error instanceof ExternalServiceError;
  },
});

async function processPayment(payment: Payment) {
  return paymentCircuit.execute(() => paymentService.process(payment));
}
```

### Circuit Breaker Decorator

```typescript
function circuitBreaker(options: CircuitBreakerOptions) {
  const circuits = new Map<string, CircuitBreaker>();
  
  return function (
    target: any,
    propertyKey: string,
    descriptor: PropertyDescriptor
  ) {
    const originalMethod = descriptor.value;
    const circuitName = `${target.constructor.name}.${propertyKey}`;
    
    if (!circuits.has(circuitName)) {
      circuits.set(circuitName, new CircuitBreaker(circuitName, options));
    }
    
    descriptor.value = async function (...args: any[]) {
      const circuit = circuits.get(circuitName)!;
      return circuit.execute(() => originalMethod.apply(this, args));
    };
    
    return descriptor;
  };
}

// Usage
class PaymentService {
  @circuitBreaker({ failureThreshold: 5, timeout: 30000 })
  async processPayment(payment: Payment) {
    return this.client.post('/payments', payment);
  }
}
```

## Fallback Patterns

### Static Fallback

```typescript
async function getUserAvatar(userId: string): Promise<string> {
  try {
    return await avatarService.get(userId);
  } catch (error) {
    logger.warn({ error, userId }, 'Avatar fetch failed, using default');
    return '/images/default-avatar.png';
  }
}
```

### Cached Fallback

```typescript
async function getProductPrice(productId: string): Promise<number> {
  try {
    const price = await priceService.getCurrentPrice(productId);
    await cache.set(`price:${productId}`, price, { ttl: 3600 });
    return price;
  } catch (error) {
    // Try cached price
    const cached = await cache.get(`price:${productId}`);
    if (cached !== null) {
      logger.warn({ productId }, 'Using cached price');
      return cached;
    }
    throw error;
  }
}
```

### Degraded Response

```typescript
interface ProductDetails {
  id: string;
  name: string;
  price: number;
  reviews?: Review[];       // Optional: can degrade
  recommendations?: Product[]; // Optional: can degrade
}

async function getProductDetails(id: string): Promise<ProductDetails> {
  const [product, reviews, recommendations] = await Promise.allSettled([
    productService.get(id),
    reviewService.getForProduct(id),
    recommendationService.get(id),
  ]);

  // Product is required
  if (product.status === 'rejected') {
    throw product.reason;
  }

  return {
    ...product.value,
    reviews: reviews.status === 'fulfilled' ? reviews.value : undefined,
    recommendations: recommendations.status === 'fulfilled' ? recommendations.value : undefined,
  };
}
```

### Feature Flag Fallback

```typescript
async function searchProducts(query: string): Promise<SearchResults> {
  // Check if new search is enabled
  if (await featureFlags.isEnabled('new-search-engine')) {
    try {
      return await newSearchService.search(query);
    } catch (error) {
      logger.error({ error }, 'New search failed, falling back');
      // Fall through to legacy search
    }
  }
  
  return legacySearchService.search(query);
}
```

## Graceful Degradation

### Service Degradation Levels

```typescript
enum DegradationLevel {
  FULL = 'full',
  PARTIAL = 'partial',
  MINIMAL = 'minimal',
  OFFLINE = 'offline',
}

class ServiceDegradation {
  private level: DegradationLevel = DegradationLevel.FULL;
  
  setLevel(level: DegradationLevel) {
    this.level = level;
    logger.warn({ level }, 'Service degradation level changed');
  }
  
  async getFeatures(): Promise<FeatureSet> {
    switch (this.level) {
      case DegradationLevel.FULL:
        return {
          search: true,
          recommendations: true,
          realTimeUpdates: true,
          analytics: true,
        };
      case DegradationLevel.PARTIAL:
        return {
          search: true,
          recommendations: false,  // Disable expensive features
          realTimeUpdates: false,
          analytics: true,
        };
      case DegradationLevel.MINIMAL:
        return {
          search: true,           // Core functionality only
          recommendations: false,
          realTimeUpdates: false,
          analytics: false,
        };
      case DegradationLevel.OFFLINE:
        return {
          search: false,
          recommendations: false,
          realTimeUpdates: false,
          analytics: false,
        };
    }
  }
}
```

### Progressive Enhancement API

```typescript
interface APIResponse<T> {
  data: T;
  degraded?: {
    features: string[];
    reason: string;
  };
}

async function getDashboard(): Promise<APIResponse<Dashboard>> {
  const degradedFeatures: string[] = [];
  
  // Core data (required)
  const [user, transactions] = await Promise.all([
    userService.getCurrent(),
    transactionService.getRecent(),
  ]);
  
  // Enhanced data (optional)
  let analytics: Analytics | undefined;
  try {
    analytics = await analyticsService.getSummary();
  } catch (error) {
    degradedFeatures.push('analytics');
    logger.warn({ error }, 'Analytics unavailable');
  }
  
  let recommendations: Product[] | undefined;
  try {
    recommendations = await recommendationService.getPersonalized();
  } catch (error) {
    degradedFeatures.push('recommendations');
    logger.warn({ error }, 'Recommendations unavailable');
  }
  
  return {
    data: { user, transactions, analytics, recommendations },
    degraded: degradedFeatures.length > 0 ? {
      features: degradedFeatures,
      reason: 'Some features temporarily unavailable',
    } : undefined,
  };
}
```

## Bulkhead Pattern

### Isolate Failures

```typescript
import pLimit from 'p-limit';

class BulkheadExecutor {
  private limiters: Map<string, ReturnType<typeof pLimit>> = new Map();
  
  constructor(
    private readonly limits: Record<string, number>
  ) {
    for (const [name, limit] of Object.entries(limits)) {
      this.limiters.set(name, pLimit(limit));
    }
  }
  
  async execute<T>(
    bulkhead: string,
    fn: () => Promise<T>
  ): Promise<T> {
    const limiter = this.limiters.get(bulkhead);
    if (!limiter) {
      throw new Error(`Unknown bulkhead: ${bulkhead}`);
    }
    return limiter(fn);
  }
}

// Configure isolation
const bulkheads = new BulkheadExecutor({
  'database': 10,      // Max 10 concurrent DB calls
  'external-api': 5,   // Max 5 concurrent API calls
  'file-processing': 3, // Max 3 concurrent file operations
});

// Usage
async function handleRequest() {
  const [user, products] = await Promise.all([
    bulkheads.execute('database', () => db.getUser(userId)),
    bulkheads.execute('external-api', () => productApi.list()),
  ]);
}
```

## Health Checks

### Dependency Health

```typescript
interface HealthStatus {
  status: 'healthy' | 'degraded' | 'unhealthy';
  checks: Record<string, {
    status: 'up' | 'down';
    latency?: number;
    error?: string;
  }>;
}

async function checkHealth(): Promise<HealthStatus> {
  const checks: HealthStatus['checks'] = {};
  
  // Database check
  const dbStart = Date.now();
  try {
    await db.query('SELECT 1');
    checks.database = { status: 'up', latency: Date.now() - dbStart };
  } catch (error) {
    checks.database = { status: 'down', error: (error as Error).message };
  }
  
  // Cache check
  const cacheStart = Date.now();
  try {
    await cache.ping();
    checks.cache = { status: 'up', latency: Date.now() - cacheStart };
  } catch (error) {
    checks.cache = { status: 'down', error: (error as Error).message };
  }
  
  // External API check
  const apiStart = Date.now();
  try {
    await externalApi.healthCheck();
    checks.externalApi = { status: 'up', latency: Date.now() - apiStart };
  } catch (error) {
    checks.externalApi = { status: 'down', error: (error as Error).message };
  }
  
  // Determine overall status
  const downCount = Object.values(checks).filter(c => c.status === 'down').length;
  const status: HealthStatus['status'] = 
    downCount === 0 ? 'healthy' :
    downCount === Object.keys(checks).length ? 'unhealthy' :
    'degraded';
  
  return { status, checks };
}
```

## Combining Patterns

### Resilient Service Call

```typescript
class ResilientClient {
  private circuit: CircuitBreaker;
  private retryOptions: RetryOptions;
  
  constructor(
    private readonly name: string,
    private readonly client: HTTPClient,
    options: {
      circuit?: Partial<CircuitBreakerOptions>;
      retry?: Partial<RetryOptions>;
    } = {}
  ) {
    this.circuit = new CircuitBreaker(name, options.circuit);
    this.retryOptions = { ...defaultRetryOptions, ...options.retry };
  }
  
  async request<T>(path: string, options?: RequestOptions): Promise<T> {
    // Circuit breaker wraps retry
    return this.circuit.execute(async () => {
      return withRetry(
        () => this.client.request<T>(path, options),
        this.retryOptions
      );
    });
  }
}

// Usage
const paymentClient = new ResilientClient('payment', httpClient, {
  circuit: { failureThreshold: 5, timeout: 30000 },
  retry: { maxAttempts: 3, baseDelay: 500 },
});
```

### Full Resilience Stack

```typescript
async function processOrder(order: Order): Promise<OrderResult> {
  // 1. Circuit breaker prevents cascade failure
  return orderCircuit.execute(async () => {
    // 2. Retry handles transient failures
    return withRetry(async () => {
      // 3. Timeout prevents hanging
      return withTimeout(async () => {
        // 4. Bulkhead limits concurrency
        return bulkheads.execute('orders', async () => {
          // 5. Fallback handles degradation
          try {
            return await orderService.process(order);
          } catch (error) {
            if (error instanceof ExternalServiceError) {
              // Queue for later processing
              await orderQueue.enqueue(order);
              return { status: 'queued', order };
            }
            throw error;
          }
        });
      }, 5000);
    }, { maxAttempts: 3 });
  });
}
```

## Anti-Patterns

### ❌ Retry Everything

```typescript
// BAD: Retrying non-retryable errors
await withRetry(() => validateInput(data)); // 400s won't magically fix
await withRetry(() => authenticate(token));  // Invalid token stays invalid

// GOOD: Only retry transient failures
await withRetry(
  () => callExternalService(),
  { shouldRetry: (e) => e.statusCode >= 500 }
);
```

### ❌ Circuit Breaker Without Fallback

```typescript
// BAD: Just throws to user
try {
  await paymentCircuit.execute(() => processPayment());
} catch (error) {
  if (error instanceof CircuitOpenError) {
    throw error; // User sees "circuit open"
  }
}

// GOOD: Graceful degradation
try {
  await paymentCircuit.execute(() => processPayment());
} catch (error) {
  if (error instanceof CircuitOpenError) {
    await queuePaymentForLater();
    return { status: 'pending', message: 'Processing delayed' };
  }
  throw error;
}
```

### ❌ Infinite Retry Loops

```typescript
// BAD: Can loop forever
while (true) {
  try {
    return await doSomething();
  } catch {
    await sleep(1000);
  }
}

// GOOD: Bounded retries
await withRetry(doSomething, { maxAttempts: 5, maxDelay: 30000 });
```
