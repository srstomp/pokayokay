---
description: Analyze completed sessions and identify patterns
skill: session-review
---

# Session Review Workflow

Analyze recent work sessions to identify what went well, what went wrong, and patterns to improve.

## Steps

### 1. Get Session History
Use ohno MCP `get_session_context` or:
```bash
npx @stevestomp/ohno-cli context
```

### 2. Review Completed Tasks
```bash
npx @stevestomp/ohno-cli tasks
```

Check for patterns:
- Tasks that took longer than expected
- Tasks that were blocked
- Tasks completed quickly

### 3. Check Git History
```bash
git log --oneline -20
```

Look for:
- Commit frequency and quality
- Reverts or fixes
- Patterns in commit messages

### 4. Identify What Went Well
- Features completed successfully
- Clean implementations
- Good test coverage
- Smooth handoffs

### 5. Identify What Went Wrong
- Blockers encountered
- Tasks that needed rework
- Missing requirements discovered late
- Context loss between sessions

### 6. Extract Patterns
Document recurring issues:
- Common blockers
- Frequent mistake types
- Areas needing more upfront planning

### 6.1 Skill Effectiveness Analysis

#### Skills Used This Session
Review which skills were invoked and their outcomes:

```markdown
| Skill | Times Used | Success Rate | Avg Duration |
|-------|------------|--------------|--------------|
| api-design | 3 | 100% | 45 min |
| testing-strategy | 2 | 50% | 60 min |
| spike | 1 | GO decision | 2.5 hours |
```

#### Spike Outcomes
Track spike decisions and follow-through:

| Spike | Decision | Follow-up Created | Implemented |
|-------|----------|-------------------|-------------|
| D1 Multi-tenant | GO | 3 tasks | 1 of 3 |
| Redis Caching | NO-GO | 0 tasks | N/A |

#### Skill Gaps Identified
Note when work would have benefited from a skill:
- Database migration manually done - would benefit from `database-design`
- CI pipeline created without `ci-cd` - missing caching optimization
- No security review on auth changes - should use `security-audit`

### 6.2 Session Quality Metrics

| Metric | This Session | Trend |
|--------|--------------|-------|
| Tasks completed | 5 | +2 vs avg |
| Tasks blocked | 1 | Same |
| Bugs discovered | 2 | +1 vs avg |
| Spikes completed | 1 | New |
| Skills invoked | 3 | +1 vs avg |
| Commits per task | 1.2 | Same |

### 7. Create Improvement Tasks
For systemic issues, create tasks:
```bash
npx @stevestomp/ohno-cli create "Add pre-commit hook for [issue]" -t chore
```

### 8. Report

```markdown
## Session Review

### Completed
- X tasks completed
- Y features shipped

### What Went Well
- [specific wins]

### What Went Wrong
- [specific issues]

### Patterns Identified
- [recurring themes]

### Recommendations
- [actionable improvements]
```

## Usage
Run periodically (e.g., end of day/week) to maintain quality and improve process.

## Related Commands

- `/pokayokay:work` - Start new session with learnings applied
- `/pokayokay:handoff` - Prepare session handoff
- `/pokayokay:audit` - Check feature completeness
- `/pokayokay:plan` - Incorporate learnings into planning
