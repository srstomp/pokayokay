#!/bin/bash
# Test script for summary.md command validation
# Tests that the command file has proper structure

set -e

COMMAND_FILE="/Users/sis4m4/Projects/stevestomp/pokayokay/plugins/yokay-evals/commands/summary.md"

echo "Testing summary command structure..."

# Test 1: File exists
if [ ! -f "$COMMAND_FILE" ]; then
    echo "FAIL: Command file does not exist at $COMMAND_FILE"
    exit 1
fi
echo "PASS: Command file exists"

# Test 2: Has frontmatter
if ! grep -q "^---" "$COMMAND_FILE"; then
    echo "FAIL: Missing frontmatter"
    exit 1
fi
echo "PASS: Has frontmatter"

# Test 3: Has description in frontmatter
if ! grep -q "^description:" "$COMMAND_FILE"; then
    echo "FAIL: Missing description in frontmatter"
    exit 1
fi
echo "PASS: Has description field"

# Test 4: Has argument-hint in frontmatter
if ! grep -q "^argument-hint:" "$COMMAND_FILE"; then
    echo "FAIL: Missing argument-hint in frontmatter"
    exit 1
fi
echo "PASS: Has argument-hint field"

# Test 5: Has main heading
if ! grep -q "^# " "$COMMAND_FILE"; then
    echo "FAIL: Missing main heading"
    exit 1
fi
echo "PASS: Has main heading"

# Test 6: Contains reference to grade reports
if ! grep -qi "skill-clarity" "$COMMAND_FILE"; then
    echo "FAIL: Missing reference to skill-clarity reports"
    exit 1
fi
echo "PASS: References grade reports"

# Test 7: Contains reference to failure analysis
if ! grep -qi "ANALYSIS.md\|failures" "$COMMAND_FILE"; then
    echo "FAIL: Missing reference to failure analysis"
    exit 1
fi
echo "PASS: References failure analysis"

# Test 8: Contains bash command examples
if ! grep -q '```bash' "$COMMAND_FILE"; then
    echo "FAIL: Missing bash code blocks"
    exit 1
fi
echo "PASS: Contains bash examples"

# Test 9: Contains yokay-evals CLI usage
if ! grep -q "yokay-evals" "$COMMAND_FILE"; then
    echo "FAIL: Missing yokay-evals CLI references"
    exit 1
fi
echo "PASS: References yokay-evals CLI"

# Test 10: Contains quality metrics section
if ! grep -qi "quality\|metrics\|summary" "$COMMAND_FILE"; then
    echo "FAIL: Missing quality metrics content"
    exit 1
fi
echo "PASS: Contains quality metrics references"

echo ""
echo "All tests passed!"
