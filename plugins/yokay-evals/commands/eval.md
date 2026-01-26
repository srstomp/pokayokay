---
description: Run meta-evaluations on agents or skills
argument-hint: --suite <agents|skills> | --agent <agent-name> [--k <runs>]
---

# Meta-Evaluation Workflow

Run meta-evaluations to measure agent accuracy and consistency using the pass^k methodology.

**Arguments**: `$ARGUMENTS` (required flags)

## Purpose

Meta-evaluation tests agents against known scenarios to verify they produce correct and consistent results. This ensures agents are reliable before using them in production workflows.

**Key Metrics:**
- **Accuracy**: Percentage of test cases where the agent's majority verdict matches expected outcome
- **Consistency (pass^k)**: Percentage of test cases where all k runs produce identical verdicts

## Steps

### 1. Choose Evaluation Scope

**Option A: Run Full Suite**
```bash
./yokay-evals/bin/yokay-evals meta --suite agents
./yokay-evals/bin/yokay-evals meta --suite skills
```

**Option B: Run Specific Agent**
```bash
./yokay-evals/bin/yokay-evals meta --agent yokay-spec-reviewer
./yokay-evals/bin/yokay-evals meta --agent yokay-quality-reviewer
```

### 2. Configure Run Count (Optional)

Override the number of runs per test case:
```bash
# Run each test 10 times instead of default (5)
./yokay-evals/bin/yokay-evals meta --agent yokay-spec-reviewer --k 10

# Quick smoke test with 3 runs
./yokay-evals/bin/yokay-evals meta --suite agents --k 3
```

**Default k value**: 5 (or per-test-case value in `eval.yaml`)

### 3. Set Meta Directory (Optional)

Specify custom meta directory location:
```bash
./yokay-evals/bin/yokay-evals meta --agent yokay-spec-reviewer --meta-dir /custom/path/meta
```

**Default**: `yokay-evals/meta`

### 4. Interpret Results

The evaluation produces a report with:

**Per-Test Results:**
```
SR-001: PASS (5/5 consistent)
SR-002: FAIL (expected PASS, got FAIL) (3/5 consistent)
SR-003: PASS (5/5 consistent)
```

**Metrics Summary:**
```
Accuracy: 66.7% (2/3 correct)
Consistency (pass^k): 66.7% (2/3 all runs agree)
```

**Status Indicators:**
- `PASS`: Majority verdict matches expected, test passes
- `FAIL (expected X, got Y)`: Majority verdict differs from expected
- `(k/k consistent)`: All k runs produced identical verdicts
- `(m/k consistent)`: Only m out of k runs agreed with majority

### 5. Understand Test Cases

Each agent has an `eval.yaml` file defining test scenarios:

**Test Case Structure:**
```yaml
test_cases:
  - id: SR-001
    name: "Complete implementation passes spec review"
    input:
      task_title: "Add user login"
      task_description: "Implement user authentication"
      acceptance_criteria:
        - "Users can log in with email/password"
        - "Invalid credentials show error"
      implementation: |
        [Code implementation here]
    expected: PASS
    k: 5
    rationale: "Implementation meets all acceptance criteria"
```

**Common Expected Verdicts:**
- `PASS`: Agent should approve/accept
- `FAIL`: Agent should reject/flag issues
- `REFINED`: Agent should propose improvements
- `NEEDS_INPUT`: Agent should request clarification
- `SKIP`: Agent should skip/defer action

### 6. Analyze Failures

**Low Accuracy (<80%)**: Agent is making incorrect decisions
- Review failed test cases in detail
- Check if agent skill/prompt needs refinement
- Verify test cases have correct expected verdicts

**Low Consistency (<80%)**: Agent is non-deterministic
- Check for temperature settings (should be low for consistency)
- Review if test cases are ambiguous
- Consider if non-determinism is acceptable for this agent

