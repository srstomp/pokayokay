# Session Protocol Reference

Detailed guide for managing AI development sessions with the project harness.

## Session Lifecycle

```
┌─────────────────────────────────────────────────────────────┐
│                    SESSION LIFECYCLE                        │
│                                                             │
│  ┌─────────┐   ┌─────────┐   ┌─────────┐   ┌─────────┐     │
│  │  INIT   │ → │  WORK   │ → │ COMMIT  │ → │  END    │     │
│  └─────────┘   └─────────┘   └─────────┘   └─────────┘     │
│       │             │             │             │           │
│       ▼             ▼             ▼             ▼           │
│   Read state    Execute      Git commit    Update          │
│   Start server  task         Sync kanban   progress.md     │
│   Sync kanban   Checkpoint   Update DB     Final sync      │
│   Plan                                     Stop server     │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Session Initialization

### Step 1: Read Configuration

```python
# Pseudocode for session init
config = read_yaml(".claude/config.yaml")
mode = config.mode  # supervised | semi-auto | autonomous
checkpoints = config.checkpoints
kanban_port = config.kanban.get("port", 3333)
```

**Announce mode**:
```markdown
## Session Start

**Mode**: supervised
**Max tasks this session**: 10
**Verification required**: Yes
**Kanban port**: 3333
```

### Step 2: Read Progress

```python
progress = read_markdown(".claude/progress.md")
current_feature = progress.active_feature
current_task = progress.active_task
last_session = progress.sessions[-1]
```

**Summarize state**:
```markdown
## Current State

**Last session**: 2025-01-10-001 (completed 4 tasks)
**In progress**: F002 - User Dashboard
**Next task**: T008 - Create header component
**Overall**: 12/47 tasks complete (25%)
```

### Step 3: Start Kanban Server

```bash
# Check if already running
if [ -f .claude/.kanban.pid ] && kill -0 $(cat .claude/.kanban.pid) 2>/dev/null; then
    echo "📊 Kanban server already running"
else
    echo "📊 Starting kanban server..."
    cd .claude && python3 -m http.server 3333 > /dev/null 2>&1 &
    echo $! > .kanban.pid
fi
```

**Announce to user**:
```markdown
## 📊 Kanban Board

**URL**: http://localhost:3333/kanban.html
**Status**: Running
**Auto-refresh**: Every 5 seconds

Open in your browser to track progress visually.
```

### Step 4: Initial Kanban Sync

```bash
python3 .claude/scripts/sync-kanban.py
```

Ensures kanban shows current state from tasks.db.

### Step 5: Read Features

```python
features = read_json(".claude/features.json")
pending = [f for f in features if f.status == "pending"]
in_progress = [f for f in features if f.status == "in_progress"]
blocked = [f for f in features if is_blocked(f)]
```

**Show work queue**:
```markdown
## Work Queue

**In Progress**: 
- F002 - User Dashboard (3/8 tasks done)

**Up Next** (P0):
- F003 - API Endpoints (blocked by F001)
- F004 - Settings Page

**Blocked**:
- F003 waiting on F001 completion
```

### Step 6: Verify Project State

Run verification commands from config:

```bash
# Check build
npm run build
# Exit code 0 = success

# Run quick tests
npm test -- --bail
# Exit code 0 = success

# Try starting dev server
npm run dev &
sleep 5
curl http://localhost:3000/health
# 200 = success
```

**Report verification**:
```markdown
## Verification

- [x] Build passes
- [x] Tests pass (47/47)
- [x] Dev server starts
- [x] Health check responds
- [x] Kanban server running

✓ Project is in good state. Ready to proceed.
```

If verification fails:
```markdown
## ⚠️ Verification Failed

**Build error**: TypeScript compilation failed
```
src/components/Dashboard.tsx:47
  Property 'user' does not exist on type '{}'
```

**Action**: Fix before starting new work.

Proceeding to fix build error...
```

### Step 7: Select Next Task

Selection priority:
1. In-progress tasks (finish what's started)
2. Unblocked P0 features
3. Unblocked P1 features
4. Unblocked P2 features

```python
def select_next_task(features, tasks):
    # First: finish in-progress
    in_progress = [t for t in tasks if t.status == "in_progress"]
    if in_progress:
        return in_progress[0]
    
    # Then: by priority, respecting dependencies
    for priority in ["P0", "P1", "P2"]:
        available = [f for f in features 
                     if f.priority == priority 
                     and not is_blocked(f)
                     and f.status != "done"]
        if available:
            feature = available[0]
            return get_next_task(feature)
    
    return None  # All done!
