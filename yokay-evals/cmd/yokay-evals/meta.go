package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

// EvalConfig represents the structure of an eval.yaml file
type EvalConfig struct {
	Agent                 string     `yaml:"agent"`
	ConsistencyThreshold  float64    `yaml:"consistency_threshold"`
	TestCases             []TestCase `yaml:"test_cases"`
}

// TestCase represents a single test case in the eval.yaml
type TestCase struct {
	ID        string    `yaml:"id"`
	Name      string    `yaml:"name"`
	Input     TaskInput `yaml:"input"`
	Expected  string    `yaml:"expected"`
	K         int       `yaml:"k"`
	Rationale string    `yaml:"rationale"`
}

// TaskInput represents the input to the agent being tested
type TaskInput struct {
	TaskTitle          string   `yaml:"task_title"`
	TaskDescription    string   `yaml:"task_description"`
	AcceptanceCriteria []string `yaml:"acceptance_criteria"`
	Implementation     string   `yaml:"implementation"`
}

// TestResult represents the result of running a test case k times
type TestResult struct {
	TestID   string
	Name     string
	Expected string
	Runs     []string // Each run's verdict
}

// EvaluationResult represents the complete evaluation result for an agent
type EvaluationResult struct {
	Agent       string
	TestResults []TestResult
}

// Metrics represents calculated metrics for the evaluation
type Metrics struct {
	Accuracy        float64
	Consistency     float64
	TotalTests      int
	CorrectCount    int
	ConsistentCount int
}

// loadEvalYAML loads and parses an eval.yaml file
func loadEvalYAML(path string) (*EvalConfig, error) {
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, fmt.Errorf("reading eval.yaml: %w", err)
	}

	var config EvalConfig
	if err := yaml.Unmarshal(data, &config); err != nil {
		return nil, fmt.Errorf("parsing eval.yaml: %w", err)
	}

	return &config, nil
}

