# Alerting Guide Reference

## Alert Philosophy

### The Golden Rules

1. **Every page should be actionable** — If you can't do something about it, it shouldn't wake you up
2. **Every alert needs a runbook** — No investigation from scratch at 3am
3. **Alert on symptoms, not causes** — Users care about latency, not CPU spikes
4. **Fewer, better alerts** — Alert fatigue kills response quality

### Alert Categories

| Category | Response | Examples |
|----------|----------|----------|
| **Pages** | Immediate (24/7) | Outage, data loss, security breach |
| **Tickets** | Business hours | Degraded performance, approaching limits |
| **Notifications** | Best effort | Warnings, anomalies, forecasts |

## SLI/SLO Deep Dive

### Common SLI Patterns

```yaml
availability:
  definition: successful_requests / total_requests
  measurement: http_requests_total{status_code!~"5.."}
  typical_target: 99.9%
  
latency:
  definition: requests_under_threshold / total_requests
  measurement: histogram_quantile(0.99, http_request_duration_seconds_bucket)
  typical_target: "p99 < 200ms"
  
throughput:
  definition: successful_operations_per_second
  measurement: rate(operations_total{status="success"}[5m])
  typical_target: "> 1000 ops/sec"
  
freshness:
  definition: time_since_last_update < threshold
  measurement: time() - last_update_timestamp
  typical_target: "< 5 minutes stale"
```

### Error Budget Calculation

```
SLO: 99.9% availability
Period: 30 days

Error Budget = 30 days × (1 - 0.999) = 30 × 0.001 = 43.2 minutes/month

Daily budget: 43.2 / 30 = 1.44 minutes/day
Weekly budget: 43.2 / 4 = 10.8 minutes/week
```

### SLO-Based Alerting

```yaml
# Prometheus alerting rules
groups:
  - name: slo-alerts
    rules:
      # Multi-burn-rate alert for error budget
      - alert: HighErrorBudgetBurn
        expr: |
          (
            # Fast burn (last 1h vs 6h)
            (1 - (sum(rate(http_requests_total{status_code!~"5.."}[1h])) / sum(rate(http_requests_total[1h])))) > (14.4 * (1 - 0.999))
            and
            (1 - (sum(rate(http_requests_total{status_code!~"5.."}[6h])) / sum(rate(http_requests_total[6h])))) > (6 * (1 - 0.999))
          )
          or
          (
            # Slow burn (last 3d vs 1d)
            (1 - (sum(rate(http_requests_total{status_code!~"5.."}[1d])) / sum(rate(http_requests_total[1d])))) > (3 * (1 - 0.999))
            and
            (1 - (sum(rate(http_requests_total{status_code!~"5.."}[3d])) / sum(rate(http_requests_total[3d])))) > (1 * (1 - 0.999))
          )
        for: 2m
        labels:
          severity: page
        annotations:
          summary: "Error budget burning too fast"
          runbook: "https://runbooks.example.com/high-error-rate"
```

## Alert Rule Examples

### Prometheus Alert Rules

```yaml
groups:
  - name: service-alerts
    rules:
      # High error rate
      - alert: HighErrorRate
        expr: |
          sum(rate(http_requests_total{status_code=~"5.."}[5m])) 
          / sum(rate(http_requests_total[5m])) > 0.05
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Error rate above 5%"
          description: "Error rate is {{ $value | humanizePercentage }}"
          runbook: "https://runbooks.example.com/high-error-rate"
          
      # High latency
      - alert: HighLatency
        expr: |
          histogram_quantile(0.99, 
            sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
          ) > 2
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "P99 latency above 2 seconds"
          description: "P99 latency is {{ $value | humanizeDuration }}"
          
      # Service down
      - alert: ServiceDown
        expr: up == 0
        for: 1m
        labels:
          severity: critical
        annotations:
          summary: "Service {{ $labels.job }} is down"
          
      # Low request rate (potential issues)
      - alert: LowTraffic
        expr: |
          sum(rate(http_requests_total[5m])) < 10
          and
          sum(rate(http_requests_total[5m] offset 1h)) > 100
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "Traffic significantly lower than 1 hour ago"
          
      # Disk space
      - alert: DiskSpaceLow
        expr: |
          (node_filesystem_avail_bytes / node_filesystem_size_bytes) * 100 < 10
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Disk space below 10% on {{ $labels.instance }}"
          
      # Memory usage
      - alert: HighMemoryUsage
        expr: |
          (1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100 > 90
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Memory usage above 90%"
```

### Datadog Monitor Configuration

