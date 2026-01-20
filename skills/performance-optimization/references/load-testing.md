# Load Testing

Performance and load testing with k6 and Artillery.

## Load Testing Fundamentals

### Test Types

| Type | Purpose | Duration | Load Pattern |
|------|---------|----------|--------------|
| **Smoke** | Verify basic functionality | 1-2 min | Minimal (1-5 VUs) |
| **Load** | Validate expected traffic | 10-60 min | Target load |
| **Stress** | Find breaking point | 20-60 min | Ramp to failure |
| **Soak** | Find memory leaks, degradation | 1-24 hours | Moderate sustained |
| **Spike** | Handle sudden traffic bursts | 10-30 min | Sharp peaks |

### Key Metrics

```
Response Time Percentiles:
- p50 (median): Typical user experience
- p95: Most users' worst experience
- p99: Edge cases, important for SLOs

Throughput:
- Requests per second (RPS)
- Transactions per second (TPS)

Error Rate:
- % of failed requests
- Error types breakdown

Saturation:
- CPU utilization
- Memory usage
- Connection pool exhaustion
```

## k6 (Grafana)

### Basic Script Structure

```javascript
// load-test.js
import http from 'k6/http';
import { check, sleep } from 'k6';

export const options = {
  // Test stages
  stages: [
    { duration: '2m', target: 100 },  // Ramp up to 100 users
    { duration: '5m', target: 100 },  // Stay at 100 users
    { duration: '2m', target: 0 },    // Ramp down to 0
  ],
  
  // Thresholds (pass/fail criteria)
  thresholds: {
    http_req_duration: ['p(95)<500'],    // 95% under 500ms
    http_req_failed: ['rate<0.01'],      // Error rate < 1%
    http_reqs: ['rate>100'],             // At least 100 RPS
  },
};

export default function () {
  const res = http.get('https://api.example.com/users');
  
  check(res, {
    'status is 200': (r) => r.status === 200,
    'response time OK': (r) => r.timings.duration < 500,
  });
  
  sleep(1);  // Think time between requests
}
```

### Running k6

```bash
# Run locally
k6 run load-test.js

# With more output
k6 run --out json=results.json load-test.js

# Cloud execution
k6 cloud load-test.js

# With environment variables
k6 run -e BASE_URL=https://staging.example.com load-test.js
```

### Common Test Patterns

**API Testing:**

```javascript
import http from 'k6/http';
import { check, group, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'https://api.example.com';

export default function () {
  // Group related requests
  group('User flow', function () {
    // Login
    const loginRes = http.post(`${BASE_URL}/auth/login`, JSON.stringify({
      email: 'test@example.com',
      password: 'password123'
    }), {
      headers: { 'Content-Type': 'application/json' },
    });
    
    check(loginRes, {
      'login successful': (r) => r.status === 200,
      'has token': (r) => r.json('token') !== undefined,
    });
    
    const token = loginRes.json('token');
    
    // Get user profile
    const profileRes = http.get(`${BASE_URL}/users/me`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    
    check(profileRes, {
      'profile retrieved': (r) => r.status === 200,
    });
  });
  
  sleep(1);
}
```

**Stress Test:**

```javascript
export const options = {
  stages: [
    { duration: '2m', target: 100 },   // Ramp to normal load
    { duration: '5m', target: 100 },   // Stay at normal
    { duration: '2m', target: 200 },   // Ramp to 2x
    { duration: '5m', target: 200 },   // Stay at 2x
    { duration: '2m', target: 300 },   // Ramp to 3x
    { duration: '5m', target: 300 },   // Stay at 3x
    { duration: '2m', target: 400 },   // Ramp to 4x
    { duration: '5m', target: 400 },   // Stay at 4x (or until failure)
    { duration: '10m', target: 0 },    // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(99)<1500'],  // Looser for stress test
    http_req_failed: ['rate<0.1'],      // Allow some errors
  },
};
```

**Spike Test:**

```javascript
export const options = {
  stages: [
    { duration: '1m', target: 50 },    // Normal load
    { duration: '10s', target: 500 },  // Spike!
    { duration: '3m', target: 500 },   // Stay at spike
    { duration: '10s', target: 50 },   // Recovery
    { duration: '3m', target: 50 },    // Verify recovery
    { duration: '10s', target: 500 },  // Another spike
    { duration: '3m', target: 500 },   // Stay
    { duration: '1m', target: 0 },     // Ramp down
  ],
};
```

**Soak Test:**

```javascript
export const options = {
  stages: [
    { duration: '5m', target: 100 },   // Ramp up
    { duration: '8h', target: 100 },   // Sustained load
    { duration: '5m', target: 0 },     // Ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<500', 'p(99)<1000'],
    http_req_failed: ['rate<0.01'],
  },
};
```

