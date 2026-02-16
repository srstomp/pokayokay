# Memory Orchestration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make pokayokay orchestrate Claude Code's native memory features — graduate confirmed failure patterns to `.claude/rules/`, curate MEMORY.md within its 200-line budget, and read memory to improve skill routing.

**Architecture:** Three new hook actions (`graduate-rules.sh`, `curate-memory.sh`) plus modifications to existing `suggest-skills.sh` and `bridge.py`. All changes are additive — no existing behavior changes. bridge.py gains a `graduate_rule()` function that calls `graduate-rules.sh`, triggered when `track_review_failure()` detects threshold crossings.

**Tech Stack:** Bash (hook scripts), Python (bridge.py), Markdown (rule files)

**Design doc:** `docs/plans/2026-02-16-memory-orchestration-design.md`

---

### Task 1: Create `graduate-rules.sh` hook action

**Files:**
- Create: `plugins/pokayokay/hooks/actions/graduate-rules.sh`
- Test: `plugins/pokayokay/tests/graduate-rules.test.sh`

**Step 1: Write the test**

Create `plugins/pokayokay/tests/graduate-rules.test.sh`:

```bash
#!/bin/bash
# Test for graduate-rules.sh - rule graduation from failure patterns
set -e

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

SCRIPT_DIR="$(cd "$(dirname "$0")/../hooks/actions" && pwd)"
SCRIPT="$SCRIPT_DIR/graduate-rules.sh"

echo "Testing graduate-rules.sh..."

# Test 1: Creates new rule file with path scope
echo "Test 1: Creates new rule file for hooks category"
export CLAUDE_PROJECT_DIR="$TEST_DIR"
export CATEGORY="missing_tests"
export PATTERN_DESCRIPTION="Review failures for missing tests in hook actions"
export AFFECTED_PATHS="plugins/pokayokay/hooks/**/*"
export FAILURE_COUNT="3"

mkdir -p "$TEST_DIR/.claude/rules/pokayokay"

OUTPUT=$(bash "$SCRIPT" 2>&1)

RULE_FILE="$TEST_DIR/.claude/rules/pokayokay/missing-tests.md"
if [ -f "$RULE_FILE" ]; then
  # Check for paths frontmatter
  if head -5 "$RULE_FILE" | grep -q "paths:"; then
    echo "  PASS: Rule file created with paths frontmatter"
  else
    echo "  FAIL: Rule file missing paths frontmatter"
    cat "$RULE_FILE"
    exit 1
  fi
else
  echo "  FAIL: Rule file not created at $RULE_FILE"
  exit 1
fi

# Test 2: Appends to existing rule file
echo "Test 2: Appends new pattern to existing rule file"
export PATTERN_DESCRIPTION="Also missing edge case tests"

OUTPUT=$(bash "$SCRIPT" 2>&1)

LINE_COUNT=$(wc -l < "$RULE_FILE")
if [ "$LINE_COUNT" -gt 8 ]; then
  echo "  PASS: Rule file has additional content"
else
  echo "  FAIL: Rule file should have grown after append"
  cat "$RULE_FILE"
  exit 1
fi

# Test 3: Handles missing CLAUDE_PROJECT_DIR gracefully
echo "Test 3: Handles missing project dir"
unset CLAUDE_PROJECT_DIR
export CATEGORY="missing_validation"
export PATTERN_DESCRIPTION="Input validation missing"
export AFFECTED_PATHS=""

if OUTPUT=$(bash "$SCRIPT" 2>&1); then
  echo "  PASS: Script exits gracefully without project dir"
else
  echo "  PASS: Script exits with error without project dir"
fi

# Test 4: Creates rules directory if missing
echo "Test 4: Creates rules directory if it does not exist"
export CLAUDE_PROJECT_DIR="$TEST_DIR/fresh-project"
mkdir -p "$TEST_DIR/fresh-project/.claude"
export CATEGORY="scope_creep"
export PATTERN_DESCRIPTION="Implementation exceeds spec"
export AFFECTED_PATHS=""
export FAILURE_COUNT="3"

OUTPUT=$(bash "$SCRIPT" 2>&1)
if [ -d "$TEST_DIR/fresh-project/.claude/rules/pokayokay" ]; then
  echo "  PASS: Rules directory created"
else
  echo "  FAIL: Rules directory not created"
  exit 1
fi

# Test 5: No paths frontmatter when AFFECTED_PATHS is empty
echo "Test 5: Project-wide rule when no paths specified"
RULE_FILE="$TEST_DIR/fresh-project/.claude/rules/pokayokay/scope-creep.md"
if [ -f "$RULE_FILE" ]; then
  if head -3 "$RULE_FILE" | grep -q "^---"; then
    echo "  FAIL: Should not have frontmatter when no paths"
    cat "$RULE_FILE"
    exit 1
  else
    echo "  PASS: No frontmatter for project-wide rule"
  fi
else
  echo "  FAIL: Rule file not created"
  exit 1
fi

echo ""
echo "All tests passed!"
```

