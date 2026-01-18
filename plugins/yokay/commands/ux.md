---
description: UX design for user flows, wireframes, and interactions
argument-hint: <task-description>
skill: ux-design
---

# UX Design Workflow

Design user experience for: `$ARGUMENTS`

## Steps

### 1. Understand Users
- Who are the users?
- What are their goals?
- What's their context (desktop, mobile, etc.)?

### 2. Map Information Architecture
- Content hierarchy
- Navigation structure
- Page relationships

### 3. Design User Flows
- Entry points
- Key paths
- Edge cases and errors

### 4. Create Wireframes
- Layout structure
- Component placement
- Interaction patterns

### 5. Document Decisions
- Rationale for choices
- Accessibility considerations
- Responsive behavior

### 6. Create Tasks
```bash
npx @stevestomp/ohno-cli create "Implement [flow/component]" -t feature
```

## Covers
- Information architecture
- Navigation patterns
- User flows and wireframes
- Form design and validation
- Feedback states and loading
- Mobile and responsive design
- Accessibility (WCAG)

## Related Commands

- `/yokay:ui` - Visual design after UX (recommended next step)
- `/yokay:api` - API design for backend needs
- `/yokay:audit` - Feature completeness check
- `/yokay:work` - Implement designed flows

## Skill Integration

When UX design involves:
- **Accessibility requirements** → Also load `accessibility-auditor` skill
- **User research needed** → Also load `persona-creation` skill
- **Performance concerns** → Create spike task first
