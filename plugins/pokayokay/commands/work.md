---
description: Start or continue orchestrated work session
argument-hint: [supervised|semi-auto|autonomous] [--parallel N]
skill: project-harness
---

# Work Session Workflow

Start or continue a development session with configurable human control.

**Mode**: `$ARGUMENTS` (default: supervised)
**Parallel**: Extract `--parallel N` or `-p N` from arguments (default: 1, max: 5)

## Argument Parsing

Parse `$ARGUMENTS` to extract:
1. **Mode**: First word if it matches supervised|semi-auto|autonomous, else "supervised"
2. **Parallel count**: Value after `--parallel` or `-p` flag, default 1, max 5

Example arguments:
- `semi-auto --parallel 3` → mode=semi-auto, parallel=3
- `-p 2` → mode=supervised, parallel=2
- `autonomous` → mode=autonomous, parallel=1

## Session Start

### 1. Get Session Context
Use ohno MCP `get_session_context` to understand:
- Previous session notes
- Current blockers
- In-progress tasks

### 2. Read Project Context
If `.claude/PROJECT.md` exists, read it for:
- Project overview
- Tech stack
- Conventions

### 3. Get Next Task
```bash
npx @stevestomp/ohno-cli next
```
Or use ohno MCP `get_next_task`.

## Parallel State Tracking

When running with `--parallel N` where N > 1:

### State Variables

Track these during the work loop:
- **active_agents**: Map of {task_id: agent_status} for in-flight implementers
- **queued_tasks**: List of task IDs ready to dispatch
- **completed_this_batch**: List of task IDs completed since last checkpoint
- **failed_blocked**: List of task IDs that failed or got blocked

### Filling the Queue

1. Call `get_tasks(status="todo")` to get available tasks
2. Filter out tasks where `blockedBy` contains any task NOT in "done" status
3. Filter out tasks where `blockedBy` contains any task in `active_agents`
4. Add up to N tasks to `queued_tasks`

### Invariant

At any time: `len(active_agents) + len(queued_tasks) <= N`

### 4. Start the Task
```bash
npx @stevestomp/ohno-cli start <task-id>
```

## Work Loop

### Sequential Mode (parallel=1)

For each task:

1. **Get next task**: `get_next_task()` from ohno
2. **Understand the task**: Read task details via `get_task()`
3. **Route to skill** (if needed): Based on task type
4. **Brainstorm gate** (conditional): See Brainstorm Gate section
5. **Dispatch implementer**: Single Task tool call
6. **Browser verification** (conditional): See Browser Verification section
7. **Two-stage review**: Spec review → Quality review
8. **Complete task**: Mark done, trigger hooks
9. **Checkpoint**: Based on mode

### Parallel Mode (parallel > 1)

Coordinator maintains N concurrent implementers:

#### Initial Dispatch

1. **Fill queue**: Get up to N tasks that are:
   - Status = "todo"
   - No unmet `blockedBy` dependencies
   - Not blocked by another task in active_agents

2. **Parallel dispatch**: Send SINGLE message with N Task tool calls:
   ```
   Task tool (yokay-implementer):
     description: "Implement: {task1.title}"
     prompt: [template for task1]

   Task tool (yokay-implementer):
     description: "Implement: {task2.title}"
     prompt: [template for task2]

   ... up to N tasks
   ```

3. **Track state**: Add all dispatched tasks to `active_agents`

#### Processing Results

As each agent returns:

1. **Remove from active_agents**
2. **Run review pipeline** (sequential for this task):
   - Spec review
   - Quality review (if spec passes)
3. **Handle result**:
   - PASS: Add to `completed_this_batch`, attempt commit
   - FAIL: Re-dispatch or add to `failed_blocked`
4. **Refill**: If `len(active_agents) < N` and queue not empty:
   - Dispatch next task from queue
   - Replenish queue from ohno if needed

#### Commit Handling

Each task commits independently when its review passes:
- Git conflicts at commit time → try rebase once
- If rebase fails → flag task, continue with others

#### Checkpoint Behavior

| Mode | Sequential | Parallel |
|------|------------|----------|
| supervised | After each task | After each task completes |
| semi-auto | Log & continue | Log & continue |
| autonomous | Skip | Skip |

Story/epic boundaries still trigger pauses per mode settings.

