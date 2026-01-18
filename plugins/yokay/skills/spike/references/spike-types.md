# Spike Types Reference

Detailed guidance for each spike type. Use this to select the right approach and ensure comprehensive investigation.

---

## Feasibility Spike

**Purpose**: Determine if something is technically possible within constraints.

**Typical Questions**:
- Can library X do Y?
- Can we achieve Z with current infrastructure?
- Is technology X suitable for our use case?
- Can we build X within Y timeframe?

### Structure

```markdown
## Feasibility Spike: [Technology/Approach]

### Core Question
Can [technology] support [specific requirement] within [constraint]?

### Success Criteria
1. [Specific capability works: Y/N]
2. [Performance acceptable: Y/N]
3. [Integration possible: Y/N]

### Test Plan
1. Set up minimal environment
2. Implement core capability
3. Test against requirements
4. Document limitations

### Decision Matrix
| Criterion | Required | Achieved | Notes |
|-----------|----------|----------|-------|
| Capability X | Y | ? | |
| Performance <Y | Y | ? | |
| Constraint Z | Y | ? | |
```

### Output Expectations

- **Proof-of-concept**: Working code demonstrating core capability
- **Limitations list**: What doesn't work or has caveats
- **Go/No-Go recommendation**: Clear decision with rationale

### Common Pitfalls

1. **Testing happy path only** — Also test edge cases and failure modes
2. **Ignoring constraints** — Test within actual project constraints (memory, CPU, etc.)
3. **Conflating feasibility with suitability** — "It works" ≠ "It's the right choice"

---

## Architecture Spike

**Purpose**: Determine the right structure or design approach for a system component.

**Typical Questions**:
- Should we use approach A or B for X?
- What's the right separation of concerns for Y?
- How should data flow through component Z?
- What patterns best fit our requirements?

### Structure

```markdown
## Architecture Spike: [Component/Decision]

### Core Question
What is the optimal architecture for [component] given [constraints]?

### Options Under Consideration
1. **Option A**: [Brief description]
   - Pros: [list]
   - Cons: [list]
   
2. **Option B**: [Brief description]
   - Pros: [list]
   - Cons: [list]

### Evaluation Criteria
| Criterion | Weight | Option A | Option B |
|-----------|--------|----------|----------|
| Simplicity | 3 | ? | ? |
| Performance | 2 | ? | ? |
| Extensibility | 2 | ? | ? |
| Team familiarity | 1 | ? | ? |

### Prototype Plan
- [ ] Sketch Option A (30 min)
- [ ] Sketch Option B (30 min)
- [ ] Compare against criteria
- [ ] Document decision rationale

### Decision
**Recommended**: [Option X]
**Rationale**: [Why this option wins]
```

### Output Expectations

- **Comparison matrix**: Structured evaluation of options
- **Diagrams**: High-level architecture sketches (text-based acceptable)
- **Decision document**: Clear recommendation with rationale
- **Trade-offs documented**: What you're giving up with chosen approach

### Common Pitfalls

1. **Analysis paralysis** — Don't compare more than 2-3 options
2. **Premature optimization** — Focus on requirements, not theoretical perfection
3. **Missing stakeholder input** — Architecture decisions often need team buy-in
4. **Ignoring migration cost** — Consider path from current state

---

## Integration Spike

**Purpose**: Determine how to connect to an external service or system.

**Typical Questions**:
- How do we connect to service X?
- What authentication method works with API Y?
- Can we integrate Z with our existing stack?
- What's the data format for integration with X?

### Structure

```markdown
## Integration Spike: [Service/System]

### Core Question
How do we integrate with [service] for [purpose]?

### Integration Requirements
- **Protocol**: REST / GraphQL / WebSocket / etc.
- **Authentication**: API key / OAuth / JWT / etc.
- **Data Format**: JSON / XML / Binary / etc.
- **Rate Limits**: [if known]

### Test Plan
1. Obtain credentials / access
2. Verify authentication works
3. Make basic read request
4. Make basic write request (if applicable)
5. Test error handling
6. Document data structures

### Success Criteria
- [ ] Successfully authenticate
- [ ] Retrieve data in expected format
- [ ] Handle rate limiting gracefully
- [ ] Error responses documented

### Code Artifacts
- Connection utility / client
- Type definitions (if TypeScript)
- Example requests / responses
```

### Output Expectations

- **Working connection**: Authenticated, functional API calls
- **Client code**: Reusable integration code
- **API documentation**: Key endpoints, data formats, gotchas
- **Error handling strategy**: How to handle failures

### Common Pitfalls

1. **Skipping authentication** — Auth is often the hardest part
2. **Testing only in sandbox** — Production may behave differently
3. **Missing error cases** — Test timeouts, rate limits, invalid data
4. **No retry strategy** — External services fail; plan for it

