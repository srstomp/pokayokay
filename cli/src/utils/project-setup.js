// cli/src/utils/project-setup.js
import { existsSync, readFileSync } from 'node:fs';
import { join, resolve } from 'node:path';
import { execFile } from 'node:child_process';
import { promisify } from 'node:util';

const execFileAsync = promisify(execFile);

/**
 * Detected project info for a directory
 * @typedef {object} ProjectInfo
 * @property {string} language - Primary language (js, rust, go, python, ruby)
 * @property {string} packageManager - Package manager to use
 * @property {string} installCommand - Command to install dependencies
 * @property {boolean} hasLockfile - Whether lockfile exists
 */

/**
 * JavaScript package manager detection priority
 * Checks lockfiles in order of preference
 */
const JS_PACKAGE_MANAGERS = [
  { lockfile: 'bun.lockb', manager: 'bun', install: 'bun install' },
  { lockfile: 'pnpm-lock.yaml', manager: 'pnpm', install: 'pnpm install' },
  { lockfile: 'yarn.lock', manager: 'yarn', install: 'yarn install' },
  { lockfile: 'package-lock.json', manager: 'npm', install: 'npm install' },
];

/**
 * Multi-language project indicators
 */
const LANGUAGE_INDICATORS = [
  // JavaScript/Node.js
  { file: 'package.json', language: 'js', detectManager: true },
  // Rust
  { file: 'Cargo.toml', language: 'rust', install: 'cargo build' },
  // Go
  { file: 'go.mod', language: 'go', install: 'go mod download' },
  // Python
  { file: 'pyproject.toml', language: 'python', install: 'poetry install' },
  { file: 'requirements.txt', language: 'python', install: 'pip install -r requirements.txt' },
  // Ruby
  { file: 'Gemfile', language: 'ruby', install: 'bundle install' },
];

/**
 * Detect JavaScript package manager from lockfile or package.json
 * @param {string} dir - Directory to check
 * @returns {object|null} Package manager info
 */
export function detectJsPackageManager(dir) {
  // Check lockfiles first (priority order)
  for (const pm of JS_PACKAGE_MANAGERS) {
    if (existsSync(join(dir, pm.lockfile))) {
      return {
        manager: pm.manager,
        install: pm.install,
        hasLockfile: true,
        lockfile: pm.lockfile
      };
    }
  }

  // Check package.json packageManager field
  const pkgPath = join(dir, 'package.json');
  if (existsSync(pkgPath)) {
    try {
      const pkg = JSON.parse(readFileSync(pkgPath, 'utf-8'));
      if (pkg.packageManager) {
        // Format: "pnpm@8.0.0" or "yarn@4.0.0"
        const manager = pkg.packageManager.split('@')[0];
        const pmInfo = JS_PACKAGE_MANAGERS.find(pm => pm.manager === manager);
        if (pmInfo) {
          return {
            manager: pmInfo.manager,
            install: pmInfo.install,
            hasLockfile: false,
            source: 'packageManager field'
          };
        }
      }
    } catch {
      // Invalid JSON, continue
    }

    // Fallback to npm if package.json exists but no lockfile
    return {
      manager: 'npm',
      install: 'npm install',
      hasLockfile: false,
      source: 'fallback'
    };
  }

  return null;
}

/**
 * Detect all project types in a directory (monorepo support)
 * @param {string} dir - Directory to scan
 * @returns {ProjectInfo[]} Array of detected project types
 */
export function detectProjects(dir) {
  const projects = [];

  for (const indicator of LANGUAGE_INDICATORS) {
    const filePath = join(dir, indicator.file);
    if (!existsSync(filePath)) continue;

    if (indicator.detectManager) {
      // JavaScript - use package manager detection
      const jsInfo = detectJsPackageManager(dir);
      if (jsInfo) {
        projects.push({
          language: 'js',
          packageManager: jsInfo.manager,
          installCommand: jsInfo.install,
          hasLockfile: jsInfo.hasLockfile,
          indicator: indicator.file
        });
      }
    } else {
      // Other languages
      projects.push({
        language: indicator.language,
        packageManager: indicator.language,
        installCommand: indicator.install,
        hasLockfile: true, // These files are effectively lockfiles
        indicator: indicator.file
      });
    }
  }

  return projects;
}

/**
 * Execute a command in a specific directory
 * @param {string} cmd - Command to run
 * @param {string[]} args - Command arguments
 * @param {string} cwd - Working directory
 * @returns {Promise<object>} Execution result
 */
async function executeInDir(cmd, args, cwd) {
  const startTime = Date.now();
  try {
    const { stdout, stderr } = await execFileAsync(cmd, args, { cwd: resolve(cwd) });
    return {
      success: true,
      stdout: stdout.toString(),
      stderr: stderr.toString(),
      duration: Date.now() - startTime
    };
  } catch (err) {
    return {
      success: false,
      stdout: err.stdout?.toString() || '',
      stderr: err.stderr?.toString() || err.message,
      duration: Date.now() - startTime,
      error: err
    };
  }
}

/**
 * Install dependencies for a project
 * @param {string} dir - Directory to install in
 * @param {ProjectInfo} project - Project info from detectProjects
 * @returns {object} Install result
 */
export async function installDependencies(dir, project) {
  const [cmd, ...args] = project.installCommand.split(' ');

  const result = await executeInDir(cmd, args, dir);

  return {
    success: result.success,
    project,
    stdout: result.stdout,
    stderr: result.stderr,
    duration: result.duration
  };
}

/**
 * Setup a worktree with all detected dependencies
 * @param {string} worktreePath - Path to worktree
 * @returns {object} Setup results
 */
export async function setupWorktree(worktreePath) {
  const projects = detectProjects(worktreePath);

  if (projects.length === 0) {
    return {
      success: true,
      message: 'No dependencies detected',
      projects: []
    };
  }

  const results = [];
  let allSuccess = true;

  for (const project of projects) {
    const result = await installDependencies(worktreePath, project);
    results.push(result);
    if (!result.success) allSuccess = false;
  }

  return {
    success: allSuccess,
    projects: results
  };
}

/**
 * Format setup output for display
 * @param {object} setupResult - Result from setupWorktree
 * @returns {string} Formatted output
 */
export function formatSetupOutput(setupResult) {
  if (setupResult.projects.length === 0) {
    return 'No dependencies to install.';
  }

  const lines = ['Installing dependencies...'];

  for (const result of setupResult.projects) {
    const { project, success, duration } = result;
    const status = success ? '✓' : '✗';
    const time = duration ? ` (${(duration / 1000).toFixed(1)}s)` : '';
    const indicator = project.hasLockfile
      ? `(${project.indicator || project.packageManager})`
      : '(no lockfile)';

    lines.push(`  ${status} ${project.language}: ${project.installCommand} ${indicator}${time}`);

    if (!success && result.stderr) {
      lines.push(`    Error: ${result.stderr.split('\n')[0]}`);
    }
  }

  return lines.join('\n');
}
