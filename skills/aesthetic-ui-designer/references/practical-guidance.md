# Practical Design Guidance

Detailed guidance for common aesthetic decisions: icons, spacing, component libraries, images, and responsive design.

## Icons

Icons are a major AI slop vector. Default icon usage screams "template."

### Icon Set Selection

Choose ONE set and commit. Match to your typography and aesthetic:

| Icon Set | Character | Best For | Avoid For |
|----------|-----------|----------|-----------|
| **Phosphor** | Versatile, 6 weights | Most projects | — |
| **Lucide** | Clean, familiar | Neutral projects | Distinctive brands |
| **Tabler** | Friendly, rounded | Consumer apps | Corporate, dense |
| **Heroicons** | Apple-influenced | iOS-like apps | Distinctive needs |
| **Radix Icons** | Minimal, precise | Developer tools | Playful contexts |
| **Feather** | Light, elegant | Minimal designs | Dense UIs |
| **Material Symbols** | Variable, comprehensive | Google ecosystem | Non-Material designs |

### Icon Sizing System

Establish consistent sizes for each context:

```
Inline (with text):     16px
Buttons:                20px
Navigation:             24px
Feature highlights:     32-48px
Hero/decorative:        64px+
```

**React example:**
```tsx
// Define once, use everywhere
const iconSize = {
  sm: 16,
  md: 20,
  lg: 24,
  xl: 32,
} as const;

<Icon size={iconSize.md} />
```

### Icon Color Strategy

**Monochrome is almost always better:**

```tsx
// ❌ AI Slop
<div className="bg-gradient-to-r from-purple-500 to-blue-500 p-3 rounded-xl">
  <Icon className="text-white" />
</div>

// ✅ Distinctive
<Icon className="text-stone-600" />
// or with accent
<Icon className="text-amber-500" />
```

**When to use color:**
- Status indicators (success/error/warning)
- Brand marks (logo, not generic icons)
- Active states (selected tab)

**How to use color:**
- Inherit text color (`currentColor`)
- One accent color, not gradients
- Consistent across all icons

### Icon + Text Patterns

| Pattern | Usage | Implementation |
|---------|-------|----------------|
| **Icon left + text** | Buttons, menu items | `flex items-center gap-2` |
| **Text + icon right** | Links, "learn more" | Arrow indicates action |
| **Icon only** | Universal actions only | Always add `aria-label` |
| **Icon above text** | Navigation tabs | Balanced vertical layout |

**Universal icons (safe for icon-only):**
- Close (×)
- Menu (≡)
- Search (🔍)
- Plus/Add (+)
- Settings (⚙)
- User (👤)

**Need labels:**
- Feature-specific actions
- Navigation items
- Anything ambiguous

### Icon Anti-Patterns

| Anti-Pattern | Why It's Bad | Fix |
|--------------|--------------|-----|
| Gradient backgrounds | Screams AI-generated | Monochrome or subtle bg |
| Mixed icon sets | Visual inconsistency | One set throughout |
| Random sizes | Chaotic, unprofessional | Consistent size scale |
| Icons everywhere | Visual noise | Icons where they aid comprehension |
| Outlined + filled mixed | Inconsistent weight | Pick one style |
| Animated icons | Distracting | Static, animate on interaction only |

---

## Spacing System

Consistent spacing is foundational. Without it, designs feel "off."

### The 4px/8px Grid

Base everything on 4px increments. 8px is the practical unit:

```
4px   - Tight: icon-text gap, input padding
8px   - Small: related element spacing
12px  - Medium-small: list item padding
16px  - Medium: section padding, card padding
24px  - Large: between components
32px  - XL: section separation
48px  - 2XL: major section breaks
64px  - 3XL: page section margins
96px  - Hero spacing
```

### Tailwind Spacing Reference

```
space-1:  4px     p-1, m-1, gap-1
space-2:  8px     p-2, m-2, gap-2
space-3:  12px    p-3, m-3, gap-3
space-4:  16px    p-4, m-4, gap-4
space-6:  24px    p-6, m-6, gap-6
space-8:  32px    p-8, m-8, gap-8
space-12: 48px    p-12, m-12, gap-12
space-16: 64px    p-16, m-16, gap-16
space-24: 96px    p-24, m-24, gap-24
```

### Spacing Principles

**1. Group related, separate distinct:**
```tsx
// ❌ Uniform spacing
<div className="space-y-4">
  <h2>Title</h2>
  <p>Description</p>
  <Button>Action</Button>
</div>

// ✅ Intentional spacing
<div>
  <h2>Title</h2>
  <p className="mt-2">Description</p>  {/* Tight: related */}
  <Button className="mt-6">Action</Button>  {/* Loose: distinct */}
</div>
```