## Git Conflict Handling (Parallel Mode)

When multiple agents complete around the same time, git conflicts may occur at commit.

### Detection

After implementer completes and reviews pass, the commit hook runs. If commit fails:

1. Check if failure is a merge conflict (exit code + stderr contains "conflict")
2. If yes, attempt resolution
3. If no, report error and continue

### Resolution Strategy

```
1. Run: git fetch origin && git rebase origin/$(git branch --show-current)
2. If rebase succeeds:
   - Run: git add -A && git rebase --continue
   - Commit should now succeed
3. If rebase fails (complex conflict):
   - Run: git rebase --abort
   - Flag task: "Git conflict - needs manual resolution"
   - Add to failed_blocked list
   - Continue with other tasks
```

### Reporting

At checkpoint, report conflict status:

```markdown
## Parallel Batch Status

✓ task-001: completed, committed
✓ task-002: completed, committed
⚠️ task-003: completed, git conflict (flagged for manual resolution)
⟳ task-004: implementing...

Continue? [y/n/resolve task-003]
```

### User Options

- **y**: Continue with remaining tasks
- **n**: Stop session
- **resolve task-XXX**: Pause to manually resolve conflict, then continue

---

## Work Loop Details

The following sections provide detailed implementation guidance for each step:

### 1. Understand the Task
Read task details via ohno MCP `get_task`.

### 2. Route to Skill (if needed)

Based on task type, determine relevant skill for domain knowledge:

**Design & UX**:
- UI work → Load `aesthetic-ui-designer` skill
- UX decisions → Load `ux-design` skill
- User research → Load `persona-creation` skill
- Accessibility → Load `accessibility-auditor` skill

**Backend & API**:
- API work → Load `api-design` skill
- Database work → Load `database-design` skill
- Architecture work → Load `architecture-review` skill
- Third-party integration → Load `api-integration` skill

**DevOps & Infrastructure**:
- CI/CD work → Load `ci-cd-expert` skill
- Observability work → Load `observability` skill

**Quality & Security**:
- Testing work → Load `testing-strategy` skill
- Security work → Load `security-audit` skill

**Investigation**:
- Spike tasks → Load `spike` skill (enforce time-box)
- Research tasks → Load `deep-research` skill

### 3. Brainstorm Gate (Conditional)

Before dispatching the implementer, check if the task needs brainstorming.

#### Trigger Conditions

Brainstorm triggers when ANY of these are true:

| Condition | Check | Rationale |
|-----------|-------|-----------|
| Short description | `len(description) < 100 chars` | Likely underspecified |
| No acceptance criteria | `acceptance_criteria is empty` | No clear success definition |
| Spike type | `task_type == "spike"` | Investigation required |
| Ambiguous keywords | Contains "investigate", "explore", "figure out" | Unclear scope |

#### Skip Conditions

Brainstorm is skipped when ANY of these are true:

| Condition | Check | Rationale |
|-----------|-------|-----------|
| Bug type | `task_type == "bug"` | Usually well-defined |
| Chore type | `task_type == "chore"` | Usually mechanical |
| Well-specified | Has description AND criteria AND no ambiguous keywords | Ready to implement |
| Manual skip | `--skip-brainstorm` flag passed | Human override |

#### Gate Logic

```python
# Pseudocode
def needs_brainstorm(task, skip_flag=False):
    # Skip conditions (check first)
    if skip_flag:
        return False
    if task.task_type in ["bug", "chore"]:
        return False
    if (len(task.description) >= 100 and
        task.acceptance_criteria and
        not has_ambiguous_keywords(task)):
        return False

    # Trigger conditions
    if len(task.description) < 100:
        return True, "Short description"
    if not task.acceptance_criteria:
        return True, "No acceptance criteria"
    if task.task_type == "spike":
        return True, "Spike investigation"
    if has_ambiguous_keywords(task):
        return True, "Ambiguous scope"

    return False
```

#### Dispatching Brainstormer

If brainstorm triggers:

1. Dispatch brainstormer:
   ```
   Task tool (yokay-brainstormer):
     description: "Brainstorm: {task.title}"
     prompt: [Fill template from agents/templates/brainstorm-prompt.md]
   ```

