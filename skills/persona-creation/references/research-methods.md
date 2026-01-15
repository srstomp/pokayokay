# Research Methods

How to gather the data that informs personas.

## Research Planning

### Define Research Goals

Before any research, answer:
1. **What decisions will this inform?** (Features, positioning, UX)
2. **What do we already know?** (Existing data, assumptions)
3. **What are our riskiest assumptions?** (Prioritize validating these)
4. **Who are we trying to understand?** (User segments)

### Research Plan Template

```markdown
# Research Plan: [Project Name]

## Objectives
- Primary: [Main question to answer]
- Secondary: [Supporting questions]

## Methodology
- Method: [Interview/Survey/Observation/etc.]
- Participants: [Who, how many, recruitment criteria]
- Timeline: [Dates]

## Key Questions
1. [Question targeting specific assumption]
2. [Question targeting specific behavior]
3. [Question targeting specific need]

## Success Criteria
- [How we know we have enough data]
- [What good answers look like]

## Logistics
- Recruitment: [How we'll find participants]
- Incentive: [Compensation if any]
- Recording: [How we'll capture data]
```

---

## User Interviews

### Interview Types

| Type | Duration | Best For |
|------|----------|----------|
| Discovery | 45-60 min | Understanding context, needs, behaviors |
| Validation | 20-30 min | Testing specific assumptions |
| Contextual | 60-90 min | Observing real environment |

### Interview Structure

**1. Warm-up (2-3 min)**
- Thank them for time
- Explain purpose (learning, not selling)
- Confirm recording consent
- "No wrong answers"

**2. Context Setting (5-10 min)**
- Role and background
- Typical day/workflow
- Relationship to problem space

**3. Core Exploration (25-40 min)**
- Past experiences with problem
- Current solutions and workarounds
- Frustrations and unmet needs
- Decision-making process

**4. Specifics (10-15 min)**
- Walk through recent example
- Details on frequency, triggers
- Tools and people involved

**5. Wrap-up (3-5 min)**
- Anything else to add
- Who else should we talk to
- Thank and next steps

### Question Frameworks

**Open-ended starters:**
- "Tell me about the last time you..."
- "Walk me through how you typically..."
- "Describe a situation where..."

**Follow-up probes:**
- "Why was that important?"
- "How did that make you feel?"
- "What happened next?"
- "Can you give me an example?"

**Behavior-focused:**
- "What do you do when [situation]?"
- "How often does [behavior] happen?"
- "What triggers you to [action]?"

**Avoiding leading questions:**
- ❌ "Don't you find X frustrating?"
- ✅ "How do you feel about X?"
- ❌ "Would you use a product that does Y?"
- ✅ "What would make Y easier for you?"

### Interview Guide Template

```markdown
# Interview Guide: [Topic]

## Participant Criteria
- [Who qualifies]
- [Who doesn't qualify]

## Introduction Script
"Hi [Name], thanks for taking the time. I'm [Name] from [Company]. 
We're trying to understand how people [problem area] so we can 
build better solutions. There are no right or wrong answers — 
we just want to learn from your experience. Is it okay if I 
record this for note-taking purposes?"

## Warm-up
1. Tell me a bit about your role.
2. How long have you been doing [activity]?

## Core Questions

### Understanding Current State
3. Walk me through how you currently [task].
4. What tools or methods do you use?
5. Who else is involved in this process?

### Pain Points
6. What's the most frustrating part of [task]?
7. Tell me about a time when [task] went wrong.
8. What workarounds have you developed?

### Needs and Goals
9. If you could wave a magic wand, what would change?
10. What would success look like for you?
11. What's preventing you from [goal] today?

### Wrap-up
12. Is there anything else about [topic] I should know?
13. Who else should I talk to about this?

## Closing Script
"Thank you so much for your time. This was incredibly helpful. 
[Next steps if any]. Do you have any questions for me?"
```

---

## Surveys

### When to Use Surveys

**Good for:**
- Quantifying behaviors and preferences
- Reaching larger sample sizes
- Validating interview findings
- Tracking changes over time

**Not good for:**
- Deep understanding of why
- Discovering unknown problems
- Complex or nuanced topics

### Survey Design Principles

1. **Keep it short**: 5-10 minutes max
2. **One topic per question**: Don't double-barrel
3. **Specific timeframes**: "In the past week" not "usually"
4. **Balanced scales**: Equal positive and negative options
5. **Mobile-friendly**: Many will take on phone

### Question Types

**Multiple choice (single answer):**
```
How often do you [behavior]?
○ Daily
○ Weekly
○ Monthly
○ Rarely
○ Never
```

**Multiple choice (multi-select):**
```
Which of the following do you use? (Select all that apply)
☐ Option A
☐ Option B
☐ Option C
☐ Other: ___
```

**Likert scale:**
```
[Statement about attitude or behavior]
○ Strongly disagree
○ Disagree
○ Neutral
○ Agree
○ Strongly agree
```

