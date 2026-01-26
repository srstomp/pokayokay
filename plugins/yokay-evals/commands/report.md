---
description: View and analyze evaluation reports
argument-hint: "[grade|eval|trends] [--format <table|chart>]"
---

# Evaluation Reporting Workflow

View, compare, and analyze evaluation reports from grading and meta-evaluation runs.

**Arguments**: `$ARGUMENTS` (report type and options)

## Purpose

The reporting system helps you track quality trends over time, identify patterns in agent behavior, and prioritize improvement efforts based on historical data.

## Report Types

### 1. Grade Reports (Skill Clarity)

View skill grading reports to track clarity improvements.

**View Latest Report:**
```bash
# Find most recent report
ls -t /Users/sis4m4/Projects/stevestomp/pokayokay/reports/skill-clarity-*.md | head -1

# Read the report
cat $(ls -t /Users/sis4m4/Projects/stevestomp/pokayokay/reports/skill-clarity-*.md | head -1)
```

**Compare Two Reports:**
```bash
# View changes between dates
diff reports/skill-clarity-2026-01-25.md reports/skill-clarity-2026-01-26.md
```

### 2. Eval Reports (Meta-Evaluation)

Meta-evaluation reports show agent accuracy and consistency metrics.

**Current Status:**
Meta-evaluation reports are printed to stdout. Future enhancement will save them to files.

**Capture Report to File:**
```bash
./yokay-evals/bin/yokay-evals meta --agent yokay-spec-reviewer > reports/meta-spec-reviewer-$(date +%Y-%m-%d).txt
```

### 3. Trend Analysis

Track quality metrics over time across multiple reports.

**Extract Summary Statistics:**
```bash
# Get average scores over time
grep "Average Score:" reports/skill-clarity-*.md

# Get pass rates over time
grep "Pass Rate:" reports/skill-clarity-*.md
```

**Visualize Trends (Manual):**
Create a summary table from multiple reports:
```markdown
| Date | Avg Score | Pass Rate | Skills < 70 |
|------|-----------|-----------|-------------|
| 2026-01-25 | 60.3 | 3.7% | 26/27 |
| 2026-01-26 | 62.1 | 7.4% | 25/27 |
| 2026-01-27 | 65.5 | 11.1% | 24/27 |
```

## Analysis Workflows

### Skill Quality Trends

**Goal:** Track which skills are improving or degrading.

**Steps:**
1. Compare skill scores across multiple reports
2. Identify skills with declining scores (regression)
3. Identify skills with improving scores (success)
4. Create tasks for regressed skills

**Extract Skill Score Over Time:**
```bash
# Find specific skill across all reports
grep "aesthetic-ui-designer" reports/skill-clarity-*.md
```

**Example Output:**
```
skill-clarity-2026-01-25.md:- **aesthetic-ui-designer** - 54.2/100
skill-clarity-2026-01-26.md:- **aesthetic-ui-designer** - 54.2/100
skill-clarity-2026-01-27.md:- **aesthetic-ui-designer** - 65.0/100  # Improved!
```

### Agent Reliability Tracking

**Goal:** Monitor agent accuracy and consistency over time.

**Steps:**
1. Run meta-eval for same agent across different dates
2. Compare accuracy and consistency metrics
3. Identify tests that become unstable
4. Correlate with code/prompt changes

**Compare Agent Performance:**
```bash
# Run eval and save to dated files
./yokay-evals/bin/yokay-evals meta --agent yokay-spec-reviewer > reports/meta-spec-reviewer-$(date +%Y-%m-%d).txt

# Compare two runs
diff reports/meta-spec-reviewer-2026-01-25.txt reports/meta-spec-reviewer-2026-01-26.txt
```

### Priority Skill Improvements

**Goal:** Identify which skills to improve first based on impact.

**Steps:**
1. Review latest skill-clarity report
2. Sort skills by score (lowest first)
3. Check which skills are used most frequently in workflows
4. Prioritize low-scoring, high-usage skills

**Find High-Impact Skills:**
```bash
# Skills used in work command
grep -r "skill:" /Users/sis4m4/Projects/stevestomp/pokayokay/plugins/pokayokay/commands/*.md

# Cross-reference with low scores in latest report
cat $(ls -t /Users/sis4m4/Projects/stevestomp/pokayokay/reports/skill-clarity-*.md | head -1) | grep -A 30 "Below Threshold"
```

### Regression Detection

**Goal:** Catch when previously-passing skills or agents start failing.

