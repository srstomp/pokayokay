#!/usr/bin/env bash
# Test design plugin integration in plan command

set -euo pipefail

echo "Testing design plugin integration in plan command..."

PLAN_FILE="plugins/pokayokay/commands/plan.md"

# Test 1: Design Plugin Integration section exists
echo "Test 1: Design Plugin Integration section exists"
if grep -q "### 4.3 Design Plugin Integration" "$PLAN_FILE"; then
  echo "  PASS: Design Plugin Integration section exists"
else
  echo "  FAIL: Design Plugin Integration section not found"
  exit 1
fi

# Test 2: Section is positioned after Spike Opportunities
echo "Test 2: Section positioned after Spike Opportunities"
# Extract line numbers
DESIGN_LINE=$(grep -n "### 4.3 Design Plugin Integration" "$PLAN_FILE" | cut -d: -f1)
SPIKE_LINE=$(grep -n "### 4.2 Detect Spike Opportunities" "$PLAN_FILE" | cut -d: -f1)

if [[ $DESIGN_LINE -gt $SPIKE_LINE ]]; then
  echo "  PASS: Design integration after Spike Opportunities"
else
  echo "  FAIL: Design integration not positioned correctly"
  exit 1
fi

# Test 3: UI/UX task detection logic documented
echo "Test 3: UI/UX task detection logic"
if grep -q "ui/ux" "$PLAN_FILE" || grep -q "design-heavy" "$PLAN_FILE" || grep -q "UI/UX" "$PLAN_FILE"; then
  echo "  PASS: UI/UX detection logic documented"
else
  echo "  FAIL: UI/UX detection logic not found"
  exit 1
fi

# Test 4: Design plugin availability check documented
echo "Test 4: Design plugin availability check"
if grep -q "design plugin" "$PLAN_FILE" && grep -q "available" "$PLAN_FILE"; then
  echo "  PASS: Plugin availability check documented"
else
  echo "  FAIL: Plugin availability check not found"
  exit 1
fi

# Test 5: Design commands mentioned in skill routing
echo "Test 5: Design commands in skill routing"
if grep -q "/design:ux" "$PLAN_FILE" || grep -q "/design:ui" "$PLAN_FILE"; then
  echo "  PASS: Design commands documented"
else
  echo "  FAIL: Design commands not found"
  exit 1
fi

# Test 6: Design-first workflow suggestion
echo "Test 6: Design-first workflow suggestion"
if grep -q "design-first" "$PLAN_FILE" || grep -q "BEFORE implementation" "$PLAN_FILE"; then
  echo "  PASS: Design-first workflow documented"
else
  echo "  FAIL: Design-first workflow not found"
  exit 1
fi

# Test 7: Plugin installation suggestion when not available
echo "Test 7: Plugin installation suggestion"
if grep -q "claude plugin install design" "$PLAN_FILE" || grep -q "install the design plugin" "$PLAN_FILE"; then
  echo "  PASS: Installation suggestion documented"
else
  echo "  FAIL: Installation suggestion not found"
  exit 1
fi

# Test 8: UI/UX keywords documented
echo "Test 8: UI/UX keywords for detection"
UI_KEYWORDS=("wireframe" "mockup" "component" "visual" "interface")
FOUND_KEYWORDS=0

for keyword in "${UI_KEYWORDS[@]}"; do
  if grep -qi "$keyword" "$PLAN_FILE"; then
    ((FOUND_KEYWORDS++))
  fi
done

if [[ $FOUND_KEYWORDS -ge 2 ]]; then
  echo "  PASS: UI/UX keywords documented ($FOUND_KEYWORDS/5)"
else
  echo "  FAIL: Not enough UI/UX keywords documented ($FOUND_KEYWORDS/5)"
  exit 1
fi

# Test 9: Design routing in keyword detection table
echo "Test 9: Design routing in keyword detection table"
if grep -q "ux-design" "$PLAN_FILE" || grep -q "aesthetic-ui-designer" "$PLAN_FILE"; then
  echo "  PASS: Design skills in skill hints"
else
  echo "  FAIL: Design skills not in skill hints"
  exit 1
fi

# Test 10: Backward compatibility - existing sections unchanged
echo "Test 10: Backward compatibility check"
if grep -q "### 4. Assign Skill Hints" "$PLAN_FILE" && \
   grep -q "### 4.1 Keyword Detection" "$PLAN_FILE" && \
   grep -q "### 4.2 Detect Spike Opportunities" "$PLAN_FILE"; then
  echo "  PASS: Existing sections preserved"
else
  echo "  FAIL: Existing sections modified"
  exit 1
fi

# Test 11: Integration with work command mentioned
echo "Test 11: Work command integration mentioned"
if grep -q "/work" "$PLAN_FILE" || grep -q "work command" "$PLAN_FILE"; then
  echo "  PASS: Work command integration mentioned"
else
  echo "  FAIL: Work command integration not mentioned"
  exit 1
fi

# Test 12: Design tasks can be created during planning
echo "Test 12: Design task creation mentioned"
if grep -q "design task" "$PLAN_FILE" || grep -q "task_type.*ux" "$PLAN_FILE" || grep -q "task_type.*ui" "$PLAN_FILE"; then
  echo "  PASS: Design task creation documented"
else
  echo "  FAIL: Design task creation not documented"
  exit 1
fi

echo ""
echo "All design integration tests passed!"
