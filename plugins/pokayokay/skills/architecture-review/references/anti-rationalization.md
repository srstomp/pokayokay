# Anti-Rationalization: Architecture Discipline

## Iron Law

**NO ARCHITECTURAL CHANGE WITHOUT DOCUMENTING THE TRADE-OFF.**

Every structural decision has costs. Name them. If you can't name the trade-off, you don't understand the change.

---

## Why This Works

Authority + commitment language doubles LLM compliance on discipline tasks (33% to 72%). Pre-rebutting common excuses prevents rationalization before it starts.

---

## Common Rationalizations

| Rationalization | Reality |
|----------------|---------|
| "It's just a small refactor" | Small refactors compound. Three small refactors become a large undocumented architectural shift. Document why. |
| "We can fix it later" | Later never comes. Fix it now or accept the trade-off explicitly with a documented decision. |
| "Everyone does it this way" | Convention is not architecture. Justify from YOUR project's constraints and principles, not industry trends. |
| "This pattern is cleaner" | "Clean" is subjective. State the measurable benefit: fewer dependencies, simpler testing, clearer boundaries. |
| "Let me just restructure this quickly" | Restructuring is never quick. Map dependencies first. Identify what breaks. Plan the migration. |
| "The current architecture doesn't support this" | Verify. Read the code. Most "architecture won't support it" claims come from not understanding the existing design. |
| "We need a new abstraction here" | Do you? Three similar code blocks is better than a premature abstraction. Wait for the third use case. |
| "This is just technical debt cleanup" | Technical debt has interest rates. Quantify the cost of keeping it vs. the cost of changing it. Then decide. |
| "The dependency is fine, it's well-maintained" | Every dependency is a coupling point. Evaluate: API surface used, upgrade burden, fallback plan if abandoned. |
| "This won't affect other modules" | Prove it. Check imports, shared types, common utilities. Architectural changes propagate further than you think. |
| "We need to future-proof this" | You don't know the future. Design for today's requirements with clean interfaces. Extensibility is not speculation. |
| "Let me introduce a new pattern" | One pattern per problem. Adding a new pattern without retiring the old one creates two ways to do things. |

---

## Red Flags — STOP

When you detect ANY of these in your reasoning, STOP IMMEDIATELY.

### Reasoning Phrases That Must Halt

1. **"Quick hack"** — STOP. Hacks without follow-up tasks become permanent. Create the follow-up task or do it right.
2. **"Temporary workaround"** — STOP. Is there a task to remove it? No? Then it's permanent. Treat it as such.
3. **"We'll migrate later"** — STOP. Write the migration plan NOW or accept the current design.
4. **"This new pattern is better"** — STOP. Better how? For whom? Document the trade-off or keep the existing pattern.
5. **"It's too coupled, let me decouple it"** — STOP. Coupling is not inherently bad. Is this coupling causing actual problems? Name them.
6. **"Let me add a layer of indirection"** — STOP. Every layer adds complexity. What specific problem does this layer solve?
7. **"The architecture is wrong"** — STOP. Architecture is not right or wrong. It serves requirements. Have the requirements changed?
8. **"This needs a rewrite"** — STOP. Rewrites are almost never justified. Identify the specific pain points and address them incrementally.

### Structural Red Flags in Code

1. **New directory created without documenting its purpose** — STOP. Every directory is a boundary decision.
2. **Circular dependency introduced** — STOP. Extract the shared concern or restructure.
3. **God module growing (>500 lines)** — STOP. Split by responsibility before adding more.
4. **New abstraction with only one implementation** — STOP. Wait for the second use case.
5. **Import from a deeper layer** — STOP. Dependencies flow downward. Inversion = architecture violation.

### What To Do When You STOP

1. State the architectural change you're about to make
2. Document the trade-off: what you gain, what you lose
3. Verify the change doesn't introduce circular dependencies
4. Check if existing patterns already solve the problem
5. If it's genuinely needed, add it to the task description as a deliberate decision

---

## Verification Checklist

Before reporting an architecture-related task as complete, verify ALL of these:

- [ ] Every new directory/module has a documented purpose
- [ ] No circular dependencies introduced (check imports)
- [ ] No new abstractions with only one implementation
- [ ] Dependency direction is consistent (higher layers depend on lower, never reverse)
- [ ] No "temporary" code without a follow-up task to remove it
- [ ] Trade-offs documented for any structural decision
- [ ] File sizes remain under 500 lines
- [ ] Existing patterns reused where applicable (no parallel patterns for same problem)