### Advanced k6 Features

**Custom metrics:**

```javascript
import { Counter, Trend, Rate, Gauge } from 'k6/metrics';

const orderCreated = new Counter('orders_created');
const orderDuration = new Trend('order_creation_duration');
const orderSuccess = new Rate('order_success_rate');
const activeOrders = new Gauge('active_orders');

export default function () {
  const start = Date.now();
  const res = http.post(`${BASE_URL}/orders`, orderData);
  const duration = Date.now() - start;
  
  orderDuration.add(duration);
  
  if (res.status === 201) {
    orderCreated.add(1);
    orderSuccess.add(1);
    activeOrders.add(1);
  } else {
    orderSuccess.add(0);
  }
}
```

**Scenarios (parallel user flows):**

```javascript
export const options = {
  scenarios: {
    // Regular users browsing
    browsers: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '5m', target: 100 },
        { duration: '10m', target: 100 },
      ],
      exec: 'browseProducts',
    },
    // Users making purchases
    buyers: {
      executor: 'constant-arrival-rate',
      rate: 10,               // 10 iterations per second
      timeUnit: '1s',
      duration: '15m',
      preAllocatedVUs: 50,
      exec: 'makePurchase',
    },
    // Admin operations
    admins: {
      executor: 'per-vu-iterations',
      vus: 5,
      iterations: 100,
      exec: 'adminTasks',
    },
  },
};

export function browseProducts() {
  http.get(`${BASE_URL}/products`);
  sleep(2);
}

export function makePurchase() {
  http.post(`${BASE_URL}/orders`, orderData);
}

export function adminTasks() {
  http.get(`${BASE_URL}/admin/reports`);
}
```

**Data parameterization:**

```javascript
import { SharedArray } from 'k6/data';
import papaparse from 'https://jslib.k6.io/papaparse/5.1.1/index.js';

// Load test data once, share across VUs
const users = new SharedArray('users', function () {
  const file = open('./users.csv');
  return papaparse.parse(file, { header: true }).data;
});

export default function () {
  // Pick random user
  const user = users[Math.floor(Math.random() * users.length)];
  
  http.post(`${BASE_URL}/auth/login`, JSON.stringify({
    email: user.email,
    password: user.password
  }));
}
```

## Artillery

### Basic Configuration

```yaml
# load-test.yml
config:
  target: 'https://api.example.com'
  phases:
    - duration: 60
      arrivalRate: 5
      name: "Warm up"
    - duration: 300
      arrivalRate: 20
      name: "Sustained load"
    - duration: 60
      arrivalRate: 5
      name: "Cool down"
  
  # Default headers
  defaults:
    headers:
      Content-Type: 'application/json'
  
  # Plugins
  plugins:
    expect: {}

scenarios:
  - name: "User flow"
    flow:
      - post:
          url: "/auth/login"
          json:
            email: "test@example.com"
            password: "password123"
          capture:
            - json: "$.token"
              as: "authToken"
          expect:
            - statusCode: 200
      
      - get:
          url: "/users/me"
          headers:
            Authorization: "Bearer {{ authToken }}"
          expect:
            - statusCode: 200
      
      - think: 2  # Wait 2 seconds
```

### Running Artillery

```bash
# Run test
artillery run load-test.yml

# With report
artillery run --output report.json load-test.yml
artillery report report.json  # Generate HTML

# Quick test
artillery quick --count 100 -n 10 https://api.example.com/health

# With environment
artillery run -e staging load-test.yml
```

### Artillery Patterns

**Multiple scenarios with weights:**

```yaml
config:
  target: 'https://api.example.com'
  phases:
    - duration: 300
      arrivalRate: 50

scenarios:
  - name: "Browse products"
    weight: 70  # 70% of traffic
    flow:
      - get:
          url: "/products"
      - think: 3
      - get:
          url: "/products/{{ $randomNumber(1, 100) }}"
  
  - name: "Make purchase"
    weight: 20  # 20% of traffic
    flow:
      - post:
          url: "/orders"
          json:
            productId: "{{ $randomNumber(1, 100) }}"
            quantity: 1
  
  - name: "Admin check"
    weight: 10  # 10% of traffic
    flow:
      - get:
          url: "/admin/stats"
```

**CSV data loading:**

```yaml
config:
  target: 'https://api.example.com'
  payload:
    path: "users.csv"
    fields:
      - "email"
      - "password"
    loadAll: true
    skipHeader: true

scenarios:
  - flow:
      - post:
          url: "/auth/login"
          json:
            email: "{{ email }}"
            password: "{{ password }}"
```

**Custom JavaScript functions:**

