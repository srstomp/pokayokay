# Checkpoint Types Reference

Complete guide to checkpoint configuration and behavior.

## Overview

Checkpoints are decision points where the harness can pause for human input, flag for review, notify, or continue silently. They're the primary mechanism for controlling automation level.

## Checkpoint Events

### Event Types

| Event | Trigger | Default |
|-------|---------|---------|
| `task_complete` | After each task finishes | pause |
| `story_complete` | After all tasks in story done | pause |
| `epic_complete` | After all stories in epic done | pause |
| `error_encountered` | Build/test failure | pause |
| `ambiguity_found` | Requirements unclear | pause |
| `scope_change` | New work discovered | pause |
| `dependency_resolved` | Blocker removed | notify |
| `session_limit` | Max tasks/time reached | pause |

### Checkpoint Behaviors

| Behavior | Action | Human Required |
|----------|--------|----------------|
| `pause` | Stop completely, wait for input | Yes |
| `review` | Flag for review, continue | No (later) |
| `notify` | Log message, continue | No |
| `skip` | Silent continue | No |

## Configuration

### In config.yaml

```yaml
checkpoints:
  task_complete: pause      # Stop after every task
  story_complete: pause     # Stop after story
  epic_complete: pause      # Stop after epic
  error_encountered: pause  # Stop on errors
  ambiguity_found: pause    # Stop when unclear
  scope_change: pause       # Stop when scope changes
```

### Mode Presets

**Supervised** (maximum control):
```yaml
checkpoints:
  task_complete: pause
  story_complete: pause
  epic_complete: pause
  error_encountered: pause
  ambiguity_found: pause
  scope_change: pause
```

**Semi-Auto** (balanced):
```yaml
checkpoints:
  task_complete: notify
  story_complete: pause
  epic_complete: pause
  error_encountered: pause
  ambiguity_found: pause
  scope_change: review
```

**Auto** (minimal interruption):
```yaml
checkpoints:
  task_complete: skip
  story_complete: notify
  epic_complete: pause
  error_encountered: pause
  ambiguity_found: review
  scope_change: review
```

## Checkpoint Formats

### PAUSE Format

```markdown
## 🛑 CHECKPOINT: [Event Type]

**Event**: [What happened]
**Context**: [Relevant details]
**Kanban**: http://localhost:3333/kanban.html (synced ✓)

### Summary
[Brief description of work done]

### What I'd Do Next
[Proposed next step with estimate]

### Your Options
1. **Continue** - Proceed with proposed next step
2. **Modify** - Change approach or provide guidance
3. **Switch** - Work on something different
4. **Review** - Wait while you inspect the work
5. **End** - Stop session here

Waiting for your decision...
```

### REVIEW Format

```markdown
## 📋 REVIEW FLAG: [Event Type]

**Event**: [What happened]
**Flagged at**: [Timestamp]
**Kanban**: Synced ✓

Added to `.claude/checkpoints/pending-review.md`

Continuing to next task...
```

### NOTIFY Format

```markdown
✓ [Event]: [Brief description] | Kanban synced → [Next action]
```

Examples:
```markdown
✓ Task T008 complete (abc1234) | Kanban synced → Starting T009
✓ Story S003 complete (5 tasks) | Kanban synced → Starting S004
✓ Dependency resolved: F001 done → F003 unblocked
```

## Pending Review File

When `review` behavior is used, items are logged to `.claude/checkpoints/pending-review.md`:

```markdown
# Pending Reviews

Items flagged for human review. Check when convenient.

## Tasks

### T008 - Create header component
- **Flagged**: 2025-01-10 15:30
- **Event**: task_complete
- **Commit**: abc1234
- **Files**: 
  - src/components/Header.tsx (new)
  - src/components/index.ts (modified)
- **Notes**: Used new dropdown pattern from design system
- **Status**: ⏳ Pending

### T012 - Add chart widget
- **Flagged**: 2025-01-10 17:00
- **Event**: task_complete
- **Commit**: mno7890
- **Files**:
  - src/widgets/Chart.tsx (new)
  - package.json (added recharts)
- **Notes**: Chose recharts over Chart.js for bundle size
- **Status**: ⏳ Pending

## Scope Changes

### SC001 - Rate limiting needed
- **Flagged**: 2025-01-10 16:15
- **Event**: scope_change
- **Feature**: F003 - API Endpoints
- **Description**: Discovered need for rate limiting middleware
- **Proposed**: Add task T015 to F003
- **Estimate**: +3 hours
- **Status**: ⏳ Pending approval

## Resolved

### T005 - Database schema
- **Flagged**: 2025-01-09 14:00
- **Reviewed**: 2025-01-09 18:00
- **Outcome**: Approved, no changes needed
- **Status**: ✓ Resolved
```

## Checkpoint Decision Handling

### Continue

User says "continue" or "yes" or "proceed":
```markdown
Continuing with T009 - Create sidebar navigation...
```

### Modify

