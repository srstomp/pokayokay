package modelbased

import (
	"fmt"
	"strings"
)

// SkillClarityGrader evaluates skill documentation against clarity criteria
type SkillClarityGrader struct {
	// Criteria weights for evaluation
	weights map[string]float64
	// Passing threshold (0-100)
	passingScore float64
}

// Criterion represents a single evaluation criterion with its score and feedback
type Criterion struct {
	Score    float64
	Feedback string
}

// NewSkillClarityGrader creates a new skill clarity grader with default weights
func NewSkillClarityGrader() *SkillClarityGrader {
	return &SkillClarityGrader{
		weights: map[string]float64{
			"clear_instructions": 0.30, // 30% - Are instructions unambiguous?
			"actionable_steps":   0.25, // 25% - Are steps concrete and executable?
			"good_examples":      0.25, // 25% - Are examples helpful and realistic?
			"appropriate_scope":  0.20, // 20% - Is the skill focused, not too broad/narrow?
		},
		passingScore: 70.0, // Default passing threshold
	}
}

// Grade evaluates skill content against clarity criteria
func (g *SkillClarityGrader) Grade(input GradeInput) (Result, error) {
	// Stub implementation - will be replaced with LLM-based evaluation
	criteria := g.evaluateCriteria(input.Content)

	// Calculate weighted score
	totalScore := 0.0
	for criterionName, criterionResult := range criteria {
		weight := g.weights[criterionName]
		totalScore += criterionResult.Score * weight
	}

	// Build detailed feedback
	details := make(map[string]any)
	for name, criterion := range criteria {
		details[name] = map[string]any{
			"score":    criterion.Score,
			"feedback": criterion.Feedback,
			"weight":   g.weights[name],
		}
	}

	// Generate summary message
	message := g.generateMessage(totalScore, criteria)

	return Result{
		Passed:  totalScore >= g.passingScore,
		Score:   totalScore,
		Message: message,
		Details: details,
	}, nil
}

// evaluateCriteria performs stub evaluation of each criterion
// TODO: Replace with LLM-based evaluation
func (g *SkillClarityGrader) evaluateCriteria(content string) map[string]Criterion {
	// Stub implementation using basic heuristics
	// This will be replaced with LLM calls in the future

	criteria := make(map[string]Criterion)

	// Clear Instructions - check for instruction markers
	instructionScore := 50.0 // default neutral score
	instructionFeedback := "Stub evaluation: Instructions clarity not yet evaluated by LLM"
	if strings.Contains(strings.ToLower(content), "instruction") {
		instructionScore = 75.0
		instructionFeedback = "Stub evaluation: Found instruction section"
	}
	if content == "" {
		instructionScore = 0.0
		instructionFeedback = "Stub evaluation: Empty content"
	}
	criteria["clear_instructions"] = Criterion{
		Score:    instructionScore,
		Feedback: instructionFeedback,
	}

	// Actionable Steps - check for step indicators
	stepsScore := 50.0
	stepsFeedback := "Stub evaluation: Actionable steps not yet evaluated by LLM"
	if strings.Contains(content, "-") || strings.Contains(content, "1.") {
		stepsScore = 75.0
		stepsFeedback = "Stub evaluation: Found step-like markers"
	}
	if content == "" {
		stepsScore = 0.0
		stepsFeedback = "Stub evaluation: Empty content"
	}
	criteria["actionable_steps"] = Criterion{
		Score:    stepsScore,
		Feedback: stepsFeedback,
	}

	// Good Examples - check for example markers
	examplesScore := 50.0
	examplesFeedback := "Stub evaluation: Examples quality not yet evaluated by LLM"
	if strings.Contains(strings.ToLower(content), "example") {
		examplesScore = 75.0
		examplesFeedback = "Stub evaluation: Found example section"
	}
	if content == "" {
		examplesScore = 0.0
		examplesFeedback = "Stub evaluation: Empty content"
	}
	criteria["good_examples"] = Criterion{
		Score:    examplesScore,
		Feedback: examplesFeedback,
	}

	// Appropriate Scope - basic content length check
	scopeScore := 50.0
	scopeFeedback := "Stub evaluation: Scope appropriateness not yet evaluated by LLM"
	contentLength := len(content)
	if contentLength > 100 && contentLength < 5000 {
		scopeScore = 75.0
		scopeFeedback = "Stub evaluation: Content length seems reasonable"
	} else if contentLength == 0 {
		scopeScore = 0.0
		scopeFeedback = "Stub evaluation: Empty content"
	} else if contentLength >= 5000 {
		scopeScore = 40.0
		scopeFeedback = "Stub evaluation: Content might be too broad"
	} else {
		scopeScore = 40.0
		scopeFeedback = "Stub evaluation: Content might be too narrow"
	}
	criteria["appropriate_scope"] = Criterion{
		Score:    scopeScore,
		Feedback: scopeFeedback,
	}

	return criteria
}

// generateMessage creates a human-readable summary message
func (g *SkillClarityGrader) generateMessage(score float64, criteria map[string]Criterion) string {
	if score >= g.passingScore {
		return fmt.Sprintf("Skill clarity evaluation passed with score %.1f/100. Note: Using stub evaluation; LLM-based grading not yet implemented.", score)
	}

	// Find weakest criterion
	weakestName := ""
	weakestScore := 100.0
	for name, criterion := range criteria {
		if criterion.Score < weakestScore {
			weakestScore = criterion.Score
			weakestName = name
		}
	}

	return fmt.Sprintf("Skill clarity evaluation failed with score %.1f/100. Weakest area: %s (%.1f). Note: Using stub evaluation; LLM-based grading not yet implemented.",
		score, weakestName, weakestScore)
}
