# Typography Guide

Practical typography guidance for web and mobile applications. Covers font selection, pairing, hierarchy, and common mistakes.

## Quick Reference

### Safe Defaults That Work

If you need to ship fast:

| Use Case | Font Stack | Why |
|----------|------------|-----|
| **SaaS / Dashboard** | Inter + Inter | Neutral, highly legible, variable font |
| **Marketing site** | Instrument Serif + Inter | Editorial feel, professional |
| **Developer tool** | JetBrains Mono + Inter | Code-friendly, technical |
| **Mobile app** | System fonts | Native feel, zero load time |
| **Blog / Content** | Literata + Source Sans 3 | Readable long-form |

### The 3-Minute Type System

```css
/* Paste this and you're 80% there */
:root {
  /* Scale: 1.25 ratio (Major Third) */
  --text-xs: 0.75rem;    /* 12px */
  --text-sm: 0.875rem;   /* 14px */
  --text-base: 1rem;     /* 16px */
  --text-lg: 1.25rem;    /* 20px */
  --text-xl: 1.563rem;   /* 25px */
  --text-2xl: 1.953rem;  /* 31px */
  --text-3xl: 2.441rem;  /* 39px */
  --text-4xl: 3.052rem;  /* 49px */
  
  /* Line heights */
  --leading-tight: 1.2;   /* Headings */
  --leading-normal: 1.5;  /* Body copy */
  --leading-relaxed: 1.7; /* Long-form */
  
  /* Weights */
  --font-normal: 400;
  --font-medium: 500;
  --font-semibold: 600;
  --font-bold: 700;
}
```

---

## Font Pairing

### Pairing Principles

**Rule 1: Contrast, Not Conflict**
Pair fonts that are different enough to create interest, but share underlying characteristics (x-height, proportions).

**Rule 2: One Star, One Supporting**
One font should dominate (usually headings), the other supports (body). Never let them compete.

**Rule 3: Fewer is Better**
Two fonts maximum. One is often enough. Three is almost always too many.

**Rule 4: Match the Era**
Fonts from similar time periods or design movements tend to harmonize (both geometric, both humanist, etc.).

---

### Curated Pairings

#### Modern SaaS / Tech

| Heading | Body | Vibe | Example Use |
|---------|------|------|-------------|
| **Inter** | Inter | Clean, neutral | Dashboards, B2B apps |
| **Geist** | Geist | Sharp, technical | Dev tools, Vercel-style |
| **Manrope** | Inter | Friendly tech | Consumer apps |
| **Space Grotesk** | Inter | Geometric, modern | Fintech, crypto |
| **Satoshi** | Inter | Contemporary | Startups |
| **Plus Jakarta Sans** | Inter | Approachable | SaaS, productivity |

#### Editorial / Content

| Heading | Body | Vibe | Example Use |
|---------|------|------|-------------|
| **Instrument Serif** | Inter | Modern editorial | Blogs, magazines |
| **Fraunces** | Source Serif 4 | Warm, quirky | Creative agencies |
| **Playfair Display** | Lato | Classic elegance | Luxury, fashion |
| **Libre Baskerville** | Source Sans 3 | Traditional | News, publishing |
| **Newsreader** | Inter | Contemporary news | Journalism |
| **Lora** | Open Sans | Readable, warm | Long-form content |

#### Mobile-First

| Heading | Body | Platform | Notes |
|---------|------|----------|-------|
| **SF Pro** | SF Pro | iOS | System font, free |
| **Roboto** | Roboto | Android | System font, free |
| **System stack** | System stack | Cross-platform | Zero load time |

System font stack:
```css
font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, 
             "Helvetica Neue", Arial, sans-serif;
```

#### Developer / Technical

| Heading | Body | Mono | Notes |
|---------|------|------|-------|
| **Inter** | Inter | JetBrains Mono | Standard dev stack |
| **Geist** | Geist | Geist Mono | Vercel ecosystem |
| **IBM Plex Sans** | IBM Plex Sans | IBM Plex Mono | IBM design language |
| **Space Grotesk** | Inter | Space Mono | Geometric family |

