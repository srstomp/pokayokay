#!/bin/bash
# Structural lint for agent definition files (agents/yokay-*.md)
# Guards against two historically parse-breaking mistakes:
#   1. Blank line before the opening frontmatter '---' (produces agent IDs like pokayokay:AGENT)
#   2. name: not matching the filename
# Also asserts a non-empty description and a valid model value if one is set.

set -e

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(dirname "$TESTS_DIR")"
AGENTS_DIR="$PLUGIN_DIR/agents"

echo "Testing agent definition structure..."

agent_count=0
fail_count=0

fail() {
  echo "  FAIL: $1"
  fail_count=$((fail_count + 1))
}

for agent_file in "$AGENTS_DIR"/yokay-*.md; do
  [ -f "$agent_file" ] || continue
  agent_count=$((agent_count + 1))
  base="$(basename "$agent_file" .md)"
  echo "Checking $base.md"

  # Extract frontmatter (lines between first and second '---')
  frontmatter="$(awk '/^---$/{count++; next} count==1{print} count>=2{exit}' "$agent_file")"

  # Test 1: frontmatter '---' must start at byte 1 (no leading blank line or BOM)
  if [ "$(head -c 3 "$agent_file")" = "---" ] && [ "$(head -n 1 "$agent_file")" = "---" ]; then
    echo "  PASS: frontmatter starts at byte 1"
  else
    fail "file does not start with '---' at byte 1 (blank line breaks name parsing)"
  fi

  # Test 2: name matches filename minus .md
  name_value="$(echo "$frontmatter" | sed -n 's/^name:[[:space:]]*//p' | head -n1)"
  if [ "$name_value" = "$base" ]; then
    echo "  PASS: name matches filename ($base)"
  else
    fail "name '$name_value' does not match filename '$base'"
  fi

  # Test 3: description is non-empty
  description_value="$(echo "$frontmatter" | sed -n 's/^description:[[:space:]]*//p' | head -n1)"
  if [ -n "$description_value" ]; then
    echo "  PASS: description is non-empty"
  else
    fail "description is missing or empty"
  fi

  # Test 4: model, if present, must be haiku|sonnet|opus|inherit
  model_value="$(echo "$frontmatter" | sed -n 's/^model:[[:space:]]*//p' | head -n1)"
  if [ -z "$model_value" ]; then
    echo "  PASS: no model key (inherits from parent)"
  else
    case "$model_value" in
      haiku|sonnet|opus|inherit)
        echo "  PASS: model '$model_value' is valid"
        ;;
      *)
        fail "model '$model_value' is not one of haiku|sonnet|opus|inherit"
        ;;
    esac
  fi
done

echo ""
if [ "$agent_count" -eq 0 ]; then
  echo "FAIL: no agent files found in $AGENTS_DIR"
  exit 1
fi

if [ "$fail_count" -gt 0 ]; then
  echo "$fail_count check(s) failed across $agent_count agent(s)"
  exit 1
fi

echo "All agent definition checks passed ($agent_count agents)"
