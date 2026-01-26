#!/bin/bash
# Functional test for summary command
# Tests that the bash commands in the skill work correctly

set -e

cd /Users/sis4m4/Projects/stevestomp/pokayokay

echo "Testing summary command functional behavior..."

# Test 1: Can generate timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
if [ -z "$TIMESTAMP" ]; then
    echo "FAIL: Cannot generate timestamp"
    exit 1
fi
echo "PASS: Timestamp generation works"

# Test 2: Can find latest grade report
LATEST_REPORT=$(ls -t reports/skill-clarity-*.md 2>/dev/null | head -1)
if [ -z "$LATEST_REPORT" ]; then
    echo "WARN: No grade reports found (this is OK if none exist yet)"
else
    if [ ! -f "$LATEST_REPORT" ]; then
        echo "FAIL: Latest report path exists but file is not readable"
        exit 1
    fi
    echo "PASS: Can find and read latest grade report: $(basename $LATEST_REPORT)"
fi

# Test 3: Can invoke yokay-evals CLI for JSON report
if [ -f "./yokay-evals/bin/yokay-evals" ]; then
    METRICS=$(./yokay-evals/bin/yokay-evals report -type grade -format json 2>/dev/null)
    if [ -z "$METRICS" ] && [ -n "$LATEST_REPORT" ]; then
        echo "FAIL: CLI exists but cannot generate JSON metrics"
        exit 1
    fi
    if [ -n "$METRICS" ]; then
        echo "PASS: Can invoke CLI and get JSON metrics"

        # Test 4: Can parse JSON metrics
        TOTAL=$(echo "$METRICS" | grep '"total_skills"' | sed 's/.*: *\([0-9]*\).*/\1/')
        if [ -z "$TOTAL" ]; then
            echo "FAIL: Cannot parse total_skills from JSON"
            exit 1
        fi
        echo "PASS: Can parse metrics (total_skills: $TOTAL)"
    else
        echo "WARN: No metrics available (OK if no reports exist)"
    fi
else
    echo "WARN: CLI binary not built (run 'go build' first)"
fi

# Test 5: Can read failure analysis file
ANALYSIS_FILE="yokay-evals/failures/ANALYSIS.md"
if [ ! -f "$ANALYSIS_FILE" ]; then
    echo "WARN: No failure analysis file (this is OK if not yet created)"
else
    TOTAL_CASES=$(grep "^\*\*Total Cases Analyzed\*\*:" "$ANALYSIS_FILE" | sed 's/.*: *\([0-9]*\).*/\1/')
    if [ -z "$TOTAL_CASES" ]; then
        echo "FAIL: Cannot parse failure analysis"
        exit 1
    fi
    echo "PASS: Can read and parse failure analysis (total cases: $TOTAL_CASES)"
fi

# Test 6: Can extract category table
if [ -f "$ANALYSIS_FILE" ]; then
    CATEGORY_TABLE=$(sed -n '/^## Category Distribution/,/^## /p' "$ANALYSIS_FILE" | \
                     grep -A 100 "^| Category" | \
                     grep "^|" | \
                     head -11)
    if [ -z "$CATEGORY_TABLE" ]; then
        echo "FAIL: Cannot extract category distribution table"
        exit 1
    fi
    echo "PASS: Can extract category distribution table"
fi

# Test 7: Arithmetic operations work (for percentages)
if command -v bc >/dev/null 2>&1; then
    RESULT=$(echo "scale=1; 15 * 100 / 20" | bc)
    if [ "$RESULT" != "75.0" ]; then
        echo "FAIL: bc arithmetic not working correctly"
        exit 1
    fi
    echo "PASS: bc arithmetic works for percentage calculations"
else
    echo "WARN: bc not available (percentages may not calculate)"
fi

# Test 8: Can generate recommendations output
if [ -n "$METRICS" ]; then
    # Test criteria sorting and extraction
    CRITERIA_LIST=$(echo "$METRICS" | grep -A 20 '"criteria_scores"' | grep '"name"\|"average"' | \
    while read -r line; do
        if echo "$line" | grep -q '"name"'; then
            NAME=$(echo "$line" | sed 's/.*: *"\([^"]*\)".*/\1/')
        elif echo "$line" | grep -q '"average"'; then
            SCORE=$(echo "$line" | sed 's/.*: *\([0-9.]*\).*/\1/')
            echo "${SCORE}|${NAME}"
        fi
    done | sort -n | head -1)

    if [ -z "$CRITERIA_LIST" ]; then
        echo "FAIL: Cannot extract and sort criteria for recommendations"
        exit 1
    fi
    echo "PASS: Can generate priority recommendations"
fi

echo ""
echo "All functional tests passed!"
