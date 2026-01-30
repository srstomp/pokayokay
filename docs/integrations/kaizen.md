# Kaizen Integration

**Intelligent failure pattern capture and fix task automation**

## Overview

The kaizen integration enables pokayokay to learn from review failures and automatically suggest or create fix tasks based on historical patterns. When a review fails (spec-review or quality-review), the `post-review-fail.sh` hook:

1. Detects the failure category using pattern matching
2. Captures the failure details in kaizen's pattern database
3. Analyzes confidence level based on similar past failures
4. Returns an action (AUTO, SUGGEST, or LOGGED) for pokayokay to handle

This creates a continuous improvement loop where common failures are automatically addressed with increasing confidence over time.

### Why Integrate Kaizen?

- **Pattern Learning** - Build a knowledge base of failure patterns specific to your project
- **Confidence-Based Actions** - High confidence failures auto-create fix tasks, low confidence ones just log
- **Reduced Toil** - Stop manually creating fix tasks for recurring issues
- **Feedback Loop** - The more failures captured, the smarter the system becomes

## Prerequisites

Before using the kaizen integration, ensure you have:

### Required

1. **kaizen CLI** - The kaizen command-line tool must be installed and available in your PATH
2. **jq** - JSON parsing utility (used by the hook script to parse kaizen output)
3. **ohno MCP** - Task management server configured in Claude Code

### Optional

- **kaizen initialized** - Run `kaizen init` in your project for project-specific pattern storage
  - If not initialized, kaizen will use global storage at `~/.config/kaizen/`

## Installation

### 1. Install kaizen

```bash
# Install from source (recommended for latest features)
go install github.com/srstomp/kaizen@latest

# Verify installation
kaizen
```

You should see the kaizen command usage:

```
Usage: kaizen <command> [options]

Commands:
  init                Initialize kaizen configuration directory
  suggest             Generate fix task suggestions based on failure patterns
  detect-category     Detect failure category from text details
  ...
```

### 2. Install jq

```bash
# macOS
brew install jq

# Linux (Debian/Ubuntu)
sudo apt-get install jq

# Linux (RHEL/CentOS)
sudo yum install jq

# Verify installation
jq --version
```

### 3. Initialize kaizen (Optional)

Initialize kaizen in your project to store failure patterns locally:

```bash
cd /path/to/your/project
kaizen init
```

This creates a `.kaizen/` directory in your project with:
- `failures.db` - SQLite database for captured failure patterns
- `config.yaml` - Configuration settings

If you skip this step, kaizen will use global storage at `~/.config/kaizen/`.

### 4. Hook Integration

The `hooks/post-review-fail.sh` hook is automatically available in pokayokay and will be executed when reviews fail. No additional configuration needed.

## How It Works

### Failure Review Lifecycle

```
┌─────────────────┐
│  Review Fails   │
│ (spec/quality)  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│ post-review-fail.sh     │
│ ─────────────────       │
│ 1. detect-category      │ ──► Pattern matching on failure text
│ 2. capture              │ ──► Store in failures database
│ 3. suggest              │ ──► Get confidence-based action
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Action Output          │
├─────────────────────────┤
│ • AUTO                  │ ──► pokayokay auto-creates fix task
│ • SUGGEST               │ ──► pokayokay prompts user
│ • LOGGED                │ ──► pokayokay just logs, continues
└─────────────────────────┘
```

### 1. Detect Category

When a review fails, kaizen analyzes the failure details to classify it:

```bash
kaizen detect-category --details "Missing test coverage for new API endpoint"
```

**Output:**
```json
{
  "detected_category": "missing-tests",
  "confidence": "high"
}
```

**Currently supported categories:**
- `missing-tests` - No tests for implementation
- `scope-creep` - Extra work beyond spec
- `wrong-product` - Misunderstood requirements or wrong file modified

*Note: Additional categories may be added in future versions.*

### 2. Capture Failure

The failure is stored in kaizen's database for pattern learning:

```bash
kaizen capture \
  --task-id "task-123" \
  --category "missing-tests" \
  --details "Missing test coverage for new API endpoint" \
  --source "quality-review"
```

