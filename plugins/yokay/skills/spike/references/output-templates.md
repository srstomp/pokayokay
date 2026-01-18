# Spike Output Templates

Templates for consistent, actionable spike documentation. Keep reports concise (<500 words) for quick consumption.

---

## Standard Spike Report Template

```markdown
# Spike Report: [Title]

**Date**: YYYY-MM-DD
**Duration**: Xh (of Yh budget)
**Type**: Feasibility | Architecture | Integration | Performance | Risk
**Decision**: GO ✓ | NO-GO ✗ | PIVOT ↺ | MORE-INFO ?

## Question
[The specific question this spike answered]

## Answer
**[YES/NO/A/B]** — [One-sentence summary]

## Evidence

### What Worked
- [Finding 1]
- [Finding 2]

### What Didn't Work
- [Limitation 1]
- [Blocker if any]

### Key Metrics (if applicable)
| Metric | Target | Actual |
|--------|--------|--------|
| [Metric] | [Target] | [Result] |

## Proof of Concept
**Location**: `.claude/spikes/[name]/`

[Brief code snippet or reference to key files]

## Recommendation
[1-2 sentences on recommendation with reasoning]

## Follow-up Tasks
1. [ ] [Task 1]
2. [ ] [Task 2]
3. [ ] [Task 3]

## Time Log
- 0:XX - [Activity]
- X:XX - [Activity]
- X:XX - [Activity]
```

---

## Feasibility Spike Report

```markdown
# Feasibility Spike: [Technology/Approach]

**Date**: YYYY-MM-DD
**Duration**: Xh
**Decision**: GO ✓ | NO-GO ✗

## Question
Can [technology] [capability] within [constraint]?

## Answer
**[YES/NO]** — [Summary]

## Feasibility Checklist
| Requirement | Required | Achieved | Notes |
|-------------|----------|----------|-------|
| [Req 1] | ✓ | ✓/✗ | |
| [Req 2] | ✓ | ✓/✗ | |
| [Req 3] | | ✓/✗ | Nice-to-have |

## Technical Findings

### Capabilities Confirmed
- [What works as expected]

### Limitations Discovered
- [What doesn't work or has caveats]

### Dependencies Required
- [Libraries, services, or setup needed]

## Proof of Concept
**Location**: `.claude/spikes/[name]/`

Key patterns demonstrated:
- [Pattern 1]
- [Pattern 2]

## Recommendation
**[GO/NO-GO]**: [Reasoning]

## Follow-up Tasks
1. [ ] [Implementation task]
2. [ ] [Configuration task]
3. [ ] [Documentation task]
```

---

## Architecture Spike Report

```markdown
# Architecture Spike: [Decision]

**Date**: YYYY-MM-DD
**Duration**: Xh
**Decision**: [Option X] ✓

## Question
Should we use [Option A] or [Option B] for [purpose]?

## Options Evaluated

### Option A: [Name]
**Pros**: [Brief list]
**Cons**: [Brief list]

### Option B: [Name]
**Pros**: [Brief list]
**Cons**: [Brief list]

## Evaluation Matrix
| Criterion | Weight | Option A | Option B |
|-----------|--------|----------|----------|
| [Criterion 1] | 3 | ★★★ | ★★ |
| [Criterion 2] | 2 | ★★ | ★★★ |
| [Criterion 3] | 1 | ★★★ | ★ |
| **Total** | | X | Y |

## Decision
**Recommended**: [Option X]

**Rationale**: [Why this option wins]

**Trade-offs accepted**: [What we give up]

## Architecture Sketch
[Text-based diagram or reference to diagram file]

## Migration Path
[If replacing existing system, how to get there]

## Follow-up Tasks
1. [ ] Document architecture decision record
2. [ ] Create implementation plan
3. [ ] Update team on decision
```

---

## Integration Spike Report

```markdown
# Integration Spike: [Service/System]

**Date**: YYYY-MM-DD
**Duration**: Xh
**Decision**: GO ✓ | NO-GO ✗

## Question
How do we integrate with [service] for [purpose]?

## Integration Summary
| Aspect | Details |
|--------|---------|
| Protocol | REST / GraphQL / WebSocket |
| Auth | API Key / OAuth2 / JWT |
| Rate Limits | X req/min |
| Data Format | JSON / XML |

## Connection Verified
- [ ] Authentication works
- [ ] Read operations work
- [ ] Write operations work
- [ ] Error handling tested

## API Findings

### Key Endpoints
| Endpoint | Method | Purpose |
|----------|--------|---------|
| /api/v1/... | GET | [Purpose] |
| /api/v1/... | POST | [Purpose] |

### Data Structures
[Brief schema or reference to types file]

### Gotchas
- [Unexpected behavior 1]
- [Undocumented quirk 2]

## Client Code
**Location**: `.claude/spikes/[name]/`

Files created:
- `client.ts` - API client
- `types.ts` - Type definitions
- `examples.ts` - Usage examples

## Follow-up Tasks
1. [ ] Add to project dependencies
2. [ ] Create error handling wrapper
3. [ ] Set up credentials management
4. [ ] Write integration tests
```

