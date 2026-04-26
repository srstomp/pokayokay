---
name: finishing-branch
description: Use after a task, story, epic, worktree, or development branch is implementation-complete and freshly verified. Presents merge, PR, keep, or discard choices and records evidence before cleanup.
---

# Finishing Branch

Close a development branch deliberately. Do not merge, delete, or mark work
complete until the branch has fresh verification evidence and a clear user or
workflow decision.

## Checklist

1. Inspect status: `git status --short --branch`.
2. Review the diff: `git diff --stat` and targeted file diffs.
3. Run the verification commands relevant to changed code.
4. Confirm task/story/epic acceptance criteria are accounted for.
5. Present the completion choice.
6. Record the decision in ohno handoff or task notes.
7. Clean up only after the selected path succeeds.

## Completion Choices

| Choice | When to use | Action |
|--------|-------------|--------|
| Merge | Local integration is desired now | Merge into the base branch after verification |
| Pull request | Human review or CI is needed | Push branch and open a PR with verification notes |
| Keep | More work remains or user wants a checkpoint | Leave branch/worktree intact and record next steps |
| Discard | Work is abandoned or superseded | Confirm explicitly, then remove branch/worktree |

## Required Report

```markdown
## Branch Finish

**Branch**: [name]
**Base**: [branch]
**Verification**: `command` -> PASS/FAIL
**Changed Files**: [summary]
**Recommended Path**: PR / merge / keep / discard
**Reason**: [short rationale]
```

Destructive cleanup, branch deletion, and discarding changes require explicit
human confirmation unless the user already requested that exact action.
