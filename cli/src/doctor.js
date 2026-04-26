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

  // Supported runtimes
  if (env.claudeInstalled) {
    console.log(chalk.green(`  ✓ Claude Code installed (v${env.claudeVersion || 'unknown'})`));
  } else {
    console.log(chalk.dim('  ○ Claude Code not installed'));
    console.log(chalk.dim('    Install from: https://claude.ai/code'));
  }

  if (env.codexInstalled) {
    console.log(chalk.green(`  ✓ Codex installed (v${env.codexVersion || 'unknown'})`));
  } else {
    console.log(chalk.dim('  ○ Codex not installed'));
  }

  if (!env.claudeInstalled && !env.codexInstalled) {
    requiredGood = false;
  }

  // Plugin
  if (env.pluginInstalled || env.codexPluginInstalled) {
    const scopes = [];
    if (env.pluginInstalled) scopes.push(`Claude ${env.pluginScope}`);
    if (env.codexPluginInstalled) scopes.push(`Codex ${env.codexPluginScope}`);
    console.log(chalk.green(`  ✓ pokayokay plugin active (${scopes.join(', ')})`));
  } else {
    console.log(chalk.red('  ✗ pokayokay plugin not installed'));
    console.log(chalk.dim('    Run: npx pokayokay'));
    requiredGood = false;
  }

  // MCP
  if (env.mcpConfigured || env.codexMcpConfigured) {
    const scopes = [];
    if (env.mcpConfigured) scopes.push(`Claude ${env.mcpScope}`);
    if (env.codexMcpConfigured) scopes.push(`Codex ${env.codexMcpScope}`);
    console.log(chalk.green(`  ✓ ohno MCP server configured (${scopes.join(', ')})`));
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
    console.log(chalk.green(`  ✓ kaizen configured (${env.kaizenScope})`));
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