```yaml
# High error rate monitor
- name: "High Error Rate - Production"
  type: metric alert
  query: |
    sum(last_5m):sum:http.requests{status_code:5xx,env:production} 
    / sum:http.requests{env:production} * 100 > 5
  message: |
    ## High Error Rate Alert
    
    Error rate is {{value}}% (threshold: 5%)
    
    **Investigation Steps:**
    1. Check recent deployments
    2. Review error logs
    3. Check dependent services
    
    @slack-engineering @pagerduty-oncall
  options:
    thresholds:
      critical: 5
      warning: 2
    notify_no_data: true
    no_data_timeframe: 10
    require_full_window: true
    include_tags: true
    
# Latency degradation monitor
- name: "P99 Latency Degradation"
  type: metric alert
  query: |
    percentile(last_5m):p99:http.request.duration{env:production} > 2
  message: |
    P99 latency is {{value}}s
    
    @slack-engineering
  options:
    thresholds:
      critical: 2
      warning: 1
```

### CloudWatch Alarm

```typescript
import { CloudWatch } from '@aws-sdk/client-cloudwatch';

const cloudwatch = new CloudWatch({ region: 'us-east-1' });

// Create high latency alarm
await cloudwatch.putMetricAlarm({
  AlarmName: 'API-HighLatency',
  AlarmDescription: 'P99 latency above 2 seconds',
  ActionsEnabled: true,
  AlarmActions: [process.env.SNS_TOPIC_ARN],
  MetricName: 'Latency',
  Namespace: 'MyApp',
  Statistic: 'p99',
  Dimensions: [{ Name: 'Environment', Value: 'production' }],
  Period: 300, // 5 minutes
  EvaluationPeriods: 2,
  DatapointsToAlarm: 2,
  Threshold: 2000, // milliseconds
  ComparisonOperator: 'GreaterThanThreshold',
  TreatMissingData: 'notBreaching',
});
```

## Runbook Templates

### Standard Runbook Structure

```markdown
# Alert: [Alert Name]

## Overview
- **Severity:** Critical / Warning
- **Impact:** What users experience
- **SLO:** Which SLO this affects

## Quick Diagnosis
1. Check [dashboard link]
2. Run: `kubectl get pods -n production | grep -v Running`
3. Check recent deployments: `git log --oneline -10`

## Common Causes

### Cause 1: Database Connection Exhaustion
**Symptoms:**
- Connection timeout errors in logs
- Database connections at max

**Resolution:**
1. Check connection pool settings
2. Identify slow queries: `SELECT * FROM pg_stat_activity WHERE state = 'active'`
3. If needed, restart service: `kubectl rollout restart deployment/api`

### Cause 2: Downstream Service Failure
**Symptoms:**
- 503 errors with specific service name
- Circuit breaker open

**Resolution:**
1. Check dependent service status
2. Verify network connectivity
3. Consider enabling fallback mode

### Cause 3: Resource Exhaustion
**Symptoms:**
- OOMKilled pods
- High CPU throttling

**Resolution:**
1. Check resource metrics
2. Scale up if justified: `kubectl scale deployment/api --replicas=5`
3. Investigate memory leak if recurring

## Escalation
- **First responder:** On-call engineer
- **15 min no progress:** Notify team lead
- **30 min no progress:** Page secondary on-call
- **User-facing outage:** Notify @incident-commander

## Post-Incident
- [ ] Update incident timeline
- [ ] Create follow-up tickets
- [ ] Update this runbook if needed
```

### Runbook Automation Snippets

```bash
#!/bin/bash
# Common diagnostic commands for runbooks

# Check recent deployments
echo "=== Recent Deployments ==="
kubectl rollout history deployment/api -n production | tail -5

# Check pod status
echo "=== Pod Status ==="
kubectl get pods -n production -o wide | grep -E "(NAME|api)"

# Check recent errors
echo "=== Recent Errors ==="
kubectl logs -n production -l app=api --tail=100 | jq 'select(.level=="error")' | head -20

# Check resource usage
echo "=== Resource Usage ==="
kubectl top pods -n production -l app=api

# Check dependent services
echo "=== Dependent Services ==="
for svc in db redis cache; do
  kubectl get pods -n production -l app=$svc -o jsonpath='{.items[*].status.phase}' | tr ' ' '\n' | sort | uniq -c
done
```

## Alert Fatigue Prevention

### Alert Tuning Checklist