**Open-ended:**
```
What's the most frustrating part of [task]?
[                                          ]
```

### Survey Structure

1. **Screener questions** (if needed)
2. **Behavioral questions** (what they do)
3. **Attitudinal questions** (how they feel)
4. **Demographics** (at the end, optional)

### Sample Survey Template

```markdown
# [Topic] Survey

## Introduction
We're researching how people [topic] to improve our product. 
This takes about 5 minutes. Your responses are anonymous.

## Screener (if needed)
1. Do you [qualifying behavior]?
   - Yes → Continue
   - No → End survey

## Current Behavior
2. How often do you [behavior]?
   [Frequency scale]

3. Which tools do you currently use for [task]?
   [Multi-select options]

4. On average, how much time do you spend on [task] per week?
   [Time ranges]

## Pain Points
5. Rate your agreement: "[Task] is easy to accomplish"
   [Likert scale]

6. What's the biggest challenge you face with [task]?
   [Open text]

## Needs
7. How important is [feature/capability] to you?
   [Importance scale]

8. What would make [task] significantly easier?
   [Open text]

## Demographics (optional)
9. What is your role?
   [Options]

10. Company size?
    [Ranges]

## Close
Thank you! [Optional: email for follow-up interview]
```

---

## Observation & Contextual Inquiry

### Contextual Inquiry Structure

1. **Introduction** (5 min)
   - Explain purpose
   - Set expectations (you do, I watch)

2. **Observation** (30-60 min)
   - Watch them work
   - Take notes on actions, tools, environment
   - Note workarounds and frustrations

3. **Retrospective** (15-20 min)
   - Walk through what you observed
   - Ask clarifying questions
   - Explore why they did certain things

### Observation Notes Template

```markdown
# Contextual Inquiry: [Participant ID]

## Context
- Date/time: 
- Location: 
- Their role: 
- Environment: 

## Workflow Observed
| Time | Action | Tools Used | Notes |
|------|--------|------------|-------|
| 0:00 | Started task X | Tool A | Seemed frustrated |
| 0:05 | Switched to manual workaround | Spreadsheet | "I always have to do this" |

## Key Observations
1. [Observation with implication]
2. [Observation with implication]

## Quotes
- "[Verbatim quote]" — context
- "[Verbatim quote]" — context

## Artifacts Collected
- [Screenshot/photo description]
- [Document sample]

## Follow-up Questions
- Why did they [observed behavior]?
- How often does [situation] happen?
```

---

## Research Synthesis

### Affinity Mapping

1. **Gather observations** (one per sticky note)
2. **Group similar observations** (bottom-up clustering)
3. **Name the groups** (themes that emerge)
4. **Identify patterns** (what appears across multiple users)
5. **Generate insights** (implications for design)

### Insight Format

```
We observed that [specific behavior/pattern],
which suggests [user need/motivation],
so we should consider [design implication].
```

**Examples:**
- "We observed that 4 of 5 participants created spreadsheet workarounds for tracking status, which suggests the current tool lacks visibility, so we should consider adding a dashboard view."
- "We observed that users check email immediately after submitting a request, which suggests they want confirmation of receipt, so we should consider adding immediate feedback."

### Synthesis Document Template

```markdown
# Research Synthesis: [Project Name]

## Research Summary
- **Dates**: [When conducted]
- **Methods**: [Interview/Survey/etc.]
- **Participants**: [Number and criteria]

## Key Themes

### Theme 1: [Name]
**Pattern**: [What we observed repeatedly]
**Quotes**:
- "[Quote]" — P1
- "[Quote]" — P3
**Insight**: [What this means]
**Implication**: [How this affects design]

### Theme 2: [Name]
[Same structure]

## User Segments Identified
Based on research, we identified [N] distinct user types:
1. **[Segment name]**: [Brief description]
2. **[Segment name]**: [Brief description]

## Prioritized Needs
| Need | Frequency | Severity | Priority |
|------|-----------|----------|----------|
| [Need] | 5/5 users | High | P1 |
| [Need] | 3/5 users | Medium | P2 |

## Recommended Next Steps
1. [Action item]
2. [Action item]

## Appendix
- [Link to raw notes]
- [Link to recordings]
```

---

## Participant Recruitment

### Recruitment Criteria

Define clearly:
- **Must have**: Required characteristics
- **Nice to have**: Preferred but not required
- **Exclude**: Disqualifying factors

### Recruitment Sources

| Source | Best For | Pros | Cons |
|--------|----------|------|------|
| Existing users | Current experience | Easy access, relevant | May be biased |
| Social/community | Early research | Diverse perspectives | Harder to qualify |
| Recruiting service | Specific criteria | Professional, fast | Expensive |
| Customer referrals | Expansion research | Warm intro | Network bias |

### Screener Questions

