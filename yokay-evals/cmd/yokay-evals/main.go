package main

import (
	"flag"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/stevestomp/yokay-evals/internal/graders/modelbased"
)

type skillResult struct {
	Name    string
	Path    string
	Score   float64
	Passed  bool
	Message string
	Details map[string]any
}

func main() {
	// Define subcommands
	gradeCmd := flag.NewFlagSet("grade-skills", flag.ExitOnError)
	skillsDir := gradeCmd.String("skills-dir", "/Users/sis4m4/Projects/stevestomp/pokayokay/plugins/pokayokay/skills", "Path to skills directory")
	reportPath := gradeCmd.String("output", "", "Output report path (default: yokay-evals/reports/skill-clarity-YYYY-MM-DD.md)")

	metaCmd := flag.NewFlagSet("meta", flag.ExitOnError)
	suite := metaCmd.String("suite", "", "Suite to run: 'agents' or 'skills'")
	agent := metaCmd.String("agent", "", "Specific agent to run (e.g., 'yokay-spec-reviewer')")
	k := metaCmd.Int("k", 5, "Number of runs for pass^k (default: 5)")
	metaDirFlag := metaCmd.String("meta-dir", "", "Path to meta directory (default: yokay-evals/meta)")

	evalCmd := flag.NewFlagSet("eval", flag.ExitOnError)
	failuresDirFlag := evalCmd.String("failures-dir", "", "Path to failures directory (default: yokay-evals/failures)")
	categoryFlag := evalCmd.String("category", "", "Filter to specific category (e.g., 'missing-tests')")
	kFlag := evalCmd.Int("k", 1, "Number of evaluation runs (default: 1)")
	formatFlag := evalCmd.String("format", "table", "Output format: 'table' or 'json'")

	reportCmd := flag.NewFlagSet("report", flag.ExitOnError)
	reportType := reportCmd.String("type", "grade", "Report type: 'grade', 'eval', or 'all'")
	reportFormat := reportCmd.String("format", "markdown", "Output format: 'markdown' or 'json'")
	listReports := reportCmd.Bool("list", false, "List available reports without aggregating")
	outputFile := reportCmd.String("output", "", "Write output to file instead of stdout")
	reportsDirFlag := reportCmd.String("reports-dir", "", "Path to reports directory (default: reports/)")

	if len(os.Args) < 2 {
		fmt.Println("Usage: yokay-evals <command> [options]")
		fmt.Println("\nCommands:")
		fmt.Println("  grade-skills    Grade all pokayokay skills and generate report")
		fmt.Println("  meta            Run meta-evaluations on agents or skills")
		fmt.Println("  eval            Run eval suite against failure cases")
		fmt.Println("  report          View and analyze evaluation reports")
		os.Exit(1)
	}

	switch os.Args[1] {
	case "grade-skills":
		gradeCmd.Parse(os.Args[2:])

		// Set default output path if not specified
		output := *reportPath
		if output == "" {
			// Get the yokay-evals directory (parent of cmd)
			execPath, err := os.Executable()
			if err != nil {
				log.Fatalf("Failed to get executable path: %v", err)
			}
			evalsDir := filepath.Join(filepath.Dir(filepath.Dir(execPath)), "..")
			reportsDir := filepath.Join(evalsDir, "reports")

			// Create reports directory if it doesn't exist
			if err := os.MkdirAll(reportsDir, 0755); err != nil {
				log.Fatalf("Failed to create reports directory: %v", err)
			}

			today := time.Now().Format("2006-01-02")
			output = filepath.Join(reportsDir, fmt.Sprintf("skill-clarity-%s.md", today))
		}

		if err := gradeSkills(*skillsDir, output); err != nil {
			log.Fatalf("Failed to grade skills: %v", err)
		}

		fmt.Printf("Report generated: %s\n", output)

	case "meta":
		metaCmd.Parse(os.Args[2:])

		// Set default meta directory if not specified
		metaDir := *metaDirFlag
		if metaDir == "" {
			// Try to find meta directory relative to current working directory
			cwd, err := os.Getwd()
			if err != nil {
				log.Fatalf("Failed to get current directory: %v", err)
			}

			// Check if we're in yokay-evals directory or a subdirectory
			if strings.Contains(cwd, "yokay-evals") {
				// Find the yokay-evals directory
				parts := strings.Split(cwd, "yokay-evals")
				if len(parts) > 0 {
					evalsDir := parts[0] + "yokay-evals"
					metaDir = filepath.Join(evalsDir, "meta")
				}
			} else {
				// Assume meta is relative to current directory
				metaDir = "meta"
			}
		}

		if err := runMetaCommand(*suite, *agent, *k, metaDir); err != nil {
			log.Fatalf("Failed to run meta-evaluation: %v", err)
		}

	case "eval":
		evalCmd.Parse(os.Args[2:])

		// Set default failures directory if not specified
		failuresDir := *failuresDirFlag
		if failuresDir == "" {
			// Try to find failures directory relative to current working directory
			cwd, err := os.Getwd()
			if err != nil {
				log.Fatalf("Failed to get current directory: %v", err)
			}

			// Check if we're in yokay-evals directory or a subdirectory
			if strings.Contains(cwd, "yokay-evals") {
				// Find the yokay-evals directory
				parts := strings.Split(cwd, "yokay-evals")
				if len(parts) > 0 {
					evalsDir := parts[0] + "yokay-evals"
					failuresDir = filepath.Join(evalsDir, "failures")
				}
			} else if strings.Contains(cwd, "pokayokay") {
				// Find the project root
				parts := strings.Split(cwd, "pokayokay")
				if len(parts) > 0 {
					projectRoot := parts[0] + "pokayokay"
					failuresDir = filepath.Join(projectRoot, "yokay-evals", "failures")
				}
			} else {
				// Assume failures is relative to current directory
				failuresDir = "failures"
			}
		}

		if err := runEvalCommand(failuresDir, *categoryFlag, *kFlag, *formatFlag); err != nil {
			log.Fatalf("Failed to run eval command: %v", err)
		}

	case "report":
		reportCmd.Parse(os.Args[2:])

		// Set default reports directory if not specified
		reportsDir := *reportsDirFlag
		if reportsDir == "" {
			// Try to find reports directory relative to current working directory
			cwd, err := os.Getwd()
			if err != nil {
				log.Fatalf("Failed to get current directory: %v", err)
			}

			// Check if we're in the project root or a subdirectory
			if strings.Contains(cwd, "pokayokay") {
				// Find the project root
				parts := strings.Split(cwd, "pokayokay")
				if len(parts) > 0 {
					projectRoot := parts[0] + "pokayokay"
					reportsDir = filepath.Join(projectRoot, "reports")
				}
			} else {
				// Assume reports is relative to current directory
				reportsDir = "reports"
			}
		}

		if err := runReportCommand(*reportType, *reportFormat, *listReports, *outputFile, reportsDir); err != nil {
			log.Fatalf("Failed to run report command: %v", err)
		}

	default:
		fmt.Printf("Unknown command: %s\n", os.Args[1])
		os.Exit(1)
	}
}

