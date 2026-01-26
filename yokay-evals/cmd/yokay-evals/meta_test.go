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
	sampleEval := `agent: yokay-test-agent
consistency_threshold: 0.95

test_cases:
  - id: TST-001
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

  - id: TST-002
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
	if evalConfig.Agent != "yokay-test-agent" {
		t.Errorf("Expected agent 'yokay-test-agent', got '%s'", evalConfig.Agent)
	}

	if evalConfig.ConsistencyThreshold != 0.95 {
		t.Errorf("Expected consistency threshold 0.95, got %f", evalConfig.ConsistencyThreshold)
	}

	if len(evalConfig.TestCases) != 2 {
		t.Fatalf("Expected 2 test cases, got %d", len(evalConfig.TestCases))
	}

	// Verify first test case
	tc1 := evalConfig.TestCases[0]
	if tc1.ID != "TST-001" {
		t.Errorf("Expected ID 'TST-001', got '%s'", tc1.ID)
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
	if tc2.ID != "TST-002" {
		t.Errorf("Expected ID 'TST-002', got '%s'", tc2.ID)
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
	sampleEval := `agent: yokay-test-agent
consistency_threshold: 0.95

test_cases:
  - id: TST-001
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

	// Execute with no override (kOverride = 0)
	result, err := runMetaEvaluation(evalPath, 0)
	if err != nil {
		t.Fatalf("runMetaEvaluation failed: %v", err)
	}

	// Verify
	if result.Agent != "yokay-test-agent" {
		t.Errorf("Expected agent 'yokay-test-agent', got '%s'", result.Agent)
	}

	if len(result.TestResults) != 1 {
		t.Fatalf("Expected 1 test result, got %d", len(result.TestResults))
	}

	// Note: Actual grading is stubbed, so we just verify structure
	tr := result.TestResults[0]
	if tr.TestID != "TST-001" {
		t.Errorf("Expected test ID 'TST-001', got '%s'", tr.TestID)
	}

	// Verify k from YAML was used (k=3)
	if len(tr.Runs) != 3 {
		t.Errorf("Expected 3 runs (from YAML k=3), got %d", len(tr.Runs))
	}
}

