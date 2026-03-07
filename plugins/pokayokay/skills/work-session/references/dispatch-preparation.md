# Dispatch Preparation

Guide for the coordinator to prepare and dispatch subagents.

## Dispatch Flow

```
GET TASK ──► BRAINSTORM? ──► IMPLEMENTER ──► SPEC REVIEW ──► QUALITY REVIEW ──► DONE
 (ohno)      (if ambiguous)    (TDD)         (adversarial)    (code quality)
```

## Step 1: Extract Task Details from ohno

**Primary Tool: `get_task(task_id)`** — returns id, title, description, status, task_type, priority, estimate_hours, story_id, acceptance_criteria, context_summary, handoff_notes, dependencies.

**Supporting Tools:**

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `get_next_task()` | Get recommended task | When coordinator picks work |
| `get_task(id)` | Get specific task | When task ID already known |
| `get_task_dependencies(id)` | Check blockers | Before dispatching |
| `get_session_context()` | Previous session state | For handoff context |

### Required Fields for Dispatch

| Field | Template Variable | Required |
|-------|-------------------|----------|
| `id` | `{TASK_ID}` | Yes |
| `title` | `{TASK_TITLE}` | Yes |
| `description` | `{TASK_DESCRIPTION}` | Yes |
| `acceptance_criteria` | `{ACCEPTANCE_CRITERIA}` | Yes* |
| `context_summary` | `{CONTEXT}` | No |
| `handoff_notes` | `{CONTEXT}` (append) | No |

*If missing, coordinator should define before dispatch.

### Building Context

Assemble context from: (1) story context if task belongs to story, (2) task's own context_summary, (3) handoff_notes from previous sessions, (4) dependency context.

## Step 2: Brainstorm Gate (Conditional)

**Agent**: `yokay-brainstormer` | **Template**: `agents/templates/brainstorm-prompt.md`

### Trigger Conditions

Brainstorm is needed when ANY of these are true:
- Description < 100 chars
- No acceptance criteria
- **AC quality check fails** (see below)
- Task type is spike
- Contains ambiguous keywords: "investigate", "explore", "figure out", "look into", "research"

Skip brainstorm when ALL of these are true:
- `--skip-brainstorm` flag set, OR task type is bug or chore
- AC present AND passes quality check

### AC Quality Check

Even when AC exists, check quality before dispatching. **Route through brainstorm if ANY criterion fails these checks:**

| Check | Fail Example | Pass Example |
|-------|-------------|-------------|
| Too vague (< 5 words) | "Settings work" | "User can update display name via settings form" |
| No verb | "Error handling" | "API returns 400 with validation errors for invalid input" |
| Not testable | "Should be fast" | "Page loads in < 2s with 1000 items" |
| Duplicate of title | "Implement auth" (title: "Implement auth") | "POST /auth/login returns JWT with 1h expiry" |
| All criteria identical pattern | 3x "Feature works correctly" | Distinct conditions per criterion |

**Quick heuristic**: If you could write a test from the criterion text alone, it passes. If you'd need to guess what to test, it fails.

### Processing Result

- **Refined**: Update ohno with refined description/AC, proceed to implementation
- **Needs Input**: PAUSE for human to answer brainstormer's questions

## Step 3: Determine Relevant Skill

Check in order:
1. **Explicit skill hint** — task or story may specify
2. **Task type mapping** — see quick reference below
3. **Keyword analysis** — parse title/description

| task_type | Primary Skill | Secondary |
|-----------|---------------|-----------|
| feature | *(use keywords)* | testing-strategy |
| bug | error-handling | testing-strategy |
| spike | spike | deep-research |
| docs | documentation | -- |
| security | security-audit | -- |
| performance | performance-optimization | -- |
| backend | api-design | api-integration |
| database | database-design | -- |
| devops | ci-cd | -- |

Include the SKILL.md content in `{RELEVANT_SKILL}`. If no skill matches, proceed without specialization.

## Step 4: Fill the Implementer Prompt Template

**Template**: `plugins/pokayokay/agents/templates/implementer-prompt.md`

| Variable | Source |
|----------|--------|
| `{TASK_ID}` | `task.id` |
| `{TASK_TITLE}` | `task.title` |
| `{TASK_DESCRIPTION}` | `task.description` |
| `{ACCEPTANCE_CRITERIA}` | Structured AC (MUST/SHOULD/COULD format) |
| `{CONTEXT}` | Assembled from story/handoff/deps |
| `{RELEVANT_SKILL}` | Skill name and guidance |
| `{WORKING_DIRECTORY}` | Project root path |

### Acceptance Criteria

Extract `## Acceptance Criteria` from task description. Preserve MUST/SHOULD/COULD tags — implementer uses these for AC-first TDD. If missing, either generate basic MUST criteria or route through brainstorm gate.

## Step 5: Dispatch

| Parameter | Value |
|-----------|-------|
| `subagent_type` | `pokayokay:yokay-implementer` |
| `prompt` | Filled implementer-prompt.md content |
| `mode` | `bypassPermissions` |

## Pre-Dispatch Checklist

- Task retrieved from ohno
- Description present (or coordinator defined one)
- Acceptance criteria defined **AND pass quality check**
- Each MUST criterion is specific enough to write a test from
- Context assembled
- Skill determined
- Template fully populated
- Dependencies resolved (task unblocked)

**STOP if AC quality check fails.** Route through brainstorm gate to refine, or refine AC yourself before dispatching. Dispatching with vague AC wastes an entire implementer cycle.
