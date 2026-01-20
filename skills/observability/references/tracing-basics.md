# Tracing Basics Reference

## Distributed Tracing Concepts

### Terminology

| Term | Definition |
|------|------------|
| **Trace** | End-to-end journey of a request across services |
| **Span** | Single unit of work with timing (one service call) |
| **Trace ID** | Unique identifier for the entire trace |
| **Span ID** | Unique identifier for a single span |
| **Parent Span ID** | Links child spans to their parent |
| **Context Propagation** | Passing trace context across service boundaries |
| **Sampling** | Deciding which traces to record (for cost/volume) |

### Trace Anatomy

```
Trace ID: abc-123
├── Span 1: API Gateway (trace_id=abc-123, span_id=001, parent=null)
│   ├── duration: 250ms
│   ├── service: api-gateway
│   └── operation: POST /orders
│
├── Span 2: Order Service (trace_id=abc-123, span_id=002, parent=001)
│   ├── duration: 180ms
│   ├── service: order-service
│   └── operation: createOrder
│
├── Span 3: Database (trace_id=abc-123, span_id=003, parent=002)
│   ├── duration: 45ms
│   ├── service: postgres
│   └── operation: INSERT orders
│
└── Span 4: Payment Service (trace_id=abc-123, span_id=004, parent=002)
    ├── duration: 120ms
    ├── service: payment-service
    └── operation: processPayment
```

## OpenTelemetry Setup

### Node.js Auto-Instrumentation

```typescript
// tracing.ts - Must be imported FIRST, before other imports
import { NodeSDK } from '@opentelemetry/sdk-node';
import { getNodeAutoInstrumentations } from '@opentelemetry/auto-instrumentations-node';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

const sdk = new NodeSDK({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: process.env.SERVICE_NAME || 'my-service',
    [SemanticResourceAttributes.SERVICE_VERSION]: process.env.SERVICE_VERSION || '1.0.0',
    [SemanticResourceAttributes.DEPLOYMENT_ENVIRONMENT]: process.env.NODE_ENV || 'development',
  }),
  
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/traces',
  }),
  
  instrumentations: [
    getNodeAutoInstrumentations({
      // Customize which instrumentations to enable
      '@opentelemetry/instrumentation-http': { enabled: true },
      '@opentelemetry/instrumentation-express': { enabled: true },
      '@opentelemetry/instrumentation-pg': { enabled: true },
      '@opentelemetry/instrumentation-redis': { enabled: true },
      '@opentelemetry/instrumentation-mongodb': { enabled: true },
      // Disable noisy instrumentations
      '@opentelemetry/instrumentation-fs': { enabled: false },
    }),
  ],
});

sdk.start();

// Graceful shutdown
process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('Tracing terminated'))
    .catch((error) => console.error('Error terminating tracing', error))
    .finally(() => process.exit(0));
});
```

### Application Entry Point

```typescript
// index.ts
import './tracing'; // MUST be first import
import express from 'express';
import { trace } from '@opentelemetry/api';

const app = express();
const tracer = trace.getTracer('my-service');

app.get('/api/orders/:id', async (req, res) => {
  // Auto-instrumentation creates span for HTTP request
  // Manual spans for custom operations
  const span = tracer.startSpan('fetchOrderDetails');
  
  try {
    const order = await orderService.getById(req.params.id);
    span.setAttributes({
      'order.id': order.id,
      'order.total': order.total,
    });
    res.json(order);
  } catch (error) {
    span.recordException(error as Error);
    span.setStatus({ code: 2, message: (error as Error).message });
    throw error;
  } finally {
    span.end();
  }
});
```

### Manual Span Creation

```typescript
import { trace, SpanKind, SpanStatusCode } from '@opentelemetry/api';

const tracer = trace.getTracer('my-service');

// Simple span
async function processOrder(orderId: string) {
  const span = tracer.startSpan('processOrder', {
    kind: SpanKind.INTERNAL,
    attributes: { 'order.id': orderId },
  });
  
  try {
    const result = await doWork(orderId);
    span.setStatus({ code: SpanStatusCode.OK });
    return result;
  } catch (error) {
    span.setStatus({ 
      code: SpanStatusCode.ERROR, 
      message: (error as Error).message 
    });
    span.recordException(error as Error);
    throw error;
  } finally {
    span.end();
  }
}

// Nested spans with context
async function checkoutFlow(cart: Cart) {
  return tracer.startActiveSpan('checkout', async (parentSpan) => {
    try {
      // Child span 1
      const order = await tracer.startActiveSpan('createOrder', async (span) => {
        const result = await orderService.create(cart);
        span.setAttribute('order.id', result.id);
        span.end();
        return result;
      });
      
      // Child span 2
      await tracer.startActiveSpan('processPayment', async (span) => {
        await paymentService.charge(order.id, cart.total);
        span.end();
      });
      
      // Child span 3
      await tracer.startActiveSpan('sendConfirmation', async (span) => {
        await emailService.sendOrderConfirmation(order);
        span.end();
      });
      
      return order;
    } finally {
      parentSpan.end();
    }
  });
}
```

## Context Propagation