func TestRunMetaEvaluationWithKOverride(t *testing.T) {
	// Setup: Create temp directory with test eval.yaml
	tmpDir := t.TempDir()
	agentDir := filepath.Join(tmpDir, "meta", "agents", "test-agent")
	err := os.MkdirAll(agentDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test agent dir: %v", err)
	}

	// Write a simple eval.yaml with k=3
	sampleEval := `agent: yokay-test-agent
consistency_threshold: 0.95

test_cases:
  - id: TST-001
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

	// Execute with kOverride = 10 (should override YAML k=3)
	result, err := runMetaEvaluation(evalPath, 10)
	if err != nil {
		t.Fatalf("runMetaEvaluation failed: %v", err)
	}

	// Verify
	if len(result.TestResults) != 1 {
		t.Fatalf("Expected 1 test result, got %d", len(result.TestResults))
	}

	tr := result.TestResults[0]

	// Verify kOverride=10 was used instead of YAML k=3
	if len(tr.Runs) != 10 {
		t.Errorf("Expected 10 runs (from kOverride=10), got %d", len(tr.Runs))
	}
}

func TestRunMetaEvaluationWithDefaultK(t *testing.T) {
	// Setup: Create temp directory with test eval.yaml
	tmpDir := t.TempDir()
	agentDir := filepath.Join(tmpDir, "meta", "agents", "test-agent")
	err := os.MkdirAll(agentDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test agent dir: %v", err)
	}

	// Write eval.yaml WITHOUT k specified (k=0 or missing)
	sampleEval := `agent: yokay-test-agent
consistency_threshold: 0.95

test_cases:
  - id: TST-001
    name: "Test pass case"
    input:
      task_title: "Test Task"
      task_description: "A test task"
      acceptance_criteria: ["Criterion 1"]
      implementation: "// code"
    expected: PASS
    rationale: "Should pass"
`
	evalPath := filepath.Join(agentDir, "eval.yaml")
	err = os.WriteFile(evalPath, []byte(sampleEval), 0644)
	if err != nil {
		t.Fatalf("Failed to write test eval.yaml: %v", err)
	}

	// Execute with no override (kOverride = 0)
	result, err := runMetaEvaluation(evalPath, 0)
	if err != nil {
		t.Fatalf("runMetaEvaluation failed: %v", err)
	}

	// Verify
	if len(result.TestResults) != 1 {
		t.Fatalf("Expected 1 test result, got %d", len(result.TestResults))
	}

	tr := result.TestResults[0]

	// Verify default k=5 was used (since neither YAML nor CLI specified k)
	if len(tr.Runs) != 5 {
		t.Errorf("Expected 5 runs (default when k not specified), got %d", len(tr.Runs))
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

// TestGetMajorityVerdictTieBreaking tests deterministic tie-breaking behavior
func TestGetMajorityVerdictTieBreaking(t *testing.T) {
	tests := []struct {
		name     string
		runs     []string
		expected string
	}{
		{
			name:     "Two-way tie - alphabetically first wins",
			runs:     []string{"PASS", "FAIL"},
			expected: "FAIL", // "FAIL" comes before "PASS" alphabetically
		},
		{
			name:     "Three-way tie - alphabetically first wins",
			runs:     []string{"PASS", "FAIL", "WARN"},
			expected: "FAIL", // "FAIL" < "PASS" < "WARN"
		},
		{
			name:     "No tie - majority wins",
			runs:     []string{"PASS", "PASS", "FAIL"},
			expected: "PASS",
		},
		{
			name:     "Empty runs",
			runs:     []string{},
			expected: "",
		},
		{
			name:     "Single run",
			runs:     []string{"PASS"},
			expected: "PASS",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := getMajorityVerdict(tt.runs)
			if result != tt.expected {
				t.Errorf("Expected %q, got %q", tt.expected, result)
			}
		})
	}
}

// TestFindEvalFiles tests the consolidated findEvalFiles function
func TestFindEvalFiles(t *testing.T) {
	// Setup: Create temp directory with eval files
	tmpDir := t.TempDir()
	testDir := filepath.Join(tmpDir, "test-suite")

	// Create structure with multiple subdirectories
	subdirs := []string{"component-a", "component-b", "component-c"}
	for _, subdir := range subdirs {
		dir := filepath.Join(testDir, subdir)
		err := os.MkdirAll(dir, 0755)
		if err != nil {
			t.Fatalf("Failed to create dir %s: %v", subdir, err)
		}

		evalContent := "test: " + subdir + "\ntest_cases: []"
		err = os.WriteFile(filepath.Join(dir, "eval.yaml"), []byte(evalContent), 0644)
		if err != nil {
			t.Fatalf("Failed to write eval.yaml for %s: %v", subdir, err)
		}
	}

	// Also create a non-eval.yaml file to ensure it's not picked up
	err := os.WriteFile(filepath.Join(testDir, "component-a", "other.yaml"), []byte("test: other"), 0644)
	if err != nil {
		t.Fatalf("Failed to write other.yaml: %v", err)
	}

	// Execute
	files, err := findEvalFiles(testDir)
	if err != nil {
		t.Fatalf("findEvalFiles failed: %v", err)
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

// TestRunMetaCommandErrors tests error handling in runMetaCommand
func TestRunMetaCommandErrors(t *testing.T) {
	tmpDir := t.TempDir()
	metaDir := filepath.Join(tmpDir, "meta")
	err := os.MkdirAll(metaDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create meta dir: %v", err)
	}

	tests := []struct {
		name        string
		suite       string
		agent       string
		expectError string
	}{
		{
			name:        "No suite or agent specified",
			suite:       "",
			agent:       "",
			expectError: "must specify either --suite or --agent",
		},
		{
			name:        "Invalid suite",
			suite:       "invalid",
			agent:       "",
			expectError: "suite directory not found",
		},
		{
			name:        "Agent not found",
			suite:       "",
			agent:       "nonexistent-agent",
			expectError: "eval.yaml not found for agent",
		},
		{
			name:        "Suite directory not found",
			suite:       "agents",
			agent:       "",
			expectError: "suite directory not found",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := runMetaCommand(tt.suite, tt.agent, 0, metaDir)
			if err == nil {
				t.Fatalf("Expected error containing %q, got nil", tt.expectError)
			}
			if !strings.Contains(err.Error(), tt.expectError) {
				t.Errorf("Expected error containing %q, got %q", tt.expectError, err.Error())
			}
		})
	}
}

// TestRunMetaCommandWithAgent tests running meta command with specific agent
func TestRunMetaCommandWithAgent(t *testing.T) {
	tmpDir := t.TempDir()
	metaDir := filepath.Join(tmpDir, "meta")
	agentDir := filepath.Join(metaDir, "agents", "test-agent")
	err := os.MkdirAll(agentDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create agent dir: %v", err)
	}

	// Write a simple eval.yaml
	sampleEval := `agent: yokay-test-agent
consistency_threshold: 0.95

test_cases:
  - id: TST-001
    name: "Test case"
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

	// Execute - should not return error
	err = runMetaCommand("", "test-agent", 0, metaDir)
	if err != nil {
		t.Errorf("runMetaCommand failed: %v", err)
	}
}

