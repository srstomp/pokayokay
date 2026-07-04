#!/usr/bin/env bash
# Validate lint.sh pre-commit lint behavior:
# - package runner selected from the lockfile (bun/pnpm/yarn lockfiles,
#   npm as the no-lockfile default), never assumed
# - missing runner and missing package.json skip with exit 0
# - lint failures are advisory (surfaced but exit 0, never blocking)
# - biome dependency without a "lint" script routes through npx biome

set -euo pipefail

TEST_DIR=$(mktemp -d)
trap 'rm -rf -- "$TEST_DIR"' EXIT

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/hooks/actions/lint.sh"
[ -f "$SCRIPT" ] || { echo "script not found: $SCRIPT"; exit 1; }

echo "Testing lint.sh..."

if bash -n "$SCRIPT"; then
  echo "  PASS: script parses (bash -n)"
else
  echo "  FAIL: bash -n reports a syntax error"
  exit 1
fi

# Mock every runner lint.sh can select; each logs its invocation and exits
# per the lint-fail flag file.
MOCK_BIN="$TEST_DIR/bin"
mkdir -p "$MOCK_BIN"
for runner in bun pnpm yarn npm npx; do
  cat > "$MOCK_BIN/$runner" << EOF
#!/usr/bin/env bash
echo "$runner \$*" >> "$TEST_DIR/calls.log"
if [ -f "$TEST_DIR/lint-fail" ]; then
  echo "lint problems found"
  exit 1
fi
exit 0
EOF
  chmod +x "$MOCK_BIN/$runner"
done
export PATH="$MOCK_BIN:$PATH"

CASE_NUM=0
new_case() {
  CASE_NUM=$((CASE_NUM + 1))
  CASE_DIR="$TEST_DIR/case-$CASE_NUM"
  mkdir -p "$CASE_DIR"
  cd "$CASE_DIR"
  : > "$TEST_DIR/calls.log"
  rm -f "$TEST_DIR/lint-fail"
}

lint_pkg_json() {
  printf '{"name":"t","scripts":{"lint":"eslint ."}}\n' > package.json
}

echo "Test 1: pnpm-lock.yaml selects pnpm"
new_case
lint_pkg_json
touch pnpm-lock.yaml
OUTPUT=$(bash "$SCRIPT")
if [[ "$OUTPUT" == *"linter (pnpm run lint) passed"* ]] && grep -q "^pnpm run lint$" "$TEST_DIR/calls.log"; then
  echo "  PASS: pnpm selected from pnpm-lock.yaml"
else
  echo "  FAIL: expected 'pnpm run lint' invocation"
  echo "$OUTPUT"; cat "$TEST_DIR/calls.log" 2>/dev/null
  exit 1
fi

echo "Test 2: bun.lock selects bun"
new_case
lint_pkg_json
touch bun.lock
OUTPUT=$(bash "$SCRIPT")
if [[ "$OUTPUT" == *"linter (bun run lint) passed"* ]] && grep -q "^bun run lint$" "$TEST_DIR/calls.log"; then
  echo "  PASS: bun selected from bun.lock"
else
  echo "  FAIL: expected 'bun run lint' invocation"
  echo "$OUTPUT"; cat "$TEST_DIR/calls.log" 2>/dev/null
  exit 1
fi

echo "Test 3: yarn.lock selects yarn"
new_case
lint_pkg_json
touch yarn.lock
OUTPUT=$(bash "$SCRIPT")
if [[ "$OUTPUT" == *"linter (yarn run lint) passed"* ]] && grep -q "^yarn run lint$" "$TEST_DIR/calls.log"; then
  echo "  PASS: yarn selected from yarn.lock"
else
  echo "  FAIL: expected 'yarn run lint' invocation"
  echo "$OUTPUT"; cat "$TEST_DIR/calls.log" 2>/dev/null
  exit 1
fi

echo "Test 4: no lockfile defaults to npm"
new_case
lint_pkg_json
OUTPUT=$(bash "$SCRIPT")
if [[ "$OUTPUT" == *"linter (npm run lint) passed"* ]] && grep -q "^npm run lint$" "$TEST_DIR/calls.log"; then
  echo "  PASS: npm used when no lockfile is present"
else
  echo "  FAIL: expected 'npm run lint' invocation"
  echo "$OUTPUT"; cat "$TEST_DIR/calls.log" 2>/dev/null
  exit 1
fi

echo "Test 5: missing runner skips with exit 0"
new_case
lint_pkg_json
touch bun.lock
RC=0
OUTPUT=$(PATH="/usr/bin:/bin" bash "$SCRIPT") || RC=$?
if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *"Lint runner not found: bun"* ]]; then
  echo "  PASS: missing bun runner skips lint without blocking"
else
  echo "  FAIL: expected 'Lint runner not found: bun' with exit 0, got exit $RC"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 6: lint failure is advisory (exit 0)"
new_case
lint_pkg_json
touch pnpm-lock.yaml
touch "$TEST_DIR/lint-fail"
RC=0
OUTPUT=$(bash "$SCRIPT") || RC=$?
if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *"failed (exit 1)"* ]] && [[ "$OUTPUT" == *"lint problems found"* ]]; then
  echo "  PASS: lint failure surfaced but did not block (exit 0)"
else
  echo "  FAIL: expected advisory failure output with exit 0, got exit $RC"
  echo "$OUTPUT"
  exit 1
fi

echo "Test 7: biome dependency without a lint script uses npx biome"
new_case
printf '{"name":"t","devDependencies":{"@biomejs/biome":"^1.9.0"}}\n' > package.json
OUTPUT=$(bash "$SCRIPT")
if [[ "$OUTPUT" == *"Biome passed"* ]] && grep -q "^npx biome check .$" "$TEST_DIR/calls.log"; then
  echo "  PASS: biome routed through npx biome check ."
else
  echo "  FAIL: expected 'npx biome check .' invocation"
  echo "$OUTPUT"; cat "$TEST_DIR/calls.log" 2>/dev/null
  exit 1
fi

echo "Test 8: no package.json skips lint"
new_case
RC=0
OUTPUT=$(bash "$SCRIPT") || RC=$?
if [ "$RC" -eq 0 ] && [[ "$OUTPUT" == *"No package.json, skipping lint"* ]]; then
  echo "  PASS: no package.json skips with exit 0"
else
  echo "  FAIL: expected package.json skip message with exit 0, got exit $RC"
  echo "$OUTPUT"
  exit 1
fi

echo ""
echo "All lint tests passed!"
