# Modern UX Patterns

Patterns for contemporary interfaces: AI experiences, dark mode, animation, internationalization, and data visualization.

## Dark Mode & Theming

### Implementation Approaches

**System Preference Detection:**
```css
@media (prefers-color-scheme: dark) {
  :root {
    --bg-primary: #1a1a1a;
    --text-primary: #ffffff;
  }
}
```

**User Choice + System Default:**
```
Theme options:
├── System (default) — Follow OS preference
├── Light — Always light
└── Dark — Always dark
```

### Toggle Placement

| Location | Best For |
|----------|----------|
| Settings page | Apps, less frequent switching |
| Header/Navbar | Frequent toggling, prominent feature |
| Profile dropdown | Secondary access, space-constrained |

**UX Guidelines:**
- Persist user preference (localStorage)
- Avoid flash on page load (preload theme)
- Instant switch (no page reload)

### Color Considerations

**Don't just invert:**
```
Light mode          Dark mode
─────────           ─────────
#FFFFFF (bg)    →   #1A1A1A (bg)      ✓ Inverted
#000000 (text)  →   #FFFFFF (text)    ✗ Too harsh

Better:
#000000 (text)  →   #E0E0E0 (text)    ✓ Softer
```

**Dark Mode Color Rules:**
- Reduce white brightness (use ~90% white)
- Desaturate bright colors
- Increase contrast for UI elements
- Shadows become less visible — use borders/elevation

**What Changes:**
- Background colors
- Text colors (slightly dimmer than pure white)
- Image brightness (consider dimming)
- Shadows (reduce or replace with borders)

**What Stays Consistent:**
- Brand colors (may need dark variants)
- Semantic colors (success, error)
- Interactive element recognition

