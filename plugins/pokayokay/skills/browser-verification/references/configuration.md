# Browser Verification Configuration

Configure browser verification behavior per-project.

## Configuration File

Create `.yokay/browser-verification.yaml` in your project root:

```yaml
# Browser Verification Configuration
# Place in .yokay/browser-verification.yaml

# Enable/disable browser verification
enabled: true

# Server detection settings
server:
  # Port range to scan for running servers
  portRange:
    min: 3000
    max: 9999

  # Preferred port (check this first)
  preferredPort: 3000

  # Auto-start server if not running
  autoStart: true

  # npm script to run if autoStart is true
  startScript: dev

# File detection settings
files:
  # Additional file extensions to consider as renderable
  additionalExtensions:
    - .njk  # Nunjucks templates
    - .twig # Twig templates

  # Additional paths to monitor (beyond defaults)
  additionalPaths:
    - src/templates/
    - src/layouts/

  # Paths to exclude from detection
  excludePaths:
    - src/email-templates/
    - src/pdf-templates/

# Screenshot storage
screenshots:
  # Where to store screenshots (relative to project root)
  directory: .ohno/screenshots

  # Screenshot format
  format: png  # or 'jpeg'

  # Include timestamp in filename
  includeTimestamp: true

# Behavior settings
behavior:
  # Advisory mode (allow skip with reason)
  advisory: true

  # Maximum time to wait for page load (seconds)
  pageLoadTimeout: 30

  # Check console for errors
  checkConsoleErrors: true

  # Take screenshot on failure
  screenshotOnFailure: true
```

## Minimal Configuration

For most projects, you only need to override what differs from defaults:

```yaml
# .yokay/browser-verification.yaml
enabled: true
server:
  preferredPort: 5173  # Vite default
```

## Disable Verification

```yaml
# .yokay/browser-verification.yaml
enabled: false
```

## Default Values

| Setting | Default |
|---------|---------|
| enabled | true |
| server.portRange.min | 3000 |
| server.portRange.max | 9999 |
| server.autoStart | true |
| server.startScript | dev |
| files.additionalExtensions | [] |
| files.additionalPaths | [] |
| files.excludePaths | [] |
| screenshots.directory | .ohno/screenshots |
| screenshots.format | png |
| behavior.advisory | true |
| behavior.pageLoadTimeout | 30 |
| behavior.checkConsoleErrors | true |

## Default File Patterns

These file patterns are always checked (unless excluded):

### Extensions
- `.html`
- `.css`, `.scss`, `.less`
- `.tsx`, `.jsx`
- `.vue`
- `.svelte`
- `.hbs`, `.ejs`, `.pug`

### Paths
- `components/`
- `views/`
- `ui/`
- `pages/`
- `src/components/`
- `src/views/`
- `src/ui/`
- `src/pages/`

## Environment Variables

Override configuration via environment:

```bash
# Disable verification for this session
YOKAY_BROWSER_VERIFY=false

# Override port
YOKAY_BROWSER_PORT=4000
```

## Per-Task Override

Add to task description to skip verification:

```
[skip-browser-verify]
```

This is useful for tasks where browser verification doesn't apply despite matching file patterns (e.g., server-side rendered content that needs a full deploy).
