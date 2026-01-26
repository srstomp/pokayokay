package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestLoadEvalYAML(t *testing.T) {
	// Setup: Create temp directory with test eval.yaml
	tmpDir := t.TempDir()
	agentDir := filepath.Join(tmpDir, "meta", "agents", "test-agent")
	err := os.MkdirAll(agentDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test agent dir: %v", err)
	}

	// Write a sample eval.yaml
	sampleEval := `agent: test-agent
consistency_threshold: 0.95

test_cases:
  - id: TEST-001
    name: "Test case one"
    input:
      task_title: "Test Task"
      task_description: "A test task"
      acceptance_criteria:
        - "Criterion 1"
        - "Criterion 2"
      implementation: |
        // code here
    expected: PASS
    k: 5
    rationale: "Should pass because xyz"

  - id: TEST-002
    name: "Test case two"
    input:
      task_title: "Another test"
      task_description: "Another test task"
      acceptance_criteria:
        - "Criterion A"
      implementation: |
        // more code
    expected: FAIL
    k: 3
    rationale: "Should fail because abc"
`
	evalPath := filepath.Join(agentDir, "eval.yaml")
	err = os.WriteFile(evalPath, []byte(sampleEval), 0644)
	if err != nil {
		t.Fatalf("Failed to write test eval.yaml: %v", err)
	}

	// Execute
	evalConfig, err := loadEvalYAML(evalPath)
	if err != nil {
		t.Fatalf("loadEvalYAML failed: %v", err)
	}

	// Verify
	if evalConfig.Agent != "test-agent" {
		t.Errorf("Expected agent 'test-agent', got '%s'", evalConfig.Agent)
	}

	if evalConfig.ConsistencyThreshold != 0.95 {
		t.Errorf("Expected consistency threshold 0.95, got %f", evalConfig.ConsistencyThreshold)
	}

	if len(evalConfig.TestCases) != 2 {
		t.Fatalf("Expected 2 test cases, got %d", len(evalConfig.TestCases))
	}

	// Verify first test case
	tc1 := evalConfig.TestCases[0]
	if tc1.ID != "TEST-001" {
		t.Errorf("Expected ID 'TEST-001', got '%s'", tc1.ID)
	}
	if tc1.Name != "Test case one" {
		t.Errorf("Expected name 'Test case one', got '%s'", tc1.Name)
	}
	if tc1.Expected != "PASS" {
		t.Errorf("Expected verdict 'PASS', got '%s'", tc1.Expected)
	}
	if tc1.K != 5 {
		t.Errorf("Expected k=5, got %d", tc1.K)
	}
	if tc1.Input.TaskTitle != "Test Task" {
		t.Errorf("Expected task title 'Test Task', got '%s'", tc1.Input.TaskTitle)
	}
	if len(tc1.Input.AcceptanceCriteria) != 2 {
		t.Errorf("Expected 2 acceptance criteria, got %d", len(tc1.Input.AcceptanceCriteria))
	}

	// Verify second test case
	tc2 := evalConfig.TestCases[1]
	if tc2.ID != "TEST-002" {
		t.Errorf("Expected ID 'TEST-002', got '%s'", tc2.ID)
	}
	if tc2.Expected != "FAIL" {
		t.Errorf("Expected verdict 'FAIL', got '%s'", tc2.Expected)
	}
	if tc2.K != 3 {
		t.Errorf("Expected k=3, got %d", tc2.K)
	}
}

func TestFindAgentEvalFiles(t *testing.T) {
	// Setup: Create temp directory with multiple agents
	tmpDir := t.TempDir()
	metaAgentsDir := filepath.Join(tmpDir, "meta", "agents")

	agents := []string{"yokay-brainstormer", "yokay-spec-reviewer", "yokay-quality-reviewer"}
	for _, agent := range agents {
		agentDir := filepath.Join(metaAgentsDir, agent)
		err := os.MkdirAll(agentDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create agent dir %s: %v", agent, err)
		}

		evalContent := "agent: " + agent + "\ntest_cases: []"
		err = os.WriteFile(filepath.Join(agentDir, "eval.yaml"), []byte(evalContent), 0644)
		if err != nil {
			t.Fatalf("Failed to write eval.yaml for %s: %v", agent, err)
		}
	}

	// Execute
	files, err := findAgentEvalFiles(metaAgentsDir)
	if err != nil {
		t.Fatalf("findAgentEvalFiles failed: %v", err)
	}

	// Verify
	if len(files) != 3 {
		t.Errorf("Expected 3 eval files, got %d", len(files))
	}

	// Verify all files end with eval.yaml
	for _, file := range files {
		if !strings.HasSuffix(file, "eval.yaml") {
			t.Errorf("File %s does not end with eval.yaml", file)
		}
	}
}

