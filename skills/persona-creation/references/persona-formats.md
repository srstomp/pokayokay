# Persona Formats

Detailed templates for each persona type.

## Format Comparison

| Format | Effort | Data Required | Best For |
|--------|--------|---------------|----------|
| Proto-Persona | Low | Assumptions | Early stage, alignment |
| Traditional Persona | High | Research data | Design decisions |
| JTBD Profile | Medium | Motivation research | Feature prioritization |
| Empathy Map | Low-Medium | Qualitative data | Team workshops |

---

## Proto-Personas

Assumption-based personas for early-stage alignment. **Must be validated with research.**

### When to Use
- No time/budget for research yet
- Need team alignment on assumptions
- Starting hypothesis to test
- Pre-research planning

### Proto-Persona Template

```markdown
# Proto-Persona: [Name]

⚠️ **STATUS: HYPOTHESIS — Requires validation**

## Quick Profile
| Attribute | Assumption |
|-----------|------------|
| Role | [Job title/context] |
| Age range | [Range] |
| Tech comfort | [Low/Medium/High] |
| Key context | [Relevant situation] |

## Assumed Goals
1. [What we think they want]
2. [What we think they want]

## Assumed Frustrations
1. [What we think frustrates them]
2. [What we think frustrates them]

## Assumed Behaviors
- [How we think they currently solve this]
- [Tools we think they use]

## Key Assumptions to Validate
1. [ ] [Critical assumption #1]
2. [ ] [Critical assumption #2]
3. [ ] [Critical assumption #3]

## Validation Plan
- Method: [Interview/Survey/etc.]
- Sample: [Who to talk to]
- Timeline: [When]

---
Created: [Date]
Confidence: Low (hypothesis only)
Last validated: Never
```

### Proto-Persona Example

```markdown
# Proto-Persona: Startup Sarah

⚠️ **STATUS: HYPOTHESIS — Requires validation**

## Quick Profile
| Attribute | Assumption |
|-----------|------------|
| Role | Founder/CEO at early-stage startup |
| Age range | 28-40 |
| Tech comfort | High |
| Key context | Pre-seed to Series A, <20 employees |

## Assumed Goals
1. Ship product quickly to validate market
2. Keep team aligned without heavy process
3. Impress investors with progress

## Assumed Frustrations
1. Too many tools, nothing integrated
2. Context switching kills productivity
3. Hard to see what everyone is working on

## Assumed Behaviors
- Uses Slack for everything
- Cobbles together free tools
- Works evenings and weekends
- Makes decisions quickly, iterates

## Key Assumptions to Validate
1. [ ] Prefers simple over feature-rich
2. [ ] Price sensitive but values time more
3. [ ] Team size is primary scaling trigger

## Validation Plan
- Method: 5-8 founder interviews
- Sample: Founders at pre-seed to Series A
- Timeline: 2 weeks
```

---

## Traditional Personas

Research-backed, comprehensive profiles for design decisions.

### When to Use
- Have completed user research
- Making significant design decisions
- Need shared understanding across team
- Informing marketing and positioning

### Traditional Persona Template

```markdown
# [Persona Name]

> "[Characteristic quote that captures their mindset]"

## Demographics
| Attribute | Value |
|-----------|-------|
| Name | [Representative name] |
| Age | [Age or range] |
| Location | [Where they are] |
| Role | [Job title/context] |
| Experience | [Years in role] |
| Tech proficiency | [Low/Medium/High + specifics] |

## Background
[2-3 sentences of relevant context: career path, current situation, 
what brought them to this point. Based on research patterns.]

## Goals
### Primary
- [Main thing they're trying to achieve]

### Secondary
- [Supporting goal]
- [Supporting goal]

## Frustrations
1. **[Pain point]**: [Specific detail from research]
2. **[Pain point]**: [Specific detail from research]
3. **[Pain point]**: [Specific detail from research]

## Behaviors
### Current Workflow
- [How they currently solve the problem]
- [Tools and methods used]
- [Frequency and triggers]

### Decision Making
- [How they evaluate solutions]
- [Who influences their decisions]
- [What information they need]

### Communication
- [Preferred channels]
- [How they learn about new tools]

## Motivations
- **Driven by**: [What motivates them]
- **Avoids**: [What they want to minimize]
- **Values**: [What matters to them]

## Quote Bank
> "[Real quote from research]"
> "[Real quote from research]"
> "[Real quote from research]"

## Scenario
[Brief story: A day in their life dealing with the problem we solve.
Written in present tense, specific details.]

## Design Implications
| Insight | Implication |
|---------|-------------|
| [Behavior/need] | [How this affects our design] |
| [Behavior/need] | [How this affects our design] |

---
**Research basis**: [N] interviews, [Date]
**Last updated**: [Date]
**Owner**: [Who maintains this]
```

