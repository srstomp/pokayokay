# Error Patterns

Patterns for designing custom errors and explicit error handling.

## Custom Error Class Hierarchy

### Full-Featured Base Error

```typescript
interface ErrorContext {
  [key: string]: unknown;
}

abstract class AppError extends Error {
  abstract readonly statusCode: number;
  readonly timestamp: Date;
  readonly isOperational: boolean;
  
  constructor(
    message: string,
    public readonly code: string,
    public readonly context: ErrorContext = {},
    public readonly cause?: Error
  ) {
    super(message);
    this.name = this.constructor.name;
    this.timestamp = new Date();
    this.isOperational = true; // vs programmer errors
    
    // Maintains proper stack trace
    Error.captureStackTrace(this, this.constructor);
    
    // Preserve cause chain (Node 16.9+)
    if (cause && !this.cause) {
      this.cause = cause;
    }
  }

  // For JSON serialization (logs, API responses)
  toJSON() {
    return {
      name: this.name,
      code: this.code,
      message: this.message,
      context: this.context,
      timestamp: this.timestamp.toISOString(),
      stack: process.env.NODE_ENV === 'development' ? this.stack : undefined,
    };
  }

  // For logging with cause chain
  getFullStack(): string {
    let stack = this.stack || '';
    if (this.cause instanceof Error) {
      stack += '\nCaused by: ' + (this.cause.stack || this.cause.message);
    }
    return stack;
  }
}
```

### Domain Error Classes

```typescript
// Validation errors (400)
class ValidationError extends AppError {
  readonly statusCode = 400;
  
  constructor(
    message: string,
    public readonly field?: string,
    public readonly value?: unknown
  ) {
    super(message, 'VALIDATION_ERROR', { field, value });
  }
  
  static required(field: string): ValidationError {
    return new ValidationError(`${field} is required`, field);
  }
  
  static invalid(field: string, value: unknown, reason?: string): ValidationError {
    const msg = reason ? `Invalid ${field}: ${reason}` : `Invalid ${field}`;
    return new ValidationError(msg, field, value);
  }
  
  static fromZod(error: z.ZodError): ValidationError {
    const issue = error.issues[0];
    return new ValidationError(
      issue.message,
      issue.path.join('.'),
      undefined
    );
  }
}

// Not found errors (404)
class NotFoundError extends AppError {
  readonly statusCode = 404;
  
  constructor(
    public readonly resource: string,
    public readonly identifier: string
  ) {
    super(
      `${resource} not found: ${identifier}`,
      'NOT_FOUND',
      { resource, identifier }
    );
  }
}

// Authentication errors (401)
class AuthenticationError extends AppError {
  readonly statusCode = 401;
  
  constructor(message = 'Authentication required', code = 'AUTH_REQUIRED') {
    super(message, code);
  }
  
  static expired(): AuthenticationError {
    return new AuthenticationError('Session expired', 'AUTH_EXPIRED');
  }
  
  static invalid(): AuthenticationError {
    return new AuthenticationError('Invalid credentials', 'AUTH_INVALID');
  }
}

// Authorization errors (403)
class AuthorizationError extends AppError {
  readonly statusCode = 403;
  
  constructor(
    public readonly action: string,
    public readonly resource: string
  ) {
    super(
      `Not authorized to ${action} ${resource}`,
      'FORBIDDEN',
      { action, resource }
    );
  }
}

// Conflict errors (409)
class ConflictError extends AppError {
  readonly statusCode = 409;
  
  constructor(message: string, context?: ErrorContext) {
    super(message, 'CONFLICT', context);
  }
  
  static duplicate(resource: string, field: string, value: string): ConflictError {
    return new ConflictError(
      `${resource} with ${field} "${value}" already exists`,
      { resource, field, value }
    );
  }
  
  static versionMismatch(resource: string, expected: number, actual: number): ConflictError {
    return new ConflictError(
      `Version conflict: expected ${expected}, got ${actual}`,
      { resource, expected, actual }
    );
  }
}

// External service errors (502/503)
class ExternalServiceError extends AppError {
  readonly statusCode = 503;
  
  constructor(
    public readonly service: string,
    message: string,
    cause?: Error
  ) {
    super(message, 'SERVICE_ERROR', { service }, cause);
  }
}

// Rate limit errors (429)
class RateLimitError extends AppError {
  readonly statusCode = 429;
  
  constructor(
    public readonly retryAfter?: number
  ) {
    super(
      `Rate limit exceeded${retryAfter ? `. Retry after ${retryAfter}s` : ''}`,
      'RATE_LIMITED',
      { retryAfter }
    );
  }
}
```

