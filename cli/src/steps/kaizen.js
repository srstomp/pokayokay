import prompts from 'prompts';
import chalk from 'chalk';
import { execute, commandExists } from '../utils/execute.js';

/**
 * Step 4: Configure kaizen integration (optional)
 * @param {object} env - Environment state
 * @returns {Promise<boolean>} True if successful or skipped
 */
export async function configureKaizen(env) {
  console.log(chalk.bold('\nStep 4/4: kaizen Integration (Optional)'));
  console.log('  kaizen captures failure patterns and auto-creates fix tasks.');
  console.log('  Improves over time as it learns from your review failures.\n');

  // Already fully configured
  if (env.kaizenCliInstalled && env.kaizenInitialized) {
    console.log(chalk.green('  ✓ kaizen already configured'));
    return true;
  }

  const { confirm } = await prompts({
    type: 'confirm',
    name: 'confirm',
    message: 'Enable kaizen integration?',
    initial: false
  });

  if (!confirm) {
    console.log(chalk.yellow('  ○ Skipped kaizen integration'));
    return false;
  }

  // Install kaizen if not present
  if (!env.kaizenCliInstalled) {
    const goInstalled = await commandExists('go');

    if (!goInstalled) {
      console.log(chalk.yellow('\n  ⚠ Go is required to install kaizen'));
      console.log('  Install Go from: https://go.dev/dl/');
      console.log('  Then run `npx pokayokay` again to complete setup.\n');
      return false;
    }

    console.log('  Installing kaizen via Go...');
    const installResult = await execute('go', ['install', 'github.com/srstomp/kaizen/cmd/kaizen@latest']);

    if (!installResult.success) {
      console.log(chalk.red(`  ✗ Failed to install kaizen: ${installResult.stderr}`));
      return false;
    }

    console.log(chalk.green('  ✓ kaizen installed'));
  }

  // Initialize kaizen if not present
  if (!env.kaizenInitialized) {
    console.log('  Initializing kaizen...');
    const initResult = await execute('kaizen', ['init']);

    if (!initResult.success) {
      console.log(chalk.red(`  ✗ Failed to initialize kaizen: ${initResult.stderr}`));
      return false;
    }

    console.log(chalk.green('  ✓ kaizen initialized (.kaizen/ created)'));
  }

  return true;
}