```javascript
// helpers.js
module.exports = {
  generateOrder: function(context, events, done) {
    context.vars.order = {
      productId: Math.floor(Math.random() * 100) + 1,
      quantity: Math.floor(Math.random() * 5) + 1,
      timestamp: Date.now()
    };
    return done();
  },
  
  logResponse: function(requestParams, response, context, ee, next) {
    console.log(`Response: ${response.statusCode}`);
    return next();
  }
};
```

```yaml
config:
  target: 'https://api.example.com'
  processor: "./helpers.js"

scenarios:
  - flow:
      - function: "generateOrder"
      - post:
          url: "/orders"
          json: "{{ order }}"
          afterResponse: "logResponse"
```

## Test Design Best Practices

### Realistic Load Profiles

```javascript
// Model real traffic patterns
export const options = {
  scenarios: {
    // Morning ramp-up (6am - 9am)
    morning: {
      executor: 'ramping-vus',
      startTime: '0s',
      stages: [
        { duration: '30m', target: 50 },
        { duration: '30m', target: 100 },
        { duration: '30m', target: 150 },
      ],
    },
    // Business hours (9am - 5pm)
    business: {
      executor: 'constant-vus',
      vus: 200,
      duration: '8h',
      startTime: '1h30m',
    },
    // Evening decline (5pm - 10pm)
    evening: {
      executor: 'ramping-vus',
      startTime: '9h30m',
      stages: [
        { duration: '1h', target: 150 },
        { duration: '2h', target: 100 },
        { duration: '2h', target: 50 },
      ],
    },
  },
};
```

### Avoiding Common Mistakes

```javascript
// ❌ Bad: Fixed think time
sleep(5);

// ✅ Good: Variable think time (more realistic)
sleep(Math.random() * 5 + 1);  // 1-6 seconds

// ❌ Bad: Same user data for all VUs
const user = { email: 'test@example.com' };

// ✅ Good: Unique data per VU
const user = users[__VU % users.length];

// ❌ Bad: Ignoring connection reuse
// (k6 handles this automatically, but check custom clients)

// ✅ Good: Use connection pooling
import http from 'k6/http';
// k6 automatically reuses connections
```

### Correlation and Session Handling

```javascript
// Extract dynamic values
const loginRes = http.post(`${BASE_URL}/auth/login`, loginData);
const token = loginRes.json('accessToken');
const sessionId = loginRes.cookies['session-id'][0].value;

// Use in subsequent requests
const headers = {
  Authorization: `Bearer ${token}`,
  Cookie: `session-id=${sessionId}`,
};

http.get(`${BASE_URL}/dashboard`, { headers });
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Load Test

on:
  schedule:
    - cron: '0 2 * * *'  # Daily at 2am
  workflow_dispatch:

jobs:
  load-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Install k6
        run: |
          sudo gpg -k
          sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
          echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
          sudo apt-get update
          sudo apt-get install k6
      
      - name: Run load test
        run: k6 run tests/load-test.js
        env:
          BASE_URL: ${{ secrets.STAGING_URL }}
      
      - name: Upload results
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: k6-results
          path: results.json
```

### Performance Gate

```javascript
// Define strict thresholds for CI
export const options = {
  thresholds: {
    http_req_duration: [
      'p(95)<200',      // 95% under 200ms
      'p(99)<500',      // 99% under 500ms
      'max<2000',       // No request over 2s
    ],
    http_req_failed: ['rate<0.001'],  // Less than 0.1% errors
    checks: ['rate>0.99'],             // 99%+ checks pass
  },
};
```

## Results Analysis

### Key Questions to Answer

```
1. What is the system's capacity?
   - Max RPS before degradation
   - Max concurrent users

2. Where are the bottlenecks?
   - Slowest endpoints
   - Resource saturation points

3. How does it degrade?
   - Gracefully (slowdown) or catastrophically (errors)?
   - Recovery time after overload

4. What are the baseline metrics?
   - Normal p50, p95, p99 latencies
   - Error rate under normal load
```

### Reporting Template

```markdown
## Load Test Report: [Date]

### Test Configuration
- Environment: Staging
- Duration: 30 minutes
- Peak VUs: 200
- Target RPS: 500

### Results Summary

| Metric | Value | Threshold | Status |
|--------|-------|-----------|--------|
| p95 Latency | 180ms | < 200ms | ✅ Pass |
| p99 Latency | 420ms | < 500ms | ✅ Pass |
| Error Rate | 0.05% | < 0.1% | ✅ Pass |
| Max RPS | 520 | > 500 | ✅ Pass |

### Bottlenecks Identified
1. `/api/search` endpoint shows 2x latency under load
2. Database connection pool saturated at 180 VUs

### Recommendations
1. Add index on search table
2. Increase connection pool size from 20 to 50

### Raw Data
[Link to detailed report]
```
