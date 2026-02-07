---
description: Diagnose and fix a bug with structured workflow
argument-hint: <bug-description-or-task-id>
---

# Bug Fix Workflow

Fix bug: `$ARGUMENTS`

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

### 5. Dispatch Agent Pipeline

**Do not implement the fix inline. Hand off to the agent pipeline.**

The diagnostic work from Steps 2-4 (root cause, reproduction steps, fix strategy) becomes context for the agents.

Read and follow `skills/project-harness/references/bug-fix-pipeline.md` with these settings:
- **Mode**: `/fix` (max 3 fixer retries, max 3 review cycles, standard quality threshold)
- **Root cause**: from Step 3
- **Reproduction steps**: from Step 2
- **Files to change**: from Step 4
- **Fix strategy**: from Step 4

The pipeline will:
1. Dispatch `yokay-implementer` with bug fix context + mandatory regression test
2. Auto-fix test failures if needed (`yokay-fixer`, max 3 attempts)
3. Verify regression test exists (re-dispatch if missing)
4. Run spec review (`yokay-spec-reviewer`)
5. Run quality review (`yokay-quality-reviewer`)

Wait for pipeline result before proceeding.

### 6. Review Pipeline Result

**If PASS**:
- Implementation committed with regression test
- Spec and quality reviews passed
- Proceed to Step 7

**If FAIL**:
- Task is blocked with reason in ohno
- Review the blocker: `npx @stevestomp/ohno-cli get <task-id>`
- Either resolve manually or re-run `/fix` with additional context

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
**Pipeline**: Implementer + Fixer([attempts]) + Spec Review + Quality Review

Commit: [hash] fix: [message]
```

## Anti-Patterns to Avoid

1. **Fixing without reproducing**: May fix wrong thing
2. **Symptom fixing**: Address root cause, not just visible issue
3. **Scope creep**: "While I'm here..." - create separate task
4. **No test**: Bug may recur without regression test

## Related Commands

- `/pokayokay:quick` - Simpler ad-hoc work
- `/pokayokay:hotfix` - Production emergencies
- `/pokayokay:work` - Continue with other tasks

## Examples

```
/pokayokay:fix Login fails when email has plus sign
/pokayokay:fix Dashboard crashes on empty data
/pokayokay:fix T045
```
