package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestRunReportCommandNoReports tests error handling when no reports exist
func TestRunReportCommandNoReports(t *testing.T) {
	tmpDir := t.TempDir()
	reportsDir := filepath.Join(tmpDir, "reports")
	err := os.MkdirAll(reportsDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test directory: %v", err)
	}

	err = runReportCommand("grade", "markdown", false, "", reportsDir)
	if err == nil {
		t.Fatalf("Expected error when no reports found, got nil")
	}
	if !strings.Contains(err.Error(), "no grade reports found") {
		t.Errorf("Expected error about missing reports, got: %v", err)
	}
}

// TestRunReportCommandInvalidFormat tests error handling for unsupported format
func TestRunReportCommandInvalidFormat(t *testing.T) {
	tmpDir := t.TempDir()
	reportsDir := filepath.Join(tmpDir, "reports")
	err := os.MkdirAll(reportsDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test directory: %v", err)
	}

	reportPath := filepath.Join(reportsDir, "skill-clarity-2026-01-26.md")
	reportContent := `# Skill Clarity Report
Generated: 2026-01-26 21:30:43
## Summary
- **Total Skills**: 1
- **Average Score**: 75.0/100
- **Pass Rate**: 100.0% (1/1)
- **Passing Threshold**: 70.0
`
	err = os.WriteFile(reportPath, []byte(reportContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	err = runReportCommand("grade", "xml", false, "", reportsDir)
	if err == nil {
		t.Fatalf("Expected error for unsupported format, got nil")
	}
	if !strings.Contains(err.Error(), "unsupported format") {
		t.Errorf("Expected error about unsupported format, got: %v", err)
	}
}

// TestRunReportCommandUnsupportedType tests error handling for unsupported report type
func TestRunReportCommandUnsupportedType(t *testing.T) {
	tmpDir := t.TempDir()
	reportsDir := filepath.Join(tmpDir, "reports")
	err := os.MkdirAll(reportsDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test directory: %v", err)
	}

	reportPath := filepath.Join(reportsDir, "skill-clarity-2026-01-26.md")
	reportContent := `# Skill Clarity Report
Generated: 2026-01-26 21:30:43
## Summary
- **Total Skills**: 1
- **Average Score**: 75.0/100
- **Pass Rate**: 100.0% (1/1)
- **Passing Threshold**: 70.0
`
	err = os.WriteFile(reportPath, []byte(reportContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	err = runReportCommand("evaluation", "markdown", false, "", reportsDir)
	if err == nil {
		t.Fatalf("Expected error for unsupported report type, got nil")
	}
	if !strings.Contains(err.Error(), "not yet implemented") {
		t.Errorf("Expected error about unsupported type, got: %v", err)
	}
}

// TestFindGradeReportsDirectoryError tests error handling when directory doesn't exist
func TestFindGradeReportsDirectoryError(t *testing.T) {
	// Use a non-existent directory path
	nonExistentDir := filepath.Join(t.TempDir(), "does-not-exist")

	// Test: Try to find reports in non-existent directory
	reports, err := findGradeReports(nonExistentDir)

	// Verify: Should return error
	if err == nil {
		t.Error("Expected error when directory doesn't exist, got nil")
	}

	// Verify: Should return empty reports list
	if len(reports) != 0 {
		t.Errorf("Expected 0 reports, got %d", len(reports))
	}
}

// TestParseGradeReportInvalidContent tests behavior with invalid report content
func TestParseGradeReportInvalidContent(t *testing.T) {
	// Create a temporary report file with invalid content (missing fields)
	tmpDir := t.TempDir()
	reportPath := filepath.Join(tmpDir, "skill-clarity-2026-01-26.md")

	// Create report with missing required fields
	reportContent := `# Some Random Document

This is not a valid skill clarity report.
It doesn't have the expected structure.
`
	err := os.WriteFile(reportPath, []byte(reportContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test report: %v", err)
	}

	// Test: Parse the invalid report
	report, err := parseGradeReport(reportPath)

	// Verify: Should not return an error (parseGradeReport is lenient)
	// but the report should have zero values for missing fields
	if err != nil {
		t.Fatalf("parseGradeReport should not error on invalid content, got: %v", err)
	}

	// Verify: Report should have zero values for missing metrics
	if report.TotalSkills != 0 {
		t.Errorf("Expected TotalSkills=0 for invalid content, got %d", report.TotalSkills)
	}

	if report.AverageScore != 0 {
		t.Errorf("Expected AverageScore=0 for invalid content, got %.1f", report.AverageScore)
	}

	if report.PassRate != 0 {
		t.Errorf("Expected PassRate=0 for invalid content, got %.1f", report.PassRate)
	}
}

// TestParseGradeReportFileNotFound tests error handling when report file doesn't exist
func TestParseGradeReportFileNotFound(t *testing.T) {
	// Use a non-existent file path
	nonExistentPath := filepath.Join(t.TempDir(), "does-not-exist.md")

	// Test: Try to parse non-existent file
	_, err := parseGradeReport(nonExistentPath)

	// Verify: Should return error
	if err == nil {
		t.Error("Expected error when file doesn't exist, got nil")
	}

	if err != nil && !strings.Contains(err.Error(), "reading report") {
		t.Errorf("Expected 'reading report' error, got: %v", err)
	}
}

// TestRunReportCommandWithOutputFile tests writing report to a file
func TestRunReportCommandWithOutputFile(t *testing.T) {
	// Create temporary directory with a valid report
	tmpDir := t.TempDir()
	reportsDir := filepath.Join(tmpDir, "reports")
	err := os.MkdirAll(reportsDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test directory: %v", err)
	}

	reportPath := filepath.Join(reportsDir, "skill-clarity-2026-01-26.md")
	reportContent := `# Skill Clarity Report
Generated: 2026-01-26 21:30:43
## Summary
- **Total Skills**: 5
- **Average Score**: 80.0/100
- **Pass Rate**: 100.0% (5/5)
- **Passing Threshold**: 70.0
`
	err = os.WriteFile(reportPath, []byte(reportContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Test: Run report command with output file
	outputFile := filepath.Join(tmpDir, "output.md")
	err = runReportCommand("grade", "markdown", false, outputFile, reportsDir)
	if err != nil {
		t.Fatalf("runReportCommand with output file failed: %v", err)
	}

	// Verify: Output file exists and has content
	content, err := os.ReadFile(outputFile)
	if err != nil {
		t.Fatalf("Failed to read output file: %v", err)
	}

	if len(content) == 0 {
		t.Error("Output file is empty")
	}

	if !strings.Contains(string(content), "Evaluation Report Summary") {
		t.Error("Output file doesn't contain expected report header")
	}
}

// TestRunReportCommandListModeWithOutputFile tests list mode with output file
func TestRunReportCommandListModeWithOutputFile(t *testing.T) {
	// Create temporary directory with test reports
	tmpDir := t.TempDir()
	reportsDir := filepath.Join(tmpDir, "reports")
	err := os.MkdirAll(reportsDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test directory: %v", err)
	}

	// Create test reports
	testFiles := []string{
		"skill-clarity-2026-01-26.md",
		"skill-clarity-2026-01-25.md",
	}

	for _, filename := range testFiles {
		path := filepath.Join(reportsDir, filename)
		err := os.WriteFile(path, []byte("# Test Report\n"), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file: %v", err)
		}
	}

	// Test: Run report command in list mode with output file
	outputFile := filepath.Join(tmpDir, "list.md")
	err = runReportCommand("grade", "markdown", true, outputFile, reportsDir)
	if err != nil {
		t.Fatalf("runReportCommand list mode with output file failed: %v", err)
	}

	// Verify: Output file exists and contains report list
	content, err := os.ReadFile(outputFile)
	if err != nil {
		t.Fatalf("Failed to read output file: %v", err)
	}

	if !strings.Contains(string(content), "Grade Reports") {
		t.Error("Output file doesn't contain 'Grade Reports' header")
	}

	for _, filename := range testFiles {
		if !strings.Contains(string(content), filename) {
			t.Errorf("Output file doesn't contain report: %s", filename)
		}
	}
}

// TestRunReportCommandJSONFormat tests JSON output format
func TestRunReportCommandJSONFormat(t *testing.T) {
	// Create temporary directory with a valid report
	tmpDir := t.TempDir()
	reportsDir := filepath.Join(tmpDir, "reports")
	err := os.MkdirAll(reportsDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test directory: %v", err)
	}

	reportPath := filepath.Join(reportsDir, "skill-clarity-2026-01-26.md")
	reportContent := `# Skill Clarity Report
Generated: 2026-01-26 21:30:43
## Summary
- **Total Skills**: 5
- **Average Score**: 80.0/100
- **Pass Rate**: 100.0% (5/5)
- **Passing Threshold**: 70.0
`
	err = os.WriteFile(reportPath, []byte(reportContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}

	// Test: Run report command with JSON format and output file
	outputFile := filepath.Join(tmpDir, "output.json")
	err = runReportCommand("grade", "json", false, outputFile, reportsDir)
	if err != nil {
		t.Fatalf("runReportCommand with JSON format failed: %v", err)
	}

	// Verify: Output file exists and is valid JSON
	content, err := os.ReadFile(outputFile)
	if err != nil {
		t.Fatalf("Failed to read output file: %v", err)
	}

	if len(content) == 0 {
		t.Error("Output file is empty")
	}

	// Verify it's valid JSON
	if !strings.HasPrefix(strings.TrimSpace(string(content)), "{") {
		t.Error("Output doesn't appear to be JSON")
	}
}
