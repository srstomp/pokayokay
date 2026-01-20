# Logging Patterns Reference

## Library Comparison

| Library | Best For | Performance | Features |
|---------|----------|-------------|----------|
| **Pino** | High-throughput APIs | Fastest | JSON-native, low overhead |
| **Winston** | Feature-rich apps | Good | Transports, formats, levels |
| **Bunyan** | Legacy Node apps | Good | JSON, dtrace support |
| **console** | Simple scripts | N/A | Built-in, no deps |

**Recommendation:** Pino for production APIs, Winston for complex logging needs.

## Pino Complete Setup

### Basic Configuration

```typescript
import pino, { Logger } from 'pino';
import { randomUUID } from 'crypto';

// Base logger configuration
export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  
  // Use ISO timestamps
  timestamp: pino.stdTimeFunctions.isoTime,
  
  // Custom formatters
  formatters: {
    level: (label) => ({ level: label }),
    bindings: () => ({}), // Remove pid/hostname if not needed
  },
  
  // Redact sensitive fields
  redact: {
    paths: [
      'password',
      '*.password',
      'req.headers.authorization',
      'req.headers.cookie',
      'creditCard',
      'ssn',
      'apiKey',
      '*.apiKey',
    ],
    censor: '[REDACTED]',
  },
});

// Child logger factory for request context
export function createRequestLogger(correlationId: string): Logger {
  return logger.child({ correlationId });
}
```

### Express Middleware

```typescript
import { Request, Response, NextFunction } from 'express';
import { logger, createRequestLogger } from './logger';

declare global {
  namespace Express {
    interface Request {
      log: pino.Logger;
      correlationId: string;
    }
  }
}

export function requestLogger(req: Request, res: Response, next: NextFunction) {
  const correlationId = req.headers['x-correlation-id']?.toString() || randomUUID();
  
  req.correlationId = correlationId;
  req.log = createRequestLogger(correlationId);
  
  // Set correlation ID on response for client debugging
  res.setHeader('x-correlation-id', correlationId);
  
  const startTime = process.hrtime.bigint();
  
  res.on('finish', () => {
    const duration = Number(process.hrtime.bigint() - startTime) / 1_000_000;
    
    req.log.info({
      event: 'http_request',
      method: req.method,
      path: req.path,
      statusCode: res.statusCode,
      duration_ms: Math.round(duration),
      userAgent: req.headers['user-agent'],
    });
  });
  
  next();
}
```

### Error Logging

```typescript
// Error serializer for consistent error logging
const errorSerializer = (err: Error & { code?: string; statusCode?: number }) => ({
  type: err.constructor.name,
  message: err.message,
  code: err.code,
  statusCode: err.statusCode,
  stack: process.env.NODE_ENV === 'development' ? err.stack : undefined,
});

// Usage
try {
  await riskyOperation();
} catch (error) {
  req.log.error({
    event: 'operation_failed',
    error: errorSerializer(error as Error),
    context: { orderId, userId },
  });
  throw error;
}
```

### Pretty Printing for Development

```typescript
import pino from 'pino';

const transport = process.env.NODE_ENV === 'development'
  ? {
      target: 'pino-pretty',
      options: {
        colorize: true,
        translateTime: 'HH:MM:ss',
        ignore: 'pid,hostname',
      },
    }
  : undefined;

const logger = pino({ transport });
```

## Winston Complete Setup

### Basic Configuration

```typescript
import winston from 'winston';

const { combine, timestamp, json, errors, printf } = winston.format;

// Custom format for development
const devFormat = printf(({ level, message, timestamp, ...meta }) => {
  const metaStr = Object.keys(meta).length ? JSON.stringify(meta, null, 2) : '';
  return `${timestamp} [${level}]: ${message} ${metaStr}`;
});

export const logger = winston.createLogger({
  level: process.env.LOG_LEVEL || 'info',
  format: combine(
    timestamp({ format: 'YYYY-MM-DDTHH:mm:ss.SSSZ' }),
    errors({ stack: true }),
    json()
  ),
  defaultMeta: { service: process.env.SERVICE_NAME || 'app' },
  transports: [
    new winston.transports.Console({
      format: process.env.NODE_ENV === 'development'
        ? combine(winston.format.colorize(), devFormat)
        : undefined,
    }),
  ],
});

// Add file transport for production
if (process.env.NODE_ENV === 'production') {
  logger.add(new winston.transports.File({ 
    filename: 'logs/error.log', 
    level: 'error' 
  }));
  logger.add(new winston.transports.File({ 
    filename: 'logs/combined.log' 
  }));
}
```

### Winston with Correlation ID

```typescript
import { AsyncLocalStorage } from 'async_hooks';

const asyncLocalStorage = new AsyncLocalStorage<{ correlationId: string }>();

// Middleware to set up context
export function contextMiddleware(req: Request, res: Response, next: NextFunction) {
  const correlationId = req.headers['x-correlation-id']?.toString() || randomUUID();
  asyncLocalStorage.run({ correlationId }, () => next());
}

// Logger that auto-includes correlation ID
export function getLogger() {
  const store = asyncLocalStorage.getStore();
  return logger.child({ correlationId: store?.correlationId });
}
```

## Log Aggregation Patterns

### JSON Lines Format (Recommended)

