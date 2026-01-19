---
description: Create or extract TypeScript SDK
argument-hint: <sdk-task>
skill: sdk-development
---

# SDK Development Workflow

SDK task: `$ARGUMENTS`

## Steps

### 1. Identify SDK Task Type
From `$ARGUMENTS`, determine:
- **Create**: Build new SDK for existing API
- **Extract**: Pull reusable code into SDK
- **Publish**: Release SDK to npm
- **Update**: Add features or fix issues

### 2. Design SDK Architecture

**For Creation:**
- Analyze API endpoints
- Design client interface
- Plan type definitions
- Choose HTTP client (fetch, axios)

**For Extraction:**
- Identify reusable code
- Define public API surface
- Plan breaking changes
- Design migration path

### 3. Implement SDK

**Package Structure:**
```
sdk/
├── src/
│   ├── index.ts         # Public exports
│   ├── client.ts        # API client
│   ├── types.ts         # TypeScript types
│   └── errors.ts        # Custom errors
├── package.json
├── tsconfig.json
└── README.md
```

**Key Features:**
- Full TypeScript types
- ESM and CJS builds
- Tree-shakeable exports
- Proper error handling
- Request/response interceptors

### 4. Build Configuration
```json
{
  "main": "./dist/index.cjs",
  "module": "./dist/index.js",
  "types": "./dist/index.d.ts",
  "exports": {
    ".": {
      "import": "./dist/index.js",
      "require": "./dist/index.cjs",
      "types": "./dist/index.d.ts"
    }
  }
}
```

### 5. Documentation
- Installation instructions
- Quick start example
- API reference
- Error handling guide

### 6. Create Implementation Tasks
```bash
npx @stevestomp/ohno-cli create "SDK: [specific task]" -t feature
```

## Covers
- SDK architecture design
- TypeScript configuration
- Build setup (ESM/CJS)
- Type definitions
- Error handling patterns
- Documentation generation
- npm publishing

## Related Commands

- `/pokayokay:api` - Design underlying API
- `/pokayokay:docs` - SDK documentation
- `/pokayokay:test` - SDK testing strategy
- `/pokayokay:work` - Implement SDK

## Skill Integration

When SDK work involves:
- **API design** → Also load `api-design` skill
- **Documentation** → Also load `documentation` skill
- **Testing** → Also load `testing-strategy` skill