**Both Low**: Fundamental agent issues
- Review agent prompt and skill definition
- Consider redesigning agent approach
- May need additional training examples

### 7. Create Remediation Tasks

For failed evaluations:

**If Accuracy is Low:**
```bash
# Create task to fix agent logic
npx @stevestomp/ohno-cli create "Fix yokay-spec-reviewer accuracy on edge cases" -t bug -p P1
```

**If Consistency is Low:**
```bash
# Create task to reduce non-determinism
npx @stevestomp/ohno-cli create "Improve yokay-spec-reviewer consistency" -t chore -p P2
```

**If Test Cases are Wrong:**
```bash
# Update eval.yaml with corrected expectations
# Re-run evaluation to verify
```

### 8. Track Progress Over Time

Run evaluations regularly to track improvements:
```bash
# Before changes
./yokay-evals/bin/yokay-evals meta --agent yokay-spec-reviewer > before.txt

# After implementing fixes
./yokay-evals/bin/yokay-evals meta --agent yokay-spec-reviewer > after.txt

# Compare results
diff before.txt after.txt
```

## Evaluation Suites

### Agents Suite

Located in: `yokay-evals/meta/agents/`

**Agents with Evaluations:**
- `yokay-spec-reviewer`: Validates implementation matches spec
- `yokay-quality-reviewer`: Checks code quality and best practices
- `yokay-brainstormer`: Refines underspecified tasks
- `yokay-browser-verifier`: Verifies UI implementation

**Adding New Agent Eval:**
1. Create `yokay-evals/meta/agents/<agent-name>/`
2. Add `eval.yaml` following the schema
3. Run `yokay-evals meta --agent <agent-name>` to verify

### Skills Suite

Located in: `yokay-evals/meta/skills/`

**Skills with Evaluations:**
- Skills can have meta-evaluations to test skill-guided agent behavior
- Less common than agent evals, used for complex skills

## Meta-Evaluation YAML Schema

**Required Fields:**
```yaml
agent: yokay-agent-name          # Agent being tested
consistency_threshold: 0.8       # Minimum consistency required (0.0-1.0)
test_cases:
  - id: XX-001                   # Unique ID (2-3 letters, 3 digits)
    name: "Test case name"
    input:
      task_title: "..."
      task_description: "..."    # Optional, depends on agent
      acceptance_criteria: []    # Optional
      implementation: "..."      # Optional
    expected: PASS               # Expected verdict
    k: 5                         # Runs per test (optional, defaults to 5)
    rationale: "Why this outcome is expected"
```

**Validation:**
- Agent name must match `^yokay-[a-z-]+$`
- Test ID must match `^[A-Z]{2,3}-\d{3}$`
- Consistency threshold: 0.0-1.0
- K value: 1-100 (or 0 for default)

## CLI Flags Reference

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| `--suite` | One of suite/agent | - | Run all evals in suite (agents\|skills) |
| `--agent` | One of suite/agent | - | Run specific agent eval |
| `--k` | No | 5 | Number of runs per test case |
| `--meta-dir` | No | `yokay-evals/meta` | Path to meta directory |

## Notes

- **Current Implementation**: Stub agent execution. Actual agent runner integration is planned but not yet implemented.
- **Test in Isolation**: Each run should be independent - agents shouldn't "learn" between runs
- **Determinism vs Creativity**: Some agents (brainstormer) may intentionally have lower consistency
- **Regression Testing**: Run evals before merging agent changes

## When to Run

**During Development:**
- After creating new agent
- After modifying agent prompts
- Before merging agent changes

**Regular Intervals:**
- Weekly regression tests
- Before production releases
- After skill updates that affect agents

**Ad-hoc:**
- When agents behave unexpectedly
- After model provider changes
- When investigating bug reports

## Related Commands

- `/yokay-evals:grade` - Grade skill clarity before running evals
- `/yokay-evals:report` - View evaluation trends over time
- `/pokayokay:revise` - Revise agent based on eval results
