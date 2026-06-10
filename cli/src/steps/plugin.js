import prompts from 'prompts';
import chalk from 'chalk';
import { existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execute } from '../utils/execute.js';
import { getCodexConfigPath } from '../utils/platform.js';
import { writeCodexHookBridgeConfig } from '../utils/config.js';

/**
 * Find the on-disk pokayokay repository root. Codex's current plugin flow adds
 * a marketplace, not an individual plugin, so it needs the repository root that
 * contains `.claude-plugin/marketplace.json`.
 *
 * @returns {string|null} Absolute path to the repository root, or null.
 */
function locateMarketplaceRoot() {
  const cwdCandidate = resolve(process.cwd());
  if (
    existsSync(join(cwdCandidate, '.claude-plugin', 'marketplace.json')) &&
    existsSync(join(cwdCandidate, 'plugins', 'pokayokay', '.codex-plugin', 'plugin.json'))
  ) {
    return cwdCandidate;
  }

  // cli/src/steps/plugin.js → cli/src/steps → cli/src → cli → repo root
  const moduleDir = dirname(fileURLToPath(import.meta.url));
  const repoCandidate = resolve(moduleDir, '..', '..', '..');
  if (
    existsSync(join(repoCandidate, '.claude-plugin', 'marketplace.json')) &&
    existsSync(join(repoCandidate, 'plugins', 'pokayokay', '.codex-plugin', 'plugin.json'))
  ) {
    return repoCandidate;
  }

  return null;
}

/**
 * Find the on-disk pokayokay plugin source for hook wiring.
 *
 * @returns {string|null} Absolute path to the plugin directory, or null.
 */
function locatePluginSource() {
  const repoRoot = locateMarketplaceRoot();
  if (repoRoot) {
    return join(repoRoot, 'plugins', 'pokayokay');
  }

  const cwdCandidate = resolve(process.cwd(), 'plugins', 'pokayokay');
  if (existsSync(join(cwdCandidate, '.codex-plugin', 'plugin.json'))) {
    return cwdCandidate;
  }

  const moduleDir = dirname(fileURLToPath(import.meta.url));
  const repoCandidate = resolve(moduleDir, '..', '..', '..', 'plugins', 'pokayokay');
  if (existsSync(join(repoCandidate, '.codex-plugin', 'plugin.json'))) {
    return repoCandidate;
  }

  return null;
}

async function ensureCodexMarketplaceEntry() {
  const marketplaceRoot = locateMarketplaceRoot();
  if (!marketplaceRoot) {
    const cwd = process.cwd();
    throw new Error(
      `Could not find the pokayokay marketplace root. Looked in:\n` +
      `  - ${cwd} (cwd)\n` +
      `  - sibling of the CLI install (repo layout)\n` +
      `Run Codex setup from a checkout of the pokayokay repo, e.g.:\n` +
      `  git clone https://github.com/srstomp/pokayokay && cd pokayokay && codex plugin marketplace add .`
    );
  }

  const addResult = await execute('codex', ['plugin', 'marketplace', 'add', marketplaceRoot]);
  if (!addResult.success) {
    throw new Error(addResult.stderr || addResult.stdout || 'codex plugin marketplace add failed');
  }

  return marketplaceRoot;
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

  if ((!needsClaude || env.pluginInstalled) && !needsCodex) {
    const scopes = [];
    if (needsClaude) scopes.push(`Claude ${env.pluginScope}`);
    if (needsCodex) scopes.push(`Codex ${env.codexPluginScope}`);
    console.log(chalk.green(`  ✓ pokayokay plugin already installed (${scopes.join(', ')})`));
    return { success: true, scope: scopes.join(', ') };
  }

  const claudeWorkPending = needsClaude && !env.pluginInstalled;
  // Codex marketplace registration and hook wiring are idempotent, and hook
  // wiring may need refreshing even when the marketplace already exists.
  const codexWorkPending = needsCodex;

  // The scope prompt only affects the Claude install flow (`--local` vs global).
  // Codex registers a marketplace in ~/.codex/config.toml.
  let scope = 'global';
  if (claudeWorkPending) {
    const promptMessage = codexWorkPending
      ? 'Install pokayokay plugin (scope applies to Claude; Codex marketplace is global)?'
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
  } else if (codexWorkPending && !env.codexPluginInstalled) {
    // Codex-only flow: confirm intent, no scope question.
    const { proceed } = await prompts({
      type: 'confirm',
      name: 'proceed',
      message: 'Add pokayokay marketplace and hook bridge for Codex?',
      initial: true
    });
    if (!proceed) {
      console.log(chalk.yellow('  ○ Skipped Codex setup'));
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
      ? ['plugin', 'install', '--local', 'pokayokay@pokayokay']
      : ['plugin', 'install', 'pokayokay@pokayokay'];

    const installResult = await execute('claude', installArgs);
    if (!installResult.success) {
      console.log(chalk.red(`  ✗ Failed to install Claude plugin: ${installResult.stderr}`));
      return { success: false, scope: null };
    }

    console.log(chalk.green(`  ✓ Claude plugin installed (${scope})`));
    installedScopes.push(`Claude ${scope}`);
  }

  if (codexWorkPending) {
    try {
      const marketplaceRoot = await ensureCodexMarketplaceEntry();
      const pluginPath = locatePluginSource();
      if (!pluginPath) {
        throw new Error('Could not find the pokayokay plugin source for Codex hook wiring');
      }
      const configPath = getCodexConfigPath();
      writeCodexHookBridgeConfig(configPath, pluginPath);
      console.log(chalk.green(`  ✓ Codex marketplace added from ${marketplaceRoot}`));
      console.log(chalk.green(`  ✓ Codex hook bridge wired in ${configPath}`));
      installedScopes.push('Codex marketplace', 'Codex hook bridge');
    } catch (err) {
      console.log(chalk.red(`  ✗ Failed to complete Codex setup:\n    ${err.message.replace(/\n/g, '\n    ')}`));
      // If Claude was already installed in this run, keep that progress; only
      // fail the whole step when nothing else succeeded.
      if (installedScopes.length === 0) {
        return { success: false, scope: null };
      }
    }
  }

  const resultScope = installedScopes.join(', ') || scope;
  return { success: true, scope: resultScope };
}
