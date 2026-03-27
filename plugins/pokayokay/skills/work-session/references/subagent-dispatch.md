# Subagent Dispatch Reference

Guide for the coordinator to prepare and dispatch subagents.

## Overview

The coordinator delegates work to subagents at various stages:

1. **Brainstorm** (conditional) - Refines ambiguous tasks before implementation
2. **Design Review** (conditional) - Validates implementation approach before coding
3. **Implementer** - Implements the task following TDD, with pre-validated approach
4. **Spec Reviewer** - Verifies implementation matches spec
5. **Quality Reviewer** - Verifies code quality standards and design compliance

This reference covers:

1. Extracting task details from ohno
2. Brainstorm gate (conditional dispatch)
3. Design review gate (conditional dispatch)
4. Filling the implementer prompt template
5. Two-stage review dispatch (spec + quality with design compliance)
6. Error handling when ohno fails

```
┌──────────────────────────────────────────────────────────────────┐
│                       DISPATCH FLOW                              │
│                                                                  │
│   ┌──────────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐   │
│   │  GET     │──►│BRAINSTORM│──►│  DESIGN  │──►│IMPLEMENTER│   │
│   │  TASK    │   │ (maybe)  │   │  REVIEW  │   │(w/ approach)│  │
│   └──────────┘   └──────────┘   │ (maybe)  │   └──────────┘   │
│        │              │         └──────────┘        │           │
│        ▼              ▼              │               ▼           │
│    ohno MCP      Refine if      Validate        Implement       │
│    get_task()    ambiguous      approach         with TDD        │
│                                                                  │
│                       ┌──────────┐     ┌──────────┐             │
│                       │  SPEC    │ ──► │ QUALITY  │             │
│                       │ REVIEWER │     │ REVIEWER │             │
│                       └──────────┘     └──────────┘             │
│                            │                │                    │
│                            ▼                ▼                    │
│                       Verify spec      Verify quality            │
│                       compliance       + design compliance       │
└──────────────────────────────────────────────────────────────────┘
```

---

## Step 1: Extract Task Details from ohno

### Using MCP Tools

The coordinator retrieves task information using ohno MCP tools.

**Primary Tool: `get_task(task_id)`**

Returns complete task details:

```json
{
  "id": "task-abc123",
  "title": "Create grid component",
  "description": "Build a responsive grid layout...",
  "status": "todo",
  "task_type": "feature",
  "priority": "P1",
  "estimate_hours": 4,
  "story_id": "story-001",
  "acceptance_criteria": "...",
  "context_summary": "Part of dashboard layout...",
  "handoff_notes": "Previous session completed header...",
  "dependencies": []
}
```

**Supporting Tools:**

| Tool | Purpose | When to Use |
|------|---------|-------------|
| `get_next_task()` | Get recommended task | When coordinator picks work |
| `get_task(id)` | Get specific task | When task ID already known |
| `get_task_dependencies(id)` | Check blockers | Before dispatching |
| `get_session_context()` | Previous session state | For handoff context |

### Required Fields for Dispatch

Extract these fields from the task:

| Field | Template Variable | Required |
|-------|-------------------|----------|
| `id` | `{TASK_ID}` | Yes |
| `title` | `{TASK_TITLE}` | Yes |
| `description` | `{TASK_DESCRIPTION}` | Yes |
| `acceptance_criteria` | `{ACCEPTANCE_CRITERIA}` | Yes* |
| `context_summary` | `{CONTEXT}` | No |
| `handoff_notes` | `{CONTEXT}` (append) | No |

*If missing, coordinator should define before dispatch.

### Building Context from Multiple Sources

Context comes from several places:

```python
# Pseudocode for context assembly
def build_context(task):
    context_parts = []

    # 1. Story context (if task belongs to story)
    if task.story_id:
        story = get_story(task.story_id)
        context_parts.append(f"Story: {story.title}")
        context_parts.append(f"Story goal: {story.description}")

    # 2. Task's own context summary
    if task.context_summary:
        context_parts.append(task.context_summary)

    # 3. Handoff notes from previous sessions
    if task.handoff_notes:
        context_parts.append(f"Previous session notes: {task.handoff_notes}")

    # 4. Dependency context
    if task.dependencies:
        dep_context = format_dependencies(task.dependencies)
        context_parts.append(dep_context)

    return "\n\n".join(context_parts)
```