**2. Component padding ≠ between-component gaps:**
```tsx
// Card internal padding
<div className="p-6">

// Space between cards
<div className="grid gap-4">
```

**3. Vertical rhythm:**
Line-height should create consistent vertical spacing. Use multiples of your base unit:

```css
/* 4px base, 24px line-height = 6 units */
line-height: 1.5;  /* on 16px = 24px */
```

### Responsive Spacing

Spacing should scale with viewport:

```tsx
// Tailwind responsive spacing
<section className="py-12 md:py-16 lg:py-24">
  <div className="px-4 md:px-6 lg:px-8">
```

| Viewport | Horizontal padding | Section spacing |
|----------|-------------------|-----------------|
| Mobile | 16-20px | 48-64px |
| Tablet | 24-32px | 64-96px |
| Desktop | 32-64px | 96-128px |

---

## Component Library Customization

Using shadcn/ui, Radix, or MUI? Customize to avoid the template look.

### shadcn/ui Customization

shadcn is unstyled by design, but the defaults still look like "shadcn."

**1. Typography override:**
```tsx
// components/ui/button.tsx
// Replace default font
className="font-display"  // Your custom font
```

**2. Border radius:**
```css
/* globals.css */
:root {
  --radius: 0.375rem;  /* Default 0.5rem is very round */
}

/* Or go sharp */
:root {
  --radius: 0;
}
```

**3. Color tokens:**
```css
/* Replace slate with stone for warmth */
:root {
  --background: 0 0% 100%;
  --foreground: 28 10% 9%;  /* stone-950 */
  --muted: 60 5% 96%;        /* stone-100 */
  --muted-foreground: 25 5% 45%;  /* stone-500 */
  /* ... map all tokens to your palette */
}
```

**4. Shadow adjustment:**
```tsx
// Default shadcn buttons have no shadow
// Add subtle shadow for depth if needed
className="shadow-sm hover:shadow"
```

### Radix Primitives Styling

Radix is unstyled. Your CSS IS the design:

```tsx
// ❌ Quick implementation (looks generic)
<Dialog.Content className="bg-white rounded-lg p-6 shadow-xl">

// ✅ Distinctive
<Dialog.Content className="bg-stone-950 text-stone-100 p-8 border border-stone-800">
```

