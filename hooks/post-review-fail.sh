#!/bin/bash
# post-review-fail.sh - Called when pokayokay review fails
# Integrates with kaizen to capture failures and create fix tasks
#
# Environment Variables:
#   TASK_ID          - The ohno task ID that failed review
#   FAILURE_DETAILS  - Details about why the review failed
#   FAILURE_SOURCE   - Source of failure (e.g., "spec-review", "quality-review")
#
# Output: JSON with action type for pokayokay to handle
#   {"action": "AUTO", "fix_task": {...}}
#   {"action": "SUGGEST", "fix_task": {...}, "confidence": "medium"}
#   {"action": "LOGGED", "message": "..."}

set -e

# Check if kaizen command exists
if ! command -v kaizen &> /dev/null; then
    echo '{"action": "LOGGED", "message": "kaizen not installed"}'
    exit 0
fi

# Validate required environment variables
if [ -z "$TASK_ID" ] || [ -z "$FAILURE_DETAILS" ] || [ -z "$FAILURE_SOURCE" ]; then
    echo '{"action": "LOGGED", "message": "missing required environment variables"}'
    exit 0
fi

# Detect category from failure details
CATEGORY_RESULT=$(kaizen detect-category --details "$FAILURE_DETAILS" 2>/dev/null || echo '{"detected_category": "unknown", "confidence": "low"}')
CATEGORY=$(echo "$CATEGORY_RESULT" | jq -r '.detected_category')

# Capture the failure
kaizen capture \
    --task-id "$TASK_ID" \
    --category "$CATEGORY" \
    --details "$FAILURE_DETAILS" \
    --source "$FAILURE_SOURCE" &> /dev/null || true

# Get suggestion (confidence-based action)
SUGGESTION=$(kaizen suggest --task-id "$TASK_ID" --category "$CATEGORY" 2>/dev/null || echo '{"action": "log"}')
ACTION=$(echo "$SUGGESTION" | jq -r '.action')

# Output action for pokayokay to handle
case "$ACTION" in
    "auto-create")
        # Extract fix task details and output for auto-creation
        echo "$SUGGESTION" | jq '{action: "AUTO", fix_task: .fix_task}'
        ;;
    "suggest")
        # Output suggestion for user confirmation
        echo "$SUGGESTION" | jq '{action: "SUGGEST", fix_task: .fix_task, confidence: .confidence}'
        ;;
    *)
        # Log only, continue with existing behavior
        echo '{"action": "LOGGED"}'
        ;;
esac