// gradeSkills finds all skill files, grades them, and generates a report
func gradeSkills(skillsDir, reportPath string) error {
	// Find all SKILL.md files
	skillFiles, err := findSkillFiles(skillsDir)
	if err != nil {
		return fmt.Errorf("finding skill files: %w", err)
	}

	if len(skillFiles) == 0 {
		return fmt.Errorf("no skill files found in %s", skillsDir)
	}

	fmt.Printf("Found %d skills to grade...\n", len(skillFiles))

	// Grade each skill
	grader := modelbased.NewSkillClarityGrader()
	results := make([]skillResult, 0, len(skillFiles))

	for i, skillPath := range skillFiles {
		fmt.Printf("[%d/%d] Grading %s...\n", i+1, len(skillFiles), filepath.Base(filepath.Dir(skillPath)))

		// Read skill content
		content, err := os.ReadFile(skillPath)
		if err != nil {
			log.Printf("Warning: Failed to read %s: %v", skillPath, err)
			continue
		}

		// Grade the skill
		result, err := grader.Grade(modelbased.GradeInput{
			Content: string(content),
			Context: map[string]any{
				"path": skillPath,
			},
		})
		if err != nil {
			log.Printf("Warning: Failed to grade %s: %v", skillPath, err)
			continue
		}

		// Extract skill name from path (directory name containing SKILL.md)
		skillName := filepath.Base(filepath.Dir(skillPath))

		results = append(results, skillResult{
			Name:    skillName,
			Path:    skillPath,
			Score:   result.Score,
			Passed:  result.Passed,
			Message: result.Message,
			Details: result.Details,
		})
	}

	if len(results) == 0 {
		return fmt.Errorf("no skills were successfully graded")
	}

	// Generate report
	if err := generateReport(results, reportPath); err != nil {
		return fmt.Errorf("generating report: %w", err)
	}

	return nil
}

