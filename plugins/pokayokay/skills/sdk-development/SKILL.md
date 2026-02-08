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
| [extraction-scope-and-boundaries.md](references/extraction-scope-and-boundaries.md) | Scope identification, dependency analysis, boundary definition |
| [extraction-usages-and-planning.md](references/extraction-usages-and-planning.md) | Finding usages, test coverage, phased extraction plan |
| [package-structure-and-clients.md](references/package-structure-and-clients.md) | SDK layout, client design patterns (single, modular, factory) |
| [configuration-and-api-design.md](references/configuration-and-api-design.md) | Config interfaces, defaults, barrel exports, method signatures |
| [internal-architecture-and-best-practices.md](references/internal-architecture-and-best-practices.md) | HTTP client, state management, tree-shaking, environment agnostic |
| [type-design.md](references/type-design.md) | Strict types, branded types, generics, discriminated unions |
| [error-handling-and-async.md](references/error-handling-and-async.md) | Error class hierarchy, retry logic, request queues, token management |
| [events-storage-and-logging.md](references/events-storage-and-logging.md) | Event emitter, storage abstraction, logger interface |
| [build-tools-and-output.md](references/build-tools-and-output.md) | tsup config, output formats, package.json exports, TypeScript config |
| [bundle-optimization-and-distribution.md](references/bundle-optimization-and-distribution.md) | Bundle size, multi-platform builds, dual packages, monorepo |
| [publishing-and-registries.md](references/publishing-and-registries.md) | npm publishing, private registries, versioning, changelogs |
| [ci-cd-and-documentation.md](references/ci-cd-and-documentation.md) | GitHub Actions, documentation, pre-publish checklist, deprecation |
