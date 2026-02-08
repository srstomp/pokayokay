---
name: browser-verification
agents: [yokay-browser-verifier]
description: Automatically verify UI changes in a real browser after implementation. Integrated into the /work workflow — checks visual elements, interactions, and console errors using Playwright. Not a standalone skill.
---

# Browser Verification Skill

Automatically verify UI changes in a real browser after implementation.

## When This Skill Is Used

This skill is triggered during the `/work` workflow after the implementer completes a task that modifies UI-related files. It is NOT a standalone skill - it's integrated into the work loop.

## Purpose

Catch visual and functional issues before code review by testing in a real browser. This prevents:
- CSS issues that look fine in code but break in browser
- JavaScript errors that only appear at runtime
- Responsive/layout issues
- Missing visual elements

## Testability Checks

Browser verification only runs when ALL three conditions are met:

### 1. Browser Tools Available

Must have either:
- Playwright MCP tools (`mcp__plugin_playwright_*`)
- Chrome Extension tools (`mcp__claude-in-chrome__*`)

### 2. Server Running

Must have an HTTP server on a dev port (3000-8999) or ability to start one via package.json scripts.

### 3. Renderable Files Changed

Task must have modified files that affect browser output:
- `.html`, `.css`, `.scss`, `.less`
- `.tsx`, `.jsx`, `.vue`, `.svelte`
- Template files (`.hbs`, `.ejs`, `.pug`)
- Files in `components/`, `views/`, `ui/`, `pages/`

If any condition fails, verification is silently skipped.

## Verification Process

1. **Navigate** to the development server
2. **Screenshot** the initial state
3. **Analyze** the page snapshot for expected elements
4. **Test interactions** if the task involves interactive behavior
5. **Check console** for JavaScript errors
6. **Report** pass/fail with evidence

## Advisory Behavior

This is NOT a hard gate. If verification suggests issues but the user believes the implementation is correct:
- User can provide a reason for skipping
- Skip reason is logged in task notes
- Work continues to spec review with warning flag

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

## Reference Documents

- `references/testability-detection.md` - How to determine if verification should run
- `references/verification-flow.md` - Step-by-step verification process
- `references/configuration.md` - Project-level configuration options

## Integration Point

```
yokay-implementer → browser-verify → yokay-spec-reviewer → yokay-quality-reviewer → complete
```

Browser verification runs AFTER implementation and BEFORE spec review.