### HTTP Headers (W3C Trace Context)

```typescript
// Outgoing request - context is auto-propagated with instrumentation
// But here's the manual approach:

import { context, propagation, trace } from '@opentelemetry/api';

async function callDownstreamService(url: string, data: unknown) {
  const headers: Record<string, string> = {};
  
  // Inject trace context into headers
  propagation.inject(context.active(), headers);
  
  // headers now contains:
  // traceparent: 00-{trace-id}-{span-id}-{flags}
  // tracestate: (optional vendor-specific data)
  
  return fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...headers,
    },
    body: JSON.stringify(data),
  });
}

// Incoming request - extract context
import { Request, Response, NextFunction } from 'express';

function extractTraceContext(req: Request, res: Response, next: NextFunction) {
  const extractedContext = propagation.extract(context.active(), req.headers);
  
  // Run the rest of the request in this context
  context.with(extractedContext, () => {
    next();
  });
}
```

### Message Queue Propagation

```typescript
// Publishing with trace context
import { context, propagation } from '@opentelemetry/api';

async function publishMessage(queue: string, payload: unknown) {
  const headers: Record<string, string> = {};
  propagation.inject(context.active(), headers);
  
  await rabbitMQ.publish(queue, {
    body: payload,
    properties: {
      headers: headers, // traceparent, tracestate
    },
  });
}

// Consuming with trace context
async function consumeMessage(message: Message) {
  const extractedContext = propagation.extract(
    context.active(),
    message.properties.headers
  );
  
  return context.with(extractedContext, async () => {
    // Processing happens within the extracted trace context
    await processMessage(message.body);
  });
}
```

## Correlation ID Implementation

### Express Middleware

```typescript
import { randomUUID } from 'crypto';
import { Request, Response, NextFunction } from 'express';
import { trace } from '@opentelemetry/api';

declare global {
  namespace Express {
    interface Request {
      correlationId: string;
    }
  }
}

export function correlationMiddleware(req: Request, res: Response, next: NextFunction) {
  // Get from header or generate new
  const correlationId = 
    req.headers['x-correlation-id']?.toString() ||
    req.headers['x-request-id']?.toString() ||
    randomUUID();
  
  req.correlationId = correlationId;
  
  // Set on response for debugging
  res.setHeader('x-correlation-id', correlationId);
  
  // Add to current span
  const span = trace.getActiveSpan();
  if (span) {
    span.setAttribute('correlation.id', correlationId);
  }
  
  next();
}
```

### Propagating to Downstream Services

```typescript
import axios, { AxiosInstance } from 'axios';

function createHttpClient(baseURL: string): AxiosInstance {
  const client = axios.create({ baseURL });
  
  client.interceptors.request.use((config) => {
    // Get correlation ID from current context
    const correlationId = getCurrentCorrelationId();
    
    if (correlationId) {
      config.headers['x-correlation-id'] = correlationId;
    }
    
    return config;
  });
  
  return client;
}

// AsyncLocalStorage for correlation ID
import { AsyncLocalStorage } from 'async_hooks';

const correlationStorage = new AsyncLocalStorage<string>();

export function getCurrentCorrelationId(): string | undefined {
  return correlationStorage.getStore();
}

export function withCorrelationId<T>(id: string, fn: () => T): T {
  return correlationStorage.run(id, fn);
}

// Usage in middleware
app.use((req, res, next) => {
  withCorrelationId(req.correlationId, () => next());
});
```

## Sampling Strategies

### Head-Based Sampling

```typescript
import { TraceIdRatioBasedSampler, AlwaysOnSampler, AlwaysOffSampler, ParentBasedSampler } from '@opentelemetry/sdk-trace-base';

// Sample 10% of traces
const sampler = new TraceIdRatioBasedSampler(0.1);

// Or use parent-based (respect upstream decision)
const parentBasedSampler = new ParentBasedSampler({
  root: new TraceIdRatioBasedSampler(0.1),
  remoteParentSampled: new AlwaysOnSampler(),
  remoteParentNotSampled: new AlwaysOffSampler(),
});

const sdk = new NodeSDK({
  sampler: parentBasedSampler,
  // ... other config
});
```

### Custom Sampling Rules

```typescript
import { Sampler, SamplingDecision, SamplingResult } from '@opentelemetry/sdk-trace-base';
import { Context, Link, SpanKind, Attributes } from '@opentelemetry/api';

class CustomSampler implements Sampler {
  shouldSample(
    context: Context,
    traceId: string,
    spanName: string,
    spanKind: SpanKind,
    attributes: Attributes,
    links: Link[]
  ): SamplingResult {
    // Always sample errors
    if (attributes['http.status_code'] >= 400) {
      return { decision: SamplingDecision.RECORD_AND_SAMPLED };
    }
    
    // Always sample specific endpoints
    if (attributes['http.route'] === '/api/payments') {
      return { decision: SamplingDecision.RECORD_AND_SAMPLED };
    }
    
    // Sample health checks at lower rate
    if (spanName.includes('health')) {
      return Math.random() < 0.01
        ? { decision: SamplingDecision.RECORD_AND_SAMPLED }
        : { decision: SamplingDecision.NOT_RECORD };
    }
    
    // Default 10% sampling
    return Math.random() < 0.1
      ? { decision: SamplingDecision.RECORD_AND_SAMPLED }
      : { decision: SamplingDecision.NOT_RECORD };
  }
  
  toString(): string {
    return 'CustomSampler';
  }
}
```