### Error Type Guards

```typescript
function isAppError(error: unknown): error is AppError {
  return error instanceof AppError;
}

function isOperationalError(error: unknown): error is AppError {
  return error instanceof AppError && error.isOperational;
}

// Type-safe error handling
function handleError(error: unknown): never {
  if (isAppError(error)) {
    // Safe to access AppError properties
    logger.error({ error: error.toJSON() });
  } else if (error instanceof Error) {
    // Standard Error
    logger.error({ message: error.message, stack: error.stack });
  } else {
    // Unknown type
    logger.error({ unknownError: error });
  }
  throw error;
}
```

## Result Pattern

### Basic Result Type

```typescript
type Result<T, E = Error> = 
  | { ok: true; value: T }
  | { ok: false; error: E };

// Constructors
const Ok = <T>(value: T): Result<T, never> => ({ ok: true, value });
const Err = <E>(error: E): Result<never, E> => ({ ok: false, error });

// Type guards
const isOk = <T, E>(result: Result<T, E>): result is { ok: true; value: T } => result.ok;
const isErr = <T, E>(result: Result<T, E>): result is { ok: false; error: E } => !result.ok;
```

### Result Utilities

```typescript
// Unwrap or throw
function unwrap<T, E>(result: Result<T, E>): T {
  if (result.ok) return result.value;
  throw result.error;
}

// Unwrap with default
function unwrapOr<T, E>(result: Result<T, E>, defaultValue: T): T {
  return result.ok ? result.value : defaultValue;
}

// Map success value
function map<T, U, E>(result: Result<T, E>, fn: (value: T) => U): Result<U, E> {
  return result.ok ? Ok(fn(result.value)) : result;
}

// Map error
function mapErr<T, E, F>(result: Result<T, E>, fn: (error: E) => F): Result<T, F> {
  return result.ok ? result : Err(fn(result.error));
}

// Flat map (for chaining Results)
function flatMap<T, U, E>(result: Result<T, E>, fn: (value: T) => Result<U, E>): Result<U, E> {
  return result.ok ? fn(result.value) : result;
}

// Try-catch wrapper
function tryCatch<T>(fn: () => T): Result<T, Error> {
  try {
    return Ok(fn());
  } catch (e) {
    return Err(e instanceof Error ? e : new Error(String(e)));
  }
}

// Async version
async function tryCatchAsync<T>(fn: () => Promise<T>): Promise<Result<T, Error>> {
  try {
    return Ok(await fn());
  } catch (e) {
    return Err(e instanceof Error ? e : new Error(String(e)));
  }
}

// Collect array of Results
function collect<T, E>(results: Result<T, E>[]): Result<T[], E> {
  const values: T[] = [];
  for (const result of results) {
    if (!result.ok) return result;
    values.push(result.value);
  }
  return Ok(values);
}
```

### Result in Practice

```typescript
// Service layer returning Results
class UserService {
  async createUser(input: CreateUserInput): Promise<Result<User, ValidationError | ConflictError>> {
    // Validate
    const validation = validateUserInput(input);
    if (!validation.ok) return validation;
    
    // Check for duplicates
    const existing = await this.userRepo.findByEmail(input.email);
    if (existing) {
      return Err(ConflictError.duplicate('User', 'email', input.email));
    }
    
    // Create
    const user = await this.userRepo.create(validation.value);
    return Ok(user);
  }
  
  async getUser(id: string): Promise<Result<User, NotFoundError>> {
    const user = await this.userRepo.findById(id);
    if (!user) {
      return Err(new NotFoundError('User', id));
    }
    return Ok(user);
  }
}

// Controller using Results
async function createUserHandler(req: Request, res: Response) {
  const result = await userService.createUser(req.body);
  
  if (!result.ok) {
    const error = result.error;
    return res.status(error.statusCode).json({ error: error.toJSON() });
  }
  
  return res.status(201).json({ data: result.value });
}

// Chaining Results
async function processOrder(orderId: string): Promise<Result<Receipt, AppError>> {
  const orderResult = await orderService.getOrder(orderId);
  if (!orderResult.ok) return orderResult;
  
  const validationResult = validateOrder(orderResult.value);
  if (!validationResult.ok) return validationResult;
  
  const paymentResult = await paymentService.charge(validationResult.value);
  if (!paymentResult.ok) return paymentResult;
  
  return Ok(createReceipt(paymentResult.value));
}

// Using flatMap for cleaner chaining
async function processOrderClean(orderId: string): Promise<Result<Receipt, AppError>> {
  return flatMap(
    await orderService.getOrder(orderId),
    (order) => flatMap(
      validateOrder(order),
      async (validated) => flatMap(
        await paymentService.charge(validated),
        (payment) => Ok(createReceipt(payment))
      )
    )
  );
}
```

