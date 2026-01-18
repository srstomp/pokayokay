# Implementation Patterns

Detailed UX patterns for common interface elements with decision guidance and anti-patterns.

## Forms

### Form Structure

**Single Column:**
Always prefer single column. Multi-column increases completion time and errors.

```
┌─────────────────────────────────┐
│ Label                           │
│ ┌─────────────────────────────┐ │
│ │ Input                       │ │
│ └─────────────────────────────┘ │
│ Helper text                     │
│                                 │
│ Label                           │
│ ┌─────────────────────────────┐ │
│ │ Input                       │ │
│ └─────────────────────────────┘ │
│                                 │
│ [Secondary]        [Primary →]  │
└─────────────────────────────────┘
```

**Exceptions for multi-column:**
- Closely related short fields: City, State, Zip
- Name: First, Last (debatable — single field often better)

### Labels

**Position:**
- **Top-aligned**: Best for most cases, allows variable label length
- **Left-aligned**: Use for data-dense forms, requires consistent label width
- **Placeholder-only**: ❌ Never — disappears, accessibility issues

**Writing:**
- Sentence case: "Email address" not "EMAIL ADDRESS"
- No colons needed
- Be specific: "Work email" not just "Email" if it matters

### Input Types

Use the right input type:

| Data | Input Type | Why |
|------|------------|-----|
| Email | `type="email"` | Mobile keyboard, validation |
| Phone | `type="tel"` | Numeric keyboard |
| Password | `type="password"` | Masked, with show/hide toggle |
| Number | `type="number"` | Numeric keyboard, spinners |
| Date | `type="date"` or date picker | Consistent format, calendar UI |
| URL | `type="url"` | Validation, keyboard |

### Validation

**Timing:**
- Validate on blur (leaving field), not while typing
- Exception: Real-time feedback for passwords (strength meter)
- Don't clear fields on error

**Error Display:**
```
┌─────────────────────────────┐
│ Email address               │
│ ┌─────────────────────────┐ │
│ │ invalid-email           │ │ ← Red border
│ └─────────────────────────┘ │
│ ⚠ Enter a valid email       │ ← Error message below
└─────────────────────────────┘
```

**Error Message Content:**
- ❌ "Invalid input"
- ✅ "Enter an email address like name@example.com"

### Required vs Optional

```
Most fields required? → Mark optional fields "(optional)"
Most fields optional? → Mark required fields "*" with legend
Don't use both asterisks AND "(optional)"
```

### Form Actions

**Button Placement:**
- Primary action on right (Western reading pattern)
- Secondary actions (cancel, back) on left
- Destructive actions need confirmation

**Button States:**
- Default: Normal
- Hover: Visual feedback
- Loading: Spinner + disabled + "Saving..."
- Disabled: Only when form invalid, with clear indication why
- Success: Brief confirmation before transition

### Long Forms

**Decision: Which Strategy?**
```
How long is the form?
├── Short (5-7 fields) → Single page
├── Medium (8-15 fields) → Chunking with headers
└── Long (15+ fields)
    └── Are sections independent?
        ├── Yes → Multi-step wizard
        └── No → Accordion or progressive disclosure
```

**Progress Indicator:**
```
Step 1        Step 2        Step 3        Step 4
  ●─────────────●─────────────○─────────────○
Account      Profile     Preferences    Review
```

### Form Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Placeholder as label | Disappears, accessibility | Label above field |
| Validating while typing | Premature errors | Validate on blur |
| Clearing form on error | Punishes users | Preserve input |
| Generic "Invalid" messages | Not actionable | Specific guidance |
| All fields marked required | Visual noise | Mark optional instead |
| Reset button | Accidental data loss | Remove or hide |
| Auto-advancing on input | Disorienting | Let user control |

---

## Buttons

### Button Hierarchy

```
Primary     Secondary     Tertiary      Destructive
┌────────┐  ┌────────┐   ┌────────┐    ┌────────┐
│ Action │  │ Action │   │ Action │    │ Delete │
└────────┘  └────────┘   └────────┘    └────────┘
Filled      Outlined      Text only     Red/Warning
```

- **One primary per view**: Don't dilute focus
- **Secondary**: Important but not primary
- **Tertiary**: Low-priority actions
- **Destructive**: Requires extra attention

### Button Labels

- Start with verb: "Save changes" not "Changes"
- Be specific: "Create account" not "Submit"
- Avoid generic: "OK", "Click here", "Submit"

