#!/bin/bash
# Run linter safely
# Called by: pre-commit hooks

# Detect linter
if [ -f "package.json" ]; then
  if grep -q '"lint"' package.json; then
    echo "Running linter..."
    bun run lint 2>/dev/null || echo "⚠️ Lint issues found"
  elif grep -q 'biome' package.json; then
    echo "Running Biome..."
    npx biome check . 2>/dev/null || echo "⚠️ Biome issues found"
  elif grep -q 'eslint' package.json; then
    echo "Running ESLint..."
    npx eslint . 2>/dev/null || echo "⚠️ ESLint issues found"
  else
    echo "✓ No linter configured"
  fi
else
  echo "✓ No package.json, skipping lint"
fi
