# Design Artifact Integration - Test Suite

This test validates that the prd-analyzer skill correctly consumes design artifacts (personas.md) from the design plugin.

## Test Purpose

Ensure the prd-analyzer skill:
1. Checks for `.claude/design/*/personas.md` files
2. Parses persona names from the personas.md file
3. Validates user stories reference defined personas
4. Warns when stories mention undefined personas
5. Works normally when no personas.md exists (backward compatible)

## Test 1: Persona File Discovery

**Scenario:** Detect personas.md files in design artifact directory

**Expected Behavior:**
- Skill checks for `.claude/design/*/personas.md` pattern
- If single project found, uses that personas.md
- If multiple projects found, asks user which to use
- If no personas.md found, proceeds without validation

**Test Script:**
```
# Setup test environment
mkdir -p .claude/design/my-project
echo "# Persona: Maria Santos" > .claude/design/my-project/personas.md

# Run prd-analyzer
prd-analyzer analyze prd-document.md

# Expected: Skill finds and reads personas.md
assert_file_read(".claude/design/my-project/personas.md")
assert_output_contains("Found design personas")
```

**Pass Criteria:**
- Skill searches for personas.md using glob pattern
- Finds personas.md when present
- Logs discovery in output

## Test 2: Persona Name Parsing

**Scenario:** Extract persona names from personas.md file

**Expected Behavior:**
- Parse persona names from "# Persona: [Name]" headers
- Support multiple personas in single file
- Handle personas with multi-word names

**Test Script:**
```
# Create personas.md with multiple personas
cat > .claude/design/test-project/personas.md << 'EOF'
# Persona: Maria Santos

Demographics...

# Persona: Jamie Cooper

Demographics...

# Persona: Alex Kim

Demographics...
EOF

# Run prd-analyzer
prd-analyzer analyze prd-document.md

# Expected: Parses all three persona names
assert_personas_found(["Maria Santos", "Jamie Cooper", "Alex Kim"])
```

