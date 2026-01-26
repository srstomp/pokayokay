package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strconv"
	"strings"
)

// GradeReport represents parsed data from a skill-clarity report
type GradeReport struct {
	FilePath         string
	GeneratedDate    string
	TotalSkills      int
	AverageScore     float64
	PassRate         float64
	PassingThreshold float64
}

// findGradeReports finds all skill-clarity-*.md reports in the given directory
// Returns reports sorted by date (newest first)
func findGradeReports(reportsDir string) ([]string, error) {
	entries, err := os.ReadDir(reportsDir)
	if err != nil {
		return nil, fmt.Errorf("reading reports directory: %w", err)
	}

	var reports []string
	pattern := regexp.MustCompile(`^skill-clarity-\d{4}-\d{2}-\d{2}\.md$`)

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		if pattern.MatchString(entry.Name()) {
			reports = append(reports, filepath.Join(reportsDir, entry.Name()))
		}
	}

	// Sort by filename (which includes date) in descending order (newest first)
	sort.Slice(reports, func(i, j int) bool {
		return filepath.Base(reports[i]) > filepath.Base(reports[j])
	})

	return reports, nil
}

// parseGradeReport parses a skill-clarity report and extracts key metrics
func parseGradeReport(reportPath string) (GradeReport, error) {
	content, err := os.ReadFile(reportPath)
	if err != nil {
		return GradeReport{}, fmt.Errorf("reading report: %w", err)
	}

	report := GradeReport{
		FilePath: reportPath,
	}

	lines := strings.Split(string(content), "\n")

	// Regex patterns to extract metrics
	generatedPattern := regexp.MustCompile(`Generated:\s*(.+)`)
	totalSkillsPattern := regexp.MustCompile(`\*\*Total Skills\*\*:\s*(\d+)`)
	averageScorePattern := regexp.MustCompile(`\*\*Average Score\*\*:\s*([\d.]+)/100`)
	passRatePattern := regexp.MustCompile(`\*\*Pass Rate\*\*:\s*([\d.]+)%`)
	passingThresholdPattern := regexp.MustCompile(`\*\*Passing Threshold\*\*:\s*([\d.]+)`)

	for _, line := range lines {
		// Extract GeneratedDate
		if matches := generatedPattern.FindStringSubmatch(line); matches != nil {
			report.GeneratedDate = strings.TrimSpace(matches[1])
		}

		// Extract TotalSkills
		if matches := totalSkillsPattern.FindStringSubmatch(line); matches != nil {
			if val, err := strconv.Atoi(matches[1]); err == nil {
				report.TotalSkills = val
			}
		}

		// Extract AverageScore
		if matches := averageScorePattern.FindStringSubmatch(line); matches != nil {
			if val, err := strconv.ParseFloat(matches[1], 64); err == nil {
				report.AverageScore = val
			}
		}

		// Extract PassRate
		if matches := passRatePattern.FindStringSubmatch(line); matches != nil {
			if val, err := strconv.ParseFloat(matches[1], 64); err == nil {
				report.PassRate = val
			}
		}

		// Extract PassingThreshold
		if matches := passingThresholdPattern.FindStringSubmatch(line); matches != nil {
			if val, err := strconv.ParseFloat(matches[1], 64); err == nil {
				report.PassingThreshold = val
			}
		}
	}

	return report, nil
}

// formatReportSummaryMarkdown formats a GradeReport as markdown
func formatReportSummaryMarkdown(report GradeReport) string {
	var sb strings.Builder

	sb.WriteString("# Evaluation Report Summary\n\n")
	sb.WriteString(fmt.Sprintf("**Report**: %s\n", filepath.Base(report.FilePath)))
	sb.WriteString(fmt.Sprintf("**Generated**: %s\n\n", report.GeneratedDate))

	sb.WriteString("## Key Metrics\n\n")
	sb.WriteString(fmt.Sprintf("- **Total Skills**: %d\n", report.TotalSkills))
	sb.WriteString(fmt.Sprintf("- **Average Score**: %.1f/100\n", report.AverageScore))
	sb.WriteString(fmt.Sprintf("- **Pass Rate**: %.1f%%\n", report.PassRate))
	sb.WriteString(fmt.Sprintf("- **Passing Threshold**: %.1f/100\n", report.PassingThreshold))

	return sb.String()
}

// formatReportSummaryJSON formats a GradeReport as JSON
func formatReportSummaryJSON(report GradeReport) (string, error) {
	data := map[string]interface{}{
		"file_path":         report.FilePath,
		"generated_date":    report.GeneratedDate,
		"total_skills":      report.TotalSkills,
		"average_score":     report.AverageScore,
		"pass_rate":         report.PassRate,
		"passing_threshold": report.PassingThreshold,
	}

	jsonBytes, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return "", fmt.Errorf("marshaling to JSON: %w", err)
	}

	return string(jsonBytes), nil
}

// listGradeReports lists all available grade reports
func listGradeReports(reportsDir string) string {
	var sb strings.Builder

	sb.WriteString("# Grade Reports\n\n")

	reports, err := findGradeReports(reportsDir)
	if err != nil {
		sb.WriteString(fmt.Sprintf("Error finding reports: %v\n", err))
		return sb.String()
	}

	if len(reports) == 0 {
		sb.WriteString("No grade reports found.\n")
		return sb.String()
	}

	sb.WriteString(fmt.Sprintf("Found %d report(s):\n\n", len(reports)))

	for i, reportPath := range reports {
		sb.WriteString(fmt.Sprintf("%d. %s\n", i+1, filepath.Base(reportPath)))
	}

	return sb.String()
}

// runReportCommand executes the report CLI command
func runReportCommand(reportType, format string, listMode bool, outputPath, reportsDir string) error {
	// List mode: just list available reports
	if listMode {
		output := listGradeReports(reportsDir)

		if outputPath != "" {
			// Write to file
			if err := os.WriteFile(outputPath, []byte(output), 0644); err != nil {
				return fmt.Errorf("writing output file: %w", err)
			}
			fmt.Printf("Report list written to: %s\n", outputPath)
		} else {
			// Write to stdout
			fmt.Print(output)
		}

		return nil
	}

	// For now, only support 'grade' type
	if reportType != "grade" {
		return fmt.Errorf("report type '%s' not yet implemented (only 'grade' is currently supported)", reportType)
	}

	// Find reports
	reports, err := findGradeReports(reportsDir)
	if err != nil {
		return fmt.Errorf("finding grade reports: %w", err)
	}

	if len(reports) == 0 {
		return fmt.Errorf("no grade reports found in %s", reportsDir)
	}

	// Get the latest report
	latestReportPath := reports[0]

	// Parse the report
	report, err := parseGradeReport(latestReportPath)
	if err != nil {
		return fmt.Errorf("parsing report: %w", err)
	}

	// Format the output
	var output string
	switch format {
	case "json":
		jsonOutput, err := formatReportSummaryJSON(report)
		if err != nil {
			return fmt.Errorf("formatting as JSON: %w", err)
		}
		output = jsonOutput
	case "markdown":
		output = formatReportSummaryMarkdown(report)
	default:
		return fmt.Errorf("unsupported format: %s (use 'markdown' or 'json')", format)
	}

	// Write output
	if outputPath != "" {
		// Write to file
		if err := os.WriteFile(outputPath, []byte(output), 0644); err != nil {
			return fmt.Errorf("writing output file: %w", err)
		}
		fmt.Printf("Report written to: %s\n", outputPath)
	} else {
		// Write to stdout
		fmt.Print(output)
	}

	return nil
}
