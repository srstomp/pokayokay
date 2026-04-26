import { readFileSync, writeFileSync, copyFileSync, existsSync, mkdirSync } from 'node:fs';
import { dirname, join, win32 } from 'node:path';

/**
 * Read Claude config file, return empty object if not found
 * @param {string} configPath - Path to config file
 * @returns {object} Parsed config or empty object
 */
export function readClaudeConfig(configPath) {
  try {
    if (!existsSync(configPath)) {
      return {};
    }
    const content = readFileSync(configPath, 'utf-8');
    return JSON.parse(content);
  } catch (err) {
    // If file exists but is invalid JSON, return empty object
    return {};
  }
}

/**
 * Write Claude config file with backup
 * @param {string} configPath - Path to config file
 * @param {object} config - Config object to write
 * @returns {string|null} Backup path if created, null otherwise
 */
export function writeClaudeConfig(configPath, config) {
  let backupPath = null;

  // Ensure directory exists
  const dir = dirname(configPath);
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }

  // Backup existing config
  if (existsSync(configPath)) {
    backupPath = `${configPath}.backup-${Date.now()}`;
    copyFileSync(configPath, backupPath);
  }

  // Write new config
  writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');

  return backupPath;
}

function backupExisting(configPath) {
  let backupPath = null;
  const dir = dirname(configPath);
  if (!existsSync(dir)) {
    mkdirSync(dir, { recursive: true });
  }

  if (existsSync(configPath)) {
    backupPath = `${configPath}.backup-${Date.now()}`;
    copyFileSync(configPath, backupPath);
  }

  return backupPath;
}

function quoteTomlString(value) {
  return JSON.stringify(String(value));
}

function formatTomlStringArray(values) {
  return `[${values.map(quoteTomlString).join(', ')}]`;
}

function parseTomlArray(value) {
  const trimmed = value.trim();
  if (!trimmed.startsWith('[') || !trimmed.endsWith(']')) {
    return [];
  }

  try {
    return JSON.parse(trimmed);
  } catch {
    return trimmed
      .slice(1, -1)
      .split(',')
      .map((item) => item.trim().replace(/^"|"$/g, ''))
      .filter(Boolean);
  }
}

/**
 * Read the subset of Codex config.toml needed by pokayokay.
 * @param {string} configPath - Path to config.toml
 * @returns {object} Parsed config with mcpServers
 */
export function readCodexConfig(configPath) {
  if (!existsSync(configPath)) {
    return {};
  }

  const config = { mcpServers: {} };
  let currentMcpServer = null;

  for (const line of readFileSync(configPath, 'utf-8').split(/\r?\n/)) {
    const section = line.match(/^\[mcp_servers\.([^\]]+)\]\s*$/);
    if (section) {
      currentMcpServer = section[1].replace(/^"|"$/g, '');
      config.mcpServers[currentMcpServer] = config.mcpServers[currentMcpServer] || {};
      continue;
    }

    if (line.startsWith('[')) {
      currentMcpServer = null;
      continue;
    }

    if (!currentMcpServer) {
      continue;
    }

    const command = line.match(/^\s*command\s*=\s*"([^"]*)"\s*$/);
    if (command) {
      config.mcpServers[currentMcpServer].command = command[1];
      continue;
    }

    const args = line.match(/^\s*args\s*=\s*(\[.*\])\s*$/);
    if (args) {
      config.mcpServers[currentMcpServer].args = parseTomlArray(args[1]);
    }
  }

  return Object.keys(config.mcpServers).length ? config : {};
}

/**
 * Add or replace one MCP server in a Codex config object.
 * @param {object} config - Existing parsed config
 * @param {string} serverName - MCP server name
 * @param {object} serverConfig - MCP server config
 * @returns {object} New config object
 */
export function upsertCodexMcpServer(config, serverName, serverConfig) {
  return {
    ...config,
    mcpServers: {
      ...(config.mcpServers || {}),
      [serverName]: serverConfig,
    },
  };
}

function codexMcpSection(serverName, serverConfig) {
  const lines = [
    `[mcp_servers.${serverName}]`,
    `command = ${quoteTomlString(serverConfig.command)}`,
  ];

  if (serverConfig.args) {
    lines.push(`args = ${formatTomlStringArray(serverConfig.args)}`);
  }

  return `${lines.join('\n')}\n`;
}

const POKAYOKAY_HOOKS_START = '# BEGIN pokayokay hooks';
const POKAYOKAY_HOOKS_END = '# END pokayokay hooks';

function removePokayokayHooksBlock(content) {
  const blockPattern = new RegExp(
    `\\n?${POKAYOKAY_HOOKS_START.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}[\\s\\S]*?${POKAYOKAY_HOOKS_END.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\n?`,
    'g'
  );
  return content.replace(blockPattern, '\n').replace(/\n{3,}/g, '\n\n').trimEnd();
}

function enableCodexHooksFeature(content) {
  const featureLine = 'codex_hooks = true';
  const featuresPattern = /(\[features\]\n)([\s\S]*?)(?=\n\[[^\]]+\]|\s*$)/;

  if (featuresPattern.test(content)) {
    return content.replace(featuresPattern, (_match, header, body) => {
      const nextBody = /^\s*codex_hooks\s*=.*$/m.test(body)
        ? body.replace(/^\s*codex_hooks\s*=.*$/m, featureLine)
        : `${body.trimEnd()}\n${featureLine}\n`;
      return `${header}${nextBody}`;
    });
  }

  const separator = content.trim().length ? '\n\n' : '';
  return `[features]\n${featureLine}\n${separator}${content.trimEnd()}`;
}

