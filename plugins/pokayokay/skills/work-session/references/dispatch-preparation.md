# Dispatch Preparation

Guide for the coordinator to prepare and dispatch subagents.

> **Runtime note:** Task-tool dispatch is Claude Code-only. On Codex, run each
> stage inline in the current session — read the stage's `agents/yokay-<name>.md`
> and follow its Behavioral Defaults, Critical Rules, and Output Contract. The
> prompt templates and ohno integration in this reference apply on both runtimes.

Use subagents deliberately. They preserve the coordinator's context and can run
in parallel, but each agent does its own model/tool work. For small changes,
prefer `/quick` or inline execution. For broad exploration, prefer the focused
explorer/test-runner agents before using full implementer/reviewer pipelines.
See [token-budgeting.md](token-budgeting.md) for budgeting rules.

## Dispatch Flow

```
GET TASK ──► BRAINSTORM? ──► DESIGN REVIEW? ──► IMPLEMENTER ──► SPEC REVIEW ──► QUALITY REVIEW ──► DONE
 (ohno)      (if ambiguous)  (if non-trivial)  (TDD, w/ approach)  (adversarial)  (quality + design)
```

Reviews are covered in [review-pipeline.md](review-pipeline.md); failure
recovery in [dispatch-errors.md](dispatch-errors.md).

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

- **Refined**: Update ohno with refined description/AC, proceed to the design review gate
- **Needs Input**: PAUSE for human to answer brainstormer's questions

## Step 3: Design Review Gate (Conditional)

Before dispatching the implementer, evaluate if the task needs design review.

**Agent**: `yokay-design-reviewer` | **Template**: `agents/templates/design-review-prompt.md`

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

### Template Variables

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
    # Store approach — it is used TWICE:
    # 1. Fills {APPROACH} in the implementer template (Step 5)
    # 2. Fills {APPROACH} in the quality-review template (design-compliance post-check)
    approach = design_review.output
    proceed_to_implementation(approach=approach)

elif design_review.status == "NEEDS_DISCUSSION":
    add_task_activity(task_id, "note", f"Design review needs discussion: {design_review.decision_needed}")
    if mode in ("supervised", "semi-auto"):
        # PAUSE for human decision, then re-run the gate with the decision in {CONTEXT}
        pause_for_human(design_review.options)
    else:  # auto / unattended — never pause here
        add_task_activity(task_id, "decision",
            "Design review NEEDS_DISCUSSION — proceeding without validated approach")
        proceed_to_implementation(approach=None)  # {APPROACH} gets the skip text
```

When design review is skipped or unresolved, fill `{APPROACH}` with
`Design review skipped — follow codebase patterns` in the implementer template,
and `None — design review was skipped` in the quality-review template. Never
leave the literal `{APPROACH}` placeholder in a dispatched prompt.

### Handling NEEDS_REDESIGN (After Implementer Dispatch)

The implementer reports `NEEDS_REDESIGN` (with evidence) when the pre-validated
approach proves infeasible. Do NOT re-dispatch the implementer against the same
approach, and do NOT treat it as a plain FAIL.

**Cap: ONE redesign cycle per task.**

```python
if implementer.status == "NEEDS_REDESIGN":
    add_task_activity(task_id, "note", f"NEEDS_REDESIGN: {implementer.evidence}")
    if redesign_cycles_used(task_id) >= 1:
        # Second NEEDS_REDESIGN — stop the cycle
        set_blocker(task_id, f"Approach infeasible after one redesign cycle: {implementer.evidence}")
        if mode == "unattended":
            move_to_next_task()
        else:  # supervised / semi-auto / auto
            pause_for_human()
    else:
        # Re-dispatch design reviewer with the evidence appended to {CONTEXT}
        # under a "### Prior Approach Infeasible" heading, then re-dispatch
        # the implementer with the revised approach.
        redesign = dispatch_design_reviewer(task, extra_context=implementer.evidence)
        if redesign.status == "APPROVED":
            proceed_to_implementation(approach=redesign.output)
        else:  # NEEDS_DISCUSSION during redesign — treat as cycle exhausted
            set_blocker(task_id, "Redesign needs human decision")
            pause_or_move_on(mode)
```

### Skip Flag

The `--skip-design` flag bypasses the gate. Proceed directly to implementation
without a validated approach (the implementer chooses its own).

## Step 4: Determine Relevant Skill

Check in order:
1. **Explicit skill hint** — task or story may specify a skill
2. **Task type** — only for non-feature types (bug, spike, docs, test)
3. **Keyword analysis** — parse title/description for domain signals

Route by **content keywords**, not by layer. A vertical slice task touching DB + API + UI should be routed based on the dominant domain, not "backend" or "frontend."

| task_type | Primary Skill | Secondary |
|-----------|---------------|-----------|
| feature | *(use keywords in title/description)* | testing-strategy |
| bug | error-handling | testing-strategy |
| spike | spike | deep-research |
| chore | *(use keywords)* | — |
| test | testing-strategy | — |

**Keyword examples**: "schema" / "migration" → database-design, "endpoint" / "REST" → api-design, "deploy" / "pipeline" → ci-cd, "auth" / "encryption" → security-audit

See [skill-routing.md](skill-routing.md) for keyword-based routing and multi-skill workflows.

Include the SKILL.md pointer in `{RELEVANT_SKILL}` — skill name plus an instruction to read `plugins/pokayokay/skills/<name>/SKILL.md` and load references on demand. If no skill matches, state `None (use Claude's general capabilities)`.

## Step 5: Fill the Implementer Prompt Template

**Template**: `plugins/pokayokay/agents/templates/implementer-prompt.md`

| Variable | Source |
|----------|--------|
| `{TASK_ID}` | `task.id` |
| `{TASK_TITLE}` | `task.title` |
| `{TASK_DESCRIPTION}` | `task.description` |
| `{ACCEPTANCE_CRITERIA}` | Structured AC (MUST/SHOULD/COULD format) |
| `{CONTEXT}` | Assembled from story/handoff/deps |
| `{RELEVANT_SKILL}` | Skill name and guidance |
| `{APPROACH}` | Design review output (Step 3), or `Design review skipped — follow codebase patterns` |
| `{WORKING_DIRECTORY}` | Project root path |

### Acceptance Criteria

Extract `## Acceptance Criteria` from the task description. Preserve MUST/SHOULD/COULD tags — the implementer uses these for AC-first TDD (failing tests for each MUST before coding). If missing, either generate basic MUST criteria or route through the brainstorm gate. The spec reviewer will check each criterion with file:line evidence, so vague or untestable criteria will cause review failures.

## Step 6: Dispatch

| Parameter | Value |
|-----------|-------|
| `subagent_type` | `pokayokay:yokay-implementer` |
| `prompt` | Filled implementer-prompt.md content |
| `mode` | `bypassPermissions` |

After dispatch: wait for completion, receive the report, validate against
acceptance criteria, then proceed to [review-pipeline.md](review-pipeline.md).

## Pre-Dispatch Checklist

- Task retrieved from ohno
- Description present (or coordinator defined one)
- Acceptance criteria defined **AND pass quality check**
- Each MUST criterion is specific enough to write a test from
- Context assembled
- Design review gate evaluated (approach stored, or skip reason known)
- Skill determined
- Template fully populated (no literal `{PLACEHOLDER}` text remains)
- Dependencies resolved (task unblocked)

**STOP if AC quality check fails.** Route through brainstorm gate to refine, or refine AC yourself before dispatching. Dispatching with vague AC wastes an entire implementer cycle.
