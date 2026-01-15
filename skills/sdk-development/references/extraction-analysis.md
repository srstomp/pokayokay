# Extraction Analysis

Analyzing existing code to plan SDK extraction.

## Analysis Process

```
┌─────────────────────────────────────────────────────────────┐
│                    ANALYSIS PROCESS                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. SCOPE              2. DEPENDENCIES       3. BOUNDARIES  │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐ │
│  │ What code?  │  →   │ Internal    │  →   │ What's in?  │ │
│  │ What files? │      │ External    │      │ What's out? │ │
│  │ What funcs? │      │ Circular?   │      │ Interface?  │ │
│  └─────────────┘      └─────────────┘      └─────────────┘ │
│                                                             │
│  4. USAGES             5. TESTS            6. PLAN          │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐ │
│  │ Who calls?  │  →   │ Coverage?   │  →   │ Order       │ │
│  │ How used?   │      │ Add tests?  │      │ Phases      │ │
│  │ Patterns?   │      │ Behavior?   │      │ Timeline    │ │
│  └─────────────┘      └─────────────┘      └─────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Identify Scope

### Find Candidate Code

```bash
# Example: Finding auth-related code
find src -name "*.ts" | xargs grep -l "auth\|login\|token\|session" | head -20

# List files in suspected directories
tree src/services/auth
tree src/lib/auth
tree src/utils/auth
```

### Map File Structure

```typescript
// Document what you find
const authCodeMap = {
  // Core functionality
  'src/services/auth/client.ts': 'Main auth client',
  'src/services/auth/api.ts': 'API calls',
  'src/services/auth/storage.ts': 'Token storage',
  
  // Types
  'src/types/auth.ts': 'Auth types',
  'src/services/auth/types.ts': 'Internal types',
  
  // Utilities
  'src/utils/jwt.ts': 'JWT parsing',
  'src/utils/storage.ts': 'Generic storage (shared)',
  
  // UI (don't extract)
  'src/components/LoginForm.tsx': 'UI component',
  'src/hooks/useAuth.ts': 'React hook',
};
```

### Categorize Code

```typescript
interface ExtractionScope {
  // Core: Must be in SDK
  core: string[];
  
  // Supporting: Needed by core
  supporting: string[];
  
  // Shared: Used by core AND other app code
  shared: string[];
  
  // Excluded: App-specific, not extracted
  excluded: string[];
}

const scope: ExtractionScope = {
  core: [
    'src/services/auth/client.ts',
    'src/services/auth/api.ts',
    'src/services/auth/types.ts',
  ],
  
  supporting: [
    'src/services/auth/storage.ts',
    'src/utils/jwt.ts',
  ],
  
  shared: [
    'src/utils/storage.ts',  // Used by auth AND other services
    'src/utils/http.ts',      // Used by auth AND other services
  ],
  
  excluded: [
    'src/components/LoginForm.tsx',  // UI component
    'src/hooks/useAuth.ts',           // React-specific
    'src/pages/login.tsx',            // App page
  ],
};
```

---

## Step 2: Analyze Dependencies

### Internal Dependencies

```bash
# Find what auth code imports from within the app
grep -r "from '\.\." src/services/auth/ | grep -v node_modules
grep -r "from '@/" src/services/auth/
```

```typescript
// Example dependency map
const internalDeps = {
  'src/services/auth/client.ts': [
    'src/services/auth/api.ts',      // ✅ Will be in SDK
    'src/services/auth/storage.ts',  // ✅ Will be in SDK
    'src/types/auth.ts',             // ✅ Will be in SDK
    'src/utils/http.ts',             // ⚠️ Shared utility
    'src/config/index.ts',           // ❌ App config - must remove
  ],
  
  'src/services/auth/api.ts': [
    'src/utils/http.ts',             // ⚠️ Shared utility
    'src/types/auth.ts',             // ✅ Will be in SDK
  ],
};
```

### External Dependencies

```bash
# Find external package imports
grep -r "from '" src/services/auth/ | grep "node_modules\|^[^./]" | sort -u
```

```typescript
// Document external dependencies
const externalDeps = {
  required: [
    // Must be bundled or peer dep
  ],
  
  optional: [
    // Used but can be made optional
  ],
  
  appSpecific: [
    // Must be removed/replaced
    'next/router',        // Framework-specific
    '@/config',           // App config
  ],
};
```

### Circular Dependencies

```bash
# Check for circular dependencies
npx madge --circular src/services/auth/
```

```typescript
// If circular deps exist, document and plan resolution
const circularDeps = [
  {
    cycle: ['client.ts', 'api.ts', 'client.ts'],
    resolution: 'Extract shared types to separate file',
  },
];
```

### Dependency Graph Script

```typescript
// scripts/analyze-deps.ts
import fs from 'fs';
import path from 'path';

