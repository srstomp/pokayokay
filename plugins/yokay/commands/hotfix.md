---
description: Urgent production fix with expedited workflow
argument-hint: <incident-description>
---

# Hotfix Workflow

Production incident: `$ARGUMENTS`

## Hotfix Philosophy

1. **Mitigate first**: Stop the bleeding before fixing root cause
2. **Communicate**: Keep stakeholders informed
3. **Fix safely**: Avoid making things worse
4. **Learn**: Postmortem prevents recurrence

## Steps

### 1. Triage Severity

| Severity | Impact | Response |
|----------|--------|----------|
| P0 | Service down, data loss | Drop everything |
| P1 | Major feature broken | Urgent, today |
| P2 | Minor issue, workaround exists | Soon, this week |

### 2. Create Hotfix Task
```bash
npx @stevestomp/ohno-cli create "HOTFIX: $ARGUMENTS" -t bug -p P0
npx @stevestomp/ohno-cli start <task-id>
```

### 3. Investigate Impact
- Who/what is affected?
- When did it start?
- Is it getting worse?
- What changed recently?

### 4. Mitigate (if possible)
Quick actions to reduce impact:
- [ ] Feature flag disable
- [ ] Rollback deployment
- [ ] Scale up resources
- [ ] Database fix
- [ ] Redirect/workaround

Document mitigation taken:
```markdown
## Mitigation Applied
[What was done to reduce impact]
```

### 5. Root Cause Analysis
Quick investigation:
- What changed recently?
- What's in the error logs?
- Can we reproduce in staging?

### 6. Implement Fix
- Create hotfix branch: `git checkout -b hotfix/[issue]`
- Minimal change to fix issue
- Test thoroughly before merge
- Commit: `fix: [HOTFIX] [description]`

### 7. Deploy Fix
- Follow deployment procedures
- Monitor after deploy
- Verify fix in production

### 8. Complete Task
```bash
npx @stevestomp/ohno-cli done <task-id> --notes "Mitigated: X. Fixed: Y. Deployed: Z"
```

### 9. Postmortem (Recommended)
Create `.claude/postmortems/[date]-[slug].md`:

```markdown
# Postmortem: [Incident Title]

**Date**: [date]
**Duration**: [start] - [resolved]
**Severity**: [P0/P1/P2]
**Impact**: [description]

## Timeline
- [time]: Incident detected
- [time]: Investigation started
- [time]: Mitigation applied
- [time]: Root cause identified
- [time]: Fix deployed
- [time]: Incident resolved

## Root Cause
[What caused the incident]

## Resolution
[How it was fixed]

## Lessons Learned
- [Lesson 1]
- [Lesson 2]

## Action Items
- [ ] [Preventive measure 1]
- [ ] [Preventive measure 2]
```

## Output

```markdown
## Hotfix Complete

**Incident**: [description]
**Severity**: [P0/P1/P2]
**Duration**: [time to resolution]
**Status**: Resolved

### Timeline
- [time]: Detected
- [time]: Mitigated
- [time]: Fixed

### Fix
[Summary of changes]

### Postmortem
[Link or "Pending"]
```

## Related Commands

- `/pokayokay:fix` - Non-urgent bug fixes
- `/pokayokay:work` - Resume normal work
- `/pokayokay:review` - Analyze incident patterns

## Examples

```
/pokayokay:hotfix Users can't login - 500 error on auth endpoint
/pokayokay:hotfix Payment processing failing for Stripe webhook
/pokayokay:hotfix Database connection pool exhausted
```

## Checklist

Before deploying hotfix:
- [ ] Root cause identified
- [ ] Fix tested locally
- [ ] Fix tested in staging (if time permits)
- [ ] Rollback plan ready
- [ ] Monitoring in place
