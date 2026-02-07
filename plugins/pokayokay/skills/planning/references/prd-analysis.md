# PRD Analysis Deep Dive

Comprehensive guidance for parsing and analyzing product requirements documents.

## Document Types

This skill handles various input formats:

| Document Type | Typical Structure | Key Sections |
|---------------|-------------------|--------------|
| **PRD** | Formal, detailed | Problem, Solution, Requirements, Success Metrics |
| **Concept Brief** | High-level, exploratory | Vision, Target Users, Core Features |
| **Feature Spec** | Focused, technical | User Stories, Acceptance Criteria, Technical Notes |
| **RFC/Design Doc** | Technical proposal | Context, Proposal, Alternatives, Implementation |
| **User Story Collection** | Agile format | As a/I want/So that, Acceptance Criteria |
| **Slack/Email Thread** | Informal, scattered | Extract requirements from conversation |

## Parsing Strategy

### First Pass: Structure Recognition

1. **Identify document type** from format and language
2. **Map sections** to standard categories
3. **Note formatting** (headers, lists, tables)

### Second Pass: Information Extraction

Extract into standard categories:

```markdown
## Extracted Information

### Vision & Goals
- Primary goal: [What problem does this solve?]
- Success looks like: [Measurable outcome]
- Timeline: [Any deadlines mentioned?]

### Users & Personas
- Primary user: [Who benefits most?]
- Secondary users: [Other stakeholders?]
- User context: [How/when/where used?]

### Features & Requirements
- Core features: [Must-have functionality]
- Supporting features: [Important but not core]
- Future considerations: [Mentioned but deferred]

### Constraints
- Technical: [Stack, integrations, performance]
- Business: [Budget, timeline, resources]
- Regulatory: [Compliance, security, privacy]

### Dependencies
- Internal: [Other teams, systems]
- External: [Third-party services, APIs]
- Data: [Required data sources]

### Unknowns & Risks
- Ambiguities: [Unclear requirements]
- Assumptions: [Things assumed but not stated]
- Risks: [What could go wrong?]
```

### Third Pass: Gap Analysis

Identify what's missing:

```markdown
## Gap Analysis

### Missing Information
- [ ] Success metrics not defined
- [ ] No error handling requirements
- [ ] Mobile behavior unspecified
- [ ] Data retention policy unclear

### Assumptions Made
- Assuming English-only (i18n not mentioned)
- Assuming standard auth (no SSO mentioned)
- Assuming web-only (mobile not specified)

### Questions for Stakeholder
1. What are the target response times?
2. How many concurrent users expected?
3. Is offline support needed?
```

---

## Feature Classification

### Priority Matrix

Use MoSCoW + numerical priority:

| Code | Priority | Meaning | Criteria |
|------|----------|---------|----------|
| P0 | Must Have | MVP, launch blocker | Product doesn't work without it |
| P1 | Should Have | Important | Significantly impacts user value |
| P2 | Could Have | Nice to have | Improves experience, not critical |
| P3 | Won't Have | Out of scope | Explicitly deferred or excluded |

### Classification Process

For each feature:

```markdown
### Feature: [Name]

**Description**: [What it does]

**Priority Assessment**:
- User impact: High/Medium/Low
- Technical complexity: High/Medium/Low
- Dependencies: [List]
- Explicit in PRD: Yes/No

**Priority**: P[0-3]
**Rationale**: [Why this priority]
```

### Scope Boundary Documentation

```markdown
## Scope Definition

### In Scope (Building)
- User registration and login
- Basic dashboard with metrics
- Data export to CSV

### Out of Scope (Not Building)
- Mobile native apps (web responsive only)
- Real-time collaboration
- Custom reporting builder

### Deferred (Future Iteration)
- SSO integration
- Advanced analytics
- API for third-party integrations
```

---

## Requirement Types

### Functional Requirements

What the system does:

```markdown
### FR-001: User Registration

**Description**: Users can create an account with email and password
**Inputs**: Email, password, name
**Outputs**: Account created, verification email sent
**Business Rules**:
- Email must be unique
- Password min 8 characters
- Email verification required before full access
**Priority**: P0
```

### Non-Functional Requirements

How the system behaves:

```markdown
### NFR-001: Response Time

**Category**: Performance
**Requirement**: Page load < 2 seconds on 3G connection
**Measurement**: Lighthouse performance score > 80
**Priority**: P1

### NFR-002: Availability

**Category**: Reliability
**Requirement**: 99.9% uptime during business hours
**Measurement**: Monitoring alerts, incident tracking
**Priority**: P0
```

### Technical Requirements

Implementation constraints:

```markdown
### TR-001: Tech Stack

**Frontend**: React 18+, TypeScript, Tailwind CSS
**Backend**: Node.js, PostgreSQL
**Infrastructure**: AWS (ECS, RDS, S3)
**Rationale**: Team expertise, existing infrastructure
```

---

## Complexity Assessment