2. Process brainstorm result:
   - Update ohno task with refined requirements:
     ```
     update_task(task_id, {
       description: refined_description,
       acceptance_criteria: proposed_criteria
     })
     ```
   - If open questions: PAUSE for human input
   - If refined: Proceed to Step 4

3. Log activity:
   ```
   add_task_activity(task_id, "note", "Brainstorm: Refined requirements")
   ```

#### Brainstorm Flow

```
┌──────────────┐
│  Get Task    │
└──────┬───────┘
       │
       ▼
┌──────────────┐     NO      ┌──────────────┐
│ Needs        │────────────►│ Skip to      │
│ Brainstorm?  │             │ Implementer  │
└──────┬───────┘             └──────────────┘
       │ YES
       ▼
┌──────────────┐
│ Brainstormer │
│  Subagent    │
└──────┬───────┘
       │
       ▼
┌──────────────┐     QUESTIONS   ┌──────────────┐
│ Result?      │────────────────►│ PAUSE for    │
└──────┬───────┘                 │ human input  │
       │ REFINED                 └──────────────┘
       ▼
┌──────────────┐
│ Update ohno  │
│ with criteria│
└──────┬───────┘
       │
       ▼
┌──────────────┐
│ Implementer  │
└──────────────┘
```

### 4. Dispatch Implementer Subagent

**CRITICAL: Do not implement inline. Always dispatch subagent.**

*Note: If brainstorm ran in Step 3, task now has refined requirements.*

1. Extract full task details from ohno:
   ```
   task = get_task(task_id)
   ```

2. Prepare context for subagent:
   - Task description (full text)
   - Acceptance criteria (if any)
   - Architectural context (where this fits in the project)
   - Relevant skill (determined in Step 2)

3. Dispatch subagent using Task tool:
   ```
   Task tool (yokay-implementer):
     description: "Implement: {task.title}"
     prompt: [Fill template from agents/templates/implementer-prompt.md]
   ```

4. Process subagent result:
   - If questions: Answer and re-dispatch
   - If complete: Proceed to Step 5 (Review)
   - If blocked: Set blocker via ohno MCP

**Why subagent?**
- Fresh context per task (no accumulated confusion)
- Subagent can ask questions before/during work
- Context discarded after task (token efficiency)

### 4.5 Browser Verification (Conditional)

After the implementer completes, check if browser verification should run.

#### Testability Checks

All three conditions must pass:

1. **Browser tools available**: Check for Playwright MCP (`mcp__plugin_playwright_*`) or Chrome extension tools
2. **Server running**: HTTP server on ports 3000-9999, or can be started via package.json
3. **Renderable files changed**: Task modified `.html`, `.css`, `.tsx`, `.jsx`, `.vue`, `.svelte`, or files in `components/`, `views/`, `ui/`, `pages/`

If any check fails, silently skip to Step 5 (Review).

#### Verification Flow

If all checks pass:

1. Dispatch browser verifier:
   ```
   Task tool (yokay-browser-verifier):
     description: "Browser verify: {task.title}"
     prompt: [Include task details, server URL, changed files]
   ```

2. Process verification result:
   - **PASS**: Continue to Step 5 (Review)
   - **ISSUE**: Re-dispatch implementer with visual/functional issues
   - **SKIP**: User provided reason, continue with warning flag

3. Log activity:
   ```
   add_task_activity(task_id, "note", "Browser verification: PASS/ISSUE/SKIP")
   ```

#### Detection Pseudocode

```python
def should_verify_browser(task, changed_files):
    # Check 1: Browser tools
    has_playwright = any_tool_matches("mcp__plugin_playwright_*")
    has_chrome = any_tool_matches("mcp__claude-in-chrome__*")
    if not (has_playwright or has_chrome):
        return False, "No browser tools"

    # Check 2: Server running
    server = detect_server([3000, 9999])
    if not server and not can_start_server():
        return False, "No server"

    # Check 3: Renderable files
    renderable_exts = ['.html', '.css', '.scss', '.tsx', '.jsx', '.vue', '.svelte']
    renderable_paths = ['components/', 'views/', 'ui/', 'pages/']

    has_renderable = any(
        f.endswith(tuple(renderable_exts)) or
        any(p in f for p in renderable_paths)
        for f in changed_files
    )
    if not has_renderable:
        return False, "No UI changes"

    return True, server
```

#### Advisory Behavior