### Button States

| State | Visual | Interaction |
|-------|--------|-------------|
| Default | Normal styling | Clickable |
| Hover | Subtle change (color shift, shadow) | Indicates interactive |
| Focus | Visible outline | Keyboard navigation |
| Active | Pressed appearance | Feedback during click |
| Loading | Spinner, disabled | Processing |
| Disabled | Muted, no pointer | Unavailable + reason |

### Icon Buttons

```
When to use what?
├── Icon + Label → Most accessible, always preferred
├── Icon only → Only universal icons (×, +, ≡, ▶, ⏸)
│               Always add aria-label
└── Label only → For text-heavy interfaces
```

### Button Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Multiple primary buttons | Unclear main action | One primary per view |
| "Click here" labels | Not accessible, not descriptive | Action-specific labels |
| Disabled without explanation | User doesn't know why | Tooltip or text explanation |
| Icon-only for unclear icons | Confusing | Add label or tooltip |
| Too many buttons | Decision paralysis | Progressive disclosure |

---

## Modals & Dialogs

### Decision: Modal vs Drawer vs Page

```
Is the task focused and completable in <30 seconds?
├── Yes: Does user need to reference background?
│   ├── Yes → Drawer/Panel (side sheet)
│   └── No → Modal
└── No: Is it a full workflow?
    ├── Yes → Full page
    └── No → Drawer with expanded state
```

### When to Use Modals

✅ Use for:
- Confirmation of destructive actions
- Focused tasks requiring completion
- Critical information requiring acknowledgment

❌ Avoid for:
- Primary content (should be a page)
- Simple messages (use toast/notification)
- Forms that might need reference to background

### Modal Structure

```
┌─────────────────────────────────────┐
│ Title                            ✕ │
├─────────────────────────────────────┤
│                                     │
│  Content                            │
│                                     │
├─────────────────────────────────────┤
│              [Cancel]   [Confirm]   │
└─────────────────────────────────────┘
```

**Required Behavior:**
- Close button (✕) always present
- Clicking backdrop closes (for non-critical)
- Escape key closes
- Focus trapped inside modal
- Return focus to trigger on close

### Confirmation Dialogs

For destructive actions:
```
┌────────────────────────────────────┐
│ Delete project?                    │
├────────────────────────────────────┤
│ "Project Name" will be permanently │
│ deleted. This cannot be undone.    │
├────────────────────────────────────┤
│           [Cancel]   [Delete]      │
└────────────────────────────────────┘
```

- Confirm button matches action: "Delete" not "OK"
- Destructive button visually distinct (red)
- State what will happen and consequences

### Modal Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Modal on page load | Intrusive, blocks content | Delay or use banner |
| Nested modals | Confusing, awkward | Single modal or page flow |
| "OK" / "Cancel" labels | Vague, error-prone | Action-specific: "Delete" / "Keep" |
| No keyboard dismiss | Accessibility failure | Escape key closes |
| Content requiring scroll | Too much for modal | Use page or drawer |

---

## Notifications & Feedback

### Decision: Which Feedback Type?

```
Does user need to take action?
├── Yes: Is it urgent/blocking?
│   ├── Yes → Modal with actions
│   └── No → Banner with action button
└── No: Is it related to a specific field?
    ├── Yes → Inline (near source)
    └── No: Is it transient information?
        ├── Yes → Toast (auto-dismiss)
        └── No → Banner (persists)
```

### Feedback Types

| Type | Use For | Persistence | Position |
|------|---------|-------------|----------|
| Toast | Success, non-critical info | Auto-dismiss (3-5s) | Top or bottom |
| Banner | System-wide messages | Until dismissed | Top of page |
| Inline | Form validation, field errors | Until resolved | Near source |
| Modal | Critical, requires action | Until user acts | Center |

### Toast/Snackbar

```
┌──────────────────────────────────┐
│ ✓ Changes saved              [×] │
└──────────────────────────────────┘
```

- Brief message
- Auto-dismiss (3-5 seconds)
- Optional dismiss button
- Optional action ("Undo")
- Don't stack more than 3

### Error Messages

**Structure:**
1. What happened (clear, not technical)
2. Why (briefly)
3. How to fix (actionable)

**Examples:**
- ❌ "Error 500"
- ❌ "Something went wrong"
- ✅ "Couldn't save changes. Check your connection and try again."

