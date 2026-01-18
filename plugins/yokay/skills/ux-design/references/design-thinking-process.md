# Design Thinking Process

A pragmatic approach to user-centered design. Design Thinking backbone with Lean UX speed.

## Phase 1: Empathize

**Goal:** Understand users deeply before solving anything.

### Research Methods

| Method | Best For | Time Investment |
|--------|----------|-----------------|
| User interviews | Deep qualitative insights | Medium |
| Surveys | Quantitative data, broad reach | Low |
| Contextual inquiry | Observing real behavior | High |
| Analytics review | Existing behavior patterns | Low |
| Support ticket analysis | Pain points, common issues | Low |
| Competitor analysis | Market expectations | Medium |

### User Interview Guide

**Structure:**
1. Warm-up (2 min) — Build rapport
2. Context (5 min) — Current situation, background
3. Core exploration (15-20 min) — Behaviors, needs, frustrations
4. Wrap-up (3 min) — Anything else, thank you

**Question Types:**
- Open-ended: "Tell me about the last time you..."
- Follow-up: "Why was that important?" "How did that make you feel?"
- Specific: "Walk me through exactly what you did"

**Avoid:**
- Leading questions: "Don't you think...?"
- Hypotheticals: "Would you use...?"
- Multiple questions at once

**Sample Questions:**
- "Describe your typical day when dealing with [problem area]"
- "What's the most frustrating part of [current process]?"
- "What have you tried before? What worked/didn't?"
- "If you could wave a magic wand, what would change?"

### Empathy Mapping

```
        What they THINK & FEEL?
        (fears, frustrations, aspirations)
                    |
What they HEAR? ----+---- What they SEE?
(influences,        |     (environment,
friends, media)     |     competitors)
                    |
        What they SAY & DO?
        (public behavior, appearance)
                    |
        +-----------+-----------+
        |                       |
     PAINS                   GAINS
  (frustrations,          (wants, needs,
   obstacles)              measures of success)
```

### Research Synthesis

After gathering data:
1. **Affinity mapping**: Group observations by theme
2. **Pattern identification**: What repeats across users?
3. **Insight generation**: "We observed [behavior], which suggests [insight]"

---

## Phase 2: Define

**Goal:** Frame the right problem to solve.

### Problem Statement Formats

**How Might We (HMW):**
```
How might we [action] for [user] so that [outcome]?
```
Example: "How might we simplify expense reporting for field sales reps so they can submit expenses in under 2 minutes?"

**Point of View (POV):**
```
[User] needs [need] because [insight].
```
Example: "Busy field sales reps need a frictionless expense submission process because they lose receipts when they can't submit immediately."

### User Personas (Quick Version)

**Template:**
```
[Name] - [Role/Archetype]

Goals:
- Primary goal
- Secondary goal

Frustrations:
- Pain point 1
- Pain point 2

Key Behavior: [Relevant habit or pattern]

Quote: "[Something they might actually say]"
```

**Guidelines:**
- Based on research, not assumptions
- 3-5 personas max
- Update as you learn more

**For comprehensive persona methodology** — including Jobs-to-be-Done profiles, validation techniques, journey mapping, and anti-patterns — use the `persona-creation` skill.

### Jobs-to-be-Done (JTBD)

Complement personas with job stories:

```
When [situation],
I want to [motivation],
so I can [outcome].
```

Example: "When I'm at a client dinner, I want to capture receipt details instantly, so I can expense it before I forget."

---

## Phase 3: Ideate

**Goal:** Explore solutions broadly before narrowing.

### Ideation Rules
- Quantity over quality initially
- No criticism during generation
- Build on others' ideas
- Wild ideas welcome

### Ideation Methods

**Brainstorming:**
- Set time limit (10-15 min)
- One idea per sticky note
- Aim for 50+ ideas

**Crazy Eights:**
1. Fold paper into 8 sections
2. 8 ideas in 8 minutes (1 min each)
3. Sketch, don't write paragraphs

**SCAMPER:**
- **S**ubstitute: What can be replaced?
- **C**ombine: What can merge?
- **A**dapt: What can be adjusted?
- **M**odify: What can change form?
- **P**ut to other use: Other applications?
- **E**liminate: What can be removed?
- **R**earrange: Different order/layout?

### Prioritization