User provides guidance:
```markdown
**Your input**: "Use a collapsible sidebar instead of hamburger menu"

Understood. I'll modify the approach:
- Use collapsible sidebar pattern
- Remember expanded/collapsed state
- Animate transition

Proceeding with modified approach...
```

### Switch

User wants different work:
```markdown
**Your input**: "Switch to F004 - Settings Page"

Switching context:
- Current progress saved
- F002 remains in_progress
- Starting F004

Analyzing F004 tasks...
```

### Review

User wants to inspect:
```markdown
**Your input**: "Let me review the header code"

I'll wait here while you review.

**Files to check**:
- src/components/Header.tsx
- src/components/Header.test.tsx

**Kanban**: http://localhost:3333/kanban.html

Let me know when you're ready to continue.
```

### End

User wants to stop:
```markdown
**Your input**: "End session"

Ending session...

### Session Summary
- Duration: 2.5 hours
- Tasks completed: 4
- Kanban: Final sync complete ✓
- Next task when resuming: T009

Session saved. Goodbye!
```

## Error Checkpoints

### Build Error

```markdown
## ⚠️ CHECKPOINT: Build Error

**Error type**: TypeScript compilation
**Location**: src/components/Dashboard.tsx:47

```
Property 'user' does not exist on type '{}'
```

### Analysis
- Recent change in T007 modified User type
- Dashboard component not updated

### Recovery Options
1. **Auto-fix** - I'll add the missing type
2. **Manual** - You fix, then tell me to continue
3. **Revert** - Roll back to last working state
4. **Investigate** - I'll analyze further before acting

What would you like me to do?
```

### Test Failure

```markdown
## ⚠️ CHECKPOINT: Test Failure

**Failed tests**: 2 of 47
**Test file**: src/components/Header.test.tsx

### Failures

1. **"should show user name"**
   - Expected: "John Doe"
   - Received: undefined
   - Likely cause: User context not mocked

2. **"should handle logout"**
   - Expected: redirect to /login
   - Received: no navigation
   - Likely cause: Router mock missing

### Recovery Options
1. **Fix tests** - I'll update the test mocks
2. **Fix code** - The component may be wrong
3. **Skip** - Mark as known failure, continue
4. **Investigate** - Deeper analysis needed

What would you like me to do?
```

## Ambiguity Checkpoints

```markdown
## ❓ CHECKPOINT: Ambiguity Found

**Feature**: F005 - Data Export
**Task**: T020 - Implement export endpoint

### Ambiguity
The PRD says "export user data" but doesn't specify:
- Which data fields to include
- What format (CSV, JSON, Excel)
- Whether to include related data (orders, preferences)

### Options

1. **Minimal** - Basic profile fields only, CSV format
   - Quick to implement (2h)
   - May need expansion later

2. **Comprehensive** - All user data, multiple formats
   - More work upfront (8h)
   - Covers most use cases

3. **Ask stakeholder** - Get clarification before proceeding
   - Blocks this task
   - Ensures correct implementation

### My Recommendation
Option 1 (Minimal) - Ship basic CSV export as P0, add formats as P2.

What's your preference?
```

## Scope Change Checkpoints

```markdown
## 🔄 CHECKPOINT: Scope Change Detected

**During**: T018 - Implement API rate limiting
**Discovery**: Need Redis for distributed rate limiting

### Impact

**Without Redis** (current plan):
- In-memory rate limiting only
- Won't work with multiple server instances
- Suitable for MVP, not production

**With Redis** (scope change):
- Add Redis dependency
- Implement distributed counters
- +4 hours work
- Production-ready

### Options

1. **Proceed without** - Keep current scope, document limitation
2. **Add Redis** - Expand scope, add infrastructure task
3. **Defer decision** - Finish current task, decide later

What would you like to do?
```

## Best Practices

### Checkpoint Frequency

| Project Phase | Recommended Mode |
|---------------|------------------|
| First epic | supervised |
| Established patterns | semi-auto |
| Routine implementation | auto |
| Critical features | supervised |
| Bug fixes | semi-auto |
| Documentation | auto |

### When to Use Each Behavior

**Use `pause` when**:
- Learning new codebase
- Critical business logic
- Security-sensitive code
- User-facing features
- First time doing something

**Use `review` when**:
- Routine implementation
- Following established patterns
- Non-critical features
- Want to batch review later

**Use `notify` when**:
- Very routine tasks
- High confidence in approach
- Time-sensitive work
- Clear acceptance criteria

**Use `skip` when**:
- Extremely routine (formatting, simple refactors)
- Already reviewed similar work
- Human unavailable but work must continue

### Avoiding Checkpoint Fatigue

Too many pauses = frustration. Solutions:

1. **Start supervised, graduate to semi-auto**
   - First few tasks: pause
   - Once patterns established: notify

2. **Batch similar tasks**
   - "Complete all P0 frontend tasks, then pause"

3. **Trust but verify**
   - Use notify + review later
   - Check pending-review.md periodically

4. **Event-based pauses**
   - Pause on errors/ambiguity (important)
   - Notify on task complete (routine)
