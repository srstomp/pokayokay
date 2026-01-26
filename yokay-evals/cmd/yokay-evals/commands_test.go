package main

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"gopkg.in/yaml.v3"
)

// CommandFrontmatter represents the YAML frontmatter in command definition files
type CommandFrontmatter struct {
	Description  string `yaml:"description"`
	ArgumentHint string `yaml:"argument-hint,omitempty"`
	Skill        string `yaml:"skill,omitempty"`
}

// TestYokayEvalsCommandFiles verifies that all yokay-evals command definition files exist
// and have valid YAML frontmatter
func TestYokayEvalsCommandFiles(t *testing.T) {
	gitRoot := getGitRoot(t)
	commandsDir := filepath.Join(gitRoot, "plugins/yokay-evals/commands")

	expectedCommands := []struct {
		name        string
		filename    string
		description string // Expected description substring
	}{
		{
			name:        "grade",
			filename:    "grade.md",
			description: "Grade pokayokay skills",
		},
		{
			name:        "eval",
			filename:    "eval.md",
			description: "Run meta-evaluations",
		},
		{
			name:        "report",
			filename:    "report.md",
			description: "View and analyze evaluation reports",
		},
	}

	for _, cmd := range expectedCommands {
		t.Run(cmd.name, func(t *testing.T) {
			cmdPath := filepath.Join(commandsDir, cmd.filename)

			// Verify file exists
			if _, err := os.Stat(cmdPath); os.IsNotExist(err) {
				t.Fatalf("Command file does not exist: %s", cmdPath)
			}

			// Read file content
			content, err := os.ReadFile(cmdPath)
			if err != nil {
				t.Fatalf("Failed to read command file: %v", err)
			}

			contentStr := string(content)

			// Verify file starts with YAML frontmatter (---)
			if !strings.HasPrefix(contentStr, "---\n") {
				t.Error("Command file must start with YAML frontmatter delimiter '---'")
			}

			// Extract YAML frontmatter
			parts := strings.SplitN(contentStr, "---\n", 3)
			if len(parts) < 3 {
				t.Fatal("Invalid frontmatter format - expected two '---' delimiters")
			}

			yamlContent := parts[1]
			markdownContent := parts[2]

			// Parse YAML frontmatter
			var frontmatter CommandFrontmatter
			if err := yaml.Unmarshal([]byte(yamlContent), &frontmatter); err != nil {
				t.Fatalf("Failed to parse YAML frontmatter: %v", err)
			}

			// Verify required fields
			if frontmatter.Description == "" {
				t.Error("Frontmatter missing required 'description' field")
			}

			// Verify description contains expected substring
			if !strings.Contains(frontmatter.Description, cmd.description) {
				t.Errorf("Description '%s' should contain '%s'", frontmatter.Description, cmd.description)
			}

			// Verify markdown content is not empty
			if strings.TrimSpace(markdownContent) == "" {
				t.Error("Command file has no markdown content after frontmatter")
			}

			// Verify markdown has a title
			if !strings.Contains(markdownContent, "# ") {
				t.Error("Command file should have at least one markdown heading")
			}

			// Verify markdown contains workflow sections
			// Purpose is required, Steps may be optional for reference docs
			if !strings.Contains(markdownContent, "## Purpose") {
				t.Error("Command file missing required section: ## Purpose")
			}

			// Report commands may have different structure (Report Types instead of Steps)
			hasSteps := strings.Contains(markdownContent, "## Steps")
			hasReportTypes := strings.Contains(markdownContent, "## Report Types")
			hasWorkflows := strings.Contains(markdownContent, "## Analysis Workflows")

			if !hasSteps && !hasReportTypes && !hasWorkflows {
				t.Error("Command file should have either ## Steps, ## Report Types, or ## Analysis Workflows section")
			}
		})
	}
}

