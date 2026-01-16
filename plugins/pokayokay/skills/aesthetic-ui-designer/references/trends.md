# Design Trends Reference

Current directions in UI/UX design. Use as inspiration for context-appropriate choices — not as new defaults to copy blindly.

> **Note:** Trends are time-sensitive. This document captures patterns as of early 2025. The principles matter more than specific techniques — trends cycle, but intentional design choices endure.

---

## Core Principle

> "The goal isn't to follow trends — it's to make informed choices that feel intentional rather than default."

For each project, consider:
1. What aesthetic fits the brand/context?
2. Which trends serve that aesthetic?
3. What unexpected combination creates distinction?

Trends are ingredients, not recipes.

---

## Typography Trends

### Variable Fonts
Single font file with adjustable weight, width, slant. Enables smooth animations and precise control.
- **Examples**: Inter (if you must), Fraunces, Epilogue, Outfit
- **Use case**: Weight transitions on hover, responsive optical sizing
- **Principle**: Flexibility without file bloat

### Neo-Grotesque Revival
Clean sans-serifs with subtle personality. Successor to the geometric era.
- **Examples**: Satoshi, General Sans, Switzer, Geist
- **Character**: Neutral but not sterile
- **Principle**: Personality without distraction

### Expressive Display
Bold, characterful headlines contrasted with neutral body text.
- **Examples**: Cabinet Grotesk, Clash Display, Zodiak, Migra
- **Pairing**: Display + IBM Plex Sans, or Display + DM Sans
- **Principle**: Hierarchy through contrast

### Monospace Beyond Code
Mono fonts for UI elements, labels, metadata — not just code blocks.
- **Examples**: JetBrains Mono, Commit Mono, Geist Mono, Berkeley Mono
- **Use case**: Eyebrows, tags, timestamps, data
- **Principle**: Technical without being cold

### Serif Comeback
Serifs returning for warmth, editorial feel, differentiation from tech defaults.
- **Examples**: Fraunces, Newsreader, Source Serif 4, Lora
- **Context**: Content-heavy apps, editorial, luxury
- **Principle**: Standing out from sans-serif saturation

---

## Color Trends

### Rich Darks (Beyond #000)
Dark themes with warmth and depth, not flat black.
- Ink blue: `#0F172A`
- Warm charcoal: `#1C1917`
- Deep forest: `#14532D`
- Midnight: `#020617`
- **Principle**: Dark can be warm

### Warm Neutrals
Moving away from cool grays toward stone, sand, cream.
- Stone palette: `#1C1917` → `#F5F5F4`
- Sand: `#FEFCE8`, `#FEF3C7`
- Cream: `#FFFBEB`
- **Principle**: Approachable over clinical

### Single Accent Strategy
One vibrant accent color against neutral base. High impact, cohesive.
- Amber on stone: `#F59E0B` on `#1C1917`
- Cyan on slate: `#22D3EE` on `#0F172A`
- Lime on zinc: `#84CC16` on `#18181B`
- **Principle**: Restraint amplifies impact

### Nature-Derived Palettes
Colors from natural contexts — less synthetic, more grounded.
- Terracotta, sage, ochre, clay
- Forest greens, ocean blues (not neon)
- Sunset warm tones
- **Principle**: Organic over artificial

### High Contrast Returns
Near-black and near-white with minimal mid-tones. Bold, accessible.
- Background: `#09090B`
- Text: `#FAFAFA`
- One accent
- **Principle**: Bold AND accessible

---

## Layout Trends

### Asymmetric Grids
Breaking from centered, symmetric layouts. Intentional imbalance.
- Left-aligned heroes
- Offset image placements
- Varied column widths
- **Principle**: Tension creates interest

### Dense Information Design
More content visible, less scrolling. Inspired by terminals, dashboards, trading interfaces.
- Smaller text (14px body)
- Tighter spacing
- Data-rich interfaces
- **Principle**: Efficiency for power users

### Bento Grid
Varied-size cards in grid layout. Popularized by Apple, now widespread.
- Mix of 1x1, 2x1, 2x2 cells
- Clear visual hierarchy through size
- Works for features, portfolios, dashboards
- **Principle**: Size encodes importance

### Horizontal Scroll
Intentional horizontal sections for galleries, features, timelines.
- Scroll-snap for precision
- Clear affordance (partial visibility)
- Mobile-friendly swipe patterns
- **Principle**: Breaking vertical monotony

### Mega Footers
Footers as navigation hubs, not afterthoughts.
- Site maps, contact, social
- Newsletter capture
- Secondary CTAs
- **Principle**: Every section earns its space

---

## Motion Trends

### Scroll-Driven Animations
Elements animate based on scroll position. Native CSS support emerging.
- Parallax depth
- Progressive reveals
- Sticky transformations
- **Principle**: Scroll as interaction

