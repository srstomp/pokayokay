#!/bin/bash
# Integration test for summary command
# Simulates running the actual skill and validates output structure

set -e

cd /Users/sis4m4/Projects/stevestomp/pokayokay

echo "Running summary command integration test..."

# Create a temporary output file
OUTPUT_FILE=$(mktemp)

# Execute the key sections of the summary command
{
    echo "# Evaluation Summary"
    echo ""
    echo "**Generated**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""

    # Skill Quality Metrics Section
    LATEST_REPORT=$(ls -t reports/skill-clarity-*.md 2>/dev/null | head -1)

    if [ -z "$LATEST_REPORT" ]; then
        echo "## Skill Quality Metrics"
        echo ""
        echo "No grade reports found."
        echo ""
    else
        echo "## Skill Quality Metrics"
        echo ""
        echo "**Latest Grade Report**: $(basename $LATEST_REPORT)"
        echo ""

        METRICS=$(./yokay-evals/bin/yokay-evals report -type grade -format json 2>/dev/null)

        if [ -n "$METRICS" ]; then
            TOTAL=$(echo "$METRICS" | grep '"total_skills"' | sed 's/.*: *\([0-9]*\).*/\1/')
            AVG_SCORE=$(echo "$METRICS" | grep '"average_score"' | sed 's/.*: *\([0-9.]*\).*/\1/')
            PASS_RATE=$(echo "$METRICS" | grep '"pass_rate"' | sed 's/.*: *\([0-9.]*\).*/\1/')
            THRESHOLD=$(echo "$METRICS" | grep '"passing_threshold"' | sed 's/.*: *\([0-9.]*\).*/\1/')

            AVG_STATUS="❌ Below Threshold"
            if (( $(echo "$AVG_SCORE >= 70" | bc -l 2>/dev/null || echo 0) )); then
                AVG_STATUS="✅ Good"
            fi

            PASS_STATUS="❌ Below Target (>50%)"
            if (( $(echo "$PASS_RATE >= 50" | bc -l 2>/dev/null || echo 0) )); then
                PASS_STATUS="✅ Meets Target"
            elif (( $(echo "$PASS_RATE >= 25" | bc -l 2>/dev/null || echo 0) )); then
                PASS_STATUS="⚠️  Needs Improvement"
            fi

            echo "| Metric | Value | Status |"
            echo "|--------|-------|--------|"
            echo "| Total Skills | $TOTAL | - |"
            echo "| Average Score | ${AVG_SCORE}/100 | $AVG_STATUS |"
            echo "| Pass Rate | ${PASS_RATE}% | $PASS_STATUS |"
            echo "| Passing Threshold | $THRESHOLD | - |"
            echo ""

            echo "### Per-Category Breakdown"
            echo ""
            echo "| Criteria | Average Score | Status |"
            echo "|----------|---------------|--------|"

            echo "$METRICS" | grep -A 20 '"criteria_scores"' | grep '"name"\|"average"' | \
            while read -r line; do
                if echo "$line" | grep -q '"name"'; then
                    NAME=$(echo "$line" | sed 's/.*: *"\([^"]*\)".*/\1/')
                elif echo "$line" | grep -q '"average"'; then
                    SCORE=$(echo "$line" | sed 's/.*: *\([0-9.]*\).*/\1/')
                    STATUS="❌ Needs Work"
                    if (( $(echo "$SCORE >= 75" | bc -l 2>/dev/null || echo 0) )); then
                        STATUS="✅ Good"
                    elif (( $(echo "$SCORE >= 60" | bc -l 2>/dev/null || echo 0) )); then
                        STATUS="⚠️  Acceptable"
                    fi
                    echo "| $NAME | $SCORE | $STATUS |"
                fi
            done
            echo ""
        fi
    fi

    # Failure Analysis Section
    ANALYSIS_FILE="yokay-evals/failures/ANALYSIS.md"

    if [ ! -f "$ANALYSIS_FILE" ]; then
        echo "## Failure Case Analysis"
        echo ""
        echo "No failure analysis found."
        echo ""
    else
        echo "## Failure Case Analysis"
        echo ""

        TOTAL_CASES=$(grep "^\*\*Total Cases Analyzed\*\*:" "$ANALYSIS_FILE" | sed 's/.*: *\([0-9]*\).*/\1/')
        echo "**Total Failure Cases**: ${TOTAL_CASES:-N/A}"
        echo ""

        echo "### Top Failure Categories"
        echo ""
        grep "^| \*\*" "$ANALYSIS_FILE" | grep -v "TOTAL\|Category" | head -3
        echo ""
    fi

    # Quality Gates
    echo "## Quality Gate Indicators"
    echo ""

    if [ -n "$METRICS" ]; then
        AVG_SCORE=$(echo "$METRICS" | grep '"average_score"' | sed 's/.*: *\([0-9.]*\).*/\1/')
        PASS_RATE=$(echo "$METRICS" | grep '"pass_rate"' | sed 's/.*: *\([0-9.]*\).*/\1/')

        QUALITY_ISSUES=0

        if (( $(echo "$AVG_SCORE < 70" | bc -l 2>/dev/null || echo 1) )); then
            echo "- 🚨 **Average Score Below 70**: Current ${AVG_SCORE}/100"
            QUALITY_ISSUES=$((QUALITY_ISSUES + 1))
        fi

        if (( $(echo "$PASS_RATE < 50" | bc -l 2>/dev/null || echo 1) )); then
            echo "- 🚨 **Pass Rate Below 50%**: Current ${PASS_RATE}%"
            QUALITY_ISSUES=$((QUALITY_ISSUES + 1))
        fi

        if [ $QUALITY_ISSUES -eq 0 ]; then
            echo "✅ All quality gates passing"
        fi
    fi

    echo ""

    # Recommendations
    echo "## Recommendations"
    echo ""
    echo "See detailed recommendations in summary output."
    echo ""

    # Next Actions
    echo "## Next Actions"
    echo ""
    echo "- Run \`/yokay-evals:grade\` to generate updated skill report"
    echo "- Review failure cases in \`yokay-evals/failures/\`"
    echo ""

} > "$OUTPUT_FILE"

