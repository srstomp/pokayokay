---
name: plan-revision
description: "Recalculates task dependencies, generates impact analysis diffs, and applies approved changes to epics/stories/tasks in ohno. Use when changing a plan, updating tasks, replanning, modifying scope or priorities, doing what-if analysis, or adjusting the roadmap after requirements change."
---

# Plan Revision

Revise existing plans with full impact visibility.

**Integrates with:**
- `ohno` — Task CRUD, dependencies, activity logging
- `work-session` — Works within session workflow

## Quick Reference

### Explore Mode
1. Load context: MCP `get_session_context()` and `get_task()` for active items.
2. Ask discovery questions (one at a time) to understand the desired change.
3. Surface connections and dependencies via MCP `get_task()` on linked tasks.
4. Propose 2-3 approaches with trade-offs.
5. Converge to concrete changes.
6. Show impact analysis (see format below).
7. **If high-risk flags detected** → require explicit user confirmation; show affected dependents.
8. Execute with approval: MCP `update_task()`, `create_task()`, or `update_task_status()` as needed.

### Direct Mode
1. Load context: MCP `get_session_context()`.
2. Parse user's stated changes.
3. Clarify only if ambiguous.
4. Show impact analysis.
5. **If high-risk flags detected** → require explicit user confirmation.
6. Execute with approval.

## Impact Analysis Format

```
| Task       | Field    | Before         | After          |
|------------|----------|----------------|----------------|
| task-abc   | status   | in_progress    | blocked        |
| task-def   | depends  | [task-abc]     | [task-abc, xy] |

Risk: ⚠ HIGH — task-abc is in progress with 3 dependents
Effort delta: +2 tasks (~8h estimated)
```

## Risk Flags

:warning: **High Risk** (require confirmation before executing):
- Task in progress or review
- Task has logged activity
- Task has 3+ dependents
- Task on critical path

:information_source: **Medium Risk:**
- Dependencies need updating
- Part of partially complete epic

## References

| Reference | Description |
|-----------|-------------|
| [ohno-tools.md](references/ohno-tools.md) | ohno MCP tools used for plan revision |