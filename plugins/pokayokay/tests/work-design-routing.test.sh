#!/usr/bin/env bash
# Test design task routing in work command

set -euo pipefail

echo "Testing design task routing in work command..."

WORK_FILE="plugins/pokayokay/commands/work.md"

# Test 1: Design Task Routing section exists
echo "Test 1: Design Task Routing section exists"
if grep -q "### 2.5 Design Task Routing (Conditional)" "$WORK_FILE"; then
  echo "  PASS: Design Task Routing section exists"
else
  echo "  FAIL: Design Task Routing section not found"
  exit 1
fi

# Test 2: Section is positioned before Brainstorm Gate
echo "Test 2: Section positioned before Brainstorm Gate"
# Extract line numbers
DESIGN_LINE=$(grep -n "### 2.5 Design Task Routing" "$WORK_FILE" | cut -d: -f1)
BRAINSTORM_LINE=$(grep -n "### 3. Brainstorm Gate" "$WORK_FILE" | cut -d: -f1)

if [[ $DESIGN_LINE -lt $BRAINSTORM_LINE ]]; then
  echo "  PASS: Design routing before Brainstorm Gate"
else
  echo "  FAIL: Design routing not positioned correctly"
  exit 1
fi

# Test 3: Design task detection logic documented
echo "Test 3: Design task detection logic"
if grep -q "is_design_task" "$WORK_FILE" || grep -q "design task detection" "$WORK_FILE"; then
  echo "  PASS: Design detection logic documented"
else
  echo "  FAIL: Design detection logic not found"
  exit 1
fi

# Test 4: Design plugin availability check documented
echo "Test 4: Design plugin availability check"
if grep -q "design plugin" "$WORK_FILE" && grep -q "available" "$WORK_FILE"; then
  echo "  PASS: Plugin availability check documented"
else
  echo "  FAIL: Plugin availability check not found"
  exit 1
fi

# Test 5: Routing to /design:* commands documented
echo "Test 5: Routing to /design:* commands"
if grep -q "/design:ux" "$WORK_FILE" || grep -q "/design:ui" "$WORK_FILE"; then
  echo "  PASS: Design command routing documented"
else
  echo "  FAIL: Design command routing not found"
  exit 1
fi

# Test 6: Plugin installation suggestion when not available
echo "Test 6: Plugin installation suggestion"
if grep -q "claude plugin install design" "$WORK_FILE" || grep -q "install the design plugin" "$WORK_FILE"; then
  echo "  PASS: Installation suggestion documented"
else
  echo "  FAIL: Installation suggestion not found"
  exit 1
fi

# Test 7: Design task types documented
echo "Test 7: Design task types listed"
DESIGN_TYPES=("ux" "ui" "persona" "accessibility" "a11y")
FOUND_TYPES=0

for type in "${DESIGN_TYPES[@]}"; do
  if grep -q "$type" "$WORK_FILE"; then
    ((FOUND_TYPES++))
  fi
done

if [[ $FOUND_TYPES -ge 3 ]]; then
  echo "  PASS: Design task types documented ($FOUND_TYPES/5)"
else
  echo "  FAIL: Not enough design types documented ($FOUND_TYPES/5)"
  exit 1
fi

# Test 8: Design keywords documented
echo "Test 8: Design keywords for detection"
if grep -q "wireframe" "$WORK_FILE" || grep -q "mockup" "$WORK_FILE" || grep -q "prototype" "$WORK_FILE"; then
  echo "  PASS: Design keywords documented"
else
  echo "  FAIL: Design keywords not found"
  exit 1
fi

# Test 9: User prompt when plugin not available
echo "Test 9: User prompt for missing plugin"
if grep -q "Continue without design plugin" "$WORK_FILE" || grep -q "design plugin not available" "$WORK_FILE"; then
  echo "  PASS: User prompt documented"
else
  echo "  FAIL: User prompt not found"
  exit 1
fi

# Test 10: Backward compatibility - existing sections unchanged
echo "Test 10: Backward compatibility check"
if grep -q "### 2. Route to Skill" "$WORK_FILE" && \
   grep -q "### 3. Brainstorm Gate" "$WORK_FILE" && \
   grep -q "### 4. Dispatch Implementer Subagent" "$WORK_FILE"; then
  echo "  PASS: Existing sections preserved"
else
  echo "  FAIL: Existing sections modified"
  exit 1
fi

echo ""
echo "All design routing tests passed!"
