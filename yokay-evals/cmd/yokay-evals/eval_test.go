package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestLoadFailureCase tests loading a single failure case from YAML
func TestLoadFailureCase(t *testing.T) {
	// Setup: Create temp directory with test failure case
	tmpDir := t.TempDir()
	failureDir := filepath.Join(tmpDir, "failures", "missed-tasks")
	err := os.MkdirAll(failureDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create failure dir: %v", err)
	}

	// Write a sample failure case
	sampleFailure := `id: MT-001
category: missed-tasks
discovered: 2026-01-25
severity: high

context:
  task: "Test task"

failure:
  description: "Test description"
  root_cause: "Test root cause"

evidence:
  task_spec: |
    Test spec
  what_was_built: |
    Test implementation

eval_criteria:
  - type: code-based
    check: "test_check()"
  - type: model-based
    check: "Model test check"
`
	failurePath := filepath.Join(failureDir, "MT-001.yaml")
	err = os.WriteFile(failurePath, []byte(sampleFailure), 0644)
	if err != nil {
		t.Fatalf("Failed to write test failure case: %v", err)
	}

	// Execute
	failureCase, err := loadFailureCase(failurePath)
	if err != nil {
		t.Fatalf("loadFailureCase failed: %v", err)
	}

	// Verify
	if failureCase.ID != "MT-001" {
		t.Errorf("Expected ID 'MT-001', got '%s'", failureCase.ID)
	}
	if failureCase.Category != "missed-tasks" {
		t.Errorf("Expected category 'missed-tasks', got '%s'", failureCase.Category)
	}
	if failureCase.Severity != "high" {
		t.Errorf("Expected severity 'high', got '%s'", failureCase.Severity)
	}
	if len(failureCase.EvalCriteria) != 2 {
		t.Fatalf("Expected 2 eval criteria, got %d", len(failureCase.EvalCriteria))
	}
	if failureCase.EvalCriteria[0].Type != "code-based" {
		t.Errorf("Expected type 'code-based', got '%s'", failureCase.EvalCriteria[0].Type)
	}
}

// TestFindFailureCases tests finding all failure case files
func TestFindFailureCases(t *testing.T) {
	// Setup: Create temp directory with multiple failure cases
	tmpDir := t.TempDir()
	failuresDir := filepath.Join(tmpDir, "failures")

	categories := []struct {
		name  string
		count int
	}{
		{"missed-tasks", 3},
		{"missing-tests", 2},
		{"wrong-product", 4},
	}

	for _, cat := range categories {
		catDir := filepath.Join(failuresDir, cat.name)
		err := os.MkdirAll(catDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create category dir %s: %v", cat.name, err)
		}

		for i := 1; i <= cat.count; i++ {
			content := `id: TEST-001
category: ` + cat.name + `
discovered: 2026-01-25
severity: medium

context:
  task: "Test"

failure:
  description: "Test"
  root_cause: "Test"

evidence:
  task_spec: "Test"
  what_was_built: "Test"

eval_criteria:
  - type: code-based
    check: "test()"
`
			filename := filepath.Join(catDir, "TEST-00"+string(rune('0'+i))+".yaml")
			err = os.WriteFile(filename, []byte(content), 0644)
			if err != nil {
				t.Fatalf("Failed to write failure case: %v", err)
			}
		}
	}

	// Execute
	cases, err := findFailureCases(failuresDir, "")
	if err != nil {
		t.Fatalf("findFailureCases failed: %v", err)
	}

	// Verify
	expectedTotal := 3 + 2 + 4
	if len(cases) != expectedTotal {
		t.Errorf("Expected %d failure cases, got %d", expectedTotal, len(cases))
	}
}

// TestFindFailureCasesWithCategoryFilter tests filtering by category
func TestFindFailureCasesWithCategoryFilter(t *testing.T) {
	// Setup: Create temp directory with multiple categories
	tmpDir := t.TempDir()
	failuresDir := filepath.Join(tmpDir, "failures")

	categories := []string{"missed-tasks", "missing-tests", "wrong-product"}
	for _, cat := range categories {
		catDir := filepath.Join(failuresDir, cat)
		err := os.MkdirAll(catDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create category dir: %v", err)
		}

		content := `id: TEST-001
category: ` + cat + `
discovered: 2026-01-25
severity: medium

context:
  task: "Test"

failure:
  description: "Test"
  root_cause: "Test"

evidence:
  task_spec: "Test"
  what_was_built: "Test"

eval_criteria:
  - type: code-based
    check: "test()"
`
		filename := filepath.Join(catDir, "TEST-001.yaml")
		err = os.WriteFile(filename, []byte(content), 0644)
		if err != nil {
			t.Fatalf("Failed to write failure case: %v", err)
		}
	}

	// Execute with filter
	cases, err := findFailureCases(failuresDir, "missing-tests")
	if err != nil {
		t.Fatalf("findFailureCases failed: %v", err)
	}

	// Verify only missing-tests cases are returned
	if len(cases) != 1 {
		t.Errorf("Expected 1 failure case, got %d", len(cases))
	}
	if len(cases) > 0 && cases[0].Category != "missing-tests" {
		t.Errorf("Expected category 'missing-tests', got '%s'", cases[0].Category)
	}
}

