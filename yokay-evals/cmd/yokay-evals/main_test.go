package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestGradeSkillsCommand(t *testing.T) {
	// Setup: Create temp directory for test output
	tmpDir := t.TempDir()
	reportPath := filepath.Join(tmpDir, "test-report.md")

	// Create a test skills directory with sample skills
	skillsDir := filepath.Join(tmpDir, "skills")
	err := os.MkdirAll(filepath.Join(skillsDir, "test-skill"), 0755)
	if err != nil {
		t.Fatalf("Failed to create test skills dir: %v", err)
	}

	// Write a sample skill file
	sampleSkill := `---
name: test-skill
description: A test skill for validation
---

# Test Skill

This is a test skill with clear instructions.

## Instructions

1. First step
2. Second step

## Examples

Here's an example of how to use this skill.
`
	err = os.WriteFile(filepath.Join(skillsDir, "test-skill", "SKILL.md"), []byte(sampleSkill), 0644)
	if err != nil {
		t.Fatalf("Failed to write test skill: %v", err)
	}

	// Execute the grading function
	err = gradeSkills(skillsDir, reportPath)
	if err != nil {
		t.Fatalf("gradeSkills failed: %v", err)
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
		"test-skill",
	}

	for _, section := range expectedSections {
		if !strings.Contains(reportStr, section) {
			t.Errorf("Report missing expected section: %s", section)
		}
	}

	// Verify report contains statistics (note: no colon after "Average Score")
	if !strings.Contains(reportStr, "Average Score") {
		t.Error("Report missing average score")
	}
	if !strings.Contains(reportStr, "Pass Rate") {
		t.Error("Report missing pass rate")
	}
}

func TestFindSkillFiles(t *testing.T) {
	// Setup: Create temp directory with multiple skills
	tmpDir := t.TempDir()

	skills := []string{"skill1", "skill2", "skill3"}
	for _, skill := range skills {
		skillDir := filepath.Join(tmpDir, skill)
		err := os.MkdirAll(skillDir, 0755)
		if err != nil {
			t.Fatalf("Failed to create skill dir %s: %v", skill, err)
		}

		err = os.WriteFile(filepath.Join(skillDir, "SKILL.md"), []byte("# "+skill), 0644)
		if err != nil {
			t.Fatalf("Failed to write SKILL.md for %s: %v", skill, err)
		}
	}

	// Execute
	files, err := findSkillFiles(tmpDir)
	if err != nil {
		t.Fatalf("findSkillFiles failed: %v", err)
	}

	// Verify
	if len(files) != 3 {
		t.Errorf("Expected 3 skill files, got %d", len(files))
	}

	// Verify all files end with SKILL.md
	for _, file := range files {
		if !strings.HasSuffix(file, "SKILL.md") {
			t.Errorf("File %s does not end with SKILL.md", file)
		}
	}
}

