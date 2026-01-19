---
description: Create user personas and journey maps
argument-hint: <persona-task>
skill: persona-creation
---

# Persona Creation Workflow

Create personas for: `$ARGUMENTS`

## Steps

### 1. Identify Persona Type
From `$ARGUMENTS`, determine:
- **Proto-persona**: Quick, assumption-based
- **Full persona**: Research-backed, detailed
- **JTBD**: Jobs-to-be-done focused
- **Journey map**: Experience mapping

### 2. Gather Input Data
Sources to consider:
- User interviews
- Analytics data
- Support tickets
- Sales feedback
- Existing research

### 3. Create Persona

**Proto-Persona Template:**
```markdown
## [Name]
**Role**: [Job title/description]
**Goals**: [What they want to achieve]
**Pain Points**: [Current frustrations]
**Tech Comfort**: [Low/Medium/High]
```

**Full Persona Template:**
```markdown
## [Name] - [Archetype]

### Demographics
- Age: [range]
- Role: [title]
- Industry: [sector]

### Goals
1. [Primary goal]
2. [Secondary goal]

### Pain Points
1. [Major frustration]
2. [Minor annoyance]

### Behaviors
- [How they work]
- [Tools they use]

### Quote
"[Representative quote]"
```

**JTBD Template:**
```markdown
## Job: [Job statement]

### When...
[Situation/trigger]

### I want to...
[Motivation/action]

### So I can...
[Expected outcome]

### Constraints
- [Limitation 1]
- [Limitation 2]
```

### 4. Create Journey Map (if needed)
```markdown
## Journey: [Journey name]

| Stage | Actions | Thoughts | Emotions | Opportunities |
|-------|---------|----------|----------|---------------|
| Awareness | | | | |
| Consideration | | | | |
| Decision | | | | |
| Onboarding | | | | |
| Usage | | | | |
```

### 5. Save Artifacts
Create `.claude/personas/[name].md`

### 6. Create Follow-up Tasks
```bash
npx @stevestomp/ohno-cli create "UX: Design for [persona]" -t feature
```

## Covers
- Proto-persona creation
- Full persona research
- Jobs-to-be-done analysis
- Journey mapping
- Empathy mapping
- User segmentation

## Related Commands

- `/pokayokay:ux` - Design for personas
- `/pokayokay:research` - Deep user research
- `/pokayokay:work` - Implement persona-driven features

## Skill Integration

When persona work involves:
- **UX design** → Also load `ux-design` skill
- **Research** → Also load `deep-research` skill
