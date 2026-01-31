// cli/src/utils/worktree.js
import { existsSync, readFileSync, appendFileSync } from 'node:fs';
import { join, basename } from 'node:path';
import { execute } from './execute.js';

/**
 * Get the default branch for the repository
 * Priority: symbolic-ref → config → fallback (main → master)
 */
export async function getDefaultBranch() {
  // Try symbolic-ref first
  const symbolicResult = await execute('git', ['symbolic-ref', 'refs/remotes/origin/HEAD']);
  if (symbolicResult.success && symbolicResult.stdout.trim()) {
    // Returns refs/remotes/origin/main → extract "main"
    return symbolicResult.stdout.trim().replace('refs/remotes/origin/', '');
  }

  // Try git config
  const configResult = await execute('git', ['config', '--get', 'init.defaultBranch']);
  if (configResult.success && configResult.stdout.trim()) {
    return configResult.stdout.trim();
  }

  // Fallback: check if main exists, else master
  const mainExists = await execute('git', ['rev-parse', '--verify', 'main']);
  if (mainExists.success) return 'main';

  const masterExists = await execute('git', ['rev-parse', '--verify', 'master']);
  if (masterExists.success) return 'master';

  return 'main'; // Ultimate fallback
}

/**
 * Generate worktree name from task/story
 * @param {object} task - Task object from ohno
 * @returns {string} Worktree name like "story-12-user-auth" or "task-42-login"
 */
export function generateWorktreeName(task) {
  const slug = slugify(task.title);

  if (task.story_id) {
    return `story-${task.story_id}-${slug}`;
  }
  return `task-${task.id}-${slug}`;
}

/**
 * Convert title to URL-safe slug
 */
function slugify(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 30);
}

/**
 * Get the worktrees directory path
 * Always uses .worktrees/ in project root
 */
export function getWorktreesDir() {
  return '.worktrees';
}

/**
 * Ensure .worktrees is in .gitignore
 */
export async function ensureWorktreesIgnored() {
  const gitignorePath = '.gitignore';
  const worktreesDir = getWorktreesDir();

  // Check if already ignored
  const checkResult = await execute('git', ['check-ignore', '-q', worktreesDir]);
  if (checkResult.success) {
    return { alreadyIgnored: true };
  }

  // Add to .gitignore
  const entry = `\n# Worktrees\n${worktreesDir}/\n`;

  if (existsSync(gitignorePath)) {
    appendFileSync(gitignorePath, entry);
  } else {
    appendFileSync(gitignorePath, entry.trim() + '\n');
  }

  return { alreadyIgnored: false, added: true };
}

/**
 * Find existing worktree for a story
 * @param {string} storyId - Story ID to search for
 * @returns {object|null} Worktree info or null
 */
export async function findStoryWorktree(storyId) {
  const result = await execute('git', ['worktree', 'list', '--porcelain']);
  if (!result.success) return null;

  const worktrees = parseWorktreeList(result.stdout);
  const pattern = `story-${storyId}-`;

  for (const wt of worktrees) {
    if (wt.branch && wt.branch.includes(pattern)) {
      return wt;
    }
    if (wt.path && basename(wt.path).startsWith(pattern)) {
      return wt;
    }
  }
  return null;
}

/**
 * Parse git worktree list --porcelain output
 */
function parseWorktreeList(output) {
  const worktrees = [];
  let current = {};

  for (const line of output.split('\n')) {
    if (line.startsWith('worktree ')) {
      if (current.path) worktrees.push(current);
      current = { path: line.replace('worktree ', '') };
    } else if (line.startsWith('HEAD ')) {
      current.head = line.replace('HEAD ', '');
    } else if (line.startsWith('branch ')) {
      current.branch = line.replace('branch refs/heads/', '');
    } else if (line === 'detached') {
      current.detached = true;
    }
  }
  if (current.path) worktrees.push(current);

  return worktrees;
}

/**
 * Create a new worktree
 * @param {string} name - Worktree directory name
 * @param {string} baseBranch - Branch to create from (e.g., "main")
 * @returns {object} Result with path and branch name
 */
export async function createWorktree(name, baseBranch) {
  const worktreesDir = getWorktreesDir();
  const worktreePath = join(worktreesDir, name);
  const branchName = name; // Use same name for branch

  // Ensure directory is ignored
  await ensureWorktreesIgnored();

  // Create worktree with new branch from base
  const result = await execute('git', [
    'worktree', 'add',
    '-b', branchName,
    worktreePath,
    baseBranch
  ]);

  if (!result.success) {
    return { success: false, error: result.stderr };
  }

  return {
    success: true,
    path: worktreePath,
    branch: branchName,
    baseBranch
  };
}

/**
 * Remove a worktree
 * @param {string} path - Worktree path
 * @param {boolean} force - Force removal
 */
export async function removeWorktree(path, force = false) {
  const args = ['worktree', 'remove'];
  if (force) args.push('--force');
  args.push(path);

  const result = await execute('git', args);
  return { success: result.success, error: result.stderr };
}

/**
 * List all worktrees with metadata
 */
export async function listWorktrees() {
  const result = await execute('git', ['worktree', 'list', '--porcelain']);
  if (!result.success) return [];

  const worktrees = parseWorktreeList(result.stdout);

  // Filter to only .worktrees/ entries (exclude main worktree)
  const worktreesDir = getWorktreesDir();
  return worktrees.filter(wt => wt.path.includes(worktreesDir));
}

/**
 * Check if currently in a worktree
 */
export async function isInWorktree() {
  const result = await execute('git', ['rev-parse', '--git-common-dir']);
  if (!result.success) return false;

  const commonDir = result.stdout.trim();
  // If git-common-dir differs from git-dir, we're in a worktree
  const gitDirResult = await execute('git', ['rev-parse', '--git-dir']);
  return commonDir !== gitDirResult.stdout.trim();
}

/**
 * Get current worktree info
 */
export async function getCurrentWorktree() {
  const isWt = await isInWorktree();
  if (!isWt) return null;

  const pathResult = await execute('git', ['rev-parse', '--show-toplevel']);
  const branchResult = await execute('git', ['branch', '--show-current']);

  return {
    path: pathResult.stdout.trim(),
    branch: branchResult.stdout.trim()
  };
}