### Traditional Persona Example

```markdown
# Marcus Chen

> "I don't need more features. I need fewer tools."

## Demographics
| Attribute | Value |
|-----------|-------|
| Name | Marcus Chen |
| Age | 34 |
| Location | Austin, TX |
| Role | Engineering Manager |
| Experience | 3 years managing, 8 years as IC |
| Tech proficiency | High (former developer) |

## Background
Marcus transitioned from senior developer to engineering manager 
3 years ago. He leads a team of 8 engineers at a Series B startup. 
He misses coding but finds satisfaction in unblocking his team.

## Goals
### Primary
- Keep his team productive and unblocked

### Secondary
- Maintain visibility into project status without micromanaging
- Protect team from scope creep and meeting overload
- Develop team members' careers

## Frustrations
1. **Context scattered everywhere**: "I check Jira, then Slack, 
   then GitHub, then Notion just to understand what's happening."
2. **Status update theater**: "We spend more time reporting progress 
   than making progress."
3. **No early warning system**: "I find out about blockers in standup, 
   which is already too late."

## Behaviors
### Current Workflow
- Checks Slack first thing, responds to overnight messages
- 3-4 hours daily in meetings (wants to reduce)
- Manually compiles status updates from multiple tools
- 1:1s with each team member weekly

### Decision Making
- Tries tools during free trials before committing
- Asks for peer recommendations in Slack communities
- Needs to justify spend to VP Engineering
- Won't adopt tools team resists

### Communication
- Lives in Slack
- Skims email, misses things there
- Prefers async updates over meetings

## Motivations
- **Driven by**: Seeing team succeed and ship
- **Avoids**: Being a bottleneck or helicopter manager
- **Values**: Transparency, autonomy, craft

## Quote Bank
> "My job is to create space for them to do great work."
> "Every tool I add is another thing they have to learn."
> "I'd pay real money for fewer meetings."

## Scenario
It's Monday morning. Marcus opens Slack to 47 unread messages. 
He scans for anything urgent, then opens Jira to prep for standup. 
Three tickets are blocked but not flagged. He sighs, pulls up the 
PR queue in GitHub, sees two reviews stalled. He spends 20 minutes 
piecing together the real status before the 10am standup.

## Design Implications
| Insight | Implication |
|---------|-------------|
| Uses 4+ tools daily | Must integrate, not replace |
| Hates status update theater | Automate status inference |
| Discovers blockers too late | Proactive notifications |
| Values team autonomy | Visibility without surveillance |

---
**Research basis**: 6 interviews, January 2024
**Last updated**: January 15, 2024
**Owner**: Product Team
```

---

## JTBD Profiles

Focus on motivation and the "job" users hire products to do.

### When to Use
- Prioritizing features
- Understanding competitive alternatives
- Reducing demographic assumptions
- Finding new market opportunities

### JTBD Core Concepts

**The Job Statement:**
```
When [situation], I want to [motivation], so I can [outcome].
```

**Hiring and Firing:**
- **Hire**: Why they start using a product
- **Fire**: Why they stop or switch

**Four Forces of Progress:**
- **Push**: Problems with current solution
- **Pull**: Attraction of new solution
- **Anxiety**: Fear of change
- **Habit**: Comfort with current way

### JTBD Profile Template