interface DependencyInfo {
  file: string;
  imports: {
    internal: string[];
    external: string[];
    relative: string[];
  };
  exportedSymbols: string[];
}

function analyzeFile(filePath: string): DependencyInfo {
  const content = fs.readFileSync(filePath, 'utf-8');
  const imports = {
    internal: [] as string[],
    external: [] as string[],
    relative: [] as string[],
  };
  
  // Match imports
  const importRegex = /import\s+(?:{[^}]+}|[\w*]+(?:\s+as\s+\w+)?)\s+from\s+['"]([^'"]+)['"]/g;
  let match;
  
  while ((match = importRegex.exec(content)) !== null) {
    const importPath = match[1];
    
    if (importPath.startsWith('.')) {
      imports.relative.push(importPath);
    } else if (importPath.startsWith('@/') || importPath.startsWith('src/')) {
      imports.internal.push(importPath);
    } else {
      imports.external.push(importPath);
    }
  }
  
  // Find exports
  const exportRegex = /export\s+(?:const|function|class|interface|type|enum)\s+(\w+)/g;
  const exportedSymbols: string[] = [];
  
  while ((match = exportRegex.exec(content)) !== null) {
    exportedSymbols.push(match[1]);
  }
  
  return { file: filePath, imports, exportedSymbols };
}

// Analyze all files in scope
function analyzeScope(files: string[]): Map<string, DependencyInfo> {
  const analysis = new Map<string, DependencyInfo>();
  
  for (const file of files) {
    analysis.set(file, analyzeFile(file));
  }
  
  return analysis;
}
```

---

## Step 3: Define Boundaries

### What Goes In SDK

```typescript
interface SDKBoundary {
  // Public API surface
  exports: {
    classes: string[];
    functions: string[];
    types: string[];
    constants: string[];
  };
  
  // Internal implementation
  internal: string[];
  
  // Configuration requirements
  config: {
    required: string[];
    optional: string[];
  };
  
  // External dependencies
  dependencies: {
    runtime: string[];
    peer: string[];
    dev: string[];
  };
}

const sdkBoundary: SDKBoundary = {
  exports: {
    classes: ['AuthClient'],
    functions: ['createAuthClient'],
    types: ['AuthConfig', 'User', 'Session', 'AuthError'],
    constants: ['AUTH_EVENTS'],
  },
  
  internal: [
    'TokenStorage',
    'TokenRefresher',
    'JwtParser',
    'HttpClient',
  ],
  
  config: {
    required: ['baseUrl'],
    optional: ['timeout', 'storage', 'onTokenRefresh'],
  },
  
  dependencies: {
    runtime: [],  // No runtime deps (ideal)
    peer: [],
    dev: ['typescript', 'tsup', 'vitest'],
  },
};
```

### What Stays in App

```typescript
const appBoundary = {
  // Framework-specific code
  framework: [
    'src/hooks/useAuth.ts',      // React hook
    'src/context/AuthContext.tsx', // React context
    'src/components/LoginForm.tsx',
  ],
  
  // App configuration
  config: [
    'src/config/auth.ts',  // App-specific config values
  ],
  
  // App-specific extensions
  extensions: [
    'src/services/auth/analytics.ts',  // App analytics integration
  ],
};
```

### Interface Design

```typescript
// Design the public interface BEFORE extraction

// sdk/src/types.ts
export interface AuthConfig {
  /** Base URL for auth API */
  baseUrl: string;
  
  /** Request timeout in milliseconds */
  timeout?: number;
  
  /** Custom storage implementation */
  storage?: TokenStorage;
  
