# Cleanup Strategies

Dead code removal, consolidation, and naming conventions.

## Dead Code Detection

### Find Unused Exports

```bash
# Using ts-prune
npx ts-prune

# Using knip (recommended)
npx knip

# Using eslint-plugin-unused-imports
# Add to .eslintrc.js
```

### Knip Configuration

```json
// knip.json
{
  "entry": [
    "src/index.ts",
    "src/app/**/*.tsx",
    "src/pages/**/*.tsx"
  ],
  "project": ["src/**/*.{ts,tsx}"],
  "ignore": [
    "**/*.test.ts",
    "**/*.spec.ts",
    "**/__mocks__/**"
  ],
  "ignoreDependencies": [
    "@types/*",
    "prettier",
    "eslint-*"
  ],
  "ignoreExportsUsedInFile": true
}
```

```bash
# Run knip
npx knip                    # Report only
npx knip --fix              # Auto-remove unused exports
npx knip --include files    # Only unused files
npx knip --include exports  # Only unused exports
```

### Find Unused Files

```typescript
// scripts/find-unused-files.ts
import fs from 'fs';
import path from 'path';
import madge from 'madge';

async function findUnusedFiles() {
  const result = await madge('src/index.ts', {
    fileExtensions: ['ts', 'tsx'],
  });
  
  const usedFiles = new Set(Object.keys(result.obj()));
  
  // Add files that are imported
  Object.values(result.obj()).forEach(imports => {
    imports.forEach(imp => usedFiles.add(imp));
  });
  
  // Get all files
  const allFiles: string[] = [];
  function walk(dir: string) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.name === 'node_modules' || entry.name.startsWith('.')) continue;
      const fullPath = path.join(dir, entry.name);
      if (entry.isDirectory()) {
        walk(fullPath);
      } else if (/\.(ts|tsx)$/.test(entry.name) && !entry.name.includes('.test.')) {
        allFiles.push(fullPath);
      }
    }
  }
  walk('src');
  
  // Find unused
  const unused = allFiles.filter(file => {
    const relative = path.relative('src', file);
    return !usedFiles.has(relative);
  });
  
  console.log('Potentially unused files:');
  unused.forEach(f => console.log(`  ${f}`));
}

findUnusedFiles();
```

### Find Unused Dependencies

```bash
# Using depcheck
npx depcheck

# Using knip
npx knip --include dependencies

# Using npm-check
npx npm-check
```

---

## Code Consolidation

### Consolidate Duplicate Functions

```typescript
// Step 1: Find duplicates
grep -r "function formatDate" src/
grep -r "const formatDate" src/

// Step 2: Compare implementations
// If identical or nearly identical, consolidate

// Step 3: Create canonical version
// src/shared/utils/date.ts
export function formatDate(date: Date, format: string = 'short'): string {
  // Best implementation
}

// Step 4: Update all usages
// Use IDE's "Find and Replace in Files"

// Step 5: Delete duplicates
```

### Consolidate Similar Components

```typescript
// BEFORE: Multiple similar buttons
// PrimaryButton.tsx
export function PrimaryButton({ children, onClick }) {
  return <button className="bg-blue-500" onClick={onClick}>{children}</button>;
}

// SecondaryButton.tsx
export function SecondaryButton({ children, onClick }) {
  return <button className="bg-gray-500" onClick={onClick}>{children}</button>;
}

// DangerButton.tsx
export function DangerButton({ children, onClick }) {
  return <button className="bg-red-500" onClick={onClick}>{children}</button>;
}

// AFTER: Single configurable component
// Button.tsx
type ButtonVariant = 'primary' | 'secondary' | 'danger';

const variantStyles: Record<ButtonVariant, string> = {
  primary: 'bg-blue-500 text-white',
  secondary: 'bg-gray-500 text-white',
  danger: 'bg-red-500 text-white',
};

interface ButtonProps {
  variant?: ButtonVariant;
  children: React.ReactNode;
  onClick?: () => void;
}

export function Button({ variant = 'primary', children, onClick }: ButtonProps) {
  return (
    <button className={variantStyles[variant]} onClick={onClick}>
      {children}
    </button>
  );
}

// Usage
<Button variant="primary">Submit</Button>
<Button variant="danger">Delete</Button>
```

