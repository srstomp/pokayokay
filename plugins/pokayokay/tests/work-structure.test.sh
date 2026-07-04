#!/usr/bin/env bash
# Doc-structure test: work.md's headless/chain-state, kaizen review-failure,
# and Brainstorm Gate details live in skill references (progressive
# disclosure). work.md keeps a summary + ${CLAUDE_PLUGIN_ROOT} pointer at each
# site; the extracted bodies must not reappear inline.

set -euo pipefail

echo "Testing work.md structure (progressive disclosure)..."

WORK_FILE="plugins/pokayokay/commands/work.md"
REF_DIR="plugins/pokayokay/skills/work-session/references"

# Test 1: extracted reference files exist
echo "Test 1: Extracted reference files exist"
for ref in chain-state.md kaizen-review-failures.md dispatch-preparation.md; do
  if [[ ! -f "$REF_DIR/$ref" ]]; then
    echo "  FAIL: $REF_DIR/$ref not found"
    exit 1
  fi
done
echo "  PASS: chain-state.md, kaizen-review-failures.md, dispatch-preparation.md exist"

# Test 2: work.md points to chain-state.md via CLAUDE_PLUGIN_ROOT
echo "Test 2: chain-state.md pointer in work.md"
if grep -qF 'CLAUDE_PLUGIN_ROOT}/skills/work-session/references/chain-state.md' "$WORK_FILE"; then
  echo "  PASS: chain-state pointer present"
else
  echo "  FAIL: chain-state pointer missing"
  exit 1
fi

# Test 3: work.md points to kaizen-review-failures.md via CLAUDE_PLUGIN_ROOT
echo "Test 3: kaizen-review-failures.md pointer in work.md"
if grep -qF 'CLAUDE_PLUGIN_ROOT}/skills/work-session/references/kaizen-review-failures.md' "$WORK_FILE"; then
  echo "  PASS: kaizen pointer present"
else
  echo "  FAIL: kaizen pointer missing"
  exit 1
fi

# Test 4: work.md points to dispatch-preparation.md (Brainstorm Gate source)
echo "Test 4: dispatch-preparation.md pointer in work.md"
if grep -qF 'CLAUDE_PLUGIN_ROOT}/skills/work-session/references/dispatch-preparation.md' "$WORK_FILE"; then
  echo "  PASS: dispatch-preparation pointer present"
else
  echo "  FAIL: dispatch-preparation pointer missing"
  exit 1
fi

# Test 5: extracted chain-state bodies are gone from work.md
echo "Test 5: Chain-state section bodies extracted"
for marker in "#### Chain State Fields" "### Chain Reporting" "### Scope Filtering" "get_scoped_tasks"; do
  if grep -qF "$marker" "$WORK_FILE"; then
    echo "  FAIL: '$marker' still inline in work.md"
    exit 1
  fi
done
if grep -qF "Chain State Fields" "$REF_DIR/chain-state.md" && \
   grep -qF "get_scoped_tasks" "$REF_DIR/chain-state.md"; then
  echo "  PASS: Chain-state bodies live only in chain-state.md"
else
  echo "  FAIL: Extracted chain-state content not found in chain-state.md"
  exit 1
fi

# Test 6: kaizen JSON contract block is gone from work.md
echo "Test 6: Kaizen review-failure body extracted"
if grep -qF '"action": "AUTO"' "$WORK_FILE"; then
  echo "  FAIL: kaizen JSON contract still inline in work.md"
  exit 1
fi
if grep -qF '"action": "AUTO"' "$REF_DIR/kaizen-review-failures.md"; then
  echo "  PASS: Kaizen contract lives only in kaizen-review-failures.md"
else
  echo "  FAIL: Kaizen contract not found in kaizen-review-failures.md"
  exit 1
fi

# Test 7: Brainstorm Gate body deduplicated (dispatch-preparation.md is source)
echo "Test 7: Brainstorm Gate deduplicated"
for marker in "def needs_brainstorm" "#### Brainstorm Flow"; do
  if grep -qF "$marker" "$WORK_FILE"; then
    echo "  FAIL: '$marker' still inline in work.md"
    exit 1
  fi
done
if grep -qF "AC Quality Check" "$REF_DIR/dispatch-preparation.md" && \
   grep -qF "{TRIGGER_REASON}" "$REF_DIR/dispatch-preparation.md"; then
  echo "  PASS: Brainstorm Gate details live in dispatch-preparation.md"
else
  echo "  FAIL: Brainstorm Gate details missing from dispatch-preparation.md"
  exit 1
fi

# Test 8: load-bearing headings preserved in work.md
echo "Test 8: Load-bearing headings preserved"
for heading in "### 2. Route to Skill" "### 3. Brainstorm Gate (Conditional)" "### 4. Dispatch Implementer Subagent"; do
  if ! grep -qF "$heading" "$WORK_FILE"; then
    echo "  FAIL: heading '$heading' missing from work.md"
    exit 1
  fi
done
echo "  PASS: Route/Brainstorm/Dispatch headings intact"

# Test 9: new reference files respect the 500-line cap
echo "Test 9: Reference size cap"
for ref in chain-state.md kaizen-review-failures.md; do
  lines=$(wc -l < "$REF_DIR/$ref")
  if [[ "$lines" -ge 500 ]]; then
    echo "  FAIL: $ref is $lines lines (cap: 500)"
    exit 1
  fi
done
echo "  PASS: New references under 500 lines"

echo ""
echo "All work structure tests passed!"