---

## Step 2: Brainstorm Gate (Conditional)

Before dispatching the implementer, evaluate if the task needs brainstorming.

### Trigger Conditions

Check these conditions to determine if brainstorming is needed:

```python
def needs_brainstorm(task, skip_flag=False):
    """
    Returns (needs_brainstorm: bool, reason: str | None)
    """
    # Skip conditions (check first)
    if skip_flag:
        return False, None
    if task.task_type in ["bug", "chore"]:
        return False, None

    # Well-specified check
    well_specified = (
        len(task.description or "") >= 100 and
        task.acceptance_criteria and
        not has_ambiguous_keywords(task)
    )
    if well_specified:
        return False, None

    # Trigger conditions
    if len(task.description or "") < 100:
        return True, "Short description (< 100 chars)"
    if not task.acceptance_criteria:
        return True, "No acceptance criteria"
    if task.task_type == "spike":
        return True, "Spike investigation required"
    if has_ambiguous_keywords(task):
        return True, "Ambiguous scope keywords"

    return False, None

def has_ambiguous_keywords(task):
    """Check for keywords indicating unclear scope."""
    ambiguous = ["investigate", "explore", "figure out", "look into", "research"]
    text = f"{task.title} {task.description}".lower()
    return any(kw in text for kw in ambiguous)
```

### Brainstorm Dispatch

**Agent**: `yokay-brainstormer`
**Template**: `agents/templates/brainstorm-prompt.md`
**Model**: sonnet (needs reasoning capability)

#### Template Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `{TASK_ID}` | `task.id` | Task identifier |
| `{TASK_TITLE}` | `task.title` | Task title |
| `{TASK_TYPE}` | `task.task_type` | feature/bug/spike/etc |
| `{TASK_DESCRIPTION}` | `task.description` | Current description |
| `{ACCEPTANCE_CRITERIA}` | `task.acceptance_criteria` | Current criteria (may be empty) |
| `{TRIGGER_REASON}` | From needs_brainstorm() | Why brainstorm triggered |
| `{WORKING_DIRECTORY}` | Project root | Working directory path |

#### Dispatch Example

```markdown
## Dispatching Brainstormer

**Task**: task-abc123 - Improve performance
**Trigger**: Short description (< 100 chars)
**Agent**: yokay-brainstormer

Refining requirements before implementation...

[Invoke Task tool with filled brainstorm-prompt.md]
```

### Processing Brainstorm Result

```python
# Pseudocode
if brainstorm.status == "Refined":
    # Update ohno with refined requirements
    update_task(task_id, {
        "description": brainstorm.refined_description,
        # Note: acceptance_criteria may need separate field or append to description
    })

    # Log activity
    add_task_activity(task_id, "note", "Brainstorm: Requirements refined")

    # Proceed to implementer dispatch
    proceed_to_implementation()

elif brainstorm.status == "Needs Input":
    # PAUSE for human to answer questions
    log_activity(task_id, "note", f"Brainstorm: Needs input - {brainstorm.questions}")
    pause_for_human(brainstorm.open_questions)
```

### Skip Flag

The `--skip-brainstorm` flag bypasses the gate:

```markdown
## Skip Brainstorm

User specified --skip-brainstorm flag.
Proceeding directly to implementation.

*Warning: Task may have ambiguous requirements.*
```

---

## Step 3: Design Review Gate (Conditional)

Before dispatching the implementer, evaluate if the task needs design review.

### Skip Conditions

Design review is NOT needed when:

```python
def skip_design_review(task, skip_flag=False):
    if skip_flag:
        return True  # --skip-design flag
    if task.task_type in ["chore", "docs"]:
        return True  # Low design risk
    ac_count = count_acceptance_criteria(task)
    if ac_count < 3 and estimated_files_touched(task) <= 1:
        return True  # Trivial change
    return False
```

### Design Review Dispatch

