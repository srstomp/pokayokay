#!/usr/bin/env bash
# Validate the Codex plugin surface exists without removing Claude support.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
PLUGIN="$ROOT/plugins/pokayokay"

echo "Testing Codex compatibility files..."

echo "Test 1: Claude manifest is still present"
if [[ -f "$PLUGIN/.claude-plugin/plugin.json" ]]; then
  echo "  PASS: Claude manifest remains"
else
  echo "  FAIL: Claude manifest missing"
  exit 1
fi

echo "Test 2: Codex manifest exists and points at shared skills/MCP"
CODEX_MANIFEST="$PLUGIN/.codex-plugin/plugin.json"
if [[ ! -f "$CODEX_MANIFEST" ]]; then
  echo "  FAIL: Codex manifest missing"
  exit 1
fi

node -e '
const fs = require("fs");
const manifest = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
if (manifest.name !== "pokayokay") throw new Error("unexpected manifest name");
if (manifest.skills !== "./skills/") throw new Error("skills path missing");
if (manifest.mcpServers !== "./.mcp.json") throw new Error("mcpServers path missing");
if (!manifest.interface || manifest.interface.displayName !== "Pokayokay") throw new Error("interface metadata missing");
' "$CODEX_MANIFEST"
echo "  PASS: Codex manifest parses"

echo "Test 3: ohno MCP config exists for plugin runtime"
MCP_CONFIG="$PLUGIN/.mcp.json"
if [[ ! -f "$MCP_CONFIG" ]]; then
  echo "  FAIL: .mcp.json missing"
  exit 1
fi

node -e '
const fs = require("fs");
const config = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
const ohno = config.mcpServers && config.mcpServers.ohno;
if (!ohno) throw new Error("ohno server missing");
if (ohno.command !== "npx") throw new Error("ohno command should use npx");
if (!ohno.args || !ohno.args.includes("@stevestomp/ohno-mcp")) throw new Error("ohno package missing");
' "$MCP_CONFIG"
echo "  PASS: ohno MCP config parses"

echo "Test 4: Codex hook config calls bridge.py"
HOOKS="$PLUGIN/hooks.json"
if [[ ! -f "$HOOKS" ]]; then
  echo "  FAIL: hooks.json missing"
  exit 1
fi

node -e '
const fs = require("fs");
const hooks = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).hooks || {};
const serialized = JSON.stringify(hooks);
if (!serialized.includes("bridge.py")) throw new Error("bridge.py not referenced");
if (!hooks.PostToolUse) throw new Error("PostToolUse hook missing");
if (!hooks.SessionEnd) throw new Error("SessionEnd hook missing");
const preMatcher = hooks.PreToolUse && hooks.PreToolUse[0] && hooks.PreToolUse[0].matcher;
if (preMatcher !== "Bash|bash|exec_command") throw new Error("PreToolUse should only match Bash tool aliases");
const permissionMatcher = hooks.PermissionRequest && hooks.PermissionRequest[0] && hooks.PermissionRequest[0].matcher;
if (permissionMatcher !== "Bash") throw new Error("PermissionRequest should only match Bash");
' "$HOOKS"
echo "  PASS: Codex hooks config parses"

echo "Test 5: Claude plugin hook config exists at hooks/hooks.json"
CLAUDE_HOOKS="$PLUGIN/hooks/hooks.json"
if [[ ! -f "$CLAUDE_HOOKS" ]]; then
  echo "  FAIL: hooks/hooks.json missing"
  exit 1
fi

node -e '
const fs = require("fs");
const hooks = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).hooks || {};
const serialized = JSON.stringify(hooks);
if (!serialized.includes("bridge.py")) throw new Error("bridge.py not referenced");
if (!hooks.PostToolUse) throw new Error("PostToolUse hook missing");
if (!hooks.SessionStart) throw new Error("SessionStart hook missing");
' "$CLAUDE_HOOKS"
echo "  PASS: Claude hooks config parses"

echo ""
echo "All Codex compatibility file tests passed!"
