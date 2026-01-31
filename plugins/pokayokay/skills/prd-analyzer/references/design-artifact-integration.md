# Design Artifact Integration

This reference provides detailed guidance on how prd-analyzer consumes design artifacts from the design plugin, specifically personas.md files.

## Overview

The prd-analyzer skill can discover and validate against user personas created by the design plugin. This integration:

- Connects user research to implementation planning
- Validates user stories reference real, researched personas
- Prevents generic "as a user" stories when specific personas exist
- Documents design artifacts used in the implementation plan

## Persona Discovery

### File Location Pattern

Personas are stored at:
```
.claude/design/<project-name>/personas.md
```

Where `<project-name>` is the design project name (e.g., "checkout-redesign", "field-notes-app").

### Discovery Algorithm

```
1. Search for all files matching: .claude/design/*/personas.md
2. Count results:
   - 0 files: Proceed without persona validation
   - 1 file: Use that personas.md automatically
   - 2+ files: Ask user which project to use

3. If personas.md found:
   - Read file contents
   - Parse persona names
   - Store for validation during story creation
```

### Example Discovery

```bash
# Finding personas files
$ find .claude/design -name "personas.md"
.claude/design/field-notes/personas.md

# Reading personas file
$ cat .claude/design/field-notes/personas.md
# Persona: Maria Santos

Demographics...

# Persona: Jamie Cooper

Demographics...
```

Result: Personas loaded: ["Maria Santos", "Jamie Cooper"]

## Persona Parsing

### Name Extraction Pattern

Extract persona names from top-level headers:

```markdown
# Persona: Maria Santos    ← Extract "Maria Santos"
# Persona: Jamie Cooper    ← Extract "Jamie Cooper"
## Demographics            ← Ignore (sub-header)
### Goals                  ← Ignore (sub-header)
# Persona: Alex Kim        ← Extract "Alex Kim"
```

**Regex Pattern:**
```
^# Persona: (.+)$
```

**Implementation:**
```
personas = []
for line in personas_file:
  if line.startswith("# Persona: "):
    name = line.replace("# Persona: ", "").strip()
    personas.append(name)
```

### Multi-Word Names

Support personas with multi-word names:
- "Maria Santos" ✓
- "Jamie Cooper" ✓
- "Dr. Sarah Johnson-Smith" ✓
- "李明" (Unicode) ✓

Trim whitespace but preserve internal spaces and special characters.

### Edge Cases

| Input | Extracted Name | Notes |
|-------|---------------|-------|
| `# Persona: Maria Santos` | "Maria Santos" | Standard case |
| `# Persona:  Maria Santos  ` | "Maria Santos" | Trim whitespace |
| `## Persona: Not This` | - | Ignore sub-headers |
| `# persona: lowercase` | - | Case-sensitive match |
| `# Persona:` | "" | Empty persona (skip) |

## User Story Validation

### Story Format Detection

Detect two formats:

1. **Persona-specific:**
   ```
   As [Persona Name], I want to [action], so that [benefit]
   ```
   Example: "As Maria Santos, I want to collect soil samples offline..."

2. **Generic role:**
   ```
   As a [role], I want to [action], so that [benefit]
   ```
   Example: "As a farmer, I want to manage inventory..."

### Distinguishing Pattern

```
IF story starts with "As " AND next word is capitalized AND not followed by "a " or "an ":
  # Likely persona reference
  Extract persona name (words until first comma)
  Validate against personas list
ELSE IF story starts with "As a " or "As an ":
  # Generic role-based story
  No validation needed
```

### Validation Logic

```python
def validate_story(story_text, personas):
  # Extract persona name from story
  match = regex.match(r'^As ([^,]+),', story_text)

  if not match:
    return {"valid": True, "warning": None}  # No persona reference

  reference = match.group(1).strip()

  # Check if it's a generic role
  if story_text.startswith("As a ") or story_text.startswith("As an "):
    return {"valid": True, "warning": None}

  # Check if persona exists
  if reference in personas:
    return {"valid": True, "persona": reference}
  else:
    return {
      "valid": False,
      "persona": reference,
      "warning": f"User story references undefined persona: {reference}"
    }
```

### Validation Examples

Given personas: ["Maria Santos", "Jamie Cooper"]

| Story | Validation Result |
|-------|-------------------|
| "As Maria Santos, I want to track samples..." | ✓ Valid (persona exists) |
| "As Jamie Cooper, I want to generate reports..." | ✓ Valid (persona exists) |
| "As a farmer, I want to manage data..." | ✓ Valid (generic role) |
| "As an administrator, I want to configure..." | ✓ Valid (generic role) |
| "As John Doe, I want to view analytics..." | ⚠ Warning: John Doe not in personas.md |
| "As the operations manager, I want..." | ✓ Valid (generic role with "the") |