### Complexity Factors

Score each factor 1-5:

| Factor | Score | Notes |
|--------|-------|-------|
| **Integration complexity** | ? | External APIs, legacy systems |
| **Data complexity** | ? | Schema design, migrations |
| **UI complexity** | ? | Custom components, interactions |
| **Business logic** | ? | Rules, workflows, edge cases |
| **Performance needs** | ? | Scale, real-time, optimization |
| **Security requirements** | ? | Auth, encryption, compliance |
| **Uncertainty** | ? | New tech, unclear requirements |

**Total Complexity**: Sum / 35 = Low (<40%) / Medium (40-70%) / High (>70%)

### Complexity-Driven Decisions

| Complexity | Approach |
|------------|----------|
| Low | Aggressive timeline, minimal planning |
| Medium | Standard planning, identify risks |
| High | Extra planning, spikes, phased delivery |

---

## Stakeholder Analysis

### Identify Stakeholders

```markdown
## Stakeholders

### Decision Makers
- **Product Owner**: [Name] — Final requirements authority
- **Tech Lead**: [Name] — Technical decisions
- **Design Lead**: [Name] — UX decisions

### Consulted
- **Engineering Team**: Implementation feedback
- **Customer Success**: User feedback
- **Legal**: Compliance review

### Informed
- **Leadership**: Progress updates
- **Marketing**: Launch coordination
```

### RACI Matrix

| Decision | Responsible | Accountable | Consulted | Informed |
|----------|-------------|-------------|-----------|----------|
| Feature priority | PM | PM | Eng, Design | Leadership |
| Tech architecture | Tech Lead | Tech Lead | Eng | PM |
| Timeline | PM, Tech Lead | PM | Eng | Leadership |

---

## Output: Analysis Document

### Template

```markdown
# PRD Analysis: [Project Name]

**Document Analyzed**: [Source document name/link]
**Analysis Date**: [Date]
**Analyst**: Claude

---

## Executive Summary

[2-3 sentences: What is this? What's the scope? What's the timeline?]

---

## Vision & Goals

**Problem Statement**: [What problem does this solve?]

**Target Users**: [Who is this for?]

**Success Metrics**:
- [Metric 1]
- [Metric 2]

---

## Scope

### In Scope
| Feature | Priority | Complexity |
|---------|----------|------------|
| ... | P0 | Medium |

### Out of Scope
- [Explicitly excluded items]

### Deferred
- [Future iteration items]

---

## Requirements Summary

### Functional Requirements
[Table or list of FRs with priority]

### Non-Functional Requirements
[Table of NFRs]

### Technical Constraints
[Stack, integrations, performance targets]

---

## Dependencies

### Internal
- [Team/system dependencies]

### External
- [Third-party dependencies]

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| ... | High/Med/Low | High/Med/Low | [Action] |

---

## Open Questions

1. [Question requiring stakeholder input]
2. [Question requiring stakeholder input]

---

## Assumptions

1. [Assumption made during analysis]
2. [Assumption made during analysis]

---

## Recommendation

[Overall assessment: Ready to plan? Needs clarification? Major concerns?]

**Recommended Next Steps**:
1. [Action item]
2. [Action item]
```

---

## Common PRD Patterns

### Well-Structured PRD

**Characteristics:**
- Clear problem statement
- Defined success metrics
- Prioritized feature list
- Technical constraints documented
- Explicit scope boundaries

**Analysis approach:** Direct extraction, minimal interpretation

### Vague/High-Level Brief

**Characteristics:**
- Vision without details
- "Make it great" type language
- Missing technical context
- No prioritization

**Analysis approach:**
1. Extract what's clear
2. Document all assumptions
3. Generate comprehensive questions
4. Propose scope for validation

### Technical-Heavy Spec

**Characteristics:**
- Implementation details but no "why"
- API specs without user context
- Database schemas without workflows

**Analysis approach:**
1. Reverse-engineer user needs
2. Map technical to functional
3. Identify missing user stories

### Scattered Requirements

**Characteristics:**
- Multiple documents/threads
- Contradictory statements
- No single source of truth

**Analysis approach:**
1. Consolidate all sources
2. Identify contradictions
3. Flag for resolution
4. Create unified view

---

## Quality Checklist

Before proceeding to task breakdown:

### Completeness
- [ ] Vision/goal is clear
- [ ] Users are identified
- [ ] Features are listed
- [ ] Priorities are assigned
- [ ] Constraints are documented

### Clarity
- [ ] Ambiguities are flagged
- [ ] Assumptions are documented
- [ ] Questions are listed
- [ ] Scope boundaries are explicit

### Feasibility
- [ ] Technical constraints are reasonable
- [ ] Timeline is realistic
- [ ] Dependencies are identified
- [ ] Risks are acknowledged

### Actionability
- [ ] Features are specific enough to break down
- [ ] Acceptance criteria exist or can be inferred
- [ ] Success metrics are measurable