```

### Step 8: Announce Plan

```markdown
## Session Plan

**Goal**: Complete User Dashboard feature (F002)
**Tasks this session**:
1. T008 - Create header component (2h)
2. T009 - Create sidebar navigation (3h)
3. T010 - Wire up routing (2h)

**Estimated time**: 7 hours
**Mode**: supervised (checkpoint after each task)
**Kanban**: http://localhost:3333/kanban.html

Ready to begin. Starting T008...
```

## Work Execution

### Task Workflow

For each task:

```markdown
## Task: T008 - Create header component

### Context
- Feature: F002 - User Dashboard
- Story: S003 - Dashboard Layout
- Type: frontend
- Estimate: 2 hours

### Plan
1. Create Header.tsx component
2. Add user avatar dropdown
3. Add navigation breadcrumb
4. Style with Tailwind
5. Export from components/index.ts

### Implementation

[Work happens here - showing key decisions]

Created `src/components/Header.tsx`:
- Responsive design (mobile menu collapses)
- User dropdown with logout action
- Breadcrumb from route params

### Verification

- [x] Component renders without errors
- [x] Mobile responsive (tested at 375px)
- [x] User dropdown opens/closes
- [x] Logout action fires

### Result

**Status**: Complete
**Time**: 1.5 hours
**Files changed**: 3
```

### Post-Task Steps (CRITICAL)

After EVERY completed task:

```markdown
### Post-Task Checklist

1. [x] Git commit
2. [x] Update tasks.db status
3. [x] **SYNC KANBAN** ← Don't forget!
4. [x] Update progress.md
5. [x] Execute checkpoint
```

### Git Commit

```bash
git add -A
git commit -m "[claude] feat(dashboard): add header component with user dropdown

- Responsive header with mobile collapse
- User avatar dropdown with logout
- Breadcrumb navigation from route

Task: T008
Feature: F002 - User Dashboard"
```

### Sync Kanban

```bash
# Always sync after DB change
python3 .claude/scripts/sync-kanban.py
```

Or inline:
```python
# After updating task status
update_task_status("T008", "done")
sync_kanban()  # ← ALWAYS
```

### Update Progress

Add to `.claude/progress.md`:

```markdown
### Task T008 Complete (15:30)

- Created Header component
- Files: Header.tsx, index.ts, Header.test.tsx
- Commit: abc1234
- Kanban: Synced ✓

**Running total**: 13/47 tasks (27%)
```

## Session Checkpoints

### Checkpoint Execution

Based on config, execute appropriate checkpoint:

```python
def execute_checkpoint(event_type, config, context):
    behavior = config.checkpoints[event_type]
    
    if behavior == "pause":
        return pause_checkpoint(context)
    elif behavior == "review":
        return review_checkpoint(context)
    elif behavior == "notify":
        return notify_checkpoint(context)
    elif behavior == "skip":
        return continue_work()
```

### Pause Checkpoint

Full stop, wait for human:

```markdown
## 🛑 CHECKPOINT: Task Complete

**Just completed**: T008 - Create header component
**Time spent**: 1.5 hours
**Commit**: abc1234
**Kanban**: http://localhost:3333/kanban.html (synced ✓)

### Summary
Created responsive header with user dropdown and breadcrumb navigation.

### Next Up
T009 - Create sidebar navigation (3h estimate)

### Your Options

1. **Continue** → Proceed to T009
2. **Review** → I'll wait while you check the code
3. **Modify** → Tell me what to change
4. **Switch** → Work on different task/feature
5. **End** → Stop session here

What would you like to do?
```

### Review Checkpoint

Flag for later, continue working:

```markdown
## 📋 FLAGGED: Task T008 for review

Added to `.claude/checkpoints/pending-review.md`
Kanban synced ✓

