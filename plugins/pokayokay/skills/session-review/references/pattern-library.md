# Pattern Library

Comprehensive catalog of agent behavior patterns - both good and bad.

## Detection Methods

### From Git History

```bash
# Pattern: Frequent reverts (thrashing)
REVERTS=$(git log --oneline --grep="[Rr]evert" | wc -l)
COMMITS=$(git log --oneline | wc -l)
REVERT_RATE=$(echo "scale=2; $REVERTS / $COMMITS" | bc)
# Bad if > 0.1 (more than 10% reverts)

# Pattern: Fix commits (bugs introduced)
FIXES=$(git log --oneline --grep="[Ff]ix" | wc -l)
# High number relative to features = quality issue

# Pattern: WIP commits (incomplete work)
WIP=$(git log --oneline --grep="[Ww][Ii][Pp]\|[Ww]ork in progress" | wc -l)
# Should be 0 in main branch

# Pattern: Commit size distribution
git log --shortstat --format="" | awk '/files? changed/ {
    files += $1
    insertions += $4
    deletions += $6
    commits++
}
END {
    print "Avg files/commit:", files/commits
    print "Avg insertions/commit:", insertions/commits
    print "Avg deletions/commit:", deletions/commits
}'
# Good: <10 files, <100 insertions per commit
```

### From Session Logs

```python
def detect_patterns_in_session(session_log: str) -> list[str]:
    patterns = []
    
    # Pattern: Verification before work
    if "verification" in session_log.lower() and \
       session_log.find("verification") < session_log.find("task start"):
        patterns.append("GOOD: Verifies before starting")
    
    # Pattern: Multiple tasks started
    task_starts = session_log.count("Task start")
    task_completes = session_log.count("Task complete")
    if task_starts > task_completes + 1:
        patterns.append("BAD: Multiple tasks started without completing")
    
    # Pattern: Error recovery
    errors = session_log.count("Error") + session_log.count("Failed")
    recoveries = session_log.count("Fixed") + session_log.count("Resolved")
    if errors > 0 and recoveries >= errors:
        patterns.append("GOOD: Recovers from errors")
    elif errors > 0 and recoveries < errors:
        patterns.append("BAD: Errors left unresolved")
    
    return patterns
```

### From Progress.md

```python
def analyze_progress_patterns(progress_md: str) -> dict:
    patterns = {
        'good': [],
        'bad': [],
        'neutral': []
    }
    
    sessions = parse_sessions(progress_md)
    
    # Pattern: Consistent task completion rate
    tasks_per_session = [s.tasks_completed for s in sessions]
    if len(set(tasks_per_session)) <= 2:
        patterns['good'].append("Consistent productivity across sessions")
    
    # Pattern: Progress updates
    for session in sessions:
        if not session.has_summary:
            patterns['bad'].append(f"Session {session.id} missing summary")
    
    # Pattern: Checkpoint respect
    checkpoint_overrides = sum(s.checkpoints_skipped for s in sessions)
    if checkpoint_overrides > 0:
        patterns['bad'].append(f"Skipped {checkpoint_overrides} checkpoints")
    
    return patterns
```

---

## Good Patterns Catalog

### G1: Verification First

**Description**: Agent runs build/tests before starting new work

**Signals**:
- "Verification" appears early in session log
- No broken code at session start
- Test failures caught before new features

**Why It Matters**: Prevents building on broken foundation

**How to Reinforce**:
- Add to session protocol
- Include in coding agent prompt
- Set `require_verification: true` in config

---

### G2: Atomic Commits

**Description**: Each commit represents one logical change

**Signals**:
- Commit messages are specific
- <100 lines per commit average
- Easy to revert individual changes

**Why It Matters**: Enables precise rollback, clear history

**How to Reinforce**:
- Add commit size check to workflow
- Praise in session reviews
- Include examples in prompts

---

### G3: Clarification Seeking

**Description**: Agent pauses on ambiguity instead of guessing

**Signals**:
- Checkpoint events for ambiguity
- Questions in session logs
- Low rate of rework

**Why It Matters**: Prevents building wrong thing

**How to Reinforce**:
- Keep ambiguity checkpoint at 'pause'
- Praise in reviews when this happens
- Don't punish for "too many questions"

---

### G4: Incremental Progress

**Description**: Completes one task fully before starting next

**Signals**:
- Linear task completion in logs
- No abandoned partial work
- Clean git history

**Why It Matters**: Reduces context switching, easier recovery

**How to Reinforce**:
- "Complete ONE task" in prompts
- Checkpoint after each task
- Review for partial work

---

### G5: Self-Testing

**Description**: Verifies own work before marking complete

