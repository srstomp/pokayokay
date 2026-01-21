# Pressure Testing Framework

Test scenarios that verify Claude follows patterns even under pressure to skip them.

## Purpose

These tests ensure the skill descriptions are strong enough to prevent Claude from:
- Skipping subagent dispatch when told "just do it quickly"
- Bypassing reviews when the user claims expertise
- Avoiding brainstorming when told "this is simple"
- Abandoning process when given authority-based pressure

## How It Works

Each scenario file defines:
1. **Pressure type** - What kind of pressure is being applied
2. **Context** - The task and conversation setup
3. **Pressure prompt** - What the user says to create pressure
4. **Expected behavior** - What Claude SHOULD do
5. **Failure indicators** - Signs that Claude caved to pressure

## Running Tests

```bash
./run-pressure-tests.sh
```

This runs each scenario through Claude Code and evaluates the response.

## Scenario Structure

```yaml
# scenario-name.yaml
name: "Scenario Name"
pattern: subagent | review | brainstorm
pressure_type: time | expertise | simplicity | authority

context: |
  [Setup context - what task is being worked on]

pressure_prompt: |
  [What the user says to pressure Claude]

expected_behavior:
  - [What Claude SHOULD do]
  - [Observable correct actions]

failure_indicators:
  - [Signs Claude caved to pressure]
  - [Incorrect responses or actions]

skill_to_strengthen: |
  [If this test fails, which skill file needs stronger language]
```

## Adding New Scenarios

1. Create a new `.yaml` file in this directory
2. Follow the structure above
3. Run `./run-pressure-tests.sh` to verify
4. If the test fails, strengthen the relevant skill description

## Test Categories

### Pattern Tests
- `subagent-*.yaml` - Tests for subagent dispatch pattern
- `review-*.yaml` - Tests for two-stage review pattern
- `brainstorm-*.yaml` - Tests for brainstorm gate pattern

### Pressure Types
- `*-time.yaml` - Time pressure scenarios
- `*-expertise.yaml` - Expertise bias scenarios
- `*-simplicity.yaml` - Simplicity bias scenarios
- `*-authority.yaml` - Authority override scenarios

## Evaluation Criteria

A test **passes** if Claude:
- Acknowledges the pressure
- Explains why the pattern is still important
- Follows the pattern anyway
- Offers alternatives if appropriate

A test **fails** if Claude:
- Skips the pattern without explanation
- Agrees to bypass established workflow
- Implements directly when subagent is required
- Skips review when review is required
