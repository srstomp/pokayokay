#!/bin/bash

# Pressure Test Runner
# Runs through pressure test scenarios and tracks results

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_FILE="$SCRIPT_DIR/results-$(date +%Y%m%d-%H%M%S).md"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Pressure Testing Framework${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "This runner helps evaluate Claude's resistance to pressure."
echo "Each scenario must be tested manually in a Claude Code session."
echo ""
echo "Results will be saved to: $RESULTS_FILE"
echo ""

# Initialize results file
cat > "$RESULTS_FILE" << EOF
# Pressure Test Results

**Date**: $(date)
**Tester**: [Your name]

## Summary

| Pattern | Scenario | Result | Notes |
|---------|----------|--------|-------|
EOF

# Function to display a scenario
display_scenario() {
    local file=$1
    local name=$(grep "^name:" "$file" | sed 's/name: *//' | tr -d '"')
    local pattern=$(grep "^pattern:" "$file" | sed 's/pattern: *//')
    local pressure_type=$(grep "^pressure_type:" "$file" | sed 's/pressure_type: *//')

    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}Scenario: ${name}${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "Pattern: ${BLUE}${pattern}${NC}"
    echo -e "Pressure Type: ${BLUE}${pressure_type}${NC}"
    echo ""

    # Extract and display context
    echo -e "${GREEN}Context:${NC}"
    sed -n '/^context:/,/^[a-z_]*:/p' "$file" | head -n -1 | tail -n +2 | sed 's/^  //'
    echo ""

    # Extract and display pressure prompt
    echo -e "${RED}Pressure Prompt:${NC}"
    sed -n '/^pressure_prompt:/,/^[a-z_]*:/p' "$file" | head -n -1 | tail -n +2 | sed 's/^  //'
    echo ""

    # Extract and display expected behavior
    echo -e "${GREEN}Expected Behavior:${NC}"
    sed -n '/^expected_behavior:/,/^[a-z_]*:/p' "$file" | head -n -1 | tail -n +2 | sed 's/^  - /  ✓ /'
    echo ""

    # Extract and display failure indicators
    echo -e "${RED}Failure Indicators:${NC}"
    sed -n '/^failure_indicators:/,/^[a-z_]*:/p' "$file" | head -n -1 | tail -n +2 | sed 's/^  - /  ✗ /'
    echo ""

    # Extract evaluation prompt
    echo -e "${YELLOW}Evaluation Question:${NC}"
    sed -n '/^evaluation_prompt:/,/^[a-z_]*:/p' "$file" | head -n -1 | tail -n +2 | sed 's/^  //'
    echo ""
}

# Function to get result
get_result() {
    local file=$1
    local name=$(grep "^name:" "$file" | sed 's/name: *//' | tr -d '"')
    local pattern=$(grep "^pattern:" "$file" | sed 's/pattern: *//')

    echo ""
    echo -e "${YELLOW}How did Claude respond?${NC}"
    echo "  [P] PASS - Claude followed the pattern despite pressure"
    echo "  [F] FAIL - Claude caved to pressure and skipped the pattern"
    echo "  [S] SKIP - Did not test this scenario"
    echo ""
    read -p "Result (P/F/S): " result

    case $result in
        [Pp])
            echo -e "${GREEN}✓ PASSED${NC}"
            ((PASSED++))
            read -p "Notes (optional): " notes
            echo "| $pattern | $name | ✅ PASS | $notes |" >> "$RESULTS_FILE"
            ;;
        [Ff])
            echo -e "${RED}✗ FAILED${NC}"
            ((FAILED++))
            read -p "What went wrong? " notes
            echo "| $pattern | $name | ❌ FAIL | $notes |" >> "$RESULTS_FILE"

            # Show skill to strengthen
            echo ""
            echo -e "${YELLOW}Skill to strengthen:${NC}"
            sed -n '/^skill_to_strengthen:/,/^[a-z_]*:/p' "$file" | head -n -1 | tail -n +2 | sed 's/^  //'
            ;;
        [Ss])
            echo -e "${BLUE}○ SKIPPED${NC}"
            ((SKIPPED++))
            echo "| $pattern | $name | ⏭ SKIP | - |" >> "$RESULTS_FILE"
            ;;
        *)
            echo "Invalid input, marking as skipped"
            ((SKIPPED++))
            echo "| $pattern | $name | ⏭ SKIP | Invalid input |" >> "$RESULTS_FILE"
            ;;
    esac

    ((TOTAL++))
}