Continuing to T009...
```

### Notify Checkpoint

Log and continue:

```markdown
✓ T008 complete (abc1234) | Kanban synced → T009
```

## Session Termination

### Normal End

When reaching natural stopping point:

```markdown
## Session Complete

**Duration**: 3.5 hours
**Tasks completed**: 5 (T008-T012)
**Commits**: 5

### Summary
- Completed Dashboard layout (S003)
- Started Widget framework (S004)
- All tests passing
- No blocking issues

### State for Next Session
- Active: T013 - Create chart widget
- Ready to continue S004

### Files Changed
- src/components/Header.tsx (new)
- src/components/Sidebar.tsx (new)
- src/components/Layout.tsx (modified)
- src/routes/dashboard.tsx (modified)
- package.json (added chart library)

### Kanban
Final sync complete ✓
http://localhost:3333/kanban.html

Session ended cleanly. Progress saved.
```

### Session End Checklist

```markdown
## Session End Checklist

1. [x] All changes committed
2. [x] tasks.db status current
3. [x] **Kanban synced (final)**
4. [x] progress.md updated  
5. [x] No broken code left
6. [ ] Stop kanban server? (optional)
7. [x] Clear summary written
8. [x] Next steps documented
```

### Stopping the Server

```bash
# Optional - can leave running between sessions
if [ -f .claude/.kanban.pid ]; then
    kill $(cat .claude/.kanban.pid) 2>/dev/null
    rm .claude/.kanban.pid
    echo "📊 Kanban server stopped"
fi
```

### Forced End

When hitting session limits:

```markdown
## Session Limit Reached

**Reason**: max_tasks_per_session (10) reached
**Tasks completed**: 10

Saving progress and syncing kanban...

[Same summary as normal end]
```

### Error End

When unrecoverable error:

```markdown
## ⚠️ Session Ended: Unrecoverable Error

**Error**: Database migration failed
**Impact**: Cannot proceed until resolved

### State
- Last successful commit: abc1234
- Incomplete work discarded
- progress.md updated with error
- **Kanban synced** (shows blocked state)

### Recovery Steps
1. Check migration logs
2. Resolve database issue
3. Start new session

Human intervention required.
```

## Session Logging

Each session creates `.claude/sessions/YYYY-MM-DD-NNN.md`:

```markdown
# Session 2025-01-10-002

**Start**: 14:30
**End**: 18:00
**Mode**: supervised
**Tasks**: 5
**Kanban syncs**: 6

## Timeline

| Time | Event | Details |
|------|-------|---------|
| 14:30 | Session start | Mode: supervised |
| 14:31 | Kanban server | Started on :3333 |
| 14:32 | Initial sync | 47 tasks loaded |
| 14:33 | Verification | All checks passed |
| 14:35 | Task start | T008 - Header component |
| 15:30 | Task complete | T008 - 1.5h |
| 15:30 | Kanban sync | 13/47 done |
| 15:32 | Checkpoint | PAUSE - user: continue |
| 15:35 | Task start | T009 - Sidebar |
| ... | ... | ... |
| 17:55 | Task complete | T012 |
| 17:55 | Kanban sync | 17/47 done |
| 18:00 | Final sync | Complete |
| 18:00 | Session end | Normal completion |

## Decisions Made

| Decision | Context | Choice |
|----------|---------|--------|
| Chart library | T012 needed charts | Chose recharts over Chart.js |
| Mobile nav | T009 sidebar | Hamburger menu pattern |

## Issues Encountered

| Issue | Resolution |
|-------|------------|
| Type error in Layout | Fixed generic type |
| Test flaky | Added wait for animation |

## Commits

1. abc1234 - feat(dashboard): add header component
2. def5678 - feat(dashboard): add sidebar navigation
3. ghi9012 - feat(dashboard): add layout wrapper
4. jkl3456 - feat(dashboard): wire up routing
5. mno7890 - feat(dashboard): add chart widget base

## Kanban Syncs

| Time | Tasks Done | Notes |
|------|------------|-------|
| 14:32 | 12/47 | Initial |
| 15:30 | 13/47 | T008 done |
| 16:15 | 14/47 | T009 done |
| 16:45 | 15/47 | T010 done |
| 17:30 | 16/47 | T011 done |
| 17:55 | 17/47 | T012 done |
| 18:00 | 17/47 | Final |
```