---

## Performance Spike Report

```markdown
# Performance Spike: [Operation/System]

**Date**: YYYY-MM-DD
**Duration**: Xh
**Decision**: GO ✓ | NO-GO ✗ | OPTIMIZE FIRST ⚠️

## Question
Can [system] achieve [target] under [conditions]?

## Test Environment
- **Hardware**: [Specs]
- **Data Volume**: [Size/count]
- **Concurrency**: [Level]
- **Test Tool**: [k6/wrk/custom]

## Benchmark Results
| Metric | Target | Baseline | Result | Status |
|--------|--------|----------|--------|--------|
| Latency p50 | <50ms | 120ms | 45ms | ✓ |
| Latency p99 | <200ms | 500ms | 180ms | ✓ |
| Throughput | 1000 rps | 300 rps | 1200 rps | ✓ |
| Memory | <512MB | 400MB | 380MB | ✓ |

## Performance Analysis

### Bottlenecks Identified
1. [Bottleneck 1] - [Impact]
2. [Bottleneck 2] - [Impact]

### Optimization Opportunities
| Optimization | Effort | Expected Gain |
|--------------|--------|---------------|
| [Opt 1] | Low | 20% |
| [Opt 2] | Medium | 40% |

## Recommendation
**[GO/NO-GO/OPTIMIZE FIRST]**: [Reasoning]

## Follow-up Tasks
1. [ ] Implement optimization X
2. [ ] Set up performance monitoring
3. [ ] Create performance regression tests
```

---

## Risk Spike Report

```markdown
# Risk Spike: [System/Approach]

**Date**: YYYY-MM-DD
**Duration**: Xh
**Decision**: ACCEPT ✓ | REJECT ✗ | MITIGATE FIRST ⚠️

## Question
What are the significant risks of [approach] and can we mitigate them?

## Risk Register

### Critical Risks
| Risk | L | I | Mitigation | Residual |
|------|---|---|------------|----------|
| [Risk 1] | H | H | [Strategy] | M |
| [Risk 2] | M | H | [Strategy] | L |

### Moderate Risks
| Risk | L | I | Mitigation | Residual |
|------|---|---|------------|----------|
| [Risk 3] | M | M | [Strategy] | L |

*L = Likelihood, I = Impact, H/M/L scale*

## Risk Categories Evaluated
- [x] Security
- [x] Reliability
- [x] Performance
- [x] Data integrity
- [ ] Compliance (N/A)
- [x] Vendor dependency

## Key Findings

### Confirmed Concerns
- [Concern that investigation validated]

### Dismissed Concerns
- [Concern that investigation found unwarranted]

### New Discoveries
- [Risk not initially considered]

## Mitigation Plan
| Risk | Mitigation | Owner | When |
|------|------------|-------|------|
| [Risk 1] | [Action] | [Who] | Before go-live |
| [Risk 2] | [Action] | [Who] | Before go-live |

## Recommendation
**[ACCEPT/REJECT/MITIGATE FIRST]**: [Reasoning]

## Follow-up Tasks
1. [ ] Implement mitigation for [Risk 1]
2. [ ] Set up monitoring for [Risk 2]
3. [ ] Create incident response plan
```

---

## Quick Decision Summary Template

For stakeholder communication (< 100 words):

```markdown
## Spike Summary: [Title]

**Question**: [One line]
**Answer**: [GO/NO-GO/PIVOT] — [One sentence]
**Key Finding**: [Most important discovery]
**Next Step**: [Immediate action]
**Full Report**: `.claude/spikes/[name].md`
```

---

## File Naming Convention

```
.claude/spikes/
├── [slug]-YYYY-MM-DD.md           # Report
└── [slug]/                         # Proof-of-concept code
    ├── README.md                   # How to run/test
    └── [code files]
```

**Slug format**: kebab-case, descriptive
- `d1-multi-tenant-2026-01-18.md`
- `websocket-vs-sse-2026-01-15.md`
- `stripe-integration-2026-01-10.md`

---

## ohno Task Notes Template

When marking spike done in ohno:

```
[DECISION] - [One-line summary]. See .claude/spikes/[name].md

Created follow-ups:
- task-xxx: [title]
- task-yyy: [title]
```

Example:
```
GO - D1 works for multi-tenant with app-layer isolation. See .claude/spikes/d1-multi-tenant-2026-01-18.md

Created follow-ups:
- task-abc: Design tenant isolation middleware
- task-def: Create PostgreSQL migration script
```
