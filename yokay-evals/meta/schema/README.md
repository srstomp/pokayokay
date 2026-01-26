# Meta-Evaluation Schema

This directory contains the JSON Schema definition for agent meta-evaluation YAML files.

## Schema File

- **eval.schema.json**: JSON Schema (Draft 7) defining the structure and validation rules for `eval.yaml` files

## Overview

The eval.yaml schema defines how to structure test cases for evaluating pokayokay agents. Each eval.yaml file tests one agent's behavior across multiple test cases.

## Schema Structure

### Top-Level Fields

```yaml
agent: yokay-agent-name              # Required: Agent name (must start with "yokay-")
consistency_threshold: 0.95          # Required: Minimum consistency (0.0-1.0)
test_cases:                          # Required: Array of test cases (min 1)
  - id: TC-001
    # ... test case fields
```

### Test Case Fields

Each test case in the `test_cases` array must have:

```yaml
- id: TC-001                         # Required: Format [A-Z]{2,3}-\d{3} (e.g., BR-001, QR-123)
  name: "Test case description"      # Required: Human-readable name
  input:                             # Required: Task input object
    task_title: "..."               # Required: Task title
    task_description: "..."         # Optional: Task description (required for brainstormer)
    acceptance_criteria:            # Optional: List of criteria
      - "Criterion 1"
      - "Criterion 2"
    implementation: |               # Optional: Code to review (required for quality reviewer)
      // code here
  expected: PASS                     # Required: Expected verdict (e.g., PASS, FAIL, REFINED)
  k: 5                               # Optional: Number of test runs (1-100, default 5)
  rationale: "Why this result..."    # Required: Explanation of expected result
```

## Validation Rules

### Agent Name
- **Pattern**: `^yokay-[a-z-]+$`
- **Example**: `yokay-brainstormer`, `yokay-quality-reviewer`
- Must start with "yokay-" followed by lowercase letters and hyphens

### Consistency Threshold
- **Type**: Number
- **Range**: 0.0 to 1.0
- **Example**: 0.8, 0.9, 0.95

### Test Case ID
- **Pattern**: `^[A-Z]{2,3}-\d{3}$`
- **Examples**: `BR-001`, `SR-042`, `QAR-123`
- 2-3 uppercase letters, dash, 3 digits

### Expected Verdict
- **Type**: String (non-empty)
- **Common Values**:
  - For quality/spec reviewers: `PASS`, `FAIL`
  - For brainstormer: `REFINED`, `SKIP`, `NEEDS_INPUT`
- Agent-specific - no strict enum validation

### K (Repetitions)
- **Type**: Integer
- **Range**: 0-100 (0 means use default of 5)
- **Default**: 5

### Task Input
- **task_title**: Required - string
- **task_description**: Optional - string (required for brainstormer)
- **acceptance_criteria**: Optional - array of strings
- **implementation**: Optional - string (required for quality reviewer)
- **Validation**: At least one of `task_description` or `implementation` must be provided

## Agent-Specific Patterns

### Brainstormer (yokay-brainstormer)
Tests task refinement capabilities:
```yaml
input:
  task_title: "Improve performance"
  task_description: "The app is slow, make it faster"
  acceptance_criteria: null
expected: REFINED  # or SKIP, NEEDS_INPUT
```

### Quality Reviewer (yokay-quality-reviewer)
Tests code quality evaluation:
```yaml
input:
  task_title: "Add user profile update endpoint"
  implementation: |
    // src/controllers/userController.ts
    export async function updateProfile(req, res) {
      // ... code here
    }
expected: PASS  # or FAIL
```

### Spec Reviewer (yokay-spec-reviewer)
Tests specification review:
```yaml
input:
  task_title: "Add email validation"
  task_description: "Validate email format"
  acceptance_criteria:
    - "Check email format"
    - "Return error on invalid email"
  implementation: |
    // implementation code
expected: PASS  # or FAIL
```

## Validation in Code

The schema is enforced by the `ValidateEvalConfig()` function in `meta.go`, which is called automatically when loading eval.yaml files. Validation errors will prevent the evaluation from running and provide clear error messages.

## Example

```yaml
# Meta-Evaluation for yokay-example
agent: yokay-example
consistency_threshold: 0.95

test_cases:
  - id: EX-001
    name: "Test case description"
    input:
      task_title: "Example task"
      task_description: "Detailed description of the task"
      acceptance_criteria:
        - "First criterion"
        - "Second criterion"
      implementation: |
        // Example implementation
        function example() {
          return true;
        }
    expected: PASS
    k: 5
    rationale: "Should pass because the implementation meets all criteria"
```

## Schema Validation Tools

While the JSON Schema file is primarily for documentation, it can be used with standard JSON Schema validators:

```bash
# Validate a YAML file against the schema (requires yq and ajv)
yq eval -o=json eval.yaml | ajv validate -s eval.schema.json
```

However, the primary validation is done by the Go code in `meta.go`, which provides better error messages and is integrated into the evaluation workflow.