**Impact/Effort Matrix:**
```
High Impact │ MAYBE        │ DO FIRST
            │ (high effort)│ (low effort)
────────────┼──────────────┼──────────────
Low Impact  │ DON'T DO     │ DO LATER
            │ (high effort)│ (low effort)
            └──────────────┴──────────────
              High Effort    Low Effort
```

**MoSCoW Prioritization:**
- **Must have**: Critical for launch
- **Should have**: Important but not critical
- **Could have**: Nice to have
- **Won't have**: Out of scope (for now)

---

## Phase 4: Prototype

**Goal:** Make ideas tangible enough to test.

### Fidelity Levels

| Level | Tools | Best For |
|-------|-------|----------|
| Low (sketches) | Paper, whiteboard | Early exploration, flow validation |
| Medium (wireframes) | Figma, Balsamiq | Structure, layout, content hierarchy |
| High (mockups) | Figma, code | Visual validation, developer handoff |
| Interactive | Figma prototype, code | Usability testing, interaction patterns |

### Prototyping Principles
- Prototype to answer specific questions
- Minimum fidelity needed to learn
- Fake it where possible (Wizard of Oz)
- Expect to throw it away

### User Flow Diagrams

**Notation:**
```
[Rectangle]     = Screen/Page
<Diamond>       = Decision point
(Rounded rect)  = Action
→               = Flow direction
```

**Example:**
```
[Landing Page] → (Click CTA) → [Sign Up Form] → <Valid?> 
                                                  ├─ Yes → [Dashboard]
                                                  └─ No → [Error State] → [Sign Up Form]
```

---

## Phase 5: Test

**Goal:** Validate with real users, identify improvements.

### Usability Testing

**Session Structure:**
1. **Introduction (2 min)**: Explain process, no wrong answers
2. **Background (3 min)**: Relevant context questions
3. **Tasks (15-20 min)**: Observe attempting core tasks
4. **Debrief (5 min)**: Overall impressions, questions

**Task Design:**
- Realistic scenarios, not instructions
- ❌ "Click the submit button"
- ✅ "You want to submit an expense for the dinner last night"

**Observation Tips:**
- Note where they pause, backtrack, or express confusion
- Ask "What are you thinking?" during pauses
- Don't help unless completely stuck
- Record sessions (with consent)

### Testing Metrics

**Quantitative:**
- Task completion rate
- Time on task
- Error rate
- Number of clicks/steps

**Qualitative:**
- Confidence level
- Satisfaction rating
- Verbal feedback
- Observed frustrations

### Five-User Rule

5 users typically uncover ~85% of usability issues. Test with 5, fix issues, test again with 5 more.

### Feedback Synthesis

After testing:
1. List all observations
2. Group by theme/area
3. Prioritize by severity × frequency
4. Create action items

**Severity Scale:**
1. **Critical**: Prevents task completion
2. **Major**: Significant difficulty, workarounds needed
3. **Minor**: Noticeable but doesn't block
4. **Cosmetic**: Polish issues

---

## Iteration

Design Thinking is cyclical. After testing:
- Return to earlier phases as needed
- Small iterations: Prototype → Test → Prototype
- Large pivots: Back to Empathize/Define

### Lean UX Integration

For faster cycles:
- **Hypothesis-driven**: "We believe [change] will [outcome] for [users]"
- **MVP mindset**: Minimum to learn, not minimum to ship
- **Build-Measure-Learn**: Ship small, gather data, iterate

### When to Move Forward

Move from phase to phase when:
- **Empathize → Define**: Clear patterns emerge from research
- **Define → Ideate**: Problem statement is specific and validated
- **Ideate → Prototype**: Promising solutions identified
- **Prototype → Test**: Prototype answers specific questions
- **Test → Ship/Iterate**: Major issues resolved, minor can iterate post-launch

---

## Templates Quick Reference

### Research Planning
```
Research Goal: [What we want to learn]
Method: [Interview/Survey/etc.]
Participants: [Who, how many]
Timeline: [When]
Key Questions: [Top 3-5]
Success Criteria: [How we know we have enough]
```

### User Story Template
```
As a [user type],
I want to [action],
so that [benefit].

Acceptance Criteria:
- [ ] Criterion 1
- [ ] Criterion 2
```

### Hypothesis Template
```
We believe that [change/feature]
for [user segment]
will result in [outcome].

We'll know we're right when [measurable signal].
```
