import { homedir } from 'node:os';
import { join } from 'node:path';
import { existsSync } from 'node:fs';
import prompts from 'prompts';
import chalk from 'chalk';
import { execute, commandExists } from '../utils/execute.js';

/**
 * Get the path to kaizen binary, checking GOPATH/bin and ~/go/bin
 * @returns {Promise<string|null>} Path to kaizen or null if not found
 */
async function getKaizenPath() {
  // Check if kaizen is in PATH
  if (await commandExists('kaizen')) {
    return 'kaizen';
  }

  // Check GOPATH/bin
  const goPathResult = await execute('go', ['env', 'GOPATH']);
  if (goPathResult.success && goPathResult.stdout.trim()) {
    const goPathBin = join(goPathResult.stdout.trim(), 'bin', 'kaizen');
    if (existsSync(goPathBin)) {
      return goPathBin;
    }
  }

  // Check ~/go/bin (default GOPATH)
  const defaultGoPath = join(homedir(), 'go', 'bin', 'kaizen');
  if (existsSync(defaultGoPath)) {
    return defaultGoPath;
  }

  return null;
}

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

  // Track the kaizen binary path
  let kaizenBin = env.kaizenCliInstalled ? 'kaizen' : null;

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

    // Find the installed binary path
    kaizenBin = await getKaizenPath();
    if (!kaizenBin) {
      console.log(chalk.yellow('  ⚠ kaizen installed but not found in PATH'));
      console.log('  Add ~/go/bin to your PATH, then run `kaizen init`');
      return false;
    }
  }

  // Initialize kaizen if not present
  if (!env.kaizenInitialized) {
    console.log('  Initializing kaizen...');
    const initResult = await execute(kaizenBin, ['init']);

    if (!initResult.success) {
      console.log(chalk.red(`  ✗ Failed to initialize kaizen: ${initResult.stderr}`));
      return false;
    }

    console.log(chalk.green('  ✓ kaizen initialized (.kaizen/ created)'));
  }

  return true;
}
