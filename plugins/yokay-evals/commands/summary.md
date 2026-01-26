---
description: Display consolidated evaluation metrics and quality dashboard
argument-hint: "[--refresh]"
---

# Evaluation Summary Dashboard

Display a consolidated view of skill quality metrics, failure analysis, and quality gate indicators.

**Arguments**: `$ARGUMENTS` (optional flags)

## Purpose

The evaluation summary provides a quick, actionable view of the current state of skill quality and failure patterns. Use this dashboard to identify priority improvement areas and track quality trends.

## Steps

### 1. Generate the Summary Dashboard

Run the summary without arguments to display the latest metrics:

```bash
cd /Users/sis4m4/Projects/stevestomp/pokayokay

# Display the dashboard
echo "# Evaluation Summary"
echo ""
echo "**Generated**: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
```

### 2. Display Skill Quality Metrics

Show latest grade report summary with per-category breakdown:

```bash
# Get latest grade report
LATEST_REPORT=$(ls -t reports/skill-clarity-*.md 2>/dev/null | head -1)

if [ -z "$LATEST_REPORT" ]; then
    echo "## Skill Quality Metrics"
    echo ""
    echo "No grade reports found. Generate one with: \`/yokay-evals:grade\`"
    echo ""
else
    echo "## Skill Quality Metrics"
    echo ""
    echo "**Latest Grade Report**: $(basename $LATEST_REPORT)"
    echo ""

    # Get summary metrics using CLI
    METRICS=$(./yokay-evals/bin/yokay-evals report -type grade -format json 2>/dev/null)

    if [ -n "$METRICS" ]; then
        # Extract metrics using grep/sed instead of jq for portability
        TOTAL=$(echo "$METRICS" | grep '"total_skills"' | sed 's/.*: *\([0-9]*\).*/\1/')
        AVG_SCORE=$(echo "$METRICS" | grep '"average_score"' | sed 's/.*: *\([0-9.]*\).*/\1/')
        PASS_RATE=$(echo "$METRICS" | grep '"pass_rate"' | sed 's/.*: *\([0-9.]*\).*/\1/')
        THRESHOLD=$(echo "$METRICS" | grep '"passing_threshold"' | sed 's/.*: *\([0-9.]*\).*/\1/')

        # Determine status indicators
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

        # Per-category breakdown
        echo "### Per-Category Breakdown"
        echo ""
        echo "| Criteria | Average Score | Status |"
        echo "|----------|---------------|--------|"

        # Extract criteria scores
        echo "$METRICS" | grep -A 20 '"criteria_scores"' | grep '"name"\|"average"' | \
        while read -r line; do
            if echo "$line" | grep -q '"name"'; then
                NAME=$(echo "$line" | sed 's/.*: *"\([^"]*\)".*/\1/')
            elif echo "$line" | grep -q '"average"'; then
                SCORE=$(echo "$line" | sed 's/.*: *\([0-9.]*\).*/\1/')

                # Determine status
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
    else
        echo "Unable to parse report metrics."
        echo ""
    fi
fi
```

### 3. Display Failure Case Analysis

Show failure category distribution from analysis report:

