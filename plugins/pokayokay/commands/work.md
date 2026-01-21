---
description: Start or continue orchestrated work session
argument-hint: [supervised|semi-auto|autonomous]
skill: project-harness
---

# Work Session Workflow

Start or continue a development session with configurable human control.

**Mode**: `$ARGUMENTS` (default: supervised)

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

### 4. Start the Task
```bash
npx @stevestomp/ohno-cli start <task-id>
```

## Work Loop

For each task:

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

### 3. Dispatch Implementer Subagent

**CRITICAL: Do not implement inline. Always dispatch subagent.**

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
   - If complete: Proceed to Step 4
   - If blocked: Set blocker via ohno MCP

**Why subagent?**
- Fresh context per task (no accumulated confusion)
- Subagent can ask questions before/during work
- Context discarded after task (token efficiency)

### 4. Two-Stage Review

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
   - **PASS**: Proceed to task completion (Step 5)
   - **FAIL**: Re-dispatch implementer with quality issues

**What quality reviewer checks:**
- Code structure and readability
- Test quality and coverage
- Edge case handling
- Project convention compliance

#### Review Loop

```
┌──────────────┐
│ Implementer  │
│  completes   │
└──────┬───────┘
       │
       ▼
┌──────────────┐     FAIL     ┌──────────────┐
│ Spec Review  │─────────────►│ Re-dispatch  │
└──────┬───────┘              │ implementer  │
       │ PASS                 │ with issues  │
       ▼                      └──────┬───────┘
┌──────────────┐                     │
│Quality Review│◄────────────────────┘
└──────┬───────┘
       │ PASS
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

### 5. Complete Task

After subagent completes (Step 3), coordinator:
- Logs activity to ohno
- Triggers post-task hooks

```bash
npx @stevestomp/ohno-cli done <task-id> --notes "What was done"
```

### 5. Checkpoint (based on mode)

**Supervised** (default):
- PAUSE after every task
- Ask user: Continue / Modify / Stop / Switch task?

**Semi-auto**:
- Log task completion, continue
- PAUSE at story/epic boundaries
- Ask user for review

**Autonomous**:
- Log and continue
- Only PAUSE at epic boundaries

### 6. Repeat
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
