---
description: Add logging, metrics, or tracing
argument-hint: <observability-task>
skill: observability
---

# Observability Workflow

Add observability for: `$ARGUMENTS`

## Steps

### 1. Identify Observability Need
From `$ARGUMENTS`, determine:
- **Logging**: Structured logs for debugging
- **Metrics**: Numerical measurements for monitoring
- **Tracing**: Request flow across services
- **Alerting**: Notifications for issues

### 2. Assess Current State
Check existing setup:
- Logging library (Pino, Winston, console)
- Metrics system (Prometheus, DataDog, CloudWatch)
- Tracing (OpenTelemetry, Jaeger)
- Alerting rules

### 3. Design Observability

**For Logging:**
- Define log levels (error, warn, info, debug)
- Structure log format (JSON)
- Add context (request ID, user ID)
- Configure log rotation

**For Metrics:**
- Identify key metrics (latency, throughput, errors)
- Define SLIs/SLOs
- Set up dashboards
- Configure retention

**For Tracing:**
- Instrument entry points
- Propagate context
- Add span attributes
- Configure sampling

**For Alerting:**
- Define alert conditions
- Set thresholds
- Configure notification channels
- Design escalation

### 4. Create Implementation Tasks
```bash
npx @stevestomp/ohno-cli create "Observability: [specific task]" -t chore
```

## Three Pillars Reference

| Pillar | Purpose | Tools |
|--------|---------|-------|
| Logs | Debug, audit | Pino, Winston, Bunyan |
| Metrics | Monitor, alert | Prometheus, StatsD, DataDog |
| Traces | Distributed debug | OpenTelemetry, Jaeger |

## Covers
- Structured logging
- Metric design (counters, gauges, histograms)
- Distributed tracing
- Alert design
- Dashboard creation
- SLI/SLO definition

## Related Commands

- `/pokayokay:cicd` - Pipeline monitoring
- `/pokayokay:work` - Implement observability
- `/pokayokay:security` - Security logging

## Skill Integration

When observability involves:
- **API monitoring** → Also load `api-design` skill
- **Database monitoring** → Also load `database-design` skill
- **Pipeline monitoring** → Also load `ci-cd-expert` skill