```bash
# Check for failure analysis
ANALYSIS_FILE="yokay-evals/failures/ANALYSIS.md"

if [ ! -f "$ANALYSIS_FILE" ]; then
    echo "## Failure Case Analysis"
    echo ""
    echo "No failure analysis found. Run \`/yokay-evals:eval\` to analyze failure cases."
    echo ""
else
    echo "## Failure Case Analysis"
    echo ""

    # Extract total cases
    TOTAL_CASES=$(grep "^\*\*Total Cases Analyzed\*\*:" "$ANALYSIS_FILE" | sed 's/.*: *\([0-9]*\).*/\1/')
    echo "**Total Failure Cases**: ${TOTAL_CASES:-N/A}"
    echo ""

    # Extract category distribution table
    echo "### Category Distribution"
    echo ""

    # Get the table from ANALYSIS.md (starts after "## Category Distribution")
    sed -n '/^## Category Distribution/,/^## /p' "$ANALYSIS_FILE" | \
    grep -A 100 "^| Category" | \
    grep "^|" | \
    head -11

    echo ""

    # Extract severity summary
    echo "### Severity Distribution"
    echo ""

    # Get severity counts
    CRITICAL=$(grep -o "Critical: [0-9]*" "$ANALYSIS_FILE" | head -1 | sed 's/Critical: //')
    HIGH=$(grep "^\*\*High\*\*" "$ANALYSIS_FILE" | grep -o "[0-9]*" | head -1)
    MEDIUM=$(grep "^\*\*Medium\*\*" "$ANALYSIS_FILE" | grep -o "[0-9]*" | head -1)

    echo "| Severity | Count | Percentage |"
    echo "|----------|-------|------------|"
    if [ -n "$CRITICAL" ] && [ -n "$TOTAL_CASES" ] && [ "$TOTAL_CASES" != "N/A" ]; then
        CRIT_PCT=$(echo "scale=1; $CRITICAL * 100 / $TOTAL_CASES" | bc 2>/dev/null || echo "N/A")
        echo "| Critical | $CRITICAL | ${CRIT_PCT}% |"
    fi
    if [ -n "$HIGH" ] && [ -n "$TOTAL_CASES" ] && [ "$TOTAL_CASES" != "N/A" ]; then
        HIGH_PCT=$(echo "scale=1; $HIGH * 100 / $TOTAL_CASES" | bc 2>/dev/null || echo "N/A")
        echo "| High | $HIGH | ${HIGH_PCT}% |"
    fi
    if [ -n "$MEDIUM" ] && [ -n "$TOTAL_CASES" ] && [ "$TOTAL_CASES" != "N/A" ]; then
        MED_PCT=$(echo "scale=1; $MEDIUM * 100 / $TOTAL_CASES" | bc 2>/dev/null || echo "N/A")
        echo "| Medium | $MEDIUM | ${MED_PCT}% |"
    fi
    echo ""

    # Extract top 3 categories
    echo "### Top Failure Categories"
    echo ""
    grep "^- \*\*Top 3 categories\*\*" "$ANALYSIS_FILE" || \
    echo "Top 3 categories account for 75% of failures (see table above)"
    echo ""
fi
```

### 4. Display Quality Gate Indicators

Highlight critical quality issues:

```bash
echo "## Quality Gate Indicators"
echo ""

# Re-extract metrics for quality gates
if [ -n "$METRICS" ]; then
    AVG_SCORE=$(echo "$METRICS" | grep '"average_score"' | sed 's/.*: *\([0-9.]*\).*/\1/')
    PASS_RATE=$(echo "$METRICS" | grep '"pass_rate"' | sed 's/.*: *\([0-9.]*\).*/\1/')

    QUALITY_ISSUES=0

    # Check average score
    if (( $(echo "$AVG_SCORE < 70" | bc -l 2>/dev/null || echo 1) )); then
        echo "- 🚨 **Average Score Below 70**: Current ${AVG_SCORE}/100"
        QUALITY_ISSUES=$((QUALITY_ISSUES + 1))
    fi

    # Check pass rate
    if (( $(echo "$PASS_RATE < 50" | bc -l 2>/dev/null || echo 1) )); then
        echo "- 🚨 **Pass Rate Below 50%**: Current ${PASS_RATE}%"
        QUALITY_ISSUES=$((QUALITY_ISSUES + 1))
    fi

    # Check critical failures
    if [ -n "$CRITICAL" ] && [ "$CRITICAL" -gt 0 ]; then
        echo "- 🚨 **Critical Severity Failures**: $CRITICAL cases require immediate attention"
        QUALITY_ISSUES=$((QUALITY_ISSUES + 1))
    fi

    if [ $QUALITY_ISSUES -eq 0 ]; then
        echo "✅ All quality gates passing"
    fi
else
    echo "N/A - No metrics available"
fi

echo ""
```

### 5. Generate Recommendations

Provide actionable next steps based on metrics:

```bash
echo "## Recommendations"
echo ""

if [ -n "$METRICS" ]; then
    # Identify lowest scoring criteria
    echo "### Priority Improvement Areas"
    echo ""

    # Parse criteria and find lowest
    echo "$METRICS" | grep -A 20 '"criteria_scores"' | grep '"name"\|"average"' | \
    while read -r line; do
        if echo "$line" | grep -q '"name"'; then
            NAME=$(echo "$line" | sed 's/.*: *"\([^"]*\)".*/\1/')
        elif echo "$line" | grep -q '"average"'; then
            SCORE=$(echo "$line" | sed 's/.*: *\([0-9.]*\).*/\1/')
            echo "${SCORE}|${NAME}"
        fi
    done | sort -n | head -3 | nl -v 1 -s '. ' | \
    while IFS='|' read -r num score name; do
        echo "**Priority $num**: Improve \"$name\" (avg: $score)"
    done

    echo ""
    echo "### Failure Pattern Focus"
    echo ""

    # Reference top failure categories
    if [ -f "$ANALYSIS_FILE" ]; then
        echo "Focus on top failure categories:"
        grep "^| \*\*" "$ANALYSIS_FILE" | grep -v "TOTAL\|Category" | head -3 | \
        sed 's/^| \*\*\([^*]*\)\*\* | \([0-9]*\) |.*/- \1 (\2 cases)/'
    fi
    echo ""
fi

echo "## Next Actions"
echo ""
echo "- Run \`/yokay-evals:grade\` to generate updated skill report"
echo "- Review failure cases in \`yokay-evals/failures/\`"
echo "- Create tasks for skills scoring < 70"
echo "- Address critical severity failures first"
echo ""
```

### 6. Optional: Refresh Reports

To generate fresh metrics before displaying:

```bash
# Check if --refresh flag was passed
if echo "$ARGUMENTS" | grep -q "\-\-refresh"; then
    echo "Refreshing reports..."

    # Regenerate grade report
    ./yokay-evals/bin/yokay-evals grade-skills

    echo ""
    echo "Reports refreshed. Re-run summary to see updated metrics."
else
    # If no --refresh, proceed with displaying current metrics
    echo "Using existing reports. Pass --refresh to regenerate."
    echo ""
fi
```

## Understanding the Output

### Skill Quality Metrics

**Status Indicators:**
- ✅ Good: Score >= 75 or Pass Rate >= 50%
- ⚠️  Acceptable/Needs Improvement: Score 60-74 or Pass Rate 25-49%
- ❌ Needs Work/Below Threshold: Score < 60 or Pass Rate < 25%

**Criteria Breakdown:**
- **Clear Instructions**: Are objectives and approach well-defined?
- **Actionable Steps**: Are steps concrete and executable?
- **Good Examples**: Are there sufficient usage examples?
- **Appropriate Scope**: Is the skill focused and not too broad?

### Failure Analysis

**Categories:**
- **missed-tasks**: Agent skipped requirements from spec
- **wrong-product**: Built with wrong technology or approach
- **missing-tests**: Inadequate test coverage
- **scope-creep**: Added unrequested features
- **premature-completion**: Declared done with failing tests
- **session-amnesia**: Lost track of earlier constraints
- **security-flaw**: Introduced security vulnerabilities
- **regression**: Broke existing functionality

**Severity Levels:**
- **Critical**: Security vulnerabilities, data integrity issues, compliance violations
- **High**: Major functionality broken, security gaps, poor UX
- **Medium**: Degraded functionality, performance issues, incomplete features

### Quality Gates

**Thresholds:**
- Average Score: Target >= 70
- Pass Rate: Target >= 50%
- Critical Failures: Target = 0

## When to Run

**Regular Intervals:**
- Weekly quality check
- Before sprint planning
- After major skill updates

**Ad-hoc:**
- When diagnosing quality issues
- Before releasing skill changes
- When prioritizing improvement work

## Example Usage

**Basic summary:**
```bash
/yokay-evals:summary
```

**Refresh and display:**
```bash
/yokay-evals:summary --refresh
```

**Capture to file:**
```bash
/yokay-evals:summary > reports/summary-$(date +%Y-%m-%d).md
```

## Notes

- **Data Sources**: Reads from `reports/skill-clarity-*.md` and `yokay-evals/failures/ANALYSIS.md`
- **Latest Reports**: Automatically uses most recent grade report by timestamp
- **Missing Data**: Shows helpful messages if reports don't exist
- **Portable**: Uses basic shell commands (grep, sed, bc) for broad compatibility

## Related Commands

- `/yokay-evals:grade` - Generate new skill clarity report
- `/yokay-evals:eval` - Analyze failure cases
- `/yokay-evals:report` - View detailed historical reports
- `/pokayokay:revise` - Revise low-scoring skills