## Jaeger Setup

### Docker Compose for Local Development

```yaml
version: '3'
services:
  jaeger:
    image: jaegertracing/all-in-one:latest
    ports:
      - "16686:16686"  # UI
      - "4317:4317"    # OTLP gRPC
      - "4318:4318"    # OTLP HTTP
    environment:
      - COLLECTOR_OTLP_ENABLED=true
```

### Connecting to Jaeger

```typescript
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';

const traceExporter = new OTLPTraceExporter({
  url: process.env.JAEGER_ENDPOINT || 'http://localhost:4318/v1/traces',
});
```

## Trace Analysis Patterns

### Finding Slow Spans

```
In Jaeger UI:
1. Search traces with duration > 2s
2. Open trace timeline view
3. Look for:
   - Long spans (the usual suspects)
   - Many sequential spans (should be parallel?)
   - Repeated spans (N+1 query pattern)
```

### Common Anti-Patterns in Traces

```
N+1 Queries:
├── getOrders (5ms)
│   ├── getUser (10ms)  ← repeated
│   ├── getUser (10ms)  ← for each
│   ├── getUser (10ms)  ← order!
│   └── getUser (10ms)

Sequential when Parallel:
├── checkout (500ms)
│   ├── validateCart (100ms)
│   ├── checkInventory (100ms)  ← these could
│   ├── calculateTax (100ms)    ← run in
│   └── reserveItems (100ms)    ← parallel

Missing Spans:
├── apiRequest (1000ms)
│   ├── authenticate (50ms)
│   └── ??? (950ms unaccounted)  ← add spans!
```

### Querying Traces Programmatically

```typescript
// Jaeger Query API
async function findSlowTraces(service: string, minDuration: number) {
  const response = await fetch(
    `${JAEGER_QUERY_URL}/api/traces?` +
    `service=${service}&` +
    `minDuration=${minDuration}ms&` +
    `limit=20`
  );
  return response.json();
}

// Find traces with errors
async function findErrorTraces(service: string) {
  const response = await fetch(
    `${JAEGER_QUERY_URL}/api/traces?` +
    `service=${service}&` +
    `tags=error:true&` +
    `limit=20`
  );
  return response.json();
}
```

## Span Attributes Best Practices

### Semantic Conventions

```typescript
import { SemanticAttributes } from '@opentelemetry/semantic-conventions';

// HTTP spans
span.setAttributes({
  [SemanticAttributes.HTTP_METHOD]: 'POST',
  [SemanticAttributes.HTTP_URL]: 'https://api.example.com/orders',
  [SemanticAttributes.HTTP_STATUS_CODE]: 200,
  [SemanticAttributes.HTTP_ROUTE]: '/api/orders',
});

// Database spans
span.setAttributes({
  [SemanticAttributes.DB_SYSTEM]: 'postgresql',
  [SemanticAttributes.DB_NAME]: 'orders',
  [SemanticAttributes.DB_OPERATION]: 'SELECT',
  [SemanticAttributes.DB_STATEMENT]: 'SELECT * FROM orders WHERE id = $1',
});

// Custom business attributes
span.setAttributes({
  'order.id': orderId,
  'order.total': total,
  'customer.tier': customerTier,
});
```

### What to Include in Spans

```yaml
Always include:
  - Operation name (descriptive)
  - Duration (automatic)
  - Status (success/error)
  - Service name
  - Environment

Include when relevant:
  - User/tenant ID (careful with cardinality)
  - Request IDs
  - Feature flags
  - Version/commit

Never include:
  - PII (passwords, SSN, etc.)
  - Secrets/tokens
  - Large payloads (> 1KB)
  - High-cardinality IDs as attributes (use events instead)
```

## Integration with Logging

### Injecting Trace Context into Logs

```typescript
import { trace, context } from '@opentelemetry/api';
import pino from 'pino';

const logger = pino({
  mixin() {
    const span = trace.getActiveSpan();
    if (span) {
      const spanContext = span.spanContext();
      return {
        trace_id: spanContext.traceId,
        span_id: spanContext.spanId,
        trace_flags: spanContext.traceFlags,
      };
    }
    return {};
  },
});

// Now every log automatically includes trace context
logger.info({ event: 'order_created', orderId: '123' });
// Output: {"level":"info","trace_id":"abc...","span_id":"def...","event":"order_created","orderId":"123"}
```

### Linking Logs to Traces in Grafana

```
# Grafana data source configuration
# In Loki, add derived fields:
{
  "derivedFields": [
    {
      "matcherRegex": "trace_id=([a-f0-9]+)",
      "name": "TraceID",
      "url": "http://jaeger:16686/trace/${__value.raw}",
      "datasourceUid": "jaeger"
    }
  ]
}
```
