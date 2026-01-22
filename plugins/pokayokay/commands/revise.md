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

## Explore Mode

When user is unsure what needs to change.

### 1. Open with Discovery Question

Ask ONE question to start:
```
Looking at your current plan, what's bothering you?

1. **Technical approach** - The tickets assume an approach I disagree with
2. **Scope** - Features need to be added, removed, or changed
3. **Priority/ordering** - Dependencies or priorities are wrong
4. **Something else** - Let me explain...
```

### 2. Drill Down with Follow-up Questions

Based on answer, ask targeted follow-ups:
- One question at a time
- Multiple choice when possible
- Surface connections: "If we change X, ticket Y depends on it"

### 3. Propose 2-3 Approaches

Once you understand the concern:
```markdown
## Approaches

**Option A (Recommended)**: [description]
- Pros: [list]
- Cons: [list]
- Impact: [N tasks affected]

**Option B**: [description]
- Pros: [list]
- Cons: [list]
- Impact: [N tasks affected]

Which approach would you like to explore?
```

### 4. Converge to Concrete Changes

After approach selected, list specific changes:
- Tasks to create
- Tasks to modify
- Tasks to archive
- Dependencies to update

Then proceed to Impact Analysis.

## Direct Mode

When user knows what they want to change.

### 1. Prompt for Changes

```
What changes do you want to make to the plan?

Be specific: "Remove the OAuth feature", "Change API from REST to GraphQL",
"Split the auth epic into two smaller epics"
```

### 2. Parse Intent

From user's response, identify:
- **Additions**: New tasks/features to create
- **Modifications**: Existing tasks to change
- **Removals**: Tasks to archive
- **Reordering**: Dependency changes

### 3. Clarify Ambiguity (if needed)

Only ask if genuinely unclear:
```
You mentioned "remove auth" - did you mean:
1. Remove the entire authentication epic (5 tasks)
2. Remove just the OAuth integration (2 tasks)
3. Something else?
```

### 4. Proceed to Impact Analysis

List the interpreted changes and move directly to impact analysis.

## Impact Analysis

Show what will change before making any modifications.

### Output Format

```markdown
## Impact Analysis

### Proposed Changes

| Action | Task | Current | Proposed | Risk |
|--------|------|---------|----------|------|
| MODIFY | T-012 | REST endpoints | GraphQL schema | :warning: High |
| ARCHIVE | T-015 | Auth middleware | (removed) | :warning: Has 2h work |
| CREATE | (new) | — | GraphQL resolvers | — |
| RELINK | T-018 | Depends on T-015 | Depends on T-NEW | — |

### Risk Assessment

:warning: **High Risk Items:**
- T-012: Core change affects 6 downstream tasks
- T-015: Has logged work that will be discarded

:information_source: **Medium Risk:**
- T-018, T-019: Dependency chain shifts

### Dependency Impact

(Show if complex dependencies affected)

T-010 (Epic: API)
  |-- T-012 [MODIFY] -> affects T-018, T-019
  |-- T-015 [ARCHIVE] -> orphans T-020
  +-- T-NEW [CREATE] -> new dependency for T-018

### Effort Delta

(Show if significant changes)

- Removing: 3 tasks (~6 hours)
- Adding: 2 tasks (~5 hours)
- Net: -1 task, -1 hour
```

### Risk Flagging Rules

Flag as :warning: High Risk when:
- Task has status `in_progress` or `review`
- Task has logged activity/time
- Task has 3+ dependent tasks
- Task is on critical path (blocks many others)

Flag as :information_source: Medium Risk when:
- Task has dependencies that need updating
- Task is part of an epic with completed siblings