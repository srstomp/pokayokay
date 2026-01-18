# Metrics Guide Reference

## Platform Comparison

| Platform | Best For | Pricing Model | Key Feature |
|----------|----------|---------------|-------------|
| **Prometheus** | Self-hosted, k8s native | Free (self-hosted) | PromQL, alerting |
| **Datadog** | Full observability stack | Per host + custom | APM integration |
| **CloudWatch** | AWS native apps | Per metric/alarm | AWS integration |
| **Grafana Cloud** | Prometheus + managed | Free tier available | Visualization |

## Prometheus Setup (Node.js)

### Basic Instrumentation

```typescript
import express from 'express';
import { Registry, Counter, Histogram, Gauge, collectDefaultMetrics } from 'prom-client';

const register = new Registry();

// Collect Node.js metrics (memory, CPU, event loop)
collectDefaultMetrics({ register });

// HTTP request counter
const httpRequestsTotal = new Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

// HTTP request duration histogram
const httpRequestDuration = new Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5, 10],
  registers: [register],
});

// Active connections gauge
const activeConnections = new Gauge({
  name: 'active_connections',
  help: 'Number of active connections',
  registers: [register],
});
```

### Express Middleware

```typescript
function metricsMiddleware(req: Request, res: Response, next: NextFunction) {
  const end = httpRequestDuration.startTimer();
  activeConnections.inc();
  
  res.on('finish', () => {
    const route = req.route?.path || req.path;
    const labels = {
      method: req.method,
      route: route,
      status_code: res.statusCode.toString(),
    };
    
    httpRequestsTotal.inc(labels);
    end(labels);
    activeConnections.dec();
  });
  
  next();
}

// Expose metrics endpoint
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});
```

### Custom Business Metrics

```typescript
// Order processing metrics
const ordersCreated = new Counter({
  name: 'orders_created_total',
  help: 'Total orders created',
  labelNames: ['status', 'payment_method'],
  registers: [register],
});

const orderValue = new Histogram({
  name: 'order_value_dollars',
  help: 'Order value in dollars',
  buckets: [10, 25, 50, 100, 250, 500, 1000],
  registers: [register],
});

const inventoryLevel = new Gauge({
  name: 'inventory_level',
  help: 'Current inventory level',
  labelNames: ['product_id', 'warehouse'],
  registers: [register],
});

// Usage
async function createOrder(order: Order) {
  const result = await db.orders.create(order);
  
  ordersCreated.inc({ 
    status: 'created', 
    payment_method: order.paymentMethod 
  });
  orderValue.observe(order.total);
  
  return result;
}
```

## Datadog Integration

### Node.js Client Setup

```typescript
import tracer from 'dd-trace';
import StatsD from 'hot-shots';

// Initialize tracer
tracer.init({
  service: process.env.DD_SERVICE || 'my-service',
  env: process.env.DD_ENV || 'development',
});

// StatsD client for custom metrics
const dogstatsd = new StatsD({
  host: process.env.DD_AGENT_HOST || 'localhost',
  port: 8125,
  globalTags: {
    env: process.env.DD_ENV || 'development',
    service: process.env.DD_SERVICE || 'my-service',
  },
});

// Custom metric helpers
const metrics = {
  increment: (name: string, tags?: Record<string, string>) => {
    dogstatsd.increment(name, 1, tags);
  },
  
  gauge: (name: string, value: number, tags?: Record<string, string>) => {
    dogstatsd.gauge(name, value, tags);
  },
  
  histogram: (name: string, value: number, tags?: Record<string, string>) => {
    dogstatsd.histogram(name, value, tags);
  },
  
  timing: (name: string, ms: number, tags?: Record<string, string>) => {
    dogstatsd.timing(name, ms, tags);
  },
};

// Usage
metrics.increment('orders.created', { payment_method: 'card' });
metrics.histogram('order.value', 99.99, { currency: 'USD' });
```

### Datadog Metrics Middleware

