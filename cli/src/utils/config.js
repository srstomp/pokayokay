import { readFileSync, writeFileSync, copyFileSync, existsSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';

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

/**
 * Check if MCP server is configured
 * @param {object} config - Claude config object
 * @param {string} serverName - MCP server name to check
 * @returns {boolean} True if server is configured
 */
export function isMcpConfigured(config, serverName) {
  return !!(config.mcpServers && config.mcpServers[serverName]);
}
