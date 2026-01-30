import chalk from 'chalk';
import { detectEnvironment } from './detect.js';
import { installPlugin } from './steps/plugin.js';
import { configureMcp } from './steps/mcp.js';
import { initOhno } from './steps/init.js';
import { configureKaizen } from './steps/kaizen.js';

/**
 * Print wizard header
 */
function printHeader() {
  console.log(chalk.bold.cyan('\n  pokayokay setup wizard\n'));
}

/**
 * Print environment detection results
 * @param {object} env - Environment state
 */
function printEnvironment(env) {
  console.log('  Detecting environment...\n');
  console.log(chalk.green(`  ✓ Platform: ${env.platformName}`));

  if (env.claudeInstalled) {
    console.log(chalk.green(`  ✓ Claude Code: v${env.claudeVersion || 'installed'}`));
  } else {
    console.log(chalk.red('  ✗ Claude Code: not found'));
  }

  console.log(chalk.green(`  ✓ Node.js: ${env.nodeVersion}`));
}

/**
 * Print completion summary
 * @param {object} results - Step results with scopes
 * @param {boolean} needsRestart - Whether Claude Code needs restart
 */
function printSummary(results, needsRestart) {
  console.log(chalk.bold.green('\n  ✓ Setup complete!\n'));

  const installed = [];
  const skipped = [];

  if (results.plugin.success) {
    installed.push(`pokayokay plugin (${results.plugin.scope})`);
  } else {
    skipped.push('pokayokay plugin');
  }

  if (results.mcp.success) {
    installed.push(`ohno MCP server (${results.mcp.scope})`);
  } else {
    skipped.push('ohno MCP server');
  }

  if (results.init) {
    installed.push('ohno project initialized');
  } else {
    skipped.push('ohno project init');
  }

  if (results.kaizen) {
    installed.push('kaizen');
  } else {
    skipped.push('kaizen integration');
  }

  if (installed.length > 0) {
    console.log('  Installed:');
    installed.forEach(item => console.log(chalk.green(`    • ${item}`)));
  }

  if (skipped.length > 0) {
    console.log('\n  Skipped:');
    skipped.forEach(item => console.log(chalk.dim(`    • ${item}`)));
  }

  // Useful commands section
  console.log(chalk.cyan('\n  Useful commands:'));
  console.log(chalk.dim('    npx @srstomp/ohno-cli status   View project status'));
  console.log(chalk.dim('    npx @srstomp/ohno-cli serve    Start MCP server manually'));
  if (results.kaizen) {
    console.log(chalk.dim('    kaizen suggest                 Get fix suggestions'));
  }

  if (needsRestart) {
    console.log(chalk.yellow('\n  ⚠ Action required:'));
    console.log('    Restart Claude Code to activate MCP server');
  }

  console.log(chalk.bold('\n  Next steps:'));
  if (needsRestart) {
    console.log("    1. Restart Claude Code");
    console.log("    2. Run '/pokayokay:plan docs/prd.md' to plan from a PRD");
    console.log("    3. Run '/pokayokay:work' to start a work session");
  } else {
    console.log("    1. Run '/pokayokay:plan docs/prd.md' to plan from a PRD");
    console.log("    2. Run '/pokayokay:work' to start a work session");
  }

  console.log(chalk.dim("\n  Run 'npx pokayokay doctor' to verify installation anytime.\n"));
}

/**
 * Main wizard entry point
 */
export async function main() {
  printHeader();

  // Detect environment
  const env = await detectEnvironment();
  printEnvironment(env);

  // Check prerequisites
  if (!env.claudeInstalled) {
    console.log(chalk.red('\n  Claude Code is required but not installed.'));
    console.log('  Install from: https://claude.ai/code\n');
    process.exit(1);
  }

  // Run steps and track results with scopes
  const pluginResult = await installPlugin(env);
  const mcpResult = await configureMcp(env);
  const initResult = await initOhno(env);
  const kaizenResult = await configureKaizen(env);

  const results = {
    plugin: pluginResult,
    mcp: mcpResult,
    init: initResult,
    kaizen: kaizenResult
  };

  // Determine if restart needed
  const needsRestart = mcpResult.needsRestart;

  // Print summary
  printSummary(results, needsRestart);
}
