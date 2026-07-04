#!/bin/bash
# Sync ohno kanban state
# Called by: post-task, post-session hooks

set -e

echo "Syncing kanban..."

# Sync via ohno CLI (runs through npx; no global binary required)
if command -v npx &> /dev/null; then
  if npx @stevestomp/ohno-cli sync; then
    echo "✓ Kanban synced via CLI"
  else
    echo "⚠️ Kanban sync failed (continuing)"
  fi
else
  echo "⚠️ npx not available, skipping sync"
fi
