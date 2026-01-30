import { homedir } from 'node:os';
import { join } from 'node:path';

/**
 * Get Claude Code config directory path based on platform
 * @returns {string} Path to Claude config directory
 */
export function getClaudeConfigDir() {
  const platform = process.platform;

  if (platform === 'win32') {
    // Windows: %APPDATA%\Claude
    return join(process.env.APPDATA || join(homedir(), 'AppData', 'Roaming'), 'Claude');
  }

  // macOS and Linux: ~/.claude
  return join(homedir(), '.claude');
}

/**
 * Get Claude Code settings.json path
 * @returns {string} Path to settings.json
 */
export function getClaudeConfigPath() {
  return join(getClaudeConfigDir(), 'settings.json');
}

/**
 * Get platform display name
 * @returns {string} Human-readable platform name
 */
export function getPlatformName() {
  const names = {
    darwin: 'macOS',
    linux: 'Linux',
    win32: 'Windows'
  };
  return names[process.platform] || process.platform;
}
