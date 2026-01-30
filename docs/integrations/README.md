# pokayokay Integrations

Overview of available integrations and how to add new ones.

## Table of Contents

1. [Available Integrations](#available-integrations)
2. [Integration Architecture](#integration-architecture)
3. [How to Add New Integrations](#how-to-add-new-integrations)
4. [Hook System](#hook-system)

---

## Available Integrations

### kaizen - Intelligent Failure Pattern Capture

**Status**: Active
**Documentation**: [kaizen.md](./kaizen.md)

Automatically capture failure patterns and create fix tasks based on historical confidence.

**Key Features**:
- Pattern learning from review failures
- Confidence-based action recommendations (AUTO/SUGGEST/LOGGED)
- Automatic fix task creation in ohno
- Continuous improvement feedback loop

**Integration Point**: `post-review-fail.sh` hook

**Use Case**: When a review fails, kaizen analyzes the failure, captures the pattern, and suggests or auto-creates a fix task based on how often similar failures have occurred.

**Example Workflow**:
```
Review fails → kaizen captures pattern → High confidence → Auto-create fix task in ohno
```

See [kaizen.md](./kaizen.md) for detailed installation and configuration.

---

## Integration Architecture

pokayokay integrates with external tools through a **hook-based architecture**:

```
┌─────────┐      ┌─────────────┐      ┌─────────┐
│  ohno   │◄────►│  pokayokay  │◄────►│ kaizen  │
│         │      │             │      │         │
│ • tasks │      │ • orchestr. │      │ • grade │
│ • deps  │      │ • agents    │      │ • track │
│ • state │      │ • hooks     │      │ • learn │
└─────────┘      └─────────────┘      └─────────┘
     │                  │                   │
     │                  │                   │
     └──────────────────┴───────────────────┘
               Integrated Workflow
```

### Component Roles

| Tool | Role | Integration Type |
|------|------|-----------------|
| **pokayokay** | Agent orchestration, review workflow | Core system |
| **kaizen** | Failure pattern capture, grading | Hook-based (post-review-fail) |
| **ohno** | Task management, dependencies | CLI-based (via kaizen) |

### Integration Patterns

pokayokay supports multiple integration patterns:

1. **Hook-based**: Scripts executed at workflow lifecycle points
   - Example: `post-review-fail.sh` for kaizen
   - Location: `hooks/`
   - Data flow: Environment variables → Hook → JSON output

2. **CLI-based**: External tools called via command-line interface
   - Example: ohno task creation
   - Location: External binaries in PATH
   - Data flow: pokayokay → CLI wrapper → External tool

3. **MCP-based**: Model Context Protocol servers (future)
   - Example: ohno MCP server
   - Location: Claude Code configuration
   - Data flow: pokayokay → Claude Code → MCP server

---

## How to Add New Integrations

### Step 1: Identify Integration Point

Determine where in the pokayokay workflow your integration should activate:

| Lifecycle Point | Hook Name | Use Case |
|----------------|-----------|----------|
| Before task starts | `pre-task-start.sh` | Validate task quality, check prerequisites |
| After task completes | `post-task-complete.sh` | Run quality checks, deploy artifacts |
| Review fails | `post-review-fail.sh` | Capture failures, create fix tasks |
| Review passes | `post-review-pass.sh` | Log success, update metrics |
| Session ends | `post-session.sh` | Generate reports, cleanup |

### Step 2: Create Hook Script

Create a new hook script in `hooks/`:

```bash
#!/bin/bash
# hooks/my-integration.sh - Description of what this hook does
#
# Environment Variables:
#   VAR_NAME     - Description of the variable
#   OTHER_VAR    - Description of another variable
#
# Output: JSON with action type for pokayokay to handle
#   {"action": "SUCCESS", "data": {...}}
#   {"action": "FAILURE", "message": "..."}

set -e

# Check if required tool exists
if ! command -v my-tool &> /dev/null; then
    echo '{"action": "FAILURE", "message": "my-tool not installed"}'
    exit 0
fi

# Validate required environment variables
if [ -z "$REQUIRED_VAR" ]; then
    echo '{"action": "FAILURE", "message": "missing required environment variables"}'
    exit 0
fi

# Execute integration logic
RESULT=$(my-tool process "$REQUIRED_VAR" 2>/dev/null || echo '{"status": "error"}')

# Parse and return result
ACTION=$(echo "$RESULT" | jq -r '.status' 2>/dev/null || echo "error")

case "$ACTION" in
    "success")
        echo '{"action": "SUCCESS", "data": '"$RESULT"'}'
        ;;
    *)
        echo '{"action": "FAILURE", "message": "integration failed"}'
        ;;
esac
```

### Step 3: Make Hook Executable

```bash
chmod +x hooks/my-integration.sh
```

### Step 4: Document Integration

Create a new documentation file in `docs/integrations/`:

```markdown
# My Integration

**Description of what the integration does**

## Overview

Explain the integration's purpose and benefits.

## Prerequisites

List required dependencies and tools.

## Installation

Step-by-step installation instructions.

## How It Works

Explain the integration workflow with diagrams.

## Configuration

Document environment variables and options.

## Example Workflows

Provide concrete examples of the integration in action.

## Troubleshooting

Common issues and solutions.

## See Also

Links to related documentation.
```

### Step 5: Update This README

Add your integration to the [Available Integrations](#available-integrations) section.

### Step 6: Test Integration

Test the hook manually:

```bash
# Set environment variables
export REQUIRED_VAR="test-value"

# Run hook
./hooks/my-integration.sh

# Verify JSON output
./hooks/my-integration.sh | jq .
```

### Step 7: Integration Checklist

Before submitting your integration:

- [ ] Hook script is executable (`chmod +x`)
- [ ] Hook checks for required dependencies
- [ ] Hook validates environment variables
- [ ] Hook returns valid JSON output
- [ ] Documentation file created in `docs/integrations/`
- [ ] Example workflows provided
- [ ] Troubleshooting section included
- [ ] This README updated with new integration
- [ ] Integration tested manually
- [ ] Error cases handled gracefully

---

## Hook System

### Hook Lifecycle

pokayokay executes hooks at specific points in the workflow:

```
┌──────────────────┐
│  Task Assigned   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ pre-task-start   │ ◄─ Hook: Validate task quality
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Agent Executes  │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Review Task     │
└────────┬─────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌─────────┐
│ PASS   │ │  FAIL   │
└───┬────┘ └────┬────┘
    │           │
    │           ▼
    │      ┌──────────────────┐
    │      │ post-review-fail │ ◄─ Hook: kaizen capture
    │      └────────┬─────────┘
    │               │
    │               ▼
    │      ┌──────────────────┐
    │      │ Create Fix Task  │
    │      └────────┬─────────┘
    │               │
    └───────────────┘
         │
         ▼
┌──────────────────┐
│ post-review-pass │ ◄─ Hook: Log success
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ Task Complete    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ post-session     │ ◄─ Hook: Generate reports
└──────────────────┘
```

### Hook Contract

All hooks must follow this contract:

#### Input (Environment Variables)

Hooks receive data through environment variables:

```bash
# Common variables (available to all hooks)
TASK_ID="task-123"                    # Current task ID
TASK_TYPE="feature"                   # Task type (feature, bug, test, etc.)
TASK_TITLE="Add user authentication"  # Task title

# Hook-specific variables
FAILURE_DETAILS="Missing test coverage"  # post-review-fail
FAILURE_SOURCE="quality-review"          # post-review-fail
```

#### Output (JSON)

Hooks must output valid JSON to stdout:

```json
{
  "action": "SUCCESS|FAILURE|AUTO|SUGGEST|LOGGED",
  "message": "Optional message",
  "data": {
    "optional": "additional data"
  }
}
```

#### Exit Codes

- `0`: Hook executed successfully (pokayokay continues)
- Non-zero: Hook failed (pokayokay logs error but continues)

### Hook Best Practices

1. **Fail gracefully**: If dependencies are missing, log and continue
2. **Validate inputs**: Check required environment variables upfront
3. **Return valid JSON**: Always output parseable JSON
4. **Use jq for JSON**: Install and use `jq` for JSON manipulation
5. **Handle errors**: Redirect stderr, catch command failures
6. **Be fast**: Hooks should complete in < 5 seconds when possible
7. **Document thoroughly**: Explain inputs, outputs, and use cases

### Hook Testing Template

Test your hooks with this template:

```bash
#!/bin/bash
# test-hook.sh - Test harness for hook scripts

HOOK_PATH="./hooks/my-integration.sh"

# Test Case 1: Missing dependency
echo "Test 1: Missing dependency"
OUTPUT=$(bash -c 'PATH=/usr/bin:/bin '$HOOK_PATH)
echo "$OUTPUT" | jq .
echo ""

# Test Case 2: Missing environment variable
echo "Test 2: Missing environment variable"
OUTPUT=$(unset REQUIRED_VAR && $HOOK_PATH)
echo "$OUTPUT" | jq .
echo ""

# Test Case 3: Success case
echo "Test 3: Success case"
OUTPUT=$(export REQUIRED_VAR="test" && $HOOK_PATH)
echo "$OUTPUT" | jq .
echo ""

# Test Case 4: Validate JSON
echo "Test 4: Validate JSON output"
export REQUIRED_VAR="test"
$HOOK_PATH | jq empty && echo "Valid JSON" || echo "Invalid JSON"
```

---

## Future Integrations

Potential integrations being considered:

### CI/CD Integration
- Trigger builds on task completion
- Deploy artifacts after review passes
- Run automated tests before review

### Metrics & Monitoring
- Track agent performance
- Measure task completion time
- Monitor failure patterns

### Communication
- Slack/Discord notifications
- Email summaries
- Team dashboards

### Code Quality
- Static analysis (linters, formatters)
- Security scanning
- Dependency auditing

---

## Related Documentation

### pokayokay Core
- [pokayokay README](../../README.md) - Getting started
- [Hook System Architecture](../prompts/hooks.md) - Detailed hook design
- [User Guide](../README.md) - Complete pokayokay guide

### Integration Documentation
- [kaizen Integration](./kaizen.md) - Failure pattern capture
- [ohno Integration](https://github.com/srstomp/ohno) - Task management

### External Tools
- [kaizen Documentation](https://github.com/srstomp/kaizen/blob/master/docs/INTEGRATION.md) - kaizen integration guide
- [kaizen User Guide](https://github.com/srstomp/kaizen/blob/master/docs/user-guide.md) - kaizen command reference
- [ohno Repository](https://github.com/srstomp/ohno) - Task management system

---

## Contributing

To contribute a new integration:

1. Follow the [How to Add New Integrations](#how-to-add-new-integrations) guide
2. Create a PR with:
   - Hook script (`hooks/my-integration.sh`)
   - Documentation (`docs/integrations/my-integration.md`)
   - This README updated
   - Test cases
3. Ensure all tests pass
4. Update version and changelog

For questions or discussions:
- GitHub Issues: https://github.com/srstomp/pokayokay/issues
- See also: [kaizen integrations](https://github.com/srstomp/kaizen/blob/master/docs/INTEGRATION.md)
