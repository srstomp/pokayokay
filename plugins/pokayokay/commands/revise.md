---
description: Revise existing plan through guided conversation or directed changes
argument-hint: [--direct]
skill: plan-revision
---

# Plan Revision Workflow

Revise the current plan with impact analysis before making changes.

**Mode**: `$ARGUMENTS` (default: explore)

## Mode Detection

Parse `$ARGUMENTS`:
- `--direct` flag → Direct mode (you know what to change)
- No flag → Explore mode (guided discovery)
- Specific statement without flag → Auto-detect direct mode

If user says something specific like "I want to remove feature X" without `--direct`, treat as direct mode.

## Session Start

### 1. Check for Existing Plan

Use ohno MCP `get_project_status` to check:
- Total task count
- Task breakdown by status

If no tasks exist:
```
No plan found. Use `/pokayokay:plan` first to create tasks.
```
Exit early.

### 2. Load Full Context

Use ohno MCP tools:
```
get_tasks()           → All tasks
get_project_status()  → Summary statistics
```

Build mental model:
- Epics and their stories
- Task dependencies
- Current progress (what's done, in progress, blocked)

### 3. Report Current State

```markdown
## Current Plan

**Status**: X tasks total (Y done, Z in progress)

**Epics**:
- [Epic 1]: N tasks
- [Epic 2]: N tasks

**In Progress**: [list any active work]
**Blocked**: [list any blockers]
```