```json
{"timestamp":"2024-01-15T10:30:00.123Z","level":"info","event":"user_login","userId":"123","correlationId":"abc-def"}
{"timestamp":"2024-01-15T10:30:00.456Z","level":"error","event":"payment_failed","error":{"type":"PaymentError","message":"Card declined"},"correlationId":"abc-def"}
```

### Shipping to Log Aggregators

**Datadog:**
```typescript
// Use pino-datadog transport
import pino from 'pino';

const logger = pino({
  transport: {
    target: 'pino-datadog',
    options: {
      apiKey: process.env.DD_API_KEY,
      service: 'my-service',
      source: 'nodejs',
    },
  },
});
```

**ELK Stack (Logstash):**
```typescript
// Write to stdout, use Filebeat to ship
// filebeat.yml
// - type: log
//   paths: ['/var/log/app/*.log']
//   json.keys_under_root: true
```

**CloudWatch:**
```typescript
// Use pino-cloudwatch transport
import pino from 'pino';

const logger = pino({
  transport: {
    target: 'pino-cloudwatch',
    options: {
      logGroupName: '/my-app/logs',
      logStreamName: `${process.env.HOSTNAME}-${Date.now()}`,
      region: 'us-east-1',
    },
  },
});
```

## Structured Logging Best Practices

### Event-Based Logging

```typescript
// Define event types for consistency
type LogEvent = 
  | 'http_request'
  | 'http_response'
  | 'user_login'
  | 'user_logout'
  | 'payment_initiated'
  | 'payment_completed'
  | 'payment_failed'
  | 'cache_hit'
  | 'cache_miss'
  | 'db_query'
  | 'external_api_call';

// Type-safe logging
function logEvent(
  logger: Logger,
  event: LogEvent,
  data: Record<string, unknown>,
  level: 'info' | 'warn' | 'error' = 'info'
) {
  logger[level]({ event, ...data });
}

// Usage
logEvent(req.log, 'payment_completed', { 
  paymentId, 
  amount, 
  duration_ms 
});
```

### Duration Tracking

```typescript
// Helper for timing operations
async function withTiming<T>(
  logger: Logger,
  event: string,
  fn: () => Promise<T>,
  metadata: Record<string, unknown> = {}
): Promise<T> {
  const start = process.hrtime.bigint();
  try {
    const result = await fn();
    const duration_ms = Number(process.hrtime.bigint() - start) / 1_000_000;
    logger.info({ event, duration_ms, success: true, ...metadata });
    return result;
  } catch (error) {
    const duration_ms = Number(process.hrtime.bigint() - start) / 1_000_000;
    logger.error({ 
      event, 
      duration_ms, 
      success: false, 
      error: (error as Error).message,
      ...metadata 
    });
    throw error;
  }
}

// Usage
const result = await withTiming(
  req.log,
  'db_query',
  () => db.users.findById(userId),
  { table: 'users', operation: 'findById' }
);
```

### Log Sampling for High-Volume Events

```typescript
// Sample 10% of debug logs in production
const shouldSample = (rate: number) => Math.random() < rate;

function logDebugSampled(
  logger: Logger,
  message: string,
  data: Record<string, unknown>,
  sampleRate = 0.1
) {
  if (process.env.NODE_ENV === 'development' || shouldSample(sampleRate)) {
    logger.debug({ ...data, sampled: true, sampleRate }, message);
  }
}
```

## Security Considerations

### PII Detection

```typescript
// Common PII patterns to redact
const piiPatterns = [
  { name: 'email', pattern: /\b[\w.+-]+@[\w.-]+\.\w{2,}\b/gi },
  { name: 'ssn', pattern: /\b\d{3}-\d{2}-\d{4}\b/g },
  { name: 'credit_card', pattern: /\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b/g },
  { name: 'phone', pattern: /\b\d{3}[-.]?\d{3}[-.]?\d{4}\b/g },
];

function redactPII(value: string): string {
  let redacted = value;
  for (const { name, pattern } of piiPatterns) {
    redacted = redacted.replace(pattern, `[REDACTED_${name.toUpperCase()}]`);
  }
  return redacted;
}
```

### Audit Logging

```typescript
// Separate audit log for compliance
const auditLogger = pino({
  level: 'info',
  transport: {
    target: 'pino/file',
    options: { destination: '/var/log/audit/audit.log' },
  },
});

function logAuditEvent(
  action: 'create' | 'read' | 'update' | 'delete',
  resource: string,
  resourceId: string,
  userId: string,
  metadata: Record<string, unknown> = {}
) {
  auditLogger.info({
    event: 'audit',
    action,
    resource,
    resourceId,
    userId,
    timestamp: new Date().toISOString(),
    ...metadata,
  });
}
```

## Log Levels in Practice

### Level Configuration by Environment

```typescript
const logLevels: Record<string, string> = {
  development: 'debug',
  test: 'warn',
  staging: 'info',
  production: 'info',
};

const level = process.env.LOG_LEVEL || logLevels[process.env.NODE_ENV || 'development'];
```

### Dynamic Level Changes

```typescript
// Endpoint to change log level at runtime (protect this!)
app.post('/admin/log-level', authMiddleware, (req, res) => {
  const { level } = req.body;
  if (['fatal', 'error', 'warn', 'info', 'debug', 'trace'].includes(level)) {
    logger.level = level;
    res.json({ success: true, level });
  } else {
    res.status(400).json({ error: 'Invalid log level' });
  }
});
```
