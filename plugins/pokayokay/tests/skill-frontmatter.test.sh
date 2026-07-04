#!/usr/bin/env bash
# Validate SKILL.md frontmatter hygiene: no non-spec agents: key, no dangling frontmatter references.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PLUGIN="$ROOT/plugins/pokayokay"

echo "Testing SKILL.md frontmatter hygiene..."

echo "Test 1: no SKILL.md frontmatter contains the non-spec 'agents:' key"
FAILED=0
for skill in "$PLUGIN"/skills/*/SKILL.md; do
  if awk '/^---$/{n++; next} n==1 && /^agents:/{found=1} END{exit !found}' "$skill"; then
    echo "  FAIL: agents: key in frontmatter of $skill"
    FAILED=1
  fi
done
if [[ "$FAILED" -eq 0 ]]; then
  echo "  PASS: no agents: key in any SKILL.md frontmatter"
else
  exit 1
fi

echo "Test 2: no Runtime Notes bullet references 'agents listed in this skill's frontmatter'"
if grep -rn "listed in this skill's frontmatter" "$PLUGIN/skills/" >/dev/null 2>&1; then
  echo "  FAIL: dangling frontmatter reference found:"
  grep -rn "listed in this skill's frontmatter" "$PLUGIN/skills/" | sed 's/^/    /'
  exit 1
fi
echo "  PASS: no dangling frontmatter references"

echo "Test 3: every SKILL.md 'name' matches its folder"
FAILED=0
for skill in "$PLUGIN"/skills/*/SKILL.md; do
  folder="$(basename "$(dirname "$skill")")"
  name="$(awk '/^---$/{n++; next} n==1 && /^name:/{sub(/^name:[ ]*/, ""); print; exit}' "$skill")"
  if [[ "$name" != "$folder" ]]; then
    echo "  FAIL: $skill has name '$name' but folder '$folder'"
    FAILED=1
  fi
done
if [[ "$FAILED" -eq 0 ]]; then
  echo "  PASS: all SKILL.md names match their folders"
else
  exit 1
fi

echo ""
echo "All skill frontmatter tests passed."
