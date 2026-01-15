---
name: accessibility-auditor
description: Analyzes web and mobile applications for WCAG 2.2 AA accessibility compliance. Audits code (HTML, React, React Native, SwiftUI), interprets automated tool output, and processes manual tester findings. Produces structured audit reports that implementation agents can action. Use this skill when conducting accessibility audits, reviewing code for a11y issues, or synthesizing accessibility test results.
---

# Accessibility Auditor

Analyze applications for WCAG 2.2 AA compliance and produce actionable audit reports.

## Audit Workflow

```
┌─────────────────────────────────────────────────────────────┐
│                        INPUTS                               │
├─────────────────┬─────────────────┬─────────────────────────┤
│ Code            │ Tool Output     │ Tester Findings         │
│ (HTML, React,   │ (axe, Light-    │ (manual testing         │
│ RN, SwiftUI)    │ house, etc.)    │ reports)                │
└────────┬────────┴────────┬────────┴────────┬────────────────┘
         │                 │                 │
         └─────────────────┼─────────────────┘
                           ▼
              ┌────────────────────────┐
              │   ANALYSIS PROCESS     │
              │  • Map to WCAG 2.2 AA  │
              │  • Classify severity   │
              │  • Identify patterns   │
              │  • Note remediation    │
              └───────────┬────────────┘
                          ▼
              ┌────────────────────────┐
              │     AUDIT REPORT       │
              │  Structured for        │
              │  implementation agent  │
              └────────────────────────┘
```

## WCAG 2.2 AA Quick Reference

### The Four Principles (POUR)

| Principle | Meaning | Key Questions |
|-----------|---------|---------------|
| **Perceivable** | Users can perceive content | Can everyone see/hear/read it? |
| **Operable** | Users can interact | Can everyone navigate and use controls? |
| **Understandable** | Users can comprehend | Is content and UI predictable and clear? |
| **Robust** | Works with assistive tech | Does it work with screen readers, etc.? |

### Compliance Levels

- **A**: Minimum (basic access)
- **AA**: Standard (legal requirement in most jurisdictions) ← **Target**
- **AAA**: Enhanced (not typically required)

## Severity Classification

Use this scale for all findings:

| Severity | Definition | Example | Priority |
|----------|------------|---------|----------|
| **Critical** | Blocks access entirely | No keyboard navigation, missing alt text on key images | P0 — Fix immediately |
| **Serious** | Major barrier, workaround difficult | Poor contrast, form errors not announced | P1 — Fix before release |
| **Moderate** | Barrier exists, workaround possible | Focus order confusing, missing skip links | P2 — Fix soon |
| **Minor** | Inconvenience, not a barrier | Redundant alt text, minor heading hierarchy issues | P3 — Fix when able |

### Severity Decision Tree

```
Can the user complete the task?
├── No → Is there a workaround?
│        ├── No → CRITICAL
│        └── Yes, but difficult → SERIOUS
└── Yes → Is the experience degraded?
          ├── Significantly → MODERATE
          └── Slightly → MINOR
```

## Audit Report Template

Use this structure for all audit reports:

```markdown
# Accessibility Audit Report

## Summary
| Metric | Count |
|--------|-------|
| Critical | X |
| Serious | X |
| Moderate | X |
| Minor | X |
| **Total Issues** | X |

**Overall Assessment**: [Pass / Fail / Conditional Pass]
**WCAG Version**: 2.2 AA
**Platform**: [Web / iOS / Android / React Native]
**Audit Date**: [Date]
**Auditor**: [Agent/Human]

## Critical Issues

### [Issue ID]: [Brief Title]
- **WCAG Criterion**: [X.X.X Name]
- **Severity**: Critical
- **Location**: [File/Component/Screen]
- **Description**: [What's wrong]
- **Impact**: [Who is affected and how]
- **Code Sample** (if applicable):
  ```
  [Problematic code]
  ```
- **Remediation**: [How to fix]
- **Remediation Code** (if applicable):
  ```
  [Fixed code]
  ```

[Repeat for each critical issue]

## Serious Issues
[Same structure]

## Moderate Issues
[Same structure]

## Minor Issues
[Same structure]

## Passed Criteria
[List WCAG criteria that were checked and passed]

## Out of Scope
[Anything not tested and why]

## Recommendations
[Overall recommendations beyond specific fixes]

## Testing Methodology
- **Automated Tools**: [List tools used]
- **Manual Testing**: [Describe manual checks]
- **Assistive Tech Tested**: [Screen readers, etc.]
```