---

## Performance Spike

**Purpose**: Determine if a solution can meet performance requirements.

**Typical Questions**:
- Can we achieve X requests per second?
- Can we process Y records in under Z time?
- Does approach A or B perform better for our workload?
- Where are the bottlenecks in system X?

### Structure

```markdown
## Performance Spike: [Operation/System]

### Core Question
Can [system/operation] achieve [target metric] under [conditions]?

### Performance Requirements
| Metric | Target | Must-Have |
|--------|--------|-----------|
| Latency (p50) | <50ms | Y |
| Latency (p99) | <200ms | Y |
| Throughput | 1000 rps | N |
| Memory | <512MB | Y |

### Test Environment
- **Hardware**: [specs or equivalent]
- **Data volume**: [realistic test data]
- **Concurrency**: [expected concurrent users/requests]

### Test Plan
1. Establish baseline measurement
2. Load test with realistic data
3. Identify bottlenecks
4. Test optimization hypotheses
5. Document findings

### Benchmark Results
| Test | Metric | Result | Target | Pass? |
|------|--------|--------|--------|-------|
| [Test 1] | Latency | ?ms | <50ms | ? |
| [Test 2] | Throughput | ? rps | 1000 rps | ? |
```

### Output Expectations

- **Benchmark results**: Concrete numbers with methodology
- **Bottleneck analysis**: What limits performance
- **Optimization recommendations**: Prioritized list if targets not met
- **Go/No-Go**: Can requirements be met (with or without optimization)?

### Common Pitfalls

1. **Unrealistic test data** — Use production-like volume and variety
2. **Testing on different hardware** — Results won't transfer
3. **Missing warmup** — JIT compilation, caching affect results
4. **Single metric focus** — Latency and throughput can trade off
5. **No p99 measurement** — Averages hide tail latency

---

## Risk Spike

**Purpose**: Identify and assess potential failure modes or risks.

**Typical Questions**:
- What could go wrong with approach X?
- What are the security risks of using Y?
- What failure modes should we design for?
- What are the operational risks of Z?

### Structure

```markdown
## Risk Spike: [System/Approach]

### Core Question
What are the significant risks of [approach] and how can we mitigate them?

### Risk Categories
- [ ] Security
- [ ] Reliability
- [ ] Performance
- [ ] Data integrity
- [ ] Vendor/dependency
- [ ] Operational
- [ ] Compliance

### Risk Register

| Risk | Likelihood | Impact | Mitigation | Residual Risk |
|------|------------|--------|------------|---------------|
| [Risk 1] | H/M/L | H/M/L | [Strategy] | H/M/L |
| [Risk 2] | H/M/L | H/M/L | [Strategy] | H/M/L |

### Investigation Areas
1. Known vulnerabilities in dependencies
2. Failure modes under load
3. Data loss scenarios
4. Recovery procedures

### Recommendations
**Accept**: Risks are acceptable given mitigations
**Reject**: Risks too high, consider alternatives
**Mitigate first**: Proceed only after implementing [mitigations]
```

### Output Expectations

- **Risk register**: Structured list with likelihood/impact
- **Mitigation strategies**: Concrete actions for each significant risk
- **Recommendation**: Accept, reject, or mitigate-first
- **Monitoring recommendations**: How to detect if risks materialize

### Common Pitfalls

1. **Only obvious risks** — Dig deeper than surface concerns
2. **No mitigation strategies** — Identifying isn't enough
3. **Binary thinking** — Risks have likelihood AND impact
4. **Ignoring operational risks** — Security isn't the only risk category
5. **No residual risk assessment** — Mitigations don't eliminate risk

---

## Spike Type Selection Guide

| Situation | Spike Type |
|-----------|------------|
| "Can we use X?" | Feasibility |
| "How should we structure X?" | Architecture |
| "How do we connect to X?" | Integration |
| "Is X fast enough?" | Performance |
| "What could go wrong with X?" | Risk |
| "Should we use A or B?" | Architecture or Feasibility (depending on criteria) |
| "Why is X slow?" | Performance |
| "Is X secure?" | Risk |

---

## Combining Spike Types

Sometimes spikes combine types. Keep primary focus clear:

- **Integration + Feasibility**: "Can we integrate with X and will it meet our needs?"
  - Primary: Integration (get it working first)
  - Secondary: Feasibility (evaluate against requirements)

- **Architecture + Performance**: "Which approach performs better?"
  - Primary: Architecture (compare options)
  - Secondary: Performance (as evaluation criterion)

- **Feasibility + Risk**: "Can we use X safely?"
  - Primary: Feasibility (does it work?)
  - Secondary: Risk (what are the dangers?)

When combining, maintain time-box discipline — don't let scope expand.
