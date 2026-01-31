#!/usr/bin/env bash

# Test: testing-strategy skill integrates with a11y-audit.md
#
# Verifies that:
# 1. The testing-strategy skill mentions checking for design artifacts
# 2. The skill includes instructions for consuming a11y-audit.md
# 3. The skill describes generating accessibility test cases from audit findings
# 4. The skill maintains backward compatibility

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_FILE="/Users/sis4m4/Projects/stevestomp/pokayokay/plugins/pokayokay/skills/testing-strategy/SKILL.md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

test_count=0
pass_count=0
fail_count=0

run_test() {
  local test_name="$1"
  local test_command="$2"

  test_count=$((test_count + 1))
  echo -e "\n${YELLOW}Test ${test_count}: ${test_name}${NC}"

  if eval "$test_command"; then
    echo -e "${GREEN}✓ PASS${NC}"
    pass_count=$((pass_count + 1))
    return 0
  else
    echo -e "${RED}✗ FAIL${NC}"
    fail_count=$((fail_count + 1))
    return 1
  fi
}

# Test 1: Skill file exists and is readable
run_test "Skill file exists" "[ -f '$SKILL_FILE' ]"

# Test 2: Skill mentions design artifact integration
run_test "Skill mentions design artifacts" \
  "grep -qi 'design artifact' '$SKILL_FILE'"

# Test 3: Skill mentions a11y-audit.md
run_test "Skill references a11y-audit.md" \
  "grep -q 'a11y-audit\.md' '$SKILL_FILE'"

# Test 4: Skill includes instructions for checking if a11y-audit exists
run_test "Skill includes check for a11y-audit existence" \
  "grep -qi 'check.*\.claude/design' '$SKILL_FILE' || grep -qi 'if.*a11y-audit' '$SKILL_FILE'"

# Test 5: Skill describes generating accessibility test cases
run_test "Skill describes generating accessibility test cases" \
  "grep -qi 'accessibility test' '$SKILL_FILE' && grep -qi 'audit.*finding' '$SKILL_FILE'"

# Test 6: Skill maintains core testing strategy content (backward compatibility)
run_test "Skill maintains test pyramid section" \
  "grep -q 'Test Pyramid' '$SKILL_FILE'"

# Test 7: Skill maintains component testing section
run_test "Skill maintains component testing guidance" \
  "grep -q 'Component Tests' '$SKILL_FILE' || grep -q 'component test' '$SKILL_FILE'"

# Test 8: Skill mentions WCAG or accessibility standards
run_test "Skill references WCAG or accessibility standards" \
  "grep -qi 'wcag' '$SKILL_FILE' || grep -qi 'accessibility.*standard' '$SKILL_FILE'"

# Test 9: Skill includes examples of accessibility test cases
run_test "Skill includes accessibility test examples" \
  "grep -qi 'aria' '$SKILL_FILE' || grep -qi 'keyboard.*nav' '$SKILL_FILE' || grep -qi 'screen reader' '$SKILL_FILE'"

# Summary
echo -e "\n============================================================"
echo -e "Test Summary:"
echo -e "  Total:  ${test_count}"
echo -e "  ${GREEN}Passed: ${pass_count}${NC}"
echo -e "  ${RED}Failed: ${fail_count}${NC}"
echo -e "============================================================\n"

if [ "$fail_count" -eq 0 ]; then
  echo -e "${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "${RED}Some tests failed.${NC}"
  exit 1
fi