**Key Radix components to customize:**
- Dialog (don't use default white + shadow)
- DropdownMenu (custom item hover states)
- Tooltip (match your color system)
- Select (avoid default browser look)

### MUI Customization

MUI has strong defaults. Override the theme:

```tsx
const theme = createTheme({
  palette: {
    primary: {
      main: '#F59E0B',  // Your accent, not MUI blue
    },
    background: {
      default: '#1C1917',
      paper: '#292524',
    },
  },
  typography: {
    fontFamily: '"Syne", "Helvetica", sans-serif',
    h1: {
      fontWeight: 600,
    },
  },
  shape: {
    borderRadius: 4,  // Default 4 is fine, 8+ gets rounded
  },
  components: {
    MuiButton: {
      styleOverrides: {
        root: {
          textTransform: 'none',  // Remove UPPERCASE
          boxShadow: 'none',      // Remove elevation
        },
      },
    },
  },
});
```

### Component Library Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Default colors | Looks like docs | Map to your palette |
| Default radius | Recognizable as library | Adjust in theme |
| Default shadows | Often too heavy | Reduce or remove |
| Default spacing | May not match your grid | Override in theme |
| No typography change | System font = generic | Custom font family |

---

## Images & Media

Stock photos and generic illustrations kill distinctive design.

### Photography Guidelines

**Selection criteria:**
- Authentic > polished (real moments, not staged)
- Consistent treatment (all same filter/color grade)
- Context-appropriate subjects
- Avoid: handshake photos, diverse-team-at-whiteboard, pointing-at-laptop

**Treatment options:**

| Treatment | Effect | CSS/Tailwind |
|-----------|--------|--------------|
| Desaturate | Cohesive, editorial | `filter: saturate(0.8)` |
| Duotone | Brand-aligned | CSS blend modes |
| High contrast | Bold, graphic | `filter: contrast(1.2)` |
| Grain overlay | Texture, warmth | SVG noise filter |
| Blur | Background, depth | `filter: blur()` |

```tsx
// Consistent image treatment
<img 
  src={photo} 
  className="saturate-[0.85] contrast-[1.05]"
/>
```

### Illustration Approaches

**Avoid overused styles:**
- ❌ Humaaans / Blush style (everyone uses them)
- ❌ Isometric office scenes
- ❌ Generic blob backgrounds
- ❌ Undraw-style flat illustrations

**Distinctive alternatives:**
- Custom line illustrations
- Photography instead of illustration
- Abstract shapes (geometric, organic)
- Icons/diagrams over decorative illustrations
- No illustration (content-first)

### Image Placeholders & Loading

```tsx
// ❌ Generic skeleton
<div className="bg-gray-200 animate-pulse" />

// ✅ Branded skeleton
<div className="bg-stone-800 animate-pulse" />

// ✅ Blur placeholder (next/image)
<Image
  placeholder="blur"
  blurDataURL={blurHash}
/>
```

### Media Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Unsplash "top results" | Everyone uses the same photos | Dig deeper, or custom |
| No image treatment | Inconsistent look | Global filter/treatment |
| Generic illustrations | Template look | Abstract, custom, or none |
| Autoplaying video | Annoying, heavy | User-initiated |
| Stock icons in hero | Cheap look | Photo, abstract, or none |

---

## Responsive Aesthetics

Maintaining design quality across breakpoints.

### What Changes, What Stays

| Element | Responsive Behavior |
|---------|-------------------|
| **Typography scale** | Reduces on mobile |
| **Spacing** | Tighter on mobile |
| **Layout** | Reflows (stack, fewer columns) |
| **Navigation** | Pattern changes (tabs → hamburger) |
| **Touch targets** | Larger on mobile |
| **Color/palette** | STAYS CONSISTENT |
| **Font family** | STAYS CONSISTENT |
| **Brand elements** | STAYS CONSISTENT |

### Typography Scaling

```tsx
// Responsive type scale
<h1 className="text-3xl md:text-5xl lg:text-6xl">

// Line height often needs adjustment
<h1 className="text-3xl leading-tight md:text-5xl md:leading-none">
```

**Scale suggestion:**

| Element | Mobile | Tablet | Desktop |
|---------|--------|--------|---------|
| H1 | 32-36px | 48px | 60-72px |
| H2 | 24-28px | 32px | 40-48px |
| Body | 16px | 16px | 16-18px |
| Small | 14px | 14px | 14px |

### Layout Reflow Patterns

**Cards:**
```tsx
// 1 → 2 → 3 columns
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 md:gap-6">
```

**Hero:**
```tsx
// Stack on mobile, side-by-side on desktop
<section className="flex flex-col lg:flex-row lg:items-center">
  <div className="lg:w-1/2">Content</div>
  <div className="lg:w-1/2">Image</div>
</section>
```

**Navigation:**
```tsx
// Hidden on mobile, visible on desktop
<nav className="hidden md:flex gap-6">
// Mobile menu
<MobileMenu className="md:hidden" />
```

### Mobile-First Aesthetic Considerations

| Desktop Pattern | Mobile Adaptation |
|-----------------|-------------------|
| Hover effects | Press/active states |
| Subtle animations | Reduced or instant |
| Multi-column | Single column |
| Small touch targets | ≥44px minimum |
| Dense info | Progressive disclosure |
| Side-by-side | Stacked |

### Responsive Anti-Patterns

| Anti-Pattern | Problem | Fix |
|--------------|---------|-----|
| Shrinking everything | Unreadable on mobile | Reflow, don't shrink |
| Same spacing all sizes | Too tight desktop or too loose mobile | Responsive spacing |
| Hiding too much | Mobile gets inferior experience | Prioritize, don't hide |
| Breakpoint cliffs | Jarring layout jumps | Fluid transitions |
| Desktop-only features | Mobile users left out | Mobile-first approach |

---

## Quick Reference: Distinctive Choices

### Instead of This → Try This

| Generic | Distinctive |
|---------|-------------|
| Inter/system font | Project-specific typeface |
| Gray palette | Warm neutrals (stone, sand) |
| White background | Dark theme or cream |
| Shadow for depth | Border or background color |
| rounded-full buttons | Sharp or subtle radius |
| Lucide defaults | Phosphor with custom size scale |
| Stock photos | Treated photos or abstract |
| shadcn defaults | Customized theme tokens |
| 3-card grid | Asymmetric or bento layout |
| Purple gradient | Single accent on neutral |

### Checklist Before Shipping

- [ ] Custom font loaded (not Inter/system)
- [ ] Color palette has personality
- [ ] Icons are consistent (one set, one size scale)
- [ ] Spacing follows 4/8px grid
- [ ] Component library customized (not default theme)
- [ ] Images treated consistently
- [ ] Responsive behavior designed (not just shrunk)
- [ ] Accessibility maintained (contrast, focus, targets)