// findAgentEvalFiles finds all eval.yaml files in the agents directory
func findAgentEvalFiles(agentsDir string) ([]string, error) {
	var evalFiles []string

	err := filepath.Walk(agentsDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && info.Name() == "eval.yaml" {
			evalFiles = append(evalFiles, path)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return evalFiles, nil
}

// findSkillEvalFiles finds all eval.yaml files in the skills directory
func findSkillEvalFiles(skillsDir string) ([]string, error) {
	var evalFiles []string

	err := filepath.Walk(skillsDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && info.Name() == "eval.yaml" {
			evalFiles = append(evalFiles, path)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return evalFiles, nil
}

// runMetaEvaluation runs meta-evaluation on a single eval.yaml file
func runMetaEvaluation(evalPath string) (EvaluationResult, error) {
	config, err := loadEvalYAML(evalPath)
	if err != nil {
		return EvaluationResult{}, err
	}

	result := EvaluationResult{
		Agent:       config.Agent,
		TestResults: make([]TestResult, 0, len(config.TestCases)),
	}

	// For each test case, run k times
	for _, tc := range config.TestCases {
		k := tc.K
		if k <= 0 {
			k = 5 // default
		}

		testResult := TestResult{
			TestID:   tc.ID,
			Name:     tc.Name,
			Expected: tc.Expected,
			Runs:     make([]string, k),
		}

		// Run the test k times
		for i := 0; i < k; i++ {
			// STUB: Agent execution not yet implemented
			// For now, we'll simulate by returning the expected verdict
			// This allows us to test the metrics calculation logic
			verdict := stubAgentExecution(tc)
			testResult.Runs[i] = verdict
		}

		result.TestResults = append(result.TestResults, testResult)
	}

	return result, nil
}

// stubAgentExecution is a placeholder for actual agent execution
// TODO: Replace this with actual agent runner integration
func stubAgentExecution(tc TestCase) string {
	// For testing purposes, return the expected verdict to ensure metrics work
	// In production, this would call the actual agent
	return tc.Expected
}

// calculateMetrics calculates accuracy and consistency metrics from test results
func calculateMetrics(results []TestResult) Metrics {
	metrics := Metrics{
		TotalTests: len(results),
	}

	for _, tr := range results {
		// Check if correct (majority vote matches expected)
		verdict := getMajorityVerdict(tr.Runs)
		if verdict == tr.Expected {
			metrics.CorrectCount++
		}

		// Check if consistent (all runs agree)
		if areAllRunsConsistent(tr.Runs) {
			metrics.ConsistentCount++
		}
	}

	// Calculate percentages
	if metrics.TotalTests > 0 {
		metrics.Accuracy = float64(metrics.CorrectCount) / float64(metrics.TotalTests)
		metrics.Consistency = float64(metrics.ConsistentCount) / float64(metrics.TotalTests)
	}

	return metrics
}

// getMajorityVerdict returns the most common verdict from runs
func getMajorityVerdict(runs []string) string {
	if len(runs) == 0 {
		return ""
	}

	counts := make(map[string]int)
	for _, verdict := range runs {
		counts[verdict]++
	}

	// Find the verdict with highest count
	maxCount := 0
	majorityVerdict := ""
	for verdict, count := range counts {
		if count > maxCount {
			maxCount = count
			majorityVerdict = verdict
		}
	}

	return majorityVerdict
}

// areAllRunsConsistent checks if all runs returned the same verdict
func areAllRunsConsistent(runs []string) bool {
	if len(runs) <= 1 {
		return true
	}

	first := runs[0]
	for _, verdict := range runs[1:] {
		if verdict != first {
			return false
		}
	}

	return true
}

// formatMetaReport formats the evaluation result into a readable report
func formatMetaReport(result EvaluationResult) string {
	var sb strings.Builder

	sb.WriteString("Meta-Evaluation Report\n")
	sb.WriteString("======================\n\n")

	sb.WriteString(fmt.Sprintf("Agent: %s\n", result.Agent))
	sb.WriteString(fmt.Sprintf("Test Cases: %d\n\n", len(result.TestResults)))

	// Calculate metrics
	metrics := calculateMetrics(result.TestResults)

	sb.WriteString("Results:\n")
	for _, tr := range result.TestResults {
		consistentCount := 0
		if areAllRunsConsistent(tr.Runs) {
			consistentCount = len(tr.Runs)
		} else {
			// Count how many agree with majority
			majority := getMajorityVerdict(tr.Runs)
			for _, verdict := range tr.Runs {
				if verdict == majority {
					consistentCount++
				}
			}
		}

		verdict := getMajorityVerdict(tr.Runs)
		status := "PASS"
		if verdict != tr.Expected {
			status = fmt.Sprintf("FAIL (expected %s, got %s)", tr.Expected, verdict)
		}

		sb.WriteString(fmt.Sprintf("  %s: %s (%d/%d consistent)\n",
			tr.TestID, status, consistentCount, len(tr.Runs)))
	}

	sb.WriteString("\nMetrics:\n")
	sb.WriteString(fmt.Sprintf("  Accuracy: %.1f%% (%d/%d correct)\n",
		metrics.Accuracy*100, metrics.CorrectCount, metrics.TotalTests))
	sb.WriteString(fmt.Sprintf("  Consistency (pass^k): %.1f%% (%d/%d all runs agree)\n",
		metrics.Consistency*100, metrics.ConsistentCount, metrics.TotalTests))

	return sb.String()
}

// runMetaCommand executes the meta CLI command
func runMetaCommand(suite, agent string, k int, metaDir string) error {
	var evalFiles []string
	var err error

	if agent != "" {
		// Run specific agent
		evalPath := filepath.Join(metaDir, "agents", agent, "eval.yaml")
		if _, err := os.Stat(evalPath); os.IsNotExist(err) {
			return fmt.Errorf("eval.yaml not found for agent: %s", agent)
		}
		evalFiles = []string{evalPath}
	} else if suite != "" {
		// Run entire suite
		suiteDir := filepath.Join(metaDir, suite)
		if _, err := os.Stat(suiteDir); os.IsNotExist(err) {
			return fmt.Errorf("suite directory not found: %s", suite)
		}

		if suite == "agents" {
			evalFiles, err = findAgentEvalFiles(suiteDir)
		} else if suite == "skills" {
			evalFiles, err = findSkillEvalFiles(suiteDir)
		} else {
			return fmt.Errorf("invalid suite: %s (must be 'agents' or 'skills')", suite)
		}

		if err != nil {
			return fmt.Errorf("finding eval files: %w", err)
		}

		if len(evalFiles) == 0 {
			return fmt.Errorf("no eval.yaml files found in %s suite", suite)
		}
	} else {
		return fmt.Errorf("must specify either --suite or --agent")
	}

	// Run evaluation for each file
	for _, evalPath := range evalFiles {
		fmt.Printf("\nRunning evaluation: %s\n", evalPath)
		fmt.Println(strings.Repeat("=", 60))

		result, err := runMetaEvaluation(evalPath)
		if err != nil {
			return fmt.Errorf("running evaluation for %s: %w", evalPath, err)
		}

		report := formatMetaReport(result)
		fmt.Println(report)

		// Note about stub implementation
		if len(result.TestResults) > 0 {
			fmt.Println("NOTE: Agent execution not yet implemented (using stub)")
			fmt.Println("      Metrics calculated from stubbed results for validation")
		}
	}

	return nil
}
