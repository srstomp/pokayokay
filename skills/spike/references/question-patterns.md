# Question Framing Patterns

How to transform vague concerns into spike-able questions that produce actionable outcomes.

---

## The Spike Question Formula

```
Can/Should [SUBJECT] [ACTION] [REQUIREMENT] within [CONSTRAINT]?
```

**Components:**
- **SUBJECT**: The technology, approach, or system under investigation
- **ACTION**: What you need it to do
- **REQUIREMENT**: Specific, measurable criteria
- **CONSTRAINT**: Boundaries (time, resources, existing systems)

---

## Transformation Patterns

### Pattern 1: Vague Technology → Specific Capability

**Vague**: "Look into Redis"

**Transform by asking**: What specifically do I need Redis to do?

| Step | Refinement |
|------|------------|
| Raw | "Look into Redis" |
| +Purpose | "Use Redis for caching" |
| +Requirement | "Use Redis to cache user session data" |
| +Constraint | "Cache user sessions with <10ms retrieval" |
| **Spike** | "Can Redis cache user sessions with <10ms retrieval and automatic expiration?" |

---

### Pattern 2: Exploration Request → A/B Decision

**Vague**: "Explore authentication options"

**Transform by asking**: What are we actually deciding between?

| Step | Refinement |
|------|------------|
| Raw | "Explore authentication options" |
| +Candidates | "Compare OAuth vs JWT vs session cookies" |
| +Context | "For our SPA with mobile apps" |
| +Criteria | "Security, implementation complexity, mobile support" |
| **Spike** | "Should we use OAuth2 or JWT for our SPA + mobile auth? (Criteria: security, complexity, mobile support)" |

---

### Pattern 3: Worry → Measurable Risk Question

**Vague**: "I'm worried about scalability"

**Transform by asking**: What specifically fails? Under what conditions?

| Step | Refinement |
|------|------------|
| Raw | "Worried about scalability" |
| +Component | "Worried about database scalability" |
| +Trigger | "Under high concurrent writes" |
| +Threshold | "When we hit 1000 writes/second" |
| **Spike** | "Can our PostgreSQL setup handle 1000 concurrent writes/second without degradation?" |

---

### Pattern 4: How Question → Architecture Decision

**Vague**: "How should we build the notification system?"

**Transform by asking**: What are the key architectural decisions?

| Step | Refinement |
|------|------------|
| Raw | "How should we build notifications?" |
| +Options | "Push vs pull, real-time vs polling" |
| +Constraint | "Must work offline, support millions of users" |
| +Focus | "Real-time delivery architecture" |
| **Spike** | "Should we use WebSockets or Server-Sent Events for real-time notifications? (Constraint: offline support, scale to 1M users)" |

---

### Pattern 5: Possibility → Feasibility Check

**Vague**: "Can we use GraphQL?"

**Transform by asking**: What would using GraphQL need to achieve?

| Step | Refinement |
|------|------------|
| Raw | "Can we use GraphQL?" |
| +Purpose | "For our mobile API" |
| +Requirement | "Support offline-first sync" |
| +Integration | "With existing REST backend" |
| **Spike** | "Can we add GraphQL for mobile while keeping REST backend, supporting offline sync?" |

---

## Question Quality Checklist

A good spike question should pass all checks:

| Check | Test | Example Fix |
|-------|------|-------------|
| **Answerable** | Can it be answered yes/no or A/B? | "How does X work?" → "Can X do Y?" |
| **Measurable** | Are success criteria concrete? | "Fast enough" → "<100ms response" |
| **Bounded** | Is scope clear? | "Investigate caching" → "Test Redis for session cache" |
| **Actionable** | Does answer lead to decision? | "Learn about X" → "Should we use X for Y?" |
| **Time-boxable** | Can it be answered in hours, not weeks? | Split into smaller questions |

---

## Domain-Specific Question Patterns

### Database/Storage

| Vague | Spike Question |
|-------|----------------|
| "Check out NoSQL options" | "Can MongoDB handle our document structure with <50ms queries at 10k docs?" |
| "Look into caching" | "Can we achieve 95% cache hit rate for user profile lookups with Redis?" |
| "Evaluate new database" | "Can database X migrate our 50GB dataset within 4-hour maintenance window?" |

