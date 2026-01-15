# Analysis Techniques

Methods for understanding and evaluating project architecture.

## Directory Structure Analysis

### Generate Structure Map

```bash
# Basic tree (exclude common noise)
tree -I 'node_modules|dist|build|.git|coverage' -L 4

# With file counts
tree -I 'node_modules|dist|.git' --dirsfirst -L 3 | head -100

# Just directories
tree -d -I 'node_modules|dist|.git' -L 4

# With file sizes
tree -I 'node_modules|dist|.git' -h -L 3
```

### Analyze File Distribution

```bash
# Count files by extension
find src -type f | sed 's/.*\.//' | sort | uniq -c | sort -rn

# Count files per directory
find src -type f | xargs -n1 dirname | sort | uniq -c | sort -rn | head -20

# Find largest files
find src -type f -name "*.ts" -exec wc -l {} + | sort -rn | head -20

# Find deeply nested files
find src -type f | awk -F/ '{print NF-1, $0}' | sort -rn | head -20
```

### Structure Report Script

```typescript
// scripts/analyze-structure.ts
import fs from 'fs';
import path from 'path';

interface DirectoryStats {
  path: string;
  fileCount: number;
  totalLines: number;
  avgFileSize: number;
  depth: number;
  children: DirectoryStats[];
}

function analyzeDirectory(dirPath: string, depth = 0): DirectoryStats {
  const entries = fs.readdirSync(dirPath, { withFileTypes: true });
  const stats: DirectoryStats = {
    path: dirPath,
    fileCount: 0,
    totalLines: 0,
    avgFileSize: 0,
    depth,
    children: [],
  };

  for (const entry of entries) {
    if (entry.name.startsWith('.') || entry.name === 'node_modules') continue;

    const fullPath = path.join(dirPath, entry.name);

    if (entry.isDirectory()) {
      stats.children.push(analyzeDirectory(fullPath, depth + 1));
    } else if (entry.isFile() && /\.(ts|tsx|js|jsx)$/.test(entry.name)) {
      const content = fs.readFileSync(fullPath, 'utf-8');
      const lines = content.split('\n').length;
      stats.fileCount++;
      stats.totalLines += lines;
    }
  }

  // Aggregate children
  for (const child of stats.children) {
    stats.fileCount += child.fileCount;
    stats.totalLines += child.totalLines;
  }

  stats.avgFileSize = stats.fileCount > 0 ? Math.round(stats.totalLines / stats.fileCount) : 0;

  return stats;
}

function printReport(stats: DirectoryStats, indent = 0): void {
  const prefix = '  '.repeat(indent);
  const name = path.basename(stats.path) || stats.path;
  console.log(`${prefix}${name}/ (${stats.fileCount} files, ${stats.totalLines} lines, avg ${stats.avgFileSize})`);

  for (const child of stats.children.sort((a, b) => b.totalLines - a.totalLines)) {
    if (child.fileCount > 0) {
      printReport(child, indent + 1);
    }
  }
}

const stats = analyzeDirectory('./src');
printReport(stats);
```

---

## Dependency Analysis

### Import Graph Visualization

```bash
# Using madge (install: npm i -g madge)
madge --image graph.svg src/index.ts
madge --circular src/  # Find circular dependencies
madge --orphans src/   # Find files not imported anywhere
madge --leaves src/    # Find files that don't import anything
```

### Dependency Matrix Script

