#!/bin/bash
# Test for template.yaml validation
# Ensures the example template is valid YAML and contains all required fields

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/template.yaml"

echo "Testing template.yaml..."

# Test 1: Verify template file exists
echo "Test 1: Template file exists"
if [ -f "$TEMPLATE_FILE" ]; then
  echo "  PASS: template.yaml exists"
else
  echo "  FAIL: template.yaml not found at $TEMPLATE_FILE"
  exit 1
fi

# Test 2: Verify it's valid YAML
echo "Test 2: Valid YAML syntax"
if command -v python3 &> /dev/null; then
  if python3 -c "import yaml; yaml.safe_load(open('$TEMPLATE_FILE'))" 2>/dev/null; then
    echo "  PASS: Valid YAML syntax"
  else
    echo "  FAIL: Invalid YAML syntax"
    exit 1
  fi
else
  echo "  SKIP: python3 not available for YAML validation"
fi

# Test 3: Verify required fields are present
echo "Test 3: Required fields present"
REQUIRED_FIELDS=("id:" "category:" "discovered:" "severity:" "context:" "failure:" "evidence:" "eval_criteria:")
MISSING_FIELDS=()

for field in "${REQUIRED_FIELDS[@]}"; do
  if ! grep -q "^${field}" "$TEMPLATE_FILE"; then
    MISSING_FIELDS+=("$field")
  fi
done

if [ ${#MISSING_FIELDS[@]} -eq 0 ]; then
  echo "  PASS: All required fields present"
else
  echo "  FAIL: Missing required fields: ${MISSING_FIELDS[*]}"
  exit 1
fi

# Test 4: Verify comments are present (template should be well-documented)
echo "Test 4: Template has documentation comments"
COMMENT_COUNT=$(grep -c "^#" "$TEMPLATE_FILE" || echo "0")
if [ "$COMMENT_COUNT" -gt 10 ]; then
  echo "  PASS: Template has $COMMENT_COUNT comment lines (well-documented)"
else
  echo "  FAIL: Template has only $COMMENT_COUNT comment lines (needs more documentation)"
  exit 1
fi

# Test 5: Verify example uses MT-001 (missed-tasks example from design doc)
echo "Test 5: Uses MT-001 example"
if grep -q "id: MT-001" "$TEMPLATE_FILE"; then
  echo "  PASS: Uses MT-001 example ID"
else
  echo "  FAIL: Should use MT-001 as example ID"
  exit 1
fi

# Test 6: Verify category matches ID prefix
echo "Test 6: Category matches ID prefix"
if grep -q "category: missed-tasks" "$TEMPLATE_FILE"; then
  echo "  PASS: Category is missed-tasks"
else
  echo "  FAIL: Category should be missed-tasks for MT-001"
  exit 1
fi

# Test 7: Verify eval_criteria has both code-based and model-based examples
echo "Test 7: Eval criteria includes both check types"
if grep -q "type: code-based" "$TEMPLATE_FILE" && grep -q "type: model-based" "$TEMPLATE_FILE"; then
  echo "  PASS: Both code-based and model-based eval criteria present"
else
  echo "  FAIL: Missing code-based or model-based eval criteria examples"
  exit 1
fi

echo ""
echo "All template validation tests passed!"
