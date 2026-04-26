import { existsSync, readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { getClaudeConfigPath, getCodexConfigPath, getPlatformName } from './utils/platform.js';
import { readClaudeConfig, readCodexConfig, isMcpConfigured } from './utils/config.js';
import { commandExists, getClaudeVersion, getCodexVersion } from './utils/execute.js';

/**
 * Check if pokayokay plugin is installed by checking disk paths
 * @returns {object} { installed: boolean, scope: 'global'|'local'|null }
 */
function detectClaudePluginInstalled() {
  // Check global paths
  const globalPaths = [
    join(homedir(), '.claude', 'plugins', 'installed', 'pokayokay'),
    join(homedir(), '.claude', 'plugins', 'marketplaces', 'srstomp-pokayokay', 'plugins', 'pokayokay')
  ];

  for (const p of globalPaths) {
    if (existsSync(p)) {
      return { installed: true, scope: 'global', path: p };
    }
  }

  // Check project-local
  if (existsSync('.claude/plugins/pokayokay')) {
    return { installed: true, scope: 'local', path: '.claude/plugins/pokayokay' };
  }

  return { installed: false, scope: null, path: null };
}

/**
 * Check if pokayokay is available to Codex through common local plugin paths
 * or the local marketplace file written by `installPlugin()`.
 * @returns {object} { installed: boolean, scope: 'global'|'local'|null }
 */
function detectCodexPluginInstalled() {
  const globalPaths = [
    join(homedir(), '.codex', 'plugins', 'installed', 'pokayokay'),
    join(homedir(), 'plugins', 'pokayokay', '.codex-plugin', 'plugin.json')
  ];

  for (const p of globalPaths) {
    if (existsSync(p)) {
      return { installed: true, scope: 'global', path: p };
    }
  }

  // Setup writes a marketplace entry to ~/.agents/plugins/marketplace.json.
  // Treat presence of the pokayokay entry as "installed" so doctor/setup
  // do not repeatedly report Codex as not installed after a successful run.
  const marketplacePath = join(homedir(), '.agents', 'plugins', 'marketplace.json');
  if (existsSync(marketplacePath)) {
    try {
      const data = JSON.parse(readFileSync(marketplacePath, 'utf-8'));
      const plugins = Array.isArray(data?.plugins) ? data.plugins : [];
      if (plugins.some((p) => p && p.name === 'pokayokay')) {
        return { installed: true, scope: 'global', path: marketplacePath };
      }
    } catch {
      // Invalid JSON — ignore and continue with the other detectors.
    }
  }

  if (existsSync('plugins/pokayokay/.codex-plugin/plugin.json')) {
    return { installed: true, scope: 'local', path: 'plugins/pokayokay' };
  }

  return { installed: false, scope: null, path: null };
}

/**
 * Check MCP configuration in both global and local configs
 * @param {string} serverName - MCP server name to check
 * @returns {object} { configured: boolean, scope: 'global'|'local'|null }
 */
function detectMcpConfig(serverName) {
  // Check global config
  const globalConfig = readClaudeConfig(getClaudeConfigPath());
  const globalConfigured = isMcpConfigured(globalConfig, serverName);

  if (globalConfigured) {
    return { configured: true, scope: 'global' };
  }

  // Check project-local .mcp.json
  if (existsSync('.mcp.json')) {
    try {
      const localConfig = JSON.parse(readFileSync('.mcp.json', 'utf-8'));
      const localConfigured = isMcpConfigured(localConfig, serverName);
      if (localConfigured) {
        return { configured: true, scope: 'local' };
      }
    } catch {
      // Invalid JSON, treat as not configured
    }
  }

  return { configured: false, scope: null };
}

/**
 * Check Codex MCP configuration.
 * @param {string} serverName - MCP server name to check
 * @returns {object} { configured: boolean, scope: 'global'|'local'|null }
 */
function detectCodexMcpConfig(serverName) {
  const globalConfig = readCodexConfig(getCodexConfigPath());
  if (isMcpConfigured(globalConfig, serverName)) {
    return { configured: true, scope: 'global' };
  }

  if (existsSync('.mcp.json')) {
    try {
      const localConfig = JSON.parse(readFileSync('.mcp.json', 'utf-8'));
      if (isMcpConfigured(localConfig, serverName)) {
        return { configured: true, scope: 'local' };
      }
    } catch {
      // Invalid JSON, treat as not configured
    }
  }

  return { configured: false, scope: null };
}

/**
 * Select default install targets based on detected runtimes.
 * @param {object} env - Runtime detection subset
 * @returns {string[]} Runtime ids
 */
export function selectDefaultInstallTargets(env) {
  return [
    env.claudeInstalled ? 'claude' : null,
    env.codexInstalled ? 'codex' : null,
  ].filter(Boolean);
}

/**
 * Check if kaizen CLI is installed and initialized
 * Checks PATH, GOPATH/bin, and ~/go/bin
 * @returns {Promise<object>} { cliInstalled: boolean, initialized: boolean, scope: 'global'|'local'|null }
 */
async function detectKaizen() {
  let cliInstalled = await commandExists('kaizen');

  // If not in PATH, check GOPATH/bin and ~/go/bin
  if (!cliInstalled) {
    const defaultGoPath = join(homedir(), 'go', 'bin', 'kaizen');
    if (existsSync(defaultGoPath)) {
      cliInstalled = true;
    }
  }

  // Check for initialization - local (.kaizen) or global (~/.config/kaizen)
  const localInit = existsSync('.kaizen');
  const globalInit = existsSync(join(homedir(), '.config', 'kaizen'));

  return {
    cliInstalled,
    initialized: localInit || globalInit,
    scope: localInit ? 'local' : globalInit ? 'global' : null
  };
}

/**
 * Detect full environment state
 * @returns {Promise<object>} Environment state object
 */
export async function detectEnvironment() {
  const configPath = getClaudeConfigPath();
  const config = readClaudeConfig(configPath);
  const codexConfigPath = getCodexConfigPath();
  const codexConfig = readCodexConfig(codexConfigPath);

  const claudeInstalled = await commandExists('claude');
  const claudeVersion = claudeInstalled ? await getClaudeVersion() : null;
  const codexInstalled = await commandExists('codex');
  const codexVersion = codexInstalled ? await getCodexVersion() : null;

  const pluginStatus = detectClaudePluginInstalled();
  const codexPluginStatus = detectCodexPluginInstalled();
  const mcpStatus = detectMcpConfig('ohno');
  const codexMcpStatus = detectCodexMcpConfig('ohno');
  const kaizenStatus = await detectKaizen();

  return {
    // Platform info
    platform: process.platform,
    platformName: getPlatformName(),
    nodeVersion: process.version,

    // Claude Code
    claudeInstalled,
    claudeVersion,
    claudeConfigPath: configPath,
    codexInstalled,
    codexVersion,
    codexConfigPath,

    // Claude plugin status
    pluginInstalled: pluginStatus.installed,
    pluginScope: pluginStatus.scope,
    pluginPath: pluginStatus.path,

    // Codex plugin status
    codexPluginInstalled: codexPluginStatus.installed,
    codexPluginScope: codexPluginStatus.scope,
    codexPluginPath: codexPluginStatus.path,

    // Claude MCP status
    mcpConfigured: mcpStatus.configured,
    mcpScope: mcpStatus.scope,

    // Codex MCP status
    codexMcpConfigured: codexMcpStatus.configured,
    codexMcpScope: codexMcpStatus.scope,

    // ohno init
    ohnoInitialized: existsSync('.ohno'),

    // kaizen status
    kaizenCliInstalled: kaizenStatus.cliInstalled,
    kaizenInitialized: kaizenStatus.initialized,
    kaizenScope: kaizenStatus.scope,

    // Raw config for later use
    config,
    codexConfig,
    defaultInstallTargets: selectDefaultInstallTargets({ claudeInstalled, codexInstalled })
  };
}
