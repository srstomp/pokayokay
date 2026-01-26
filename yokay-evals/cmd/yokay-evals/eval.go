package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"

	"github.com/stevestomp/yokay-evals/internal/harness"
	"gopkg.in/yaml.v3"
)

// FailureCase represents a documented agent failure case
type FailureCase struct {
	ID           string          `yaml:"id"`
	Category     string          `yaml:"category"`
	Discovered   string          `yaml:"discovered"`
	Severity     string          `yaml:"severity"`
	Context      FailureContext  `yaml:"context"`
	Failure      FailureDetails  `yaml:"failure"`
	Evidence     FailureEvidence `yaml:"evidence"`
	EvalCriteria []EvalCriterion `yaml:"eval_criteria"`
}

// FailureContext contains context about where/when the failure occurred
type FailureContext struct {
	Task      string `yaml:"task"`
	SessionID string `yaml:"session_id,omitempty"`
}

// FailureDetails describes what went wrong
type FailureDetails struct {
	Description string `yaml:"description"`
	RootCause   string `yaml:"root_cause"`
}

// FailureEvidence contains the evidence of the failure
type FailureEvidence struct {
	TaskSpec     string `yaml:"task_spec"`
	WhatWasBuilt string `yaml:"what_was_built"`
}

// EvalCriterion represents a single evaluation check
type EvalCriterion struct {
	Type  string `yaml:"type"`
	Check string `yaml:"check"`
}

// EvalResult represents the result of evaluating a failure case
type EvalResult struct {
	CaseID   string
	Category string
	Runs     []bool // Each run's pass/fail status
}

// CategoryMetrics represents evaluation metrics for a category
type CategoryMetrics struct {
	Total    int
	Pass     int
	Fail     int
	PassRate float64
}

// loadFailureCase loads and parses a failure case from a YAML file
func loadFailureCase(path string) (*FailureCase, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("reading failure case: %w", err)
	}

	var failureCase FailureCase
	if err := yaml.Unmarshal(data, &failureCase); err != nil {
		return nil, fmt.Errorf("parsing failure case: %w", err)
	}

	return &failureCase, nil
}

// findFailureCases finds all failure case YAML files in the failures directory
// If category is not empty, only returns cases matching that category
func findFailureCases(failuresDir string, category string) ([]FailureCase, error) {
	var cases []FailureCase

	// Walk the failures directory
	err := filepath.Walk(failuresDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Skip directories and non-YAML files
		if info.IsDir() || !strings.HasSuffix(info.Name(), ".yaml") {
			return nil
		}

		// Skip schema.yaml and template files
		if info.Name() == "schema.yaml" || strings.Contains(path, "examples") {
			return nil
		}

		// Load the failure case
		failureCase, err := loadFailureCase(path)
		if err != nil {
			// Skip files that can't be loaded (might be schema or other files)
			return nil
		}

		// Filter by category if specified
		if category != "" && failureCase.Category != category {
			return nil
		}

		cases = append(cases, *failureCase)
		return nil
	})

	if err != nil {
		return nil, err
	}

	return cases, nil
}

// runEvaluation runs evaluation on a failure case k times
// Each run is executed in an isolated context with its own temp directory
// For now, this is stubbed to always return pass
func runEvaluation(failureCase FailureCase, k int) (EvalResult, error) {
	result := EvalResult{
		CaseID:   failureCase.ID,
		Category: failureCase.Category,
		Runs:     make([]bool, k),
	}

	// Run evaluation k times, each in its own isolated context
	for i := 0; i < k; i++ {
		ctx, err := harness.NewIsolatedContext()
		if err != nil {
			return result, fmt.Errorf("creating isolated context for run %d: %w", i+1, err)
		}
		defer ctx.Cleanup()

		// TODO: Execute eval_criteria in ctx.WorkingDir()
		// For now, still stubbed to always pass
		result.Runs[i] = true
	}

	return result, nil
}

