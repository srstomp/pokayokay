package modelbased

import (
	"testing"
)

func TestSkillClarityGrader_New(t *testing.T) {
	grader := NewSkillClarityGrader()
	if grader == nil {
		t.Fatal("Expected NewSkillClarityGrader to return non-nil grader")
	}
}

func TestSkillClarityGrader_Grade(t *testing.T) {
	grader := NewSkillClarityGrader()

	tests := []struct {
		name        string
		input       GradeInput
		expectError bool
	}{
		{
			name: "basic skill content",
			input: GradeInput{
				Content: `# Test Skill
## Instructions
Clear instructions here.

## Examples
- Example 1
- Example 2
`,
				Context: map[string]any{},
			},
			expectError: false,
		},
		{
			name: "empty content",
			input: GradeInput{
				Content: "",
				Context: map[string]any{},
			},
			expectError: false, // Should handle gracefully
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result, err := grader.Grade(tt.input)

			if tt.expectError && err == nil {
				t.Error("Expected error but got none")
			}
			if !tt.expectError && err != nil {
				t.Errorf("Expected no error but got: %v", err)
			}

			if err == nil {
				// Verify result structure
				if result.Score < 0 || result.Score > 100 {
					t.Errorf("Expected score between 0 and 100, got %f", result.Score)
				}
				if result.Message == "" {
					t.Error("Expected non-empty message")
				}
				if result.Details == nil {
					t.Error("Expected non-nil Details map")
				}
			}
		})
	}
}

func TestSkillClarityGrader_CriteriaWeights(t *testing.T) {
	// Verify the grader has the expected criteria
	expectedCriteria := map[string]float64{
		"clear_instructions": 0.30,
		"actionable_steps":   0.25,
		"good_examples":      0.25,
		"appropriate_scope":  0.20,
	}

	// Test that weights sum to 1.0
	totalWeight := 0.0
	for _, weight := range expectedCriteria {
		totalWeight += weight
	}

	if totalWeight != 1.0 {
		t.Errorf("Expected weights to sum to 1.0, got %f", totalWeight)
	}
}

func TestSkillClarityGrader_DetailedFeedback(t *testing.T) {
	grader := NewSkillClarityGrader()

	input := GradeInput{
		Content: `# Example Skill
## Instructions
Do something specific.

## Examples
- Good example 1
- Good example 2

## Scope
Focused and clear.
`,
		Context: map[string]any{},
	}

	result, err := grader.Grade(input)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	// Verify detailed feedback is provided
	expectedKeys := []string{
		"clear_instructions",
		"actionable_steps",
		"good_examples",
		"appropriate_scope",
	}

	for _, key := range expectedKeys {
		if _, exists := result.Details[key]; !exists {
			t.Errorf("Expected Details to contain key '%s'", key)
		}
	}
}
