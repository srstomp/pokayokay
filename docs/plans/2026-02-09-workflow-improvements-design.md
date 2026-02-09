# Pokayokay Workflow Improvements

Three improvements based on real-world session review findings.

## Change 1: Route design tasks to /design:* commands in unattended mode

### Problem

Design tasks (task_type: `ux`, `ui`, `persona`, `a11y`) get stuck in unattended mode because the work loop doesn't route them to design plugin commands. They either block the chain or get routed to a generic implementer that doesn't use the design plugin's templates and quality enforcement.

### Solution

In the work loop's task dispatch, detect design task types and route to the corresponding `/design:*` skill:

| task_type | Design Command |
|-----------|---------------|
| `ux` | `/design:ux` |
| `ui` | `/design:ui` |
| `persona` | `/design:persona` |
| `a11y` | `/design:a11y` |

The design plugin commands already generate artifacts autonomously (ux-spec.md, ui-system.md, etc.) with anti-slop quality enforcement and distinctiveness scoring. No human interaction is needed.

### Files to Change

**`plugins/pokayokay/commands/work.md`** - In the task dispatch/skill routing section, add design task type detection before the generic implementer dispatch:

```markdown
### Design Task Routing (Unattended)

Before dispatching to the implementer, check if the task has a design task type:

If task_type is one of: ux, ui, persona, a11y
  AND the design plugin is available:
    → Invoke the corresponding /design:* command
    → Pass the task description and concept doc as context
    → Design artifacts are written to .claude/design/<project>/
    → Mark task complete with artifact paths in handoff notes

If design plugin is NOT available:
    → Route to implementer with instruction to generate design artifacts
      from the concept doc (fallback, lower quality)
```

**`plugins/pokayokay/skills/planning/references/design-integration.md`** - Update the headless section to clarify that design tasks are fully executable, not human-gated:

```markdown
**If `--headless` / unattended is active:**
- Design tasks route to /design:* commands automatically
- Design plugin generates artifacts without human interaction
- Implementation tasks that depend on design tasks unblock when design completes
```

### Scope

~15 lines in work.md, ~5 lines in design-integration.md

---

## Change 2: Test infrastructure auto-detection in batch 1

### Problem

When the planner creates tasks for a new project, test infrastructure setup (Vitest config, test utilities, mock patterns) is created as a regular task alongside component tasks. If implementer agents pick up component tasks before test infra exists, they either skip tests, install duplicate configs, or fail spec review.

### Solution

Add test infrastructure detection to the planner. If the project lacks test infrastructure, create a "Setup test infrastructure" task with highest priority in batch 1, and block all implementation tasks on it.

### Detection Heuristic

Check the project for existing test infrastructure:

```
Has test framework:
  - vitest.config.* OR jest.config.* OR pytest.ini OR .pytest.ini
  - Cargo.toml with [dev-dependencies] containing test framework
  - go.mod (Go has built-in testing)

Has test files:
  - *.test.* OR *.spec.* files exist
  - __tests__/ OR tests/ directories exist

Has test utilities:
  - test/utils.* OR test/helpers.* OR test/setup.*
  - __mocks__/ directory
```

If NONE of the above exist → project needs test infrastructure setup.

### Task Creation

When test infra is missing, the planner creates:

```
Task: "Setup test infrastructure"
  task_type: chore
  priority: P0
  batch: 1 (first batch, before any implementation)
  description: |
    Set up testing framework and utilities for the project:
    - Install and configure test framework (Vitest/Jest/pytest based on stack)
    - Create test utility file with common helpers
    - Create mock patterns for external dependencies
    - Add test script to package.json / Makefile
    - Write one example test to verify the setup works

  All implementation tasks MUST depend on this task.
```

### Files to Change

**`plugins/pokayokay/agents/yokay-planner.md`** - Add instruction to detect test infrastructure:

```markdown
### Test Infrastructure Check

Before creating implementation tasks, check if the project has test infrastructure:
- Look for test config files (vitest.config.*, jest.config.*, pytest.ini, etc.)
- Look for existing test files (*.test.*, *.spec.*, __tests__/, tests/)
- Look for test utilities (test/utils.*, test/helpers.*)

If NO test infrastructure exists:
  1. Create a "Setup test infrastructure" task as the FIRST task in batch 1
  2. Set task_type to "chore" with highest priority
  3. Add dependency: ALL implementation tasks depend on this task
  4. Include in the task description: framework choice, config, utilities, mock patterns
```

**`plugins/pokayokay/skills/planning/references/task-breakdown.md`** - Add batch ordering rule:

```markdown
### Batch Ordering Rules

Batch 1 (infrastructure) MUST include:
- Test infrastructure setup (if project has no existing test framework)
- Database schema/migrations (if applicable)
- Shared utilities and types
- Configuration files

These must complete before batch 2+ (implementation tasks) can start.
```