## Error Aggregation

### Collecting Multiple Errors

```typescript
class AggregateError extends AppError {
  readonly statusCode = 400;
  
  constructor(
    public readonly errors: AppError[],
    message = 'Multiple errors occurred'
  ) {
    super(message, 'AGGREGATE_ERROR', {
      count: errors.length,
      errors: errors.map(e => e.toJSON()),
    });
  }
}

// Validation that collects all errors
function validateForm(input: FormInput): Result<ValidForm, AggregateError> {
  const errors: ValidationError[] = [];
  
  if (!input.email) {
    errors.push(ValidationError.required('email'));
  } else if (!isValidEmail(input.email)) {
    errors.push(ValidationError.invalid('email', input.email, 'invalid format'));
  }
  
  if (!input.password) {
    errors.push(ValidationError.required('password'));
  } else if (input.password.length < 8) {
    errors.push(ValidationError.invalid('password', '[redacted]', 'must be at least 8 characters'));
  }
  
  if (errors.length > 0) {
    return Err(new AggregateError(errors, 'Form validation failed'));
  }
  
  return Ok(input as ValidForm);
}
```

## Error Wrapping

### Preserving Error Chains

```typescript
// Wrap with context
function wrapError(error: Error, message: string, context?: ErrorContext): AppError {
  if (error instanceof AppError) {
    // Add context to existing AppError
    return new (error.constructor as any)(
      `${message}: ${error.message}`,
      error.code,
      { ...error.context, ...context },
      error.cause || error
    );
  }
  
  // Wrap unknown error
  return new InternalError(message, context, error);
}

// Usage
async function fetchUserOrders(userId: string): Promise<Order[]> {
  try {
    const user = await userService.getUser(userId);
    return await orderService.getByUser(user.id);
  } catch (error) {
    throw wrapError(
      error as Error,
      `Failed to fetch orders for user ${userId}`,
      { userId }
    );
  }
}
```

## Zod Integration

```typescript
import { z } from 'zod';

// Convert Zod errors to ValidationError
function fromZodError(error: z.ZodError): ValidationError {
  const issue = error.issues[0];
  const field = issue.path.join('.');
  return ValidationError.invalid(field, undefined, issue.message);
}

// Parse with Result
function parseWithResult<T>(schema: z.Schema<T>, data: unknown): Result<T, ValidationError> {
  const result = schema.safeParse(data);
  if (result.success) {
    return Ok(result.data);
  }
  return Err(fromZodError(result.error));
}

// Usage
const userSchema = z.object({
  email: z.string().email(),
  name: z.string().min(1),
});

const result = parseWithResult(userSchema, req.body);
if (!result.ok) {
  return res.status(400).json({ error: result.error.toJSON() });
}
```

## Best Practices

### 1. Be Specific About Error Types

```typescript
// ❌ Generic
throw new Error('Failed');

// ✅ Specific
throw new NotFoundError('Order', orderId);
throw ValidationError.invalid('email', input.email, 'must be a valid email');
```

### 2. Include Actionable Context

```typescript
// ❌ Missing context
throw new ExternalServiceError('Payment service', 'Request failed');

// ✅ Actionable context
throw new ExternalServiceError(
  'Payment service',
  'Request failed',
  originalError
);
// Context includes: service name, original error, timestamp
```

### 3. Distinguish Operational vs Programmer Errors

```typescript
// Operational: Expected, handle gracefully
throw new ValidationError('Invalid email');  // User can fix
throw new NotFoundError('Order', id);        // Expected state
throw new RateLimitError(60);                // Temporary

// Programmer: Unexpected, let crash
throw new TypeError('Expected array');       // Bug in code
throw new ReferenceError('undefined');       // Bug in code
```

### 4. Use Factory Methods for Common Cases

```typescript
class ValidationError extends AppError {
  // Factory methods make usage cleaner
  static required(field: string): ValidationError { ... }
  static invalid(field: string, value: unknown, reason?: string): ValidationError { ... }
  static tooLong(field: string, max: number, actual: number): ValidationError { ... }
  static fromZod(error: z.ZodError): ValidationError { ... }
}

// Usage
throw ValidationError.required('email');
throw ValidationError.tooLong('name', 100, 150);
```