## Output Documentation

### PROJECT.md Section

When personas are used, add this section after "Tech Stack":

```markdown
## Design Artifacts

**Personas** (from `.claude/design/field-notes/personas.md`):
- Maria Santos
- Jamie Cooper
- Alex Kim

User stories validated against these personas.
```

If validation warnings exist, add to "Current Gaps":

```markdown
## Current Gaps

- User story references undefined persona: John Doe (Story: story-004-03)
  → Add persona definition to .claude/design/field-notes/personas.md or update story to use generic role
- User story references undefined persona: Jane Smith (Story: story-008-01)
  → Add persona definition or update story to use generic role
```

### Implementation Plan Section

Add to implementation-plan.md:

```markdown
## Design Artifacts Used

**Personas:** `.claude/design/field-notes/personas.md`
- Maria Santos (farm owner-operator, regenerative practices)
- Jamie Cooper (operations manager, logistics focus)
- Alex Kim (freelance designer, mobile-first workflow)

### Persona Validation Results

✓ **15 user stories** reference defined personas:
  - 8 stories for Maria Santos
  - 5 stories for Jamie Cooper
  - 2 stories for Alex Kim

✓ **12 user stories** use generic roles (no validation needed)

⚠ **2 validation warnings:**

1. **Story story-004-03:** "As John Doe, I want to manage user permissions..."
   - Persona "John Doe" not found in personas.md
   - **Recommendation:** Add persona definition for John Doe or revise story to use generic role ("As an administrator...")

2. **Story story-008-01:** "As Jane Smith, I want to export compliance reports..."
   - Persona "Jane Smith" not found in personas.md
   - **Recommendation:** Add persona definition for Jane Smith or revise story to use generic role ("As a compliance officer...")

### Next Steps

1. Review validation warnings above
2. Either add missing persona definitions to personas.md or update stories to use generic roles
3. Consider creating persona-specific stories for better user-centered design
```

### Validation Summary Format

```
Persona Validation: X stories validated
✓ Y stories reference defined personas
✓ Z stories use generic roles
⚠ W warnings (undefined personas)
```

## Multiple Design Projects

### Detection

```bash
$ find .claude/design -name "personas.md"
.claude/design/field-notes/personas.md
.claude/design/checkout-flow/personas.md
.claude/design/analytics-dashboard/personas.md
```

### User Prompt

```
Multiple design projects found:
1. field-notes (3 personas)
2. checkout-flow (2 personas)
3. analytics-dashboard (4 personas)

Which project's personas should be used for validation?
[Enter number or project name]: _
```

### Implementation

```
projects = find_all_personas_files()

if len(projects) == 0:
  print("No design personas found (proceeding without validation)")
  return None

elif len(projects) == 1:
  print(f"Found personas in {projects[0]}")
  return load_personas(projects[0])

else:
  print("Multiple design projects found:")
  for i, project in enumerate(projects):
    count = count_personas(project)
    print(f"{i+1}. {project.name} ({count} personas)")

  selection = input("Which project's personas should be used? ")
  selected_project = parse_selection(selection, projects)
  return load_personas(selected_project)
```

## Backward Compatibility

### No Personas File

If no `.claude/design/*/personas.md` exists:

```
1. Proceed with normal PRD analysis
2. No persona validation performed
3. No errors or warnings about missing personas
4. Optional note in output: "No design personas found"
```

**Example output note (optional):**

```
Design Artifacts: None found

Note: User personas can improve story validation. Create personas using the design plugin:
  /design:persona

Then re-run prd-analyzer to validate stories against personas.
```

### Graceful Degradation

```
try:
  personas = discover_personas()
  if personas:
    validate_stories(personas)
except FileNotFoundError:
  # No personas file, continue normally
  pass
except Exception as e:
  # Log error but don't block analysis
  log.warning(f"Could not load personas: {e}")
  pass
```

**Never block or error** if personas.md is missing or malformed.

## Integration Workflow

### Full Process Flow

```
1. User runs: prd-analyzer analyze project-brief.md

2. Skill initialization:
   ├─ Search for .claude/design/*/personas.md
   ├─ If found: Parse persona names
   └─ If not found: Continue without validation

3. PRD Analysis:
   ├─ Extract features, requirements
   ├─ Classify priorities
   └─ Identify user types (cross-reference with personas)

4. Task Breakdown:
   ├─ Create epics
   ├─ Create stories
   │  ├─ Check story format
   │  ├─ If persona reference: Validate against personas.md
   │  └─ Store validation results
   └─ Create tasks

5. Output Generation:
   ├─ PROJECT.md
   │  ├─ Add Design Artifacts section (if personas used)
   │  └─ Add validation warnings to Current Gaps
   ├─ implementation-plan.md
   │  └─ Add Persona Validation summary
   └─ Other outputs (tasks.db, features.json, etc.)

6. Report to user:
   ├─ Summary of personas found
   ├─ Validation results
   └─ Recommendations for warnings
```