```markdown
# JTBD Profile: [Job Name]

## The Job
> When [situation/trigger], 
> I want to [motivation/action], 
> so I can [desired outcome].

## Context
### Trigger Situations
- [When does this job arise?]
- [What prompts them to seek a solution?]

### Frequency
[How often does this job need doing?]

### Current Solutions
| Solution | Hired For | Fired Because |
|----------|-----------|---------------|
| [Current tool/method] | [What it does well] | [Where it falls short] |
| [Alternative] | [What it does well] | [Where it falls short] |

## Four Forces

### Push (Away from current solution)
- [Problem with status quo]
- [Frustration driving change]

### Pull (Toward new solution)
- [Attractive capability]
- [Desired improvement]

### Anxiety (Preventing change)
- [Fear or uncertainty]
- [Risk they perceive]

### Habit (Keeping them stuck)
- [Comfort with current way]
- [Switching cost]

## Job Stories

### Main Job Story
When [specific situation],
I want to [specific action],
so I can [specific outcome].

### Related Job Stories
When [situation], I want to [action], so I can [outcome].
When [situation], I want to [action], so I can [outcome].

## Success Metrics
How do they measure if the job is done well?
- [Metric they care about]
- [Outcome they measure]

## Hiring Criteria
When evaluating solutions, they look for:
1. [Priority criterion]
2. [Secondary criterion]
3. [Tertiary criterion]

## Design Implications
| Job Insight | Product Implication |
|-------------|---------------------|
| [Need from job] | [Feature/approach] |
| [Constraint from context] | [Design consideration] |

---
**Research basis**: [Method and date]
**Related personas**: [Link to traditional personas if any]
```

### JTBD Profile Example

```markdown
# JTBD Profile: Stay Informed on Project Status

## The Job
> When I'm preparing for a stakeholder meeting, 
> I want to quickly understand project health and blockers, 
> so I can give confident updates without looking unprepared.

## Context
### Trigger Situations
- 30 minutes before exec meeting
- Monday morning planning
- When stakeholder asks unexpected question
- Before committing to new deadline

### Frequency
2-3 times daily for formal updates, continuously for awareness

### Current Solutions
| Solution | Hired For | Fired Because |
|----------|-----------|---------------|
| Slack scanning | Real-time, from the source | Time-consuming, easy to miss things |
| Jira dashboards | Official record | Out of date, noisy, requires interpretation |
| Standup meetings | Face-to-face, unblocks | Only once daily, time-consuming |
| Asking team directly | Accurate, immediate | Interrupts them, doesn't scale |

## Four Forces

### Push (Away from current solution)
- Takes 20+ minutes to piece together status
- Information scattered across 4+ tools
- Find out about blockers too late
- Look unprepared in front of stakeholders

### Pull (Toward new solution)
- Single view of project health
- Early warning on risks
- Confidence in stakeholder meetings
- Less time chasing information

### Anxiety (Preventing change)
- "Will my team actually use this?"
- "Is this just another tool to check?"
- "What if it's wrong and I rely on it?"

### Habit (Keeping them stuck)
- Current workflow is familiar
- Team already uses these tools
- Sunk cost in existing setup

## Job Stories

### Main Job Story
When I'm about to meet with stakeholders,
I want a 30-second summary of project status,
so I can answer questions confidently.

### Related Job Stories
When a team member seems stuck,
I want to know before they escalate,
so I can unblock them proactively.

When priorities shift mid-week,
I want to see impact on all projects,
so I can reset expectations appropriately.

## Success Metrics
- Time from "need status" to "have status" (target: <1 min)
- Surprise blockers discovered in meetings (target: 0)
- Hours spent on status compilation (target: reduce 50%)

## Hiring Criteria
1. **Speed**: Can I get the answer in under a minute?
2. **Accuracy**: Can I trust this in front of stakeholders?
3. **Adoption**: Will my team actually use this?
4. **Integration**: Does it work with our current tools?

## Design Implications
| Job Insight | Product Implication |
|-------------|---------------------|
| Needs answer in 30 seconds | Summary view, not detailed dashboard |
| Stakes are stakeholder trust | Must be accurate, show data freshness |
| Competes with Slack/Jira combo | Must integrate, not replace |
| Fear of team non-adoption | Passive data collection preferred |
```

---

## Empathy Maps

Visual synthesis of user mindset for team alignment.

### When to Use
- Workshop settings
- Quick alignment on user perspective
- Synthesizing interview findings
- Complementing other persona formats

### Empathy Map Structure