### Consolidate Configuration

```typescript
// BEFORE: Config scattered
// src/services/api.ts
const API_URL = process.env.NEXT_PUBLIC_API_URL;

// src/lib/auth.ts
const AUTH_SECRET = process.env.AUTH_SECRET;

// src/utils/logger.ts
const LOG_LEVEL = process.env.LOG_LEVEL || 'info';

// AFTER: Centralized config
// src/config/index.ts
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  API_URL: z.string().url(),
  AUTH_SECRET: z.string().min(32),
  LOG_LEVEL: z.enum(['debug', 'info', 'warn', 'error']).default('info'),
  DATABASE_URL: z.string(),
});

const parsed = envSchema.safeParse(process.env);

if (!parsed.success) {
  console.error('❌ Invalid environment variables:', parsed.error.format());
  process.exit(1);
}

export const config = parsed.data;

// Usage everywhere
import { config } from '@/config';
const apiUrl = config.API_URL;
```

---

## Naming Conventions

### File Naming

```
✅ Recommended patterns:

Components:     PascalCase.tsx      UserList.tsx, OrderForm.tsx
Hooks:          camelCase.ts        useUser.ts, useOrders.ts
Utils:          camelCase.ts        formatDate.ts, validation.ts
Types:          camelCase.ts        user.types.ts (or types.ts)
Constants:      camelCase.ts        constants.ts
Services:       camelCase.ts        user.service.ts
Tests:          *.test.ts           user.service.test.ts
Styles:         *.module.css        Button.module.css

❌ Avoid:
- Mixed conventions in same project
- Generic names: utils.ts, helpers.ts, misc.ts
- Abbreviations: usr.ts, ord.ts
```

### Directory Naming

```
✅ Recommended:
- Lowercase with hyphens: user-management/
- Or lowercase: users/, orders/
- Consistent across project

❌ Avoid:
- PascalCase folders: UserManagement/
- Mixed conventions
- Deep nesting
```

### Rename Script

```typescript
// scripts/rename-files.ts
import fs from 'fs';
import path from 'path';

const renamePatterns: Array<{
  match: RegExp;
  transform: (name: string) => string;
}> = [
  // userService.ts → user.service.ts
  {
    match: /^([a-z]+)Service\.ts$/,
    transform: (name) => name.replace(/^([a-z]+)Service\.ts$/, '$1.service.ts'),
  },
  // UserComponent.tsx → User.tsx (if in components folder)
  {
    match: /^([A-Z][a-zA-Z]+)Component\.tsx$/,
    transform: (name) => name.replace(/Component\.tsx$/, '.tsx'),
  },
];

function renameFiles(dir: string, dryRun = true) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  
  for (const entry of entries) {
    if (entry.name === 'node_modules' || entry.name.startsWith('.')) continue;
    
    const fullPath = path.join(dir, entry.name);
    
    if (entry.isDirectory()) {
      renameFiles(fullPath, dryRun);
    } else {
      for (const pattern of renamePatterns) {
        if (pattern.match.test(entry.name)) {
          const newName = pattern.transform(entry.name);
          const newPath = path.join(dir, newName);
          
          if (dryRun) {
            console.log(`Would rename: ${fullPath} → ${newPath}`);
          } else {
            fs.renameSync(fullPath, newPath);
            console.log(`Renamed: ${fullPath} → ${newPath}`);
          }
          break;
        }
      }
    }
  }
}

// Dry run first
renameFiles('src', true);

// Then actual rename
// renameFiles('src', false);
```

---

## Import Cleanup

### Remove Unused Imports

```bash
# Using eslint
npx eslint --fix src/

# Using organize-imports-cli
npx organize-imports-cli src/**/*.ts

# Using prettier-plugin-organize-imports
# Add to prettier config
```

### ESLint Configuration