  /** Called when token is refreshed */
  onTokenRefresh?: (token: string) => void;
  
  /** Called on authentication errors */
  onError?: (error: AuthError) => void;
}

export interface TokenStorage {
  getToken(): string | null;
  setToken(token: string): void;
  removeToken(): void;
}

export interface User {
  id: string;
  email: string;
  name: string;
  roles: string[];
}

export interface Session {
  user: User;
  accessToken: string;
  refreshToken: string;
  expiresAt: number;
}

// sdk/src/client.ts
export class AuthClient {
  constructor(config: AuthConfig);
  
  // Authentication
  login(email: string, password: string): Promise<Session>;
  logout(): Promise<void>;
  refreshToken(): Promise<string>;
  
  // State
  getUser(): User | null;
  getSession(): Session | null;
  isAuthenticated(): boolean;
  
  // Events
  onStateChange(callback: (user: User | null) => void): () => void;
}
```

---

## Step 4: Find All Usages

### Search for Usages

```bash
# Find all imports of auth code
grep -rn "from.*auth" src/ --include="*.ts" --include="*.tsx" | grep -v "node_modules"

# Find all usages of specific exports
grep -rn "AuthClient\|useAuth\|authService" src/ --include="*.ts" --include="*.tsx"
```

### Document Usage Patterns

```typescript
// Map how auth is currently used
const usagePatterns = {
  // Direct client usage
  'src/pages/api/protected.ts': {
    imports: ['authService'],
    usage: 'authService.verifyToken(token)',
    migration: 'Import from @org/auth-sdk instead',
  },
  
  // React hook usage
  'src/components/Dashboard.tsx': {
    imports: ['useAuth'],
    usage: 'const { user, logout } = useAuth()',
    migration: 'useAuth stays in app, wraps SDK',
  },
  
  // Direct API calls (should use SDK)
  'src/pages/login.tsx': {
    imports: ['authApi'],
    usage: 'authApi.login(email, password)',
    migration: 'Replace with SDK client',
  },
};
```

### Count Impact

```typescript
const impactAnalysis = {
  // Files that will need updates
  filesAffected: 23,
  
  // By category
  breakdown: {
    components: 8,    // React components using hooks
    pages: 5,         // Pages using auth
    apiRoutes: 6,     // API routes verifying auth
    utilities: 4,     // Utils depending on auth
  },
  
  // Risk assessment
  risk: 'medium',  // Based on number of changes
};
```

---

## Step 5: Verify Test Coverage

### Check Existing Coverage

```bash
# Run coverage for auth code
npx vitest run --coverage src/services/auth/
```

### Document Coverage

```typescript
const testCoverage = {
  files: {
    'client.ts': { lines: 78, branches: 65, functions: 80 },
    'api.ts': { lines: 90, branches: 85, functions: 95 },
    'storage.ts': { lines: 60, branches: 50, functions: 70 },
  },
  
  gaps: [
    'Error handling in refreshToken()',
    'Edge case: expired token during refresh',
    'Storage fallback when localStorage unavailable',
  ],
  
  recommendation: 'Add tests for gaps before extraction',
};
```

### Write Missing Tests

```typescript
// Add tests for behavior before extraction
describe('AuthClient', () => {
  describe('refreshToken', () => {
    it('refreshes token when access token expired', async () => {
      // Document current behavior
    });
    
    it('handles refresh token also expired', async () => {
      // Document error behavior
    });
    
    it('queues multiple refresh requests', async () => {
      // Document race condition handling
    });
  });
});
```

---

## Step 6: Create Extraction Plan

### Phased Approach

```typescript
interface ExtractionPlan {
  phases: Phase[];
  timeline: string;
  rollback: string;
}

interface Phase {
  name: string;
  tasks: string[];
  validation: string[];
  duration: string;
}