This stores the failure in kaizen's SQLite database:
- Project-local: `.kaizen/failures.db`
- Global: `~/.config/kaizen/failures.db`

### 3. Get Suggestion

Based on historical patterns and confidence, kaizen suggests an action:

```bash
kaizen suggest --task-id "task-123" --category "missing-tests"
```

**Output (High Confidence - AUTO):**
```json
{
  "action": "auto-create",
  "confidence": "high",
  "fix_task": {
    "title": "Add tests for task-123",
    "description": "Add missing test coverage for API endpoint",
    "type": "test"
  }
}
```

**Output (Medium Confidence - SUGGEST):**
```json
{
  "action": "suggest",
  "confidence": "medium",
  "fix_task": {
    "title": "Fix quality issues in task-123",
    "description": "Address quality-review failures",
    "type": "fix"
  }
}
```

**Output (Low Confidence - LOGGED):**
```json
{
  "action": "log"
}
```

## Configuration Options

### Environment Variables

The `post-review-fail.sh` hook expects these environment variables (automatically set by pokayokay):

| Variable | Description | Example |
|----------|-------------|---------|
| `TASK_ID` | The ohno task ID that failed review | `task-123` |
| `FAILURE_DETAILS` | Details about why the review failed | `Missing test coverage...` |
| `FAILURE_SOURCE` | Source of failure | `spec-review`, `quality-review` |

### Confidence Thresholds

Kaizen determines confidence based on **occurrence count** - how often this failure type has been captured:

| Occurrences | Confidence | Action |
|-------------|------------|--------|
| 5+ | High | AUTO (auto-create fix task) |
| 2-4 | Medium | SUGGEST (prompt user) |
| 0-1 | Low | LOGGED (just record) |

The more frequently a failure pattern occurs, the more confident kaizen becomes that it knows how to fix it.

### Storage Location

Control where kaizen stores failures:

```bash
# Project-local storage (recommended)
cd /path/to/project
kaizen init

# Global storage (default if not initialized)
# Uses ~/.config/kaizen/
```

## Example Workflows

### AUTO: High Confidence Auto-Creation

**Scenario:** Missing tests is a common failure in your project.

```bash
# Review fails for task-456
TASK_ID=task-456
FAILURE_DETAILS="No test file found for src/api/users.go"
FAILURE_SOURCE="quality-review"

# Hook executes
./hooks/post-review-fail.sh

# Output
{
  "action": "AUTO",
  "fix_task": {
    "title": "Add tests for task-456",
    "description": "Add missing test coverage for users API",
    "type": "test"
  }
}
```

**pokayokay behavior:**
- Automatically creates fix task in ohno
- Adds to current sprint/backlog
- Links to original failing task
- Continues workflow without user prompt

### SUGGEST: Medium Confidence Prompt

**Scenario:** Quality issues need context from developer.

```bash
# Review fails for task-789
TASK_ID=task-789
FAILURE_DETAILS="Code duplication detected in auth module"
FAILURE_SOURCE="quality-review"

# Hook executes
./hooks/post-review-fail.sh

# Output
{
  "action": "SUGGEST",
  "fix_task": {
    "title": "Refactor auth module for task-789",
    "description": "Address code duplication in authentication",
    "type": "refactor"
  },
  "confidence": "medium"
}
```

**pokayokay behavior:**
- Shows suggested fix task to user
- Prompts: "Create this fix task? (y/n)"
- If yes, creates task in ohno
- If no, logs failure and continues

### LOGGED: Low Confidence Just Logs

**Scenario:** Unfamiliar failure pattern, not enough data.

```bash
# Review fails for task-321
TASK_ID=task-321
FAILURE_DETAILS="Unclear acceptance criteria interpretation"
FAILURE_SOURCE="spec-review"

# Hook executes
./hooks/post-review-fail.sh

# Output
{
  "action": "LOGGED"
}
```

**pokayokay behavior:**
- Logs the failure in session notes
- Does NOT create a fix task
- Continues with normal review failure handling
- Pattern is captured for future learning

