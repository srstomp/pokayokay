# Handoff Guide

## Handoff vs Review

| Aspect | Handoff | Review |
|--------|---------|--------|
| Purpose | Document state for next session | Extract lessons from this session |
| Timing | End of session (always) | End of session (optional) |
| Output | ohno handoff notes | Review report with patterns |
| Audience | Next agent/session | Current user for improvement |

Handoff optionally triggers review before finalizing (see `/pokayokay:handoff` Step 5).

## State Documentation Templates

### Completed Work

```markdown
### Completed
- [task-id]: [brief description] ([skill used])
```

### In-Progress Work

```markdown
### In Progress
- [task-id]: [what's done, what remains]
  - Files changed: [list]
  - Current blocker: [if any]
  - Estimated remaining: [rough]
```

### Decisions Made

```markdown
### Decisions
- [decision]: [rationale] — affects [what]
```

Decisions are critical handoff context. The next session can't re-derive decisions without wasting tokens.

## Skill Usage Tracking

Track which skills were used to help the next session route work efficiently:

```markdown
### Skills Used
| Skill | Tasks | Outcome |
|-------|-------|---------|
| api-design | T001, T003 | Designed user endpoints |
| testing-strategy | T002 | Set up Playwright E2E |

### Skills Recommended But Not Used
- security-audit (auth changes were made)
- observability (new API endpoints lack logging)
```

"Recommended but not used" flags help the next session prioritize missed quality checks.

## Investigation Continuity

### Spikes (Must Complete Within Time-Box)

```markdown
| Spike | Time Used | Time Remaining | Status |
|-------|-----------|----------------|--------|
| Redis caching | 1.5h | 1.5h | Resume next session |
```

Incomplete spikes should be resumed immediately in the next session.

### Deep Research (Multi-Session)

```markdown
| Research | Day | Phase | Next Step |
|----------|-----|-------|-----------|
| Auth providers | 2 of 3 | Analysis | Create comparison matrix |
```

## ohno Integration

### Writing Handoff Notes

Use `set_handoff_notes` MCP tool to persist handoff context:

```
mcp__ohno__set_handoff_notes({
  task_id: "current-task-id",
  notes: "handoff markdown content"
})
```

### Reading Handoff Notes (Next Session)

```
mcp__ohno__get_task_handoff({ task_id: "task-id" })
mcp__ohno__get_session_context()
```

The `/pokayokay:work --continue` command automatically reads handoff notes when resuming.

## Ad-Hoc Work

Track unplanned work that happened outside task scope:

```markdown
| Type | Description | Time | Task Created? |
|------|-------------|------|---------------|
| Bug fix | Fixed login redirect | 20 min | Yes (T045) |
| Refactor | Extracted auth util | 15 min | No |
```

If ad-hoc work exceeds 30 minutes total, create tasks retroactively for tracking.