```
┌─────────────────────────────────────────────────────────────┐
│                          [Name]                             │
│                      [Goal/Situation]                       │
├─────────────────────────────┬───────────────────────────────┤
│         THINKS & FEELS      │           SEES                │
│                             │                               │
│  What occupies their        │  What is their environment?   │
│  thinking?                  │  What do they see others      │
│                             │  doing?                       │
│  What matters to them       │  What are they exposed to?    │
│  (unspoken)?                │                               │
│                             │                               │
├─────────────────────────────┼───────────────────────────────┤
│           HEARS             │         SAYS & DOES           │
│                             │                               │
│  What do colleagues,        │  What is their public         │
│  friends, influencers       │  behavior?                    │
│  say?                       │  What do they say to others?  │
│                             │                               │
│  What channels              │  What actions do they take?   │
│  influence them?            │                               │
│                             │                               │
├─────────────────────────────┴───────────────────────────────┤
│                          PAINS                              │
│  What frustrates them? What obstacles do they face?         │
│  What risks do they fear?                                   │
├─────────────────────────────────────────────────────────────┤
│                          GAINS                              │
│  What do they want to achieve? How do they measure success? │
│  What would make their life easier?                         │
└─────────────────────────────────────────────────────────────┘
```

### Empathy Map Template (Markdown)

```markdown
# Empathy Map: [Name]

**Context**: [Situation/goal we're mapping]

## Thinks & Feels
*Internal thoughts, emotions, worries*
- [Thought/concern]
- [Emotion]
- [Unspoken worry]

## Sees
*Environment, market, what others do*
- [What they observe]
- [Industry trends they notice]
- [Competitor behaviors]

## Hears
*Influences, channels, what others say*
- [What colleagues say]
- [Industry influencers]
- [Family/friends input]

## Says & Does
*Public behavior, observable actions*
- [Statements they make]
- [Actions they take]
- [How they behave in public]

## Pains
*Frustrations, obstacles, fears*
- [Major frustration]
- [Obstacle to success]
- [Risk they worry about]

## Gains
*Goals, success measures, desires*
- [What they want to achieve]
- [How they measure success]
- [What would delight them]

---
**Created**: [Date]
**Session participants**: [Who contributed]
**Source data**: [Interviews/observations referenced]
```

### Empathy Map Example

```markdown
# Empathy Map: Marcus (Engineering Manager)

**Context**: Managing team productivity and stakeholder expectations

## Thinks & Feels
- "Am I doing a good job as a manager?"
- Worried about burning out high performers
- Wants to be seen as an enabler, not a blocker
- Feels pressure from both team and leadership
- Misses the clarity of being an IC

## Sees
- Team using 5+ tools daily
- Other managers struggling with same problems
- Industry trend toward "maker time" and async
- Competitors shipping faster
- VP checking Jira more frequently

## Hears
- Team complaining about meetings
- Leadership asking for "more visibility"
- Podcasts about engineering management
- Twitter debates about remote work
- Spouse asking why he's always stressed

## Says & Does
- Advocates publicly for team autonomy
- Shields team from interruptions
- Cancels recurring meetings aggressively
- Writes detailed status updates weekly
- Takes calls in off-hours to avoid team interruption

## Pains
- No single source of truth for status
- Surprised by blockers in standup
- Spends 20+ min/day compiling updates
- Feels like a bottleneck
- Can't protect team and keep leadership informed

## Gains
- Team ships without needing him
- Confident in stakeholder conversations
- Early warning on problems
- More time for strategic work
- Team members growing in their careers

---
**Created**: January 2024
**Session participants**: Product, Design, Eng leads
**Source data**: 6 manager interviews
```

---

## Choosing the Right Format

### Decision Matrix

```
                          Research Available?
                         No                 Yes
                    ┌──────────────────┬──────────────────┐
Need Quick          │ Proto-Persona    │ Empathy Map      │
Alignment?   Yes    │ (validate later) │ (workshop format)│
                    ├──────────────────┼──────────────────┤
                    │ Wait for research│ Full format:     │
             No     │ before detailed  │ Traditional +    │
                    │ personas         │ JTBD + Journey   │
                    └──────────────────┴──────────────────┘
```

### Combining Formats

