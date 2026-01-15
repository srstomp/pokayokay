# Jobs-to-be-Done Framework

Deep dive into JTBD methodology for understanding user motivation.

## Core Philosophy

**People don't buy products. They hire them to do a job.**

- A "job" is the progress someone wants to make in a particular circumstance
- Jobs are stable over time (even as products change)
- Understanding jobs reveals true competitive landscape

### Classic Example: Milkshake

McDonald's wanted to sell more milkshakes. Traditional approach: make them tastier, cheaper, more variety.

JTBD approach: Why do people "hire" a milkshake?

**Morning commuters**: Hired to make a boring drive interesting and keep them full until lunch. Competitors: bagels, bananas, coffee, boredom.

**Afternoon parents**: Hired to be a treat for kids after school. Competitors: toys, other treats, quality time.

Same product, different jobs = different design implications.

---

## Job Statement Syntax

### Basic Format
```
When [situation], I want to [motivation], so I can [outcome].
```

### Components

**Situation (When):**
- The trigger or context
- Specific circumstance
- What prompts the need

**Motivation (Want to):**
- The action or capability needed
- What they're trying to do
- Verb-focused

**Outcome (So I can):**
- The benefit or result
- Why it matters
- The "why behind the why"

### Examples

```
When I'm preparing for a meeting with stakeholders,
I want to quickly see project health,
so I can give confident updates without looking unprepared.

When a new team member joins,
I want to get them productive quickly,
so I can minimize the burden on existing team members.

When I notice a recurring bug pattern,
I want to understand the root cause,
so I can fix it once instead of repeatedly.
```

### Writing Good Job Statements

**Be specific:**
- ❌ "When I'm at work, I want to be productive"
- ✅ "When I'm deep in code, I want to avoid interruptions, so I can maintain flow state"

**Focus on progress, not product:**
- ❌ "When I open the app, I want to see the dashboard"
- ✅ "When I start my day, I want to know what needs my attention, so I can prioritize effectively"

**Include emotional jobs:**
- Functional: "...so I can complete the task"
- Emotional: "...so I can feel confident"
- Social: "...so I can look competent to others"

---

## The Four Forces

What drives adoption and switching decisions.

```
                     CHANGE
                        ↑
    ┌───────────────────┼───────────────────┐
    │                   │                   │
    │      PUSH         │        PULL       │
    │  (current pain)   │   (new solution)  │
    │                   │                   │
    │         ↘         │         ↙         │
    │           ↘       │       ↙           │
    │             ↘     │     ↙             │
────┤               ↘   │   ↙               ├────
    │               ↗   │   ↖               │
    │             ↗     │     ↖             │
    │           ↗       │       ↖           │
    │         ↗         │         ↖         │
    │                   │                   │
    │     HABIT         │      ANXIETY      │
    │  (inertia)        │   (fear of new)   │
    │                   │                   │
    └───────────────────┼───────────────────┘
                        ↓
                   NO CHANGE
```

### Force 1: Push (Current Solution Problems)

What's driving them away from current state?

**Discovery questions:**
- What's frustrating about your current approach?
- When does your current solution fail you?
- What workarounds have you created?

**Examples:**
- "I spend 30 minutes a day just finding information"
- "The old tool crashes when we hit 1000 users"
- "My team hates using it, so data is always stale"

### Force 2: Pull (New Solution Attraction)

What's attracting them to a new solution?

**Discovery questions:**
- What would make your life easier?
- What have you seen others do that you want?
- What would a perfect solution look like?

**Examples:**
- "I want a single place for everything"
- "I saw our competitor ship twice as fast"
- "The demo made it look so simple"

### Force 3: Anxiety (Fear of Change)

What fears prevent them from switching?

**Discovery questions:**
- What concerns do you have about switching?
- What could go wrong?
- What would you need to feel confident?

**Examples:**
- "What if my team won't adopt it?"
- "What if we lose our historical data?"
- "What if it's harder than what we have?"

### Force 4: Habit (Inertia)

What keeps them comfortable with status quo?

**Discovery questions:**
- What would you miss about your current solution?
- What parts of your workflow work well today?
- What would you have to relearn?

**Examples:**
- "Everyone already knows how to use Excel"
- "We've invested years building our current setup"
- "At least I know where everything is"

### Using the Forces

**For adoption to happen:**
Push + Pull > Anxiety + Habit

**Design implications:**

| Force | Strategy |
|-------|----------|
| Increase Push | Remind them of current pain |
| Increase Pull | Demo the vision, show results |
| Decrease Anxiety | Free trials, guarantees, migration support |
| Decrease Habit | Import existing data, familiar patterns |

---

## Competitive Landscape Through JTBD

Traditional competition: Similar products in same category.

JTBD competition: Anything hired for the same job.

### Example: Morning Coffee

**Traditional competitors:**
- Other coffee shops
- Home coffee makers

**JTBD competitors (for "wake up and feel alert"):**
- Tea
- Energy drinks
- Exercise
- Cold shower
- Extra sleep

**JTBD competitors (for "enjoyable morning routine"):**
- Breakfast ritual
- Meditation
- Morning news
- Social media scroll

### Mapping JTBD Competition

