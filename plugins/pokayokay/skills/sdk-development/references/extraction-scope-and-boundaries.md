# Extraction: Scope and Boundaries

Analyzing existing code to plan SDK extraction: scope identification, dependency analysis, and boundary definition.

## Analysis Process

```
┌─────────────────────────────────────────────────────────────┐
│                    ANALYSIS PROCESS                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  1. SCOPE              2. DEPENDENCIES       3. BOUNDARIES  │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐ │
│  │ What code?  │  ->  │ Internal    │  ->  │ What's in?  │ │
│  │ What files? │      │ External    │      │ What's out? │ │
│  │ What funcs? │      │ Circular?   │      │ Interface?  │ │
│  └─────────────┘      └─────────────┘      └─────────────┘ │
│                                                             │
│  4. USAGES             5. TESTS            6. PLAN          │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐ │
│  │ Who calls?  │  ->  │ Coverage?   │  ->  │ Order       │ │
│  │ How used?   │      │ Add tests?  │      │ Phases      │ │
│  │ Patterns?   │      │ Behavior?   │      │ Timeline    │ │
│  └─────────────┘      └─────────────┘      └─────────────┘ │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Step 1: Identify Scope

### Find Candidate Code

Use `find` and `grep` to locate relevant files:
- Search for auth-related code across `src/`
- List files in suspected directories like `src/services/auth`, `src/lib/auth`, `src/utils/auth`

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

Search for imports from within the app using grep on `src/services/auth/`.

```typescript
// Example dependency map
const internalDeps = {
  'src/services/auth/client.ts': [
    'src/services/auth/api.ts',      // Will be in SDK
    'src/services/auth/storage.ts',  // Will be in SDK
    'src/types/auth.ts',             // Will be in SDK
    'src/utils/http.ts',             // Shared utility
    'src/config/index.ts',           // App config - must remove
  ],

  'src/services/auth/api.ts': [
    'src/utils/http.ts',             // Shared utility
    'src/types/auth.ts',             // Will be in SDK
  ],
};
```

### External Dependencies

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

Use `npx madge --circular` to check for circular dependencies.

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