Often best to use multiple:
1. **Proto-Personas** → Start here to align and plan research
2. **Research** → Validate and deepen understanding
3. **Traditional Personas** → Full profiles from research
4. **JTBD Profiles** → Add motivation layer
5. **Empathy Maps** → Workshop tool for team alignment
6. **Journey Maps** → Map experience over time

Each format illuminates different aspects of the user.

---

## Persona Anti-Patterns

Common mistakes that make personas useless or harmful.

### Anti-Pattern 1: The Invented Persona

**Problem:** Persona created from assumptions, not research.

```
❌ "Let's brainstorm who our users are"
❌ "I think our users probably..."
❌ Demographics copied from marketing materials
```

**Why it fails:** Confirms biases instead of revealing insights. Team builds for imaginary user.

**Fix:** Any persona without research backing should be explicitly labeled "Proto-Persona" with validation plan.

---

### Anti-Pattern 2: The Demographic Shell

**Problem:** All demographics, no behavior or motivation.

```
❌ Sarah, 34, lives in Austin, married, two kids, drives a Honda...
   [But what does she actually DO? What does she NEED?]
```

**Why it fails:** Demographics don't inform design decisions. Knowing she's 34 doesn't tell you how to build the interface.

**Fix:** Lead with goals, frustrations, and behaviors. Demographics only if they affect the product.

---

### Anti-Pattern 3: The Flattering Mirror

**Problem:** Persona describes who the team *wishes* users were.

```
❌ "Power users who love exploring features"
❌ "Early adopters excited about our technology"
❌ "Users who read documentation thoroughly"
```

**Why it fails:** Builds for fantasy user, alienates real ones.

**Fix:** Include inconvenient truths: "Switches between 4 apps, won't learn new workflows," "Skips onboarding, expects immediate value."

---

### Anti-Pattern 4: The Zombie Persona

**Problem:** Created once, never updated, still referenced years later.

```
❌ "According to our persona from 2019..."
❌ Persona references deprecated features
❌ Market has shifted but persona hasn't
```

**Why it fails:** Outdated personas mislead decisions. Worse than no persona.

**Fix:** Date every persona. Schedule quarterly reviews. Kill personas that no longer reflect reality.

---

### Anti-Pattern 5: The Persona Explosion

**Problem:** Too many personas, each representing tiny segment.

```
❌ 12 personas for a simple B2B tool
❌ Separate personas for minor variations
❌ "We need one for every industry vertical"
```

**Why it fails:** Dilutes focus. Can't design for 12 people at once. Team ignores all of them.

**Fix:** 3-5 personas maximum. If you need more, you're building multiple products or need better segmentation.

---

### Anti-Pattern 6: The Useless Detail

**Problem:** Persona includes irrelevant specifics that don't inform design.

```
❌ "Marcus enjoys hiking on weekends and has a golden retriever named Max"
   [Unless you're building a hiking or pet app, this is noise]
```

**Why it fails:** Clutters the document. Team can't distinguish signal from noise.

**Fix:** Every detail should answer: "How does this affect what we build?" If it doesn't, cut it.

---

### Anti-Pattern 7: The Solo Author

**Problem:** One person creates personas in isolation.

```
❌ "I wrote up our personas, here they are"
❌ No team input or review
❌ Presented as finished artifact
```

**Why it fails:** No buy-in. Team doesn't trust or use them. Misses perspectives.

**Fix:** Collaborative synthesis workshops. Team reviews drafts. Personas are team artifacts, not documents thrown over the wall.

---

### Anti-Pattern 8: The Jargon Persona

**Problem:** Written in UX/product jargon instead of human language.

```
❌ "Seeks to optimize workflow efficiency and minimize cognitive load"
❌ "Pain point: inadequate information architecture"
```

**Why it fails:** Loses the human. Team can't empathize with jargon.

**Fix:** Use the user's own words. Quotes from research. Plain language.

---

### Quick Self-Check

Before finalizing a persona, ask:

| Question | If No... |
|----------|----------|
| Is this based on real research? | Label as proto-persona |
| Does every detail inform design? | Cut the fluff |
| Would this survive if proven wrong? | You're too attached |
| Has the team contributed? | Get input before finalizing |
| Could I find this person in the real world? | Too abstract |
| When was this last validated? | Schedule review |
