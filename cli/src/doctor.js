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
  let allGood = true;
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
    console.log(chalk.green('  ✓ pokayokay plugin active'));
  } else {
    console.log(chalk.red('  ✗ pokayokay plugin not installed'));
    console.log(chalk.dim('    Run: claude plugin install pokayokay@srstomp-pokayokay'));
    requiredGood = false;
  }

  // MCP
  if (env.mcpConfigured) {
    console.log(chalk.green('  ✓ ohno MCP server configured'));
  } else {
    console.log(chalk.red('  ✗ ohno MCP server not configured'));
    console.log(chalk.dim('    Run: npx pokayokay (to configure)'));
    requiredGood = false;
  }

  // ohno init
  if (env.ohnoInitialized) {
    console.log(chalk.green('  ✓ ohno project initialized (.ohno/ exists)'));
  } else {
    console.log(chalk.yellow('  ○ ohno not initialized in this project'));
    console.log(chalk.dim('    Run: npx @stevestomp/ohno-cli init'));
    allGood = false;
  }

  // kaizen (optional)
  if (env.kaizenConfigured) {
    console.log(chalk.green('  ✓ kaizen integration configured'));
  } else {
    console.log(chalk.dim('  ○ kaizen integration not configured (optional)'));
  }

  // Summary
  console.log();
  if (requiredGood) {
    if (allGood) {
      console.log(chalk.green.bold('  All components working!\n'));
    } else {
      console.log(chalk.yellow.bold('  Required components working. Optional items pending.\n'));
    }
    process.exit(0);
  } else {
    console.log(chalk.red.bold('  Some required components missing. Run npx pokayokay to fix.\n'));
    process.exit(1);
  }
}