func TestGenerateReport(t *testing.T) {
	tmpDir := t.TempDir()
	reportPath := filepath.Join(tmpDir, "report.md")

	// Create sample grading results
	results := []skillResult{
		{
			Name:    "excellent-skill",
			Path:    "/path/to/excellent-skill/SKILL.md",
			Score:   85.0,
			Passed:  true,
			Message: "Excellent clarity",
			Details: map[string]any{
				"clear_instructions": map[string]any{
					"score":    90.0,
					"feedback": "Very clear",
					"weight":   0.30,
				},
			},
		},
		{
			Name:    "poor-skill",
			Path:    "/path/to/poor-skill/SKILL.md",
			Score:   45.0,
			Passed:  false,
			Message: "Needs improvement",
			Details: map[string]any{
				"clear_instructions": map[string]any{
					"score":    40.0,
					"feedback": "Unclear",
					"weight":   0.30,
				},
			},
		},
	}

	err := generateReport(results, reportPath)
	if err != nil {
		t.Fatalf("generateReport failed: %v", err)
	}

	// Verify report was created
	content, err := os.ReadFile(reportPath)
	if err != nil {
		t.Fatalf("Failed to read report: %v", err)
	}

	reportStr := string(content)

	// Debug: print report content
	t.Logf("Report content:\n%s", reportStr)

	// Verify both skills are in the report
	if !strings.Contains(reportStr, "excellent-skill") {
		t.Error("Report missing excellent-skill")
	}
	if !strings.Contains(reportStr, "poor-skill") {
		t.Error("Report missing poor-skill")
	}

	// Verify scores are present
	if !strings.Contains(reportStr, "85.0") {
		t.Error("Report missing excellent-skill score")
	}
	if !strings.Contains(reportStr, "45.0") {
		t.Error("Report missing poor-skill score")
	}

	// Verify summary statistics (note: no colon after "Average Score")
	if !strings.Contains(reportStr, "Average Score") {
		t.Error("Report missing average score")
	}
	if !strings.Contains(reportStr, "Pass Rate") {
		t.Error("Report missing pass rate")
	}

	// Verify skills below threshold are highlighted
	if !strings.Contains(reportStr, "Below Threshold") && !strings.Contains(reportStr, "Needs Improvement") {
		t.Error("Report not highlighting skills below threshold")
	}
}

func TestGenerateReportWithMalformedDetails(t *testing.T) {
	tmpDir := t.TempDir()
	reportPath := filepath.Join(tmpDir, "report.md")

	// Create results with various malformed Details structures
	results := []skillResult{
		{
			Name:    "missing-fields-skill",
			Path:    "/path/to/missing-fields/SKILL.md",
			Score:   75.0,
			Passed:  true,
			Message: "Has malformed details",
			Details: map[string]any{
				"clear_instructions": map[string]any{
					"score": 80.0,
					// Missing "feedback" and "weight" fields
				},
			},
		},
		{
			Name:    "wrong-type-skill",
			Path:    "/path/to/wrong-type/SKILL.md",
			Score:   70.0,
			Passed:  true,
			Message: "Has wrong type details",
			Details: map[string]any{
				"clear_instructions": map[string]any{
					"score":    "not-a-number", // Wrong type - should be float64
					"feedback": 123,            // Wrong type - should be string
					"weight":   "0.30",         // Wrong type - should be float64
				},
			},
		},
		{
			Name:    "not-a-map-skill",
			Path:    "/path/to/not-a-map/SKILL.md",
			Score:   80.0,
			Passed:  true,
			Message: "Has non-map details",
			Details: map[string]any{
				"clear_instructions": "not-a-map", // Should be map[string]any
			},
		},
		{
			Name:    "normal-skill",
			Path:    "/path/to/normal/SKILL.md",
			Score:   85.0,
			Passed:  true,
			Message: "Normal skill",
			Details: map[string]any{
				"clear_instructions": map[string]any{
					"score":    90.0,
					"feedback": "Very clear",
					"weight":   0.30,
				},
			},
		},
	}

	// Should not panic even with malformed details
	err := generateReport(results, reportPath)
	if err != nil {
		t.Fatalf("generateReport failed: %v", err)
	}

	// Verify report was created
	content, err := os.ReadFile(reportPath)
	if err != nil {
		t.Fatalf("Failed to read report: %v", err)
	}

	reportStr := string(content)

	// All skills should still appear in the report
	if !strings.Contains(reportStr, "missing-fields-skill") {
		t.Error("Report missing skill with missing fields")
	}
	if !strings.Contains(reportStr, "wrong-type-skill") {
		t.Error("Report missing skill with wrong type fields")
	}
	if !strings.Contains(reportStr, "not-a-map-skill") {
		t.Error("Report missing skill with non-map details")
	}
	if !strings.Contains(reportStr, "normal-skill") {
		t.Error("Report missing normal skill")
	}

	// Verify the normal skill's details are properly rendered
	if !strings.Contains(reportStr, "Very clear") {
		t.Error("Report missing feedback from normal skill")
	}
}
