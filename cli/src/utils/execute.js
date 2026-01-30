import { execFile } from 'node:child_process';
import { promisify } from 'node:util';
import which from 'which';

const execFileAsync = promisify(execFile);

/**
 * Check if a command exists in PATH
 * @param {string} command - Command name to check
 * @returns {Promise<boolean>} True if command exists
 */
export async function commandExists(command) {
  try {
    await which(command);
    return true;
  } catch {
    return false;
  }
}

/**
 * Execute a command safely using execFile (prevents shell injection)
 * @param {string} command - Command to execute
 * @param {string[]} args - Arguments array
 * @returns {Promise<{stdout: string, stderr: string}>} Command output
 */
export async function execute(command, args = []) {
  try {
    const { stdout, stderr } = await execFileAsync(command, args);
    return { stdout: stdout.toString(), stderr: stderr.toString(), success: true };
  } catch (err) {
    return {
      stdout: err.stdout?.toString() || '',
      stderr: err.stderr?.toString() || err.message,
      success: false,
      error: err
    };
  }
}

/**
 * Get Claude Code version
 * @returns {Promise<string|null>} Version string or null if not installed
 */
export async function getClaudeVersion() {
  const result = await execute('claude', ['--version']);
  if (result.success) {
    // Parse version from output like "claude v1.2.3"
    const match = result.stdout.match(/v?(\d+\.\d+\.\d+)/);
    return match ? match[1] : result.stdout.trim();
  }
  return null;
}