```javascript
// .eslintrc.js
module.exports = {
  plugins: ['unused-imports', 'import'],
  rules: {
    'unused-imports/no-unused-imports': 'error',
    'unused-imports/no-unused-vars': [
      'warn',
      {
        vars: 'all',
        varsIgnorePattern: '^_',
        args: 'after-used',
        argsIgnorePattern: '^_',
      },
    ],
    'import/no-duplicates': 'error',
  },
};
```

### Sort and Organize Imports

```javascript
// .prettierrc
{
  "plugins": ["@trivago/prettier-plugin-sort-imports"],
  "importOrder": [
    "^react",
    "^next",
    "<THIRD_PARTY_MODULES>",
    "^@/(.*)$",
    "^[./]"
  ],
  "importOrderSeparation": true,
  "importOrderSortSpecifiers": true
}
```

---

## File Structure Cleanup

### Flatten Deep Nesting

```typescript
// BEFORE: Too deep
src/features/users/components/forms/inputs/text/TextInput.tsx

// AFTER: Flattened
src/features/users/components/TextInput.tsx

// Or if shared:
src/shared/components/inputs/TextInput.tsx
```

### Remove Empty Directories

```bash
# Find empty directories
find src -type d -empty

# Remove empty directories
find src -type d -empty -delete
```

### Consolidate Small Files

```typescript
// BEFORE: Many tiny files
// src/utils/isEmail.ts (3 lines)
// src/utils/isPhone.ts (3 lines)
// src/utils/isUrl.ts (3 lines)

// AFTER: Single file
// src/utils/validation.ts
export function isEmail(value: string): boolean { /* ... */ }
export function isPhone(value: string): boolean { /* ... */ }
export function isUrl(value: string): boolean { /* ... */ }
```

---

## Type Cleanup

### Remove Duplicate Types

```typescript
// Step 1: Find similar types
grep -r "interface User" src/
grep -r "type User" src/

// Step 2: Compare and merge
// BEFORE:
// types/user.ts
interface User { id: string; name: string; email: string; }

// services/types.ts
interface UserData { id: string; name: string; email: string; }  // Duplicate!

// AFTER:
// types/user.ts
export interface User {
  id: string;
  name: string;
  email: string;
}

// Use everywhere
import { User } from '@/types/user';
```

### Remove `any` Types

```typescript
// Find all 'any' usages
grep -r ": any" src/ | grep -v node_modules

// Replace with proper types
// BEFORE
function processData(data: any): any {
  return data.map((item: any) => item.value);
}

// AFTER
interface DataItem {
  value: string;
  // ... other properties
}

function processData(data: DataItem[]): string[] {
  return data.map(item => item.value);
}
```

### Type Consolidation Script

```typescript
// scripts/find-duplicate-types.ts
import fs from 'fs';
import path from 'path';

interface TypeDefinition {
  name: string;
  file: string;
  line: number;
  type: 'interface' | 'type';
}

function findTypes(dir: string): TypeDefinition[] {
  const types: TypeDefinition[] = [];
  
  function walk(currentDir: string) {
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });
    
    for (const entry of entries) {
      if (entry.name === 'node_modules') continue;
      
      const fullPath = path.join(currentDir, entry.name);
      
      if (entry.isDirectory()) {
        walk(fullPath);
      } else if (/\.(ts|tsx)$/.test(entry.name)) {
        const content = fs.readFileSync(fullPath, 'utf-8');
        const lines = content.split('\n');
        
        lines.forEach((line, index) => {
          // Match interface declarations
          const interfaceMatch = line.match(/^export\s+interface\s+(\w+)/);
          if (interfaceMatch) {
            types.push({
              name: interfaceMatch[1],
              file: fullPath,
              line: index + 1,
              type: 'interface',
            });
          }
          
          // Match type declarations
          const typeMatch = line.match(/^export\s+type\s+(\w+)/);
          if (typeMatch) {
            types.push({
              name: typeMatch[1],
              file: fullPath,
              line: index + 1,
              type: 'type',
            });
          }
        });
      }
    }
  }
  
  walk(dir);
  return types;
}

// Find duplicates
const types = findTypes('src');
const byName = new Map<string, TypeDefinition[]>();

types.forEach(t => {
  const existing = byName.get(t.name) || [];
  existing.push(t);
  byName.set(t.name, existing);
});

console.log('Duplicate type definitions:');
byName.forEach((definitions, name) => {
  if (definitions.length > 1) {
    console.log(`\n${name}:`);
    definitions.forEach(d => {
      console.log(`  ${d.file}:${d.line}`);
    });
  }
});
```

