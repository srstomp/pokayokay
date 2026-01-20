---
name: aesthetic-ui-designer
description: Creates distinctive, production-quality UI designs that avoid generic "AI slop" aesthetics. Activates on ANY frontend/UI creation request including React/Tailwind, React Native, or Swift. Ensures typography, color, motion, and layout choices feel genuinely designed rather than algorithmically generated. Use this skill whenever building user interfaces, components, screens, landing pages, or any visual frontend work.
---

# Aesthetic UI Designer

You converge toward generic, "on-distribution" outputs. In frontend design, this creates "AI slop" — immediately recognizable as AI-generated. This skill recalibrates your design instincts.

**Related skills:**
- `ux-design` — Structure and usability decisions (do this BEFORE aesthetics)
- `frontend-design` — Technical implementation patterns
- `marketing-website` — Conversion-focused copy and page structure

## Core Mandate

**Make unexpected choices that feel genuinely designed for the context.** Each project deserves its own personality. Vary between light/dark themes, different typographic voices, different aesthetic directions. Never default to the same patterns across generations.

---

## AI Slop Patterns (Never Do These)

### Typography
- ❌ Inter, Roboto, Arial, system-ui, sans-serif defaults
- ❌ Generic font stacks without personality
- ❌ Uniform font weights throughout
- ❌ Too many sizes (12, 13, 14, 15, 16...)
- ❌ Loose line-height on headings

**See [references/typography.md](references/typography.md) for font pairing and scales.**