This is advisory, not blocking:
- User can skip with a reason
- Skip reason is logged in task notes
- Work continues to review with warning flag

See `skills/browser-verification/SKILL.md` for full details.

### 5. Two-Stage Review

After implementer completes, run reviews in sequence:

#### Stage 1: Spec Compliance Review

Verify implementation matches task specification.

1. Dispatch spec reviewer:
   ```
   Task tool (yokay-spec-reviewer):
     description: "Spec review: {task.title}"
     prompt: [Fill template from agents/templates/spec-review-prompt.md]
   ```

2. Process spec review result:
   - **PASS**: Proceed to quality review (Stage 2)
   - **FAIL**: Re-dispatch implementer with spec issues

**What spec reviewer checks:**
- All acceptance criteria met
- No missing requirements
- No scope creep (extra work)
- Correct interpretation of spec

#### Stage 2: Quality Review

Only runs if spec review passes.

1. Dispatch quality reviewer:
   ```
   Task tool (yokay-quality-reviewer):
     description: "Quality review: {task.title}"
     prompt: [Fill template from agents/templates/quality-review-prompt.md]
   ```

2. Process quality review result:
   - **PASS**: Proceed to task completion (Step 6)
   - **FAIL**: Re-dispatch implementer with quality issues

**What quality reviewer checks:**
- Code structure and readability
- Test quality and coverage
- Edge case handling
- Project convention compliance

#### Review Failure Hook Integration

When either spec or quality review fails, the post-review-fail hook is invoked to analyze the failure and suggest corrective actions.

**Hook Execution:**

```bash
# Set environment variables and call hook
export TASK_ID="<current-task-id>"
export FAILURE_DETAILS="<review-failure-details>"
export FAILURE_SOURCE="<spec-review|quality-review>"

./hooks/post-review-fail.sh
```

The hook analyzes the failure using kaizen and returns JSON with one of three actions:

**1. AUTO Action (High Confidence)**

Hook detects a well-known failure pattern and auto-creates a fix task.

```json
{
  "action": "AUTO",
  "fix_task": {
    "title": "Fix: Missing error handling in API endpoint",
    "description": "Review failed due to missing error handling...",
    "type": "bug",
    "estimate": 2
  }
}
```

Coordinator behavior:
1. Create fix task in ohno:
   ```bash
   npx @stevestomp/ohno-cli create "${fix_task.title}" \
     -t ${fix_task.type} \
     --description "${fix_task.description}" \
     -e ${fix_task.estimate} \
     --source "kaizen-fix"
   ```
2. Block current task on the fix task:
   ```bash
   npx @stevestomp/ohno-cli dep add <current-task-id> <fix-task-id>
   npx @stevestomp/ohno-cli block <current-task-id> "Blocked by fix task ${fix_task_id}"
   ```
3. Log activity:
   ```bash
   add_task_activity(task_id, "note", "Review failed, fix task auto-created: ${fix_task_id}")
   ```
4. Get next task and continue work loop

**2. SUGGEST Action (Medium Confidence)**

Hook has a suggestion but needs user confirmation.

```json
{
  "action": "SUGGEST",
  "fix_task": {
    "title": "Fix: Improve test coverage for edge cases",
    "description": "Review suggests adding tests for...",
    "type": "test",
    "estimate": 3
  },
  "confidence": "medium"
}
```

Coordinator behavior:
1. Present suggestion to user:
   ```markdown
   Review failed. Suggested fix task:
   - Title: ${fix_task.title}
   - Type: ${fix_task.type}
   - Estimate: ${fix_task.estimate}h
   - Description: ${fix_task.description}

   Create fix task? (yes/no/customize)
   ```
2. Handle user response:
   - **yes**: Create fix task, block current task, get next task
   - **no**: Continue with existing re-dispatch behavior (max 3 cycles)
   - **customize**: Let user modify fix_task details, then create

**3. LOGGED Action (Low Confidence)**

Hook cannot confidently suggest a fix task, only logs the failure.

```json
{
  "action": "LOGGED",
  "message": "Failure logged to kaizen database"
}
```

Coordinator behavior:
1. Log activity:
   ```bash
   add_task_activity(task_id, "note", "Review failed: ${FAILURE_DETAILS}")
   ```
2. Continue with existing re-dispatch behavior (max 3 cycles)

**Hook Integration Flow:**