### Dark Mode Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Pure black (#000) backgrounds | Harsh, eye strain | Use dark gray (#1a1a1a) |
| Pure white (#fff) text | Too much contrast | Use #e0e0e0 or #f0f0f0 |
| Same colors for both modes | Poor contrast in one mode | Create dark mode palette |
| Flash of wrong theme | Jarring on load | Preload theme before render |
| No system preference option | Forces manual choice | Default to "system" |

---

## AI & Conversational UX

### AI Response Patterns

**Streaming Responses:**
```
┌─────────────────────────────────────┐
│ User: What is machine learning?     │
├─────────────────────────────────────┤
│ AI: Machine learning is a branch of │
│ artificial intelligence that█       │
│                                     │
│ [Stop generating]                   │
└─────────────────────────────────────┘
```

- Stream text word-by-word or chunk-by-chunk
- Show cursor/typing indicator
- Allow user to stop generation
- Don't show "typing..." for long periods

**Loading States for AI:**

| Pattern | Use When |
|---------|----------|
| Streaming text | Response being generated |
| Skeleton + "Thinking..." | Processing before response |
| Progress steps | Multi-step AI workflow |
| Pulsing indicator | Short wait (<5s) |

### Confidence & Uncertainty

**Show confidence appropriately:**
```
High confidence:
"The capital of France is Paris."

Low confidence:
"Based on the available information, it appears that..."
"I'm not certain, but..."
```

**Visual confidence indicators:**
```
┌─────────────────────────────────────┐
│ Result: Paris                       │
│ Confidence: ████████░░ 80%          │
└─────────────────────────────────────┘
```

### Human-in-the-Loop

```
┌─────────────────────────────────────┐
│ AI Draft                            │
│ ─────────────────────────────────── │
│ Subject: Re: Meeting Follow-up      │
│                                     │
│ Thank you for meeting with me       │
│ yesterday. As discussed, I'll send  │
│ the proposal by Friday.             │
│                                     │
│ [Edit] [Regenerate] [Send as-is]    │
└─────────────────────────────────────┘
```

- Always allow editing AI output
- Offer regeneration options
- Don't auto-send/auto-commit
- Make AI's role clear (not masquerading as human)

### Chat Interface Patterns

**Message Bubbles:**
```
User messages: Right-aligned, brand color
AI messages: Left-aligned, neutral color
System messages: Centered, muted
```

**Input Area:**
```
┌─────────────────────────────────────┐
│ [📎] Type a message...        [Send]│
└─────────────────────────────────────┘
```

- Multi-line expansion for long input
- Attachment support (if applicable)
- Clear send affordance
- Keyboard shortcut (Enter or Cmd+Enter)

### AI UX Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| No loading state | User thinks it's broken | Immediate feedback: "Thinking..." |
| Can't stop generation | User trapped waiting | Stop/cancel button |
| Auto-apply AI changes | User loses control | Preview + explicit apply |
| No edit capability | AI output is final | Always editable |
| Hiding AI involvement | Misleading | Transparent about AI role |
| Over-promising accuracy | Trust erosion | Appropriate confidence language |
| No fallback for failures | Dead end | Retry, alternative, or human handoff |

### Prompt Input UX

**Suggestions/Starters:**
```
┌─────────────────────────────────────┐
│ Try asking:                         │
│ • "Summarize this document"         │
│ • "Find action items"               │
│ • "Translate to Spanish"            │
└─────────────────────────────────────┘
```

**Prompt Templates:**
```
┌─────────────────────────────────────┐
│ Write a [type] about [topic]        │
│        ↓              ↓             │
│     [dropdown]    [text input]      │
└─────────────────────────────────────┘
```

---

## Animation & Motion

### When to Animate

| Animate | Don't Animate |
|---------|---------------|
| State transitions | First render |
| User-initiated actions | Background updates |
| Spatial relationships | Every hover state |
| Drawing attention | Decorative motion |
| Loading/progress | Static content |

### Duration Guidelines

| Animation Type | Duration | Easing |
|----------------|----------|--------|
| Micro-interactions (button) | 100-200ms | ease-out |
| State changes (toggle) | 150-300ms | ease-out |
| Enter/appear | 200-300ms | ease-out |
| Exit/disappear | 150-200ms | ease-in |
| Page transitions | 300-500ms | ease-in-out |
| Complex sequences | 300-700ms | custom |

**Rule of thumb:** Fast enough to feel responsive, slow enough to be perceived.

### Easing Functions

```
ease-out:    Fast start, slow end    (entering elements)
ease-in:     Slow start, fast end    (exiting elements)
ease-in-out: Slow-fast-slow          (moving elements)
linear:      Constant speed          (progress bars only)
```

### Common Animation Patterns

**Fade:**
- Simplest transition
- Use for: modals, toasts, subtle changes
- Avoid: spatial changes (confusing origin)

**Slide:**
- Shows direction/relationship
- Use for: panels, drawers, navigation
- Direction should match mental model (right = forward)

**Scale:**
- Draws attention
- Use for: emphasis, appearing elements
- Subtle scaling (0.95-1.0, not 0-1)

**Skeleton Shimmer:**
```css
@keyframes shimmer {
  0% { background-position: -200px 0; }
  100% { background-position: 200px 0; }
}
```

### Reduced Motion

**Always respect system preference:**
```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
  }
}
```

**Alternative for reduced motion:**
- Replace motion with opacity changes
- Use instant state changes
- Keep essential feedback (just simpler)

### Animation Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Animation on every hover | Distracting, fatiguing | Reserve for important interactions |
| Long durations (>500ms) | Feels slow | Keep under 300ms for most |
| Blocking animations | Can't interact during | Allow interruption |
| Bouncy/playful for serious UI | Undermines credibility | Match tone to context |
| Ignoring reduced motion | Accessibility failure | Always provide alternative |
| Animation without purpose | Visual noise | Every animation earns its place |

---

## Micro-interactions

### Anatomy of Micro-interaction

```
Trigger → Rules → Feedback → Loops/Modes
  │         │        │          │
Click    Logic    Visual/     Repeat?
Hover    State    Audio       States?
Gesture  Change   Haptic
```

### Common Micro-interactions

**Button Press:**
```
Default → Hover → Active → Loading → Success
                    ↓
              Scale 0.98
              Darker color
```

**Toggle:**
```
OFF                     ON
[  ○    ] ──────────→ [    ● ]
  Gray                  Colored
         Slide + color
```

**Like/Favorite:**
```
♡ (empty) ──tap──→ ❤️ (filled)
                      │
                    Scale up 1.2
                    then settle 1.0
                    (optional: particles)
```

**Form Validation:**
```
Typing...    Blur         Error/Success
[        ] → [input   ] → [input ✓] green
                          [input ✗] red + shake
```

**Pull-to-Refresh:**
```
Pull ──→ Threshold ──→ Loading ──→ Complete
  │          │            │           │
Arrow      Spinner     Spinning    Checkmark
rotates    appears      active      dismiss
```

### Feedback Types

| Type | Use For | Platform |
|------|---------|----------|
| Visual (color, scale) | All interactions | All |
| Motion (animation) | State changes | All |
| Haptic (vibration) | Confirmations | Mobile |
| Audio (click, ping) | Important actions | Desktop (optional) |

### Delight vs Distraction

**Delightful:**
- Confirms user action
- Provides useful feedback
- Subtle, doesn't interrupt flow
- Consistent with brand

**Distracting:**
- Animations for everything
- Long, complex animations
- Sounds without user control
- Inconsistent animation language

---

## Data Visualization UX

### Chart Selection

| Data Type | Best Chart |
|-----------|------------|
| Comparison (few items) | Bar chart |
| Comparison (many items) | Horizontal bar |
| Trend over time | Line chart |
| Part of whole | Pie (≤5 slices) or stacked bar |
| Distribution | Histogram |
| Correlation | Scatter plot |
| Geographic | Map |

### Interaction Patterns

**Hover/Touch Details:**
```
┌────────────────────────────────────────┐
│     ●                                  │
│    /│\     ┌───────────────┐          │
│   / │ \    │ March 2024    │          │
│  /  │  \   │ Revenue: $45K │          │
│ ●   │   ●  └───────────────┘          │
└────────────────────────────────────────┘
```

- Show tooltip on hover/touch
- Highlight related data
- Don't require hover for key information

**Filtering/Drilling:**
```
[All] [Product A] [Product B]
    ↓
Click legend → Toggle series visibility
Click bar → Drill into details
```

**Responsive Charts:**
- Simplify on mobile (fewer labels, larger touch targets)
- Consider different chart type (horizontal bar vs vertical)
- Allow full-screen/expand for detail

### Accessibility for Data Viz

**Required:**
- Alternative text describing key insights
- Data table alternative
- Colorblind-safe palettes
- Don't rely on color alone (use patterns/labels)

**Color Palettes:**
```
Categorical (distinct items):
Use 6-8 distinguishable colors

Sequential (low to high):
Single hue, varying lightness

Diverging (negative to positive):
Two hues meeting at neutral center
```

### Data Viz Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Pie chart with 10+ slices | Unreadable | Bar chart or group "other" |
| 3D charts | Distorts data | 2D only |
| Truncated Y-axis | Exaggerates differences | Start at zero (usually) |
| Rainbow color scales | No natural order | Sequential or diverging scales |
| Legend far from chart | Hard to match | Inline labels or nearby legend |
| No data table fallback | Accessibility failure | Provide table alternative |
| Jittery/animated data | Hard to read | Static or transition animations |

---

## Internationalization (i18n)

### Text Expansion

**Plan for text growth:**

| Language | Expansion vs English |
|----------|---------------------|
| German | +30% |
| French | +20% |
| Russian | +30% |
| Japanese | -10% (but height varies) |
| Arabic | +25% |

**Design implications:**
- Buttons with flexible width
- Avoid fixed-width containers for text
- Test with longer strings ("pseudolocalization")

### RTL (Right-to-Left) Layout

**Languages:** Arabic, Hebrew, Persian, Urdu

**What Mirrors:**
- Text alignment (right → left)
- Navigation flow
- Icons indicating direction (arrows, etc.)
- Progress bars (fill from right)
- Form layouts

**What Doesn't Mirror:**
- Phone numbers, dates
- Logos
- Video controls (universal)
- Charts with time-based X-axis

**CSS:**
```css
html[dir="rtl"] {
  /* Logical properties handle this automatically */
}

/* Use logical properties */
.element {
  margin-inline-start: 16px;  /* Not margin-left */
  padding-inline-end: 8px;    /* Not padding-right */
}
```

### Date, Time, Number Formats

| Locale | Date | Number | Currency |
|--------|------|--------|----------|
| US | 01/15/2024 | 1,234.56 | $1,234.56 |
| UK | 15/01/2024 | 1,234.56 | £1,234.56 |
| Germany | 15.01.2024 | 1.234,56 | 1.234,56 € |
| Japan | 2024/01/15 | 1,234.56 | ¥1,234 |

**Use Intl APIs:**
```javascript
new Intl.DateTimeFormat('de-DE').format(date);
new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }).format(1234.56);
```

### Icon & Imagery Considerations

**Culturally Sensitive:**
- Hand gestures (thumbs up, OK sign vary)
- Animal symbolism
- Colors (red = luck in China, danger in US)
- Religious symbols
- Body imagery

**Directional Icons:**
- Inbox/outbox arrows may need mirroring
- "Back" arrow should match reading direction
- Progress indicators

### i18n Anti-Patterns

| Anti-Pattern | Problem | Solution |
|--------------|---------|----------|
| Concatenating strings | Breaks in other languages | Use full phrases with placeholders |
| Hardcoded dates/numbers | Wrong format | Use Intl APIs |
| Fixed-width buttons | Text overflow | Flexible widths |
| Icons with embedded text | Can't translate | Separate text layer |
| Assuming LTR | Broken RTL layouts | Use logical CSS properties |
| US-centric defaults | Confuses global users | Detect locale or ask |

### String Externalization

```javascript
// ❌ Bad: Concatenation
const message = "Hello " + name + ", you have " + count + " items";

// ✅ Good: Templates with placeholders
const message = t('greeting', { name, count });
// greeting: "Hello {{name}}, you have {{count}} items"
// greeting_de: "Hallo {{name}}, Sie haben {{count}} Artikel"
```

---

## Summary: Modern Pattern Principles

1. **Respect user preferences** — System settings (dark mode, reduced motion, locale)
2. **Be transparent with AI** — Show what's AI, allow control
3. **Animate with purpose** — Every motion earns its place
4. **Design for the world** — Plan for translation and cultural differences
5. **Make data accessible** — Charts need alternatives and keyboard support