### Empty States

Never leave blank space. Empty states should:
1. Explain why it's empty
2. Guide toward first action
3. Feel inviting, not broken

```
┌─────────────────────────────────────┐
│                                     │
│            [Illustration]           │
│                                     │
│       No projects yet               │
│                                     │
│   Create your first project to      │
│   start organizing your work.       │
│                                     │
│        [+ Create Project]           │
│                                     │
└─────────────────────────────────────┘
```

### Notification Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Silent failures | User thinks action worked | Always show feedback |
| Auto-dismissing errors | Can't read/act in time | Persist until acknowledged |
| Toast for errors | Not prominent enough | Inline or banner |
| Stacking many toasts | Overwhelming | Queue or consolidate |
| Same style for all types | Can't distinguish severity | Different colors/icons |

---

## Loading States

### Decision: Which Loading Pattern?

```
Do you know how long it will take?
├── Yes: Is it > 10 seconds?
│   ├── Yes → Progress bar with estimate
│   └── No → Determinate progress bar
└── No: Is it content loading?
    ├── Yes → Skeleton screen
    └── No: Is it < 3 seconds expected?
        ├── Yes → Spinner (maybe delayed)
        └── No → Indeterminate progress with status
```

### Loading Indicators

| Type | Use For |
|------|---------|
| Spinner | Short, indeterminate loads (<3s expected) |
| Progress bar | Determinate progress, long operations |
| Skeleton | Content loading, maintains layout |
| Shimmer | Content loading with motion |

### Skeleton Screens

```
┌─────────────────────────────────────┐
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░         │
├─────────────────────────────────────┤
│ ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓                │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░   │
│ ░░░░░░░░░░░░░░░░░░░░░░░░░░         │
└─────────────────────────────────────┘
```

- Match shape of actual content
- Subtle pulse animation (not distracting)
- Better than spinners for content areas

### Optimistic UI

Update UI before server confirms (for low-risk actions):
1. Update UI immediately
2. Send request to server
3. Rollback if fails (with notification)

**Good for:** Likes, toggles, reordering
**Avoid for:** Payments, deletions, critical data

### Loading Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Full-page spinner | Feels broken/slow | Skeleton or partial loading |
| No loading state | User thinks click didn't work | Immediate feedback |
| Spinner for content | Layout shift when loaded | Skeleton screens |
| Blocking all interaction | Frustrating | Load progressively |
| No timeout handling | Infinite waiting | Error after reasonable time |

---

## Onboarding

### Onboarding Principles

- **Delay signup**: Let users see value first
- **Progressive profiling**: Ask minimum now, more later
- **Skippable**: Don't block returning users
- **Contextual**: Teach at moment of need, not upfront dump

### Decision: Which Onboarding Pattern?

```
Is user brand new to this type of product?
├── Yes: Is the product complex?
│   ├── Yes → Guided setup + contextual tooltips
│   └── No → Empty state guidance
└── No: Is there critical setup required?
    ├── Yes → Minimal required wizard
    └── No → No onboarding (let them explore)
```

### Onboarding Patterns

**Empty State Guidance:**
Teach within the first empty state, not before.

**Tooltips/Coachmarks:**
```
┌─────────────────────────────────┐
│                        [+ New] ←── ┌─────────────────┐
│                                    │ Create your     │
│                                    │ first project   │
│                                    │ here.    [Got it]│
│                                    └─────────────────┘
```
- Point to actual UI
- Dismissible
- Don't overwhelm (1-3 max per session)

**Checklist:**
```
Get started (2/4 complete)
[✓] Create account
[✓] Set up profile
[ ] Invite team members
[ ] Create first project
```
- Shows progress
- Completable, not infinite
- Celebrate completion

### First-Run Experience

**Good pattern:**
1. Sign up (minimal info)
2. One key action (create first X)
3. Immediate value delivery
4. Secondary setup later

### Onboarding Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Long tutorial before use | Users forget, leave | Teach in context |
| Feature tour of empty UI | Nothing to relate to | Teach with real content |
| Mandatory multi-step wizard | High drop-off | Minimal required steps |
| Can't skip/dismiss | Frustrates returning users | Always skippable |
| Tooltips everywhere | Overwhelming | 1-3 per session max |
| No empty state guidance | Users don't know what to do | Clear first action |

---

## Tables & Lists

### Decision: Table vs List vs Cards vs Grid