## Analysis Process

### Step 1: Identify Input Type

| Input | Analysis Approach |
|-------|-------------------|
| Code | Static analysis against WCAG criteria |
| Automated tool output | Map findings to WCAG, verify, remove false positives |
| Tester findings | Standardize format, map to WCAG, classify severity |
| Mixed | Synthesize all sources, deduplicate |

### Step 2: Map to WCAG 2.2 AA

Every finding must map to a specific WCAG criterion:
- Reference: [references/wcag-22-aa.md](references/wcag-22-aa.md)

If a finding doesn't map to WCAG AA, classify as:
- Best Practice (not WCAG, but recommended)
- AAA (beyond AA requirement)
- Platform-Specific (HIG, Material guidelines)

### Step 3: Classify Severity

Use the severity definitions above. Be consistent:
- Same issue type = same severity across report
- Document reasoning for edge cases

### Step 4: Identify Patterns

Look for systemic issues:
- Same problem across multiple components
- Root cause analysis (e.g., missing design system support)
- Note in recommendations section

### Step 5: Specify Remediation

Every issue needs actionable remediation:
- Specific enough for implementation agent to execute
- Include code samples when analyzing code
- Reference platform-specific solutions

## Code Analysis Checklist

Quick checklist for code review. Details in [references/code-analysis.md](references/code-analysis.md).

### HTML/React/Web

- [ ] Images have meaningful alt text (or empty for decorative)
- [ ] Form inputs have associated labels
- [ ] Heading hierarchy is logical (h1 → h2 → h3)
- [ ] Color contrast meets 4.5:1 (text) / 3:1 (large text, UI)
- [ ] Focus is visible and logical
- [ ] Interactive elements are keyboard accessible
- [ ] ARIA used correctly (or native HTML preferred)
- [ ] Skip link present
- [ ] Language declared
- [ ] Error messages associated with inputs

### React Native

- [ ] accessibilityLabel on touchables/images
- [ ] accessibilityRole set correctly
- [ ] accessibilityHint for non-obvious actions
- [ ] accessibilityState for toggles/selections
- [ ] Focus order logical
- [ ] Touch targets ≥44pt
- [ ] Announcements for dynamic content

### SwiftUI / iOS

- [ ] accessibilityLabel on custom views
- [ ] accessibilityValue for state
- [ ] accessibilityHint for actions
- [ ] accessibilityElement(children:) grouping
- [ ] VoiceOver navigation order
- [ ] Dynamic Type support
- [ ] Sufficient contrast

## Interpreting Tool Output

### Common Tools

| Tool | Strength | Limitation |
|------|----------|------------|
| axe | Comprehensive, low false positives | Can't test keyboard nav, focus order |
| Lighthouse | Quick overview, integrated | Less detailed than axe |
| WAVE | Visual overlay helpful | Can be noisy |
| Accessibility Inspector (iOS) | Native iOS testing | Manual process |
| Android Accessibility Scanner | Native Android testing | Limited depth |

### Tool Output Processing

1. **Import findings** from tool
2. **Remove false positives** (verify each finding)
3. **Map to WCAG criterion** (tools don't always specify)
4. **Classify severity** (tool severity often inaccurate)
5. **Add context** (location, impact, remediation)
6. **Deduplicate** (same issue across pages/components)

## Processing Tester Findings

Manual tester reports may need standardization:

1. **Normalize format** to audit report structure
2. **Map to WCAG** if tester didn't specify
3. **Classify severity** using consistent scale
4. **Add technical detail** if tester provided only description
5. **Verify reproducibility** if unclear
6. **Request clarification** if finding is ambiguous

See [references/tester-findings.md](references/tester-findings.md) for interpretation guide.

---

**References:**
- [references/wcag-22-aa.md](references/wcag-22-aa.md) — Full WCAG 2.2 AA criteria for auditing
- [references/code-analysis.md](references/code-analysis.md) — Platform-specific code analysis patterns
- [references/common-issues.md](references/common-issues.md) — Frequently found issues with quick fixes
- [references/tester-findings.md](references/tester-findings.md) — Interpreting manual test results
