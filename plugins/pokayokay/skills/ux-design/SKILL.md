---
name: ux-design
description: Structured UX decision-making for user flows and interaction patterns. Guides choosing the right UX patterns and applying user-centered thinking.
---

# UX Design

Make sound UX decisions through user-centered thinking. Guides interaction design, not visual styling.

**Use for:** User flows, UI patterns, interaction improvements
**Not for:** Visual styling, research, accessibility audits

---

## How to Use This Skill

### 1. Understand the User Need

Clarify: **Who** (user type), **What** (goal not task), **Where/When** (context), **Why** (motivation/pain)

**Example:** "Help power users customize notifications without overwhelming casual users"

### 2. Choose the Right Pattern

**Modal vs Page vs Drawer:**
```
Quick task (<2 min)?
├─ Yes: Needs background context?
│  ├─ No → Modal
│  └─ Yes → Drawer/Panel
└─ No → Full page
```

**Navigation:**
```
3-5 sections?
├─ Mobile → Bottom tabs
└─ Web → Top navbar/sidebar
6+ sections → Sidebar + search
```

See [references/patterns.md](references/patterns.md) for complete library.

### 3. Apply Core Principles

- **User control**: Back/cancel/undo always available
- **Feedback**: Acknowledge every action (loading/success/error)
- **Error prevention**: Disable invalid vs allow then reject
- **Consistency**: Same pattern = same action everywhere

**Example:** Disable "Submit" + show "Fill required fields" (not error after click)

### 4. Design Key States

Every element needs: **Default**, **Hover**, **Focus**, **Disabled** (+ why), **Loading**, **Error**, **Empty** (+ guidance)

### 5. Usability Check

- [ ] Complete without instructions? Primary action obvious?
- [ ] Errors helpful (what + fix)? Can undo/escape?
- [ ] Keyboard accessible? Touch targets ≥44px?

---

## Examples: Good vs Poor UX

**Form Validation**
- Poor: Placeholders only, validates while typing, "Invalid input", clears on error
- Good: Labels above fields, validates on blur, "Email must include @", preserves input

**Delete Confirmation**
- Poor: Click → Immediately deleted → Toast
- Good: Modal "Delete?" [Cancel] [Delete] OR "Deleted. [Undo]" (5 sec)

**Mobile Navigation**
- Poor: Hamburger menu (hides features)
- Good: Bottom tabs 3-5 items (visible, one-tap)

---

## Quick Decision Guide

**Forms:** Single column | Label above field | Validate on blur

**Messages:** Errors inline | Success toast | Warnings banner | Confirmations modal

**Mobile:** Bottom tabs (≤5) | Touch ≥44pt | Actions in thumb zone | No hover-only

**Loading:** Skeletons > spinners | Optimistic UI | Progress (>5s)

---

## References

[references/patterns.md](references/patterns.md) | [references/design-thinking-process.md](references/design-thinking-process.md) | [references/modern-patterns.md](references/modern-patterns.md) | [references/information-architecture.md](references/information-architecture.md) | [references/accessibility.md](references/accessibility.md)
