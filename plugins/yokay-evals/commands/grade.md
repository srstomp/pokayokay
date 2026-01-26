---
description: Grade pokayokay skills for clarity
argument-hint: "[--skills-dir <path>] [--output <path>]"
---

# Skill Grading Workflow

Grade all pokayokay skills using the Skill Clarity Grader and generate a comprehensive report.

**Arguments**: `$ARGUMENTS` (optional flags)

## Purpose

The skill grading system evaluates pokayokay skills against clarity criteria to ensure they provide actionable guidance to agents. This helps identify skills that need improvement before they're used in production workflows.

## Steps

### 1. Prepare Environment

Ensure the yokay-evals CLI is built and available:
```bash
cd /Users/sis4m4/Projects/stevestomp/pokayokay/yokay-evals
go build -o bin/yokay-evals cmd/yokay-evals/*.go
```

### 2. Run Grade Command

Grade all skills with default settings:
```bash
./yokay-evals/bin/yokay-evals grade-skills
```

**Available Flags:**
- `--skills-dir <path>` - Path to skills directory (default: `plugins/pokayokay/skills`)
- `--output <path>` - Custom output path (default: `reports/skill-clarity-YYYY-MM-DD.md`)

**Example with custom path:**
```bash
./yokay-evals/bin/yokay-evals grade-skills --skills-dir /custom/path/skills --output ./my-report.md
```

### 3. Review the Report

The grader evaluates each skill against four criteria:

**Grading Criteria** (weighted):
- **Clear Instructions** (30%): Are the skill's objectives and approach well-defined?
- **Actionable Steps** (30%): Does the skill provide concrete, executable steps?
- **Good Examples** (20%): Are there sufficient examples demonstrating usage?
- **Appropriate Scope** (20%): Is the skill focused and not too broad?

**Scoring Levels:**
- **80-100**: Excellent - Skill is production-ready
- **70-79**: Pass (Low) - Needs minor improvements
- **Below 70**: Failed - Requires significant revision

### 4. Review Report Sections

The generated report contains:

**Summary Section:**
- Total skills graded
- Average score across all skills
- Pass rate percentage
- Skills below threshold

**Skills by Score:**
- Ranked list from highest to lowest
- Visual status indicators (Pass/Fail/Low)

**Detailed Breakdown:**
- Individual criterion scores
- Specific feedback for each skill
- Improvement recommendations

### 5. Address Low-Scoring Skills

For skills scoring below 80:

**Priority 1: Failed Skills (< 70)**
1. Read the detailed breakdown for specific issues
2. Use `/pokayokay:revise` to update the skill
3. Focus on criteria with lowest scores first

**Priority 2: Low-Pass Skills (70-79)**
1. Review feedback for quick wins
2. Add examples if "Good Examples" score is low
3. Clarify steps if "Actionable Steps" needs work

### 6. Re-grade After Improvements

After revising skills, run the grader again to verify improvements:
```bash
./yokay-evals/bin/yokay-evals grade-skills
```

Compare the new report with the previous one to track progress.

## Output Format

**Report Location:** `reports/skill-clarity-YYYY-MM-DD.md`

**Report Structure:**
```markdown
# Skill Clarity Report

Generated: 2026-01-26 21:30:43

## Summary
- Total Skills: 27
- Average Score: 60.3/100
- Pass Rate: 3.7% (1/27)

## Skills Below Threshold (< 80%)
- skill-name - 75.0/100 - Needs Improvement
- another-skill - 68.0/100 - FAILED

## Skills by Score
| Rank | Skill | Score | Status |
|------|-------|-------|--------|
| 1    | best-skill | 85.0 | ✅ Pass |
| 2    | good-skill | 75.0 | ⚠️  Pass (Low) |
| 3    | poor-skill | 65.0 | ❌ Fail |

## Detailed Breakdown
### skill-name
**Overall Score**: 75.0/100
**Criteria Scores**:
- Clear Instructions (30%): 80.0/100
- Actionable Steps (30%): 70.0/100
- Good Examples (20%): 75.0/100
- Appropriate Scope (20%): 75.0/100
```

## When to Run

**Regular Intervals:**
- After creating new skills
- After major skill revisions
- Before releasing skill updates
- Monthly skill quality checks

**Ad-hoc:**
- When agents report unclear guidance
- During skill audits
- When onboarding new skill authors

## Notes

- **Current Implementation**: Uses heuristic-based evaluation (stub). LLM-based grading is planned but not yet implemented.
- **Non-Blocking**: Grading is advisory - skills can be used even if they score low, but should be prioritized for improvement.
- **Incremental Improvement**: Focus on improving one criterion at a time for failed skills.

## Related Commands

- `/pokayokay:revise` - Revise a skill based on grading feedback
- `/yokay-evals:eval` - Run meta-evaluations on agents using skills
- `/yokay-evals:report` - View historical grading trends