// TestLoadEvalYAMLErrors tests error handling when loading invalid YAML
func TestLoadEvalYAMLErrors(t *testing.T) {
	tests := []struct {
		name        string
		yamlContent string
		expectError string
	}{
		{
			name:        "Invalid YAML syntax",
			yamlContent: "agent: test\n\tinvalid: [unclosed",
			expectError: "parsing eval.yaml",
		},
		{
			name:        "Empty file",
			yamlContent: "",
			expectError: "", // Empty YAML is valid, just results in zero values
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			tmpDir := t.TempDir()
			evalPath := filepath.Join(tmpDir, "eval.yaml")
			err := os.WriteFile(evalPath, []byte(tt.yamlContent), 0644)
			if err != nil {
				t.Fatalf("Failed to write test eval.yaml: %v", err)
			}

			_, err = loadEvalYAML(evalPath)
			if tt.expectError != "" {
				if err == nil {
					t.Fatalf("Expected error containing %q, got nil", tt.expectError)
				}
				if !strings.Contains(err.Error(), tt.expectError) {
					t.Errorf("Expected error containing %q, got %q", tt.expectError, err.Error())
				}
			}
		})
	}
}

// TestLoadEvalYAMLFileNotFound tests error when file doesn't exist
func TestLoadEvalYAMLFileNotFound(t *testing.T) {
	_, err := loadEvalYAML("/nonexistent/path/eval.yaml")
	if err == nil {
		t.Fatal("Expected error for nonexistent file, got nil")
	}
	if !strings.Contains(err.Error(), "reading eval.yaml") {
		t.Errorf("Expected error about reading file, got: %v", err)
	}
}

