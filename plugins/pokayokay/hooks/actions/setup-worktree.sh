#!/bin/bash
# Setup worktree for task based on type
# Environment: TASK_ID, TASK_TYPE, TASK_TITLE, STORY_ID, FORCE_WORKTREE, FORCE_INPLACE

# Smart defaults by task type
WORKTREE_TYPES="feature bug spike"
INPLACE_TYPES="chore docs"

# Skip if forced in-place
if [[ "$FORCE_INPLACE" == "true" ]]; then
    echo "MODE=in-place"
    echo "REASON=--in-place flag"
    exit 0
fi

# Check if task type needs worktree
needs_worktree() {
    [[ "$FORCE_WORKTREE" == "true" ]] && return 0
    [[ " $WORKTREE_TYPES " =~ " $TASK_TYPE " ]] && return 0
    [[ " $INPLACE_TYPES " =~ " $TASK_TYPE " ]] && return 1
    return 0  # Default to worktree for unknown types
}

if ! needs_worktree; then
    echo "MODE=in-place"
    echo "REASON=$TASK_TYPE task"
    exit 0
fi

# Generate worktree name
SLUG=$(echo "$TASK_TITLE" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-$//' | head -c 30)
if [[ -n "$STORY_ID" ]]; then
    NAME="story-${STORY_ID}-${SLUG}"
else
    NAME="task-${TASK_ID}-${SLUG}"
fi

# Check for existing story worktree
if [[ -n "$STORY_ID" ]]; then
    EXISTING=$(git worktree list --porcelain 2>/dev/null | grep -A1 "^worktree " | grep "story-${STORY_ID}-" | head -1 || true)
    if [[ -n "$EXISTING" ]]; then
        # Extract path from the worktree line
        EXISTING_PATH=$(git worktree list 2>/dev/null | grep "story-${STORY_ID}-" | awk '{print $1}' | head -1)
        if [[ -n "$EXISTING_PATH" ]]; then
            echo "MODE=worktree"
            echo "WORKTREE_PATH=$EXISTING_PATH"
            echo "WORKTREE_REUSED=true"
            exit 0
        fi
    fi
fi

# Get base branch
BASE=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || echo "main")

# Check if branch already exists
if git rev-parse --verify "$NAME" >/dev/null 2>&1; then
    # Branch exists, check if worktree exists for it
    EXISTING_PATH=$(git worktree list 2>/dev/null | grep "\[$NAME\]" | awk '{print $1}' || true)
    if [[ -n "$EXISTING_PATH" ]]; then
        echo "MODE=worktree"
        echo "WORKTREE_PATH=$EXISTING_PATH"
        echo "WORKTREE_REUSED=true"
        exit 0
    fi
    # Branch exists but no worktree - this is an error state, skip worktree
    echo "MODE=in-place"
    echo "REASON=branch $NAME already exists"
    exit 0
fi

# Create worktree
WORKTREE_PATH=".worktrees/$NAME"

# Ensure .worktrees directory exists
mkdir -p .worktrees

if ! git worktree add -b "$NAME" "$WORKTREE_PATH" "$BASE" 2>&1; then
    echo "MODE=in-place"
    echo "REASON=worktree creation failed"
    exit 0
fi

# Ensure .worktrees is ignored
if ! git check-ignore -q .worktrees 2>/dev/null; then
    if [[ -f .gitignore ]]; then
        echo -e "\n# Worktrees\n.worktrees/" >> .gitignore
    else
        echo -e "# Worktrees\n.worktrees/" > .gitignore
    fi
fi

# Install dependencies in worktree (non-blocking)
(
    cd "$WORKTREE_PATH" 2>/dev/null || exit 0
    if [[ -f "bun.lockb" ]]; then
        bun install --silent 2>/dev/null || true
    elif [[ -f "pnpm-lock.yaml" ]]; then
        pnpm install --silent 2>/dev/null || true
    elif [[ -f "yarn.lock" ]]; then
        yarn install --silent 2>/dev/null || true
    elif [[ -f "package-lock.json" ]]; then
        npm install --silent 2>/dev/null || true
    fi
) &

# Symlink memory directory so worktree agents can access project memory
PROJECT_DIR=$(pwd)
MAIN_MEMORY_DIR="$HOME/.claude/projects/$(echo "$PROJECT_DIR" | tr '/' '-' | sed 's/^-//')/memory"
WORKTREE_ABS_PATH="$(cd "$WORKTREE_PATH" && pwd)"
WORKTREE_MEMORY_DIR="$HOME/.claude/projects/$(echo "$WORKTREE_ABS_PATH" | tr '/' '-' | sed 's/^-//')/memory"

if [ -d "$MAIN_MEMORY_DIR" ] && [ ! -e "$WORKTREE_MEMORY_DIR" ]; then
    mkdir -p "$(dirname "$WORKTREE_MEMORY_DIR")"
    ln -s "$MAIN_MEMORY_DIR" "$WORKTREE_MEMORY_DIR" 2>/dev/null || true
fi

echo "MODE=worktree"
echo "WORKTREE_PATH=$WORKTREE_PATH"
echo "WORKTREE_BRANCH=$NAME"
echo "WORKTREE_CREATED=true"
echo "BASE_BRANCH=$BASE"