### Micro-Interactions (Restrained)
Small feedback moments, not decoration.
- Button press states
- Toggle confirmations
- Input validation feedback
- **Principle**: Feedback, not flair

### Page Transitions
Smooth transitions between routes/pages.
- Shared element transitions
- Crossfade with stagger
- Exit animations before enter
- **Principle**: Continuity between states

### Spring Physics
Natural spring curves over linear/ease.
- `spring(response: 0.4, dampingFraction: 0.8)`
- Framer Motion: `type: "spring"`
- Feels organic, less mechanical
- **Principle**: Physics feels natural

### Reduced Motion Respect
Always provide `prefers-reduced-motion` alternatives.
- Instant state changes
- No parallax
- Essential animations only
- **Principle**: Accessibility is non-negotiable

---

## Visual Effect Trends

### Glassmorphism (Evolved)
Frosted glass effects, but subtler than 2021 peak.
- Lower blur values (8-12px vs 20+)
- Subtle borders
- Used sparingly, not everywhere
- **Principle**: Effect serves function

### Grain & Texture
Subtle noise overlays for warmth, print-like quality.
- SVG noise filters
- Low opacity (0.03-0.08)
- Adds depth to flat colors
- **Principle**: Digital can feel tactile

### Gradient Mesh
Complex, organic gradients. Beyond linear two-color.
- Multiple color stops
- Radial and conic gradients
- Subtle, not overwhelming
- **Principle**: Gradients can be sophisticated

### Border-Based Depth
Borders replacing shadows for elevation.
- 1px borders
- Subtle color variation
- Cleaner, more precise
- **Principle**: Precision over diffusion

### Negative Space
Generous whitespace as design element.
- Breathing room
- Focus direction
- Premium feel
- **Principle**: Space is intentional

---

## Component Trends

### Command Palettes (⌘K)
Keyboard-first navigation pattern.
- Quick actions
- Search everything
- Power user efficiency
- **Principle**: Speed for experts

### Bottom Navigation (Mobile)
Thumb-zone accessible primary nav.
- 4-5 items max
- Icon + label
- Active state clarity
- **Principle**: Ergonomics over convention

### Skeleton Loading
Content placeholders during load.
- Matches content shape
- Subtle pulse animation
- Better than spinners
- **Principle**: Perceived performance

### Toast Notifications
Non-blocking feedback.
- Bottom or top positioning
- Auto-dismiss
- Action buttons optional
- **Principle**: Inform without interrupting

### Floating Action Buttons (Contextual)
Single primary action, context-aware.
- Not for navigation
- Position: bottom-right
- Subtle shadow or elevation
- **Principle**: One clear action

---

## Aesthetic Directions

Use these as starting points for cohesive design systems:

### Neo-Brutalist
Raw, honest, anti-polish.
- System fonts or chunky sans
- Harsh borders, no shadows
- High contrast, primary colors
- Visible structure

### Editorial
Magazine-inspired, content-first.
- Serif headlines
- Column-based layouts
- Generous whitespace
- Typographic hierarchy

### Terminal/Hacker
Developer-inspired, information-dense.
- Monospace throughout
- Dark theme, green/amber accent
- Dense layouts
- Keyboard-first

### Soft Minimal
Warm, approachable, calm.
- Rounded corners (subtle)
- Warm neutrals
- Soft shadows
- Ample whitespace

### Corporate Modern
Professional but not boring.
- Clean sans-serif
- Navy/slate + one accent
- Structured grids
- Subtle motion

---

## What to Avoid (Dated Patterns)

These were trendy but now signal "template":

| Pattern | Why to Avoid |
|---------|--------------|
| Neumorphism (soft UI) | Hard to execute, accessibility issues |
| Extreme glassmorphism | Overused 2021-2022 |
| Purple gradients | The AI slop signature |
| Floating 3D illustrations | Blush/Humaaans style overexposed |
| Particle backgrounds | Performance and distraction |
| Oversized cursors | Gimmick |
| Rainbow gradients | Lacks sophistication |
| Excessive shadows | shadow-2xl everywhere |

---

## Applying Trends Thoughtfully

### Questions to Ask

1. **Does this trend serve my context?**
   - A banking app shouldn't adopt neo-brutalism
   - A developer tool can skip the warm neutrals

2. **Am I using it because it's trendy or because it fits?**
   - Bento grids work for feature showcases, not every layout
   - Variable fonts need a reason (animation, optical sizing)

3. **What's the expected lifespan?**
   - Navigation patterns last years
   - Color trends cycle faster
   - Effects (glass, grain) date quickly

4. **Can I execute it well?**
   - Glassmorphism done poorly looks cheap
   - Dense layouts need excellent hierarchy

### Timeless Over Trendy

When in doubt, these always work:
- Clear hierarchy
- Generous whitespace
- Intentional typography
- Restrained color
- Purposeful motion
- Accessibility

The best designs feel inevitable, not fashionable.