# Validate the output structure
echo ""
echo "Validating output structure..."

# Test 1: Has main heading
if ! grep -q "^# Evaluation Summary" "$OUTPUT_FILE"; then
    echo "FAIL: Missing main heading"
    rm "$OUTPUT_FILE"
    exit 1
fi
echo "PASS: Has main heading"

# Test 2: Has timestamp
if ! grep -q "^\*\*Generated\*\*:" "$OUTPUT_FILE"; then
    echo "FAIL: Missing timestamp"
    rm "$OUTPUT_FILE"
    exit 1
fi
echo "PASS: Has timestamp"

# Test 3: Has Skill Quality Metrics section
if ! grep -q "^## Skill Quality Metrics" "$OUTPUT_FILE"; then
    echo "FAIL: Missing Skill Quality Metrics section"
    rm "$OUTPUT_FILE"
    exit 1
fi
echo "PASS: Has Skill Quality Metrics section"

# Test 4: Has metrics table (if reports exist)
if grep -q "skill-clarity-" "$OUTPUT_FILE"; then
    if ! grep -q "^| Metric | Value | Status |" "$OUTPUT_FILE"; then
        echo "FAIL: Missing metrics table"
        rm "$OUTPUT_FILE"
        exit 1
    fi
    echo "PASS: Has metrics table"
fi

# Test 5: Has Per-Category Breakdown (if reports exist)
if grep -q "skill-clarity-" "$OUTPUT_FILE"; then
    if ! grep -q "^### Per-Category Breakdown" "$OUTPUT_FILE"; then
        echo "FAIL: Missing per-category breakdown"
        rm "$OUTPUT_FILE"
        exit 1
    fi
    echo "PASS: Has per-category breakdown"
fi

# Test 6: Has Failure Case Analysis section
if ! grep -q "^## Failure Case Analysis" "$OUTPUT_FILE"; then
    echo "FAIL: Missing Failure Case Analysis section"
    rm "$OUTPUT_FILE"
    exit 1
fi
echo "PASS: Has Failure Case Analysis section"

# Test 7: Has Quality Gate Indicators section
if ! grep -q "^## Quality Gate Indicators" "$OUTPUT_FILE"; then
    echo "FAIL: Missing Quality Gate Indicators section"
    rm "$OUTPUT_FILE"
    exit 1
fi
echo "PASS: Has Quality Gate Indicators section"

# Test 8: Has Recommendations section
if ! grep -q "^## Recommendations" "$OUTPUT_FILE"; then
    echo "FAIL: Missing Recommendations section"
    rm "$OUTPUT_FILE"
    exit 1
fi
echo "PASS: Has Recommendations section"

# Test 9: Has Next Actions section
if ! grep -q "^## Next Actions" "$OUTPUT_FILE"; then
    echo "FAIL: Missing Next Actions section"
    rm "$OUTPUT_FILE"
    exit 1
fi
echo "PASS: Has Next Actions section"

# Test 10: Verify specific values are present (if reports exist)
if grep -q "skill-clarity-" "$OUTPUT_FILE"; then
    if ! grep -q "| Total Skills |" "$OUTPUT_FILE"; then
        echo "FAIL: Missing Total Skills metric"
        rm "$OUTPUT_FILE"
        exit 1
    fi
    echo "PASS: Has Total Skills metric"

    if ! grep -q "| Average Score |" "$OUTPUT_FILE"; then
        echo "FAIL: Missing Average Score metric"
        rm "$OUTPUT_FILE"
        exit 1
    fi
    echo "PASS: Has Average Score metric"

    if ! grep -q "| Pass Rate |" "$OUTPUT_FILE"; then
        echo "FAIL: Missing Pass Rate metric"
        rm "$OUTPUT_FILE"
        exit 1
    fi
    echo "PASS: Has Pass Rate metric"
fi

echo ""
echo "Preview of generated output:"
echo "---"
head -30 "$OUTPUT_FILE"
echo "..."
echo "---"
echo ""

# Clean up
rm "$OUTPUT_FILE"

echo "All integration tests passed!"