// calculateEvalMetrics calculates metrics by category from eval results
func calculateEvalMetrics(results []EvalResult) map[string]CategoryMetrics {
	metrics := make(map[string]CategoryMetrics)

	for _, result := range results {
		cat := result.Category
		m := metrics[cat]
		m.Total++

		// Determine pass/fail based on majority vote
		passCount := 0
		for _, run := range result.Runs {
			if run {
				passCount++
			}
		}

		if passCount > len(result.Runs)/2 {
			m.Pass++
		} else {
			m.Fail++
		}

		metrics[cat] = m
	}

	// Calculate pass rates
	for cat, m := range metrics {
		if m.Total > 0 {
			m.PassRate = float64(m.Pass) / float64(m.Total) * 100
		}
		metrics[cat] = m
	}

	return metrics
}

// formatEvalSummary formats evaluation results into a summary table or JSON
func formatEvalSummary(results []EvalResult, format string) string {
	if format == "json" {
		return formatEvalSummaryJSON(results)
	}
	return formatEvalSummaryTable(results)
}

// formatEvalSummaryTable formats results as a table
func formatEvalSummaryTable(results []EvalResult) string {
	var sb strings.Builder

	sb.WriteString("Eval Results Summary\n")
	sb.WriteString("====================\n\n")

	// Calculate metrics by category
	metrics := calculateEvalMetrics(results)

	// Get sorted category names for consistent output
	categories := make([]string, 0, len(metrics))
	for cat := range metrics {
		categories = append(categories, cat)
	}
	sort.Strings(categories)

	// Print category table
	sb.WriteString(fmt.Sprintf("%-20s | %-6s | %-6s | %-6s | %-10s\n",
		"Category", "Cases", "Pass", "Fail", "Pass Rate"))
	sb.WriteString(strings.Repeat("-", 70) + "\n")

	totalCases := 0
	totalPass := 0
	totalFail := 0

	for _, cat := range categories {
		m := metrics[cat]
		sb.WriteString(fmt.Sprintf("%-20s | %-6d | %-6d | %-6d | %9.1f%%\n",
			cat, m.Total, m.Pass, m.Fail, m.PassRate))
		totalCases += m.Total
		totalPass += m.Pass
		totalFail += m.Fail
	}

	// Overall summary
	sb.WriteString("\n")
	overallPassRate := 0.0
	if totalCases > 0 {
		overallPassRate = float64(totalPass) / float64(totalCases) * 100
	}
	sb.WriteString(fmt.Sprintf("Total: %d cases, %d pass, %d fail (%.1f%%)\n",
		totalCases, totalPass, totalFail, overallPassRate))

	sb.WriteString("\nNOTE: Eval criteria execution not yet implemented (using stub)\n")
	sb.WriteString("      All cases currently return pass for validation\n")

	return sb.String()
}

// formatEvalSummaryJSON formats results as JSON
func formatEvalSummaryJSON(results []EvalResult) string {
	metrics := calculateEvalMetrics(results)

	output := map[string]interface{}{
		"categories": metrics,
		"results":    results,
	}

	data, err := json.MarshalIndent(output, "", "  ")
	if err != nil {
		return fmt.Sprintf(`{"error": "failed to marshal JSON: %v"}`, err)
	}

	return string(data)
}

// runEvalCommand executes the eval CLI command
func runEvalCommand(failuresDir string, category string, k int, format string) error {
	// Check if failures directory exists
	if _, err := os.Stat(failuresDir); os.IsNotExist(err) {
		return fmt.Errorf("failures directory not found: %s", failuresDir)
	}

	// Find failure cases
	cases, err := findFailureCases(failuresDir, category)
	if err != nil {
		return fmt.Errorf("finding failure cases: %w", err)
	}

	if len(cases) == 0 {
		if category != "" {
			fmt.Printf("No failure cases found for category: %s\n", category)
		} else {
			fmt.Println("No failure cases found")
		}
		return nil
	}

	fmt.Printf("Found %d failure case(s) to evaluate...\n\n", len(cases))

	// Run evaluation on each case
	results := make([]EvalResult, 0, len(cases))
	for i, failureCase := range cases {
		fmt.Printf("[%d/%d] Evaluating %s...\n", i+1, len(cases), failureCase.ID)

		result, err := runEvaluation(failureCase, k)
		if err != nil {
			fmt.Printf("Warning: Failed to evaluate %s: %v\n", failureCase.ID, err)
			continue
		}

		results = append(results, result)
	}

	// Print summary
	fmt.Println()
	summary := formatEvalSummary(results, format)
	fmt.Println(summary)

	return nil
}