```markdown
Weekly Alert Review:
- [ ] How many alerts fired this week?
- [ ] How many were actionable?
- [ ] How many were duplicates?
- [ ] How many auto-resolved before investigation?

For each noisy alert:
- [ ] Increase threshold by 20%?
- [ ] Increase `for` duration?
- [ ] Add better filtering?
- [ ] Convert to ticket instead of page?
- [ ] Delete entirely?
```

### Alert Grouping and Deduplication

```yaml
# Alertmanager configuration for grouping
route:
  group_by: ['alertname', 'service']
  group_wait: 30s      # Wait before sending first notification
  group_interval: 5m   # Wait before sending updates
  repeat_interval: 4h  # Wait before repeating
  
  routes:
    # Critical alerts - page immediately
    - match:
        severity: critical
      receiver: pagerduty
      group_wait: 10s
      
    # Warnings - batch and send to Slack
    - match:
        severity: warning
      receiver: slack
      group_wait: 5m
      group_interval: 30m
      
inhibit_rules:
  # Don't alert on service errors if service is down
  - source_match:
      alertname: ServiceDown
    target_match:
      alertname: HighErrorRate
    equal: ['service']
```

### Severity Matrix

| Impact | Urgency | Severity | Response |
|--------|---------|----------|----------|
| User-facing outage | Immediate | P1 Critical | Page 24/7 |
| Degraded performance | Soon | P2 High | Page business hours |
| Single user affected | Normal | P3 Medium | Ticket |
| Potential future issue | Low | P4 Low | Dashboard |

## PagerDuty Integration

### Webhook Configuration

```typescript
import axios from 'axios';

interface PagerDutyEvent {
  routing_key: string;
  event_action: 'trigger' | 'acknowledge' | 'resolve';
  dedup_key: string;
  payload: {
    summary: string;
    severity: 'critical' | 'error' | 'warning' | 'info';
    source: string;
    custom_details?: Record<string, unknown>;
  };
}

async function sendPagerDutyAlert(event: PagerDutyEvent) {
  await axios.post('https://events.pagerduty.com/v2/enqueue', event);
}

// Usage
await sendPagerDutyAlert({
  routing_key: process.env.PAGERDUTY_ROUTING_KEY!,
  event_action: 'trigger',
  dedup_key: `high-error-rate-${Date.now()}`,
  payload: {
    summary: 'Error rate above 5% on production API',
    severity: 'critical',
    source: 'api-production',
    custom_details: {
      error_rate: '7.3%',
      dashboard: 'https://grafana.example.com/d/api-overview',
      runbook: 'https://runbooks.example.com/high-error-rate',
    },
  },
});
```

### Slack Alert Formatting

```typescript
interface SlackAlert {
  channel: string;
  attachments: Array<{
    color: string;
    title: string;
    text: string;
    fields: Array<{ title: string; value: string; short: boolean }>;
    actions?: Array<{ type: string; text: string; url: string }>;
  }>;
}

function formatSlackAlert(
  alertName: string,
  severity: 'critical' | 'warning' | 'info',
  details: Record<string, string>
): SlackAlert {
  const colors = { critical: '#FF0000', warning: '#FFA500', info: '#0000FF' };
  
  return {
    channel: '#alerts',
    attachments: [
      {
        color: colors[severity],
        title: `🚨 ${alertName}`,
        text: details.summary,
        fields: Object.entries(details)
          .filter(([k]) => k !== 'summary')
          .map(([title, value]) => ({ title, value, short: true })),
        actions: [
          { type: 'button', text: 'Dashboard', url: details.dashboard },
          { type: 'button', text: 'Runbook', url: details.runbook },
        ],
      },
    ],
  };
}
```

## On-Call Best Practices

### Handoff Checklist

```markdown
## On-Call Handoff

### Current Status
- [ ] All services healthy
- [ ] No active incidents
- [ ] Error budget status: X% remaining

### Recent Events
- List any incidents from the past shift
- Note any ongoing investigations
- Mention upcoming maintenance windows

### Known Issues
- List any flapping alerts
- Note any expected anomalies
- Document any temporary workarounds in place

### Action Items
- [ ] Review overnight alerts
- [ ] Check dashboard for anomalies
- [ ] Verify backup completion
```

### Incident Response Flow

```
Alert Fires → Acknowledge (5 min) → Diagnose (15 min) → Communicate (ongoing) → Resolve → Post-mortem

Timeline expectations:
- 0-5 min: Acknowledge alert
- 5-15 min: Initial diagnosis
- 15 min: First status update
- 30 min: Escalate if no progress
- Resolution + 24h: Post-mortem scheduled
```
