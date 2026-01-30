import prompts from 'prompts';
import chalk from 'chalk';
import { execute } from '../utils/execute.js';

/**
 * Step 1: Install pokayokay plugin
 * @param {object} env - Environment state
 * @returns {Promise<boolean>} True if successful or skipped
 */
export async function installPlugin(env) {
  console.log(chalk.bold('\nStep 1/4: Claude Code Plugin'));
  console.log('  The pokayokay plugin provides orchestration commands like /work, /plan, /audit.\n');

  if (env.pluginInstalled) {
    console.log(chalk.green('  ✓ pokayokay plugin already installed'));
    return true;
  }

  const { confirm } = await prompts({
    type: 'confirm',
    name: 'confirm',
    message: 'Install pokayokay plugin?',
    initial: true
  });

  if (!confirm) {
    console.log(chalk.yellow('  ○ Skipped plugin installation'));
    return false;
  }

  // Add marketplace (ignore "already installed" error)
  console.log('  Adding marketplace...');
  const addResult = await execute('claude', ['plugin', 'marketplace', 'add', 'srstomp/pokayokay']);
  if (!addResult.success) {
    const isAlreadyInstalled = addResult.stderr.includes('already installed');
    if (isAlreadyInstalled) {
      console.log(chalk.dim('  Marketplace already added'));
    } else {
      console.log(chalk.red(`  ✗ Failed to add marketplace: ${addResult.stderr}`));
      return false;
    }
  } else {
    console.log(chalk.green('  ✓ Marketplace added'));
  }

  // Install plugin
  console.log('  Installing plugin...');
  const installResult = await execute('claude', ['plugin', 'install', 'pokayokay@srstomp-pokayokay']);
  if (!installResult.success) {
    console.log(chalk.red(`  ✗ Failed to install plugin: ${installResult.stderr}`));
    return false;
  }

  console.log(chalk.green('  ✓ Plugin installed'));
  return true;
}
