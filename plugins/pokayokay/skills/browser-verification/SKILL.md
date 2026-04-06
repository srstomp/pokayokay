---
name: browser-verification
agents: [yokay-browser-verifier]
description: "Navigates to the dev server, takes screenshots, checks for visual regressions, tests interactions, and detects console errors using Playwright MCP tools. Use when verifying UI changes in a browser, running visual checks after frontend implementation, performing e2e verification, or checking for JavaScript console errors. Integrated into the /work workflow — not a standalone skill."
---

# Browser Verification Skill

Automatically verify UI changes in a real browser after implementation.

## When This Skill Is Used

Triggered during the `/work` workflow after the implementer completes a task that modifies UI-related files. Not a standalone skill — integrated into the work loop.

## Testability Checks

Browser verification only runs when ALL three conditions are met:

### 1. Browser Tools Available

Must have either:
- Playwright MCP tools (`mcp__plugin_playwright_*`)
- Chrome Extension tools (`mcp__claude-in-chrome__*`)

### 2. Server Running

Check for an HTTP server on a dev port (3000-8999):
```bash
lsof -iTCP:3000-8999 -sTCP:LISTEN -P -n | head -5
```
If none found, start one via `npm run dev` or the project's start script.

### 3. Renderable Files Changed

Task must have modified files that affect browser output:
- `.html`, `.css`, `.scss`, `.less`, `.tsx`, `.jsx`, `.vue`, `.svelte`
- Template files (`.hbs`, `.ejs`, `.pug`)
- Files in `components/`, `views/`, `ui/`, `pages/`

If any condition fails, verification is silently skipped.

## Verification Process

1. **Navigate** to the dev server:
   `mcp__plugin_playwright_navigate({url: 'http://localhost:3000'})`
2. **Screenshot** the initial state:
   `mcp__plugin_playwright_screenshot()`
3. **Analyze** the snapshot for expected elements from the task acceptance criteria.
4. **Test interactions** if the task involves interactive behavior (click, type, hover).
5. **Check console** for JavaScript errors:
   `mcp__plugin_playwright_evaluate({script: 'window.__console_errors || []'})`
6. **Report** pass/fail with evidence (screenshots, error logs).
7. **If issues found**: document specific failures → implementer can fix → re-verify. If user deems implementation correct, skip reason is logged in task notes and work continues with a warning flag.

## Configuration

Projects can customize in `.pokayokay.json`:

```json
{
  "browserVerification": {
    "enabled": true,
    "portRange": [3000, 9999],
    "additionalPaths": ["src/templates/"],
    "excludePaths": ["src/email-templates/"]
  }
}
```

## Integration Point

```
yokay-implementer → browser-verify → yokay-spec-reviewer → yokay-quality-reviewer → complete
```

## References

| Reference | Description |
|-----------|-------------|
| [testability-detection.md](references/testability-detection.md) | How to determine if verification should run |
| [verification-flow.md](references/verification-flow.md) | Step-by-step verification process |
| [configuration.md](references/configuration.md) | Project-level configuration options |