**Pass Criteria:**
- Correctly extracts all persona names
- Handles multi-word names
- Ignores other markdown headers (##, ###)

## Test 3: User Story Validation - Valid References

**Scenario:** User story references a defined persona

**Expected Behavior:**
- Story format: "As [persona name], I want to [goal], so that [benefit]"
- Validates persona name exists in personas.md
- No warning generated for valid references

**Test Script:**
```
# Setup personas.md
echo "# Persona: Maria Santos" > .claude/design/project/personas.md

# Create PRD with user story referencing Maria Santos
cat > prd.md << 'EOF'
## User Stories
- As Maria Santos, I want to track soil samples offline, so that I can work without cell coverage
EOF

# Run prd-analyzer
prd-analyzer analyze prd.md

# Expected: No persona validation warnings
assert_no_warnings_for_story("As Maria Santos")
```

**Pass Criteria:**
- Validates story references defined persona
- No warnings generated
- Story marked as valid in output

## Test 4: User Story Validation - Invalid References

**Scenario:** User story references undefined persona

**Expected Behavior:**
- Story references persona not in personas.md
- Warning generated identifying the undefined persona
- Suggestion to add persona or update story

**Test Script:**
```
# Setup personas.md with one persona
echo "# Persona: Maria Santos" > .claude/design/project/personas.md

# Create PRD with story referencing undefined persona
cat > prd.md << 'EOF'
## User Stories
- As John Doe, I want to manage inventory, so that I can track stock levels
EOF

# Run prd-analyzer
prd-analyzer analyze prd.md

# Expected: Warning for undefined persona
assert_warning_contains("John Doe not found in personas.md")
assert_suggestion_contains("Add persona definition or update story")
```

**Pass Criteria:**
- Detects undefined persona reference
- Generates clear warning message
- Includes suggestion for remediation

## Test 5: Multiple Personas Validation

**Scenario:** Multiple user stories with mix of valid/invalid persona references

**Expected Behavior:**
- Validates each story independently
- Reports all validation issues
- Continues processing despite warnings

**Test Script:**
```
# Setup personas.md
cat > .claude/design/project/personas.md << 'EOF'
# Persona: Maria Santos
# Persona: Alex Kim
EOF

# Create PRD with mixed references
cat > prd.md << 'EOF'
## User Stories
- As Maria Santos, I want to track samples
- As John Doe, I want to view reports
- As Alex Kim, I want to export data
- As Jane Smith, I want to share insights
EOF

# Run prd-analyzer
prd-analyzer analyze prd.md

# Expected: Warnings for John Doe and Jane Smith only
assert_warning_for("John Doe")
assert_warning_for("Jane Smith")
assert_no_warning_for("Maria Santos")
assert_no_warning_for("Alex Kim")
assert_story_count(4)
```

**Pass Criteria:**
- Validates all stories
- Warns only for undefined personas
- Does not warn for defined personas
- Processes all stories successfully

## Test 6: Backward Compatibility - No Personas File

**Scenario:** No personas.md file exists

**Expected Behavior:**
- Skill proceeds normally without persona validation
- No warnings about missing personas.md
- User stories processed without persona checks
- Note in output that personas.md not found (optional)

**Test Script:**
```
# Ensure no personas.md exists
rm -rf .claude/design

# Create PRD with user stories
cat > prd.md << 'EOF'
## User Stories
- As a farmer, I want to track data
- As an operations manager, I want reports
EOF

# Run prd-analyzer
prd-analyzer analyze prd.md

# Expected: Normal operation, no persona validation
assert_no_persona_warnings()
assert_stories_processed(2)
assert_output_contains("No design personas found" OR no message)
```

**Pass Criteria:**
- Skill works normally without personas.md
- No errors or blocking behavior
- Stories processed successfully
- Optional note about missing personas (not required)

## Test 7: Generic Persona References

**Scenario:** Story uses generic role instead of specific persona name

**Expected Behavior:**
- Story format: "As a [role], I want to..." (lowercase "a")
- Treated as generic story, not persona-specific
- No validation warning (not referencing a persona)

**Test Script:**
```
# Setup personas.md
echo "# Persona: Maria Santos" > .claude/design/project/personas.md

# Create PRD with generic role-based stories
cat > prd.md << 'EOF'
## User Stories
- As a farm owner, I want to manage data
- As an administrator, I want to configure settings
- As Maria Santos, I want to track samples
EOF

# Run prd-analyzer
prd-analyzer analyze prd.md

# Expected: Only validates "Maria Santos" reference
assert_no_warning_for("As a farm owner")
assert_no_warning_for("As an administrator")
assert_validation_for("As Maria Santos")
```

**Pass Criteria:**
- Distinguishes between generic roles ("As a") and personas ("As [Name]")
- Only validates persona-specific stories
- Generic stories processed without persona validation

## Test 8: PROJECT.md Integration

**Scenario:** Persona validation results documented in PROJECT.md

**Expected Behavior:**
- PROJECT.md includes section on design artifacts if personas used
- Lists personas available for reference
- Notes any validation warnings in "Current Gaps" section

**Test Script:**
```
# Setup personas.md
cat > .claude/design/project/personas.md << 'EOF'
# Persona: Maria Santos
# Persona: Alex Kim
EOF

# Create PRD with one invalid reference
cat > prd.md << 'EOF'
## User Stories
- As Maria Santos, I want to track samples
- As John Doe, I want to view reports
EOF

# Run prd-analyzer
prd-analyzer analyze prd.md

# Read generated PROJECT.md
project_md = read_file(".claude/PROJECT.md")

# Expected: References to personas and validation issues
assert_contains(project_md, "Design Artifacts")
assert_contains(project_md, "personas.md")
assert_contains(project_md, "Maria Santos, Alex Kim")
assert_contains(project_md, "Current Gaps")
assert_contains(project_md, "User story references undefined persona: John Doe")
```

**Pass Criteria:**
- PROJECT.md documents design artifacts used
- Lists available personas
- Reports persona validation warnings in gaps section
- Clear, actionable documentation

## Test 9: Implementation Plan Output

**Scenario:** Persona validation warnings included in implementation-plan.md

**Expected Behavior:**
- Implementation plan includes design artifacts section
- Lists personas used for validation
- Reports validation warnings with line references

**Test Script:**
```
# Setup test case with validation warnings
# (similar to Test 8)

# Read generated implementation-plan.md
plan = read_file(".claude/implementation-plan.md")

# Expected: Persona information and warnings
assert_contains(plan, "## Design Artifacts")
assert_contains(plan, "Personas:")
assert_contains(plan, "Validation Warnings:")
assert_contains(plan, "John Doe not found")
```

**Pass Criteria:**
- Implementation plan documents personas
- Includes validation warnings section
- Clear remediation guidance

## Test 10: Multiple Project Directories

**Scenario:** Multiple design projects exist, user selects one

**Expected Behavior:**
- Finds multiple `.claude/design/*/personas.md` files
- Asks user which project to use
- Uses selected project's personas for validation

**Test Script:**
```
# Setup multiple design projects
mkdir -p .claude/design/project-a
mkdir -p .claude/design/project-b
echo "# Persona: Maria Santos" > .claude/design/project-a/personas.md
echo "# Persona: Jamie Cooper" > .claude/design/project-b/personas.md

# Run prd-analyzer (should prompt for selection)
# User selects: project-a

# Expected: Uses project-a personas
assert_prompt_contains("Multiple design projects found")
assert_personas_loaded(["Maria Santos"])
assert_not_loaded(["Jamie Cooper"])
```

**Pass Criteria:**
- Detects multiple projects
- Prompts user for selection
- Uses correct project's personas
- Continues normally after selection

## Success Criteria

All tests pass when:
- Skill searches for `.claude/design/*/personas.md` files
- Correctly parses persona names from file
- Validates user stories against persona definitions
- Generates warnings for undefined persona references
- Works normally without personas.md (backward compatible)
- Distinguishes generic roles from specific personas
- Documents findings in PROJECT.md and implementation-plan.md
- Handles multiple design projects gracefully
- Provides clear, actionable validation messages
- Does not block or error on validation warnings

## Implementation Notes

Key implementation areas in SKILL.md:
1. Add "Design Artifact Integration" section after "Integration Points"
2. Update "Analysis Framework" to include persona discovery
3. Update "Story Definition" to include persona validation
4. Update "PROJECT.md Generation" template to include design artifacts section
5. Update "Workflow" to add persona discovery step
6. Add anti-pattern: "Ignoring design artifacts"
