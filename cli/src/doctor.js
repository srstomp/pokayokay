import chalk from 'chalk';
import { detectEnvironment } from './detect.js';

/**
 * Print doctor header
 */
function printHeader() {
  console.log(chalk.bold.cyan('\n  pokayokay doctor\n'));
  console.log('  Checking installation...\n');
}

/**
 * Doctor command - validate installation
 */
export async function doctor() {
  printHeader();

  const env = await detectEnvironment();
  let requiredGood = true;

  // Claude Code
  if (env.claudeInstalled) {
    console.log(chalk.green(`  ✓ Claude Code installed (v${env.claudeVersion || 'unknown'})`));
  } else {
    console.log(chalk.red('  ✗ Claude Code not installed'));
    console.log(chalk.dim('    Install from: https://claude.ai/code'));
    requiredGood = false;
  }

  // Plugin
  if (env.pluginInstalled) {
    console.log(chalk.green(`  ✓ pokayokay plugin active (${env.pluginScope})`));
  } else {
    console.log(chalk.red('  ✗ pokayokay plugin not installed'));
    console.log(chalk.dim('    Run: npx pokayokay'));
    requiredGood = false;
  }

  // MCP
  if (env.mcpConfigured) {
    console.log(chalk.green(`  ✓ ohno MCP server configured (${env.mcpScope})`));
  } else {
    console.log(chalk.red('  ✗ ohno MCP server not configured'));
    console.log(chalk.dim('    Run: npx pokayokay'));
    requiredGood = false;
  }

  // ohno init
  if (env.ohnoInitialized) {
    console.log(chalk.green('  ✓ ohno project initialized (.ohno/ exists)'));
  } else {
    console.log(chalk.yellow('  ○ ohno not initialized in this project'));
    console.log(chalk.dim('    Run: npx @stevestomp/ohno-cli init'));
  }

  // kaizen (optional)
  if (env.kaizenCliInstalled && env.kaizenInitialized) {
    console.log(chalk.green('  ✓ kaizen configured'));
  } else if (env.kaizenCliInstalled) {
    console.log(chalk.yellow('  ○ kaizen CLI installed but not initialized'));
    console.log(chalk.dim('    Run: kaizen init'));
  } else {
    console.log(chalk.dim('  ○ kaizen not installed (optional)'));
  }

  // Summary
  console.log();
  if (requiredGood) {
    console.log(chalk.green.bold('  All required components working!\n'));
    process.exit(0);
  } else {
    console.log(chalk.red.bold('  Some required components missing. Run npx pokayokay to fix.\n'));
    process.exit(1);
  }
}
