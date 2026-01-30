#!/usr/bin/env bash
# Test parallel mode argument parsing and documentation

set -euo pipefail

echo "Testing parallel mode documentation..."

WORK_FILE="plugins/pokayokay/commands/work.md"
SKILL_FILE="plugins/pokayokay/skills/project-harness/SKILL.md"

# Test 1: work.md has parallel flag in argument-hint
echo "Test 1: Parallel flag in argument-hint"
if grep -q "\-\-parallel" "$WORK_FILE"; then
  echo "  PASS: --parallel flag documented"
else
  echo "  FAIL: --parallel flag not found in work.md"
  exit 1
fi

# Test 2: work.md has parallel state tracking section
echo "Test 2: Parallel state tracking section"
if grep -q "Parallel State Tracking" "$WORK_FILE"; then
  echo "  PASS: State tracking section exists"
else
  echo "  FAIL: State tracking section not found"
  exit 1
fi

# Test 3: work.md has parallel dispatch documentation
echo "Test 3: Parallel dispatch in work loop"
if grep -q "Parallel Mode (parallel > 1)" "$WORK_FILE"; then
  echo "  PASS: Parallel mode in work loop"
else
  echo "  FAIL: Parallel work loop not found"
  exit 1
fi

# Test 4: Git conflict handling section exists
echo "Test 4: Git conflict handling"
if grep -q "Git Conflict Handling" "$WORK_FILE"; then
  echo "  PASS: Conflict handling documented"
else
  echo "  FAIL: Conflict handling not found"
  exit 1
fi

# Test 5: project-harness has parallel execution docs
echo "Test 5: Project harness parallel docs"
if grep -q "Parallel Execution" "$SKILL_FILE"; then
  echo "  PASS: Parallel execution in skill"
else
  echo "  FAIL: Parallel execution not in skill"
  exit 1
fi

# Test 6: Parallel dispatch example exists
echo "Test 6: Parallel dispatch template"
TEMPLATE="plugins/pokayokay/agents/templates/parallel-dispatch-example.md"
if [[ -f "$TEMPLATE" ]]; then
  echo "  PASS: Template exists"
else
  echo "  FAIL: Template not found"
  exit 1
fi

echo ""
echo "All parallel mode tests passed!"
