# Frontend Performance

Detailed guide to frontend optimization: bundle size, rendering, and Core Web Vitals.

## Bundle Analysis

### Analyzing Bundle Size

**webpack-bundle-analyzer:**

```bash
# Install
npm install -D webpack-bundle-analyzer

# Add to webpack config
const BundleAnalyzerPlugin = require('webpack-bundle-analyzer').BundleAnalyzerPlugin;

module.exports = {
  plugins: [
    new BundleAnalyzerPlugin({
      analyzerMode: 'static',
      reportFilename: 'bundle-report.html',
      openAnalyzer: false
    })
  ]
};

# Or use stats file
webpack --profile --json > stats.json
npx webpack-bundle-analyzer stats.json
```

**source-map-explorer:**

```bash
npm install -D source-map-explorer

# Analyze production build
npx source-map-explorer 'build/static/js/*.js' --html result.html
```

**Next.js bundle analyzer:**

```javascript
// next.config.js
const withBundleAnalyzer = require('@next/bundle-analyzer')({
  enabled: process.env.ANALYZE === 'true',
});

module.exports = withBundleAnalyzer({
  // config
});

// Run: ANALYZE=true npm run build
```

### Common Bundle Bloat Causes

| Library | Typical Size | Alternative |
|---------|--------------|-------------|
| moment.js | ~300KB | date-fns (~40KB tree-shakeable) |
| lodash | ~70KB | lodash-es (tree-shakeable) or native |
| chart.js | ~200KB | lightweight alternatives |
| aws-sdk | ~2.5MB | @aws-sdk/client-* (modular) |

**Tree shaking verification:**

```javascript
// ❌ Imports entire library
import _ from 'lodash';
const result = _.get(obj, 'path');

// ✅ Tree-shakeable import
import { get } from 'lodash-es';
const result = get(obj, 'path');

// Or even better: native
const result = obj?.path;
```

## Code Splitting Strategies

### Route-Based Splitting

**React Router:**

```tsx
import { lazy, Suspense } from 'react';
import { Routes, Route } from 'react-router-dom';

// Lazy load routes
const Home = lazy(() => import('./pages/Home'));
const Dashboard = lazy(() => import('./pages/Dashboard'));
const Settings = lazy(() => import('./pages/Settings'));

function App() {
  return (
    <Suspense fallback={<PageLoader />}>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Suspense>
  );
}
```

**Next.js (automatic):**

```tsx
// pages/dashboard.tsx - automatically code split
export default function Dashboard() {
  return <div>Dashboard</div>;
}

// Dynamic imports for components
import dynamic from 'next/dynamic';

const HeavyComponent = dynamic(() => import('../components/HeavyComponent'), {
  loading: () => <Skeleton />,
  ssr: false  // Disable SSR if client-only
});
```

### Component-Based Splitting

```tsx
// Split heavy libraries
const Chart = lazy(() => 
  import('chart.js').then(chartjs => {
    // Initialize
    return import('./ChartComponent');
  })
);

// Split by user interaction
function Editor() {
  const [showAdvanced, setShowAdvanced] = useState(false);
  
  return (
    <div>
      <BasicEditor />
      {showAdvanced && (
        <Suspense fallback={<Spinner />}>
          <AdvancedFeatures />
        </Suspense>
      )}
    </div>
  );
}
```

### Prefetching Strategies

```tsx
// Prefetch on hover
function NavLink({ to, children }) {
  const prefetch = () => {
    const component = routeComponents[to];
    if (component) {
      component.preload?.();
    }
  };
  
  return (
    <Link to={to} onMouseEnter={prefetch}>
      {children}
    </Link>
  );
}

// Prefetch after initial load
useEffect(() => {
  // Wait for main content
  requestIdleCallback(() => {
    import('./LikelyNextPage');
  });
}, []);
```

## Image Optimization

### Modern Formats

| Format | Use Case | Browser Support |
|--------|----------|-----------------|
| WebP | General use | 97%+ |
| AVIF | Best compression | 90%+ |
| JPEG | Fallback | Universal |
| PNG | Transparency needed | Universal |

**Picture element for format fallback:**

```html
<picture>
  <source srcset="image.avif" type="image/avif">
  <source srcset="image.webp" type="image/webp">
  <img src="image.jpg" alt="Description" width="800" height="600">
</picture>
```

### Responsive Images

```html
<!-- Responsive based on viewport -->
<img
  srcset="
    image-400.jpg 400w,
    image-800.jpg 800w,
    image-1200.jpg 1200w
  "
  sizes="
    (max-width: 600px) 100vw,
    (max-width: 1200px) 50vw,
    800px
  "
  src="image-800.jpg"
  alt="Description"
  width="800"
  height="600"
  loading="lazy"
  decoding="async"
/>
```

### Lazy Loading

