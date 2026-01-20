---
description: Conduct comprehensive research for major decisions
argument-hint: <research-topic>
skill: deep-research
---

# Deep Research Workflow

Research: `$ARGUMENTS`

## When to Use

Use `/pokayokay:research` for **multi-day** investigations:
- Technology evaluation
- Competitive analysis
- Architecture exploration
- Vendor selection

For quick (2-4 hour) investigations, use `/pokayokay:spike` instead.

## Steps

### 1. Scope the Research
Define clearly:
- **Primary question**: What decision does this inform?
- **Criteria**: How will we evaluate options?
- **Constraints**: Budget, timeline, team skills
- **Stakeholders**: Who needs the output?

### 2. Create Research Task
```bash
npx @stevestomp/ohno-cli create "Research: $TOPIC" -t research
```

### 3. Gather Sources
- Official documentation
- Community resources (GitHub, Stack Overflow)
- Case studies and benchmarks
- Expert opinions and comparisons

### 4. Evaluate Options
Against defined criteria:
- Technical fit
- Learning curve
- Community support
- Long-term viability
- Cost implications

### 5. Synthesize Findings
- Compare options in structured format
- Identify trade-offs
- Form recommendation with rationale

### 6. Generate Report
Create `.claude/research/[topic]-[date].md`:
```markdown
# Research: [Topic]

## Question
[The decision this informs]

## Options Evaluated
[List with brief description]

## Evaluation Matrix
| Criteria | Option A | Option B | Option C |
|----------|----------|----------|----------|

## Recommendation
[Primary recommendation with rationale]

## Trade-offs
[What you give up with this choice]

## Next Steps
[Follow-up actions]
```

### 7. Create Follow-up Tasks
```bash
npx @stevestomp/ohno-cli create "[implementation task]" -t feature
```

## Covers
- Technology evaluation
- Vendor comparison
- Architecture decisions
- Build vs buy analysis
- Migration planning

## Related Commands

- `/pokayokay:spike` - Shorter time-boxed investigation
- `/pokayokay:arch` - Architecture review
- `/pokayokay:work` - Implement chosen approach

## Skill Integration

When research involves:
- **Architecture patterns** → Also load `architecture-review` skill
- **Security evaluation** → Also load `security-audit` skill
- **Database options** → Also load `database-design` skill