### Scope

~20 lines in yokay-planner.md, ~15 lines in task-breakdown.md

---

## Change 3: Chain completion audit

### Problem

When a chain completes (all tasks done), `session-chain.sh` generates a report and exits. Individual agents test their own work, spec reviewers check spec compliance, quality reviewers check code quality. But nobody validates the full integration against the original concept doc/PRD.

Result: 12 well-built, well-tested tasks that don't add up to a working feature.

### Solution

When a chain completes, automatically dispatch `yokay-auditor` to run a feature completeness audit against the original concept doc/PRD before declaring the chain done.

### Flow

```
session-chain.sh detects: all tasks done (READY_COUNT == 0)
    │
    ├── Instead of "complete", return "audit_pending"
    │
    ▼
bridge.py handle_session_end() sees "audit_pending"
    │
    ├── Dispatch yokay-auditor with:
    │   - Concept doc / PRD path
    │   - List of completed tasks and their handoffs
    │   - Instruction: "Verify feature completeness against spec"
    │
    ├── Auditor returns PASS or FAIL
    │
    ├── PASS → chain complete, generate report
    │
    └── FAIL →
        ├── unattended: create remediation tasks, continue chain
        └── auto/semi-auto: report gaps, pause for human review
```

### Implementation Details

**`plugins/pokayokay/hooks/actions/session-chain.sh`**

Add a new action type `audit_pending` when all tasks are done but audit hasn't run yet:

```bash
# Check if chain audit has already been done this chain
CHAIN_AUDITED="${CHAIN_AUDITED:-false}"

if [ "$READY_COUNT" -eq 0 ]; then
    if [ "$CHAIN_AUDITED" = "true" ]; then
        ACTION="complete"
    else
        ACTION="audit_pending"
    fi
elif [ "$NEXT_INDEX" -ge "$MAX_CHAINS" ]; then
    ACTION="limit_reached"
else
    ACTION="continue"
fi
```

Add `CHAIN_AUDITED` to the environment and output JSON.

**`plugins/pokayokay/hooks/actions/bridge.py`** `handle_session_end()`

When chain result action is `audit_pending`:

```python
if chain_action == "audit_pending":
    # Don't end the chain yet - signal to coordinator to run audit
    # The coordinator (work.md) handles the actual audit dispatch
    chain_state["audit_pending"] = True
    save_chain_state(chain_state)
```

The coordinator in work.md detects `audit_pending` in chain state and dispatches the auditor before declaring done.

**`plugins/pokayokay/commands/work.md`**

Add chain audit section:

```markdown
### Chain Completion Audit

When all tasks in scope are done, before declaring the chain complete:

1. Read chain state - check for `audit_pending: true`
2. Find the concept doc / PRD for the scope:
   - Epic scope: look in `docs/plans/`, `docs/concepts/`, or epic description
   - Story scope: use story description + parent epic context
   - All scope: use PROJECT.md or the most recent plan document
3. Dispatch yokay-auditor:
   - Input: concept doc + list of completed task handoffs
   - Instruction: "Verify all requirements from the concept doc are implemented"
4. Process result:
   - PASS: mark chain_state.audit_passed = true, chain completes normally
   - FAIL with gaps:
     - Create remediation tasks for each gap
     - In unattended mode: continue chain with new tasks
     - In auto/semi-auto mode: pause and report gaps
```

**`plugins/pokayokay/hooks/actions/bridge.py`** chain state

Add fields to chain state:

```python
chain_state = {
    # ... existing fields ...
    "audit_pending": False,   # True when all tasks done but audit not yet run
    "audit_passed": False,    # True when audit passed
    "audit_gaps": [],         # List of gaps found by auditor
}
```

### Scope

~15 lines in session-chain.sh, ~20 lines in bridge.py, ~30 lines in work.md

---

## Implementation Order

1. **Change 2: Test infra detection** (simplest, isolated to planner)
2. **Change 1: Design task routing** (small, isolated to work.md dispatch)
3. **Change 3: Chain audit** (largest, touches bridge.py + session-chain.sh + work.md)

## Testing

### Change 1
- Run `/plan` on a UI-heavy concept doc → verify design tasks are created
- Run `/work unattended` → verify design tasks route to `/design:*` commands
- Verify design artifacts are produced and task is marked complete

### Change 2
- Run `/plan` on a project with no test files → verify test setup task is batch 1
- Run `/plan` on a project with existing tests → verify no test setup task created
- Run `/work` → verify implementation tasks wait for test setup

### Change 3
- Complete all tasks in a chain → verify auditor runs before chain completion
- Auditor finds gaps → verify remediation tasks are created in unattended mode
- Auditor passes → verify chain completes normally with report