### API/Integration

| Vague | Spike Question |
|-------|----------------|
| "Integrate with Stripe" | "Can we implement Stripe subscriptions with our existing user model in 2 days?" |
| "Check API compatibility" | "Does vendor API support our required fields: [list] with acceptable rate limits?" |
| "Look into webhooks" | "Can we reliably process vendor webhooks with at-least-once delivery guarantee?" |

### Performance

| Vague | Spike Question |
|-------|----------------|
| "Optimize the dashboard" | "Can we reduce dashboard load time from 3s to <1s without caching?" |
| "Make it faster" | "Can we achieve <200ms API response for listing endpoint at 1000 RPS?" |
| "Handle more traffic" | "Can our current infrastructure handle 5x traffic with horizontal scaling only?" |

### Security

| Vague | Spike Question |
|-------|----------------|
| "Review security" | "Are there known vulnerabilities in our auth flow that attackers could exploit?" |
| "Check compliance" | "Does our data handling meet GDPR requirements for [specific scenario]?" |
| "Evaluate encryption" | "Can we implement E2E encryption without breaking existing features?" |

### Architecture

| Vague | Spike Question |
|-------|----------------|
| "Consider microservices" | "Would extracting auth to separate service reduce deployment complexity?" |
| "Evaluate event sourcing" | "Can event sourcing handle our audit requirements without excessive storage?" |
| "Look at serverless" | "Can we move batch processing to Lambda within $X/month budget?" |

---

## Red Flags: Questions That Need Refinement

### Too Broad

❌ "Investigate the best approach for X"
✅ "Compare approach A vs B for X based on [criteria]"

### No Success Criteria

❌ "Check if X works"
✅ "Verify X can handle [specific requirement]"

### Unbounded

❌ "Explore options for Y"
✅ "Evaluate top 2 options for Y against [criteria]"

### Multiple Questions

❌ "Can we use X, and if so, how should we structure it, and what are the risks?"
✅ Split into 3 separate spikes:
1. "Can we use X for [purpose]?" (Feasibility)
2. "How should we structure X integration?" (Architecture)
3. "What are the risks of using X?" (Risk)

---

## Generating Questions from Concerns

When someone says "I'm concerned about X," use this template:

```markdown
## Concern Analysis: [Topic]

**Raw Concern**: [What they said]

**Underlying Questions**:
1. Feasibility: Can we [capability] with [technology]?
2. Performance: Can [system] handle [load] within [constraint]?
3. Risk: What could go wrong with [approach]?
4. Architecture: Should we use [option A] or [option B]?

**Spike Priority**: [Which question is most critical?]

**Proposed Spike Question**: [Final question]
```

---

## From Vague to Spike: Complete Example

**Initial Request**: "We need to look into real-time features"

### Step 1: Clarify Purpose
**Ask**: What real-time features specifically?
**Answer**: Chat and presence indicators

### Step 2: Identify Options
**Options**: WebSockets, Server-Sent Events, Polling, Third-party (Pusher/Ably)

### Step 3: Define Constraints
- Scale: 10k concurrent users
- Budget: <$500/month
- Team expertise: Limited WebSocket experience

### Step 4: Pick Primary Question
Most critical unknown: Can we build this ourselves vs. use third-party?

### Step 5: Frame Spike Question
**Spike**: "Can we implement presence indicators with WebSockets for 10k concurrent users, or should we use Pusher? (Criteria: cost <$500/mo, complexity, reliability)"

---

## Question Validation Template

Before starting any spike, validate the question:

```markdown
## Spike Question Validation

**Question**: [Your spike question]

### Validation Checks
- [ ] Has clear yes/no or A/B answer
- [ ] Success criteria are measurable
- [ ] Scope is bounded (not "explore")
- [ ] Can be answered in [time box]
- [ ] Outcome leads to decision

### If Any Check Fails
**Problem**: [Which check failed]
**Refined Question**: [Improved version]
```