func TestRunMetaEvaluation(t *testing.T) {
	// Setup: Create temp directory with test eval.yaml
	tmpDir := t.TempDir()
	agentDir := filepath.Join(tmpDir, "meta", "agents", "test-agent")
	err := os.MkdirAll(agentDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test agent dir: %v", err)
	}

	// Write a simple eval.yaml
	sampleEval := `agent: test-agent
consistency_threshold: 0.95

test_cases:
  - id: TEST-001
    name: "Test pass case"
    input:
      task_title: "Test Task"
      task_description: "A test task"
      acceptance_criteria: ["Criterion 1"]
      implementation: "// code"
    expected: PASS
    k: 3
    rationale: "Should pass"
`
	evalPath := filepath.Join(agentDir, "eval.yaml")
	err = os.WriteFile(evalPath, []byte(sampleEval), 0644)
	if err != nil {
		t.Fatalf("Failed to write test eval.yaml: %v", err)
	}

	// Execute
	result, err := runMetaEvaluation(evalPath)
	if err != nil {
		t.Fatalf("runMetaEvaluation failed: %v", err)
	}

	// Verify
	if result.Agent != "test-agent" {
		t.Errorf("Expected agent 'test-agent', got '%s'", result.Agent)
	}

	if len(result.TestResults) != 1 {
		t.Fatalf("Expected 1 test result, got %d", len(result.TestResults))
	}

	// Note: Actual grading is stubbed, so we just verify structure
	tr := result.TestResults[0]
	if tr.TestID != "TEST-001" {
		t.Errorf("Expected test ID 'TEST-001', got '%s'", tr.TestID)
	}
}

func TestCalculateMetrics(t *testing.T) {
	// Test accuracy and consistency calculations
	testResults := []TestResult{
		{TestID: "T1", Expected: "PASS", Runs: []string{"PASS", "PASS", "PASS"}},           // correct, consistent
		{TestID: "T2", Expected: "FAIL", Runs: []string{"FAIL", "FAIL", "FAIL"}},           // correct, consistent
		{TestID: "T3", Expected: "PASS", Runs: []string{"FAIL", "FAIL", "FAIL"}},           // incorrect, consistent
		{TestID: "T4", Expected: "FAIL", Runs: []string{"PASS", "PASS", "FAIL"}},           // incorrect, inconsistent
		{TestID: "T5", Expected: "PASS", Runs: []string{"PASS", "PASS", "PASS", "PASS"}},   // correct, consistent (k=4)
	}

	metrics := calculateMetrics(testResults)

	// Accuracy: 3 correct out of 5 = 60%
	expectedAccuracy := 3.0 / 5.0
	if metrics.Accuracy != expectedAccuracy {
		t.Errorf("Expected accuracy %f, got %f", expectedAccuracy, metrics.Accuracy)
	}

	// Consistency: 4 out of 5 have all runs agreeing = 80%
	expectedConsistency := 4.0 / 5.0
	if metrics.Consistency != expectedConsistency {
		t.Errorf("Expected consistency %f, got %f", expectedConsistency, metrics.Consistency)
	}

	// Total test cases
	if metrics.TotalTests != 5 {
		t.Errorf("Expected 5 total tests, got %d", metrics.TotalTests)
	}

	// Correct count
	if metrics.CorrectCount != 3 {
		t.Errorf("Expected 3 correct, got %d", metrics.CorrectCount)
	}

	// Consistent count
	if metrics.ConsistentCount != 4 {
		t.Errorf("Expected 4 consistent, got %d", metrics.ConsistentCount)
	}
}

func TestFormatMetaReport(t *testing.T) {
	// Create sample evaluation result
	evalResult := EvaluationResult{
		Agent: "test-agent",
		TestResults: []TestResult{
			{
				TestID:   "T1",
				Name:     "Test one",
				Expected: "PASS",
				Runs:     []string{"PASS", "PASS", "PASS"},
			},
			{
				TestID:   "T2",
				Name:     "Test two",
				Expected: "FAIL",
				Runs:     []string{"PASS", "FAIL", "FAIL"},
			},
		},
	}

	report := formatMetaReport(evalResult)

	// Verify report contains expected sections
	if !strings.Contains(report, "Meta-Evaluation Report") {
		t.Error("Report missing header")
	}
	if !strings.Contains(report, "test-agent") {
		t.Error("Report missing agent name")
	}
	if !strings.Contains(report, "T1") {
		t.Error("Report missing test ID T1")
	}
	if !strings.Contains(report, "T2") {
		t.Error("Report missing test ID T2")
	}
	if !strings.Contains(report, "Accuracy") {
		t.Error("Report missing accuracy metric")
	}
	if !strings.Contains(report, "Consistency") {
		t.Error("Report missing consistency metric")
	}

	// Verify verdict info is present
	if !strings.Contains(report, "3/3") {
		t.Error("Report missing consistency notation for T1")
	}
}
