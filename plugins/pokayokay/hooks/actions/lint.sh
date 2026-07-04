#!/bin/bash
# Run linter safely
# Called by: pre-commit hooks (via bridge.py handle_pre_commit)
#
# Exit-code contract (see HOOKS.md): 0 = success, 2 = error (blocks the
# commit). Lint problems are advisory: they surface to the agent in the
# output but this script always exits 0 so a lint failure (or a missing
# lint runner) never blocks the commit.

LINT_LABEL=""
LINT_CMD=""

# Detect linter
if [ -f "package.json" ]; then
  if grep -q '"lint"' package.json; then
    # Select the package runner from the lockfile instead of assuming bun,
    # so non-bun projects don't get a fabricated "lint failed" every commit.
    if [ -f "bun.lockb" ] || [ -f "bun.lock" ]; then
      RUNNER="bun"
    elif [ -f "pnpm-lock.yaml" ]; then
      RUNNER="pnpm"
    elif [ -f "yarn.lock" ]; then
      RUNNER="yarn"
    else
      RUNNER="npm"
    fi
    if ! command -v "$RUNNER" > /dev/null 2>&1; then
      echo "⚠️ Lint runner not found: ${RUNNER} is not installed (skipping lint)"
      exit 0
    fi
    LINT_LABEL="linter (${RUNNER} run lint)"
    LINT_CMD="$RUNNER run lint"
  elif grep -q 'biome' package.json; then
    if ! command -v npx > /dev/null 2>&1; then
      echo "⚠️ Lint runner not found: npx is not installed (skipping lint)"
      exit 0
    fi
    LINT_LABEL="Biome"
    LINT_CMD="npx biome check ."
  elif grep -q 'eslint' package.json; then
    if ! command -v npx > /dev/null 2>&1; then
      echo "⚠️ Lint runner not found: npx is not installed (skipping lint)"
      exit 0
    fi
    LINT_LABEL="ESLint"
    LINT_CMD="npx eslint ."
  else
    echo "✓ No linter configured"
    exit 0
  fi
else
  echo "✓ No package.json, skipping lint"
  exit 0
fi

echo "Running ${LINT_LABEL}..."
OUTPUT=$($LINT_CMD 2>&1)
RC=$?

if [ "$RC" -ne 0 ]; then
  echo "⚠️ ${LINT_LABEL} failed (exit ${RC}):"
  echo "$OUTPUT" | tail -n 20
  exit 0
fi

echo "✓ ${LINT_LABEL} passed"