// TestCommandDescriptions verifies each command has appropriate description length
func TestCommandDescriptions(t *testing.T) {
	gitRoot := getGitRoot(t)
	commandsDir := filepath.Join(gitRoot, "plugins/yokay-evals/commands")

	commandFiles := []string{"grade.md", "eval.md", "report.md"}

	for _, filename := range commandFiles {
		t.Run(filename, func(t *testing.T) {
			cmdPath := filepath.Join(commandsDir, filename)
			content, err := os.ReadFile(cmdPath)
			if err != nil {
				t.Fatalf("Failed to read file: %v", err)
			}

			// Extract frontmatter
			parts := strings.SplitN(string(content), "---\n", 3)
			if len(parts) < 3 {
				t.Fatal("Invalid frontmatter")
			}

			var frontmatter CommandFrontmatter
			if err := yaml.Unmarshal([]byte(parts[1]), &frontmatter); err != nil {
				t.Fatalf("Failed to parse frontmatter: %v", err)
			}

			// Description should be concise but informative (10-100 chars is reasonable)
			descLen := len(frontmatter.Description)
			if descLen < 10 {
				t.Errorf("Description too short (%d chars): '%s'", descLen, frontmatter.Description)
			}
			if descLen > 100 {
				t.Errorf("Description too long (%d chars): '%s'", descLen, frontmatter.Description)
			}
		})
	}
}

// TestCommandMarkdownStructure verifies command files follow expected structure
func TestCommandMarkdownStructure(t *testing.T) {
	gitRoot := getGitRoot(t)
	commandsDir := filepath.Join(gitRoot, "plugins/yokay-evals/commands")

	commandFiles := []string{"grade.md", "eval.md", "report.md"}

	for _, filename := range commandFiles {
		t.Run(filename, func(t *testing.T) {
			cmdPath := filepath.Join(commandsDir, filename)
			content, err := os.ReadFile(cmdPath)
			if err != nil {
				t.Fatalf("Failed to read file: %v", err)
			}

			contentStr := string(content)

			// Verify standard sections exist
			requiredSections := []string{
				"## Purpose",
				"## Related Commands",
			}

			for _, section := range requiredSections {
				if !strings.Contains(contentStr, section) {
					t.Errorf("Missing required section: %s", section)
				}
			}

			// Verify workflow/structure sections (flexible for different command types)
			hasSteps := strings.Contains(contentStr, "## Steps")
			hasReportTypes := strings.Contains(contentStr, "## Report Types")
			hasWorkflows := strings.Contains(contentStr, "## Analysis Workflows")

			if !hasSteps && !hasReportTypes && !hasWorkflows {
				t.Error("Command should have workflow/structure section (## Steps, ## Report Types, or ## Analysis Workflows)")
			}

			// Verify code blocks use proper syntax (```)
			codeBlockCount := strings.Count(contentStr, "```")
			if codeBlockCount%2 != 0 {
				t.Error("Unmatched code block delimiters (```)")
			}

			// Verify no bare URLs (should be in markdown link format or code blocks)
			// This is a simple heuristic check
			lines := strings.Split(contentStr, "\n")
			for i, line := range lines {
				// Skip code blocks
				if strings.HasPrefix(strings.TrimSpace(line), "```") {
					continue
				}
				// Check for http:// or https:// not in markdown link
				if strings.Contains(line, "http://") || strings.Contains(line, "https://") {
					if !strings.Contains(line, "](http") && !strings.Contains(line, "](https") {
						// Allow URLs in code blocks and examples
						if !strings.Contains(line, "://") {
							continue
						}
						t.Logf("Warning: Potential bare URL at line %d: %s", i+1, line)
					}
				}
			}
		})
	}
}

// TestCommandExamplesIncludeActualPaths verifies examples use realistic paths
func TestCommandExamplesIncludeActualPaths(t *testing.T) {
	gitRoot := getGitRoot(t)
	commandsDir := filepath.Join(gitRoot, "plugins/yokay-evals/commands")

	testCases := []struct {
		file         string
		expectedPath string // Path that should appear in examples
	}{
		{
			file:         "grade.md",
			expectedPath: "yokay-evals/bin/yokay-evals grade-skills",
		},
		{
			file:         "eval.md",
			expectedPath: "yokay-evals/bin/yokay-evals meta",
		},
		{
			file:         "report.md",
			expectedPath: "reports/skill-clarity",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.file, func(t *testing.T) {
			cmdPath := filepath.Join(commandsDir, tc.file)
			content, err := os.ReadFile(cmdPath)
			if err != nil {
				t.Fatalf("Failed to read file: %v", err)
			}

			if !strings.Contains(string(content), tc.expectedPath) {
				t.Errorf("Command file should include example path: %s", tc.expectedPath)
			}
		})
	}
}