#### Distinctive / Brand-Forward

| Heading | Body | Vibe | Notes |
|---------|------|------|-------|
| **Cabinet Grotesk** | Inter | Bold, confident | Statements |
| **Clash Display** | Satoshi | Modern, edgy | Creative tech |
| **General Sans** | Inter | Clean, versatile | Premium feel |
| **Sora** | Inter | Geometric, soft | Friendly tech |
| **Outfit** | Inter | Modern, clean | Contemporary |

---

### Font Sources

**Free & High Quality:**
- [Google Fonts](https://fonts.google.com) — Massive library, variable fonts
- [Fontsource](https://fontsource.org) — Self-hosted Google Fonts
- [Font Share](https://www.fontshare.com) — Indian Type Foundry, excellent quality
- [Uncut](https://uncut.wtf) — Curated free fonts

**Paid (Worth It):**
- [Pangram Pangram](https://pangrampangram.com) — Clash, Cabinet, General Sans
- [Atipo Foundry](https://www.atipofoundry.com) — Satoshi, Zodiak
- [Colophon](https://www.colophon-foundry.org) — Apercu, Reader
- [Commercial Type](https://commercialtype.com) — Premium classics

---

## Type Scale

### Understanding Scales

A type scale creates mathematical harmony between sizes. Common ratios:

| Ratio | Name | Feel | Use Case |
|-------|------|------|----------|
| 1.125 | Major Second | Subtle | Dense UI, mobile |
| 1.2 | Minor Third | Moderate | Most apps |
| 1.25 | Major Third | Balanced | Marketing, editorial |
| 1.333 | Perfect Fourth | Prominent | Bold headlines |
| 1.5 | Perfect Fifth | Dramatic | Hero sections |
| 1.618 | Golden Ratio | Classical | Luxury, editorial |

### Recommended Scales

#### Compact (1.2 ratio) — Dense UI

```css
--text-xs: 0.694rem;   /* 11px */
--text-sm: 0.833rem;   /* 13px */
--text-base: 1rem;     /* 16px */
--text-lg: 1.2rem;     /* 19px */
--text-xl: 1.44rem;    /* 23px */
--text-2xl: 1.728rem;  /* 28px */
--text-3xl: 2.074rem;  /* 33px */
--text-4xl: 2.488rem;  /* 40px */
```

Best for: Dashboards, admin panels, data-dense apps

#### Balanced (1.25 ratio) — General Purpose

```css
--text-xs: 0.75rem;    /* 12px */
--text-sm: 0.875rem;   /* 14px */
--text-base: 1rem;     /* 16px */
--text-lg: 1.25rem;    /* 20px */
--text-xl: 1.563rem;   /* 25px */
--text-2xl: 1.953rem;  /* 31px */
--text-3xl: 2.441rem;  /* 39px */
--text-4xl: 3.052rem;  /* 49px */
```

Best for: SaaS, apps, most websites

#### Expressive (1.333 ratio) — Marketing

```css
--text-xs: 0.75rem;    /* 12px */
--text-sm: 0.875rem;   /* 14px */
--text-base: 1rem;     /* 16px */
--text-lg: 1.333rem;   /* 21px */
--text-xl: 1.777rem;   /* 28px */
--text-2xl: 2.369rem;  /* 38px */
--text-3xl: 3.157rem;  /* 51px */
--text-4xl: 4.209rem;  /* 67px */
```

Best for: Landing pages, marketing sites, portfolios

### Tailwind Mapping

| CSS Variable | Tailwind | Size |
|--------------|----------|------|
| --text-xs | `text-xs` | 12px |
| --text-sm | `text-sm` | 14px |
| --text-base | `text-base` | 16px |
| --text-lg | `text-lg` | 18px |
| --text-xl | `text-xl` | 20px |
| --text-2xl | `text-2xl` | 24px |
| --text-3xl | `text-3xl` | 30px |
| --text-4xl | `text-4xl` | 36px |
| --text-5xl | `text-5xl` | 48px |

Note: Tailwind's default scale uses a ~1.2 ratio but isn't mathematically pure. For strict scales, define custom values in `tailwind.config.js`.

---

## Hierarchy & Weight

### The Hierarchy Stack

Every interface needs these levels:

| Level | Purpose | Example | Typical Style |
|-------|---------|---------|---------------|
| **Display** | Hero moments | Page title | 3xl-4xl, bold |
| **H1** | Page heading | "Dashboard" | 2xl, semibold |
| **H2** | Section heading | "Recent Activity" | xl, semibold |
| **H3** | Subsection | "This Week" | lg, semibold |
| **Body** | Main content | Paragraphs | base, normal |
| **Body Small** | Secondary | Timestamps | sm, normal |
| **Caption** | Tertiary | Labels, hints | xs, normal/medium |

### Weight Guidelines

**Don't rely on size alone.** Use weight + size + color together:

```
Hierarchy = Size × Weight × Color contrast
```

| Weight | Name | Use For |
|--------|------|---------|
| 400 | Regular | Body text, paragraphs |
| 500 | Medium | Emphasis, buttons, UI labels |
| 600 | Semibold | Headings (modern preference) |
| 700 | Bold | Strong headings, CTAs |

**Modern trend**: 600 (semibold) for headings instead of 700 (bold). Feels less aggressive.

### Weight Pairing

```css
/* Recommended */
h1, h2, h3 { font-weight: 600; }
body { font-weight: 400; }
strong { font-weight: 600; }
button { font-weight: 500; }

/* Avoid */
h1 { font-weight: 900; } /* Too heavy */
h1 { font-weight: 400; } /* No hierarchy */
```

---

## Line Height & Spacing

### Line Height Rules

| Content Type | Line Height | Why |
|--------------|-------------|-----|
| Headings | 1.1 – 1.2 | Tight, cohesive |
| UI text | 1.4 – 1.5 | Balanced |
| Body copy | 1.5 – 1.6 | Readable |
| Long-form | 1.6 – 1.8 | Comfortable reading |

**The bigger the text, the tighter the line height.**

```css
h1 { line-height: 1.1; }
h2, h3 { line-height: 1.2; }
p { line-height: 1.5; }
.long-form p { line-height: 1.7; }
```

### Letter Spacing

| Size | Spacing | Tailwind |
|------|---------|----------|
| Display (48px+) | -0.02em to -0.03em | `tracking-tighter` |
| Heading (24-48px) | -0.01em to -0.02em | `tracking-tight` |
| Body (14-18px) | 0 | `tracking-normal` |
| Small caps | +0.05em to +0.1em | `tracking-wide` |
| All caps | +0.05em to +0.15em | `tracking-wider` |

**Large text needs tighter spacing. Small caps and all-caps need looser spacing.**

### Paragraph Spacing

Space between paragraphs should be larger than line spacing but smaller than section spacing:

```css
p { 
  margin-bottom: 1em;  /* Same as font size */
}

/* Or use spacing scale */
p + p { margin-top: 1.5rem; }
section { margin-top: 3rem; }
```

---

## Responsive Typography

### Fluid Type

Instead of breakpoints, use `clamp()`:

```css
/* Fluid heading: 24px at 320px viewport, 48px at 1200px */
h1 {
  font-size: clamp(1.5rem, 1rem + 2.5vw, 3rem);
}

/* Fluid body: 16px minimum, scales slightly */
body {
  font-size: clamp(1rem, 0.95rem + 0.25vw, 1.125rem);
}
```

### Fluid Scale System

```css
:root {
  --text-base: clamp(1rem, 0.95rem + 0.25vw, 1.125rem);
  --text-lg: clamp(1.125rem, 1rem + 0.5vw, 1.25rem);
  --text-xl: clamp(1.25rem, 1rem + 1vw, 1.5rem);
  --text-2xl: clamp(1.5rem, 1rem + 2vw, 2rem);
  --text-3xl: clamp(1.875rem, 1rem + 3vw, 2.5rem);
  --text-4xl: clamp(2.25rem, 1rem + 4vw, 3.5rem);
}
```

### Mobile Considerations

| Aspect | Desktop | Mobile | Why |
|--------|---------|--------|-----|
| Base size | 16px | 16px | Minimum for readability |
| Heading scale | 1.25+ | 1.2 | Less room for drama |
| Line height | 1.5 | 1.6 | More thumb scrolling |
| Measure (width) | 65-75ch | 100% | Full width is fine |

---

## Common Mistakes

### Mistake 1: Too Many Weights

❌ **Problem**: Using 400, 500, 600, 700, 800 all on one page

```css
/* Bad */
.label { font-weight: 500; }
.title { font-weight: 800; }
.subtitle { font-weight: 600; }
.body { font-weight: 400; }
.emphasis { font-weight: 700; }
```

✅ **Fix**: Limit to 2-3 weights

```css
/* Good */
h1, h2, h3 { font-weight: 600; }
body, p { font-weight: 400; }
strong, button { font-weight: 500; }
```

---

### Mistake 2: Too Many Sizes

❌ **Problem**: 12px, 13px, 14px, 15px, 16px, 17px...

✅ **Fix**: Use a scale with clear jumps

```css
/* Use only these sizes */
--text-xs: 12px;
--text-sm: 14px;
--text-base: 16px;
--text-lg: 20px;
--text-xl: 25px;
```

---

### Mistake 3: Headings That Don't Pop

❌ **Problem**: H1 looks barely different from body text

```css
/* Bad */
h1 { font-size: 1.5rem; font-weight: 400; }
p { font-size: 1rem; font-weight: 400; }
```

✅ **Fix**: Combine size + weight + color

```css
/* Good */
h1 { 
  font-size: 2.5rem; 
  font-weight: 600; 
  color: var(--text-primary);   /* darker */
  letter-spacing: -0.02em;
}
p { 
  font-size: 1rem; 
  font-weight: 400; 
  color: var(--text-secondary); /* lighter */
}
```

---

### Mistake 4: Loose Heading Line Height

❌ **Problem**: Large headings with body-text line height look disconnected

```css
/* Bad */
h1 { 
  font-size: 3rem; 
  line-height: 1.6; /* Too loose! */
}
```

✅ **Fix**: Tighten line height as size increases

```css
/* Good */
h1 { 
  font-size: 3rem; 
  line-height: 1.1; 
}
```

---

### Mistake 5: No Letter Spacing on Large Text

❌ **Problem**: Hero text looks too spaced out

```css
/* Bad */
.hero-title { 
  font-size: 4rem; 
  /* default letter-spacing */
}
```

✅ **Fix**: Tighten tracking on large text

```css
/* Good */
.hero-title { 
  font-size: 4rem; 
  letter-spacing: -0.03em; 
}
```

---

### Mistake 6: All Caps Without Tracking

❌ **Problem**: ALL CAPS text looks cramped

```css
/* Bad */
.label { 
  text-transform: uppercase; 
}
```

✅ **Fix**: Increase letter spacing

```css
/* Good */
.label { 
  text-transform: uppercase; 
  letter-spacing: 0.05em;
  font-size: 0.75rem;
  font-weight: 500;
}
```

---

### Mistake 7: Body Text Too Wide

❌ **Problem**: Lines of text spanning full width

✅ **Fix**: Limit line length to 65-75 characters

```css
/* Good */
.prose {
  max-width: 65ch;
}

/* Or */
article p {
  max-width: 680px;
}
```

---

### Mistake 8: Wrong Font for Context

❌ **Problem**: Using a quirky display font for body text

| Font Type | Good For | Bad For |
|-----------|----------|---------|
| Display/Decorative | Heroes, logos | Body text |
| Geometric sans | Headings, UI | Long-form reading |
| Humanist sans | Body, UI | — |
| Serif | Long-form, headings | Dense UI |
| Monospace | Code, data | Body text |

---

### Mistake 9: Ignoring Font Loading

❌ **Problem**: Flash of unstyled text (FOUT) or invisible text (FOIT)

✅ **Fix**: Use font-display and preload

```html
<!-- Preload critical font -->
<link rel="preload" href="/fonts/inter-var.woff2" as="font" type="font/woff2" crossorigin>

<style>
@font-face {
  font-family: 'Inter';
  src: url('/fonts/inter-var.woff2') format('woff2');
  font-display: swap; /* Show fallback immediately */
}
</style>
```

---

### Mistake 10: Inconsistent Text Colors

❌ **Problem**: Random grays throughout the app

✅ **Fix**: Define a text color system

```css
:root {
  --text-primary: #111827;    /* Headings, important */
  --text-secondary: #4B5563;  /* Body text */
  --text-tertiary: #9CA3AF;   /* Captions, hints */
  --text-disabled: #D1D5DB;   /* Disabled states */
  --text-inverse: #FFFFFF;    /* On dark backgrounds */
}
```

---

## Platform-Specific Guidance

### iOS (SwiftUI / UIKit)

**System Fonts**: SF Pro (text), SF Mono (code), New York (serif)

```swift
// Dynamic Type (recommended)
Text("Heading")
    .font(.title)
    
Text("Body")
    .font(.body)

// Custom fonts with Dynamic Type
Text("Custom")
    .font(.custom("Inter", size: 16, relativeTo: .body))
```

**iOS Typography Scale**:
| Style | Size | Weight |
|-------|------|--------|
| Large Title | 34pt | Bold |
| Title 1 | 28pt | Bold |
| Title 2 | 22pt | Bold |
| Title 3 | 20pt | Semibold |
| Headline | 17pt | Semibold |
| Body | 17pt | Regular |
| Callout | 16pt | Regular |
| Subhead | 15pt | Regular |
| Footnote | 13pt | Regular |
| Caption 1 | 12pt | Regular |
| Caption 2 | 11pt | Regular |

### Android (Compose / XML)

**System Fonts**: Roboto (default), Noto (internationalization)

```kotlin
// Material 3 Typography
Text(
    text = "Heading",
    style = MaterialTheme.typography.headlineMedium
)

Text(
    text = "Body",
    style = MaterialTheme.typography.bodyLarge
)
```

**Material 3 Type Scale**:
| Style | Size | Weight |
|-------|------|--------|
| Display Large | 57sp | Regular |
| Display Medium | 45sp | Regular |
| Display Small | 36sp | Regular |
| Headline Large | 32sp | Regular |
| Headline Medium | 28sp | Regular |
| Headline Small | 24sp | Regular |
| Title Large | 22sp | Regular |
| Title Medium | 16sp | Medium |
| Title Small | 14sp | Medium |
| Body Large | 16sp | Regular |
| Body Medium | 14sp | Regular |
| Body Small | 12sp | Regular |
| Label Large | 14sp | Medium |
| Label Medium | 12sp | Medium |
| Label Small | 11sp | Medium |

### React Native

```jsx
// System fonts (recommended for native feel)
const styles = StyleSheet.create({
  heading: {
    fontFamily: Platform.OS === 'ios' ? 'System' : 'Roboto',
    fontSize: 24,
    fontWeight: '600',
  },
  body: {
    fontFamily: Platform.OS === 'ios' ? 'System' : 'Roboto',
    fontSize: 16,
    fontWeight: '400',
    lineHeight: 24,
  },
});
```

---

## Quick Checklist

Before shipping, verify:

- [ ] **2-3 fonts maximum** (ideally 1-2)
- [ ] **2-3 weights maximum** (400, 500/600)
- [ ] **Type scale is consistent** (mathematical ratio)
- [ ] **Headings are tight** (line-height 1.1-1.2)
- [ ] **Body is comfortable** (line-height 1.5+)
- [ ] **Large text has negative tracking**
- [ ] **All-caps has positive tracking**
- [ ] **Line length is 65-75 characters**
- [ ] **Font loading is optimized** (preload, font-display)
- [ ] **Text colors are systematic** (primary, secondary, tertiary)
- [ ] **Mobile responsive** (fluid or breakpoint-based)
- [ ] **Accessibility** (16px minimum, sufficient contrast)