```
Review FAIL
     │
     ▼
┌─────────────────┐
│ Call post-      │
│ review-fail.sh  │
└────────┬────────┘
         │
         ▼
    Parse JSON
         │
    ┌────┴─────┬─────────────┐
    │          │             │
    ▼          ▼             ▼
┌──────┐  ┌─────────┐  ┌──────────┐
│ AUTO │  │ SUGGEST │  │ LOGGED   │
└───┬──┘  └────┬────┘  └─────┬────┘
    │          │              │
    ▼          ▼              │
┌──────────┐  ┌──────────┐   │
│ Create   │  │ Prompt   │   │
│ fix task │  │ user     │   │
└─────┬────┘  └────┬─────┘   │
      │            │         │
      │       ┌────┴─────┐   │
      │       │          │   │
      │      yes        no   │
      │       │          │   │
      ▼       ▼          ▼   ▼
┌─────────────────────────────┐
│ Block current task          │
│ Get next task               │
└─────────────────────────────┘
                  OR
┌─────────────────────────────┐
│ Re-dispatch implementer     │
│ (existing behavior)         │
└─────────────────────────────┘
```

#### Review Loop

```
┌──────────────┐
│ Implementer  │
│  completes   │
└──────┬───────┘
       │
       ▼
┌──────────────┐  NO   ┌──────────────┐
│ UI changes?  │──────►│ Skip browser │
│              │       │  verify      │
└──────┬───────┘       └──────┬───────┘
       │ YES                  │
       ▼                      │
┌──────────────┐  ISSUE  ┌────┴────────┐
│   Browser    │────────►│ Re-dispatch │
│   Verify     │         │ implementer │
└──────┬───────┘         └─────────────┘
       │ PASS/SKIP             ▲
       ▼                       │
┌──────────────┐     FAIL      │
│ Spec Review  │───────────────┤
└──────┬───────┘               │
       │ PASS                  │
       ▼                       │
┌──────────────┐     FAIL      │
│Quality Review│───────────────┤
└──────┬───────┘               │
       │ PASS                  │
       │                       │
       │ ┌─────────────────────┘
       │ │ Review FAIL
       │ ▼
       │ ┌─────────────────┐
       │ │ post-review-    │
       │ │ fail.sh hook    │
       │ └────────┬────────┘
       │          │
       │     ┌────┴─────┬──────────┐
       │     │          │          │
       │     ▼          ▼          ▼
       │ ┌──────┐  ┌────────┐  ┌───────┐
       │ │ AUTO │  │SUGGEST │  │LOGGED │
       │ └───┬──┘  └───┬────┘  └───┬───┘
       │     │         │           │
       │     ▼         ▼           │
       │ ┌────────┐ ┌──────┐      │
       │ │ Create │ │Prompt│      │
       │ │fix task│ │ user │      │
       │ └───┬────┘ └──┬───┘      │
       │     │      yes│ │no      │
       │     │      ┌──┘ │        │
       │     ▼      ▼    ▼        ▼
       │ ┌────────────────────────────┐
       │ │ Block current, get next    │
       │ └────────────────────────────┘
       │              OR
       │ ┌────────────────────────────┐
       └─┤ Re-dispatch implementer    │
         │ (max 3 cycles)             │
         └────────────────────────────┘
       ▼
┌──────────────┐
│   Complete   │
│    Task      │
└──────────────┘
```

**Re-dispatch rules:**
- Include specific issues from review
- Reference original acceptance criteria
- Maximum 3 review cycles (then escalate to human)

#### Logging Reviews to ohno

After each review, log activity:
```
add_task_activity(task_id, "note", "Spec review: PASS")
add_task_activity(task_id, "note", "Quality review: PASS")
```

Or for failures:
```
add_task_activity(task_id, "note", "Spec review: FAIL - Missing requirement X")
```

### 6. Complete Task

After reviews pass (Step 5), coordinator:
- Logs activity to ohno
- Triggers post-task hooks

```bash
npx @stevestomp/ohno-cli done <task-id> --notes "What was done"
```

### 7. Checkpoint (based on mode)

#### Sequential Mode

**Supervised** (default):
- PAUSE after every task
- Ask user: Continue / Modify / Stop / Switch task?

**Semi-auto**:
- Log task completion, continue
- PAUSE at story/epic boundaries

