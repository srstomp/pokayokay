---
description: Diagnose and fix a bug with structured workflow
argument-hint: <bug-description-or-task-id>
skill: error-handling
---

# Bug Fix Workflow

Fix bug: `$ARGUMENTS`

## Mode Selection

Check `$ARGUMENTS` for `--thorough` flag:
- **Default (light pipeline)**: Implementer agent only, coordinator self-reviews.
- **`--thorough`**: Full agent pipeline. Read and follow `skills/work-session/references/bug-fix-pipeline.md` instead of this command. Stop reading here.

## Bug Fix Philosophy

1. **Reproduce first**: Confirm the bug exists and understand conditions
2. **Diagnose root cause**: Don't just fix symptoms
3. **Fix with minimal change**: Avoid scope creep
4. **Verify the fix**: Confirm bug is resolved
5. **Add regression test**: Prevent recurrence

## Steps

### 1. Create or Get Bug Task
If `$ARGUMENTS` is a task ID:
```bash
npx @stevestomp/ohno-cli get <task-id>
```

If `$ARGUMENTS` is a description:
```bash
npx @stevestomp/ohno-cli create "Bug: $ARGUMENTS" -t bug
npx @stevestomp/ohno-cli start <task-id>
```

### 2. Reproduce the Bug
Before fixing, confirm:
- [ ] Bug can be reproduced
- [ ] Reproduction steps documented
- [ ] Affected code/component identified

If cannot reproduce:
- Ask for more information
- Check if already fixed
- Document as "cannot reproduce"

### 3. Diagnose Root Cause
Investigate:
- Read error messages/stack traces
- Add logging to trace execution
- Check recent changes (`git log`)
- Review related tests

Document findings:
```markdown
## Root Cause
[Explanation of why the bug occurs]
```

### 4. Plan the Fix
Before coding:
- Identify files to change
- Consider side effects
- Plan regression test

### 5. Dispatch Implementer

Read `agents/templates/implementer-prompt.md` and fill these variables:

| Variable | Value |
|----------|-------|
| `{TASK_ID}` | Task ID from Step 1 |
| `{TASK_TITLE}` | Task title from Step 1 |
| `{TASK_DESCRIPTION}` | Root cause + reproduction steps + fix strategy from Steps 2-4 |
| `{ACCEPTANCE_CRITERIA}` | See below |
| `{CONTEXT}` | Bug fix context block (see below) |
| `{RELEVANT_SKILL}` | `error-handling` |
| `{WORKING_DIRECTORY}` | Project root |
| `{RESUME_CONTEXT}` | Empty |

**Acceptance criteria to use:**
```
- [ ] Bug described in root cause is fixed
- [ ] Regression test exists (fails without fix, passes with fix)
- [ ] All existing tests pass
- [ ] Fix is minimal — no refactoring, no "while I'm here" changes
- [ ] Commit message follows: fix: [description]
```

**Context block to use:**
```
## Bug Fix Context

### Root Cause
{from Step 3}

### Reproduction Steps
{from Step 2}

### Files to Change
{from Step 4}

### Fix Strategy
{from Step 4}

### MANDATORY: Regression Test
Write a test that reproduces the original bug condition, FAILS without the fix, and PASSES with the fix.
```

Dispatch:
```
Task tool:
  subagent_type: "pokayokay:yokay-implementer"
  description: "Fix: {task title}"
  prompt: [filled implementer-prompt.md]
```

### 6. Verify Result

**Do NOT dispatch review agents. Verify the result yourself:**

1. **Check the implementer's report:**
   - Did it commit? If not, the fix failed — block task and stop.
   - Did it add a regression test? If not, re-dispatch once:
     "Implementation is missing a MANDATORY regression test. Add a test that reproduces the original bug and verifies the fix."

2. **Run the test suite:**
   - If tests pass: proceed to self-review.
   - If tests fail: dispatch `yokay-fixer` with test output. Max 2 attempts.
   - If fixer exhausts retries: block task in ohno and stop.

3. **Self-review the diff:**
   - Does the change match the root cause from Step 3?
   - Is it minimal? No unrelated changes?
   - Is the regression test meaningful (not a trivial assertion)?

### 7. Complete Task
```bash
npx @stevestomp/ohno-cli done <task-id> --notes "Root cause: X. Fixed by: Y. Test: Z"
```

## Output

```markdown
## Bug Fix Complete

**Bug**: [task-id] - [description]
**Root Cause**: [explanation]
**Fix**: [summary of changes]
**Regression Test**: [test file/name]
**Files Changed**: [list]

Commit: [hash] fix: [message]
```

## Anti-Patterns to Avoid

1. **Fixing without reproducing**: May fix wrong thing
2. **Symptom fixing**: Address root cause, not just visible issue
3. **Scope creep**: "While I'm here..." - create separate task
4. **No test**: Bug may recur without regression test

## Options

- `--thorough`: Use full agent pipeline (implementer + spec review + quality review). Reads `bug-fix-pipeline.md`. Higher context cost.
