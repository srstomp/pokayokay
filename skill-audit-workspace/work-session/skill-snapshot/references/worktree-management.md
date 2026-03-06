# Worktree Management

## Worktree Isolation

After getting the next task, decide whether to isolate work in a git worktree.

### Decision Priority

Evaluate in order - first match wins:

```
1. Explicit flags (from /work command arguments)
   --worktree    → Always use worktree
   --in-place    → Never use worktree

2. Smart defaults by task type
   feature, bug, spike → Worktree
   chore, docs         → In-place
   test                → Inherit from sibling tasks in story

3. Fallback
   Unknown type → Worktree (safer default)
```

### Worktree Setup

When using a worktree:

**Step 1: Check for existing story worktree**
```bash
# If task belongs to a story, check for reusable worktree
git worktree list --porcelain | grep "story-{story_id}-"
```
If found, `cd` into existing worktree and skip to task work.

**Step 2: Create new worktree**
```bash
# Generate name from task/story
NAME="task-{id}-{slug}" or "story-{story_id}-{slug}"

# Get base branch
BASE=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's|refs/remotes/origin/||')

# Create worktree with new branch
git worktree add -b $NAME .worktrees/$NAME $BASE
```

**Step 3: Ensure ignored**
```bash
# Add to .gitignore if not already
echo ".worktrees/" >> .gitignore  # (check first)
```

**Step 4: Install dependencies**
```bash
cd .worktrees/$NAME

# Detect package manager and install
if [ -f bun.lockb ]; then bun install
elif [ -f pnpm-lock.yaml ]; then pnpm install
elif [ -f yarn.lock ]; then yarn install
elif [ -f package-lock.json ]; then npm install
fi
```

**Step 5: Announce and continue**
```markdown
## Worktree Setup

Creating worktree for feature task: {title}
  ✓ Branch created: task-42-user-auth
  ✓ Worktree ready at .worktrees/task-42-user-auth
  ✓ Dependencies installed (bun, 4.2s)

Ready to work.
```

### In-Place Work

When working in-place (chore/docs or `--in-place` flag):

```markdown
## Working In-Place

Chore task: {title}
Working directly on current branch (no worktree).
```

No worktree setup, no completion prompts.

## Worktree Completion

After a task completes (reviews pass), handle the worktree based on context.

### Task Within a Story

Commit and continue - no prompt needed:

```markdown
Task 42 complete (part of Story 12).

  ✓ Committed to story-12-user-auth branch

Story has 2 more tasks remaining.
Continue with next task? [Y/n]
```

Stay in worktree for remaining story tasks.

### Standalone Task or Story Complete

Prompt user for worktree disposition:

```markdown
[Task 42 complete / Story 12 complete]

What would you like to do?

  1. Merge to main (Recommended)
  2. Create Pull Request
  3. Keep worktree (continue later)
  4. Discard work

Which option?
```

**Option implementations:**

| Option | Commands |
|--------|----------|
| Merge | `git checkout main && git merge --no-ff {branch} && git worktree remove .worktrees/{name} && git branch -d {branch}` |
| PR | `git push -u origin {branch} && gh pr create --title "{task-title}" --body "Closes task #{id}"` |
| Keep | Do nothing - worktree remains for later |
| Discard | `git worktree remove --force .worktrees/{name} && git branch -D {branch}` |

### In-Place Completion

If working in-place, skip worktree prompts entirely. Standard commit flow only.
