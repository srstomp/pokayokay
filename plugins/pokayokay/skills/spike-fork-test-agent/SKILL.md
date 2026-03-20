---
name: spike-fork-test-agent
description: Test skill for plugin agent resolution with context fork
context: fork
agent: yokay-auditor
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob
---

# Fork Test Skill (Plugin Agent)

This skill tests whether agent: yokay-auditor resolves to the plugin's agent definition.

## Verification Steps

1. Report your system prompt / agent identity
2. Run this command and report the output:

```bash
echo "AGENT_TEST_MARKER: agent=yokay-auditor, pid=$$, timestamp=$(date +%s)"
```

3. Report whether you are the yokay-auditor agent (check your instructions for "Feature Completeness Auditor" or "L0-L5")
4. Report which model you're running on

Return ONLY:
- "AGENT_RESOLVED: yes" or "AGENT_RESOLVED: no"
- "AGENT_IDENTITY: [your agent name/identity]"
- The AGENT_TEST_MARKER output
- "MODEL: [model name if known]"
