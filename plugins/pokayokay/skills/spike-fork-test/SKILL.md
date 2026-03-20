---
name: spike-fork-test
description: Test skill for context fork spike validation
context: fork
agent: Explore
disable-model-invocation: true
allowed-tools: Bash, Read
---

# Fork Test Skill

This skill tests whether context: fork works from plugin skills.

## Verification Steps

1. Report whether you are running in a forked subagent context or inline
2. Run this command and report the output:

```bash
echo "FORK_TEST_MARKER: context=fork, agent=Explore, skill_dir=${CLAUDE_SKILL_DIR}, pid=$$, timestamp=$(date +%s)"
```

3. Report which tools you have available
4. Report whether you can see conversation history from the parent

## Dynamic Injection Test

The following line should contain the output of the command (not the literal syntax):

DYNAMIC_INJECT: !`echo "INJECTED_VALUE_$(date +%Y%m%d)"`

Skill directory: ${CLAUDE_SKILL_DIR}

## Return Format

Return ONLY:
- "FORKED: yes" or "FORKED: no"
- The FORK_TEST_MARKER output
- List of available tools
- "HISTORY: visible" or "HISTORY: not visible"
- "DYNAMIC_INJECT: [whatever appeared on that line above]"
- "SKILL_DIR: [whatever ${CLAUDE_SKILL_DIR} resolved to]"