**Signals**:
- Test runs in session logs
- Manual verification noted
- Low defect rate in later sessions

**Why It Matters**: Catches bugs early

**How to Reinforce**:
- Require verification in task completion
- Include in acceptance criteria
- Praise when tests written

---

### G6: Progress Documentation

**Description**: Keeps progress.md updated consistently

**Signals**:
- Entry after each task
- Clear session summaries
- Next steps documented

**Why It Matters**: Enables smooth session handoffs

**How to Reinforce**:
- Part of task completion checklist
- Review for quality in retrospectives

---

## Bad Patterns Catalog

### B1: Scope Creep

**Description**: Adding features not in original spec

**Signals**:
- Tasks appear that weren't in features.json
- Estimates balloon mid-project
- "While I'm here..." in logs

**Why It Matters**: Delays delivery, loses focus

**How to Prevent**:
- Scope change checkpoint at 'pause'
- Strict acceptance criteria
- Flag any new tasks for approval

**Recovery**: Revert to last checkpoint, refocus on spec

---

### B2: Build Breaking

**Description**: Committing code that doesn't compile/pass tests

**Signals**:
- Build failures in session logs
- Fix commits following feature commits
- Test failures ignored

**Why It Matters**: Compounds errors, blocks progress

**How to Prevent**:
- Require build pass before commit
- Add pre-commit hooks
- Include in git commit prompt

**Recovery**: Revert to last good state, run full test suite

---

### B3: Thrashing

**Description**: Repeatedly changing the same code without progress

**Signals**:
- Multiple reverts in sequence
- Same file modified many times
- Long session with few completions

**Why It Matters**: Wastes time, indicates confusion

**How to Prevent**:
- Pause after 2 reverts in same area
- Switch to supervised mode
- Ask for human guidance

**Recovery**: Stop, understand problem fully before continuing

---

### B4: Estimate Optimism

**Description**: Consistently underestimating task complexity

**Signals**:
- Actual time > 1.5x estimate regularly
- Certain task types always over
- Never accounting for unknowns

**Why It Matters**: Schedule unpredictability

**How to Prevent**:
- Track estimate accuracy per task type
- Apply multipliers (stored in .claude/)
- Include buffer in planning

**Recovery**: Adjust remaining estimates, update multipliers

---

### B5: Knowledge Loss

**Description**: Repeating mistakes from previous sessions

**Signals**:
- Same bug introduced twice
- Same wrong approach tried
- Ignoring previous learnings

**Why It Matters**: Wasted effort, frustration

**How to Prevent**:
- Maintain .claude/known-issues.md
- Read at session start
- Update after fixing bugs

**Recovery**: Document the issue, add to session init

---

### B6: Over-Engineering

**Description**: Building more than required

**Signals**:
- Simple task takes 3x estimate
- Abstractions added without need
- "Future-proofing" mentioned

**Why It Matters**: Delays delivery, adds complexity

**How to Prevent**:
- Clear acceptance criteria
- "Simplest thing that works" in prompts
- Review for gold-plating

**Recovery**: Simplify, remove unnecessary abstractions

---

### B7: Test Avoidance

**Description**: Skipping or ignoring test failures

**Signals**:
- Tests not run in session
- Failures marked as "known"
- Coverage decreasing

**Why It Matters**: Quality degradation, regression risk

**How to Prevent**:
- Require tests in task completion
- Block commit on test failure
- Review coverage trends

**Recovery**: Stop features, fix tests first

---

### B8: Context Overload

**Description**: Taking on too much in one session

**Signals**:
- Many tasks started, few finished
- Session ends with partial work
- Errors increase late in session

**Why It Matters**: Quality drops, handoff is messy

**How to Prevent**:
- Session task limits
- Time-based checkpoints
- One thing at a time

**Recovery**: Complete or revert partial work, end session clean

---

## Pattern Interaction Matrix

Some patterns interact:

| Pattern A | Pattern B | Interaction |
|-----------|-----------|-------------|
| Scope creep | Over-engineering | Amplify each other |
| Thrashing | Build breaking | Often co-occur |
| Verification first | Test avoidance | Mutually exclusive |
| Atomic commits | Context overload | Atomic prevents overload |
| Clarification seeking | Scope creep | Clarification prevents creep |

---

## Pattern Severity Levels

| Level | Action | Examples |
|-------|--------|----------|
| **Critical** | Stop session, human intervention | Thrashing, repeated build breaks |
| **Warning** | Flag for review, continue cautiously | Estimate drift, minor scope creep |
| **Info** | Log and continue | Single revert, slight over time |
| **Positive** | Reinforce, note for learning | Good patterns observed |
