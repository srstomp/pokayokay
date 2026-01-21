# Subagent Dispatch Reference

Guide for the coordinator to prepare and dispatch implementer subagents.

## Overview

The coordinator delegates task implementation to subagents. This reference covers:

1. Extracting task details from ohno
2. Formatting context for the subagent
3. Filling the implementer prompt template
4. Error handling when ohno fails

```
┌─────────────────────────────────────────────────────────────┐
│                    DISPATCH FLOW                            │
│                                                             │
│   ┌──────────┐     ┌──────────┐     ┌──────────┐          │
│   │  GET     │ ──► │  FILL    │ ──► │ DISPATCH │          │
│   │  TASK    │     │ TEMPLATE │     │ SUBAGENT │          │
│   └──────────┘     └──────────┘     └──────────┘          │
│        │                │                │                 │
│        ▼                ▼                ▼                 │
│    ohno MCP         Populate        Task tool with        │
│    get_task()       template        yokay-implementer     │
│                     variables       agent type            │
└─────────────────────────────────────────────────────────────┘
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

## Step 2: Determine Relevant Skill

Route the task to an appropriate skill based on characteristics.

### Routing Decision

Check these in order:

1. **Explicit skill hint** - Task or story may specify a skill
2. **Task type mapping** - Use task_type field
3. **Keyword analysis** - Parse title/description for patterns

See [skill-routing.md](skill-routing.md) for complete routing rules.

### Quick Reference

| task_type | Skill |
|-----------|-------|
| frontend | aesthetic-ui-designer |
| backend | api-design |
| qa | api-testing |
| design | ux-design |
| database | architecture-review |

### Format for Template

```markdown
**Recommended Skill**: aesthetic-ui-designer

This skill provides patterns for:
- Component architecture
- Responsive design
- Accessibility considerations
- Design system integration
```

If no skill matches, use:

```markdown
**Recommended Skill**: None (use Claude's general capabilities)

No specialized skill applies to this task. Use Claude's built-in knowledge for implementation.
```

---

## Step 3: Fill the Implementer Prompt Template

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
| `{ACCEPTANCE_CRITERIA}` | `task.acceptance_criteria` or coordinator-defined | Bullet list |
| `{CONTEXT}` | Built from multiple sources | Story + handoff + deps |
| `{RELEVANT_SKILL}` | Routing decision | Skill name and guidance |
| `{WORKING_DIRECTORY}` | Project root | `/path/to/project` |

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

aesthetic-ui-designer

This skill provides patterns for component architecture, responsive design, and design system integration.

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

## Step 4: Dispatch the Subagent

### Using the Task Tool

Dispatch using the Task tool with `yokay-implementer` agent type:

```markdown
## Dispatching Implementer

**Task**: task-abc123 - Create grid component
**Agent**: yokay-implementer
**Skill**: aesthetic-ui-designer

[Invoke Task tool with filled template]
```

### Task Tool Parameters

| Parameter | Value |
|-----------|-------|
| `agent_type` | `yokay-implementer` |
| `prompt` | Filled implementer-prompt.md content |

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

4. **Proceed without ohno** - If completely unavailable
   ```markdown
   ## Working Without ohno

   ohno is unavailable. Proceeding with manual context.

   **Task** (from coordinator notes):
   - ID: task-abc123
   - Title: Create grid component
   - Description: [as remembered/documented]

   Will sync to ohno when available.
   ```

### When Task Data is Incomplete

**Missing description:**
```markdown
## Incomplete Task Data

Task task-abc123 has no description.

**Options:**
1. Ask human for description
2. Infer from title and context
3. Block task pending clarification

Requesting human input...
```

**Missing acceptance criteria:**
```markdown
## Missing Acceptance Criteria

Task has no defined acceptance criteria.

**Coordinator action**: Define criteria before dispatch:

### Acceptance Criteria (Coordinator-Defined)

- [ ] Implementation matches task title/description
- [ ] Code follows existing patterns
- [ ] Tests verify core functionality
- [ ] No regressions introduced

Proceeding with these criteria...
```

### When Skill Routing Fails

**No matching skill:**
```markdown
## No Skill Match

Task type "devops" has no mapped skill.

**Proceeding with**: Claude's general capabilities

The implementer will use built-in knowledge without specialized skill loading.
```

**Skill file not found:**
```markdown
## Skill Not Available

Skill "aesthetic-ui-designer" not found at expected path.

**Recovery:**
1. Check skill installation
2. Use alternative skill if available
3. Proceed without skill specialization

Proceeding without skill...
```

### When Subagent Dispatch Fails

**Task tool unavailable:**
```markdown
## Cannot Dispatch Subagent

Task tool not available in this environment.

**Fallback**: Coordinator will implement directly.

Switching to direct implementation mode...
```

**Subagent returns error:**
```markdown
## Subagent Error

Implementer returned an error:
[Error details]

**Recovery:**
1. Analyze error cause
2. Fix prerequisites if needed
3. Re-dispatch with corrections

[Take appropriate action]
```

---

## Complete Dispatch Example

### Coordinator Workflow

```markdown
## Preparing Subagent Dispatch

### 1. Getting Task from ohno

Calling get_task("task-abc123")...

Result:
- ID: task-abc123
- Title: Create grid component
- Description: Build responsive grid...
- Status: todo
- Story: Dashboard Layout

### 2. Routing to Skill

Task type: frontend
Keyword match: "component", "grid"
Selected skill: aesthetic-ui-designer

### 3. Building Context

Story context: Dashboard Layout - Building core layout components
Handoff notes: Header complete, grid is next
Dependencies: None (unblocked)

### 4. Filling Template

[Template populated with all variables]

### 5. Dispatching

Agent: yokay-implementer
Prompt: [filled template content]

[Invoke Task tool]

### 6. Awaiting Result

Waiting for implementer to complete...
```

---

## Quick Reference Checklist

Before dispatching a subagent:

```markdown
## Pre-Dispatch Checklist

- [ ] Task retrieved from ohno (get_task)
- [ ] Task has description (or coordinator defined one)
- [ ] Acceptance criteria defined (explicit or default)
- [ ] Context assembled from story/handoff/deps
- [ ] Skill determined via routing
- [ ] Template fully populated (no unfilled variables)
- [ ] Working directory confirmed
- [ ] Dependencies are resolved (task is unblocked)
```
