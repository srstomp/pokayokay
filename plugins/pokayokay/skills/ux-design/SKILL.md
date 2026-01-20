---
name: ux-design
description: Comprehensive UX design guidance covering research, information architecture, interaction patterns, and accessibility. Activates on ANY UI/UX work including user flows, navigation, forms, onboarding, error handling, and responsive design. Covers both process (Design Thinking, user research, personas) and implementation (patterns, accessibility, mobile UX). Use this skill for all user experience decisions on web and mobile platforms.
---

# UX Design

User experience is the foundation. Visual aesthetics built on poor UX will fail. This skill ensures structural soundness before surface polish.

**Related skills:**
- `aesthetic-ui-designer` — Visual execution after UX decisions are made
- `persona-creation` — Deep user research, personas, JTBD, journey mapping
- `accessibility-auditor` — Comprehensive WCAG 2.2 AA audits

## Design Thinking Framework

A pragmatic approach: Design Thinking structure with Lean UX speed.

```
Empathize → Define → Ideate → Prototype → Test → Iterate
    ↑                                              |
    └──────────────────────────────────────────────┘
```

### Quick Process Guide

| Phase | Goal | Output |
|-------|------|--------|
| **Empathize** | Understand users deeply | Research insights, empathy maps |
| **Define** | Frame the right problem | Problem statement, personas |
| **Ideate** | Explore solutions broadly | Sketches, concepts, user flows |
| **Prototype** | Make ideas tangible | Wireframes, clickable prototypes |
| **Test** | Validate with real users | Feedback, iteration priorities |

**For detailed process guidance:** See [references/design-thinking-process.md](references/design-thinking-process.md)

---

## Core UX Principles

### 1. User Control & Freedom
- Always provide escape routes (cancel, undo, back)
- Don't trap users in flows
- Confirm destructive actions, but don't over-confirm routine ones

### 2. Consistency & Standards
- Follow platform conventions (web vs iOS vs Android)
- Internal consistency: same action = same result everywhere
- Use familiar patterns before inventing new ones

### 3. Error Prevention > Error Messages
- Disable invalid actions rather than allowing then rejecting
- Use constraints (date pickers vs free text)
- Provide smart defaults

### 4. Recognition Over Recall
- Show options, don't require memorization
- Persistent navigation and context
- Recently used items, search history

### 5. Flexibility & Efficiency
- Shortcuts for experts, guidance for novices
- Customizable workflows
- Progressive disclosure: simple default, advanced available

### 6. Feedback & Visibility
- Every action needs acknowledgment
- System status always visible
- Loading states, progress indicators, success confirmations

### 7. Help Users Recover
- Clear error messages: what happened, why, how to fix
- Preserve user input on errors
- Offer alternatives when primary path fails

---

## Information Architecture

Structure content so users find what they need.

### Navigation Principles
- **7±2 rule**: Limit top-level items to 5-9
- **3-click guideline**: Major content within 3 clicks (flexible, not rigid)
- **Clear labeling**: User language, not internal jargon
- **Visible location**: Users should always know where they are

### Navigation Patterns

| Pattern | Use When | Platform |
|---------|----------|----------|
| Top navbar | Few primary sections | Web |
| Sidebar | Many sections, dashboard apps | Web |
| Bottom tabs | 3-5 primary destinations | Mobile |
| Hamburger menu | Secondary nav, space-constrained | Both |
| Tab bar | Content categories at same level | Both |
| Breadcrumbs | Deep hierarchies, need path visibility | Web |

**For detailed IA guidance:** See [references/information-architecture.md](references/information-architecture.md)

---

## Implementation Patterns

### Forms

