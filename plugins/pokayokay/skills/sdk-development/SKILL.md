---
name: sdk-development
description: Use when building TypeScript SDKs, extracting shared code into packages, creating developer tooling libraries, designing clean API surfaces, or publishing to npm (public or private). Covers typed clients, error handling, multi-target bundling (ESM/CJS/browser).
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
