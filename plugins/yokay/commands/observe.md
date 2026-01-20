---
description: Add logging, metrics, or tracing
argument-hint: <observability-task> [--audit]
skill: observability
---

# Observability Workflow

Add observability for: `$ARGUMENTS`

## Mode Detection

Parse `$ARGUMENTS` to determine mode:
- **`--audit` flag present** → Observability gap analysis mode (creates tasks for gaps)
- **No flag** → Design/implement mode (default behavior)

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

## Audit Mode (`--audit` flag)

When `--audit` is specified, switch to observability gap analysis mode:

### Audit Steps

1. **Inventory Current Observability**
Scan codebase for:
- Logging statements and configuration
- Metrics instrumentation
- Tracing setup
- Alerting rules

2. **Map Critical Paths**
Identify components that MUST have observability:
- API endpoints (latency, errors, throughput)
- Database operations (query time, connection pool)
- External service calls (availability, latency)
- Authentication flows (attempts, failures)
- Payment/transaction flows (success rate, failures)

3. **Identify Gaps by Environment**

| Environment | Missing Observability | Priority |
|-------------|----------------------|----------|
| Production | Critical path without alerting | P1 |
| Production | No error tracking on API | P1 |
| Production | Missing latency metrics | P2 |
| Staging/Dev | Missing traces | P3 |
| Any | No structured logging | P2 |

4. **Create Tasks for Gaps**

**Automatically create ohno tasks** using MCP tools for identified gaps:

```
create_task({
  title: "Observability: [what needs coverage]",
  description: "[Gap description]\n\nComponent: [name]\nPillar: [logs/metrics/traces/alerts]\nEnvironment: [prod/staging/dev]\nImpact: [what we can't see without this]",
  task_type: "chore",
  estimate_hours: [1-4 based on scope]
})
```

**Example task creation:**
- No alerting on payment API → `create_task("Observability: Add alerting for payment API errors", type: chore)` P1
- Missing request tracing → `create_task("Observability: Add OpenTelemetry tracing to order service", type: chore)` P2
- No database metrics → `create_task("Observability: Add connection pool and query metrics", type: chore)` P2

5. **Report Summary**
```
Observability Audit Results:

| Pillar | Coverage | Gaps |
|--------|----------|------|
| Logs | [X]% | [N] components |
| Metrics | [X]% | [N] components |
| Traces | [X]% | [N] components |
| Alerts | [X]% | [N] critical paths |

Created [N] observability tasks:
- [task-id]: Observability: [name] (P1/P2/P3)
- ...

Critical blind spots: [list of most important gaps]
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
