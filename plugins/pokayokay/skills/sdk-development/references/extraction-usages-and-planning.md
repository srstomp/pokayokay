# Extraction: Usages, Testing, and Planning

Finding all usages, verifying test coverage, and creating a phased extraction plan.

## Step 4: Find All Usages

### Search for Usages

Search for all imports of auth code and usages of specific exports across the codebase using grep.

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

Run coverage for the target code using `vitest run --coverage`.

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
