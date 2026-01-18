---
description: Start a time-boxed technical investigation
argument-hint: <spike-question>
skill: spike
---

# Spike Investigation Workflow

Investigate: `$ARGUMENTS`

## Spike Discipline

Spikes answer questions, they don't build features.

**Good spike questions:**
- "Can we integrate with X API?"
- "Is Y library suitable for our use case?"
- "What's the best approach for Z?"

**Bad spike questions:**
- "Build authentication" (that's a feature)
- "Investigate the codebase" (too vague)
- "Make it faster" (needs specific question)

## Steps

### 1. Clarify the Question
Reframe `$ARGUMENTS` as a specific, answerable question.

If vague, ask:
- What decision does this inform?
- What would a "yes" answer look like?
- What would a "no" answer look like?

### 2. Set Time Box
| Duration | Use Case |
|----------|----------|
| 1h | Quick feasibility check |
| 2h | Standard investigation (default) |
| 4h | Complex evaluation |
| 8h | Deep dive (requires justification) |

### 3. Create Spike Task
```bash
npx @stevestomp/ohno-cli create "Spike: $QUESTION" -t spike
npx @stevestomp/ohno-cli start <task-id>
```

### 4. Define Success Criteria
Before starting, document:
```markdown
## Spike: [Question]
**Time Box**: [hours]
**Started**: [timestamp]
**Must Conclude By**: [timestamp + time-box]

### Success Criteria
- [ ] [Specific criterion 1]
- [ ] [Specific criterion 2]
```

### 5. Investigate
Focus on answering the question:
- Research (docs, examples, community)
- Proof-of-concept code (if needed)
- Document findings as you go

### 6. Checkpoint at 50%
At half time, assess:
```markdown
## Spike Checkpoint (50%)
**Progress**: [summary of findings so far]
**On Track?**: Yes / No / Pivoting
**Remaining Time**: [hours]
```

If off track:
- Should we narrow scope?
- Is more time needed? (requires justification)

### 7. Conclude with Decision
Even if time runs out, produce decision:

| Decision | Meaning | Next Step |
|----------|---------|-----------|
| GO | Feasible, proceed | Create implementation tasks |
| NO-GO | Not feasible | Document why, close spike |
| PIVOT | New question | Create new spike task |
| MORE-INFO | Insufficient data | One follow-up spike max |

### 8. Generate Spike Report
Create `.claude/spikes/[date]-[slug].md`:

```markdown
# Spike: [Question]

**Date**: [date]
**Time spent**: [hours]
**Decision**: [GO/NO-GO/PIVOT/MORE-INFO]

## Question
[The specific question investigated]

## Answer
[Clear answer with rationale]

## Findings
[Key discoveries]

## Evidence
[Code samples, links, screenshots]

## Recommendation
[What to do next]

## Follow-up
- [ ] [Action item 1]
- [ ] [Action item 2]
```

### 9. Create Follow-up Tasks
If decision is GO:
```bash
npx @stevestomp/ohno-cli create "[implementation task]" -t feature
```

### 10. Complete Spike
```bash
npx @stevestomp/ohno-cli done <task-id> --notes "Decision: X. See .claude/spikes/[file]"
```

## Output

```markdown
## Spike Complete

**Question**: [question]
**Answer**: [GO/NO-GO/PIVOT/MORE-INFO]
**Time**: [actual] / [budgeted]
**Report**: .claude/spikes/[file].md

### Summary
[2-3 sentence summary]

### Next Steps
[Follow-up tasks created, or "No action needed"]
```

## Related Commands

- `/yokay:research` - Longer multi-day research
- `/yokay:work` - Implement spike findings
- `/yokay:quick` - Non-investigative quick work

## Examples

```
/yokay:spike Can we use Clerk for authentication?
/yokay:spike What's the best state management for our React app?
/yokay:spike Is our current architecture suitable for real-time features?
```
