import { existsSync, readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';
import { getClaudeConfigPath, getPlatformName } from './utils/platform.js';
import { readClaudeConfig, isMcpConfigured } from './utils/config.js';
import { commandExists, getClaudeVersion } from './utils/execute.js';

/**
 * Check if pokayokay plugin is installed by checking disk paths
 * @returns {object} { installed: boolean, scope: 'global'|'local'|null }
 */
function detectPluginInstalled() {
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

  const claudeInstalled = await commandExists('claude');
  const claudeVersion = claudeInstalled ? await getClaudeVersion() : null;

  const pluginStatus = detectPluginInstalled();
  const mcpStatus = detectMcpConfig('ohno');
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

    // Plugin status
    pluginInstalled: pluginStatus.installed,
    pluginScope: pluginStatus.scope,
    pluginPath: pluginStatus.path,

    // MCP status
    mcpConfigured: mcpStatus.configured,
    mcpScope: mcpStatus.scope,

    // ohno init
    ohnoInitialized: existsSync('.ohno'),

    // kaizen status
    kaizenCliInstalled: kaizenStatus.cliInstalled,
    kaizenInitialized: kaizenStatus.initialized,
    kaizenScope: kaizenStatus.scope,

    // Raw config for later use
    config
  };
}
