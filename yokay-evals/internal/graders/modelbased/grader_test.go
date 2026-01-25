package modelbased

import (
	"testing"
)

// TestGraderInterface verifies that SkillClarityGrader implements Grader interface
func TestGraderInterface(t *testing.T) {
	var _ Grader = (*SkillClarityGrader)(nil)
}

// TestResult verifies Result struct structure
func TestResult(t *testing.T) {
	result := Result{
		Passed:  true,
		Score:   85.5,
		Message: "Test message",
		Details: map[string]any{
			"key": "value",
		},
	}

	if !result.Passed {
		t.Error("Expected Passed to be true")
	}
	if result.Score != 85.5 {
		t.Errorf("Expected Score to be 85.5, got %f", result.Score)
	}
	if result.Message != "Test message" {
		t.Errorf("Expected Message to be 'Test message', got %s", result.Message)
	}
	if result.Details["key"] != "value" {
		t.Error("Expected Details to contain key-value pair")
	}
}

// TestGradeInput verifies GradeInput struct structure
func TestGradeInput(t *testing.T) {
	input := GradeInput{
		Content: "test content",
		Context: map[string]any{
			"key": "value",
		},
	}

	if input.Content != "test content" {
		t.Errorf("Expected Content to be 'test content', got %s", input.Content)
	}
	if input.Context["key"] != "value" {
		t.Error("Expected Context to contain key-value pair")
	}
}
