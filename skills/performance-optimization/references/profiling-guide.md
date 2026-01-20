# Profiling Guide

Chrome DevTools, Node.js profiling, and flame graph analysis.

## Chrome DevTools

### Performance Panel

**Recording a profile:**

1. Open DevTools (F12)
2. Go to Performance tab
3. Click Record (or Ctrl+E)
4. Perform the actions to profile
5. Click Stop
6. Analyze the results

**Key sections to examine:**

| Section | What It Shows | Look For |
|---------|---------------|----------|
| **Summary** | Time breakdown by category | Large Script or Rendering |
| **Main** | Main thread activity | Long tasks (>50ms) |
| **Network** | Request waterfall | Blocking resources |
| **Frames** | Frame rate over time | Drops below 60fps |
| **Timings** | FCP, LCP, etc. | Core Web Vitals |

**Understanding the flame chart:**

```
Task breakdown (top to bottom = call stack):
┌─────────────────────────────────────────────────────────┐
│ Task                                                     │
├─────────────────────────────────────────────────────────┤
│ Function Call                                            │
├───────────────────────┬─────────────────────────────────┤
│ parseHTML             │ evaluateScript                   │
├───────────────────────┼─────────────────────────────────┤
│ recalcStyle           │ layout                           │
└───────────────────────┴─────────────────────────────────┘

Color coding:
- Yellow: Script execution
- Purple: Rendering (style, layout)
- Green: Painting
- Gray: Other (idle, etc.)
```

**Finding long tasks:**

```javascript
// Enable Long Tasks API in code
const observer = new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    console.log('Long task detected:', {
      duration: entry.duration,
      startTime: entry.startTime,
      name: entry.name
    });
  }
});

observer.observe({ type: 'longtask', buffered: true });
```

### Network Panel

**Key columns to enable:**

- Waterfall (visual timing)
- Time (total request time)
- Size (transferred/actual)
- Initiator (what triggered request)

**Timing breakdown:**

```
┌──────────────────────────────────────────────────────────┐
│ DNS Lookup → TCP Connect → SSL → Request → Response      │
├──────────┬───────────┬──────┬─────────┬─────────────────┤
│  10ms    │   15ms    │ 30ms │  5ms    │    200ms        │
└──────────┴───────────┴──────┴─────────┴─────────────────┘

- Queueing: Time waiting to start
- DNS: Domain name resolution
- Connection: TCP handshake
- SSL: TLS negotiation
- Request: Time to send request
- Waiting (TTFB): Server processing
- Content Download: Receiving response
```

**Useful filters:**

```
// Filter by type
is:running           // Currently loading
larger-than:100k     // Large resources
-domain:cdn.com      // Exclude CDN
method:POST          // Only POST requests
status-code:404      // Failed requests
```

### Memory Panel

**Heap snapshot workflow:**

1. Take snapshot before action
2. Perform suspected leaky action
3. Take snapshot after
4. Compare snapshots (Comparison view)

**Finding memory leaks:**

```
Snapshot Comparison:
┌─────────────────────────────────────────────────────────┐
│ Constructor        # New   # Deleted   # Delta   Size   │
├─────────────────────────────────────────────────────────┤
│ Array              1000    500         +500      50KB   │
│ EventListener      200     0           +200      20KB   │
│ HTMLDivElement     150     50          +100      15KB   │
└─────────────────────────────────────────────────────────┘

Focus on:
- Growing # Delta (objects accumulating)
- Large Size delta
- EventListener / closure leaks
```

**Allocation timeline:**

1. Click "Allocation instrumentation on timeline"
2. Record during suspected leak
3. Look for blue bars (allocated, never freed)
4. Click bar to see retained object tree

**Common leak patterns:**

```javascript
// ❌ Forgotten event listeners
element.addEventListener('click', handler);
// Never removed when element is destroyed

// ✅ Cleanup in useEffect
useEffect(() => {
  element.addEventListener('click', handler);
  return () => element.removeEventListener('click', handler);
}, []);

// ❌ Closures holding references
function setup() {
  const largeData = fetchLargeData();
  return function() {
    // largeData is retained forever
    console.log(largeData.length);
  };
}

// ❌ Detached DOM nodes
const elements = [];
function create() {
  const el = document.createElement('div');
  elements.push(el);  // Reference prevents GC
}
```

### Coverage Panel

**Finding unused code:**

1. Open Coverage panel (Ctrl+Shift+P → "Coverage")
2. Click reload to start recording
3. Interact with the page
4. View results

**Reading coverage results:**

