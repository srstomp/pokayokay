---
description: Create distinctive, production-quality visual designs
argument-hint: <task-description>
skill: aesthetic-ui-designer
---

# Visual Design Workflow

Create visual design for: `$ARGUMENTS`

## Prerequisites
Run `/pokayokay:ux` first to establish structure and flows.

## Steps

### 1. Establish Design System
- Typography scale
- Color palette
- Spacing system
- Component patterns

### 2. Apply Visual Treatment
- Typography selection and pairing
- Color application
- Iconography
- Imagery guidelines

### 3. Add Polish
- Micro-interactions
- Motion and animation
- Loading states
- Empty states

### 4. Avoid "AI Slop"
- No generic gradient backgrounds
- Meaningful color choices
- Intentional whitespace
- Distinctive personality

### 5. Document
- Design tokens
- Component specifications
- Usage guidelines

### 6. Create Tasks
```bash
npx @stevestomp/ohno-cli create "Style [component]" -t feature
```

## Covers
- Typography selection and pairing
- Color strategy and palettes
- Spacing systems and layout
- Icon selection and consistency
- Motion and animation
- Avoiding generic aesthetics

## Related Commands

- `/yokay:ux` - UX design (prerequisite)
- `/yokay:audit --dimension accessibility` - Accessibility audit after implementation
- `/yokay:work` - Implement visual components

## Skill Integration

When UI design involves:
- **Accessibility concerns** → Also load `accessibility-auditor` skill
- **Component testing** → Also load `testing-strategy` skill
- **Performance concerns** → Consider performance-critical patterns