**Structure:**
- One column layouts outperform multi-column
- Group related fields visually
- Logical order (don't ask shipping before cart)

**Inputs:**
- Label above field (not placeholder-only)
- Appropriate input types (email, tel, date)
- Inline validation after field blur, not while typing

**Actions:**
- Primary action visually dominant
- Destructive actions require confirmation
- Disabled submit until valid (with clear indication why)

### Feedback States

Every interactive element needs:
- **Default**: Resting state
- **Hover**: Mouse over (desktop)
- **Focus**: Keyboard navigation (accessibility critical)
- **Active**: Being pressed/clicked
- **Disabled**: Unavailable, with clear reason
- **Loading**: Processing, with indicator
- **Success/Error**: Outcome confirmation

### Loading & Empty States

**Loading:**
- Skeleton screens over spinners
- Progress indicators for long operations
- Optimistic UI where safe

**Empty states:**
- Explain why empty
- Guide toward first action
- Never just blank space

### Error Handling

```
[Clear icon] What went wrong
             Why it happened (briefly)
             [Primary action to fix] [Secondary: help/retry]
```

- Position near the source
- Don't blame the user
- Offer recovery path

### Onboarding

- Delay account creation until necessary
- Value first, signup second
- Progressive profiling over long forms
- Skippable for returning users

**For detailed patterns:** See [references/patterns.md](references/patterns.md)
**For modern patterns (AI, dark mode, animation):** See [references/modern-patterns.md](references/modern-patterns.md)

---

## Mobile-Specific UX

### Touch Targets
- Minimum 44×44pt (iOS) / 48×48dp (Android)
- Spacing between targets to prevent mis-taps
- Primary actions in thumb zone (bottom of screen)

### Gestures
- Swipe for delete/archive (with undo)
- Pull-to-refresh for lists
- Pinch-to-zoom for images/maps
- Avoid gesture-only actions; provide visible alternatives

### Mobile Navigation
- Bottom tab bar for primary nav (≤5 items)
- Stack navigation for hierarchical content
- Modal for focused tasks (with clear dismiss)
- Avoid hamburger menus as primary nav

### Performance UX
- Perceived performance matters more than actual
- Instant feedback, background processing
- Offline states and graceful degradation

---

## Accessibility Essentials

Accessibility improves UX for everyone. For comprehensive audits, use the `accessibility-auditor` skill.

### Quick Checklist

**Perceivable:**
- [ ] Text alternatives for images (`alt` text)
- [ ] Color contrast: 4.5:1 for text, 3:1 for large text
- [ ] Don't convey info by color alone

**Operable:**
- [ ] Full keyboard navigation
- [ ] Visible focus indicators
- [ ] Touch targets ≥44px
- [ ] No keyboard traps

**Understandable:**
- [ ] Clear error messages with recovery path
- [ ] Labels for all form inputs
- [ ] Consistent navigation

**Robust:**
- [ ] Semantic HTML (use right elements)
- [ ] ARIA only when HTML isn't sufficient

**For implementation details:** See [references/accessibility.md](references/accessibility.md)
**For full WCAG 2.2 AA audits:** Use the `accessibility-auditor` skill

---

## Responsive Design

### Breakpoint Strategy
- Design mobile-first, enhance upward
- Content determines breakpoints, not devices
- Common: 640px (sm), 768px (md), 1024px (lg), 1280px (xl)

### What Changes Per Breakpoint
- Navigation pattern (tabs → sidebar → topnav)
- Grid columns
- Touch vs hover interactions
- Content density

### What Stays Consistent
- Core functionality
- Information hierarchy
- Brand identity
- Accessibility

---

## UX Anti-Patterns

### Navigation Anti-Patterns

| Anti-Pattern | Why It's Bad | Instead |
|--------------|--------------|---------|
| **Hamburger as primary nav** | Hides key options, reduces discovery | Bottom tabs (mobile), visible nav (web) |
| **Mystery meat navigation** | Icons without labels confuse users | Label icons, or use text links |
| **Deep nesting (5+ levels)** | Users get lost, high abandonment | Flatten hierarchy, use search |
| **Inconsistent back behavior** | Breaks mental model | Predictable back = previous screen |
| **Pagination in infinite content** | Jarring interruption | Infinite scroll with "load more" option |

### Form Anti-Patterns

| Anti-Pattern | Why It's Bad | Instead |
|--------------|--------------|---------|
| **Placeholder as label** | Disappears, accessibility issues | Label above field |
| **Validating while typing** | Premature errors frustrate users | Validate on blur |
| **Clearing form on error** | Punishes users for mistakes | Preserve input, highlight error |
| **Generic error messages** | "Invalid" doesn't help | Specific: "Use 8+ characters" |
| **Required \* everywhere** | Noise if most are required | Mark optional fields instead |
| **Multi-column forms** | Increases completion time | Single column (exceptions: city/state/zip) |

### Feedback Anti-Patterns

| Anti-Pattern | Why It's Bad | Instead |
|--------------|--------------|---------|
| **Silent failures** | User doesn't know what happened | Always confirm or explain failure |
| **Modal for everything** | Interrupts flow, modal fatigue | Toast for success, inline for errors |
| **Auto-dismissing errors** | User can't read/act in time | Persist until dismissed or fixed |
| **Spinners for content** | No layout stability | Skeleton screens |
| **Blocking loaders** | UI feels frozen | Non-blocking indicators |

### Onboarding Anti-Patterns

| Anti-Pattern | Why It's Bad | Instead |
|--------------|--------------|---------|
| **Feature tours upfront** | Users forget, want to explore | Contextual hints when relevant |
| **Mandatory lengthy signup** | High drop-off | Delay signup, progressive profiling |
| **Tooltips everywhere** | Overwhelming | Max 1-3 per session |
| **Can't skip** | Frustrates returning users | Always allow skip |
| **Empty state with no guidance** | Users don't know what to do | Explain + clear first action |

### Mobile Anti-Patterns

| Anti-Pattern | Why It's Bad | Instead |
|--------------|--------------|---------|
| **Tiny touch targets** | Mis-taps, frustration | ≥44pt/48dp |
| **Hover-dependent features** | No hover on touch | Tap/press alternatives |
| **Desktop modals on mobile** | Hard to dismiss, blocks screen | Bottom sheets |
| **Fixed position nav + keyboard** | Covers input fields | Hide nav during input |
| **Gesture-only actions** | Discoverable, accessibility | Visible buttons + gesture shortcut |

### General Anti-Patterns

| Anti-Pattern | Why It's Bad | Instead |
|--------------|--------------|---------|
| **Confirmation for routine actions** | Slows users down | Only confirm destructive/irreversible |
| **Jargon in UI** | Users don't understand | Plain language |
| **Disabled without explanation** | User doesn't know why | Explain what's needed |
| **Infinite scroll for all lists** | Can't bookmark, no sense of progress | Paginate long lists with stable URLs |
| **Auto-playing video/audio** | Startling, consumes data | User-initiated playback |

---

## UX Decision Trees

### Modal vs Page vs Drawer

```
Is the task focused and short?
├── Yes: Does user need to reference background content?
│   ├── Yes → Drawer/Panel (side sheet)
│   └── No → Modal
└── No: Is the task a full workflow?
    ├── Yes → Full page
    └── No: Is it contextual actions?
        ├── Yes → Bottom sheet (mobile) / Dropdown (web)
        └── No → Consider page or panel
```

### Tabs vs Accordion vs Sections

```
Is content mutually exclusive (only one visible at a time)?
├── Yes: Are items few (≤5) and parallel?
│   ├── Yes → Tabs
│   └── No → Accordion
└── No: Should all content be scannable?
    ├── Yes → Stacked sections (all visible)
    └── No → Progressive disclosure (expand on demand)
```

### Pagination vs Infinite Scroll

```
Does user need to find specific item or reach specific point?
├── Yes → Pagination (URL stability, can bookmark)
└── No: Is content time-based / feed-like?
    ├── Yes: Is list long and exploratory?
    │   ├── Yes → Infinite scroll + "back to top"
    │   └── No → Load more button
    └── No → Pagination with visible page count
```

### Toast vs Inline vs Modal (for messages)

```
Is immediate action required?
├── Yes → Modal with action buttons
└── No: Is it an error related to specific field?
    ├── Yes → Inline (near field)
    └── No: Is it a success/info message?
        ├── Yes → Toast (auto-dismiss ok)
        └── No: Is it a system-level warning?
            ├── Yes → Banner (top of page)
            └── No → Toast or inline
```

---

## UX Checklist

Before finalizing any interface:

### Structure
- [ ] Clear information hierarchy
- [ ] Intuitive navigation
- [ ] User always knows their location
- [ ] Important actions are prominent

### Interaction
- [ ] Every action has feedback
- [ ] Error states are helpful
- [ ] Loading states are present
- [ ] Empty states guide users

### Accessibility
- [ ] Keyboard navigable
- [ ] Screen reader compatible
- [ ] Sufficient color contrast
- [ ] Touch targets adequate

### Mobile
- [ ] Thumb-zone friendly
- [ ] Touch targets ≥44pt
- [ ] Works offline or degrades gracefully
- [ ] No hover-dependent functionality

---

**References:**
- [references/design-thinking-process.md](references/design-thinking-process.md) — Full process, research methods, ideation, testing
- [references/information-architecture.md](references/information-architecture.md) — Site structure, navigation, content organization
- [references/patterns.md](references/patterns.md) — Detailed implementation patterns with decision guidance
- [references/modern-patterns.md](references/modern-patterns.md) — AI UX, dark mode, animation, i18n, data visualization
- [references/accessibility.md](references/accessibility.md) — Accessibility implementation essentials
