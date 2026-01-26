package main

import (
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

// TestGradeSkillsCommandIntegration tests the grade-skills command end-to-end
func TestGradeSkillsCommandIntegration(t *testing.T) {
	// Build the binary first
	binaryPath := buildBinary(t)
	defer os.Remove(binaryPath)

	// Setup: Create temp directory for test output
	tmpDir := t.TempDir()
	reportPath := filepath.Join(tmpDir, "integration-report.md")

	// Create a test skills directory with sample skills
	skillsDir := filepath.Join(tmpDir, "skills")
	err := os.MkdirAll(filepath.Join(skillsDir, "test-skill-1"), 0755)
	if err != nil {
		t.Fatalf("Failed to create test skills dir: %v", err)
	}

	// Write a sample skill file
	sampleSkill := `---
name: test-skill-1
description: A test skill for integration validation
---

# Test Skill

This is a test skill with clear instructions.

## Instructions

1. First step with clear guidance
2. Second step with actionable items

## Examples

Here's an example of how to use this skill.
`
	err = os.WriteFile(filepath.Join(skillsDir, "test-skill-1", "SKILL.md"), []byte(sampleSkill), 0644)
	if err != nil {
		t.Fatalf("Failed to write test skill: %v", err)
	}

	// Execute the binary
	cmd := exec.Command(binaryPath, "grade-skills", "--skills-dir", skillsDir, "--output", reportPath)
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Command failed: %v\nOutput: %s", err, string(output))
	}

	// Verify exit code (should be 0 on success)
	if cmd.ProcessState.ExitCode() != 0 {
		t.Errorf("Expected exit code 0, got %d", cmd.ProcessState.ExitCode())
	}

	// Verify stdout contains success message
	outputStr := string(output)
	if !strings.Contains(outputStr, "Report generated") {
		t.Errorf("Output missing 'Report generated' message. Got: %s", outputStr)
	}

	// Verify report was created
	if _, err := os.Stat(reportPath); os.IsNotExist(err) {
		t.Fatal("Report file was not created")
	}

	// Read and verify report content
	content, err := os.ReadFile(reportPath)
	if err != nil {
		t.Fatalf("Failed to read report: %v", err)
	}

	reportStr := string(content)

	// Verify report contains expected sections
	expectedSections := []string{
		"# Skill Clarity Report",
		"## Summary",
		"## Skills by Score",
		"test-skill-1",
	}

	for _, section := range expectedSections {
		if !strings.Contains(reportStr, section) {
			t.Errorf("Report missing expected section: %s", section)
		}
	}
}

// TestGradeSkillsCommandInvalidDirectory tests error handling for non-existent directory
func TestGradeSkillsCommandInvalidDirectory(t *testing.T) {
	// Build the binary first
	binaryPath := buildBinary(t)
	defer os.Remove(binaryPath)

	tmpDir := t.TempDir()
	reportPath := filepath.Join(tmpDir, "report.md")

	// Execute with non-existent skills directory
	cmd := exec.Command(binaryPath, "grade-skills", "--skills-dir", "/nonexistent/path", "--output", reportPath)
	output, err := cmd.CombinedOutput()

	// Verify non-zero exit code
	if err == nil {
		t.Fatal("Expected command to fail with non-existent directory")
	}

	if cmd.ProcessState.ExitCode() == 0 {
		t.Error("Expected non-zero exit code for invalid directory")
	}

	// Verify error message in output
	outputStr := string(output)
	if !strings.Contains(outputStr, "Failed") || !strings.Contains(outputStr, "grade skills") {
		t.Errorf("Expected error message about grading failure. Got: %s", outputStr)
	}
}

// TestGradeSkillsCommandNoSkills tests error handling when no skills found
func TestGradeSkillsCommandNoSkills(t *testing.T) {
	// Build the binary first
	binaryPath := buildBinary(t)
	defer os.Remove(binaryPath)

	tmpDir := t.TempDir()
	reportPath := filepath.Join(tmpDir, "report.md")

	// Create empty skills directory
	skillsDir := filepath.Join(tmpDir, "empty-skills")
	err := os.MkdirAll(skillsDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create empty skills dir: %v", err)
	}

	// Execute with empty skills directory
	cmd := exec.Command(binaryPath, "grade-skills", "--skills-dir", skillsDir, "--output", reportPath)
	output, err := cmd.CombinedOutput()

	// Verify non-zero exit code
	if err == nil {
		t.Fatal("Expected command to fail with no skills")
	}

	if cmd.ProcessState.ExitCode() == 0 {
		t.Error("Expected non-zero exit code when no skills found")
	}

	// Verify error message
	outputStr := string(output)
	if !strings.Contains(outputStr, "no skill") {
		t.Errorf("Expected error about no skills found. Got: %s", outputStr)
	}
}