**Autonomous**:
- Log and continue
- Only PAUSE at epic boundaries

#### Parallel Mode

**Supervised** (default):
- PAUSE after each task completes (not waiting for batch)
- Show batch status table
- Ask user: Continue / Modify / Stop / Drain / Resolve conflict?

**Semi-auto**:
- Log each completion
- PAUSE at story/epic boundaries
- Show batch status at pause

**Autonomous**:
- Log and continue
- PAUSE at epic boundaries
- Show summary at pause

#### Batch Status Table

When pausing in parallel mode, show:

```markdown
## Parallel Batch Status

| Task | Title | Status | Notes |
|------|-------|--------|-------|
| task-001 | User auth | ✓ completed | committed abc123 |
| task-002 | Login endpoint | ✓ completed | committed def456 |
| task-003 | Password hash | ⚠️ conflict | needs resolution |
| task-004 | Session mgmt | ⟳ implementing | agent-xyz |

**Queue**: 3 tasks waiting
**Completed this session**: 5 tasks

Options:
- **continue** / **c**: Keep going
- **drain**: Finish active, don't start new
- **resolve <task>**: Pause to fix conflict
- **stop**: End session now
```

### 8. Repeat
Get next task and continue until:
- No more tasks
- User requests stop
- Checkpoint triggers pause

## Hook System

Hooks execute automatically at lifecycle points:

- **pre-session**: Verifies clean git state
- **pre-task**: Checks for blockers
- **post-task**: Syncs ohno, commits changes (mode-dependent)
- **post-story**: Runs tests, mini-audit
- **post-session**: Final sync, summary

Hooks guarantee sync and commit execution (mode-dependent).

### Customizing Hooks

Create `.yokay/hooks.yaml` in your project:

```yaml
hooks:
  post-task:
    actions:
      - sync
      - commit
      - my-custom-action

  pre-commit:
    enabled: false  # Disable linting
```

See `hooks/HOOKS.md` for full configuration.

## Session End

### 1. Update Session Notes
Use ohno MCP to log:
- What was accomplished
- Any blockers encountered
- Recommended next steps

### 2. Report to User
- Tasks completed this session
- Current project status
- Next recommended task

*Post-session hooks handle final sync and summary.*

## Modes Reference

| Mode | Task Complete | Story Complete | Epic Complete |
|------|--------------|----------------|---------------|
| supervised | PAUSE | PAUSE | PAUSE |
| semi-auto | log | PAUSE | PAUSE |
| autonomous | skip | log | PAUSE |

## Spike Task Protocol

When working on a spike task:

### 1. Time-Box Reminder
At session start, announce time limit:
```markdown
## Spike: [Question]
**Time Box**: [hours from task estimate]
**Started**: [timestamp]
**Must Conclude By**: [timestamp + time-box]
```

### 2. Checkpoint at 50%
Halfway through time-box, assess progress:
```markdown
## Spike Checkpoint (50%)
**Progress**: [summary of findings so far]
**On Track?**: Yes / No / Pivoting
**Remaining Time**: [hours]
```

### 3. Mandatory Conclusion
At time-box end, MUST produce decision:
- **GO**: Create implementation tasks from findings
- **NO-GO**: Document why not feasible, close spike
- **PIVOT**: Create new spike with adjusted question
- **MORE-INFO**: (Rare) Create follow-up spike, max 1 re-spike

### 4. Output Location
Save spike report to `.claude/spikes/[name]-[date].md`

## Bug Discovery During Work

If you discover a bug while working on a feature:

### Minor Bugs (< 30 min fix)
1. Fix immediately
2. Add to current commit with note
3. Continue with original task

### Larger Bugs
1. Log in ohno: `npx @stevestomp/ohno-cli create "Bug: [description]" -t bug -p P1`
2. Continue with original task
3. Address bug in future `/pokayokay:work` session

### Blocking Bugs
1. Block current task: `npx @stevestomp/ohno-cli block <task-id> "Blocked by bug"`
2. Create bug task with P0 priority
3. Switch to bug fix immediately

## Related Commands

- `/pokayokay:plan` - Create tasks before working
- `/pokayokay:handoff` - End session with context preservation
- `/pokayokay:audit` - Check feature completeness
- `/pokayokay:review` - Analyze session patterns