---

## Comment Cleanup

### Remove TODO/FIXME Accumulation

```bash
# Find all TODOs
grep -rn "TODO\|FIXME\|HACK\|XXX" src/

# Count by type
grep -r "TODO" src/ | wc -l
grep -r "FIXME" src/ | wc -l
```

### Process TODO Comments

```typescript
// scripts/process-todos.ts
import fs from 'fs';
import path from 'path';

interface TodoItem {
  file: string;
  line: number;
  type: 'TODO' | 'FIXME' | 'HACK' | 'XXX';
  text: string;
  author?: string;
  date?: string;
}

function extractTodos(dir: string): TodoItem[] {
  const todos: TodoItem[] = [];
  const todoRegex = /\/\/\s*(TODO|FIXME|HACK|XXX)(\([^)]+\))?:?\s*(.+)/i;
  
  function walk(currentDir: string) {
    const entries = fs.readdirSync(currentDir, { withFileTypes: true });
    
    for (const entry of entries) {
      if (entry.name === 'node_modules') continue;
      
      const fullPath = path.join(currentDir, entry.name);
      
      if (entry.isDirectory()) {
        walk(fullPath);
      } else if (/\.(ts|tsx|js|jsx)$/.test(entry.name)) {
        const content = fs.readFileSync(fullPath, 'utf-8');
        const lines = content.split('\n');
        
        lines.forEach((line, index) => {
          const match = line.match(todoRegex);
          if (match) {
            todos.push({
              file: path.relative(process.cwd(), fullPath),
              line: index + 1,
              type: match[1].toUpperCase() as TodoItem['type'],
              text: match[3].trim(),
              author: match[2]?.replace(/[()]/g, ''),
            });
          }
        });
      }
    }
  }
  
  walk(dir);
  return todos;
}

const todos = extractTodos('src');

// Group by type
const byType = {
  FIXME: todos.filter(t => t.type === 'FIXME'),
  TODO: todos.filter(t => t.type === 'TODO'),
  HACK: todos.filter(t => t.type === 'HACK'),
  XXX: todos.filter(t => t.type === 'XXX'),
};

// Report
console.log('=== TODO/FIXME Report ===\n');

if (byType.FIXME.length > 0) {
  console.log(`🔴 FIXME (${byType.FIXME.length}):`);
  byType.FIXME.forEach(t => {
    console.log(`  ${t.file}:${t.line} - ${t.text}`);
  });
}

if (byType.TODO.length > 0) {
  console.log(`\n🟡 TODO (${byType.TODO.length}):`);
  byType.TODO.slice(0, 20).forEach(t => {
    console.log(`  ${t.file}:${t.line} - ${t.text}`);
  });
  if (byType.TODO.length > 20) {
    console.log(`  ... and ${byType.TODO.length - 20} more`);
  }
}
```

---

## Cleanup Checklist

### Quick Wins (< 1 hour)
- [ ] Remove unused imports (`eslint --fix`)
- [ ] Sort imports consistently
- [ ] Remove console.log statements
- [ ] Fix obvious type errors

### Short-term (1 day)
- [ ] Run knip, address unused exports
- [ ] Consolidate duplicate utility functions
- [ ] Standardize file naming
- [ ] Remove empty files and directories

### Medium-term (1 week)
- [ ] Consolidate similar components
- [ ] Centralize configuration
- [ ] Address TODO/FIXME backlog
- [ ] Update outdated dependencies

### Long-term (ongoing)
- [ ] Enforce conventions with linting
- [ ] Regular dependency audits
- [ ] Periodic architecture reviews
- [ ] Documentation updates