```markdown
# Participant Screener: [Study Name]

1. Do you currently use [category of product]?
   - Yes → Continue
   - No → End

2. How often do you [key behavior]?
   - Daily/Weekly → Qualify
   - Monthly or less → May qualify (note)
   - Never → End

3. What is your role?
   - [Target roles] → Qualify
   - Other → End

4. [Additional qualifying question]

## Qualified if:
- [Criteria summary]

## Compensation:
- [Amount/gift card]

## Scheduling:
- [Link to calendar/scheduler]
```

### Sample Sizes

| Method | Minimum | Recommended | Notes |
|--------|---------|-------------|-------|
| Interviews | 5 | 8-12 | 5 finds ~85% of issues |
| Surveys | 30 | 100+ | For statistical significance |
| Usability tests | 5 | 5-8 per round | Test, fix, repeat |
| Contextual inquiry | 3 | 5-8 | Resource intensive |

---

## Persona Validation

Personas are hypotheses until validated. Here's how to confirm they reflect reality.

### When to Validate

| Situation | Action |
|-----------|--------|
| Proto-personas created | Validate before design decisions |
| Major product pivot | Re-validate existing personas |
| Personas over 6 months old | Scheduled review |
| User feedback contradicts persona | Investigate and update |
| Entering new market segment | Validate for new context |

### Validation Methods

#### 1. Quantitative Survey

Confirm persona attributes at scale.

**Approach:**
1. Extract key claims from persona (behaviors, goals, frustrations)
2. Convert to survey questions
3. Survey larger sample (100+)
4. Compare results to persona claims

**Example:**
```
Persona claim: "Checks project status 3-4 times daily"

Survey question:
How often do you check on project status?
○ Multiple times per hour
○ 3-5 times per day       ← Target
○ Once daily
○ A few times per week
○ Weekly or less
```

**Validation threshold:** If <60% of respondents match persona claim, investigate.

#### 2. Analytics Validation

Use behavioral data to confirm stated behaviors.

**What to check:**
| Persona Claim | Analytics Validation |
|---------------|---------------------|
| "Uses mobile primarily" | Device breakdown in analytics |
| "Visits daily" | Session frequency data |
| "Completes task in <2 min" | Time-on-task metrics |
| "Abandons at pricing page" | Funnel drop-off data |

**Watch for:** Stated behavior (interviews) vs. actual behavior (analytics) gaps. People say one thing, do another.

#### 3. Segment Analysis

Confirm persona segments exist in your actual user base.

**Approach:**
1. Identify defining characteristics of each persona
2. Query your user data for those characteristics
3. Check if segments are:
   - Distinct (not overlapping significantly)
   - Substantial (large enough to matter)
   - Behaving as predicted

**Example:**
```sql
-- Do "power users" (Persona: Marcus) actually exist?
SELECT 
  COUNT(*) as user_count,
  AVG(sessions_per_week) as avg_sessions,
  AVG(features_used) as avg_features
FROM users
WHERE 
  sessions_per_week > 10 
  AND account_age_days > 30
```

If segment is tiny or doesn't behave as described, persona needs revision.

#### 4. Predictive Validation

Test if persona predicts real user behavior.

**Approach:**
1. Use persona to predict how users will respond to new feature/change
2. Ship the change
3. Measure actual response
4. Compare prediction to reality

**Example:**
```
Prediction: "Marcus (eng manager) will use the new dashboard view 
            because he needs quick status visibility"

Result: Dashboard adoption by manager segment = 12%

Conclusion: Persona missed something. Investigate why.
```

### Validation Documentation

Track validation status on every persona:

```markdown
## Validation Status

| Claim | Method | Result | Date |
|-------|--------|--------|------|
| Checks status 3-4x daily | Survey (n=142) | Confirmed (68%) | Jan 2024 |
| Uses mobile primarily | Analytics | Refuted (23% mobile) | Jan 2024 |
| Frustrated by manual reporting | Interviews (5) | Confirmed | Dec 2023 |

**Overall confidence:** Medium — mobile claim needs revision
**Next validation:** April 2024
**Owner:** [Name]
```

### Updating After Validation

When validation reveals gaps:

1. **Minor discrepancy** (one attribute off): Update the attribute, note the change
2. **Major discrepancy** (core behavior wrong): Investigate with qualitative research before updating
3. **Segment doesn't exist**: Retire the persona, consolidate with another
4. **New segment discovered**: Create new persona, validate it

### Validation Cadence

| Persona Type | Validation Frequency |
|--------------|---------------------|
| Proto-persona | Before any design decisions |
| New persona | Within 30 days of creation |
| Established persona | Quarterly review |
| Post-pivot | Immediate re-validation |

### Red Flags Requiring Immediate Validation

- Customer feedback consistently contradicts persona
- Support tickets from "unexpected" user types
- Feature adoption doesn't match persona predictions
- Sales reports different user motivations
- Churn analysis shows missed frustrations
