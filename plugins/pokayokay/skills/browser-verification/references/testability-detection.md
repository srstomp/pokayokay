# Testability Detection

Determines whether browser verification should run for a given task. All three checks must pass.

## Check 1: Browser Tools Available

Look for MCP tools that enable browser automation:

**Playwright MCP tools:**
- `mcp__plugin_playwright_playwright__browser_navigate`
- `mcp__plugin_playwright_playwright__browser_snapshot`
- `mcp__plugin_playwright_playwright__browser_take_screenshot`
- `mcp__plugin_playwright_playwright__browser_click`

**Chrome Extension tools:**
- `mcp__claude-in-chrome__*`

**Detection:** Check if any of these tools are available in the current session. If neither Playwright nor Chrome extension tools exist, silent skip.

## Check 2: Server Running or Startable

Scan for active HTTP servers on common development ports.

### Port Detection Command

```bash
lsof -i -P | grep LISTEN | grep -E ':(3[0-9]{3}|4[0-9]{3}|5[0-9]{3}|8[0-9]{3})'
```

### Port Ranges

| Range | Common Uses |
|-------|-------------|
| 3000-3999 | React, Next.js, Node.js |
| 4000-4999 | Various frameworks |
| 5000-5999 | Vite, Flask |
| 8000-8999 | Python, Node.js |

### If No Server Running

1. Check `package.json` for scripts:
   - `serve`
   - `dev`
   - `start`

2. Offer to start the server if script exists

3. If no scripts found, silent skip

### Multiple Servers

If multiple servers found:
1. Check project context (which directory is being worked on)
2. Prompt user to select if ambiguous

## Check 3: Task Changed Renderable Files

Check if the task modified files that affect browser output.

### File Extensions

| Extension | Type |
|-----------|------|
| `.html` | HTML |
| `.css`, `.scss`, `.less` | Styles |
| `.tsx`, `.jsx` | React components |
| `.vue` | Vue components |
| `.svelte` | Svelte components |
| `.hbs`, `.ejs`, `.pug` | Templates |

### Path Patterns

- `components/`
- `views/`
- `ui/`
- `pages/`
- `src/components/`
- `src/views/`
- `src/ui/`
- `src/pages/`

### Getting Changed Files

From task activity or git:
```bash
git diff --name-only HEAD~1
```

Or from implementer's report (files changed section).

## Decision Matrix

| Browser Tools | Server | Renderable Files | Result |
|--------------|--------|------------------|--------|
| No | - | - | Skip (no capability) |
| Yes | No | - | Skip (nothing to test against) |
| Yes | Yes | No | Skip (no UI changes) |
| Yes | Yes | Yes | **Verify** |

## Output Format

```typescript
interface TestabilityResult {
  canTest: boolean;
  reason?: string;  // If cannot test
  server?: {
    url: string;
    port: number;
  };
  files?: string[];  // Changed renderable files
  browserTool: 'playwright' | 'chrome' | null;
}
```

## Configuration Override

Check `.pokayokay.json` for custom settings:

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

If `enabled: false`, always skip regardless of other checks.
