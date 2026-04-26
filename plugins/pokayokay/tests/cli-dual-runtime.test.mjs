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

console.log('');
console.log('All CLI dual-runtime tests passed!');
