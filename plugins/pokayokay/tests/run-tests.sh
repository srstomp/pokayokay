#!/bin/bash
# pokayokay test suite runner.
# - Runs every *.test.sh in this directory via bash
# - Runs every *.test.mjs (e.g. cli-dual-runtime.test.mjs) via node
# - Prints per-test PASS/FAIL and a summary
# - Exits non-zero if any test fails
# pressure/ is excluded: it is a manual evaluation checklist, not automated tests.

set -u

# Prerequisites: several bridge/WIP tests need jq, and cli-*.test.mjs need
# cli/node_modules (npm ci --prefix cli). Fail loudly, not mysteriously.
missing=""
command -v jq >/dev/null 2>&1 || missing="$missing jq"
command -v python3 >/dev/null 2>&1 || missing="$missing python3"
command -v node >/dev/null 2>&1 || missing="$missing node"
if [ -n "$missing" ]; then
  echo "ERROR: missing required tools:$missing" >&2
  exit 1
fi

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TESTS_DIR/../../.." && pwd)"

# Several tests reference files relative to the repo root; normalize cwd
# so the suite behaves the same regardless of where it is invoked from.
cd "$REPO_ROOT" || exit 1

pass_count=0
fail_count=0
failed_tests=()

run_one() {
  local runner="$1"
  local test_file="$2"
  local name output
  name="$(basename "$test_file")"

  if output="$("$runner" "$test_file" 2>&1)"; then
    echo "PASS  $name"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL  $name"
    printf '%s\n' "$output" | tail -40 | sed 's/^/      | /'
    fail_count=$((fail_count + 1))
    failed_tests+=("$runner plugins/pokayokay/tests/$name")
  fi
}

echo "Running pokayokay test suite..."
echo ""

for test_file in "$TESTS_DIR"/*.test.sh; do
  [ -f "$test_file" ] || continue
  run_one bash "$test_file"
done

for test_file in "$TESTS_DIR"/*.test.mjs; do
  [ -f "$test_file" ] || continue
  run_one node "$test_file"
done

echo ""
echo "============================================================"
echo "Summary: $pass_count passed, $fail_count failed"
echo "============================================================"

if [ "$fail_count" -gt 0 ]; then
  echo ""
  echo "Failed tests (re-run individually for details):"
  for cmd in "${failed_tests[@]}"; do
    echo "  $cmd"
  done
  exit 1
fi

exit 0
