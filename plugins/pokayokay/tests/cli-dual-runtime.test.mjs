#!/usr/bin/env node
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

import {
  getCodexConfigDir,
  getCodexConfigPath,
  getClaudeConfigPath,
} from '../../../cli/src/utils/platform.js';
import {
  isMcpConfigured,
  readCodexConfig,
  writeCodexHookBridgeConfig,
  writeCodexConfig,
  writeCodexMcpServer,
  upsertCodexMcpServer,
} from '../../../cli/src/utils/config.js';
import { selectDefaultInstallTargets } from '../../../cli/src/detect.js';

console.log('Testing CLI dual-runtime helpers...');

console.log('Test 1: Codex config helpers are separate from Claude');
assert.ok(getCodexConfigDir().endsWith('.codex'));
assert.ok(getCodexConfigPath().endsWith(join('.codex', 'config.toml')));
assert.notEqual(getCodexConfigPath(), getClaudeConfigPath());
console.log('  PASS: config paths are runtime-specific');

console.log('Test 2: Codex MCP config can be written and read');
const tempDir = mkdtempSync(join(tmpdir(), 'pokayokay-codex-config-'));
try {
  const configPath = join(tempDir, 'config.toml');
  const backupPath = writeCodexConfig(configPath, {
    mcpServers: {
      ohno: {
        command: 'npx',
        args: ['@stevestomp/ohno-mcp'],
      },
    },
  });
  assert.equal(backupPath, null);
  const content = readFileSync(configPath, 'utf8');
  assert.match(content, /\[mcp_servers\.ohno\]/);
  assert.match(content, /command = "npx"/);
  assert.match(content, /args = \["@stevestomp\/ohno-mcp"\]/);

  const parsed = readCodexConfig(configPath);
  assert.equal(parsed.mcpServers.ohno.command, 'npx');
  assert.deepEqual(parsed.mcpServers.ohno.args, ['@stevestomp/ohno-mcp']);
  assert.equal(isMcpConfigured(parsed, 'ohno'), true);
  console.log('  PASS: Codex config round-trips ohno MCP');
} finally {
  rmSync(tempDir, { recursive: true, force: true });
}

console.log('Test 3: Codex MCP upsert preserves existing servers');
const updated = upsertCodexMcpServer(
  {
    mcpServers: {
      github: {
        command: 'npx',
        args: ['github-mcp'],
      },
    },
  },
  'ohno',
  { command: 'npx', args: ['@stevestomp/ohno-mcp'] }
);
assert.equal(updated.mcpServers.github.command, 'npx');
assert.equal(updated.mcpServers.ohno.command, 'npx');
console.log('  PASS: upsert preserves other MCP servers');

console.log('Test 4: default install target includes all detected runtimes');
assert.deepEqual(selectDefaultInstallTargets({ claudeInstalled: true, codexInstalled: true }), ['claude', 'codex']);
assert.deepEqual(selectDefaultInstallTargets({ claudeInstalled: true, codexInstalled: false }), ['claude']);
assert.deepEqual(selectDefaultInstallTargets({ claudeInstalled: false, codexInstalled: true }), ['codex']);
console.log('  PASS: runtime target defaults are dual-runtime aware');

console.log('Test 5: writeCodexMcpServer is idempotent on CRLF-encoded configs');
// On Windows, ~/.codex/config.toml may use CRLF line endings. Without the
// CRLF normalization in config.js, the section-replacement regex would
// miss the existing block and append a duplicate `[mcp_servers.<name>]`
// section. This test pins down that idempotence.
{
  const crlfDir = mkdtempSync(join(tmpdir(), 'pokayokay-codex-crlf-'));
  try {
    const configPath = join(crlfDir, 'config.toml');
    const initial = '[mcp_servers.ohno]\ncommand = "npx"\nargs = ["old"]\n';
    writeFileSync(configPath, initial.replace(/\n/g, '\r\n'));

    writeCodexMcpServer(configPath, 'ohno', {
      command: 'npx',
      args: ['@stevestomp/ohno-mcp'],
    });

    const result = readFileSync(configPath, 'utf8');
    const occurrences = (result.match(/\[mcp_servers\.ohno\]/g) || []).length;
    assert.equal(occurrences, 1, 'CRLF input should not produce a duplicate section');
    assert.match(result, /args = \["@stevestomp\/ohno-mcp"\]/);
    console.log('  PASS: CRLF-encoded section is upserted in place');
  } finally {
    rmSync(crlfDir, { recursive: true, force: true });
  }
}

