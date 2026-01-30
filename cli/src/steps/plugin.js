import prompts from 'prompts';
import chalk from 'chalk';
import { execute } from '../utils/execute.js';

/**
 * Step 1: Install pokayokay plugin
 * @param {object} env - Environment state
 * @returns {Promise<{success: boolean, scope: string|null}>}
 */
export async function installPlugin(env) {
  console.log(chalk.bold('\nStep 1/4: Claude Code Plugin'));
  console.log('  The pokayokay plugin provides orchestration commands like /work, /plan, /audit.\n');

  if (env.pluginInstalled) {
    console.log(chalk.green(`  ✓ pokayokay plugin already installed (${env.pluginScope})`));
    return { success: true, scope: env.pluginScope };
  }

  const { scope } = await prompts({
    type: 'select',
    name: 'scope',
    message: 'Install pokayokay plugin?',
    choices: [
      { title: 'Global (recommended)', description: 'Available in all projects', value: 'global' },
      { title: 'Project-local', description: 'Only this project', value: 'local' },
      { title: 'Skip', value: 'skip' }
    ],
    initial: 0
  });

  if (scope === 'skip' || !scope) {
    console.log(chalk.yellow('  ○ Skipped plugin installation'));
    return { success: false, scope: null };
  }

  // Add marketplace (ignore errors if already added)
  console.log('  Adding marketplace...');
  const addResult = await execute('claude', ['plugin', 'marketplace', 'add', 'srstomp/pokayokay']);
  if (addResult.success) {
    console.log(chalk.green('  ✓ Marketplace added'));
  } else if (addResult.stderr.includes('already')) {
    console.log(chalk.dim('  Marketplace already added'));
  } else {
    console.log(chalk.red(`  ✗ Failed to add marketplace: ${addResult.stderr}`));
    return { success: false, scope: null };
  }

  // Install plugin with scope
  console.log(`  Installing plugin (${scope})...`);
  const installArgs = scope === 'local'
    ? ['plugin', 'install', '--local', 'pokayokay@srstomp-pokayokay']
    : ['plugin', 'install', 'pokayokay@srstomp-pokayokay'];

  const installResult = await execute('claude', installArgs);
  if (!installResult.success) {
    console.log(chalk.red(`  ✗ Failed to install plugin: ${installResult.stderr}`));
    return { success: false, scope: null };
  }

  console.log(chalk.green(`  ✓ Plugin installed (${scope})`));
  return { success: true, scope };
}