// TestMetaCommandIntegration tests the meta command end-to-end
func TestMetaCommandIntegration(t *testing.T) {
	// Build the binary first
	binaryPath := buildBinary(t)
	defer os.Remove(binaryPath)

	// Setup: Create temp directory with test meta structure
	tmpDir := t.TempDir()
	metaDir := filepath.Join(tmpDir, "meta")
	agentDir := filepath.Join(metaDir, "agents", "test-agent")
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
    k: 3
    rationale: "Should pass because xyz"
`
	evalPath := filepath.Join(agentDir, "eval.yaml")
	err = os.WriteFile(evalPath, []byte(sampleEval), 0644)
	if err != nil {
		t.Fatalf("Failed to write test eval.yaml: %v", err)
	}

	// Execute the binary
	cmd := exec.Command(binaryPath, "meta", "--agent", "test-agent", "--meta-dir", metaDir)
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Command failed: %v\nOutput: %s", err, string(output))
	}

	// Verify exit code
	if cmd.ProcessState.ExitCode() != 0 {
		t.Errorf("Expected exit code 0, got %d", cmd.ProcessState.ExitCode())
	}

	outputStr := string(output)

	// Verify output contains expected sections
	expectedInOutput := []string{
		"Running evaluation",
		"Meta-Evaluation Report",
		"yokay-test-agent",
		"TST-001",
		"Accuracy",
		"Consistency",
	}

	for _, expected := range expectedInOutput {
		if !strings.Contains(outputStr, expected) {
			t.Errorf("Output missing expected text: %s\nGot: %s", expected, outputStr)
		}
	}
}

// TestMetaCommandWithKOverride tests that --k flag overrides YAML k value
func TestMetaCommandWithKOverride(t *testing.T) {
	// Build the binary first
	binaryPath := buildBinary(t)
	defer os.Remove(binaryPath)

	// Setup
	tmpDir := t.TempDir()
	metaDir := filepath.Join(tmpDir, "meta")
	agentDir := filepath.Join(metaDir, "agents", "test-agent")
	err := os.MkdirAll(agentDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test agent dir: %v", err)
	}

	// Write eval.yaml with k=3
	sampleEval := `agent: yokay-test-agent
consistency_threshold: 0.95

test_cases:
  - id: TST-001
    name: "Test case"
    input:
      task_title: "Test"
      task_description: "Test description"
      implementation: "code"
    expected: PASS
    k: 3
    rationale: "Should pass"
`
	evalPath := filepath.Join(agentDir, "eval.yaml")
	err = os.WriteFile(evalPath, []byte(sampleEval), 0644)
	if err != nil {
		t.Fatalf("Failed to write test eval.yaml: %v", err)
	}

	// Execute with --k 10 (should override YAML k=3)
	cmd := exec.Command(binaryPath, "meta", "--agent", "test-agent", "--k", "10", "--meta-dir", metaDir)
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Command failed: %v\nOutput: %s", err, string(output))
	}

	// Verify exit code
	if cmd.ProcessState.ExitCode() != 0 {
		t.Errorf("Expected exit code 0, got %d", cmd.ProcessState.ExitCode())
	}

	// The output should show consistency as 10/10 (if all runs agree)
	// Since we're using stub execution that returns expected value, all should agree
	outputStr := string(output)
	if !strings.Contains(outputStr, "10/10 consistent") {
		t.Errorf("Expected to see '10/10 consistent' in output (k override). Got: %s", outputStr)
	}
}

// TestMetaCommandInvalidAgent tests error handling for non-existent agent
func TestMetaCommandInvalidAgent(t *testing.T) {
	// Build the binary first
	binaryPath := buildBinary(t)
	defer os.Remove(binaryPath)

	tmpDir := t.TempDir()
	metaDir := filepath.Join(tmpDir, "meta")
	err := os.MkdirAll(metaDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create meta dir: %v", err)
	}

	// Execute with non-existent agent
	cmd := exec.Command(binaryPath, "meta", "--agent", "nonexistent-agent", "--meta-dir", metaDir)
	output, err := cmd.CombinedOutput()

	// Verify non-zero exit code
	if err == nil {
		t.Fatal("Expected command to fail with non-existent agent")
	}

	if cmd.ProcessState.ExitCode() == 0 {
		t.Error("Expected non-zero exit code for invalid agent")
	}

	// Verify error message
	outputStr := string(output)
	if !strings.Contains(outputStr, "eval.yaml not found") {
		t.Errorf("Expected error about eval.yaml not found. Got: %s", outputStr)
	}
}

// TestMetaCommandNoSuiteOrAgent tests error handling when neither suite nor agent specified
func TestMetaCommandNoSuiteOrAgent(t *testing.T) {
	// Build the binary first
	binaryPath := buildBinary(t)
	defer os.Remove(binaryPath)

	tmpDir := t.TempDir()
	metaDir := filepath.Join(tmpDir, "meta")
	err := os.MkdirAll(metaDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create meta dir: %v", err)
	}

	// Execute without --suite or --agent
	cmd := exec.Command(binaryPath, "meta", "--meta-dir", metaDir)
	output, err := cmd.CombinedOutput()

	// Verify non-zero exit code
	if err == nil {
		t.Fatal("Expected command to fail when neither suite nor agent specified")
	}

	if cmd.ProcessState.ExitCode() == 0 {
		t.Error("Expected non-zero exit code when neither suite nor agent specified")
	}

	// Verify error message
	outputStr := string(output)
	if !strings.Contains(outputStr, "must specify either --suite or --agent") {
		t.Errorf("Expected error about missing suite/agent. Got: %s", outputStr)
	}
}

// TestUnknownCommand tests error handling for unknown commands
func TestUnknownCommand(t *testing.T) {
	// Build the binary first
	binaryPath := buildBinary(t)
	defer os.Remove(binaryPath)

	// Execute with unknown command
	cmd := exec.Command(binaryPath, "unknown-command")
	output, err := cmd.CombinedOutput()

	// Verify non-zero exit code
	if err == nil {
		t.Fatal("Expected command to fail with unknown command")
	}

	if cmd.ProcessState.ExitCode() == 0 {
		t.Error("Expected non-zero exit code for unknown command")
	}

	// Verify error message
	outputStr := string(output)
	if !strings.Contains(outputStr, "Unknown command") {
		t.Errorf("Expected 'Unknown command' error. Got: %s", outputStr)
	}
}

// TestNoCommand tests error handling when no command is provided
func TestNoCommand(t *testing.T) {
	// Build the binary first
	binaryPath := buildBinary(t)
	defer os.Remove(binaryPath)

	// Execute with no arguments
	cmd := exec.Command(binaryPath)
	output, err := cmd.CombinedOutput()

	// Verify non-zero exit code
	if err == nil {
		t.Fatal("Expected command to fail with no arguments")
	}

	if cmd.ProcessState.ExitCode() == 0 {
		t.Error("Expected non-zero exit code when no command provided")
	}

	// Verify usage message
	outputStr := string(output)
	if !strings.Contains(outputStr, "Usage") {
		t.Errorf("Expected usage message. Got: %s", outputStr)
	}

	// Should show available commands
	if !strings.Contains(outputStr, "grade-skills") || !strings.Contains(outputStr, "meta") {
		t.Errorf("Expected to show available commands. Got: %s", outputStr)
	}
}

// TestGradeSkillsCommandMultipleSkills tests grading multiple skills at once
func TestGradeSkillsCommandMultipleSkills(t *testing.T) {
	// Build the binary first
	binaryPath := buildBinary(t)
	defer os.Remove(binaryPath)

	// Setup: Create temp directory for test output
	tmpDir := t.TempDir()
	reportPath := filepath.Join(tmpDir, "multi-skill-report.md")

	// Create a test skills directory with multiple skills
	skillsDir := filepath.Join(tmpDir, "skills")

	skills := []struct {
		name    string
		content string
	}{
		{
			name: "skill-alpha",
			content: `---
name: skill-alpha
description: First test skill
---

# Skill Alpha

Clear instructions here.

## Instructions

1. Step one
2. Step two

## Examples

Example usage.
`,
		},
		{
			name: "skill-beta",
			content: `---
name: skill-beta
description: Second test skill
---

# Skill Beta

More clear instructions.

## Instructions

1. First action
2. Second action

## Examples

Example code.
`,
		},
		{
			name: "skill-gamma",
			content: `---
name: skill-gamma
description: Third test skill
---

# Skill Gamma

Comprehensive instructions.

## Instructions

1. Initial step
2. Follow-up step
3. Final step

## Examples

Detailed examples here.
`,
		},
	}

	for _, skill := range skills {
		skillDir := filepath.Join(skillsDir, skill.name)
		err := os.MkdirAll(skillDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create skill dir %s: %v", skill.name, err)
		}

		err = os.WriteFile(filepath.Join(skillDir, "SKILL.md"), []byte(skill.content), 0644)
		if err != nil {
			t.Fatalf("Failed to write skill %s: %v", skill.name, err)
		}
	}

	// Execute the binary
	cmd := exec.Command(binaryPath, "grade-skills", "--skills-dir", skillsDir, "--output", reportPath)
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Command failed: %v\nOutput: %s", err, string(output))
	}

	// Verify exit code
	if cmd.ProcessState.ExitCode() != 0 {
		t.Errorf("Expected exit code 0, got %d", cmd.ProcessState.ExitCode())
	}

	// Verify output mentions all skills
	outputStr := string(output)
	if !strings.Contains(outputStr, "Found 3 skills") {
		t.Errorf("Expected to find 3 skills. Got: %s", outputStr)
	}

	// Read and verify report content
	content, err := os.ReadFile(reportPath)
	if err != nil {
		t.Fatalf("Failed to read report: %v", err)
	}

	reportStr := string(content)

	// Verify all skills are in the report
	for _, skill := range skills {
		if !strings.Contains(reportStr, skill.name) {
			t.Errorf("Report missing skill: %s", skill.name)
		}
	}

	// Verify summary shows correct count
	if !strings.Contains(reportStr, "Total Skills**: 3") {
		t.Error("Report missing correct total skills count")
	}

	// Verify table has all skills
	if !strings.Contains(reportStr, "| 1 |") && !strings.Contains(reportStr, "| 2 |") && !strings.Contains(reportStr, "| 3 |") {
		t.Error("Report missing skill rankings")
	}
}

// TestMetaCommandMultipleTestCases tests running meta eval with multiple test cases
func TestMetaCommandMultipleTestCases(t *testing.T) {
	// Build the binary first
	binaryPath := buildBinary(t)
	defer os.Remove(binaryPath)

	// Setup
	tmpDir := t.TempDir()
	metaDir := filepath.Join(tmpDir, "meta")
	agentDir := filepath.Join(metaDir, "agents", "multi-test-agent")
	err := os.MkdirAll(agentDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test agent dir: %v", err)
	}

	// Write eval.yaml with multiple test cases
	sampleEval := `agent: yokay-multi-test-agent
consistency_threshold: 0.90

test_cases:
  - id: TC-001
    name: "First test case"
    input:
      task_title: "Task One"
      task_description: "Description one"
      implementation: "code one"
    expected: PASS
    k: 3
    rationale: "Should pass test one"

  - id: TC-002
    name: "Second test case"
    input:
      task_title: "Task Two"
      task_description: "Description two"
      implementation: "code two"
    expected: FAIL
    k: 3
    rationale: "Should fail test two"

  - id: TC-003
    name: "Third test case"
    input:
      task_title: "Task Three"
      task_description: "Description three"
      implementation: "code three"
    expected: PASS
    k: 5
    rationale: "Should pass test three"
`
	evalPath := filepath.Join(agentDir, "eval.yaml")
	err = os.WriteFile(evalPath, []byte(sampleEval), 0644)
	if err != nil {
		t.Fatalf("Failed to write test eval.yaml: %v", err)
	}

	// Execute the binary
	cmd := exec.Command(binaryPath, "meta", "--agent", "multi-test-agent", "--meta-dir", metaDir)
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Command failed: %v\nOutput: %s", err, string(output))
	}

	// Verify exit code
	if cmd.ProcessState.ExitCode() != 0 {
		t.Errorf("Expected exit code 0, got %d", cmd.ProcessState.ExitCode())
	}

	outputStr := string(output)

	// Verify output contains all test case IDs
	for _, id := range []string{"TC-001", "TC-002", "TC-003"} {
		if !strings.Contains(outputStr, id) {
			t.Errorf("Output missing test case ID: %s", id)
		}
	}

	// Verify test count
	if !strings.Contains(outputStr, "Test Cases: 3") {
		t.Error("Output missing correct test case count")
	}

	// Verify metrics are calculated
	if !strings.Contains(outputStr, "Accuracy") && !strings.Contains(outputStr, "Consistency") {
		t.Error("Output missing metrics")
	}
}

// buildBinary builds the yokay-evals binary and returns its path
// The binary is built in a temp directory and should be removed by the caller
func buildBinary(t *testing.T) string {
	t.Helper()

	tmpDir := t.TempDir()
	binaryPath := filepath.Join(tmpDir, "yokay-evals")

	// Build the binary
	cmd := exec.Command("go", "build", "-o", binaryPath, ".")
	cmd.Dir = "/Users/sis4m4/Projects/stevestomp/pokayokay/yokay-evals/cmd/yokay-evals"
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Failed to build binary: %v\nOutput: %s", err, string(output))
	}

	return binaryPath
}
