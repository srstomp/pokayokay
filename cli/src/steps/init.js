import prompts from 'prompts';
import chalk from 'chalk';
import { execute } from '../utils/execute.js';

/**
 * Step 3: Initialize ohno in current project
 * @param {object} env - Environment state
 * @returns {Promise<boolean>} True if successful or skipped
 */
export async function initOhno(env) {
  console.log(chalk.bold('\nStep 3/4: Initialize Project'));
  console.log(`  Create .ohno/ directory in current project for task tracking.\n`);

  if (env.ohnoInitialized) {
    console.log(chalk.green('  ✓ ohno already initialized (.ohno/ exists)'));
    return true;
  }

  const cwd = process.cwd();
  const { confirm } = await prompts({
    type: 'confirm',
    name: 'confirm',
    message: `Initialize ohno in ${cwd}?`,
    initial: true
  });

  if (!confirm) {
    console.log(chalk.yellow('  ○ Skipped ohno initialization'));
    return false;
  }

  console.log('  Initializing ohno...');
  const result = await execute('npx', ['@stevestomp/ohno-cli', 'init']);

  if (!result.success) {
    console.log(chalk.red(`  ✗ Failed: ${result.stderr}`));
    return false;
  }

  console.log(chalk.green('  ✓ ohno initialized'));
  return true;
}
