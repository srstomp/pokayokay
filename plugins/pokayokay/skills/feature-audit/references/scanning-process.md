# Scanning Process

## Backend Scan

Find evidence of implementation:

```bash
# Services
find backend/src/services -name "*.ts" | head -20
grep -l "export.*class\|export.*function" backend/src/services/*.ts

# API routes/handlers
find . -path "*/api/*" -name "*.ts" | head -20
find . -path "*/handlers/*" -name "*.ts" | head -20

# Database models/schema
find . -name "schema.ts" -o -name "models.ts" -o -name "*.model.ts"
```

## Frontend Scan

Find UI implementation:

```bash
# Routes/pages (framework-dependent)
find . -path "*/pages/*" -name "*.tsx" 2>/dev/null
find . -path "*/app/*" -name "page.tsx" 2>/dev/null
find . -path "*/screens/*" -name "*.tsx" 2>/dev/null
find . -path "*/routes/*" -name "*.tsx" 2>/dev/null

# Components
find . -path "*/components/*" -name "*.tsx" | grep -i "FEATURE_NAME"

# Navigation
grep -r "href=\|to=\|navigate\|Link" --include="*.tsx" src/components/nav/
```

## API Integration Scan

Verify frontend calls backend:

```bash
# Find API calls
grep -r "fetch\|axios\|useMutation\|useQuery" --include="*.tsx" src/

# Find service imports
grep -r "import.*from.*services\|import.*from.*api" --include="*.tsx" src/
```

## Navigation Scan

Check if feature is reachable:

```bash
# Find navigation components
find . -name "*nav*" -o -name "*sidebar*" -o -name "*menu*" | grep -E "\.(tsx|jsx)$"

# Check for links to feature
grep -r "/FEATURE_ROUTE" --include="*.tsx" src/
```

## Audit Output

### Report Structure

See [remediation-templates.md](remediation-templates.md) for task creation patterns.

### JSON Output Format

```json
{
  "audit_date": "2026-01-12",
  "project": "VoiceForm AI",
  "framework": { "frontend": "nextjs-app", "backend": "separate", "mobile": null },
  "summary": {
    "total_features": 30,
    "by_level": {
      "L5_complete": 12, "L4_accessible": 5, "L3_routable": 3,
      "L2_frontend_exists": 2, "L1_backend_only": 8, "L0_not_started": 0
    }
  },
  "features": [
    {
      "id": "F028", "title": "Analytics API", "level": 1, "level_name": "backend_only",
      "evidence": {
        "backend": { "found": true, "files": ["backend/src/services/analytics-api.ts"] },
        "frontend": { "found": false, "files": [] },
        "route": { "found": false, "path": null },
        "navigation": { "found": false, "location": null }
      },
      "remediation": [
        { "type": "create_route", "description": "Create analytics page", "path": "app/analytics/page.tsx" },
        { "type": "add_navigation", "description": "Add Analytics to sidebar" }
      ]
    }
  ]
}
```