# Interactive or batch mode
echo -e "${YELLOW}Select mode:${NC}"
echo "  [I] Interactive - Go through each scenario one by one"
echo "  [L] List - Just list all scenarios"
echo "  [S] Single - Run a single scenario by name"
echo ""
read -p "Mode (I/L/S): " mode

case $mode in
    [Ll])
        echo ""
        echo -e "${BLUE}Available Scenarios:${NC}"
        echo ""
        for file in "$SCRIPT_DIR"/*.yaml; do
            if [ -f "$file" ]; then
                name=$(grep "^name:" "$file" | sed 's/name: *//' | tr -d '"')
                pattern=$(grep "^pattern:" "$file" | sed 's/pattern: *//')
                pressure=$(grep "^pressure_type:" "$file" | sed 's/pressure_type: *//')
                basename=$(basename "$file")
                echo "  $basename"
                echo "    Name: $name"
                echo "    Pattern: $pattern | Pressure: $pressure"
                echo ""
            fi
        done
        exit 0
        ;;
    [Ss])
        read -p "Scenario file name (e.g., subagent-time.yaml): " scenario_name
        file="$SCRIPT_DIR/$scenario_name"
        if [ -f "$file" ]; then
            display_scenario "$file"
            echo ""
            echo -e "${YELLOW}Test this scenario in Claude Code, then record result.${NC}"
            get_result "$file"
        else
            echo -e "${RED}Scenario not found: $scenario_name${NC}"
            exit 1
        fi
        ;;
    [Ii]|*)
        echo ""
        echo -e "${YELLOW}Running all scenarios interactively...${NC}"
        echo "For each scenario:"
        echo "  1. Read the context and pressure prompt"
        echo "  2. Test it in a fresh Claude Code session with /pokayokay:work"
        echo "  3. Record whether Claude passed or failed"
        echo ""
        read -p "Press Enter to begin..."

        for file in "$SCRIPT_DIR"/*.yaml; do
            if [ -f "$file" ]; then
                display_scenario "$file"
                echo ""
                echo -e "${YELLOW}Test this scenario in Claude Code, then record result.${NC}"
                get_result "$file"
                echo ""
                read -p "Press Enter for next scenario (or Ctrl+C to stop)..."
            fi
        done
        ;;
esac

# Final summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}    Test Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Total: $TOTAL"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo -e "${BLUE}Skipped: $SKIPPED${NC}"
echo ""

# Add summary to results file
cat >> "$RESULTS_FILE" << EOF

## Final Summary

- **Total Scenarios**: $TOTAL
- **Passed**: $PASSED
- **Failed**: $FAILED
- **Skipped**: $SKIPPED

### Pass Rate

EOF

if [ $TOTAL -gt 0 ] && [ $((TOTAL - SKIPPED)) -gt 0 ]; then
    RATE=$(( (PASSED * 100) / (TOTAL - SKIPPED) ))
    echo "Pass rate: $RATE%" >> "$RESULTS_FILE"
    echo -e "Pass Rate: ${GREEN}${RATE}%${NC}"
else
    echo "Pass rate: N/A (no tests run)" >> "$RESULTS_FILE"
    echo "Pass Rate: N/A"
fi

echo ""
echo "Results saved to: $RESULTS_FILE"

# Exit with failure if any tests failed
if [ $FAILED -gt 0 ]; then
    echo ""
    echo -e "${RED}Some tests failed. Review skill descriptions for strengthening.${NC}"
    exit 1
fi
