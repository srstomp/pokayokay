# Dual Runtime Codex Support Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add Codex plugin support beside existing Claude Code support without removing or weakening the Claude runtime path.

**Architecture:** Keep Pokayokay's commands, skills, agents, and hook scripts shared. Add Codex-specific manifests/config files, make the CLI detect and configure both runtimes, and normalize hook payloads before routing them through the existing bridge logic.

**Tech Stack:** Shell tests, Node.js ESM CLI modules, Python hook bridge, JSON/TOML-like config generation, existing Pokayokay plugin layout.

---

### Task 1: Red Tests for Dual Runtime Surface

**Files:**
- Create: `plugins/pokayokay/tests/codex-compatibility.test.sh`
- Create: `plugins/pokayokay/tests/cli-dual-runtime.test.mjs`
- Create: `plugins/pokayokay/tests/bridge-runtime-normalization.test.sh`

**Step 1:** Write failing tests that assert `.codex-plugin/plugin.json`, plugin `.mcp.json`, and Codex hook config exist while `.claude-plugin/plugin.json` remains.

**Step 2:** Write failing CLI tests for Codex config path helpers, MCP config writing, and runtime selection defaults.

**Step 3:** Write failing bridge tests showing Claude-style and Codex-style payloads both route file changes to the same WIP update behavior.

### Task 2: Codex Plugin Files

**Files:**
- Create: `plugins/pokayokay/.codex-plugin/plugin.json`
- Create: `plugins/pokayokay/.mcp.json`
- Create: `plugins/pokayokay/hooks.json`

**Steps:**
- Add Codex manifest metadata pointing at shared skills and MCP config.
- Add ohno MCP config.
- Add a conservative hook config that calls the existing bridge script.

### Task 3: CLI Platform Layer

**Files:**
- Modify: `cli/src/utils/platform.js`
- Modify: `cli/src/utils/config.js`
- Modify: `cli/src/utils/execute.js`
- Modify: `cli/src/detect.js`
- Modify: `cli/src/steps/mcp.js`
- Modify: `cli/src/steps/plugin.js`
- Modify: `cli/src/index.js`

**Steps:**
- Add Codex config path helpers and read/write support for `~/.codex/config.toml`.
- Detect `codex` alongside `claude`.
- Let the setup wizard target Claude, Codex, or both.
- Preserve all existing Claude config behavior.

### Task 4: Runtime-Neutral Bridge

**Files:**
- Modify: `plugins/pokayokay/hooks/actions/bridge.py`

**Steps:**
- Add a small normalization layer that accepts existing Claude payloads unchanged.
- Add support for Codex-style aliases such as lowercase tool names and `event`/`hook_event` fields.
- Use `YOKAY_PROJECT_DIR` and `CODEX_WORKSPACE_DIR` before falling back to `CLAUDE_PROJECT_DIR`/cwd.

### Task 5: Docs and Verification

**Files:**
- Modify: `README.md`
- Modify: `cli/README.md`
- Modify: selected command docs with Claude-only continuation language.

**Steps:**
- Present Pokayokay as Claude Code plus Codex compatible.
- Keep Claude install docs intact while adding Codex notes.
- Run focused new tests, then the relevant existing hook tests.