const extractionPlan: ExtractionPlan = {
  phases: [
    {
      name: 'Phase 1: Preparation',
      tasks: [
        'Add missing tests for auth code',
        'Document current behavior',
        'Create SDK package structure',
        'Set up build tooling',
      ],
      validation: [
        'All auth tests passing',
        'Behavior documented',
        'Package builds successfully',
      ],
      duration: '2-3 days',
    },
    
    {
      name: 'Phase 2: Extract Core',
      tasks: [
        'Copy types to SDK',
        'Copy error classes to SDK',
        'Copy core client to SDK',
        'Remove app-specific dependencies',
        'Add SDK tests',
      ],
      validation: [
        'SDK builds',
        'SDK tests pass',
        'No app dependencies in SDK',
      ],
      duration: '3-4 days',
    },
    
    {
      name: 'Phase 3: Integrate',
      tasks: [
        'Add SDK as app dependency',
        'Update app imports',
        'Update app hooks to use SDK',
        'Remove old auth code from app',
      ],
      validation: [
        'App builds',
        'App tests pass',
        'No duplicate code',
      ],
      duration: '2-3 days',
    },
    
    {
      name: 'Phase 4: Publish',
      tasks: [
        'Write SDK documentation',
        'Add usage examples',
        'Publish to npm (private)',
        'Update app to use published version',
      ],
      validation: [
        'SDK installs correctly',
        'Examples work',
        'Documentation complete',
      ],
      duration: '1-2 days',
    },
  ],
  
  timeline: '8-12 days total',
  
  rollback: 'Keep old auth code on branch until Phase 3 complete',
};
```

### Task Checklist

```markdown
## Extraction Checklist

### Phase 1: Preparation
- [ ] Audit all auth code files
- [ ] Map dependencies (internal/external)
- [ ] Identify circular dependencies
- [ ] Document public API surface
- [ ] Add missing test coverage
- [ ] Create SDK package skeleton
- [ ] Set up tsup/build config
- [ ] Set up vitest/test config

### Phase 2: Extract Core
- [ ] Create src/types.ts with public types
- [ ] Create src/errors.ts with error classes
- [ ] Create src/client.ts with main client
- [ ] Create src/internal/ for private utilities
- [ ] Remove app-specific imports
- [ ] Replace app config with constructor config
- [ ] Add unit tests for all exports
- [ ] Verify build output (ESM/CJS/types)

### Phase 3: Integrate
- [ ] Install SDK in app (file: or link)
- [ ] Update imports file by file
- [ ] Run app tests after each file
- [ ] Update React hooks to wrap SDK
- [ ] Delete old auth code from app
- [ ] Run full test suite

### Phase 4: Publish
- [ ] Write README with examples
- [ ] Add API documentation
- [ ] Create CHANGELOG
- [ ] Configure npm publish
- [ ] Publish to registry
- [ ] Update app to use published package
- [ ] Tag release in git
```

---

## Analysis Report Template

```markdown
# SDK Extraction Analysis: Auth Service

## Overview
- **Source Location:** src/services/auth/
- **Files to Extract:** 8
- **Lines of Code:** ~1,200
- **External Dependencies:** 0
- **Internal Dependencies:** 3 (to resolve)

## Scope

### In Scope (SDK)
| File | Purpose | Status |
|------|---------|--------|
| client.ts | Main auth client | Extract |
| api.ts | API calls | Extract |
| storage.ts | Token storage | Extract |
| types.ts | Public types | Extract |
| errors.ts | Error classes | Extract |

### Out of Scope (App)
| File | Purpose | Reason |
|------|---------|--------|
| useAuth.ts | React hook | Framework-specific |
| AuthContext.tsx | React context | Framework-specific |
| LoginForm.tsx | UI component | App-specific |

## Dependencies

### Must Resolve
- `src/config/index.ts` - Replace with constructor config
- `src/utils/http.ts` - Copy to SDK or make peer dep

### External Packages
- None required (ideal)

## Usage Impact
- **Files Affected:** 23
- **Components:** 8
- **API Routes:** 6
- **Risk Level:** Medium

## Test Coverage
- Current: 72%
- Target: 90%
- Gaps: Error handling, edge cases

## Recommended Timeline
- Preparation: 2-3 days
- Extraction: 3-4 days
- Integration: 2-3 days
- Publishing: 1-2 days
- **Total:** 8-12 days

## Risks
1. Breaking changes to hook API
2. Token migration for existing users
3. Error handling differences

## Mitigation
1. Keep hook API compatible
2. Document migration for tokens
3. Comprehensive error testing
```
