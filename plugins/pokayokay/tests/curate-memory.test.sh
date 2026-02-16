#!/bin/bash
# Test for curate-memory.sh - MEMORY.md section enforcement
set -e

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

SCRIPT_DIR="$(cd "$(dirname "$0")/../hooks/actions" && pwd)"
SCRIPT="$SCRIPT_DIR/curate-memory.sh"

echo "Testing curate-memory.sh..."

# Test 1: Creates MEMORY.md from template when missing
echo "Test 1: Creates MEMORY.md from template when missing"
MEMORY_DIR="$TEST_DIR/memory1"
mkdir -p "$MEMORY_DIR"
export MEMORY_DIR="$MEMORY_DIR"

OUTPUT=$(bash "$SCRIPT" 2>&1)

if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
  if grep -q "## Completed Work" "$MEMORY_DIR/MEMORY.md" && \
     grep -q "## Key Decisions" "$MEMORY_DIR/MEMORY.md" && \
     grep -q "## Topic Index" "$MEMORY_DIR/MEMORY.md"; then
    echo "  PASS: MEMORY.md created with all sections"
  else
    echo "  FAIL: MEMORY.md missing required sections"
    cat "$MEMORY_DIR/MEMORY.md"
    exit 1
  fi
else
  echo "  FAIL: MEMORY.md not created"
  exit 1
fi

# Test 2: Preserves content outside pokayokay sections
echo "Test 2: Preserves non-pokayokay content"
MEMORY_DIR="$TEST_DIR/memory2"
mkdir -p "$MEMORY_DIR"
export MEMORY_DIR="$MEMORY_DIR"

cat > "$MEMORY_DIR/MEMORY.md" << 'EOF'
# Memory

## My Custom Section
- This is my own note that Claude wrote
- Another custom note

## Completed Work
<!-- pokayokay: managed by session-chain hooks -->
- epic-123: Some work (2026-02-10, COMPLETE)

## Key Decisions
<!-- pokayokay: promoted from session handoffs -->
- Decision A: rationale

## Architecture Notes
<!-- pokayokay: stable project structure -->

## Active Patterns
<!-- pokayokay: graduated to .claude/rules/ when confirmed -->

## Recent Bug Fixes
<!-- pokayokay: rotated, max 5 entries -->

## Topic Index
<!-- pokayokay: links to detail files -->
EOF

OUTPUT=$(bash "$SCRIPT" 2>&1)

if grep -q "My Custom Section" "$MEMORY_DIR/MEMORY.md" && \
   grep -q "This is my own note" "$MEMORY_DIR/MEMORY.md"; then
  echo "  PASS: Non-pokayokay content preserved"
else
  echo "  FAIL: Non-pokayokay content lost"
  cat "$MEMORY_DIR/MEMORY.md"
  exit 1
fi

# Test 3: Enforces section line budget (overflow to archive)
echo "Test 3: Overflow moves old entries to archive"
MEMORY_DIR="$TEST_DIR/memory3"
mkdir -p "$MEMORY_DIR"
export MEMORY_DIR="$MEMORY_DIR"

# Create MEMORY.md with 22 content lines in Completed Work (budget: 20 including header+comment)
{
  echo "# Memory"
  echo ""
  echo "## Completed Work"
  echo "<!-- pokayokay: managed by session-chain hooks -->"
  for i in $(seq 1 22); do
    echo "- epic-$i: Work item $i (2026-01-$((i % 28 + 1)), COMPLETE)"
  done
  echo ""
  echo "## Key Decisions"
  echo "<!-- pokayokay: promoted from session handoffs -->"
  echo "- Keep this decision"
  echo ""
  echo "## Architecture Notes"
  echo "<!-- pokayokay: stable project structure -->"
  echo ""
  echo "## Active Patterns"
  echo "<!-- pokayokay: graduated to .claude/rules/ when confirmed -->"
  echo ""
  echo "## Recent Bug Fixes"
  echo "<!-- pokayokay: rotated, max 5 entries -->"
  echo ""
  echo "## Topic Index"
  echo "<!-- pokayokay: links to detail files -->"
} > "$MEMORY_DIR/MEMORY.md"

OUTPUT=$(bash "$SCRIPT" 2>&1)

# Check that Completed Work section was trimmed
CW_LINES=$(sed -n '/^## Completed Work/,/^## /p' "$MEMORY_DIR/MEMORY.md" | wc -l)
if [ "$CW_LINES" -le 22 ]; then
  echo "  PASS: Completed Work section trimmed to budget"
else
  echo "  FAIL: Completed Work section has $CW_LINES lines (expected <= 22)"
  exit 1
fi

# Check that overflow file was created
if [ -f "$MEMORY_DIR/completed-work-archive.md" ]; then
  echo "  PASS: Overflow archive created"
else
  echo "  FAIL: Overflow archive not created"
  exit 1
fi

# Test 4: Total line count stays under 200
echo "Test 4: Total MEMORY.md stays under 200 lines"
TOTAL_LINES=$(wc -l < "$MEMORY_DIR/MEMORY.md")
if [ "$TOTAL_LINES" -le 200 ]; then
  echo "  PASS: Total lines ($TOTAL_LINES) under 200"
else
  echo "  FAIL: Total lines ($TOTAL_LINES) exceeds 200"
  exit 1
fi

echo ""
echo "All tests passed!"
