# Skill Improvement Program

Human-editable steering file for the auto-skill-improvement loop.
The agent reads this before each iteration to guide its strategy.

## Current Focus

Establish baselines for all 23 skills. Then improve process skills first
(work-session, planning, spike) as they have the highest proven value-add (+18-28%).

## Constraints

- Don't add domain knowledge Claude already knows (testing-strategy lesson: -7% delta)
- Keep SKILL.md under 100 lines
- Keep references under 500 lines each
- Prefer removing content over adding (simplicity criterion)
- Don't change skill names or command mappings
- Don't modify eval.json (eval criteria are human-controlled)

## Strategy Notes

- Description wording has outsized impact (the "Description Trap")
- Anti-rationalization content is uniquely valuable
- Authority + commitment language doubles LLM compliance (33% → 72%)
- Process discipline > domain knowledge
- "When NOT to Use" sections improve routing accuracy
- Binary criteria in eval — decompose quality into multiple pass/fail checks

## Skill Tiers (Priority Order)

1. **Process skills** (highest value): work-session, planning, spike, deep-research
2. **Process-adjacent**: session-review, plan-revision, browser-verification, feature-audit, worktrees
3. **Cross-cutting**: error-handling, architecture-review, observability, performance-optimization
4. **Domain skills** (lowest value): api-design, database-design, testing-strategy, ci-cd, sdk-development, figma-plugin, api-integration, cloud-infrastructure, security-audit, documentation

## Stop Conditions

- Stop improving a skill when < 1% gain across 10 consecutive experiments
- Stop domain skills if they can't beat baseline after 20 experiments
- Stop the whole run when budget is exhausted
