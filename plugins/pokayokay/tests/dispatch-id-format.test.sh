#!/usr/bin/env bash
# Doc-contract test: every dispatch ID a coordinator can copy from the docs
# must be plugin-qualified (pokayokay:yokay-<name>), never a bare yokay- label.
# Scans commands, agent templates, SKILL.md files, and skill references.
# File-path references like agents/yokay-<name>.md are legitimate and ignored.

set -euo pipefail

echo "Testing dispatch ID format in documentation..."

DOC_FILES=(
  plugins/pokayokay/commands/*.md
  plugins/pokayokay/agents/templates/*.md
  plugins/pokayokay/skills/*/SKILL.md
  plugins/pokayokay/skills/*/references/*.md
)

# Test 1: no legacy "Task tool (yokay-..." dispatch shorthand anywhere
echo "Test 1: No 'Task tool (yokay-' shorthand"
if grep -n "Task tool (yokay-" "${DOC_FILES[@]}" ; then
  echo "  FAIL: legacy 'Task tool (yokay-' shorthand found (see matches above)"
  exit 1
else
  echo "  PASS: No legacy dispatch shorthand"
fi

# Test 2: every subagent_type line naming a yokay- agent is plugin-qualified.
# Note: 'pokayokay' itself contains 'yokay', so check for lines with 'yokay-'
# that lack the qualified 'pokayokay:yokay-' form.
echo "Test 2: subagent_type lines are plugin-qualified"
if grep -rn "subagent_type" "${DOC_FILES[@]}" | grep "yokay-" | grep -v "pokayokay:yokay-" ; then
  echo "  FAIL: unqualified subagent_type dispatch ID found (see matches above)"
  exit 1
else
  echo "  PASS: All subagent_type dispatch IDs qualified"
fi

# Test 3: no '**Agent**:' gate label with a bare yokay- ID (backticks optional)
echo "Test 3: Agent gate labels are plugin-qualified"
if grep -rnE '\*\*Agent\*\*:.*`?yokay-' "${DOC_FILES[@]}" | grep -v "pokayokay:yokay-" ; then
  echo "  FAIL: bare '**Agent**: yokay-...' label found (see matches above)"
  exit 1
else
  echo "  PASS: All Agent gate labels qualified"
fi

echo ""
echo "All dispatch ID format tests passed!"
