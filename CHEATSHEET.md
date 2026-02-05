# pokayokay Quick Reference

## Setup
```bash
claude plugin marketplace add srstomp/pokayokay
claude plugin install pokayokay@srstomp-pokayokay
npx @stevestomp/ohno-cli init
```

## Core Workflow
```
/plan → /revise (optional) → /work → /audit → /handoff
```

| Command | Purpose |
|---------|---------|
| `/pokayokay:plan <prd>` | Create tasks from PRD |
| `/pokayokay:plan --headless <prd>` | Autonomous PRD analysis |
| `/pokayokay:plan --review` | Review plan decisions |
| `/pokayokay:revise` | Revise plan (explore mode) |
| `/pokayokay:revise --direct` | Revise plan (know what to change) |
| `/pokayokay:work` | Start supervised session |
| `/pokayokay:work semi-auto` | Pause at story boundaries |
| `/pokayokay:work autonomous` | Pause at epic boundaries |
| `/pokayokay:work --continue` | Resume interrupted session |
| `/pokayokay:work semi-auto -n 3` | Run 3 tasks in parallel |
| `/pokayokay:work semi-auto -n auto` | Adaptive parallel sizing |
| `/pokayokay:audit` | Check accessibility (L0-L5) |
| `/pokayokay:audit --full` | Check all 5 dimensions |
| `/pokayokay:handoff` | End session with context |

## Ad-Hoc Commands
| Command | Purpose |
|---------|---------|
| `/pokayokay:quick <task>` | Quick task + immediate work |
| `/pokayokay:fix <bug>` | Bug diagnosis workflow |
| `/pokayokay:spike <question>` | Time-boxed investigation |
| `/pokayokay:hotfix <issue>` | Production incident |

## Development Commands
| Command | Purpose |
|---------|---------|
| `/pokayokay:api` | REST/GraphQL design |
| `/pokayokay:db` | Database schema |
| `/pokayokay:arch` | Architecture review |
| `/pokayokay:test` | Testing strategy |
| `/pokayokay:integrate` | API integration |

## Infrastructure Commands
| Command | Purpose |
|---------|---------|
| `/pokayokay:cicd` | CI/CD pipelines |
| `/pokayokay:security` | Security audit |
| `/pokayokay:observe` | Logging/metrics |

## Work Modes
| Mode | Task | Story | Epic |
|------|------|-------|------|
| supervised | PAUSE | PAUSE | PAUSE |
| semi-auto | log | PAUSE | PAUSE |
| autonomous | log | log | PAUSE |

## Completeness Levels (L0-L5)
| Level | Meaning |
|-------|---------|
| L0 | Not started |
| L1 | Backend only |
| L2 | Frontend exists, not routable |
| L3 | Has route, not in nav |
| L4 | In nav, missing polish |
| L5 | Complete |

## Spike Decisions
| Decision | Meaning |
|----------|---------|
| GO | Proceed with approach |
| NO-GO | Don't proceed |
| PIVOT | Different approach |
| MORE-INFO | Need specific info (rare) |

## Sub-Agents
| Agent | Model | Purpose |
|-------|-------|---------|
| yokay-auditor | Sonnet | L0-L5 scanning |
| yokay-brainstormer | Sonnet | Task refinement |
| yokay-browser-verifier | Sonnet | UI verification |
| yokay-explorer | Haiku | Fast codebase search |
| yokay-fixer | Sonnet | Auto-retry test failures |
| yokay-implementer | Sonnet | TDD implementation |
| yokay-quality-reviewer | Haiku | Code quality |
| yokay-reviewer | Sonnet | Code review |
| yokay-security-scanner | Sonnet | OWASP scanning |
| yokay-spec-reviewer | Haiku | Spec compliance |
| yokay-spike-runner | Sonnet | Investigations |
| yokay-test-runner | Haiku | Test execution |

## ohno CLI
```bash
npx @stevestomp/ohno-cli list      # View tasks
npx @stevestomp/ohno-cli serve     # Kanban board
npx @stevestomp/ohno-cli next      # Get next task
npx @stevestomp/ohno-cli done <id> # Complete task
```

## Files
| Path | Purpose |
|------|---------|
| `.claude/PROJECT.md` | Project context |
| `.claude/spikes/*.md` | Spike reports |
| `.yokay/hooks.yaml` | Custom hooks |