```typescript
function datadogMiddleware(req: Request, res: Response, next: NextFunction) {
  const start = Date.now();
  
  res.on('finish', () => {
    const duration = Date.now() - start;
    const route = req.route?.path || 'unknown';
    
    const tags = {
      method: req.method,
      route: route,
      status_code: res.statusCode.toString(),
    };
    
    metrics.increment('http.requests', tags);
    metrics.timing('http.request.duration', duration, tags);
    
    if (res.statusCode >= 400) {
      metrics.increment('http.errors', tags);
    }
  });
  
  next();
}
```

## CloudWatch Metrics

### AWS SDK Setup

```typescript
import { CloudWatch } from '@aws-sdk/client-cloudwatch';

const cloudwatch = new CloudWatch({ region: process.env.AWS_REGION });

async function putMetric(
  name: string,
  value: number,
  unit: 'Count' | 'Milliseconds' | 'Bytes' | 'Percent',
  dimensions: Record<string, string> = {}
) {
  await cloudwatch.putMetricData({
    Namespace: process.env.CW_NAMESPACE || 'MyApp',
    MetricData: [
      {
        MetricName: name,
        Value: value,
        Unit: unit,
        Timestamp: new Date(),
        Dimensions: Object.entries(dimensions).map(([Name, Value]) => ({
          Name,
          Value,
        })),
      },
    ],
  });
}

// Batch multiple metrics
async function putMetrics(
  metrics: Array<{
    name: string;
    value: number;
    unit: 'Count' | 'Milliseconds' | 'Bytes' | 'Percent';
    dimensions?: Record<string, string>;
  }>
) {
  await cloudwatch.putMetricData({
    Namespace: process.env.CW_NAMESPACE || 'MyApp',
    MetricData: metrics.map((m) => ({
      MetricName: m.name,
      Value: m.value,
      Unit: m.unit,
      Timestamp: new Date(),
      Dimensions: Object.entries(m.dimensions || {}).map(([Name, Value]) => ({
        Name,
        Value,
      })),
    })),
  });
}
```

### EMF (Embedded Metric Format) for Lambda

```typescript
// CloudWatch Embedded Metric Format for structured logs with metrics
function emfLog(
  metrics: Record<string, number>,
  dimensions: Record<string, string>,
  properties: Record<string, unknown> = {}
) {
  const emf = {
    _aws: {
      Timestamp: Date.now(),
      CloudWatchMetrics: [
        {
          Namespace: process.env.CW_NAMESPACE || 'MyApp',
          Dimensions: [Object.keys(dimensions)],
          Metrics: Object.keys(metrics).map((name) => ({
            Name: name,
            Unit: 'Count',
          })),
        },
      ],
    },
    ...dimensions,
    ...metrics,
    ...properties,
  };
  
  console.log(JSON.stringify(emf));
}

// Usage in Lambda
emfLog(
  { RequestCount: 1, Latency: 45 },
  { Environment: 'prod', FunctionName: 'orderProcessor' },
  { orderId: '123', userId: 'user_456' }
);
```

## Dashboard Patterns

### Essential Dashboard Panels

```yaml
# Dashboard structure for any service
panels:
  row_1_overview:
    - request_rate: rate(http_requests_total[5m])
    - error_rate: rate(http_errors_total[5m]) / rate(http_requests_total[5m])
    - latency_p99: histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))
    - active_connections: active_connections
    
  row_2_latency:
    - latency_heatmap: http_request_duration_seconds_bucket
    - latency_by_route: histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (route, le))
    
  row_3_errors:
    - errors_by_type: sum(rate(http_errors_total[5m])) by (error_type)
    - errors_by_route: sum(rate(http_errors_total[5m])) by (route)
    
  row_4_resources:
    - cpu_usage: process_cpu_seconds_total
    - memory_usage: process_resident_memory_bytes
    - event_loop_lag: nodejs_eventloop_lag_seconds
```

### Grafana Dashboard JSON Structure