```tsx
// Native lazy loading
<img loading="lazy" src="image.jpg" alt="" />

// Intersection Observer for more control
function LazyImage({ src, alt }) {
  const [isLoaded, setIsLoaded] = useState(false);
  const imgRef = useRef();
  
  useEffect(() => {
    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          setIsLoaded(true);
          observer.disconnect();
        }
      },
      { rootMargin: '100px' } // Load 100px before visible
    );
    
    observer.observe(imgRef.current);
    return () => observer.disconnect();
  }, []);
  
  return (
    <img
      ref={imgRef}
      src={isLoaded ? src : placeholder}
      alt={alt}
    />
  );
}
```

### Next.js Image Component

```tsx
import Image from 'next/image';

// Automatic optimization
<Image
  src="/photo.jpg"
  width={800}
  height={600}
  alt="Photo"
  placeholder="blur"
  blurDataURL={blurPlaceholder}
  priority={false}  // true for above-fold
/>

// Fill container
<div style={{ position: 'relative', width: '100%', aspectRatio: '16/9' }}>
  <Image
    src="/photo.jpg"
    fill
    style={{ objectFit: 'cover' }}
    alt="Photo"
  />
</div>
```

## Rendering Optimization

### React Performance Patterns

**Avoiding unnecessary re-renders:**

```tsx
// ❌ Creates new object every render
<Child style={{ color: 'red' }} />

// ✅ Stable reference
const styles = useMemo(() => ({ color: 'red' }), []);
<Child style={styles} />

// ❌ Creates new function every render
<Button onClick={() => handleClick(id)} />

// ✅ Stable callback
const handleClickMemo = useCallback(() => handleClick(id), [id]);
<Button onClick={handleClickMemo} />
```

**List optimization:**

```tsx
// ❌ Missing key or using index
{items.map((item, index) => <Item key={index} {...item} />)}

// ✅ Stable unique key
{items.map(item => <Item key={item.id} {...item} />)}

// Virtualization for long lists
import { FixedSizeList } from 'react-window';

function VirtualList({ items }) {
  return (
    <FixedSizeList
      height={600}
      itemCount={items.length}
      itemSize={50}
      width="100%"
    >
      {({ index, style }) => (
        <div style={style}>{items[index].name}</div>
      )}
    </FixedSizeList>
  );
}
```

### CSS Performance

**GPU-accelerated properties:**

```css
/* ✅ GPU accelerated (compositing only) */
transform: translateX(100px);
opacity: 0.5;
filter: blur(5px);

/* ❌ Triggers layout */
left: 100px;
width: 200px;
height: 200px;

/* ❌ Triggers paint */
background-color: red;
box-shadow: 0 0 10px black;
```

**Will-change (use sparingly):**

```css
/* Only for known animations */
.animated-element {
  will-change: transform;
}

/* Remove after animation */
.animated-element.idle {
  will-change: auto;
}
```

**Contain for isolation:**

```css
/* Isolate layout/paint calculations */
.card {
  contain: layout paint;
}

/* Strictest containment */
.widget {
  contain: strict;
}
```

## Core Web Vitals Deep Dive

### LCP Debugging

```javascript
// Measure LCP programmatically
new PerformanceObserver((list) => {
  const entries = list.getEntries();
  const lastEntry = entries[entries.length - 1];
  console.log('LCP element:', lastEntry.element);
  console.log('LCP time:', lastEntry.startTime);
}).observe({ type: 'largest-contentful-paint', buffered: true });
```

**LCP optimization checklist:**

```
□ Preload LCP image
  <link rel="preload" as="image" href="hero.jpg" fetchpriority="high">

□ Use fetchpriority="high" on LCP image
  <img src="hero.jpg" fetchpriority="high" />

□ Avoid lazy loading LCP element

□ Inline critical CSS for LCP

□ Preconnect to image origins
  <link rel="preconnect" href="https://cdn.example.com">

□ Use responsive images
  srcset with appropriate sizes
```

### INP Debugging

```javascript
// Measure INP
new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (entry.interactionId) {
      console.log('Interaction:', entry.name);
      console.log('Duration:', entry.duration);
      console.log('Processing time:', entry.processingEnd - entry.processingStart);
    }
  }
}).observe({ type: 'event', buffered: true, durationThreshold: 0 });
```

**Long task optimization:**

```javascript
// Break up long tasks
async function processLargeArray(items) {
  const CHUNK_SIZE = 100;
  
  for (let i = 0; i < items.length; i += CHUNK_SIZE) {
    const chunk = items.slice(i, i + CHUNK_SIZE);
    processChunk(chunk);
    
    // Yield to main thread
    await new Promise(resolve => setTimeout(resolve, 0));
  }
}

// Using scheduler API (when available)
async function processWithScheduler(items) {
  for (const item of items) {
    await scheduler.yield();
    processItem(item);
  }
}
```

### CLS Debugging

