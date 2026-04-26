import prompts from 'prompts';
import chalk from 'chalk';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join, resolve } from 'node:path';
import { execute } from '../utils/execute.js';

function ensureCodexMarketplaceEntry() {
  const agentsDir = join(homedir(), '.agents', 'plugins');
  const marketplacePath = join(agentsDir, 'marketplace.json');
  mkdirSync(agentsDir, { recursive: true });

  let marketplace = {
    name: 'pokayokay-local',
    interface: {
      displayName: 'Pokayokay Local'
    },
    plugins: []
  };

  if (existsSync(marketplacePath)) {
    try {
      marketplace = JSON.parse(readFileSync(marketplacePath, 'utf-8'));
      marketplace.plugins = marketplace.plugins || [];
      marketplace.interface = marketplace.interface || { displayName: 'Local Plugins' };
    } catch {
      // Replace invalid marketplace JSON with a valid local marketplace.
    }
  }

  // The marketplace file lives under the user home directory, so a relative
  // plugin path would be ambiguous. Resolve to an absolute path against the
  // current working directory (the project root the user ran setup from).
  const pluginPath = resolve(process.cwd(), 'plugins', 'pokayokay');

  const entry = {
    name: 'pokayokay',
    source: {
      source: 'local',
      path: pluginPath
    },
    policy: {
      installation: 'AVAILABLE',
      authentication: 'ON_INSTALL'
    },
    category: 'Coding'
  };

  const index = marketplace.plugins.findIndex((plugin) => plugin.name === 'pokayokay');
  if (index >= 0) {
    marketplace.plugins[index] = entry;
  } else {
    marketplace.plugins.push(entry);
  }

  writeFileSync(marketplacePath, JSON.stringify(marketplace, null, 2) + '\n');
  return marketplacePath;
}

/**
 * Step 1: Install pokayokay plugin
 * @param {object} env - Environment state
 * @returns {Promise<{success: boolean, scope: string|null}>}
 */
export async function installPlugin(env) {
  console.log(chalk.bold('\nStep 1/4: AI Runtime Plugin'));
  console.log('  The pokayokay plugin provides orchestration commands like /work, /plan, /audit.\n');

  const targets = env.installTargets || env.defaultInstallTargets || ['claude'];
  const needsClaude = targets.includes('claude');
  const needsCodex = targets.includes('codex');

  if ((!needsClaude || env.pluginInstalled) && (!needsCodex || env.codexPluginInstalled)) {
    const scopes = [];
    if (needsClaude) scopes.push(`Claude ${env.pluginScope}`);
    if (needsCodex) scopes.push(`Codex ${env.codexPluginScope}`);
    console.log(chalk.green(`  ✓ pokayokay plugin already installed (${scopes.join(', ')})`));
    return { success: true, scope: scopes.join(', ') };
  }

  const claudeWorkPending = needsClaude && !env.pluginInstalled;
  const codexWorkPending = needsCodex && !env.codexPluginInstalled;

  // The scope prompt only affects the Claude install flow (`--local` vs global).
  // Codex always writes a marketplace entry under ~/.agents/plugins/marketplace.json.
  let scope = 'global';
  if (claudeWorkPending) {
    const promptMessage = codexWorkPending
      ? 'Install pokayokay plugin (scope applies to Claude; Codex marketplace entry is global)?'
      : 'Install pokayokay plugin for Claude?';
    const response = await prompts({
      type: 'select',
      name: 'scope',
      message: promptMessage,
      choices: [
        { title: 'Global (recommended)', description: 'Available in all projects', value: 'global' },
        { title: 'Project-local', description: 'Only this project', value: 'local' },
        { title: 'Skip', value: 'skip' }
      ],
      initial: 0
    });
    scope = response.scope;
    if (scope === 'skip' || !scope) {
      console.log(chalk.yellow('  ○ Skipped plugin installation'));
      return { success: false, scope: null };
    }
  } else if (codexWorkPending) {
    // Codex-only flow: confirm intent, no scope question.
    const { proceed } = await prompts({
      type: 'confirm',
      name: 'proceed',
      message: 'Write pokayokay marketplace entry for Codex (~/.agents/plugins/marketplace.json)?',
      initial: true
    });
    if (!proceed) {
      console.log(chalk.yellow('  ○ Skipped Codex marketplace entry'));
      return { success: false, scope: null };
    }
  }

  const installedScopes = [];

  if (claudeWorkPending) {
    // Add marketplace (ignore errors if already added)
    console.log('  Adding Claude marketplace...');
    const addResult = await execute('claude', ['plugin', 'marketplace', 'add', 'srstomp/pokayokay']);
    if (addResult.success) {
      console.log(chalk.green('  ✓ Claude marketplace added'));
    } else if (addResult.stderr.includes('already')) {
      console.log(chalk.dim('  Claude marketplace already added'));
    } else {
      console.log(chalk.red(`  ✗ Failed to add Claude marketplace: ${addResult.stderr}`));
      return { success: false, scope: null };
    }

    // Install plugin with scope
    console.log(`  Installing Claude plugin (${scope})...`);
    const installArgs = scope === 'local'
      ? ['plugin', 'install', '--local', 'pokayokay@srstomp-pokayokay']
      : ['plugin', 'install', 'pokayokay@srstomp-pokayokay'];

    const installResult = await execute('claude', installArgs);
    if (!installResult.success) {
      console.log(chalk.red(`  ✗ Failed to install Claude plugin: ${installResult.stderr}`));
      return { success: false, scope: null };
    }

    console.log(chalk.green(`  ✓ Claude plugin installed (${scope})`));
    installedScopes.push(`Claude ${scope}`);
  }

  if (codexWorkPending) {
    const marketplacePath = ensureCodexMarketplaceEntry();
    // Be explicit: we only wrote a marketplace entry. Codex still needs to
    // load/activate it (the user does this with `codex plugin install`).
    console.log(chalk.green(`  ✓ Codex marketplace entry written to ${marketplacePath}`));
    console.log(chalk.dim('    Run `codex plugin install pokayokay` to activate it in Codex.'));
    installedScopes.push('Codex marketplace entry');
  }

  const resultScope = installedScopes.join(', ') || scope;
  return { success: true, scope: resultScope };
}