```
┌─────────────────────────────────────────────────────────┐
│ URL                    │ Type │ Total │ Unused │ Usage  │
├────────────────────────┼──────┼───────┼────────┼────────┤
│ bundle.js              │ JS   │ 500KB │ 300KB  │ 40%    │
│ styles.css             │ CSS  │ 100KB │ 70KB   │ 30%    │
│ vendor.js              │ JS   │ 200KB │ 180KB  │ 10%    │
└────────────────────────────────────────────────────────┘

Red = unused code
Blue/green = used code
```

### Lighthouse

**Running audit:**

1. Open Lighthouse panel
2. Select categories (Performance, Accessibility, etc.)
3. Choose device (Mobile/Desktop)
4. Click "Analyze page load"

**Key metrics explained:**

| Metric | Good | Needs Work | Poor | Description |
|--------|------|------------|------|-------------|
| FCP | <1.8s | 1.8-3s | >3s | First content visible |
| LCP | <2.5s | 2.5-4s | >4s | Main content visible |
| TBT | <200ms | 200-600ms | >600ms | Main thread blocking |
| CLS | <0.1 | 0.1-0.25 | >0.25 | Visual stability |
| Speed Index | <3.4s | 3.4-5.8s | >5.8s | How quickly content fills |

**Interpreting opportunities:**

```
Opportunity                     Savings
─────────────────────────────────────────
Eliminate render-blocking       2.5s
Properly size images            1.2s
Remove unused CSS               0.8s
Enable text compression         0.5s

Priority:
1. Largest savings first
2. Low effort / high impact
3. Consider implementation cost
```

## Node.js Profiling

### Built-in Profiler

**CPU profiling:**

```bash
# Generate V8 log
node --prof app.js

# Process the log (generates readable output)
node --prof-process isolate-*.log > profile.txt
```

**Interpreting profile output:**

```
[Summary]:
   ticks  total  nonlib   name
    523   52.3%  100.0%  JavaScript
      0    0.0%    0.0%  C++
      0    0.0%    0.0%  GC
    477   47.7%          Shared libraries

[JavaScript]:
   ticks  total  nonlib   name
    312   31.2%   59.7%  LazyCompile: processData /app/data.js:15
    145   14.5%   27.7%  LazyCompile: parseJSON /app/parser.js:42
     66    6.6%   12.6%  LazyCompile: validateInput /app/validate.js:8

Focus on:
- Highest tick counts
- Self time vs. total time
```

### Chrome DevTools for Node

**Start with inspector:**

```bash
# Start with inspector
node --inspect app.js

# Break on first line
node --inspect-brk app.js

# Open chrome://inspect in Chrome
```

**Profiling workflow:**

1. Connect DevTools to Node process
2. Go to Profiler tab
3. Click "Start" to begin CPU profiling
4. Run the operation to profile
5. Click "Stop"
6. Analyze flame chart

### Memory Profiling

**Heap snapshot:**

```javascript
// Programmatic heap snapshot
const v8 = require('v8');
const fs = require('fs');

// Take snapshot
const snapshotFile = `/tmp/heap-${Date.now()}.heapsnapshot`;
const stream = fs.createWriteStream(snapshotFile);
v8.writeHeapSnapshot(snapshotFile);
console.log(`Heap snapshot written to ${snapshotFile}`);

// Load in Chrome DevTools Memory panel
```

**Memory usage tracking:**

```javascript
// Get heap statistics
const v8 = require('v8');

setInterval(() => {
  const stats = v8.getHeapStatistics();
  console.log({
    heapUsed: Math.round(stats.used_heap_size / 1024 / 1024) + 'MB',
    heapTotal: Math.round(stats.total_heap_size / 1024 / 1024) + 'MB',
    external: Math.round(stats.external_memory / 1024 / 1024) + 'MB',
  });
}, 5000);

// Or use process.memoryUsage()
const usage = process.memoryUsage();
console.log({
  rss: Math.round(usage.rss / 1024 / 1024) + 'MB',
  heapTotal: Math.round(usage.heapTotal / 1024 / 1024) + 'MB',
  heapUsed: Math.round(usage.heapUsed / 1024 / 1024) + 'MB',
  external: Math.round(usage.external / 1024 / 1024) + 'MB',
});
```

### Async Hooks for Tracing

```javascript
const async_hooks = require('async_hooks');
const fs = require('fs');

// Track async operations
const asyncOperations = new Map();

const hook = async_hooks.createHook({
  init(asyncId, type, triggerAsyncId) {
    asyncOperations.set(asyncId, {
      type,
      triggerAsyncId,
      startTime: Date.now()
    });
  },
  destroy(asyncId) {
    const op = asyncOperations.get(asyncId);
    if (op) {
      const duration = Date.now() - op.startTime;
      if (duration > 100) {
        fs.writeSync(1, `Slow async ${op.type}: ${duration}ms\n`);
      }
      asyncOperations.delete(asyncId);
    }
  }
});

hook.enable();
```

## Flame Graph Analysis