console.log('Test 6: writeCodexHookBridgeConfig enables hooks idempotently');
{
  const hooksDir = mkdtempSync(join(tmpdir(), 'pokayokay-codex-hooks-'));
  try {
    const configPath = join(hooksDir, 'config.toml');
    writeFileSync(configPath, 'model = "gpt-5.3-codex"\n\n[features]\nfoo = true\n');

    writeCodexHookBridgeConfig(configPath, '/repo/plugins/pokayokay');
    const firstResult = readFileSync(configPath, 'utf8');
    const backupPath = writeCodexHookBridgeConfig(configPath, '/repo/plugins/pokayokay');

    const result = readFileSync(configPath, 'utf8');
    assert.equal(result, firstResult, 'second identical write should not change config');
    assert.equal(backupPath, null, 'second identical write should not create backup');
    assert.match(result, /model = "gpt-5\.3-codex"/);
    assert.match(result, /\[features\]\nfoo = true\ncodex_hooks = true/);
    assert.equal((result.match(/BEGIN pokayokay hooks/g) || []).length, 1);
    assert.equal((result.match(/bridge\.py/g) || []).length, 5);
    assert.match(result, /matcher = "startup\|resume\|clear\|compact"/);
    assert.match(result, /\[\[hooks\.SessionEnd\]\]/);
    assert.match(result, /\[\[hooks\.PermissionRequest\]\]/);
    const preToolUseBlock = result.match(/\[\[hooks\.PreToolUse\]\][\s\S]*?(?=\n\[\[hooks\.|\n# END pokayokay hooks|$)/);
    assert.ok(preToolUseBlock, 'PreToolUse block should exist');
    assert.match(preToolUseBlock[0], /matcher = "Bash\|bash\|exec_command"/);
    assert.doesNotMatch(preToolUseBlock[0], /matcher = "Bash\|apply_patch\|Edit\|Write"/);
    const permissionRequestBlock = result.match(/\[\[hooks\.PermissionRequest\]\][\s\S]*?(?=\n\[\[hooks\.|\n# END pokayokay hooks|$)/);
    assert.ok(permissionRequestBlock, 'PermissionRequest block should exist');
    assert.match(permissionRequestBlock[0], /matcher = "Bash"/);
    assert.doesNotMatch(permissionRequestBlock[0], /matcher = "Bash\|apply_patch\|Edit\|Write"/);
    console.log('  PASS: Codex hook wiring is appended once and preserves config');
  } finally {
    rmSync(hooksDir, { recursive: true, force: true });
  }
}

console.log('Test 7: writeCodexHookBridgeConfig reuses [features] at EOF');
{
  const eofFeaturesDir = mkdtempSync(join(tmpdir(), 'pokayokay-codex-features-eof-'));
  try {
    const configPath = join(eofFeaturesDir, 'config.toml');
    writeFileSync(configPath, '[features]');

    writeCodexHookBridgeConfig(configPath, '/repo/plugins/pokayokay');

    const result = readFileSync(configPath, 'utf8');
    assert.equal((result.match(/\[features\]/g) || []).length, 1, 'should not duplicate [features]');
    assert.match(result, /\[features\]\ncodex_hooks = true/);
    console.log('  PASS: EOF [features] section is updated in place');
  } finally {
    rmSync(eofFeaturesDir, { recursive: true, force: true });
  }
}

console.log('Test 8: writeCodexHookBridgeConfig normalizes Windows-style paths');
{
  const hooksDir = mkdtempSync(join(tmpdir(), 'pokayokay-codex-windows-hooks-'));
  try {
    const configPath = join(hooksDir, 'config.toml');
    writeCodexHookBridgeConfig(configPath, 'C:\\Users\\steve\\pokayokay\\plugins\\pokayokay\\');

    const result = readFileSync(configPath, 'utf8');
    assert.match(result, /C:\\\\Users\\\\steve\\\\pokayokay\\\\plugins\\\\pokayokay\\\\hooks\\\\actions\\\\bridge\.py/);
    assert.doesNotMatch(result, /\\\\\/hooks/);
    console.log('  PASS: Windows path remains consistently escaped in TOML');
  } finally {
    rmSync(hooksDir, { recursive: true, force: true });
  }
}

console.log('Test 9: writeCodexHookBridgeConfig keeps root-level keys at root');
{
  const rootKeysDir = mkdtempSync(join(tmpdir(), 'pokayokay-codex-root-keys-'));
  try {
    const configPath = join(rootKeysDir, 'config.toml');
    writeFileSync(
      configPath,
      [
        'model = "gpt-5-codex"',
        'approval_policy = "never"',
        'sandbox_mode = "workspace-write"',
        '',
        '[mcp_servers.ohno]',
        'command = "npx"',
        'args = ["@stevestomp/ohno-mcp"]',
        '',
      ].join('\n')
    );

    writeCodexHookBridgeConfig(configPath, '/repo/plugins/pokayokay');

    const result = readFileSync(configPath, 'utf8');
    // In TOML, keys after a table header belong to that table. When no
    // [features] table exists yet it must be APPENDED after existing content;
    // prepending it above root-level keys silently swallows the user's
    // model/approval_policy/sandbox_mode into the features table.
    const firstTableIndex = result.search(/^\[/m);
    assert.ok(firstTableIndex !== -1, 'config should contain table headers');
    for (const rootKey of ['model = "gpt-5-codex"', 'approval_policy = "never"', 'sandbox_mode = "workspace-write"']) {
      const keyIndex = result.indexOf(rootKey);
      assert.ok(keyIndex !== -1, `${rootKey} should survive the write`);
      assert.ok(
        keyIndex < firstTableIndex,
        `${rootKey} must stay above the first table header (root scope)`
      );
    }
    assert.match(result, /\[features\]\ncodex_hooks = true/);
    const parsed = readCodexConfig(configPath);
    assert.equal(parsed.mcpServers.ohno.command, 'npx');
    assert.deepEqual(parsed.mcpServers.ohno.args, ['@stevestomp/ohno-mcp']);
    console.log('  PASS: [features] is appended after root keys, not prepended');
  } finally {
    rmSync(rootKeysDir, { recursive: true, force: true });
  }
}

console.log('Test 10: installPlugin reports Codex hook bridge scope');
{
  const pluginStepSource = readFileSync(new URL('../../../cli/src/steps/plugin.js', import.meta.url), 'utf8');
  assert.match(
    pluginStepSource,
    /installedScopes\.push\('Codex marketplace', 'Codex plugin', 'Codex hook bridge'\)/,
    'Codex install summary should include marketplace, plugin add, and hook bridge work'
  );
  assert.match(
    pluginStepSource,
    /\['plugin', 'add', 'pokayokay@pokayokay'\]/,
    'Codex install must run `codex plugin add` after registering the marketplace'
  );
  assert.match(pluginStepSource, /Failed to complete Codex setup/);
  assert.doesNotMatch(pluginStepSource, /Failed to write Codex marketplace entry/);
  assert.doesNotMatch(pluginStepSource, /codex plugin install/);
  assert.doesNotMatch(pluginStepSource, /pokayokay@srstomp-pokayokay/);
  console.log('  PASS: Codex install summary includes hook bridge wiring');
}

console.log('');
console.log('All CLI dual-runtime tests passed!');