**Step 2: Run test to verify it fails**

Run: `bash plugins/pokayokay/tests/graduate-rules.test.sh`
Expected: FAIL (script doesn't exist)

**Step 3: Write the implementation**

Create `plugins/pokayokay/hooks/actions/graduate-rules.sh`:

```bash
#!/bin/bash
# Graduate recurring failure patterns to .claude/rules/ files
# Called by: bridge.py when failure count >= threshold
# Environment: CLAUDE_PROJECT_DIR, CATEGORY, PATTERN_DESCRIPTION, AFFECTED_PATHS, FAILURE_COUNT
# Output: Creates/updates .claude/rules/pokayokay/<category>.md

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
CATEGORY="${CATEGORY:-}"
PATTERN="${PATTERN_DESCRIPTION:-}"
PATHS="${AFFECTED_PATHS:-}"
COUNT="${FAILURE_COUNT:-0}"

if [ -z "$CATEGORY" ] || [ -z "$PATTERN" ]; then
  exit 0
fi

# Convert category to filename (missing_tests -> missing-tests)
FILENAME=$(echo "$CATEGORY" | tr '_' '-')

# Ensure rules directory exists
RULES_DIR="$PROJECT_DIR/.claude/rules/pokayokay"
mkdir -p "$RULES_DIR"

RULE_FILE="$RULES_DIR/$FILENAME.md"
DATE=$(date +%Y-%m-%d)

if [ -f "$RULE_FILE" ]; then
  # Append new pattern to existing file
  # Check if this exact pattern already exists
  if grep -qF "$PATTERN" "$RULE_FILE" 2>/dev/null; then
    # Pattern already recorded, update date
    exit 0
  fi
  echo "" >> "$RULE_FILE"
  echo "- $PATTERN (seen ${COUNT}x, recorded $DATE)" >> "$RULE_FILE"
else
  # Create new rule file
  DISPLAY_NAME=$(echo "$CATEGORY" | tr '_' ' ' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

  if [ -n "$PATHS" ]; then
    # Path-scoped rule
    {
      echo "---"
      echo "paths:"
      echo "  - \"$PATHS\""
      echo "---"
      echo ""
      echo "# $DISPLAY_NAME Rules"
      echo ""
      echo "Patterns detected from recurring review failures (auto-graduated by pokayokay)."
      echo ""
      echo "- $PATTERN (seen ${COUNT}x, recorded $DATE)"
    } > "$RULE_FILE"
  else
    # Project-wide rule (no frontmatter)
    {
      echo "# $DISPLAY_NAME Rules"
      echo ""
      echo "Patterns detected from recurring review failures (auto-graduated by pokayokay)."
      echo ""
      echo "- $PATTERN (seen ${COUNT}x, recorded $DATE)"
    } > "$RULE_FILE"
  fi
fi
```

**Step 4: Run test to verify it passes**

Run: `bash plugins/pokayokay/tests/graduate-rules.test.sh`
Expected: All tests pass

**Step 5: Commit**

```bash
git add plugins/pokayokay/hooks/actions/graduate-rules.sh plugins/pokayokay/tests/graduate-rules.test.sh
git commit -m "feat: add graduate-rules.sh for failure-to-rule graduation"
```

---

### Task 2: Wire `graduate-rules.sh` into bridge.py

**Files:**
- Modify: `plugins/pokayokay/hooks/actions/bridge.py:854-1012` (FAILURE_CATEGORIES + track_review_failure)
- Modify: `plugins/pokayokay/hooks/actions/bridge.py:33-52` (HOOK_TIMEOUTS)

**Step 1: Add category-to-path mapping in bridge.py**

After `FAILURE_CATEGORIES` (line 863), add a mapping from failure categories to the file paths they typically affect. This tells `graduate-rules.sh` which paths to scope the rule to.

Add after line 863:

```python
# Map failure categories to likely affected file paths for rule scoping
CATEGORY_PATH_SCOPES: Dict[str, str] = {
    "missing_error_handling": "",  # Project-wide
    "missing_tests": "",  # Project-wide
    "scope_creep": "",  # Project-wide
    "missing_validation": "",  # Project-wide
    "missing_auth": "src/**/*.{ts,py}",
    "missing_edge_cases": "",  # Project-wide
    "naming_conventions": "",  # Project-wide
    "missing_types": "**/*.{ts,tsx}",
}
```

**Step 2: Add `graduate-rules.sh` to HOOK_TIMEOUTS**

At line ~48 in the HOOK_TIMEOUTS dict, add:

```python
    "graduate-rules": 10,
```

**Step 3: Add the `_graduate_rule()` helper function**

Add before `track_review_failure()` (before line 985):

```python
def _graduate_rule(category: str, context: str, count: int) -> None:
    """Graduate a recurring failure to a .claude/rules/ file."""
    display_name = category.replace("_", " ").title()
    description = f"Review failures for {display_name.lower()}: {context[:150]}"

    affected_paths = CATEGORY_PATH_SCOPES.get(category, "")

    env = {
        "CATEGORY": category,
        "PATTERN_DESCRIPTION": description,
        "AFFECTED_PATHS": affected_paths,
        "FAILURE_COUNT": str(count),
    }

    run_action("graduate-rules", env=env)
```

**Step 4: Add graduation call in `track_review_failure()`**

In `track_review_failure()` (line 985), after each `write_recurring_failure_to_memory()` call (lines 1003 and 1009), add:

```python
            _graduate_rule(category, cat_data["last_context"], cat_data["count"])
```

So lines 1002-1005 become:

```python
        if cat_data["count"] >= REVIEW_FAILURE_THRESHOLD and not cat_data.get("written"):
            write_recurring_failure_to_memory(category, cat_data["count"], cat_data["last_context"])
            _graduate_rule(category, cat_data["last_context"], cat_data["count"])
            cat_data["written"] = True
            newly_recorded.append(category)
```

And lines 1008-1009 become:

```python
        if cat_data.get("written") and cat_data["count"] % REVIEW_FAILURE_THRESHOLD == 0:
            write_recurring_failure_to_memory(category, cat_data["count"], cat_data["last_context"])
            _graduate_rule(category, cat_data["last_context"], cat_data["count"])
```

**Step 5: Run existing tests to verify nothing breaks**

Run: `for test in plugins/pokayokay/tests/*.test.sh; do echo "--- $test ---"; bash "$test"; done`
Expected: All existing tests pass

**Step 6: Commit**

```bash
git add plugins/pokayokay/hooks/actions/bridge.py
git commit -m "feat: wire graduate-rules into bridge.py failure tracking"
```

---

### Task 3: Create `curate-memory.sh` hook action

**Files:**
- Create: `plugins/pokayokay/hooks/actions/curate-memory.sh`
- Test: `plugins/pokayokay/tests/curate-memory.test.sh`

**Step 1: Write the test**

Create `plugins/pokayokay/tests/curate-memory.test.sh`:

```bash
#!/bin/bash
# Test for curate-memory.sh - MEMORY.md section enforcement
set -e

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

SCRIPT_DIR="$(cd "$(dirname "$0")/../hooks/actions" && pwd)"
SCRIPT="$SCRIPT_DIR/curate-memory.sh"

echo "Testing curate-memory.sh..."

# Test 1: Creates MEMORY.md from template when missing
echo "Test 1: Creates MEMORY.md from template when missing"
MEMORY_DIR="$TEST_DIR/memory1"
mkdir -p "$MEMORY_DIR"
export MEMORY_DIR="$MEMORY_DIR"

OUTPUT=$(bash "$SCRIPT" 2>&1)

if [ -f "$MEMORY_DIR/MEMORY.md" ]; then
  if grep -q "## Completed Work" "$MEMORY_DIR/MEMORY.md" && \
     grep -q "## Key Decisions" "$MEMORY_DIR/MEMORY.md" && \
     grep -q "## Topic Index" "$MEMORY_DIR/MEMORY.md"; then
    echo "  PASS: MEMORY.md created with all sections"
  else
    echo "  FAIL: MEMORY.md missing required sections"
    cat "$MEMORY_DIR/MEMORY.md"
    exit 1
  fi
else
  echo "  FAIL: MEMORY.md not created"
  exit 1
fi

# Test 2: Preserves content outside pokayokay sections
echo "Test 2: Preserves non-pokayokay content"
MEMORY_DIR="$TEST_DIR/memory2"
mkdir -p "$MEMORY_DIR"
export MEMORY_DIR="$MEMORY_DIR"

cat > "$MEMORY_DIR/MEMORY.md" << 'EOF'
# Memory

## My Custom Section
- This is my own note that Claude wrote
- Another custom note

## Completed Work
<!-- pokayokay: managed by session-chain hooks -->
- epic-123: Some work (2026-02-10, COMPLETE)

## Key Decisions
<!-- pokayokay: promoted from session handoffs -->
- Decision A: rationale

## Architecture Notes
<!-- pokayokay: stable project structure -->

## Active Patterns
<!-- pokayokay: graduated to .claude/rules/ when confirmed -->

## Recent Bug Fixes
<!-- pokayokay: rotated, max 5 entries -->

## Topic Index
<!-- pokayokay: links to detail files -->
EOF

OUTPUT=$(bash "$SCRIPT" 2>&1)

if grep -q "My Custom Section" "$MEMORY_DIR/MEMORY.md" && \
   grep -q "This is my own note" "$MEMORY_DIR/MEMORY.md"; then
  echo "  PASS: Non-pokayokay content preserved"
else
  echo "  FAIL: Non-pokayokay content lost"
  cat "$MEMORY_DIR/MEMORY.md"
  exit 1
fi

# Test 3: Enforces section line budget (overflow to archive)
echo "Test 3: Overflow moves old entries to archive"
MEMORY_DIR="$TEST_DIR/memory3"
mkdir -p "$MEMORY_DIR"
export MEMORY_DIR="$MEMORY_DIR"

# Create MEMORY.md with 22 content lines in Completed Work (budget: 20 including header+comment)
{
  echo "# Memory"
  echo ""
  echo "## Completed Work"
  echo "<!-- pokayokay: managed by session-chain hooks -->"
  for i in $(seq 1 22); do
    echo "- epic-$i: Work item $i (2026-01-$((i % 28 + 1)), COMPLETE)"
  done
  echo ""
  echo "## Key Decisions"
  echo "<!-- pokayokay: promoted from session handoffs -->"
  echo "- Keep this decision"
  echo ""
  echo "## Architecture Notes"
  echo "<!-- pokayokay: stable project structure -->"
  echo ""
  echo "## Active Patterns"
  echo "<!-- pokayokay: graduated to .claude/rules/ when confirmed -->"
  echo ""
  echo "## Recent Bug Fixes"
  echo "<!-- pokayokay: rotated, max 5 entries -->"
  echo ""
  echo "## Topic Index"
  echo "<!-- pokayokay: links to detail files -->"
} > "$MEMORY_DIR/MEMORY.md"

OUTPUT=$(bash "$SCRIPT" 2>&1)

# Check that Completed Work section was trimmed
CW_LINES=$(sed -n '/^## Completed Work/,/^## /p' "$MEMORY_DIR/MEMORY.md" | wc -l)
if [ "$CW_LINES" -le 22 ]; then
  echo "  PASS: Completed Work section trimmed to budget"
else
  echo "  FAIL: Completed Work section has $CW_LINES lines (expected <= 22)"
  exit 1
fi

# Check that overflow file was created
if [ -f "$MEMORY_DIR/completed-work-archive.md" ]; then
  echo "  PASS: Overflow archive created"
else
  echo "  FAIL: Overflow archive not created"
  exit 1
fi

# Test 4: Total line count stays under 200
echo "Test 4: Total MEMORY.md stays under 200 lines"
TOTAL_LINES=$(wc -l < "$MEMORY_DIR/MEMORY.md")
if [ "$TOTAL_LINES" -le 200 ]; then
  echo "  PASS: Total lines ($TOTAL_LINES) under 200"
else
  echo "  FAIL: Total lines ($TOTAL_LINES) exceeds 200"
  exit 1
fi

echo ""
echo "All tests passed!"
```

**Step 2: Run test to verify it fails**

Run: `bash plugins/pokayokay/tests/curate-memory.test.sh`
Expected: FAIL (script doesn't exist)

**Step 3: Write the implementation**

Create `plugins/pokayokay/hooks/actions/curate-memory.sh`. This script uses an embedded Python block for reliable section parsing (bash is fragile with multiline markdown parsing):

```bash
#!/bin/bash
# Curate MEMORY.md - enforce section structure and line budgets
# Called by: bridge.py on SessionEnd
# Environment: MEMORY_DIR (auto memory directory path)
# Output: Updated MEMORY.md with enforced budgets, overflow to topic files

set -e

MEMORY_DIR="${MEMORY_DIR:-}"

if [ -z "$MEMORY_DIR" ] || [ ! -d "$MEMORY_DIR" ]; then
  exit 0
fi

export MEMORY_FILE="$MEMORY_DIR/MEMORY.md"

# If MEMORY.md doesn't exist, create from template
if [ ! -f "$MEMORY_FILE" ]; then
  cat > "$MEMORY_FILE" << 'TEMPLATE'
# Memory

## Completed Work
<!-- pokayokay: managed by session-chain hooks -->

## Key Decisions
<!-- pokayokay: promoted from session handoffs -->

## Architecture Notes
<!-- pokayokay: stable project structure -->

## Active Patterns
<!-- pokayokay: graduated to .claude/rules/ when confirmed -->

## Recent Bug Fixes
<!-- pokayokay: rotated, max 5 entries -->

## Topic Index
<!-- pokayokay: links to detail files -->
- See `memory/chain-learnings.md` for session history
- See `memory/spike-results.md` for spike outcomes
- See `memory/recurring-failures.md` for failure patterns
TEMPLATE
  exit 0
fi

# Ensure all pokayokay sections exist
for section in "Completed Work" "Key Decisions" "Architecture Notes" "Active Patterns" "Recent Bug Fixes" "Topic Index"; do
  if ! grep -q "^## $section" "$MEMORY_FILE"; then
    COMMENT=""
    case "$section" in
      "Completed Work") COMMENT="<!-- pokayokay: managed by session-chain hooks -->" ;;
      "Key Decisions") COMMENT="<!-- pokayokay: promoted from session handoffs -->" ;;
      "Architecture Notes") COMMENT="<!-- pokayokay: stable project structure -->" ;;
      "Active Patterns") COMMENT="<!-- pokayokay: graduated to .claude/rules/ when confirmed -->" ;;
      "Recent Bug Fixes") COMMENT="<!-- pokayokay: rotated, max 5 entries -->" ;;
      "Topic Index") COMMENT="<!-- pokayokay: links to detail files -->" ;;
    esac
    echo "" >> "$MEMORY_FILE"
    echo "## $section" >> "$MEMORY_FILE"
    echo "$COMMENT" >> "$MEMORY_FILE"
  fi
done

# Enforce section line budgets via Python (reliable multiline parsing)
python3 - "$MEMORY_FILE" "$MEMORY_DIR" << 'PYEOF'
import os
import sys

memory_file = sys.argv[1]
memory_dir = sys.argv[2]

budgets = {
    "Completed Work": 20,
    "Key Decisions": 40,
    "Architecture Notes": 30,
    "Active Patterns": 15,
    "Recent Bug Fixes": 15,
    "Topic Index": 10,
}

archives = {
    "Completed Work": "completed-work-archive.md",
    "Key Decisions": "decisions-archive.md",
    "Architecture Notes": "architecture-archive.md",
    "Recent Bug Fixes": "bugfixes-archive.md",
}

pokayokay_marker = "<!-- pokayokay:"

with open(memory_file, "r") as f:
    content = f.read()

lines = content.split("\n")

# Parse into sections: list of (header, is_pokayokay, content_lines)
sections = []
current_header = None
current_lines = []
current_is_pokayokay = False

for line in lines:
    if line.startswith("## "):
        if current_header is not None or current_lines:
            sections.append((current_header, current_is_pokayokay, current_lines))
        current_header = line[3:].strip()
        current_lines = [line]
        current_is_pokayokay = False
    elif pokayokay_marker in line and current_header:
        current_is_pokayokay = True
        current_lines.append(line)
    elif line.startswith("# ") and not line.startswith("## "):
        if current_header is not None or current_lines:
            sections.append((current_header, current_is_pokayokay, current_lines))
        current_header = None
        current_lines = [line]
        current_is_pokayokay = False
    else:
        current_lines.append(line)

if current_header is not None or current_lines:
    sections.append((current_header, current_is_pokayokay, current_lines))

# Enforce budgets on pokayokay sections
output_sections = []
for header, is_pokayokay, section_lines in sections:
    if not is_pokayokay or header not in budgets:
        output_sections.append(section_lines)
        continue

    budget = budgets[header]
    if len(section_lines) <= budget:
        output_sections.append(section_lines)
        continue

    # Over budget - trim oldest content lines (keep header + comment + newest)
    header_lines = section_lines[:2]
    content_lines = section_lines[2:]

    while content_lines and not content_lines[0].strip():
        content_lines.pop(0)

    overflow_count = len(content_lines) - (budget - 2)
    if overflow_count > 0 and header in archives:
        overflow = content_lines[:overflow_count]
        remaining = content_lines[overflow_count:]

        archive_path = os.path.join(memory_dir, archives[header])
        archive_header = "# {} Archive\n\nOverflow entries from MEMORY.md, managed by pokayokay.\n\n".format(header)
        existing = ""
        if os.path.exists(archive_path):
            with open(archive_path, "r") as f:
                existing = f.read()
        if not existing.strip():
            existing = archive_header

        existing += "\n" + "\n".join(overflow) + "\n"
        with open(archive_path, "w") as f:
            f.write(existing)

        output_sections.append(header_lines + remaining)
    else:
        output_sections.append(header_lines + content_lines[:(budget - 2)])

output = "\n".join(line for section in output_sections for line in section)
output = output.rstrip() + "\n"

with open(memory_file, "w") as f:
    f.write(output)
PYEOF
```

**Step 4: Run test to verify it passes**

Run: `bash plugins/pokayokay/tests/curate-memory.test.sh`
Expected: All tests pass

**Step 5: Commit**

```bash
git add plugins/pokayokay/hooks/actions/curate-memory.sh plugins/pokayokay/tests/curate-memory.test.sh
git commit -m "feat: add curate-memory.sh for MEMORY.md section enforcement"
```

---

### Task 4: Wire `curate-memory.sh` into bridge.py SessionEnd

**Files:**
- Modify: `plugins/pokayokay/hooks/actions/bridge.py:520-594` (handle_session_end)
- Modify: `plugins/pokayokay/hooks/actions/bridge.py:33-52` (HOOK_TIMEOUTS)
- Modify: `plugins/pokayokay/hooks/actions/bridge.py:420-517` (memory dir helpers)

**Step 1: Add `curate-memory` to HOOK_TIMEOUTS**

At line ~48 (alongside the `graduate-rules` entry added in Task 2):

```python
    "curate-memory": 15,
```

**Step 2: Extract memory directory resolution into a shared helper**

The pattern for finding the memory directory is duplicated across `_write_chain_learnings()` (line 420), `_write_spike_result()` (line 477), and `write_recurring_failure_to_memory()` (line 909). Extract it. Add before `_write_chain_learnings()`:

```python
def _get_memory_dir() -> Optional[Path]:
    """Get the auto memory directory for the current project.

    Checks Claude's project memory directory first, falls back to project-local.
    Returns None if neither can be determined.
    """
    project_dir = os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())
    project_key = project_dir.replace("/", "-").lstrip("-")
    claude_memory = Path.home() / ".claude" / "projects" / project_key / "memory"
    if claude_memory.exists():
        return claude_memory
    local_memory = Path(project_dir) / "memory"
    if local_memory.exists():
        return local_memory
    return None
```

**Step 3: Refactor existing memory functions to use `_get_memory_dir()`**

Update `_write_chain_learnings()`, `_write_spike_result()`, and `write_recurring_failure_to_memory()` — replace each function's 4-6 line directory-finding block with:

```python
    target_dir = _get_memory_dir()
    if target_dir is None:
        target_dir = Path(os.environ.get("CLAUDE_PROJECT_DIR", os.getcwd())) / "memory"
    target_dir.mkdir(parents=True, exist_ok=True)
```

**Step 4: Add memory curation call in `handle_session_end()`**

In `handle_session_end()` (line 520), after `run_action("session-summary")` (line 526) and before the chain state check (line 529), add:

```python
    # Curate MEMORY.md - enforce section structure and line budgets
    memory_dir = _get_memory_dir()
    if memory_dir:
        results.append(run_action("curate-memory", env={"MEMORY_DIR": str(memory_dir)}))
```

**Step 5: Run all tests**

Run: `for test in plugins/pokayokay/tests/*.test.sh; do echo "--- $test ---"; bash "$test"; done`
Expected: All tests pass

**Step 6: Commit**

```bash
git add plugins/pokayokay/hooks/actions/bridge.py
git commit -m "feat: wire curate-memory into SessionEnd, extract _get_memory_dir helper"
```

---

### Task 5: Add memory reads to `suggest-skills.sh`

**Files:**
- Modify: `plugins/pokayokay/hooks/actions/suggest-skills.sh`
- Test: `plugins/pokayokay/tests/suggest-skills-memory.test.sh`

**Step 1: Write the test**

Create `plugins/pokayokay/tests/suggest-skills-memory.test.sh`:

```bash
#!/bin/bash
# Test for suggest-skills.sh memory-informed routing
set -e

TEST_DIR=$(mktemp -d)
trap "rm -rf $TEST_DIR" EXIT

SCRIPT_DIR="$(cd "$(dirname "$0")/../hooks/actions" && pwd)"
SCRIPT="$SCRIPT_DIR/suggest-skills.sh"

echo "Testing suggest-skills.sh memory integration..."

# Setup: create memory files
MEMORY_DIR="$TEST_DIR/memory"
mkdir -p "$MEMORY_DIR"

# Test 1: Suppresses spike when already answered
echo "Test 1: Suppresses spike for previously answered question"
cat > "$MEMORY_DIR/spike-results.md" << 'EOF'
# Spike Results

## Should we use Redis for caching? (2026-02-10)
- **Result**: GO
- **Task**: T-42
- **Finding**: Redis is the right choice for our session caching needs
EOF

export CLAUDE_PROJECT_DIR="$TEST_DIR"
export TASK_TITLE="Investigate whether Redis is suitable for caching"
export TASK_TYPE="spike"
export MEMORY_DIR="$MEMORY_DIR"

OUTPUT=$(bash "$SCRIPT" 2>&1)

if echo "$OUTPUT" | grep -qi "already investigated\|prior spike\|spike-results"; then
  echo "  PASS: References prior spike result"
else
  echo "  FAIL: Should reference prior spike for Redis caching"
  echo "  Output: $OUTPUT"
  exit 1
fi

# Test 2: Boosts skill based on recurring failures
echo "Test 2: Boosts testing-strategy for missing_tests failures"
cat > "$MEMORY_DIR/recurring-failures.md" << 'EOF'
# Recurring Review Failures

## Missing Tests (seen 5x)
**Pattern**: Review failures for missing tests
**Context**: Implementation lacks unit tests for edge cases
**First recorded**: 2026-02-10
EOF

export TASK_TITLE="Add input validation to user form"
export TASK_TYPE="feature"

OUTPUT=$(bash "$SCRIPT" 2>&1)

if echo "$OUTPUT" | grep -qi "testing-strategy\|recurring.*test"; then
  echo "  PASS: Boosted testing-strategy due to recurring failures"
else
  echo "  FAIL: Should boost testing-strategy skill"
  echo "  Output: $OUTPUT"
  exit 1
fi

# Test 3: Mentions relevant graduated rules
echo "Test 3: Mentions graduated rules when they exist"
mkdir -p "$TEST_DIR/.claude/rules/pokayokay"
cat > "$TEST_DIR/.claude/rules/pokayokay/missing-tests.md" << 'EOF'
# Missing Tests Rules

- Always write tests before implementation
EOF

export TASK_TITLE="Implement new API endpoint"
export TASK_TYPE="feature"

OUTPUT=$(bash "$SCRIPT" 2>&1)

if echo "$OUTPUT" | grep -qi "rules\|graduated.*pattern"; then
  echo "  PASS: Mentions graduated rules"
else
  echo "  FAIL: Should mention relevant graduated rules"
  echo "  Output: $OUTPUT"
  exit 1
fi

echo ""
echo "All tests passed!"
```

**Step 2: Run test to verify it fails**

Run: `bash plugins/pokayokay/tests/suggest-skills-memory.test.sh`
Expected: FAIL (memory integration doesn't exist yet)

**Step 3: Modify `suggest-skills.sh`**

Replace the entire output block (lines 46-56) and add memory reads before it. The full updated script becomes:

```bash
#!/bin/bash
# Suggest relevant skills based on task content and project memory
# Called by: pre-task hooks
# Environment: TASK_ID, TASK_TITLE, TASK_TYPE, MEMORY_DIR (optional), CLAUDE_PROJECT_DIR
# Output: Skill suggestions and memory context in additionalContext

set -e

TITLE="${TASK_TITLE:-}"
TYPE="${TASK_TYPE:-}"

# Skip if no title available
if [ -z "$TITLE" ]; then
  exit 0
fi

TITLE_LOWER=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]')
SUGGESTIONS=()

# Performance-related keywords
if echo "$TITLE_LOWER" | grep -qE "(optimi|slow|latency|cache|memory|bundle|performance|speed)"; then
  SUGGESTIONS+=("performance-optimization")
fi

# Security-related keywords
if echo "$TITLE_LOWER" | grep -qE "(auth|security|permiss|access|encrypt|vulnerab|token|jwt|oauth)"; then
  SUGGESTIONS+=("security-audit")
fi

# Accessibility-related keywords
if echo "$TITLE_LOWER" | grep -qE "(a11y|accessibility|screen.?reader|aria|wcag|keyboard)"; then
  SUGGESTIONS+=("accessibility-auditor")
fi

# Observability-related keywords
if echo "$TITLE_LOWER" | grep -qE "(log|metric|trac|monitor|alert|debug)"; then
  SUGGESTIONS+=("observability")
fi

# Testing-related keywords (beyond testing-strategy already routed)
if echo "$TITLE_LOWER" | grep -qE "(test|spec|coverage|mock|e2e|integration)"; then
  SUGGESTIONS+=("testing-strategy")
fi

# --- Memory-informed routing ---
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-.}"
MEM_DIR="${MEMORY_DIR:-}"
MEMORY_NOTES=()

# Auto-detect memory dir if not set
if [ -z "$MEM_DIR" ]; then
  PROJECT_KEY=$(echo "$PROJECT_DIR" | tr '/' '-' | sed 's/^-//')
  CLAUDE_MEMORY="$HOME/.claude/projects/$PROJECT_KEY/memory"
  if [ -d "$CLAUDE_MEMORY" ]; then
    MEM_DIR="$CLAUDE_MEMORY"
  elif [ -d "$PROJECT_DIR/memory" ]; then
    MEM_DIR="$PROJECT_DIR/memory"
  fi
fi

if [ -n "$MEM_DIR" ] && [ -d "$MEM_DIR" ]; then
  # Check spike results - flag prior investigations
  SPIKE_FILE="$MEM_DIR/spike-results.md"
  if [ -f "$SPIKE_FILE" ] && echo "$TITLE_LOWER" | grep -qE "(investigat|spike|evaluat|should we|feasib)"; then
    for word in $(echo "$TITLE_LOWER" | tr -cs '[:alpha:]' '\n' | sort -u); do
      if [ ${#word} -gt 4 ] && grep -qi "$word" "$SPIKE_FILE" 2>/dev/null; then
        MATCH_LINE=$(grep -i "$word" "$SPIKE_FILE" | head -1)
        MEMORY_NOTES+=("Prior spike found in spike-results.md matching '$word': $MATCH_LINE")
        break
      fi
    done
  fi

  # Check recurring failures - boost relevant skills
  FAILURES_FILE="$MEM_DIR/recurring-failures.md"
  if [ -f "$FAILURES_FILE" ]; then
    if grep -qi "missing.test" "$FAILURES_FILE" 2>/dev/null; then
      SUGGESTIONS+=("testing-strategy")
      MEMORY_NOTES+=("Recurring 'missing tests' failures detected - testing-strategy skill boosted")
    fi
    if grep -qi "missing.error.handling\|error.state" "$FAILURES_FILE" 2>/dev/null; then
      SUGGESTIONS+=("error-handling")
      MEMORY_NOTES+=("Recurring 'error handling' failures detected - error-handling skill boosted")
    fi
    if grep -qi "missing.validation\|input.validation" "$FAILURES_FILE" 2>/dev/null; then
      MEMORY_NOTES+=("Recurring 'missing validation' failures - ensure input validation in implementation")
    fi
  fi
fi

# Check graduated rules
RULES_DIR="$PROJECT_DIR/.claude/rules/pokayokay"
if [ -d "$RULES_DIR" ]; then
  RULE_FILES=$(ls -1 "$RULES_DIR"/*.md 2>/dev/null | xargs -I{} basename {} .md | tr '\n' ', ' | sed 's/,$//')
  if [ -n "$RULE_FILES" ]; then
    MEMORY_NOTES+=("Graduated patterns in .claude/rules/pokayokay/: $RULE_FILES")
  fi
fi

# Deduplicate suggestions
if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
  SUGGESTIONS=($(printf '%s\n' "${SUGGESTIONS[@]}" | sort -u))
fi

# Output suggestions and memory context
if [ ${#SUGGESTIONS[@]} -gt 0 ] || [ ${#MEMORY_NOTES[@]} -gt 0 ]; then
  echo ""
  if [ ${#SUGGESTIONS[@]} -gt 0 ]; then
    echo "## Skill Suggestions"
    echo ""
    echo "Based on task content and project memory, consider loading these additional skills:"
    echo ""
    for skill in "${SUGGESTIONS[@]}"; do
      echo "- \`$skill\`"
    done
  fi
  if [ ${#MEMORY_NOTES[@]} -gt 0 ]; then
    echo ""
    echo "## Memory Context"
    echo ""
    for note in "${MEMORY_NOTES[@]}"; do
      echo "- $note"
    done
  fi
  echo ""
fi
```

**Step 4: Run new test to verify it passes**

Run: `bash plugins/pokayokay/tests/suggest-skills-memory.test.sh`
Expected: All tests pass

**Step 5: Run all existing tests**

Run: `for test in plugins/pokayokay/tests/*.test.sh; do echo "--- $test ---"; bash "$test"; done`
Expected: All tests pass

**Step 6: Commit**

```bash
git add plugins/pokayokay/hooks/actions/suggest-skills.sh plugins/pokayokay/tests/suggest-skills-memory.test.sh
git commit -m "feat: add memory-informed skill routing to suggest-skills.sh"
```

---

### Task 6: Update CHANGELOG and bump version

**Files:**
- Modify: `CHANGELOG.md`
- Modify: `plugins/pokayokay/plugin.json`

**Step 1: Read current version from plugin.json**

Check `plugins/pokayokay/plugin.json` for current `"version"` field.

**Step 2: Update CHANGELOG**

Change `## [Unreleased]` header to `## [0.13.0] - YYYY-MM-DD` (use current date).

**Step 3: Bump version in plugin.json**

Update `"version"` field to `"0.13.0"`.

**Step 4: Commit**

```bash
git add CHANGELOG.md plugins/pokayokay/plugin.json
git commit -m "chore: bump version to 0.13.0 for memory orchestration"
```

---

### Task 7: Run full test suite and verify

**Files:**
- No new files

**Step 1: Run all tests**

Run: `for test in plugins/pokayokay/tests/*.test.sh; do echo "=== $test ==="; bash "$test" || echo "FAILED: $test"; done`
Expected: All tests pass

**Step 2: Verify bridge.py has no syntax errors**

Run: `python3 -c "exec(open('plugins/pokayokay/hooks/actions/bridge.py').read()); print('bridge.py syntax OK')"`
Expected: No syntax errors

**Step 3: Verify new tests pass in isolation**

Run: `bash plugins/pokayokay/tests/graduate-rules.test.sh && bash plugins/pokayokay/tests/curate-memory.test.sh && bash plugins/pokayokay/tests/suggest-skills-memory.test.sh`
Expected: All pass
