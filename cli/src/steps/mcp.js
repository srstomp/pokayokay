import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import prompts from 'prompts';
import chalk from 'chalk';
import { readClaudeConfig, writeClaudeConfig } from '../utils/config.js';

/**
 * Read .mcp.json or return empty object
 * @returns {object}
 */
function readLocalMcpConfig() {
  if (!existsSync('.mcp.json')) {
    return {};
  }
  try {
    return JSON.parse(readFileSync('.mcp.json', 'utf-8'));
  } catch {
    return {};
  }
}

/**
 * Write .mcp.json
 * @param {object} config
 */
function writeLocalMcpConfig(config) {
  writeFileSync('.mcp.json', JSON.stringify(config, null, 2) + '\n');
}

/**
 * Step 2: Configure ohno MCP server
 * @param {object} env - Environment state
 * @returns {Promise<{success: boolean, scope: string|null, needsRestart: boolean}>}
 */
export async function configureMcp(env) {
  console.log(chalk.bold('\nStep 2/4: ohno Task Management'));
  console.log('  ohno tracks tasks, dependencies, and progress via MCP.');
  console.log('  Required for /work and /plan commands.\n');

  if (env.mcpConfigured) {
    console.log(chalk.green(`  ✓ ohno MCP server already configured (${env.mcpScope})`));
    return { success: true, scope: env.mcpScope, needsRestart: false };
  }

  const { scope } = await prompts({
    type: 'select',
    name: 'scope',
    message: 'Configure ohno MCP server?',
    choices: [
      { title: 'Global (recommended)', description: 'Available in all projects', value: 'global' },
      { title: 'Project-local', description: 'Only this project, stored in .mcp.json', value: 'local' },
      { title: 'Skip', value: 'skip' }
    ],
    initial: 0
  });

  if (scope === 'skip' || !scope) {
    console.log(chalk.yellow('  ○ Skipped MCP configuration'));
    return { success: false, scope: null, needsRestart: false };
  }

  const mcpEntry = {
    command: 'npx',
    args: ['@stevestomp/ohno-mcp']
  };

  try {
    if (scope === 'global') {
      // Add to global Claude config
      const config = readClaudeConfig(env.claudeConfigPath);
      config.mcpServers = config.mcpServers || {};
      config.mcpServers.ohno = mcpEntry;

      const backupPath = writeClaudeConfig(env.claudeConfigPath, config);
      if (backupPath) {
        console.log(chalk.dim(`  Backed up config to ${backupPath}`));
      }
    } else {
      // Add to project-local .mcp.json
      const config = readLocalMcpConfig();
      config.mcpServers = config.mcpServers || {};
      config.mcpServers.ohno = mcpEntry;
      writeLocalMcpConfig(config);
    }

    console.log(chalk.green(`  ✓ MCP server configured (${scope})`));
    console.log(chalk.yellow('  ⚠ Restart Claude Code to activate'));
    return { success: true, scope, needsRestart: true };
  } catch (err) {
    console.log(chalk.red(`  ✗ Failed: ${err.message}`));
    return { success: false, scope: null, needsRestart: false };
  }
}