```
Is data structured with multiple comparable attributes?
├── Yes: Are rows similar and need comparison?
│   ├── Yes → Table
│   └── No → Cards (varying content per item)
└── No: Is content primarily visual?
    ├── Yes: Are items equal importance?
    │   ├── Yes → Grid
    │   └── No → Featured + list/grid
    └── No → List
```

### Table Best Practices

**Structure:**
- Header row: Clear labels, sortable indicators
- Alignment: Numbers right, text left
- Row actions: End of row or hover-reveal

**Responsive Tables:**
- Horizontal scroll for wide tables
- Card transformation on mobile
- Priority columns (show key, hide secondary)

```
Desktop:
| Name       | Status   | Created    | Actions |
|------------|----------|------------|---------|
| Project A  | Active   | Jan 1      | ••• |

Mobile (cards):
┌─────────────────────┐
│ Project A        ••• │
│ Active • Jan 1       │
└─────────────────────┘
```

### List Interactions

- **Select**: Checkbox or tap row
- **Expand**: Reveal details inline
- **Swipe actions**: Delete, archive (mobile)
- **Reorder**: Drag handle + drop zones

### Pagination vs Infinite Scroll

```
Does user need to find a specific item or return to a point?
├── Yes → Pagination
│         (URLs stable, bookmarkable, keyboard-friendly)
└── No: Is content time-based/exploratory (feed)?
    ├── Yes → Infinite scroll
    │         (Add "back to top" and position memory)
    └── No: Is total count manageable (<100)?
        ├── Yes → Show all or pagination
        └── No → Pagination with visible total
```

---

## Search

### Search Box

**Placement:**
- Consistent location (usually header)
- Easily accessible
- Appropriate width (25-30 characters minimum)

**Behavior:**
- Show recent searches
- Autocomplete/suggestions
- Clear button when filled

### Search Results

```
Showing 24 results for "project"

┌─────────────────────────────────────┐
│ **Project** Management Guide        │
│ Learn how to manage **projects**... │
│ docs.example.com/guide              │
└─────────────────────────────────────┘
```

- Echo query at top
- Result count
- Highlight matched terms
- Show context/snippet
- Faceted filters for large sets

### No Results

```
┌─────────────────────────────────────┐
│                                     │
│   No results for "asdfgh"           │
│                                     │
│   Suggestions:                      │
│   • Check your spelling             │
│   • Try more general terms          │
│   • Browse categories below         │
│                                     │
│   [Browse all] [Clear search]       │
│                                     │
└─────────────────────────────────────┘
```

---

## Mobile-Specific Patterns

### Bottom Sheets

```
┌─────────────────────────────────────┐
│           Content                   │
│                                     │
├─────────────────────────────────────┤
│             ━━━                     │ ← Drag handle
│ ┌─────────────────────────────────┐ │
│ │  Option 1                       │ │
│ │  Option 2                       │ │
│ │  Option 3                       │ │
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

- Use for: Actions, filters, secondary content
- Drag to dismiss
- Multiple height stops (peek, half, full)

### Pull to Refresh

```
     ↓ Pull to refresh
┌─────────────────────┐
│                     │
│   [Refreshing...]   │
│                     │
│   Content           │
│                     │
└─────────────────────┘
```

- Clear affordance
- Loading indicator during refresh
- Update timestamp after

### Floating Action Button (FAB)

```
┌─────────────────────┐
│                     │
│   Content           │
│                     │
│                 ┌───┤
│                 │ + │
│                 └───┘
└─────────────────────┘
```

- Single primary action
- Bottom right (thumb zone)
- Don't overuse (one per screen max)
- Consider extended FAB with label for clarity

### Gesture Shortcuts

| Gesture | Common Use |
|---------|------------|
| Swipe left | Delete, archive |
| Swipe right | Mark complete, favorite |
| Long press | Select, context menu |
| Pinch | Zoom |
| Pull down | Refresh |

**Always provide visible alternative to gestures.**

### Mobile Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Tiny touch targets | Mis-taps | ≥44pt/48dp |
| Hover-dependent features | No hover on touch | Tap alternatives |
| Desktop modals on mobile | Hard to dismiss | Bottom sheets |
| Gesture-only actions | Not discoverable | Visible buttons + gesture |
| Fixed nav + keyboard | Covers input | Hide nav during input |
| Long forms on mobile | High abandonment | Minimize or split steps |