### Understanding Flame Graphs

```
Reading flame graphs:
┌─────────────────────────────────────────────────────────┐
│                        main()                           │ ← Entry point
├─────────────────────────┬───────────────────────────────┤
│      processData()      │         sendResponse()        │
├───────────┬─────────────┼───────────────────────────────┤
│  parse()  │  validate() │           render()            │
├───────────┼─────────────┼─────────────────┬─────────────┤
│   JSON    │   schema    │    template     │   escape    │
└───────────┴─────────────┴─────────────────┴─────────────┘

Key concepts:
- Width = time spent in function (wider = slower)
- Y-axis = call stack depth (bottom = caller, top = callee)
- Color = usually random or by module
```

### Generating Flame Graphs

**0x (Node.js):**

```bash
# Install
npm install -g 0x

# Generate flame graph
0x app.js

# With specific duration
0x --collect-delay 5000 app.js

# Output: flamegraph.html
```

**clinic.js:**

```bash
# Install
npm install -g clinic

# CPU flame graph
clinic flame -- node app.js

# Doctor (general health)
clinic doctor -- node app.js

# Bubbleprof (async operations)
clinic bubbleprof -- node app.js
```

### Interpreting Flame Graphs

**What to look for:**

```
1. Wide towers = expensive functions
   └─→ Candidate for optimization

2. Plateaus at top = leaf functions
   └─→ Actual work happening here

3. Deep narrow stacks = many function calls
   └─→ Consider inlining or reducing depth

4. Recurring patterns = called frequently
   └─→ Consider caching or batching
```

**Common patterns:**

```
Pattern: Wide JSON.parse
┌─────────────────────────────────────────────────────────┐
│                    handleRequest                         │
├─────────────────────────────────────────────────────────┤
│                     JSON.parse                           │
└─────────────────────────────────────────────────────────┘
Fix: Stream parsing, smaller payloads, avoid re-parsing

Pattern: Regex backtracking
┌─────────────────────────────────────────────────────────┐
│                     validateInput                        │
├─────────────────────────────────────────────────────────┤
│                    RegExp.exec                           │
└─────────────────────────────────────────────────────────┘
Fix: Optimize regex, use non-backtracking patterns

Pattern: Garbage collection spikes
┌─────────────────────────────────────────────────────────┐
│                        main                              │
├──────────┬──────────────────────────────────────────────┤
│    GC    │                  work                         │
└──────────┴──────────────────────────────────────────────┘
Fix: Reduce allocations, object pooling
```

## Application Performance Monitoring (APM)

### DataDog APM

```javascript
// Initialize tracing
const tracer = require('dd-trace').init({
  service: 'my-service',
  env: process.env.NODE_ENV,
  version: process.env.APP_VERSION,
});

// Manual spans
const span = tracer.startSpan('my.custom.operation');
try {
  await doWork();
} finally {
  span.finish();
}

// Add tags
span.setTag('user.id', userId);
span.setTag('order.total', orderTotal);
```

### New Relic

```javascript
// newrelic.js config
exports.config = {
  app_name: ['My Application'],
  license_key: process.env.NEW_RELIC_LICENSE_KEY,
  logging: {
    level: 'info'
  },
  allow_all_headers: true,
  attributes: {
    exclude: ['request.headers.cookie']
  }
};

// Custom instrumentation
const newrelic = require('newrelic');

newrelic.startSegment('myCustomOperation', true, async function() {
  await doWork();
});

// Add custom attributes
newrelic.addCustomAttribute('orderId', orderId);
```

### OpenTelemetry

```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');

const sdk = new NodeSDK({
  traceExporter: new OTLPTraceExporter({
    url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT,
  }),
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': { enabled: false },
    }),
  ],
});

sdk.start();

// Manual spans
const { trace } = require('@opentelemetry/api');
const tracer = trace.getTracer('my-service');

const span = tracer.startSpan('processOrder');
span.setAttribute('order.id', orderId);
try {
  await processOrder();
} finally {
  span.end();
}
```

## Quick Reference

### When to Use Which Tool

| Scenario | Tool |
|----------|------|
| Page load performance | Lighthouse, Performance panel |
| JavaScript execution time | Performance panel, flame graphs |
| Memory leaks | Memory panel (heap snapshots) |
| Unused code | Coverage panel |
| Network bottlenecks | Network panel |
| Node.js CPU profiling | --inspect, 0x, clinic |
| Node.js memory issues | heap snapshots, --inspect |
| Production monitoring | APM (DataDog, New Relic, etc.) |

### Performance Checklist

```
□ Profile before optimizing (measure first)
□ Focus on the biggest bottleneck
□ Make one change at a time
□ Re-measure after each change
□ Document baseline and improvements
□ Set up monitoring for regression detection
```
