package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"testing"
)

// TestFindGradeReports verifies that findGradeReports can locate skill-clarity reports
func TestFindGradeReports(t *testing.T) {
	// Create a temporary directory with test reports
	tmpDir := t.TempDir()
	reportsDir := filepath.Join(tmpDir, "reports")
	err := os.MkdirAll(reportsDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test reports dir: %v", err)
	}

	// Create test report files
	testFiles := []string{
		"skill-clarity-2026-01-25.md",
		"skill-clarity-2026-01-26.md",
		"skill-clarity-2026-01-24.md",
		"other-report.md", // Should not be included
	}

	for _, filename := range testFiles {
		path := filepath.Join(reportsDir, filename)
		err := os.WriteFile(path, []byte("# Test Report\n"), 0644)
		if err != nil {
			t.Fatalf("Failed to create test file: %v", err)
		}
	}

	// Test: Find grade reports
	reports, err := findGradeReports(reportsDir)
	if err != nil {
		t.Fatalf("findGradeReports failed: %v", err)
	}

	// Verify: Should find 3 skill-clarity reports, sorted by date (newest first)
	expectedCount := 3
	if len(reports) != expectedCount {
		t.Errorf("Expected %d reports, got %d", expectedCount, len(reports))
	}

	// Verify: Reports should be sorted by date (newest first)
	expectedOrder := []string{
		"skill-clarity-2026-01-26.md",
		"skill-clarity-2026-01-25.md",
		"skill-clarity-2026-01-24.md",
	}

	for i, expected := range expectedOrder {
		if i >= len(reports) {
			break
		}
		if filepath.Base(reports[i]) != expected {
			t.Errorf("Report %d: expected %s, got %s", i, expected, filepath.Base(reports[i]))
		}
	}
}