## Troubleshooting

### kaizen not found

**Symptom:**
```json
{"action": "LOGGED", "message": "kaizen not installed"}
```

**Solution:**
```bash
# Verify kaizen is in PATH
which kaizen

# If not found, install
go install github.com/srstomp/kaizen@latest

# Add Go bin to PATH if needed
export PATH="$PATH:$(go env GOPATH)/bin"
```

### jq not installed

**Symptom:**
```json
{"action": "LOGGED", "message": "jq not installed"}
```

**Solution:**
```bash
# macOS
brew install jq

# Linux
sudo apt-get install jq  # Debian/Ubuntu
sudo yum install jq      # RHEL/CentOS

# Verify
jq --version
```

### No suggestions returned

**Symptom:**
Hook always returns `{"action": "LOGGED"}` even for common failures.

**Possible causes:**

1. **Not enough historical data**
   - Kaizen needs several similar failures to build confidence
   - Solution: Continue using the system, patterns will improve

2. **Category not detected**
   - Check if failure details are too generic
   - Solution: Ensure reviews provide specific failure reasons

3. **Storage issues**
   - Check if `.kaizen/` or `~/.config/kaizen/` directories are writable
   - Solution: Fix permissions or run `kaizen init`

**Debug:**
```bash
# Manually test detection
kaizen detect-category --details "Your failure message"

# Check database exists
ls -la .kaizen/failures.db  # Project-local
ls -la ~/.config/kaizen/failures.db  # Global

# Test suggestion directly
kaizen suggest --task-id "test" --category "missing-tests"
```

### Missing required environment variables

**Symptom:**
```json
{"action": "LOGGED", "message": "missing required environment variables"}
```

**Cause:**
Hook is being called without proper environment setup.

**Solution:**
Ensure pokayokay is setting `TASK_ID`, `FAILURE_DETAILS`, and `FAILURE_SOURCE` before calling the hook. This should happen automatically - if you see this error, it's likely a bug in pokayokay's hook invocation.

### Invalid JSON output

**Symptom:**
pokayokay reports parse error when processing hook output.

**Debug:**
```bash
# Run hook manually with test data
export TASK_ID="test-123"
export FAILURE_DETAILS="Test failure message"
export FAILURE_SOURCE="quality-review"
./hooks/post-review-fail.sh

# Check if output is valid JSON
./hooks/post-review-fail.sh | jq .
```

**Solution:**
- Update kaizen to latest version
- Check for error messages in kaizen commands
- Verify jq is working correctly

## Advanced Usage

### Understanding Confidence Thresholds

Confidence is based on **occurrence count** - how many times kaizen has seen similar failures:

| Occurrences | Confidence | What Happens |
|-------------|------------|--------------|
| 5+ times | High | Hook outputs AUTO, pokayokay creates fix task automatically |
| 2-4 times | Medium | Hook outputs SUGGEST, pokayokay prompts user |
| 0-1 times | Low | Hook outputs LOGGED, failure recorded for learning |

### Viewing Captured Patterns

Kaizen stores failures in a SQLite database:

```bash
# Check if database exists
ls -la .kaizen/failures.db       # Project-local
ls -la ~/.config/kaizen/failures.db  # Global

# Query the database (requires sqlite3)
sqlite3 .kaizen/failures.db "SELECT category, COUNT(*) FROM failures GROUP BY category"
```

### Global vs Project-Local Storage

**Project-local** (`.kaizen/`):
- Patterns specific to this project
- Better for project-specific conventions
- Shared via git (add to .gitignore if sensitive)

**Global** (`~/.config/kaizen/`):
- Patterns across all your projects
- Better for personal workflow patterns
- Not shared across team

**Recommendation:** Use project-local for team projects, global for personal projects.

## See Also

- [kaizen GitHub Repository](https://github.com/srstomp/kaizen)
- [kaizen User Guide](https://github.com/srstomp/kaizen/blob/master/docs/user-guide.md)
- [pokayokay Hook System](../README.md#hook-system)
- [ohno Task Management](https://github.com/srstomp/ohno)
