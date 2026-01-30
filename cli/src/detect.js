import { existsSync } from 'node:fs';
import { getClaudeConfigPath, getPlatformName } from './utils/platform.js';
import { readClaudeConfig, isMcpConfigured } from './utils/config.js';
import { commandExists, getClaudeVersion } from './utils/execute.js';

/**
 * Check if pokayokay plugin is installed
 * @param {object} config - Claude config object
 * @returns {boolean} True if plugin is installed
 */
function isPluginInstalled(config) {
  // Check in plugins array or installedPlugins
  const plugins = config.plugins || config.installedPlugins || [];
  return plugins.some(p =>
    typeof p === 'string'
      ? p.includes('pokayokay')
      : p.name?.includes('pokayokay')
  );
}

/**
 * Check if kaizen hooks are configured
 * @returns {boolean} True if kaizen hooks exist
 */
function isKaizenConfigured() {
  // Check for kaizen hook files or config
  return existsSync('.claude/hooks/post-review-fail.sh') ||
         existsSync('hooks/post-review-fail.sh');
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

  return {
    // Platform info
    platform: process.platform,
    platformName: getPlatformName(),
    nodeVersion: process.version,

    // Claude Code
    claudeInstalled,
    claudeVersion,
    claudeConfigPath: configPath,

    // Current state
    pluginInstalled: isPluginInstalled(config),
    mcpConfigured: isMcpConfigured(config, 'ohno'),
    ohnoInitialized: existsSync('.ohno'),
    kaizenConfigured: isKaizenConfigured(),

    // Raw config for later use
    config
  };
}