// TestRunEvaluation tests running evaluation on failure cases (stubbed)
func TestRunEvaluation(t *testing.T) {
	// Create sample failure case
	failureCase := FailureCase{
		ID:       "MT-001",
		Category: "missed-tasks",
		Severity: "high",
		EvalCriteria: []EvalCriterion{
			{Type: "code-based", Check: "test_check()"},
			{Type: "model-based", Check: "Model check"},
		},
	}

	// Execute evaluation (stubbed, should always pass for now)
	result, err := runEvaluation(failureCase, 1)
	if err != nil {
		t.Fatalf("runEvaluation failed: %v", err)
	}

	// Verify result structure
	if result.CaseID != "MT-001" {
		t.Errorf("Expected case ID 'MT-001', got '%s'", result.CaseID)
	}
	if len(result.Runs) != 1 {
		t.Errorf("Expected 1 run, got %d", len(result.Runs))
	}
}

// TestRunEvaluationMultipleRuns tests k > 1 runs
func TestRunEvaluationMultipleRuns(t *testing.T) {
	failureCase := FailureCase{
		ID:       "MT-001",
		Category: "missed-tasks",
		EvalCriteria: []EvalCriterion{
			{Type: "code-based", Check: "test()"},
		},
	}

	// Execute with k=5
	result, err := runEvaluation(failureCase, 5)
	if err != nil {
		t.Fatalf("runEvaluation failed: %v", err)
	}

	// Verify 5 runs
	if len(result.Runs) != 5 {
		t.Errorf("Expected 5 runs, got %d", len(result.Runs))
	}
}

// TestFormatEvalSummary tests summary table generation
func TestFormatEvalSummary(t *testing.T) {
	// Create sample eval results
	results := []EvalResult{
		{CaseID: "MT-001", Category: "missed-tasks", Runs: []bool{true, true, true}},
		{CaseID: "MT-002", Category: "missed-tasks", Runs: []bool{false, false, false}},
		{CaseID: "WT-001", Category: "missing-tests", Runs: []bool{true, true, true}},
		{CaseID: "WT-002", Category: "missing-tests", Runs: []bool{true, false, true}},
		{CaseID: "WP-001", Category: "wrong-product", Runs: []bool{true, true, true}},
	}

	// Execute
	summary := formatEvalSummary(results, "table")

	// Verify summary contains expected sections
	if !strings.Contains(summary, "Eval Results Summary") {
		t.Error("Summary missing header")
	}
	if !strings.Contains(summary, "missed-tasks") {
		t.Error("Summary missing missed-tasks category")
	}
	if !strings.Contains(summary, "missing-tests") {
		t.Error("Summary missing missing-tests category")
	}
	if !strings.Contains(summary, "wrong-product") {
		t.Error("Summary missing wrong-product category")
	}
	// Should show pass counts
	if !strings.Contains(summary, "Pass") && !strings.Contains(summary, "Fail") {
		t.Error("Summary missing pass/fail indicators")
	}
}

// TestFormatEvalSummaryJSON tests JSON output format
func TestFormatEvalSummaryJSON(t *testing.T) {
	results := []EvalResult{
		{CaseID: "MT-001", Category: "missed-tasks", Runs: []bool{true, true, true}},
	}

	// Execute
	summary := formatEvalSummary(results, "json")

	// Verify it's valid JSON (contains expected JSON syntax)
	if !strings.Contains(summary, "{") || !strings.Contains(summary, "}") {
		t.Error("JSON summary doesn't contain JSON syntax")
	}
	if !strings.Contains(summary, "MT-001") {
		t.Error("JSON summary missing case ID")
	}
}