**Steps:**
1. Compare latest report with baseline (e.g., last release)
2. Identify skills that dropped below 70 (failed)
3. Identify agents with decreased accuracy
4. Create P1 tasks for regressions

**Detect Regressions:**
```bash
# Compare baseline vs current
comm -3 <(grep "✅ Pass" reports/skill-clarity-baseline.md | sort) \
         <(grep "✅ Pass" reports/skill-clarity-$(date +%Y-%m-%d).md | sort)
```

## Report Formats

### Grade Report Structure

**File:** `reports/skill-clarity-YYYY-MM-DD.md`

**Sections:**
1. **Summary**: Aggregate statistics
2. **Skills Below Threshold**: Failed and low-pass skills
3. **Skills by Score**: Ranked table
4. **Detailed Breakdown**: Per-skill criterion scores

**Key Metrics to Track:**
- Average Score (target: > 75)
- Pass Rate (target: > 90%)
- Count of failed skills (target: 0)

### Meta-Eval Report Structure

**Currently:** Stdout only (future: saved to files)

**Sections:**
1. **Header**: Agent name, test count
2. **Results**: Per-test PASS/FAIL with consistency
3. **Metrics**: Accuracy and consistency percentages

**Key Metrics to Track:**
- Accuracy (target: > 90%)
- Consistency (target: > 80%)
- Failed test IDs

## Automation Opportunities

### Scheduled Reporting

**Weekly Grade Report:**
```bash
# Add to cron or CI
0 0 * * 0 cd /path/to/pokayokay && ./yokay-evals/bin/yokay-evals grade-skills
```

**Pre-Commit Meta-Eval:**
```bash
# In pre-commit hook
./yokay-evals/bin/yokay-evals meta --suite agents --k 3
```

### Slack/Email Alerts

**Future Enhancement:** Send alerts when:
- Average skill score drops below threshold
- Agent accuracy falls below 80%
- New skills fail grading

### Dashboard

**Future Enhancement:** Web dashboard showing:
- Skill score trends over time
- Agent reliability heatmap
- Test failure history
- Top priority improvements

## Report Storage

**Current Locations:**
- Grade reports: `reports/skill-clarity-YYYY-MM-DD.md`
- Meta-eval reports: Stdout (save manually)

**Recommended Organization:**
```
reports/
  skill-clarity/
    2026-01-26.md
    2026-01-27.md
  meta-eval/
    agents/
      yokay-spec-reviewer/
        2026-01-26.txt
        2026-01-27.txt
      yokay-quality-reviewer/
        2026-01-26.txt
  trends/
    skill-scores-q1-2026.csv
    agent-accuracy-q1-2026.csv
```

## Analysis Examples

### Example 1: Skill Improvement Verification

**Scenario:** You revised the `api-design` skill. Did it improve?

```bash
# Before revision
grep "api-design" reports/skill-clarity-2026-01-25.md
# Output: - **api-design** - 60.5/100 - FAILED

# After revision
./yokay-evals/bin/yokay-evals grade-skills
grep "api-design" reports/skill-clarity-2026-01-26.md
# Output: - **api-design** - 78.5/100 - ⚠️ Pass (Low)

# Improvement: +18 points, now passing!
```

### Example 2: Agent Regression Investigation

**Scenario:** `yokay-spec-reviewer` started failing tests. What changed?

```bash
# Compare meta-eval results
diff reports/meta-spec-reviewer-2026-01-20.txt reports/meta-spec-reviewer-2026-01-26.txt

# Check git log for changes to agent
git log --oneline --since="2026-01-20" --until="2026-01-26" -- agents/yokay-spec-reviewer/

# Identify commit that broke it, revert or fix
```

### Example 3: Quarterly Quality Report

**Scenario:** Generate executive summary of skill quality for Q1.

```bash
# Extract summaries from all Q1 reports
for report in reports/skill-clarity-2026-0[1-3]-*.md; do
  echo "## $(basename $report)"
  grep -A 4 "## Summary" "$report"
  echo
done > reports/trends/q1-2026-summary.md
```

## Notes

- **Manual Process**: Current reporting is manual. Automation is planned.
- **Git-Tracked Reports**: Consider committing reports to track changes over time
- **Baseline Reports**: Tag specific reports as baselines for comparison (e.g., release versions)

## Related Commands

- `/yokay-evals:grade` - Generate new skill clarity report
- `/yokay-evals:eval` - Generate new meta-evaluation report
- `/pokayokay:audit` - Audit feature completeness (different from quality)
- `/pokayokay:review` - Review session patterns (different from skill quality)
