import { homedir } from 'node:os';
import { join } from 'node:path';

/**
 * Get Claude Code config directory path based on platform
 * @returns {string} Path to Claude config directory
 */
export function getClaudeConfigDir() {
  // Claude Code stores user settings in ~/.claude on every platform,
  // including Windows (%USERPROFILE%\.claude). %APPDATA%\Claude is Claude
  // Desktop's directory, which Claude Code never reads.
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
 * Get Codex config directory path.
 * @returns {string} Path to Codex config directory
 */
export function getCodexConfigDir() {
  return join(homedir(), '.codex');
}

/**
 * Get Codex config.toml path.
 * @returns {string} Path to Codex config.toml
 */
export function getCodexConfigPath() {
  return join(getCodexConfigDir(), 'config.toml');
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