## Quality Checklist

Before completing persona integration:

- [ ] Personas.md discovery attempted
- [ ] Persona names correctly parsed (multi-word names supported)
- [ ] Multiple projects handled (user prompted if needed)
- [ ] User stories validated (persona-specific only)
- [ ] Generic roles ("As a...") not validated
- [ ] Validation warnings generated for undefined personas
- [ ] PROJECT.md includes design artifacts section
- [ ] Implementation plan includes validation summary
- [ ] Backward compatible (works without personas.md)
- [ ] No errors or blocking if personas.md missing
- [ ] Clear, actionable warnings and recommendations

## Example End-to-End

### Input Files

**.claude/design/field-notes/personas.md:**
```markdown
# Persona: Maria Santos

Demographics: Farm owner-operator...

# Persona: Jamie Cooper

Demographics: Operations manager...
```

**project-brief.md:**
```markdown
# Field Notes App

## User Stories

1. As Maria Santos, I want to collect soil samples offline
2. As Jamie Cooper, I want to generate weekly reports
3. As a farm worker, I want to log daily activities
4. As John Doe, I want to manage team permissions
```

### Processing

```
1. Discover personas.md → Found: .claude/design/field-notes/personas.md
2. Parse personas → ["Maria Santos", "Jamie Cooper"]
3. Validate stories:
   - Story 1: ✓ Maria Santos (valid)
   - Story 2: ✓ Jamie Cooper (valid)
   - Story 3: ✓ Generic role (no validation)
   - Story 4: ⚠ John Doe (not in personas.md)
```

### Output (PROJECT.md excerpt)

```markdown
## Design Artifacts

**Personas** (from `.claude/design/field-notes/personas.md`):
- Maria Santos
- Jamie Cooper

User stories validated against these personas.

## Current Gaps

- User story references undefined persona: John Doe (Story: story-001-04)
  → Add persona definition to .claude/design/field-notes/personas.md or update story to use generic role
```

### Output (implementation-plan.md excerpt)

```markdown
## Design Artifacts Used

**Personas:** `.claude/design/field-notes/personas.md`
- Maria Santos
- Jamie Cooper

### Persona Validation Results

✓ 2 user stories reference defined personas
✓ 1 user story uses generic role
⚠ 1 validation warning:

**Story story-001-04:** "As John Doe, I want to manage team permissions..."
- Persona "John Doe" not found in personas.md
- **Recommendation:** Add persona definition for John Doe or revise to "As an administrator..."
```

## Anti-Patterns

### DON'T: Block on missing personas

```
❌ BAD:
ERROR: No personas.md found. Cannot proceed.
Please create personas first.

✓ GOOD:
No design personas found (proceeding without validation)
Note: Create personas with /design:persona for better story validation
```

### DON'T: Validate generic roles

```
❌ BAD:
⚠ Warning: "a farmer" not found in personas.md

✓ GOOD:
(No validation for generic role "As a farmer...")
```

### DON'T: Case-insensitive matching

```
❌ BAD:
Story: "As maria santos, I want..."
Matched to persona: "Maria Santos" ✓

✓ GOOD:
Story: "As maria santos, I want..."
⚠ Warning: "maria santos" not found (did you mean "Maria Santos"?)
```

### DON'T: Overwrite user stories

```
❌ BAD:
Found story: "As a user, I want to export data..."
Auto-corrected to: "As Maria Santos, I want to export data..."

✓ GOOD:
Found story: "As a user, I want to export data..."
Note: Consider using specific persona (Maria Santos, Jamie Cooper) instead of generic "user"
```

## Testing Checklist

Verify these scenarios:

- [ ] Single personas.md file discovered and used
- [ ] Multiple projects prompt user for selection
- [ ] No personas.md → proceeds without validation
- [ ] Persona names with spaces parsed correctly
- [ ] Unicode persona names supported
- [ ] Generic roles ("As a...") not validated
- [ ] Persona-specific stories validated
- [ ] Undefined personas generate warnings
- [ ] PROJECT.md includes design artifacts section
- [ ] Implementation plan includes validation summary
- [ ] No errors if personas.md missing
- [ ] No errors if personas.md malformed (graceful degradation)
- [ ] Warnings are clear and actionable
- [ ] Recommendations provided for warnings

## References

- [Design Plugin: Artifact Storage](../../../../toyoda/plugins/design/references/artifact-storage.md)
- [Design Plugin: Persona Template](../../../../toyoda/plugins/design/templates/persona.md)
- [Design Plugin: Persona Examples](../../../../toyoda/plugins/design/examples/personas/)
- [PRD Analyzer: Story Definition](task-breakdown.md)