// findSkillFiles recursively finds all SKILL.md files in the given directory
func findSkillFiles(rootDir string) ([]string, error) {
	var skillFiles []string

	err := filepath.Walk(rootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !info.IsDir() && info.Name() == "SKILL.md" {
			skillFiles = append(skillFiles, path)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return skillFiles, nil
}

// generateReport creates a markdown report from grading results
func generateReport(results []skillResult, reportPath string) error {
	// Sort results by score (highest to lowest)
	sort.Slice(results, func(i, j int) bool {
		return results[i].Score > results[j].Score
	})

	// Calculate summary statistics
	totalScore := 0.0
	passCount := 0
	for _, r := range results {
		totalScore += r.Score
		if r.Passed {
			passCount++
		}
	}
	avgScore := totalScore / float64(len(results))
	passRate := float64(passCount) / float64(len(results)) * 100

	// Build report content
	var sb strings.Builder

	// Header
	sb.WriteString("# Skill Clarity Report\n\n")
	sb.WriteString(fmt.Sprintf("Generated: %s\n\n", time.Now().Format("2006-01-02 15:04:05")))
	sb.WriteString("This report evaluates pokayokay skills using the Skill Clarity Grader.\n")
	sb.WriteString("**Note**: Current grading uses heuristic-based evaluation (stub implementation). LLM-based grading not yet implemented.\n\n")

	// Summary
	sb.WriteString("## Summary\n\n")
	sb.WriteString(fmt.Sprintf("- **Total Skills**: %d\n", len(results)))
	sb.WriteString(fmt.Sprintf("- **Average Score**: %.1f/100\n", avgScore))
	sb.WriteString(fmt.Sprintf("- **Pass Rate**: %.1f%% (%d/%d)\n", passRate, passCount, len(results)))
	sb.WriteString(fmt.Sprintf("- **Passing Threshold**: 70.0\n\n"))

	// Skills below threshold
	belowThreshold := []skillResult{}
	for _, r := range results {
		if r.Score < 80.0 {
			belowThreshold = append(belowThreshold, r)
		}
	}

	if len(belowThreshold) > 0 {
		sb.WriteString("## Skills Below Threshold (< 80%)\n\n")
		sb.WriteString("These skills need improvement:\n\n")
		for _, r := range belowThreshold {
			status := "Needs Improvement"
			if r.Score < 70.0 {
				status = "**FAILED**"
			}
			sb.WriteString(fmt.Sprintf("- **%s** - %.1f/100 - %s\n", r.Name, r.Score, status))
		}
		sb.WriteString("\n")
	}

	// Ranked list
	sb.WriteString("## Skills by Score\n\n")
	sb.WriteString("All skills ranked from highest to lowest:\n\n")
	sb.WriteString("| Rank | Skill | Score | Status |\n")
	sb.WriteString("|------|-------|-------|--------|\n")

	for i, r := range results {
		status := "✅ Pass"
		if !r.Passed {
			status = "❌ Fail"
		} else if r.Score < 80.0 {
			status = "⚠️  Pass (Low)"
		}
		sb.WriteString(fmt.Sprintf("| %d | %s | %.1f | %s |\n", i+1, r.Name, r.Score, status))
	}
	sb.WriteString("\n")

	// Detailed breakdown
	sb.WriteString("## Detailed Breakdown\n\n")
	for _, r := range results {
		sb.WriteString(fmt.Sprintf("### %s\n\n", r.Name))
		sb.WriteString(fmt.Sprintf("**Overall Score**: %.1f/100 - %s\n\n", r.Score, r.Message))
		sb.WriteString("**Criteria Scores**:\n\n")

		// Extract and display criteria details
		criteria := []string{"clear_instructions", "actionable_steps", "good_examples", "appropriate_scope"}
		for _, criterion := range criteria {
			if details, ok := r.Details[criterion].(map[string]any); ok {
				// Safely extract fields with type checking
				score, scoreOk := details["score"].(float64)
				feedback, feedbackOk := details["feedback"].(string)
				weight, weightOk := details["weight"].(float64)

				// Skip this criterion if any field is missing or has wrong type
				if !scoreOk || !feedbackOk || !weightOk {
					continue
				}

				sb.WriteString(fmt.Sprintf("- **%s** (weight: %.0f%%): %.1f/100\n",
					formatCriterionName(criterion), weight*100, score))
				sb.WriteString(fmt.Sprintf("  - %s\n", feedback))
			}
		}
		sb.WriteString("\n")
	}

	// Write report to file
	if err := os.WriteFile(reportPath, []byte(sb.String()), 0644); err != nil {
		return fmt.Errorf("writing report file: %w", err)
	}

	return nil
}

// formatCriterionName converts snake_case to Title Case
func formatCriterionName(name string) string {
	parts := strings.Split(name, "_")
	for i, part := range parts {
		if len(part) > 0 {
			// Manually title case: capitalize first letter, lowercase the rest
			parts[i] = strings.ToUpper(part[:1]) + strings.ToLower(part[1:])
		}
	}
	return strings.Join(parts, " ")
}