```typescript
// scripts/analyze-deps.ts
import fs from 'fs';
import path from 'path';

interface ImportInfo {
  file: string;
  imports: string[];
  importedBy: string[];
}

function extractImports(filePath: string): string[] {
  const content = fs.readFileSync(filePath, 'utf-8');
  const imports: string[] = [];

  // Match import statements
  const importRegex = /import\s+(?:(?:\{[^}]*\}|\*\s+as\s+\w+|\w+)\s+from\s+)?['"]([^'"]+)['"]/g;
  let match;

  while ((match = importRegex.exec(content)) !== null) {
    const importPath = match[1];
    if (importPath.startsWith('.')) {
      // Resolve relative import
      const resolved = path.resolve(path.dirname(filePath), importPath);
      imports.push(resolved);
    }
  }

  return imports;
}

function analyzeImports(srcDir: string): Map<string, ImportInfo> {
  const files = new Map<string, ImportInfo>();

  function walkDir(dir: string) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.name === 'node_modules' || entry.name.startsWith('.')) continue;

      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        walkDir(fullPath);
      } else if (/\.(ts|tsx|js|jsx)$/.test(entry.name)) {
        files.set(fullPath, {
          file: fullPath,
          imports: extractImports(fullPath),
          importedBy: [],
        });
      }
    }
  }

  walkDir(srcDir);

  // Build reverse index
  for (const [file, info] of files) {
    for (const imported of info.imports) {
      // Try with extensions
      for (const ext of ['', '.ts', '.tsx', '/index.ts', '/index.tsx']) {
        const resolved = imported + ext;
        if (files.has(resolved)) {
          files.get(resolved)!.importedBy.push(file);
          break;
        }
      }
    }
  }

  return files;
}

function findCircularDeps(files: Map<string, ImportInfo>): string[][] {
  const cycles: string[][] = [];
  const visited = new Set<string>();
  const stack = new Set<string>();

  function dfs(file: string, path: string[]): void {
    if (stack.has(file)) {
      // Found cycle
      const cycleStart = path.indexOf(file);
      cycles.push(path.slice(cycleStart));
      return;
    }

    if (visited.has(file)) return;

    visited.add(file);
    stack.add(file);

    const info = files.get(file);
    if (info) {
      for (const imported of info.imports) {
        dfs(imported, [...path, file]);
      }
    }

    stack.delete(file);
  }

  for (const file of files.keys()) {
    dfs(file, []);
  }

  return cycles;
}

function findHubs(files: Map<string, ImportInfo>): Array<{ file: string; score: number }> {
  return Array.from(files.entries())
    .map(([file, info]) => ({
      file: path.relative(process.cwd(), file),
      score: info.imports.length + info.importedBy.length,
    }))
    .sort((a, b) => b.score - a.score)
    .slice(0, 20);
}

// Run analysis
const files = analyzeImports('./src');
console.log('\n=== Circular Dependencies ===');
const cycles = findCircularDeps(files);
cycles.forEach((cycle, i) => {
  console.log(`\nCycle ${i + 1}:`);
  cycle.forEach(f => console.log(`  → ${path.relative(process.cwd(), f)}`));
});

console.log('\n=== Hub Files (Most Connected) ===');
findHubs(files).forEach(({ file, score }) => {
  console.log(`  ${score.toString().padStart(3)} connections: ${file}`);
});
```

### Dependency Direction Analysis

```typescript
// Check that dependencies flow in correct direction
// UI → Services → Data

const LAYERS = {
  'components': 1,
  'pages': 1,
  'hooks': 2,
  'services': 3,
  'repositories': 4,
  'models': 5,
  'utils': 6,  // Can be used anywhere
};

function checkLayerViolations(files: Map<string, ImportInfo>): string[] {
  const violations: string[] = [];

  for (const [file, info] of files) {
    const fileLayer = getLayer(file);
    if (fileLayer === null) continue;

    for (const imported of info.imports) {
      const importedLayer = getLayer(imported);
      if (importedLayer === null) continue;

      // Higher layers should not import from lower layers
      // (Lower number = higher in architecture)
      if (importedLayer < fileLayer && !isUtilsLayer(imported)) {
        violations.push(
          `${path.basename(file)} (layer ${fileLayer}) imports ${path.basename(imported)} (layer ${importedLayer})`
        );
      }
    }
  }

  return violations;
}

function getLayer(filePath: string): number | null {
  for (const [folder, layer] of Object.entries(LAYERS)) {
    if (filePath.includes(`/${folder}/`)) {
      return layer;
    }
  }
  return null;
}
```

---

## Complexity Metrics

### File Complexity