```json
{
  "title": "Service Overview",
  "panels": [
    {
      "title": "Request Rate",
      "type": "timeseries",
      "targets": [
        {
          "expr": "sum(rate(http_requests_total[5m])) by (route)",
          "legendFormat": "{{route}}"
        }
      ],
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 0 }
    },
    {
      "title": "Error Rate",
      "type": "gauge",
      "targets": [
        {
          "expr": "sum(rate(http_errors_total[5m])) / sum(rate(http_requests_total[5m])) * 100"
        }
      ],
      "fieldConfig": {
        "defaults": {
          "thresholds": {
            "steps": [
              { "color": "green", "value": 0 },
              { "color": "yellow", "value": 1 },
              { "color": "red", "value": 5 }
            ]
          },
          "unit": "percent"
        }
      },
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 0 }
    }
  ]
}
```

## PromQL Cheat Sheet

### Rate and Increase

```promql
# Requests per second (last 5 minutes)
rate(http_requests_total[5m])

# Total requests in last hour
increase(http_requests_total[1h])

# Instant rate (last two samples)
irate(http_requests_total[5m])
```

### Aggregations

```promql
# Sum across all instances
sum(rate(http_requests_total[5m]))

# Sum by route
sum(rate(http_requests_total[5m])) by (route)

# Average by instance
avg(rate(http_requests_total[5m])) by (instance)

# Top 5 routes by request rate
topk(5, sum(rate(http_requests_total[5m])) by (route))
```

### Histograms and Percentiles

```promql
# P99 latency
histogram_quantile(0.99, rate(http_request_duration_seconds_bucket[5m]))

# P99 latency by route
histogram_quantile(0.99, sum(rate(http_request_duration_seconds_bucket[5m])) by (route, le))

# Apdex score (satisfied < 0.1s, tolerated < 0.4s)
(
  sum(rate(http_request_duration_seconds_bucket{le="0.1"}[5m])) +
  sum(rate(http_request_duration_seconds_bucket{le="0.4"}[5m]))
) / 2 / sum(rate(http_request_duration_seconds_count[5m]))
```

### Error Rates

```promql
# Error percentage
sum(rate(http_requests_total{status_code=~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100

# Availability (success rate)
sum(rate(http_requests_total{status_code!~"5.."}[5m])) / sum(rate(http_requests_total[5m])) * 100
```

## Cardinality Management

### Label Guidelines

```typescript
// ❌ HIGH CARDINALITY - Avoid
const badMetric = new Counter({
  name: 'http_requests_total',
  labelNames: ['user_id', 'request_id', 'session_id'], // Millions of combinations!
});

// ✅ LOW CARDINALITY - Good
const goodMetric = new Counter({
  name: 'http_requests_total',
  labelNames: ['method', 'route', 'status_code'], // < 1000 combinations
});

// ✅ Use bucketed labels for high-cardinality values
function getLatencyBucket(ms: number): string {
  if (ms < 100) return '<100ms';
  if (ms < 500) return '100-500ms';
  if (ms < 1000) return '500ms-1s';
  return '>1s';
}
```

### Cardinality Estimation

```promql
# Count unique label combinations
count(count by (__name__) ({__name__=~".+"}))

# Count unique values for a label
count(count by (route) (http_requests_total))

# Find high-cardinality metrics
topk(10, count by (__name__) ({__name__=~".+"}))
```

## Deployment Markers

### Annotating Deployments

```typescript
// Record deployment marker
async function recordDeployment(version: string, commit: string) {
  // Prometheus: Use a gauge that resets on deploy
  deploymentInfo.set({ version, commit }, 1);
  
  // Datadog: Send event
  dogstatsd.event('deployment', `Deployed ${version}`, {
    tags: [`version:${version}`, `commit:${commit}`],
  });
  
  // CloudWatch: Put annotation
  await cloudwatch.putMetricData({
    Namespace: 'Deployments',
    MetricData: [{
      MetricName: 'DeploymentMarker',
      Value: 1,
      Dimensions: [
        { Name: 'Version', Value: version },
        { Name: 'Commit', Value: commit },
      ],
    }],
  });
}
```

### Version in Metrics

```typescript
const appInfo = new Gauge({
  name: 'app_info',
  help: 'Application info',
  labelNames: ['version', 'commit', 'node_version'],
});

// Set once at startup
appInfo.set(
  {
    version: process.env.APP_VERSION || 'unknown',
    commit: process.env.GIT_COMMIT || 'unknown',
    node_version: process.version,
  },
  1
);
```