// TestValidateEvalConfig tests validation of EvalConfig
func TestValidateEvalConfig(t *testing.T) {
	tests := []struct {
		name        string
		config      EvalConfig
		expectError bool
		errorMsg    string
	}{
		{
			name: "Valid config",
			config: EvalConfig{
				Agent:                "yokay-brainstormer",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "Test case",
						Input: TaskInput{
							TaskTitle:       "Test task",
							TaskDescription: "Description",
							Implementation:  "code",
						},
						Expected:  "PASS",
						K:         5,
						Rationale: "Because reasons",
					},
				},
			},
			expectError: false,
		},
		{
			name: "Invalid agent name - no yokay prefix",
			config: EvalConfig{
				Agent:                "brainstormer",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "PASS",
						Rationale: "Reason",
					},
				},
			},
			expectError: true,
			errorMsg:    "agent name must match pattern ^yokay-[a-z-]+$",
		},
		{
			name: "Invalid agent name - uppercase",
			config: EvalConfig{
				Agent:                "yokay-Brainstormer",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "PASS",
						Rationale: "Reason",
					},
				},
			},
			expectError: true,
			errorMsg:    "agent name must match pattern ^yokay-[a-z-]+$",
		},
		{
			name: "Missing agent name",
			config: EvalConfig{
				Agent:                "",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "PASS",
						Rationale: "Reason",
					},
				},
			},
			expectError: true,
			errorMsg:    "agent is required",
		},
		{
			name: "Consistency threshold too low",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: -0.1,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "PASS",
						Rationale: "Reason",
					},
				},
			},
			expectError: true,
			errorMsg:    "consistency_threshold must be between 0.0 and 1.0",
		},
		{
			name: "Consistency threshold too high",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: 1.5,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "PASS",
						Rationale: "Reason",
					},
				},
			},
			expectError: true,
			errorMsg:    "consistency_threshold must be between 0.0 and 1.0",
		},
		{
			name: "No test cases",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: 0.95,
				TestCases:            []TestCase{},
			},
			expectError: true,
			errorMsg:    "test_cases must contain at least 1 test case",
		},
		{
			name: "Invalid test ID format - lowercase",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "br-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "PASS",
						Rationale: "Reason",
					},
				},
			},
			expectError: true,
			errorMsg:    "test case ID 'br-001' must match pattern ^[A-Z]{2,3}-\\d{3}$",
		},
		{
			name: "Invalid test ID format - missing dash",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BR001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "PASS",
						Rationale: "Reason",
					},
				},
			},
			expectError: true,
			errorMsg:    "test case ID 'BR001' must match pattern ^[A-Z]{2,3}-\\d{3}$",
		},
		{
			name: "Invalid test ID format - four letter prefix",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BRST-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "PASS",
						Rationale: "Reason",
					},
				},
			},
			expectError: true,
			errorMsg:    "test case ID 'BRST-001' must match pattern ^[A-Z]{2,3}-\\d{3}$",
		},
		{
			name: "Missing test name",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "PASS",
						Rationale: "Reason",
					},
				},
			},
			expectError: true,
			errorMsg:    "test case BR-001: name is required",
		},
		{
			name: "Missing expected value",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "",
						Rationale: "Reason",
					},
				},
			},
			expectError: true,
			errorMsg:    "test case BR-001: expected is required",
		},
		{
			name: "K value too low",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "PASS",
						K:         0,
						Rationale: "Reason",
					},
				},
			},
			expectError: false, // K is optional, 0 means use default
		},
		{
			name: "K value too high",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "PASS",
						K:         150,
						Rationale: "Reason",
					},
				},
			},
			expectError: true,
			errorMsg:    "test case BR-001: k must be between 1 and 100 (or 0 for default)",
		},
		{
			name: "Missing task title",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "PASS",
						Rationale: "Reason",
					},
				},
			},
			expectError: true,
			errorMsg:    "test case BR-001: input.task_title is required",
		},
		{
			name: "Valid with implementation but no description (for quality reviewer)",
			config: EvalConfig{
				Agent:                "yokay-quality-reviewer",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "QR-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "",
							Implementation:  "code",
						},
						Expected:  "PASS",
						Rationale: "Reason",
					},
				},
			},
			expectError: false,
		},
		{
			name: "Missing both description and implementation",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "",
							Implementation:  "",
						},
						Expected:  "PASS",
						Rationale: "Reason",
					},
				},
			},
			expectError: true,
			errorMsg:    "at least one of input.task_description or input.implementation is required",
		},
		{
			name: "Valid without implementation (for brainstormer)",
			config: EvalConfig{
				Agent:                "yokay-brainstormer",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "",
						},
						Expected:  "REFINED",
						Rationale: "Reason",
					},
				},
			},
			expectError: false,
		},
		{
			name: "Missing rationale",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: 0.95,
				TestCases: []TestCase{
					{
						ID:   "BR-001",
						Name: "Test",
						Input: TaskInput{
							TaskTitle:       "Test",
							TaskDescription: "Desc",
							Implementation:  "code",
						},
						Expected:  "PASS",
						Rationale: "",
					},
				},
			},
			expectError: true,
			errorMsg:    "test case BR-001: rationale is required",
		},
		{
			name: "Valid with 3-letter ID prefix",
			config: EvalConfig{
				Agent:                "yokay-test",
				ConsistencyThreshold: 0.8,
				TestCases: []TestCase{
					{
						ID:   "QAR-123",
						Name: "Test case",
						Input: TaskInput{
							TaskTitle:          "Test",
							TaskDescription:    "Desc",
							AcceptanceCriteria: []string{"Criterion 1", "Criterion 2"},
							Implementation:     "code",
						},
						Expected:  "FAIL",
						K:         10,
						Rationale: "Reason",
					},
				},
			},
			expectError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := ValidateEvalConfig(&tt.config)

			if tt.expectError {
				if err == nil {
					t.Errorf("Expected error containing '%s', got nil", tt.errorMsg)
				} else if !strings.Contains(err.Error(), tt.errorMsg) {
					t.Errorf("Expected error containing '%s', got '%s'", tt.errorMsg, err.Error())
				}
			} else {
				if err != nil {
					t.Errorf("Expected no error, got: %v", err)
				}
			}
		})
	}
}