// TestCalculateEvalMetrics tests metric calculation
func TestCalculateEvalMetrics(t *testing.T) {
	results := []EvalResult{
		{CaseID: "MT-001", Category: "missed-tasks", Runs: []bool{true, true, true}},   // pass
		{CaseID: "MT-002", Category: "missed-tasks", Runs: []bool{false, false, true}}, // fail (majority false)
		{CaseID: "WT-001", Category: "missing-tests", Runs: []bool{true, true, true}},  // pass
		{CaseID: "WT-002", Category: "missing-tests", Runs: []bool{true, false, true}}, // pass (majority true)
	}

	// Execute
	metrics := calculateEvalMetrics(results)

	// Verify metrics by category
	if len(metrics) != 2 {
		t.Fatalf("Expected 2 categories, got %d", len(metrics))
	}

	// Check missed-tasks: 2 cases, 1 pass, 1 fail
	mtMetrics := metrics["missed-tasks"]
	if mtMetrics.Total != 2 {
		t.Errorf("Expected 2 total for missed-tasks, got %d", mtMetrics.Total)
	}
	if mtMetrics.Pass != 1 {
		t.Errorf("Expected 1 pass for missed-tasks, got %d", mtMetrics.Pass)
	}
	if mtMetrics.Fail != 1 {
		t.Errorf("Expected 1 fail for missed-tasks, got %d", mtMetrics.Fail)
	}

	// Check missing-tests: 2 cases, 2 pass, 0 fail
	wtMetrics := metrics["missing-tests"]
	if wtMetrics.Total != 2 {
		t.Errorf("Expected 2 total for missing-tests, got %d", wtMetrics.Total)
	}
	if wtMetrics.Pass != 2 {
		t.Errorf("Expected 2 pass for missing-tests, got %d", wtMetrics.Pass)
	}
}

// TestRunEvalCommand tests the eval CLI command
func TestRunEvalCommand(t *testing.T) {
	// Setup: Create temp directory with failure cases
	tmpDir := t.TempDir()
	failuresDir := filepath.Join(tmpDir, "failures")

	// Create a couple of failure cases
	categories := []string{"missed-tasks", "missing-tests"}
	for _, cat := range categories {
		catDir := filepath.Join(failuresDir, cat)
		err := os.MkdirAll(catDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create category dir: %v", err)
		}

		content := `id: TEST-001
category: ` + cat + `
discovered: 2026-01-25
severity: medium

context:
  task: "Test task"

failure:
  description: "Test description"
  root_cause: "Test root cause"

evidence:
  task_spec: "Test spec"
  what_was_built: "Test implementation"

eval_criteria:
  - type: code-based
    check: "test_check()"
`
		filename := filepath.Join(catDir, "TEST-001.yaml")
		err = os.WriteFile(filename, []byte(content), 0644)
		if err != nil {
			t.Fatalf("Failed to write failure case: %v", err)
		}
	}

	// Execute - should not return error
	err := runEvalCommand(failuresDir, "", 1, "table")
	if err != nil {
		t.Errorf("runEvalCommand failed: %v", err)
	}
}

// TestRunEvalCommandWithCategoryFilter tests eval command with category filter
func TestRunEvalCommandWithCategoryFilter(t *testing.T) {
	// Setup
	tmpDir := t.TempDir()
	failuresDir := filepath.Join(tmpDir, "failures")

	// Create failure cases in multiple categories
	categories := []string{"missed-tasks", "missing-tests"}
	for _, cat := range categories {
		catDir := filepath.Join(failuresDir, cat)
		err := os.MkdirAll(catDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create category dir: %v", err)
		}

		content := `id: TEST-001
category: ` + cat + `
discovered: 2026-01-25
severity: medium

context:
  task: "Test"

failure:
  description: "Test"
  root_cause: "Test"

evidence:
  task_spec: "Test"
  what_was_built: "Test"

eval_criteria:
  - type: code-based
    check: "test()"
`
		filename := filepath.Join(catDir, "TEST-001.yaml")
		err = os.WriteFile(filename, []byte(content), 0644)
		if err != nil {
			t.Fatalf("Failed to write failure case: %v", err)
		}
	}

	// Execute with category filter
	err := runEvalCommand(failuresDir, "missing-tests", 1, "table")
	if err != nil {
		t.Errorf("runEvalCommand with category filter failed: %v", err)
	}
}

// TestRunEvalCommandErrors tests error handling
func TestRunEvalCommandErrors(t *testing.T) {
	tests := []struct {
		name        string
		failuresDir string
		expectError string
	}{
		{
			name:        "Directory does not exist",
			failuresDir: "/nonexistent/path",
			expectError: "failures directory not found",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := runEvalCommand(tt.failuresDir, "", 1, "table")
			if err == nil {
				t.Fatalf("Expected error containing %q, got nil", tt.expectError)
			}
			if !strings.Contains(err.Error(), tt.expectError) {
				t.Errorf("Expected error containing %q, got %q", tt.expectError, err.Error())
			}
		})
	}
}
