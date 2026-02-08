---
name: observability
description: Use when adding logging to services, setting up monitoring, creating alerts, debugging production issues, designing SLIs/SLOs, or implementing structured logging (Pino, Winston), metrics (Prometheus, DataDog, CloudWatch), or distributed tracing (OpenTelemetry).
---

# Observability

Implement the three pillars of observability: logs, metrics, and traces.

## The Three Pillars

| Pillar | Purpose | Key Question |
|--------|---------|--------------|
| **Logs** | Discrete events with context | What happened? |
| **Metrics** | Aggregated measurements | How much/many? |
| **Traces** | Request flow across services | Where did time go? |

## Quick Pick

- Debug specific request? → Logs + Traces
- Alert on thresholds? → Metrics
- Understand system health? → All three
- Starting from zero? → Logs first, then metrics, then traces

## Key Principles

- Use structured logging (JSON) with correlation IDs across all services
- Instrument the four golden signals: latency, traffic, errors, saturation
- Define SLIs/SLOs before building dashboards or alerts
- Alert on symptoms (user impact), not causes (CPU usage)

## Quick Start Checklist

1. Set up structured logger (Pino recommended for Node.js)
2. Add request correlation IDs (middleware)
3. Instrument key metrics (RED: Rate, Errors, Duration)
4. Configure distributed tracing (OpenTelemetry)
5. Create dashboards for golden signals
6. Set up alerts with appropriate severity levels

## References

| Reference | Description |
|-----------|-------------|
| [logging-patterns.md](references/logging-patterns.md) | Structured logging, log levels, Pino/Winston setup |
| [metrics-guide.md](references/metrics-guide.md) | Prometheus, counters/gauges/histograms, golden signals |
| [tracing-basics.md](references/tracing-basics.md) | OpenTelemetry, distributed tracing, span design |
| [alerting-guide.md](references/alerting-guide.md) | Alert design, SLIs/SLOs, severity levels, dashboards |
