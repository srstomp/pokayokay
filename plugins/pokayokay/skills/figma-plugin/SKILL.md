---
name: figma-plugin
description: Create Figma plugins with the Plugin API. Covers plugin architecture (sandbox + UI), node manipulation, styles, components, UI development with postMessage communication, and publishing. Use this skill when building Figma plugins, working with the Figma Plugin API, or creating design automation tools.
---

# Figma Plugin Development

Build plugins that extend Figma's functionality using the Plugin API.

## Architecture

Figma plugins run in two threads communicating via postMessage:
- **Main thread (sandbox)**: Plugin API access, node manipulation, `figma.*` calls
- **UI thread (iframe)**: HTML/CSS/JS interface, no Figma API access, npm packages allowed

## Key Principles

- Main thread handles all Figma document operations
- UI thread handles user interface and external APIs
- Communication between threads via `figma.ui.postMessage()` and `onmessage`
- Plugins must be performant — avoid blocking the main thread

## Quick Start Checklist

1. Set up project with `manifest.json` (name, id, main, ui)
2. Create main thread code (`code.ts`) with plugin logic
3. Create UI (`ui.html`) with interface elements
4. Wire up postMessage communication between threads
5. Test in Figma development mode
6. Publish via Figma Community

## References

| Reference | Description |
|-----------|-------------|
| [project-setup.md](references/project-setup.md) | Manifest, TypeScript setup, build configuration |
| [plugin-api.md](references/plugin-api.md) | Node types, properties, creation, traversal |
| [ui-development.md](references/ui-development.md) | iframe UI, postMessage, Figma design system |
| [common-patterns.md](references/common-patterns.md) | Selection handling, batch operations, undo groups |
