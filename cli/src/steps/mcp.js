import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import prompts from 'prompts';
import chalk from 'chalk';
import {
  readClaudeConfig,
  writeClaudeConfig,
  writeCodexMcpServer,
} from '../utils/config.js';

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

  const targets = env.installTargets || env.defaultInstallTargets || ['claude'];
  const needsClaude = targets.includes('claude');
  const needsCodex = targets.includes('codex');

  if ((!needsClaude || env.mcpConfigured) && (!needsCodex || env.codexMcpConfigured)) {
    const scopes = [];
    if (needsClaude) scopes.push(`Claude ${env.mcpScope}`);
    if (needsCodex) scopes.push(`Codex ${env.codexMcpScope}`);
    console.log(chalk.green(`  ✓ ohno MCP server already configured (${scopes.join(', ')})`));
    return { success: true, scope: scopes.join(', '), needsRestart: false };
  }

  const localDescription = needsCodex
    ? 'Only this project, stored in .mcp.json (Codex MCP config is global-only: ~/.codex/config.toml)'
    : 'Only this project, stored in .mcp.json';
  const { scope } = await prompts({
    type: 'select',
    name: 'scope',
    message: 'Configure ohno MCP server?',
    choices: [
      { title: 'Global (recommended)', description: 'Available in all projects', value: 'global' },
      { title: 'Project-local', description: localDescription, value: 'local' },
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
    const configuredScopes = [];

    if (needsClaude && !env.mcpConfigured && scope === 'global') {
      // Add to global Claude config
      const config = readClaudeConfig(env.claudeConfigPath);
      config.mcpServers = config.mcpServers || {};
      config.mcpServers.ohno = mcpEntry;

      const backupPath = writeClaudeConfig(env.claudeConfigPath, config);
      if (backupPath) {
        console.log(chalk.dim(`  Backed up config to ${backupPath}`));
      }
      configuredScopes.push('Claude global');
    } else if (needsClaude && !env.mcpConfigured) {
      // Add to project-local .mcp.json
      const config = readLocalMcpConfig();
      config.mcpServers = config.mcpServers || {};
      config.mcpServers.ohno = mcpEntry;
      writeLocalMcpConfig(config);
      configuredScopes.push('Claude local');
    }

    if (needsCodex && !env.codexMcpConfigured) {
      // Codex only loads MCP servers from ~/.codex/config.toml; a
      // project-local .mcp.json is a Claude Code convention Codex never
      // reads. Always write the Codex entry globally, regardless of scope.
      if (scope === 'local') {
        console.log(chalk.dim(`  Codex MCP config is global-only; writing to ${env.codexConfigPath}`));
      }
      const backupPath = writeCodexMcpServer(env.codexConfigPath, 'ohno', mcpEntry);
      if (backupPath) {
        console.log(chalk.dim(`  Backed up Codex config to ${backupPath}`));
      }
      configuredScopes.push('Codex global');
    }

    const resultScope = configuredScopes.join(', ') || scope;
    console.log(chalk.green(`  ✓ MCP server configured (${resultScope})`));
    console.log(chalk.yellow('  ⚠ Restart configured AI runtimes to activate MCP server'));
    return { success: true, scope: resultScope, needsRestart: true };
  } catch (err) {
    console.log(chalk.red(`  ✗ Failed: ${err.message}`));
    return { success: false, scope: null, needsRestart: false };
  }
}
