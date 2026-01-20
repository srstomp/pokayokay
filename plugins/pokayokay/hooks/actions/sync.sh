#!/bin/bash
# Sync ohno kanban state
# Called by: post-task, post-session hooks

set -e

echo "Syncing kanban..."

# Try MCP first (if available), fall back to CLI
if command -v ohno &> /dev/null; then
  npx @stevestomp/ohno-cli sync
  echo "✓ Kanban synced via CLI"
else
  echo "⚠️ ohno CLI not available, skipping sync"
fi
