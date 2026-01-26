#!/bin/bash
# Check eval quality metrics at story/epic boundaries
# Called by: post-story, post-epic hooks
# Environment: STORY_ID, EPIC_ID, BOUNDARY_TYPE (story|epic)
# Output: Warning if eval thresholds not met

set -e

BOUNDARY="${BOUNDARY_TYPE:-story}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
YOKAY_EVALS_BIN="$PROJECT_ROOT/yokay-evals/bin/yokay-evals"

echo "Checking eval gates for ${BOUNDARY}..."

# Check if yokay-evals binary exists (graceful skip if not)
if [ ! -f "$YOKAY_EVALS_BIN" ]; then
  echo "Info: yokay-evals binary not found at $YOKAY_EVALS_BIN, skipping eval gate"
  exit 0
fi

# Define thresholds based on boundary type
# Story boundaries: lower thresholds (60 avg, 50% pass rate)
# Epic boundaries: higher thresholds (70 avg, 50% pass rate)
if [ "$BOUNDARY" = "epic" ]; then
  SCORE_THRESHOLD=70
else
  SCORE_THRESHOLD=60
fi
PASS_RATE_THRESHOLD=50

# Get latest eval metrics (disable set -e for this command)
set +e
REPORT_JSON=$("$YOKAY_EVALS_BIN" report --type grade --format json 2>&1)
REPORT_EXIT_CODE=$?
set -e

# Check if report command succeeded
if [ $REPORT_EXIT_CODE -ne 0 ]; then
  echo "Warning: Failed to get eval report, skipping eval gate"
  echo "$REPORT_JSON"
  exit 0
fi

# Parse JSON (using grep/awk for portability)
AVG_SCORE=$(echo "$REPORT_JSON" | grep -o '"average_score": [0-9.]*' | awk -F': ' '{print $2}' | head -1)
PASS_RATE=$(echo "$REPORT_JSON" | grep -o '"pass_rate": [0-9.]*' | awk -F': ' '{print $2}' | head -1)

# Handle empty values
if [ -z "$AVG_SCORE" ] || [ -z "$PASS_RATE" ]; then
  echo "Warning: Could not parse eval metrics, skipping eval gate"
  exit 0
fi

# Check thresholds (using awk for float comparison)
SCORE_BELOW=$(awk -v score="$AVG_SCORE" -v threshold="$SCORE_THRESHOLD" 'BEGIN {print (score < threshold) ? 1 : 0}')
PASS_BELOW=$(awk -v rate="$PASS_RATE" -v threshold="$PASS_RATE_THRESHOLD" 'BEGIN {print (rate < threshold) ? 1 : 0}')

# Output results
if [ "$SCORE_BELOW" -eq 1 ] || [ "$PASS_BELOW" -eq 1 ]; then
  echo ""
  echo "## Eval Gate Warning"
  echo ""
  echo "Eval metrics at ${BOUNDARY} completion:"
  echo ""
  echo "- Average Score: ${AVG_SCORE} (threshold: ${SCORE_THRESHOLD})"
  echo "- Pass Rate: ${PASS_RATE}% (threshold: ${PASS_RATE_THRESHOLD}%)"
  echo ""

  if [ "$SCORE_BELOW" -eq 1 ]; then
    echo "Warning: Average score below ${BOUNDARY} threshold"
  fi

  if [ "$PASS_BELOW" -eq 1 ]; then
    echo "Warning: Pass rate below threshold"
  fi

  echo ""
  echo "Consider:"
  echo "- Run \`yokay-evals report\` for detailed breakdown"
  echo "- Review failing skills with \`yokay-evals report --type grade\`"
  echo "- Improve skill clarity before moving forward"
  echo ""
else
  echo "Eval gates passed (avg: ${AVG_SCORE}, pass rate: ${PASS_RATE}%)"
fi