```markdown
## Job: [Job Statement]

### Direct Competitors
Products explicitly designed for this job:
- [Competitor 1]
- [Competitor 2]

### Indirect Competitors
Other products hired for this job:
- [Alternative 1]
- [Alternative 2]

### Non-Consumption
What do people do when they don't hire anything?
- [Status quo]
- [Manual workaround]

### Over-Served Alternatives
Solutions that are overkill for this job:
- [Enterprise solution used by individuals]
- [Complex tool when simple needed]
```

---

## Job Hierarchy

Jobs exist at different levels of abstraction.

```
                    Aspirational Job
                   /                \
          Core Functional         Emotional/Social
          Job                     Job
         /    \                   /    \
    Related   Related        Related   Related
    Job       Job            Job       Job
```

### Levels

**Aspirational Job**: Big life goal
- "Be a successful entrepreneur"
- "Raise healthy, happy children"

**Core Functional Job**: Main task
- "Manage my team's projects"
- "Prepare healthy meals"

**Related Jobs**: Supporting tasks
- "Track project progress"
- "Share status with stakeholders"

**Emotional Jobs**: How they want to feel
- "Feel in control"
- "Feel confident in front of stakeholders"

**Social Jobs**: How they want to be perceived
- "Look competent to leadership"
- "Be seen as a good parent"

### Job Map Template

```markdown
## Job Map: [User/Segment]

### Aspirational Job
[Big picture goal they're working toward]

### Core Functional Job
[Primary task they're trying to accomplish]

### Related Jobs
- [Supporting task 1]
- [Supporting task 2]
- [Supporting task 3]

### Emotional Jobs
- [How they want to feel]
- [What they want to avoid feeling]

### Social Jobs
- [How they want to be perceived]
- [What perception they want to avoid]
```

---

## Job Discovery Interview

### Interview Structure

**1. Find a switching story (10 min)**
- "Tell me about the last time you started using a new [product category]"
- "What were you using before?"
- "When did you first think about switching?"

**2. Explore the timeline (20 min)**
- "Walk me through how you went from first thought to actually using it"
- "What was the moment you knew you needed something different?"
- "What alternatives did you consider?"

**3. Dig into forces (15 min)**
- **Push**: "What was frustrating about the old way?"
- **Pull**: "What attracted you to the new solution?"
- **Anxiety**: "What concerns did you have?"
- **Habit**: "What did you have to give up?"

**4. Understand the job (10 min)**
- "What were you ultimately trying to accomplish?"
- "How do you know if that's going well?"
- "What would a perfect solution do for you?"

### Interview Questions by Force

**Push questions:**
- What was the moment you realized you needed something different?
- What was the last straw?
- What workarounds did you have to create?
- What was the cost of the old way (time, money, frustration)?

**Pull questions:**
- What first attracted you to the new solution?
- What did you imagine it would be like to use?
- What results did you hope to see?
- What did you see others achieving?

**Anxiety questions:**
- What almost stopped you from switching?
- What concerns did you have?
- What convinced you it would work out?
- What would have made you feel more confident?

**Habit questions:**
- What did you have to give up?
- What felt comfortable about the old way?
- What did you have to relearn?
- What would have made switching easier?

---

## JTBD for Feature Prioritization

### Job-Feature Matrix

```markdown
| Feature | Job 1 | Job 2 | Job 3 | Total Impact |
|---------|-------|-------|-------|--------------|
| Feature A | ++ | + | - | 2 |
| Feature B | + | ++ | ++ | 5 |
| Feature C | - | + | ++ | 2 |
```

**Rating:**
- ++: Directly enables the job
- +: Helps with the job
- -: Neutral
- --: Gets in the way

### Outcome-Driven Innovation

**1. List desired outcomes:**
What metrics does success look like for each job?

**2. Rate importance and satisfaction:**
For each outcome, rate:
- Importance (1-5)
- Current satisfaction (1-5)

**3. Calculate opportunity:**
Opportunity = Importance + (Importance - Satisfaction)

High opportunity = High importance, low satisfaction = Build here.

```markdown
| Outcome | Importance | Satisfaction | Opportunity |
|---------|------------|--------------|-------------|
| Minimize time to get status | 5 | 2 | 8 |
| Reduce surprise blockers | 5 | 3 | 7 |
| Fewer status meetings | 4 | 2 | 6 |
| Easy to share with stakeholders | 3 | 3 | 3 |
```

---

## Job Stories vs User Stories

### User Story
```
As a [user type],
I want to [action],
so that [benefit].
```

**Focus**: Who the user is, what they want to do.

### Job Story
```
When [situation],
I want to [motivation],
so I can [outcome].
```

**Focus**: The context and motivation, not the user's identity.

### When to Use Each

| Use User Stories When | Use Job Stories When |
|-----------------------|----------------------|
| Role matters for permissions | Context matters more than role |
| Building role-specific features | Same feature serves different users |
| Team thinks in user segments | Team thinks in use cases |
| Simpler product, clear users | Complex product, varied contexts |

### Converting Between Formats

**User Story:**
"As a project manager, I want to see a dashboard, so that I can track progress."

**Job Story:**
"When I'm about to join a stakeholder meeting, I want to quickly see project health, so I can give confident updates."

The job story reveals the actual context and stakes, leading to better design.
