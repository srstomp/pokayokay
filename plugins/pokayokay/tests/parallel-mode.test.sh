#!/usr/bin/env bash
# Test parallel mode argument parsing and documentation

set -euo pipefail

echo "Testing parallel mode documentation..."

WORK_FILE="plugins/pokayokay/commands/work.md"
SKILL_FILE="plugins/pokayokay/skills/work-session/SKILL.md"

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

# Test 5: work-session has parallel execution docs
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

# Test 7: Structured conflict check (Packages trailer) documented before heuristic
echo "Test 7: Structured conflict check before heuristic"
STRUCTURED_LINE=$(grep -n "Structured conflict check" "$WORK_FILE" | head -1 | cut -d: -f1)
HEURISTIC_LINE=$(grep -n "detect_file_conflicts" "$WORK_FILE" | head -1 | cut -d: -f1)

if [[ -z "$STRUCTURED_LINE" ]]; then
  echo "  FAIL: 'Structured conflict check' not found in work.md"
  exit 1
fi
if [[ -z "$HEURISTIC_LINE" ]]; then
  echo "  FAIL: detect_file_conflicts heuristic not found in work.md"
  exit 1
fi
if [[ $STRUCTURED_LINE -lt $HEURISTIC_LINE ]]; then
  echo "  PASS: Structured check documented before the regex heuristic"
else
  echo "  FAIL: Structured check (line $STRUCTURED_LINE) not before heuristic (line $HEURISTIC_LINE)"
  exit 1
fi

# Test 8: Both checks unioned (heuristic still runs on tagged tasks)
echo "Test 8: Structured + heuristic conflict sets unioned"
if grep -q "detect_package_conflicts(queued_tasks) + detect_file_conflicts(queued_tasks)" "$WORK_FILE"; then
  echo "  PASS: Conflict sets unioned"
else
  echo "  FAIL: Union of structured + heuristic conflict sets not found"
  exit 1
fi

# Test 9: plan.md instructs the Packages: description trailer
echo "Test 9: plan.md Packages: trailer instruction"
PLAN_FILE="plugins/pokayokay/commands/plan.md"
if grep -q "Packages: <comma-separated packages_touched>" "$PLAN_FILE"; then
  echo "  PASS: Packages: trailer documented in plan.md"
else
  echo "  FAIL: Packages: trailer instruction not found in plan.md"
  exit 1
fi

# Test 10: parallel-execution.md documents the two-tier conflict check
echo "Test 10: Two-tier conflict detection in parallel-execution.md"
PARALLEL_REF="plugins/pokayokay/skills/work-session/references/parallel-execution.md"
if grep -q "Conflict Detection (Two-Tier)" "$PARALLEL_REF" && grep -q "Packages:" "$PARALLEL_REF"; then
  echo "  PASS: Two-tier conflict detection documented"
else
  echo "  FAIL: Two-tier conflict detection not documented in parallel-execution.md"
  exit 1
fi

echo ""
echo "All parallel mode tests passed!"