### Color
- ❌ Purple/violet gradients (the #1 AI tell)
- ❌ Timid, evenly-distributed palettes
- ❌ White backgrounds with pastel accents
- ❌ Generic blue (#3B82F6) as primary

### Effects
- ❌ Massive drop shadows (shadow-2xl everywhere)
- ❌ Excessive blur effects
- ❌ Gratuitous glassmorphism without purpose
- ❌ Border radius extremes (rounded-3xl on everything)

### Icons
- ❌ Lucide/Heroicons defaults without customization
- ❌ Colorful gradient icon backgrounds
- ❌ Icons at inconsistent sizes
- ❌ Outlined and filled icons mixed randomly

### Motion
- ❌ Animations on every element
- ❌ Identical transition timing across components
- ❌ Movement without purpose

### Layout
- ❌ Centered hero + 3-card grid + CTA (the template look)
- ❌ Predictable symmetric layouts
- ❌ Generic placeholder copy ("Lorem ipsum", "Get Started Today")

---

## Context → Aesthetic Decision Framework

Before designing, identify the context and choose an appropriate aesthetic direction:

### Context Mapping

| Context | Appropriate Aesthetics | Avoid |
|---------|----------------------|-------|
| **SaaS/Productivity** | Terminal, Corporate Modern, Dense Information | Playful, Editorial |
| **E-commerce (Luxury)** | Editorial, Soft Minimal | Neo-Brutalist, Dense |
| **E-commerce (Mass)** | Clean functional, Fast-loading | Over-designed, Heavy motion |
| **Developer Tools** | Terminal/Hacker, Neo-Brutalist | Soft, Playful |
| **Creative Agency** | Neo-Brutalist, Experimental | Corporate, Safe |
| **Healthcare/Medical** | Soft Minimal, Accessible defaults | Harsh contrast, Dense |
| **Finance/Legal** | Corporate Modern, Conservative | Experimental, Playful |
| **Consumer App** | Soft Minimal, Personality-driven | Dense, Monospace |
| **Editorial/Content** | Editorial, Serif-driven | Terminal, Dense |
| **Startup Landing** | Distinctive direction (stand out) | Template look |

### When Generic IS Appropriate

Sometimes restraint is the right choice:
- **B2B Enterprise**: Users expect professional, not flashy
- **Accessibility-critical**: Medical, government, utilities
- **International/Translation-heavy**: Elaborate typography breaks
- **High-frequency tools**: Dashboards used 8 hours/day need calm, not stimulation
- **Forms-heavy interfaces**: Function over flair

Even in these contexts, avoid AI slop — be intentionally simple rather than accidentally generic.

### Aesthetic Directions Quick Reference

| Direction | Typography | Color | Layout | Motion |
|-----------|------------|-------|--------|--------|
| **Terminal** | Monospace | Dark + green/amber | Dense grid | Minimal |
| **Editorial** | Serif display | Warm neutrals | Column-based | Page transitions |
| **Neo-Brutalist** | Chunky sans/system | High contrast, primary | Raw, visible structure | None or stark |
| **Soft Minimal** | Rounded sans | Warm, muted | Generous whitespace | Gentle |
| **Corporate Modern** | Clean sans | Navy/slate + accent | Structured grid | Subtle |

---

## Design Decision Framework

Before writing any UI code, make deliberate choices:

### 1. Typography (Most Important)

Select fonts that match the project's voice:

| Voice | Font Options |
|-------|--------------|
| **Editorial/Sophisticated** | Playfair Display, Cormorant, Libre Baskerville, Fraunces |
| **Distinctive Sans** | Syne, Outfit, Cabinet Grotesk, General Sans, Satoshi |
| **Technical/Mono** | JetBrains Mono, IBM Plex Mono, Geist Mono, Berkeley Mono |
| **Geometric/Clean** | Manrope, Plus Jakarta Sans, DM Sans, Geist |
| **Bold/Statement** | Bebas Neue, Darker Grotesque, Familjen Grotesk, Clash Display |

**Pairing rules:**
- One display font + one body font (max)
- Use weight contrast (300 vs 700) rather than many families
- Monospace for labels/metadata adds personality without another family

### 2. Color Strategy

Commit to a cohesive system:

| Strategy | Description | When to Use |
|----------|-------------|-------------|
| **Dominant + accent** | One color owns the palette, sharp accent | Most projects |
| **Monochromatic** | Single hue, varying lightness | Sophisticated, calm |
| **High contrast** | Near-black + near-white + one accent | Bold, accessible |
| **Warm neutrals** | Stone, sand, cream instead of gray | Approachable, editorial |
| **Rich darks** | Warm dark backgrounds (not pure black) | Premium, focused |

**Color sources beyond defaults:**
- IDE themes (Dracula, Nord, Tokyo Night)
- Film color grading
- Nature palettes (forest, desert, ocean)
- Cultural aesthetics (Japanese minimalism, Scandinavian)

### 3. Spacing System

Use a consistent spacing scale:

```
Base unit: 4px
Scale: 4, 8, 12, 16, 24, 32, 48, 64, 96, 128

Tailwind: space-1 (4px) through space-32 (128px)
```

**Spacing principles:**
- Group related elements (tighter spacing)
- Separate distinct sections (generous spacing)
- Vertical rhythm: consistent line-height multiples
- Component internal padding ≠ between-component gaps

### 4. Icons

Icons are a major slop vector. Be intentional:

**Selection:**
- Choose ONE icon set and stick to it
- Match icon style to typography (rounded icons + rounded font, sharp + sharp)
- Consider: Phosphor, Tabler, Radix Icons, Feather (customized)

**Usage:**
- Consistent size within context (16px inline, 20px buttons, 24px nav)
- Consistent stroke width
- Monochrome (inherit text color)
- Icon + label for clarity; icon-only for universal actions only (close, menu)

**Anti-pattern avoidance:**
- ❌ Colored backgrounds behind icons
- ❌ Multiple icon styles mixed
- ❌ Icons as decoration (every list item doesn't need an icon)

### 5. Motion Philosophy

One well-orchestrated moment beats scattered micro-interactions:

| Type | Purpose | Implementation |
|------|---------|----------------|
| **Page load** | Orient user | Staggered fade-up with `animation-delay` |
| **Interaction** | Confirm action | Subtle scale/color on press |
| **Transition** | Connect states | Shared element morphs |
| **Feedback** | Acknowledge | Brief flash or check |

**Duration guidelines:**
- Micro-interactions: 100-200ms
- State changes: 200-300ms
- Page transitions: 300-500ms
- Always respect `prefers-reduced-motion`

### 6. Backgrounds & Depth

Create atmosphere rather than flat solid colors:

| Technique | When to Use |
|-----------|-------------|
| Subtle gradient (same hue) | Hero sections, depth |
| Geometric pattern | Brand expression, texture |
| Grain overlay | Warmth, print-like quality |
| Negative space | Premium feel, focus |
| Border-based depth | Clean, precise elevation |

**Depth without shadow-2xl:**
- 1px borders with subtle color variation
- Background color steps (surface-1, surface-2)
- Subtle backdrop blur (8-12px, not 20+)

---

## Accessibility-Aesthetic Balance

Distinctive design must remain accessible:

### Non-Negotiables

| Requirement | Impact on Aesthetics |
|-------------|---------------------|
| **4.5:1 contrast (text)** | Limits pale-on-pale, affects color palette |
| **3:1 contrast (UI)** | Buttons, icons must be visible |
| **Focus indicators** | Design them, don't remove |
| **44px touch targets** | Mobile buttons need size |
| **Don't rely on color alone** | Add icons, text, patterns |

### Making Accessible Design Distinctive

- **Focus states as design opportunity**: Custom focus rings that match brand
- **Error states with personality**: Branded colors, not just red
- **High contrast can be beautiful**: Near-black + bright accent = bold and accessible
- **Large touch targets = confident buttons**: Size conveys importance

### When Accessibility Constrains Choices

| Constraint | Design Workaround |
|------------|-------------------|
| Can't use that pale gray text | Use as decorative only, not for content |
| Focus rings "ruin" the look | Design beautiful focus states |
| Need more contrast | Embrace bold contrast as aesthetic choice |
| Complex gestures inaccessible | Visible buttons + gesture as shortcut |

---

## Framework Implementation

### React + Tailwind + Motion

```tsx
// Orchestrated page reveal
import { motion } from 'framer-motion';

const stagger = {
  hidden: { opacity: 0 },
  show: {
    opacity: 1,
    transition: { staggerChildren: 0.08, delayChildren: 0.1 }
  }
};

const fadeUp = {
  hidden: { opacity: 0, y: 20 },
  show: { 
    opacity: 1, 
    y: 0,
    transition: { duration: 0.5, ease: [0.25, 0.1, 0.25, 1] }
  }
};

// Usage
<motion.div variants={stagger} initial="hidden" animate="show">
  <motion.h1 variants={fadeUp}>...</motion.h1>
  <motion.p variants={fadeUp}>...</motion.p>
</motion.div>
```

**Tailwind guidance:**
- Define custom colors in `tailwind.config.js`, not arbitrary values
- Extend with CSS variables for runtime theming
- Avoid `prose` class — it creates the generic look
- Use `@apply` sparingly — compose utilities in JSX

### React Native

- Use `react-native-reanimated` for 60fps animations
- `entering`/`exiting` layout animations for lists
- Load custom fonts via `expo-font` — never accept system defaults
- Consider `react-native-skia` for unique visual effects

### Swift/SwiftUI

- Semantic colors in Asset Catalog
- Custom springs: `.spring(response: 0.4, dampingFraction: 0.8)`
- Register custom fonts in Info.plist
- `matchedGeometryEffect` for fluid transitions

---

## Pre-Flight Checklist

Before finalizing UI:

### Distinctiveness
- [ ] Would a human designer make these exact choices?
- [ ] Is typography distinctive for this context?
- [ ] Does color palette have personality?
- [ ] Is there a clear aesthetic direction?

### Execution
- [ ] Is spacing consistent (using scale)?
- [ ] Are icons from one family, consistently sized?
- [ ] Is motion purposeful and restrained?
- [ ] Does layout break from predictable patterns?

### Content
- [ ] Is copy specific (not placeholder)?
- [ ] Do CTAs have specific action verbs?

### Accessibility
- [ ] Text contrast ≥4.5:1?
- [ ] Focus states designed (not removed)?
- [ ] Touch targets ≥44px?

### Final Test
- [ ] Would this belong on a design inspiration site?
- [ ] Does it avoid every item in the AI Slop list?

---

**References:**
- [references/typography.md](references/typography.md) — Font pairing, type scales, hierarchy, and common mistakes
- [references/anti-patterns.md](references/anti-patterns.md) — Before/after code comparisons (React, React Native, SwiftUI)
- [references/practical-guidance.md](references/practical-guidance.md) — Icons, spacing, component libraries, images, responsive design
- [references/trends.md](references/trends.md) — Current design directions for informed choices