// TestParseGradeReport verifies that parseGradeReport can extract metrics from a report file
func TestParseGradeReport(t *testing.T) {
	// Create a temporary report file with known content
	tmpDir := t.TempDir()
	reportPath := filepath.Join(tmpDir, "skill-clarity-2026-01-26.md")

	reportContent := `# Skill Clarity Report

Generated: 2026-01-26 21:30:43

This report evaluates pokayokay skills using the Skill Clarity Grader.
**Note**: Current grading uses heuristic-based evaluation (stub implementation). LLM-based grading not yet implemented.

## Summary

- **Total Skills**: 27
- **Average Score**: 60.3/100
- **Pass Rate**: 3.7% (1/27)
- **Passing Threshold**: 70.0

## Skills Below Threshold (< 80%)

These skills need improvement:

- **ux-design** - 75.0/100 - Needs Improvement
- **documentation** - 68.0/100 - **FAILED**
`

	err := os.WriteFile(reportPath, []byte(reportContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test report: %v", err)
	}

	// Test: Parse the report
	report, err := parseGradeReport(reportPath)
	if err != nil {
		t.Fatalf("parseGradeReport failed: %v", err)
	}

	// Verify: Extracted metrics are correct
	if report.TotalSkills != 27 {
		t.Errorf("Expected TotalSkills=27, got %d", report.TotalSkills)
	}

	if report.AverageScore != 60.3 {
		t.Errorf("Expected AverageScore=60.3, got %.1f", report.AverageScore)
	}

	expectedPassRate := 3.7
	if report.PassRate != expectedPassRate {
		t.Errorf("Expected PassRate=%.1f, got %.1f", expectedPassRate, report.PassRate)
	}

	if report.PassingThreshold != 70.0 {
		t.Errorf("Expected PassingThreshold=70.0, got %.1f", report.PassingThreshold)
	}

	// Verify: GeneratedDate is extracted
	if !strings.Contains(report.GeneratedDate, "2026-01-26") {
		t.Errorf("Expected GeneratedDate to contain '2026-01-26', got '%s'", report.GeneratedDate)
	}
}

// TestFormatReportSummaryMarkdown verifies markdown formatting of report summary
func TestFormatReportSummaryMarkdown(t *testing.T) {
	report := GradeReport{
		FilePath:         "/path/to/skill-clarity-2026-01-26.md",
		GeneratedDate:    "2026-01-26 21:30:43",
		TotalSkills:      27,
		AverageScore:     60.3,
		PassRate:         3.7,
		PassingThreshold: 70.0,
	}

	// Test: Format as markdown
	output := formatReportSummaryMarkdown(report)

	// Verify: Output contains key metrics
	expectedStrings := []string{
		"# Evaluation Report Summary",
		"skill-clarity-2026-01-26.md",
		"2026-01-26 21:30:43",
		"27",
		"60.3",
		"3.7%",
		"70.0",
	}

	for _, expected := range expectedStrings {
		if !strings.Contains(output, expected) {
			t.Errorf("Expected output to contain '%s'", expected)
		}
	}
}

// TestFormatReportSummaryJSON verifies JSON formatting of report summary
func TestFormatReportSummaryJSON(t *testing.T) {
	report := GradeReport{
		FilePath:         "/path/to/skill-clarity-2026-01-26.md",
		GeneratedDate:    "2026-01-26 21:30:43",
		TotalSkills:      27,
		AverageScore:     60.3,
		PassRate:         3.7,
		PassingThreshold: 70.0,
	}

	// Test: Format as JSON
	output, err := formatReportSummaryJSON(report)
	if err != nil {
		t.Fatalf("formatReportSummaryJSON failed: %v", err)
	}

	// Verify: Output is valid JSON
	var parsed map[string]interface{}
	if err := json.Unmarshal([]byte(output), &parsed); err != nil {
		t.Fatalf("Output is not valid JSON: %v", err)
	}

	// Verify: JSON contains expected fields
	if parsed["file_path"] != report.FilePath {
		t.Errorf("Expected file_path=%s, got %v", report.FilePath, parsed["file_path"])
	}

	if parsed["total_skills"] != float64(27) {
		t.Errorf("Expected total_skills=27, got %v", parsed["total_skills"])
	}
}

// TestListGradeReports verifies that listGradeReports outputs correct format
func TestListGradeReports(t *testing.T) {
	// Create temporary directory with test reports
	tmpDir := t.TempDir()
	reportsDir := filepath.Join(tmpDir, "reports")
	err := os.MkdirAll(reportsDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test reports dir: %v", err)
	}

	// Create test report files
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

	// Test: List grade reports
	output := listGradeReports(reportsDir)

	// Verify: Output contains both reports
	for _, filename := range testFiles {
		if !strings.Contains(output, filename) {
			t.Errorf("Expected output to contain '%s'", filename)
		}
	}

	// Verify: Output has header
	if !strings.Contains(output, "Grade Reports") {
		t.Error("Expected output to have 'Grade Reports' header")
	}
}

// TestRunReportCommand verifies the main report command execution
func TestRunReportCommand(t *testing.T) {
	// Create temporary directory structure
	tmpDir := t.TempDir()
	reportsDir := filepath.Join(tmpDir, "reports")
	err := os.MkdirAll(reportsDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test reports dir: %v", err)
	}

	// Create a test report with valid content
	reportPath := filepath.Join(reportsDir, "skill-clarity-2026-01-26.md")
	reportContent := `# Skill Clarity Report

Generated: 2026-01-26 21:30:43

## Summary

- **Total Skills**: 10
- **Average Score**: 75.5/100
- **Pass Rate**: 80.0% (8/10)
- **Passing Threshold**: 70.0
`

	err = os.WriteFile(reportPath, []byte(reportContent), 0644)
	if err != nil {
		t.Fatalf("Failed to create test report: %v", err)
	}

	// Test: Run report command with grade type
	err = runReportCommand("grade", "markdown", false, "", reportsDir)
	if err != nil {
		t.Fatalf("runReportCommand failed: %v", err)
	}

	// Note: Since runReportCommand outputs to stdout, we can't easily capture
	// the output in this test. In a real implementation, we'd refactor to
	// accept an io.Writer for testability.
}

// TestRunReportCommandListMode verifies list mode
func TestRunReportCommandListMode(t *testing.T) {
	// Create temporary directory structure
	tmpDir := t.TempDir()
	reportsDir := filepath.Join(tmpDir, "reports")
	err := os.MkdirAll(reportsDir, 0755)
	if err != nil {
		t.Fatalf("Failed to create test reports dir: %v", err)
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

	// Test: Run report command in list mode
	err = runReportCommand("grade", "markdown", true, "", reportsDir)
	if err != nil {
		t.Fatalf("runReportCommand in list mode failed: %v", err)
	}
}
