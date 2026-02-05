---
name: sdk-development
description: Create, extract, and publish TypeScript SDKs. Covers analyzing existing applications to extract reusable logic, designing clean SDK APIs, implementing typed clients with proper error handling, bundling for multiple targets (ESM/CJS/browser), and publishing to npm (public or private registries). Use this skill when building SDKs, extracting shared code into packages, or creating developer tooling libraries.
---

# SDK Development

Create professional TypeScript SDKs from scratch or by extraction.

## Key Principles

- **Clean public API** — Export only what consumers need, hide internals
- **Type everything** — Full type coverage for config, methods, responses, and errors
- **Meaningful errors** — Typed error classes with codes and context
- **Sensible defaults** — Works out of the box with minimal config
- **Framework agnostic** — Core SDK has no framework dependencies; add bindings separately

## Quick Start Checklist

1. Analyze scope: new SDK or extraction from existing app
2. Design public API surface (exports, types, config)
3. Implement client with typed methods and error handling
4. Configure build for ESM/CJS/types (tsup recommended)
5. Write tests (unit + integration) and examples
6. Publish to npm with proper package.json exports field

## References

| Reference | Description |
|-----------|-------------|
| [extraction-analysis.md](references/extraction-analysis.md) | Analyzing code, finding boundaries, planning extraction |
| [sdk-architecture.md](references/sdk-architecture.md) | SDK structure, patterns, API design |
| [implementation.md](references/implementation.md) | TypeScript patterns, types, error handling |
| [building-bundling.md](references/building-bundling.md) | Build tools, formats, tree-shaking |
| [publishing.md](references/publishing.md) | npm publishing, private registries, versioning, CI/CD |
