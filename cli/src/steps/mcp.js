import prompts from 'prompts';
import chalk from 'chalk';
import { readClaudeConfig, writeClaudeConfig } from '../utils/config.js';

/**
 * Step 2: Configure ohno MCP server
 * @param {object} env - Environment state
 * @returns {Promise<boolean>} True if successful or skipped
 */
export async function configureMcp(env) {
  console.log(chalk.bold('\nStep 2/4: ohno Task Management'));
  console.log('  ohno tracks tasks, dependencies, and progress via MCP.');
  console.log('  Required for /work and /plan commands.\n');

  if (env.mcpConfigured) {
    console.log(chalk.green('  ✓ ohno MCP server already configured'));
    return true;
  }

  const { confirm } = await prompts({
    type: 'confirm',
    name: 'confirm',
    message: 'Configure ohno MCP server?',
    initial: true
  });

  if (!confirm) {
    console.log(chalk.yellow('  ○ Skipped MCP configuration'));
    return false;
  }

  try {
    // Read current config
    const config = readClaudeConfig(env.claudeConfigPath);

    // Add ohno MCP server
    config.mcpServers = config.mcpServers || {};
    config.mcpServers.ohno = {
      command: 'npx',
      args: ['@stevestomp/ohno-mcp']
    };

    // Write with backup
    const backupPath = writeClaudeConfig(env.claudeConfigPath, config);

    if (backupPath) {
      console.log(chalk.dim(`  Backed up existing config to ${backupPath}`));
    }

    console.log(chalk.green('  ✓ MCP server configured'));
    console.log(chalk.yellow('  ⚠ Restart Claude Code to activate'));
    return true;
  } catch (err) {
    console.log(chalk.red(`  ✗ Failed: ${err.message}`));
    return false;
  }
}