```typescript
// scripts/analyze-complexity.ts

interface FileComplexity {
  file: string;
  lines: number;
  functions: number;
  imports: number;
  exports: number;
  complexity: 'low' | 'medium' | 'high' | 'critical';
}

function analyzeFileComplexity(filePath: string): FileComplexity {
  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n').length;

  // Count functions (rough estimate)
  const functionMatches = content.match(/function\s+\w+|const\s+\w+\s*=\s*(?:async\s*)?\(/g);
  const functions = functionMatches?.length ?? 0;

  // Count imports
  const importMatches = content.match(/^import\s+/gm);
  const imports = importMatches?.length ?? 0;

  // Count exports
  const exportMatches = content.match(/^export\s+/gm);
  const exports = exportMatches?.length ?? 0;

  // Determine complexity
  let complexity: FileComplexity['complexity'] = 'low';
  if (lines > 500 || functions > 20 || imports > 30) {
    complexity = 'critical';
  } else if (lines > 300 || functions > 15 || imports > 20) {
    complexity = 'high';
  } else if (lines > 150 || functions > 10 || imports > 10) {
    complexity = 'medium';
  }

  return {
    file: path.relative(process.cwd(), filePath),
    lines,
    functions,
    imports,
    exports,
    complexity,
  };
}

// Find complex files
function findComplexFiles(srcDir: string): FileComplexity[] {
  const results: FileComplexity[] = [];

  function walk(dir: string) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.name === 'node_modules' || entry.name.startsWith('.')) continue;

      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        walk(fullPath);
      } else if (/\.(ts|tsx|js|jsx)$/.test(entry.name)) {
        results.push(analyzeFileComplexity(fullPath));
      }
    }
  }

  walk(srcDir);

  return results
    .filter(f => f.complexity !== 'low')
    .sort((a, b) => b.lines - a.lines);
}
```

### Cohesion Analysis

```typescript
// Check if files in a folder are related

function analyzeCohesion(folderPath: string): {
  folder: string;
  cohesion: 'high' | 'medium' | 'low';
  internalImports: number;
  externalImports: number;
  issues: string[];
} {
  const files = fs.readdirSync(folderPath)
    .filter(f => /\.(ts|tsx|js|jsx)$/.test(f))
    .map(f => path.join(folderPath, f));

  let internalImports = 0;
  let externalImports = 0;
  const issues: string[] = [];

  for (const file of files) {
    const imports = extractImports(file);

    for (const imp of imports) {
      const isInternal = files.some(f =>
        imp.startsWith(folderPath) ||
        f.startsWith(imp)
      );

      if (isInternal) {
        internalImports++;
      } else {
        externalImports++;
      }
    }
  }

  const ratio = internalImports / (internalImports + externalImports || 1);

  let cohesion: 'high' | 'medium' | 'low' = 'high';
  if (ratio < 0.3) {
    cohesion = 'low';
    issues.push('Files in this folder rarely import each other');
  } else if (ratio < 0.5) {
    cohesion = 'medium';
  }

  return {
    folder: path.relative(process.cwd(), folderPath),
    cohesion,
    internalImports,
    externalImports,
    issues,
  };
}
```

---

## Code Pattern Detection

### Detect Common Issues

```typescript
// scripts/detect-issues.ts

interface Issue {
  type: string;
  severity: 'critical' | 'high' | 'medium' | 'low';
  file: string;
  line?: number;
  message: string;
}

function detectIssues(filePath: string): Issue[] {
  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');
  const issues: Issue[] = [];
  const relativePath = path.relative(process.cwd(), filePath);

  // Check for barrel file with too many exports
  if (filePath.endsWith('index.ts') || filePath.endsWith('index.tsx')) {
    const exportCount = (content.match(/export \* from/g) || []).length;
    if (exportCount > 10) {
      issues.push({
        type: 'barrel-explosion',
        severity: 'medium',
        file: relativePath,
        message: `Barrel file with ${exportCount} re-exports may cause bundle bloat`,
      });
    }
  }

  // Check for mixed concerns (e.g., DB access in component)
  if (filePath.includes('/components/') || filePath.includes('/pages/')) {
    if (content.includes('prisma') || content.includes('mongoose')) {
      issues.push({
        type: 'layer-violation',
        severity: 'high',
        file: relativePath,
        message: 'Direct database access in UI layer',
      });
    }
  }

  // Check for god files
  if (lines.length > 500) {
    issues.push({
      type: 'god-file',
      severity: 'high',
      file: relativePath,
      message: `File has ${lines.length} lines, consider splitting`,
    });
  }

  // Check for too many imports
  const importCount = (content.match(/^import /gm) || []).length;
  if (importCount > 25) {
    issues.push({
      type: 'high-coupling',
      severity: 'medium',
      file: relativePath,
      message: `File has ${importCount} imports, may indicate high coupling`,
    });
  }

  // Check for any/unknown abuse
  const anyCount = (content.match(/: any\b/g) || []).length;
  if (anyCount > 5) {
    issues.push({
      type: 'type-safety',
      severity: 'medium',
      file: relativePath,
      message: `File has ${anyCount} 'any' types`,
    });
  }

  // Check for TODO/FIXME accumulation
  const todoCount = (content.match(/\/\/\s*(TODO|FIXME|HACK|XXX)/gi) || []).length;
  if (todoCount > 3) {
    issues.push({
      type: 'tech-debt',
      severity: 'low',
      file: relativePath,
      message: `File has ${todoCount} TODO/FIXME comments`,
    });
  }

  // Check for console.log in production code
  if (!filePath.includes('.test.') && !filePath.includes('.spec.')) {
    const consoleCount = (content.match(/console\.(log|debug|info)/g) || []).length;
    if (consoleCount > 0) {
      issues.push({
        type: 'debug-code',
        severity: 'low',
        file: relativePath,
        message: `File has ${consoleCount} console statements`,
      });
    }
  }

  return issues;
}
```