function codexHookBridgeBlock(pluginPath) {
  const pluginRoot = String(pluginPath).replace(/[\\/]+$/, '');
  const bridgePath = pluginRoot.includes('\\')
    ? win32.join(pluginRoot, 'hooks', 'actions', 'bridge.py')
    : join(pluginRoot, 'hooks', 'actions', 'bridge.py');
  const command = quoteTomlString(bridgePath);

  return [
    POKAYOKAY_HOOKS_START,
    '[[hooks.SessionStart]]',
    'matcher = "startup|resume|clear|compact"',
    '[[hooks.SessionStart.hooks]]',
    'type = "command"',
    `command = ${command}`,
    'timeout = 30',
    'statusMessage = "Preparing pokayokay session"',
    '',
    '[[hooks.PreToolUse]]',
    'matcher = "Bash"',
    '[[hooks.PreToolUse.hooks]]',
    'type = "command"',
    `command = ${command}`,
    'timeout = 30',
    'statusMessage = "Checking pokayokay tool policy"',
    '',
    '[[hooks.PermissionRequest]]',
    'matcher = "Bash"',
    '[[hooks.PermissionRequest.hooks]]',
    'type = "command"',
    `command = ${command}`,
    'timeout = 10',
    'statusMessage = "Reviewing pokayokay approval policy"',
    '',
    '[[hooks.PostToolUse]]',
    'matcher = "Bash|apply_patch|Edit|Write|mcp__ohno__.*"',
    '[[hooks.PostToolUse.hooks]]',
    'type = "command"',
    `command = ${command}`,
    'timeout = 30',
    'statusMessage = "Recording pokayokay work state"',
    '',
    '[[hooks.SessionEnd]]',
    '[[hooks.SessionEnd.hooks]]',
    'type = "command"',
    `command = ${command}`,
    'timeout = 30',
    'statusMessage = "Finalizing pokayokay session"',
    POKAYOKAY_HOOKS_END,
  ].join('\n');
}

/**
 * Write a minimal Codex config.toml from a parsed config object.
 * @param {string} configPath - Path to config.toml
 * @param {object} config - Config object
 * @returns {string|null} Backup path if created, null otherwise
 */
export function writeCodexConfig(configPath, config) {
  const backupPath = backupExisting(configPath);
  const sections = Object.entries(config.mcpServers || {})
    .map(([name, server]) => codexMcpSection(name, server));

  writeFileSync(configPath, `${sections.join('\n')}`.trimEnd() + '\n');
  return backupPath;
}

/**
 * Upsert one MCP server section into an existing Codex config.toml while
 * preserving unrelated config.
 * @param {string} configPath - Path to config.toml
 * @param {string} serverName - MCP server name
 * @param {object} serverConfig - MCP server config
 * @returns {string|null} Backup path if created, null otherwise
 */
export function writeCodexMcpServer(configPath, serverName, serverConfig) {
  const backupPath = backupExisting(configPath);
  const rawExisting = existsSync(configPath) ? readFileSync(configPath, 'utf-8') : '';
  // Normalize line endings to LF so Windows-edited config.toml files
  // (CRLF) are still recognized by the section-replacement regex; without
  // this, a pre-existing `[mcp_servers.<name>]` block on CRLF would not
  // match and we'd append a duplicate section.
  const existing = rawExisting.replace(/\r\n/g, '\n');
  const section = codexMcpSection(serverName, serverConfig);
  const header = `[mcp_servers.${serverName}]`;
  const escaped = header.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const sectionPattern = new RegExp(`${escaped}\\n[\\s\\S]*?(?=\\n\\[[^\\]]+\\]|\\s*$)`);

  let next;
  if (sectionPattern.test(existing)) {
    next = existing.replace(sectionPattern, section.trimEnd());
  } else {
    const separator = existing.trim().length ? '\n\n' : '';
    next = `${existing.trimEnd()}${separator}${section.trimEnd()}`;
  }

  writeFileSync(configPath, `${next.trimEnd()}\n`);
  return backupPath;
}

/**
 * Upsert Codex hook configuration for the pokayokay bridge while preserving
 * unrelated config.toml content. This enables Codex's hook feature and keeps
 * the pokayokay hook block idempotent with visible ownership markers.
 * @param {string} configPath - Path to Codex config.toml
 * @param {string} pluginPath - Absolute path to the pokayokay plugin root
 * @returns {string|null} Backup path if created, null otherwise
 */
export function writeCodexHookBridgeConfig(configPath, pluginPath) {
  const rawExisting = existsSync(configPath) ? readFileSync(configPath, 'utf-8') : '';
  const existing = rawExisting.replace(/\r\n/g, '\n');
  const withoutOldBlock = removePokayokayHooksBlock(existing);
  const withFeature = enableCodexHooksFeature(withoutOldBlock);
  const next = `${withFeature.trimEnd()}\n\n${codexHookBridgeBlock(pluginPath)}\n`;

  if (existing === next) {
    return null;
  }

  const backupPath = backupExisting(configPath);
  writeFileSync(configPath, next);
  return backupPath;
}

/**
 * Check if MCP server is configured
 * @param {object} config - Claude config object
 * @param {string} serverName - MCP server name to check
 * @returns {boolean} True if server is configured
 */
export function isMcpConfigured(config, serverName) {
  return !!(config.mcpServers && config.mcpServers[serverName]);
}
