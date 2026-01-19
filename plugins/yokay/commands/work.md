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

Based on task type, load relevant skill for domain knowledge:

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

### 3. Implement
Do the work.

### 4. Complete Task
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
