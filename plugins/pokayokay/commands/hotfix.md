---
description: Urgent production fix with expedited workflow
argument-hint: <incident-description>
skill: error-handling
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

### 6. Dispatch Agent Pipeline

**Do not implement the fix inline. Hand off to the agent pipeline.**

Read and follow `skills/work-session/references/bug-fix-pipeline.md` with these settings:
- **Mode**: `/hotfix` (max 2 fixer retries, max 1 review cycle, Critical-only quality threshold)
- **Root cause**: from Step 5
- **Impact analysis**: from Step 3
- **Mitigation applied**: from Step 4 (if any)

The pipeline will:
1. Dispatch `yokay-implementer` with hotfix context + mandatory regression test
2. Auto-fix test failures if needed (`yokay-fixer`, max 2 attempts)
3. Verify regression test exists (re-dispatch if missing)
4. Run task review (`yokay-task-reviewer`, Critical-only mode)

**Time pressure handling:**
- Fixer gets 2 attempts (not 3)
- Review cycle limit is 1 — first failure escalates to human immediately
- Review only fails on Critical severity (security, crash, data loss)

**If pipeline PASS**: proceed to Deploy Fix.
**If pipeline FAIL**: task blocked. Review the blocker, then either resolve manually or deploy the mitigation from Step 4 instead.

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
**Pipeline**: Implementer + Fixer([attempts]) + Spec Review + Quality Review (Critical-only)

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
- [ ] Agent pipeline passed (implementer + spec review + quality review)
- [ ] Regression test included
- [ ] Fix tested in staging (if time permits)
- [ ] Rollback plan ready
- [ ] Monitoring in place