```javascript
// Identify CLS sources
new PerformanceObserver((list) => {
  for (const entry of list.getEntries()) {
    if (!entry.hadRecentInput) {
      console.log('CLS:', entry.value);
      entry.sources.forEach(source => {
        console.log('Source element:', source.node);
        console.log('Previous rect:', source.previousRect);
        console.log('Current rect:', source.currentRect);
      });
    }
  }
}).observe({ type: 'layout-shift', buffered: true });
```

**CLS prevention patterns:**

```css
/* Reserve space for dynamic content */
.ad-container {
  min-height: 250px;
  aspect-ratio: 300/250;
}

/* Font loading stability */
@font-face {
  font-family: 'CustomFont';
  font-display: swap;
  src: url('font.woff2') format('woff2');
  size-adjust: 100%;
  ascent-override: 90%;
  descent-override: 20%;
}

/* Skeleton placeholders */
.skeleton {
  background: linear-gradient(90deg, #f0f0f0 25%, #e0e0e0 50%, #f0f0f0 75%);
  background-size: 200% 100%;
  animation: shimmer 1.5s infinite;
}
```

## Resource Hints

### Preconnect

```html
<!-- DNS + TCP + TLS handshake ahead of time -->
<link rel="preconnect" href="https://api.example.com">
<link rel="preconnect" href="https://fonts.googleapis.com">

<!-- DNS only (lighter) -->
<link rel="dns-prefetch" href="https://analytics.example.com">
```

### Preload

```html
<!-- Critical resources -->
<link rel="preload" href="/fonts/main.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="/hero.jpg" as="image" fetchpriority="high">
<link rel="preload" href="/critical.css" as="style">

<!-- Module preload -->
<link rel="modulepreload" href="/main.js">
```

### Prefetch

```html
<!-- Next page resources (low priority) -->
<link rel="prefetch" href="/next-page.js">
<link rel="prefetch" href="/next-page-data.json">
```

## Web Workers

**Offloading heavy computation:**

```javascript
// worker.js
self.onmessage = function(e) {
  const result = expensiveComputation(e.data);
  self.postMessage(result);
};

// main.js
const worker = new Worker('worker.js');

worker.onmessage = function(e) {
  displayResult(e.data);
};

worker.postMessage(largeDataSet);
```

**Using Comlink for easier API:**

```javascript
// worker.js
import { expose } from 'comlink';

const api = {
  processData(data) {
    return expensiveComputation(data);
  }
};

expose(api);

// main.js
import { wrap } from 'comlink';

const worker = new Worker(new URL('./worker.js', import.meta.url));
const api = wrap(worker);

const result = await api.processData(data);
```

## Service Worker Caching

**Cache-first strategy for static assets:**

```javascript
// sw.js
const CACHE_NAME = 'static-v1';
const STATIC_ASSETS = [
  '/app.js',
  '/styles.css',
  '/logo.png'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then(cache => cache.addAll(STATIC_ASSETS))
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.destination === 'image' ||
      event.request.destination === 'script' ||
      event.request.destination === 'style') {
    event.respondWith(
      caches.match(event.request)
        .then(cached => cached || fetch(event.request))
    );
  }
});
```

**Stale-while-revalidate for API:**

```javascript
self.addEventListener('fetch', (event) => {
  if (event.request.url.includes('/api/')) {
    event.respondWith(
      caches.open('api-cache').then(async (cache) => {
        const cached = await cache.match(event.request);
        const fetched = fetch(event.request).then(response => {
          cache.put(event.request, response.clone());
          return response;
        });
        return cached || fetched;
      })
    );
  }
});
```

## Performance Monitoring

### Real User Monitoring (RUM)

```javascript
// Collect Core Web Vitals
import { onCLS, onINP, onLCP, onFCP, onTTFB } from 'web-vitals';

function sendToAnalytics({ name, value, id }) {
  fetch('/analytics', {
    method: 'POST',
    body: JSON.stringify({ metric: name, value, id }),
    keepalive: true  // Survives page unload
  });
}

onCLS(sendToAnalytics);
onINP(sendToAnalytics);
onLCP(sendToAnalytics);
onFCP(sendToAnalytics);
onTTFB(sendToAnalytics);
```

### Performance Budget Enforcement

```javascript
// Check at build time
const BUDGETS = {
  js: 200 * 1024,      // 200KB
  css: 50 * 1024,      // 50KB
  images: 500 * 1024,  // 500KB
  total: 1000 * 1024   // 1MB
};

function checkBudgets(stats) {
  const violations = [];
  
  if (stats.js > BUDGETS.js) {
    violations.push(`JS exceeds budget: ${stats.js} > ${BUDGETS.js}`);
  }
  // ... other checks
  
  if (violations.length > 0) {
    throw new Error(`Budget violations:\n${violations.join('\n')}`);
  }
}
```
