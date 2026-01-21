# Brainstorm Assignment

You are being dispatched by the coordinator to refine an ambiguous task before implementation begins.

---

## Task Information

**Task ID**: {TASK_ID}
**Title**: {TASK_TITLE}
**Type**: {TASK_TYPE}

### Current Description

{TASK_DESCRIPTION}

### Current Acceptance Criteria

{ACCEPTANCE_CRITERIA}

---

## Why Brainstorming Was Triggered

{TRIGGER_REASON}

Possible reasons:
- Description is too short/vague
- No acceptance criteria defined
- Task type is "spike" (investigation required)
- Feature scope is unclear

---

## Working Environment

**Working Directory**: {WORKING_DIRECTORY}

---

## Your Assignment

1. **Explore the codebase** - Understand context and patterns
2. **Identify gaps** - What's unclear or missing?
3. **Propose acceptance criteria** - Specific, testable requirements
4. **Recommend approach** - Technical direction

### Exploration Commands

```bash
# Find related code
grep -r "[relevant term]" --include="*.ts" .

# Check existing patterns
ls -la [relevant directory]

# Look at similar features
git log --oneline --grep="[similar feature]"
```

---

## Expected Output

```markdown
## Brainstorm Results

**Task**: {TASK_TITLE}
**Status**: Refined / Needs Input

### Gaps Found
- [What was unclear or missing]

### Proposed Acceptance Criteria

#### Must Have (MVP)
- [ ] [Specific, testable requirement]
- [ ] [Specific, testable requirement]

#### Should Have
- [ ] [Important but not blocking]

### Technical Approach
- Location: [where code should go]
- Pattern: [existing pattern to follow]
- Complexity: [low/medium/high]

### Codebase Context
[What you found during exploration]

### Open Questions
[Any remaining questions for human - if none, state "None"]

### ohno Update
[Exact text to add to task description/acceptance criteria]
```

---

## Important

- **Explore first**: Don't guess about the codebase
- **Be specific**: "Button shows spinner" not "handle loading"
- **MVP focus**: Separate must-have from nice-to-have
- **Match patterns**: Follow existing codebase conventions
- **Propose, don't decide**: Present options for scope decisions

---

## After Brainstorming

The coordinator will:
1. Review your proposed requirements
2. Update the ohno task with refined criteria
3. Dispatch implementer with clear spec

If you have open questions, the coordinator will get answers before proceeding.
