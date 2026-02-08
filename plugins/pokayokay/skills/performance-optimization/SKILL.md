---
name: performance-optimization
description: Use when analyzing performance issues, optimizing slow pages or APIs, setting up load testing (k6, Artillery), implementing caching, reducing bundle sizes, establishing performance budgets, or profiling bottlenecks. Covers frontend (Core Web Vitals, rendering, bundle size) and backend (query optimization, caching, async patterns) optimization.
---

# Performance Optimization

Systematic approach to identifying and fixing performance bottlenecks.

## Key Principles

- **Measure first** — Never optimize without data; establish baseline metrics
- **Identify bottleneck type** — Network, CPU, memory, I/O, or rendering
- **One change at a time** — Apply targeted fix, re-measure, compare against baseline
- **Quick wins first** — Check compression, caching, indexes, N+1 queries before deep optimization

## Core Web Vitals Targets

| Metric | Good | Poor |
|--------|------|------|
| LCP (Largest Contentful Paint) | < 2.5s | > 4.0s |
| INP (Interaction to Next Paint) | < 200ms | > 500ms |
| CLS (Cumulative Layout Shift) | < 0.1 | > 0.25 |

## Quick Start Checklist

1. Measure baseline (Lighthouse, RUM data, or APM)
2. Identify bottleneck type: network, CPU, memory, I/O, or rendering
3. Check quick wins: compression, caching headers, indexes, N+1 queries
4. Read relevant reference for deep optimization
5. Apply fix, re-measure, validate improvement
6. Set performance budgets and enforce in CI

## References

| Reference | Description |
|-----------|-------------|
| [frontend-perf.md](references/frontend-perf.md) | Bundle analysis, rendering, Core Web Vitals |
| [backend-perf.md](references/backend-perf.md) | Query optimization, caching, async patterns |
| [load-testing.md](references/load-testing.md) | k6, Artillery patterns, CI integration |
| [profiling-guide.md](references/profiling-guide.md) | Chrome DevTools, Node profiling, flame graphs |