### Generate Issue Report

```typescript
function generateIssueReport(srcDir: string): void {
  const allIssues: Issue[] = [];

  function walk(dir: string) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });

    for (const entry of entries) {
      if (entry.name === 'node_modules' || entry.name.startsWith('.')) continue;

      const fullPath = path.join(dir, entry.name);

      if (entry.isDirectory()) {
        walk(fullPath);
      } else if (/\.(ts|tsx|js|jsx)$/.test(entry.name)) {
        allIssues.push(...detectIssues(fullPath));
      }
    }
  }

  walk(srcDir);

  // Group by severity
  const bySeverity = {
    critical: allIssues.filter(i => i.severity === 'critical'),
    high: allIssues.filter(i => i.severity === 'high'),
    medium: allIssues.filter(i => i.severity === 'medium'),
    low: allIssues.filter(i => i.severity === 'low'),
  };

  console.log('\n=== Architecture Issues Report ===\n');

  for (const [severity, issues] of Object.entries(bySeverity)) {
    if (issues.length === 0) continue;

    console.log(`\n## ${severity.toUpperCase()} (${issues.length})\n`);

    for (const issue of issues) {
      console.log(`- [${issue.type}] ${issue.file}`);
      console.log(`  ${issue.message}`);
    }
  }

  console.log('\n=== Summary ===');
  console.log(`Critical: ${bySeverity.critical.length}`);
  console.log(`High: ${bySeverity.high.length}`);
  console.log(`Medium: ${bySeverity.medium.length}`);
  console.log(`Low: ${bySeverity.low.length}`);
}
```

---

## External Tools

### Recommended Tools

| Tool | Purpose | Install |
|------|---------|---------|
| **madge** | Dependency graphs, circular deps | `npm i -g madge` |
| **dependency-cruiser** | Dependency rules, validation | `npm i -D dependency-cruiser` |
| **source-map-explorer** | Bundle analysis | `npm i -D source-map-explorer` |
| **webpack-bundle-analyzer** | Bundle visualization | `npm i -D webpack-bundle-analyzer` |
| **eslint-plugin-import** | Import linting | `npm i -D eslint-plugin-import` |
| **knip** | Find unused files/exports | `npm i -D knip` |

### Dependency Cruiser Config

```javascript
// .dependency-cruiser.js
module.exports = {
  forbidden: [
    {
      name: 'no-circular',
      severity: 'error',
      from: {},
      to: { circular: true },
    },
    {
      name: 'no-orphans',
      severity: 'warn',
      from: { orphan: true, pathNot: '\\.d\\.ts$' },
      to: {},
    },
    {
      name: 'no-ui-to-data',
      severity: 'error',
      from: { path: '^src/components' },
      to: { path: '^src/repositories' },
    },
  ],
  options: {
    doNotFollow: { path: 'node_modules' },
    tsConfig: { fileName: 'tsconfig.json' },
  },
};
```

```bash
# Run dependency-cruiser
npx depcruise src --config .dependency-cruiser.js
npx depcruise src --output-type dot | dot -T svg > deps.svg
```

### Knip Config (Find Unused)

```json
// knip.json
{
  "entry": ["src/index.ts", "src/main.ts"],
  "project": ["src/**/*.ts"],
  "ignore": ["**/*.test.ts", "**/*.spec.ts"],
  "ignoreDependencies": ["@types/*"]
}
```

```bash
npx knip  # Find unused files, exports, dependencies
```
