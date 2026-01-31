---
name: worktrees
description: Git worktree management for isolated task development
---

# Worktrees Skill

Guide for managing git worktrees in pokayokay.

## When Worktrees Are Created

| Task Type | Default | Override |
|-----------|---------|----------|
| feature | Worktree | --in-place |
| bug | Worktree | --in-place |
| spike | Worktree | --in-place |
| chore | In-place | --worktree |
| docs | In-place | --worktree |
| test | Inherits | explicit flag |

## Story-Based Reuse

Tasks within the same story share a worktree:

```
Story 12: User Authentication
├── Task 42: Login form      → .worktrees/story-12-user-auth/
├── Task 43: Session handling → .worktrees/story-12-user-auth/ (reused)
└── Task 44: Logout button   → .worktrees/story-12-user-auth/ (reused)
```

Benefits:
- Related changes stay together
- No merge conflicts between related tasks
- Single PR for entire story
- Cleaner git history

## Worktree Lifecycle

```
┌─────────────┐
│ Task starts │
└──────┬──────┘
       │
       ▼
┌──────────────────┐     NO      ┌──────────────┐
│ Needs worktree?  │────────────►│ Work in-place│
└──────┬───────────┘             └──────────────┘
       │ YES
       ▼
┌──────────────────┐     YES     ┌──────────────┐
│ Story worktree   │────────────►│ Reuse it     │
│ exists?          │             └──────────────┘
└──────┬───────────┘
       │ NO
       ▼
┌──────────────────┐
│ Create worktree  │
│ Install deps     │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Work on task     │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Task complete    │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐     YES     ┌──────────────┐
│ Part of story?   │────────────►│ Continue to  │
│                  │             │ next task    │
└──────┬───────────┘             └──────────────┘
       │ NO (or story done)
       ▼
┌──────────────────┐
│ Completion prompt│
│ merge/PR/keep/   │
│ discard          │
└──────────────────┘
```

## Directory Structure

```
project/
├── .worktrees/           # All worktrees (auto-ignored)
│   ├── story-12-user-auth/
│   │   ├── src/
│   │   ├── tests/
│   │   └── ...
│   └── task-51-email/
├── .gitignore            # Contains ".worktrees/"
└── src/                  # Main worktree
```

## Completion Options

### Merge to Default Branch

Direct merge, good for:
- Small features
- Bug fixes
- Team doesn't require PRs

```bash
git checkout main
git merge --no-ff story-12-user-auth
git worktree remove .worktrees/story-12-user-auth
git branch -d story-12-user-auth
```

### Create Pull Request

Pushes branch, creates PR via gh CLI:
- Requires review
- CI/CD validation
- Keeps worktree for iterations

```bash
git push -u origin story-12-user-auth
gh pr create --title "feat: user authentication" --body "..."
```

### Keep Worktree

No action, useful when:
- Work is incomplete
- Waiting for external input
- Planning to continue later

### Discard Work

Force removes all changes:
- Failed experiment
- Requirements changed
- Duplicate work

```bash
git worktree remove --force .worktrees/story-12-user-auth
git branch -D story-12-user-auth
```

## Dependency Installation

On worktree creation, dependencies auto-install:

| Lockfile | Command |
|----------|---------|
| bun.lockb | bun install |
| pnpm-lock.yaml | pnpm install |
| yarn.lock | yarn install |
| package-lock.json | npm install |
| Cargo.toml | cargo build |
| go.mod | go mod download |
| pyproject.toml | poetry install |
| requirements.txt | pip install -r requirements.txt |
| Gemfile | bundle install |

Monorepos: All detected languages are installed.

## Troubleshooting

### "Worktree already exists"

Another worktree uses this branch:
```bash
git worktree list  # Find which worktree
```

### "Permission denied"

Worktree might be locked:
```bash
rm .git/worktrees/<name>/locked
```

### Dependency install fails

Options:
1. Retry with different flags (--legacy-peer-deps)
2. Skip and install manually
3. Abort and investigate

### Merge conflicts

If merging fails:
```bash
git checkout main
git merge story-12-user-auth
# Resolve conflicts
git add .
git commit
git worktree remove .worktrees/story-12-user-auth
```