**Agent**: `yokay-design-reviewer`
**Template**: `agents/templates/design-review-prompt.md`
**Model**: sonnet (needs design reasoning)

#### Template Variables

| Variable | Source | Description |
|----------|--------|-------------|
| `{TASK_ID}` | `task.id` | Task identifier |
| `{TASK_TITLE}` | `task.title` | Task title |
| `{TASK_DESCRIPTION}` | `task.description` | Full description |
| `{ACCEPTANCE_CRITERIA}` | `task.acceptance_criteria` | Structured AC |
| `{CONTEXT}` | Built from story + handoff + deps | Where this fits |
| `{WORKING_DIRECTORY}` | Project root | Working directory path |

### Processing Design Review Result

```python
if design_review.status == "APPROVED":
    # Store approach for implementer dispatch
    approach = design_review.output
    # Proceed to implementer with {APPROACH} filled
    proceed_to_implementation(approach=approach)

elif design_review.status == "NEEDS_DISCUSSION":
    # PAUSE for human decision
    log_activity(task_id, "note", f"Design review needs discussion: {design_review.decision_needed}")
    pause_for_human(design_review.options)
```

### Skip Flag

The `--skip-design` flag bypasses the gate:

```markdown
## Skip Design Review

User specified --skip-design flag.
Proceeding directly to implementation without validated approach.

*Warning: Implementer will choose its own approach.*
```

---

## Step 4: Determine Relevant Skill

Route the task to an appropriate skill based on characteristics.

### Routing Decision

Check these in order:

1. **Explicit skill hint** — Task or story may specify a skill
2. **Task type** — Only for non-feature types (bug, spike, docs, test)
3. **Keyword analysis** — Parse title/description for domain signals

Route by **content keywords**, not by layer. A vertical slice task touching DB + API + UI should be routed based on the dominant domain, not "backend" or "frontend."

See [skill-routing.md](skill-routing.md) for complete routing rules.

### Quick Reference

| task_type | Primary Skill | Secondary |
|-----------|---------------|-----------|
| feature | *(use keywords in title/description)* | testing-strategy |
| bug | error-handling | testing-strategy |
| spike | spike | deep-research |
| chore | *(use keywords)* | — |
| test | testing-strategy | — |

**Keyword examples**: "schema" / "migration" → database-design, "endpoint" / "REST" → api-design, "deploy" / "pipeline" → ci-cd, "auth" / "encryption" → security-audit

See [skill-routing.md](skill-routing.md) for keyword-based routing and multi-skill workflows

### Format for Template

Include the SKILL.md content (now ~50 lines) in the `{RELEVANT_SKILL}` template variable. The agent will see the reference table and can load specific references on-demand.

```markdown
**Recommended Skill**: api-design

Read `plugins/pokayokay/skills/api-design/SKILL.md` for key principles, checklist, and reference index.
Load reference files from `references/` only when you need deeper guidance.
```

If no skill matches, use:

```markdown
**Recommended Skill**: None (use Claude's general capabilities)

No specialized skill applies to this task. Use Claude's built-in knowledge for implementation.
```

---

## Step 5: Fill the Implementer Prompt Template

### Template Location

```
plugins/pokayokay/agents/templates/implementer-prompt.md
```

### Template Variables

| Variable | Source | Example |
|----------|--------|---------|
| `{TASK_ID}` | `task.id` | `task-abc123` |
| `{TASK_TITLE}` | `task.title` | `Create grid component` |
| `{TASK_DESCRIPTION}` | `task.description` | Full description text |
| `{ACCEPTANCE_CRITERIA}` | Structured AC from task description (see below) | MUST/SHOULD/COULD list |
| `{CONTEXT}` | Built from multiple sources | Story + handoff + deps |
| `{RELEVANT_SKILL}` | Routing decision | Skill name and guidance |
| `{APPROACH}` | Design review output (Step 3) | Validated implementation approach, or empty if skipped |
| `{WORKING_DIRECTORY}` | Project root | `/path/to/project` |

### Acceptance Criteria in Dispatch

The planner produces structured AC in `[MUST/type] criterion` format within task
descriptions. When filling `{ACCEPTANCE_CRITERIA}`:

1. **Extract** the `## Acceptance Criteria` section from the ohno task description
2. **Preserve** the MUST/SHOULD/COULD tags and type annotations — the implementer
   uses these to drive AC-first TDD (failing tests for each MUST before coding)
3. **If missing** (legacy tasks without structured AC), the coordinator should either:
   - Generate basic MUST criteria from the description before dispatching
   - Route the task through brainstorm gate to add AC first

The spec reviewer will check each criterion with file:line evidence, so vague or
untestable criteria will cause review failures. Better to refine AC upfront.

### Filling the Template

**Example Input:**

```json
{
  "id": "task-abc123",
  "title": "Create grid component",
  "description": "Build a responsive grid layout component that supports 1-4 column configurations. Should use CSS Grid and integrate with existing design system.",
  "acceptance_criteria": "- Renders without errors\n- Supports cols={1|2|3|4} prop\n- Responsive breakpoints (sm, md, lg)\n- Exported from components/index.ts",
  "story_id": "story-001",
  "context_summary": "Part of dashboard layout work. Header component already complete.",
  "handoff_notes": "Previous session set up the component structure. Tests are pending."
}
```

**Example Output (filled template):**

```markdown
# Task Implementation Assignment

You are being dispatched by the coordinator to implement a specific task...

---

## Task Information

**Task ID**: task-abc123
**Title**: Create grid component

### Description

Build a responsive grid layout component that supports 1-4 column configurations. Should use CSS Grid and integrate with existing design system.

### Acceptance Criteria

- Renders without errors
- Supports cols={1|2|3|4} prop
- Responsive breakpoints (sm, md, lg)
- Exported from components/index.ts

---

## Context

### Where This Fits

**Story**: Dashboard Layout

Part of dashboard layout work. Header component already complete.

Previous session notes: Previous session set up the component structure. Tests are pending.

### Recommended Skill

api-design

This skill provides patterns for API design, request/response schemas, and error handling.

---

## Working Environment

**Working Directory**: /Users/dev/projects/my-app

...
```

### Acceptance Criteria Best Practices

If `acceptance_criteria` is empty or vague, coordinator should define:

```markdown
### Acceptance Criteria

- [ ] Component renders without console errors
- [ ] All props documented with TypeScript types
- [ ] Unit tests cover happy path and edge cases
- [ ] Exported from appropriate index file
- [ ] Follows existing code patterns in codebase
```

---

## Step 6: Dispatch the Subagent

### Using the Task Tool

Dispatch using the Task tool with `yokay-implementer` agent type:

```markdown
## Dispatching Implementer

**Task**: task-abc123 - Create grid component
**Agent**: yokay-implementer
**Skill**: api-design

[Invoke Task tool with filled template]
```

### Task Tool Parameters

| Parameter | Value |
|-----------|-------|
| `subagent_type` | `pokayokay:yokay-implementer` |
| `prompt` | Filled implementer-prompt.md content |
| `mode` | `bypassPermissions` |

### After Dispatch

The coordinator should:

1. Wait for subagent completion
2. Receive implementation report
3. Validate against acceptance criteria
4. Update task status in ohno
5. Proceed to next task or checkpoint

---

## Error Handling

### When ohno MCP Fails

**Symptom**: MCP tool call returns error or times out.

**Recovery Steps:**

1. **Retry once** - Transient failures are common
   ```
   First attempt failed. Retrying get_task()...
   ```

2. **Check MCP connection** - Verify ohno server is running
   ```markdown
   ## ohno Connection Issue

   Unable to reach ohno MCP server.

   **Possible causes:**
   - ohno server not running
   - MCP configuration incorrect
   - Network/socket issue

   **Recovery:**
   1. Check: `npx @stevestomp/ohno-cli status`
   2. Restart if needed: `npx @stevestomp/ohno-cli serve`
   3. Retry task operation

   Waiting for resolution...
   ```

3. **Use CLI fallback** - If MCP unavailable, use shell commands
   ```bash
   # Get task via CLI
   npx @stevestomp/ohno-cli task task-abc123
   ```

