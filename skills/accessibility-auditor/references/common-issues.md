# Common Accessibility Issues

Frequently found issues with severity, WCAG mapping, and remediation.

## Quick Reference Table

| Issue | Severity | WCAG | Effort |
|-------|----------|------|--------|
| Missing alt text | Critical/Serious | 1.1.1 | Low |
| No keyboard access | Critical | 2.1.1 | Medium |
| Missing form labels | Serious | 1.3.1, 3.3.2 | Low |
| Insufficient contrast | Serious | 1.4.3 | Low |
| No focus indicator | Serious | 2.4.7 | Low |
| Missing page language | Moderate | 3.1.1 | Low |
| Missing skip link | Moderate | 2.4.1 | Low |
| Empty links/buttons | Serious | 2.4.4, 4.1.2 | Low |
| Poor heading structure | Moderate | 1.3.1 | Medium |
| Focus trap | Critical | 2.1.2 | Medium |
| Auto-playing media | Moderate | 1.4.2 | Low |
| Missing error identification | Serious | 3.3.1 | Medium |
| Touch target too small | Moderate | 2.5.8 | Low |
| Color-only indication | Serious | 1.4.1 | Medium |

---

## Image Issues

### Missing Alt Text

**Severity**: Critical (for informative images) / Serious (for functional images)
**WCAG**: 1.1.1 Non-text Content

**Detection**:
- `<img>` without `alt` attribute
- Empty `alt=""` on informative images
- Background images conveying information

**Impact**: Screen reader users get no information about the image.

**Remediation**:

```html
<!-- Before -->
<img src="chart.png">

<!-- After: Informative image -->
<img src="chart.png" alt="Q2 revenue increased 40% over Q1">

<!-- After: Decorative image -->
<img src="decoration.png" alt="">

<!-- After: Complex image -->
<figure>
  <img src="complex-data.png" alt="Regional sales comparison">
  <figcaption>
    North region: $1.2M (35%), South: $0.9M (26%)...
  </figcaption>
</figure>
```

### Uninformative Alt Text

**Severity**: Serious
**WCAG**: 1.1.1 Non-text Content

**Detection**:
- Alt text like "image", "photo", "icon"
- Filename as alt text (IMG_2847.jpg)
- Alt text describes appearance, not purpose

**Remediation**:
- Describe the *purpose* or *content*, not the format
- For functional images, describe the *action*
- For data visualizations, describe the *insight*

```html
<!-- Before -->
<img src="graph.png" alt="line graph">

<!-- After -->
<img src="graph.png" alt="User signups grew 300% from January to March">
```

---

## Form Issues

### Missing Form Labels

**Severity**: Serious
**WCAG**: 1.3.1 Info and Relationships, 3.3.2 Labels or Instructions

**Detection**:
- `<input>` without associated `<label>`
- Placeholder text used as only label
- Label not programmatically associated

**Impact**: Screen reader users don't know what to enter.

**Remediation**:

```html
<!-- Before: Placeholder only -->
<input type="email" placeholder="Email address">

<!-- Before: Visual label, no association -->
<label>Email</label>
<input type="email">

<!-- After: Properly associated -->
<label for="email">Email address</label>
<input type="email" id="email">

<!-- After: Wrapping label -->
<label>
  Email address
  <input type="email">
</label>

<!-- After: aria-label when visual label impossible -->
<input type="search" aria-label="Search products">
```

### Error Messages Not Associated

**Severity**: Serious
**WCAG**: 3.3.1 Error Identification

**Detection**:
- Error messages not linked to input via `aria-describedby`
- Error announced via color/position only
- Dynamic errors not announced to screen readers

**Remediation**:

```html
<!-- Before -->
<input type="email" class="error">
<span class="error-text">Invalid email format</span>

<!-- After -->
<input 
  type="email" 
  aria-invalid="true"
  aria-describedby="email-error"
>
<span id="email-error" role="alert">
  Invalid email format. Please include @ symbol.
</span>
```

### Missing Autocomplete

**Severity**: Moderate
**WCAG**: 1.3.5 Identify Input Purpose

**Detection**:
- Personal data fields without autocomplete attribute
- Common fields: name, email, tel, address, cc-number

**Remediation**:

```html
<input type="text" autocomplete="name">
<input type="email" autocomplete="email">
<input type="tel" autocomplete="tel">
<input type="text" autocomplete="street-address">
<input type="text" autocomplete="cc-number">
```

---

## Keyboard Issues

### No Keyboard Access

**Severity**: Critical
**WCAG**: 2.1.1 Keyboard

**Detection**:
- Interactive elements not reachable via Tab
- Custom controls without keyboard handlers
- Click events without keyboard equivalents

**Impact**: Keyboard users cannot use the functionality.

**Remediation**:

```html
<!-- Before: Click only -->
<div class="button" onclick="submit()">Submit</div>

<!-- After: Use button element -->
<button onclick="submit()">Submit</button>

<!-- After: If div required -->
<div 
  role="button"
  tabindex="0"
  onclick="submit()"
  onkeydown="if(event.key === 'Enter' || event.key === ' ') submit()"
>
  Submit
</div>
```

### Focus Trap

**Severity**: Critical
**WCAG**: 2.1.2 No Keyboard Trap

**Detection**:
- Cannot Tab out of a component
- Modal doesn't allow exit
- Embedded content traps focus

**Impact**: Keyboard users stuck, must refresh page.

**Remediation**:
- Ensure Escape closes modals
- Focus trap should be intentional (modals) and escapable
- Check third-party widgets and iframes

### Missing Focus Indicator

**Severity**: Serious
**WCAG**: 2.4.7 Focus Visible

**Detection**:
- `outline: none` without replacement
- Focus indicator same color as background
- Focus indicator too subtle

**Impact**: Keyboard users don't know where they are.

**Remediation**:

```css
/* Before: Removed focus */
*:focus {
  outline: none;
}

/* After: Custom focus indicator */
*:focus {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}

/* Or use :focus-visible for keyboard only */
*:focus-visible {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}
```

### Poor Focus Order

**Severity**: Moderate
**WCAG**: 2.4.3 Focus Order

**Detection**:
- Tab order doesn't match visual order
- Focus jumps unexpectedly
- Off-screen elements receive focus
- `tabindex` values > 0

**Remediation**:
- Remove positive tabindex values
- Ensure DOM order matches visual order
- Hide off-screen content from focus (`tabindex="-1"` or `display: none`)

---

## Color & Contrast Issues

### Insufficient Color Contrast

**Severity**: Serious
**WCAG**: 1.4.3 Contrast (Minimum)

**Detection**:
- Text contrast < 4.5:1 (normal text)
- Text contrast < 3:1 (large text: 18pt+ or 14pt bold+)
- UI component contrast < 3:1 (1.4.11)

**Impact**: Users with low vision cannot read content.

**Tools**:
- WebAIM Contrast Checker
- Chrome DevTools (inspect → color picker shows ratio)
- axe DevTools

**Remediation**:
- Darken light text or lighten dark backgrounds
- Common failures: light gray (#999) on white, light placeholder text

```css
/* Before: 2.85:1 ratio */
.light-text { color: #999; }

/* After: 4.5:1+ ratio */
.light-text { color: #595959; }
```

### Color as Only Indicator

**Severity**: Serious
**WCAG**: 1.4.1 Use of Color

**Detection**:
- Links distinguished only by color
- Required fields indicated only by color
- Errors shown only in red
- Chart data distinguished only by color

**Impact**: Color blind users miss the information.

**Remediation**:

```html
<!-- Before: Color-only error -->
<input type="email" style="border-color: red">

<!-- After: Color + icon + text -->
<input type="email" aria-invalid="true" aria-describedby="err">
<span id="err">
  ⚠️ Invalid email format
</span>

<!-- Before: Links by color only -->
<p>Visit our <a href="/about">about page</a> for more.</p>

<!-- After: Underlined (default, don't override) -->
<p>Visit our <a href="/about">about page</a> for more.</p>
/* Keep underline or add other visual indicator */
```

---

## Structure Issues

### Missing or Poor Heading Structure

**Severity**: Moderate
**WCAG**: 1.3.1 Info and Relationships

**Detection**:
- Page without `<h1>`
- Skipped heading levels (h1 → h3)
- Styled divs instead of headings
- Multiple h1 elements

**Impact**: Screen reader users can't navigate by headings.

**Remediation**:

```html
<!-- Before: Skipped level -->
<h1>Page Title</h1>
<h3>First Section</h3>  <!-- Should be h2 -->

<!-- After: Proper hierarchy -->
<h1>Page Title</h1>
<h2>First Section</h2>
<h3>Subsection</h3>
<h2>Second Section</h2>

<!-- Before: Styled div -->
<div class="section-heading">Features</div>

<!-- After: Semantic heading -->
<h2 class="section-heading">Features</h2>
```

### Missing Skip Link

**Severity**: Moderate
**WCAG**: 2.4.1 Bypass Blocks

**Detection**:
- No skip link at page start
- Skip link hidden but not functional
- Skip link target doesn't exist

**Impact**: Keyboard users must tab through navigation on every page.

**Remediation**:

```html
<!-- Skip link (first focusable element) -->
<a href="#main-content" class="skip-link">
  Skip to main content
</a>

<nav><!-- Navigation --></nav>

<main id="main-content" tabindex="-1">
  <!-- Main content -->
</main>

<style>
.skip-link {
  position: absolute;
  left: -9999px;
}
.skip-link:focus {
  left: 10px;
  top: 10px;
  /* Make visible on focus */
}
</style>
```

### Missing Page Language

**Severity**: Moderate
**WCAG**: 3.1.1 Language of Page

**Detection**:
- No `lang` attribute on `<html>`
- Incorrect language code

**Impact**: Screen readers use wrong pronunciation.

**Remediation**:

```html
<html lang="en">
<!-- or -->
<html lang="es">
<html lang="fr">
```

---

## Interactive Element Issues

### Empty Links or Buttons

**Severity**: Serious
**WCAG**: 2.4.4 Link Purpose, 4.1.2 Name Role Value

**Detection**:
- Links/buttons with no text content
- Icon-only without accessible name
- Images as links without alt

**Impact**: Screen reader announces "link" or "button" with no context.

**Remediation**:

```html
<!-- Before: Empty link -->
<a href="/search"><svg class="icon-search"></svg></a>

<!-- After: aria-label -->
<a href="/search" aria-label="Search">
  <svg class="icon-search" aria-hidden="true"></svg>
</a>

<!-- Before: Image link without alt -->
<a href="/home"><img src="logo.png"></a>

<!-- After -->
<a href="/home">
  <img src="logo.png" alt="Home">
</a>
```

### Vague Link Text

**Severity**: Moderate
**WCAG**: 2.4.4 Link Purpose

**Detection**:
- "Click here", "Read more", "Learn more" without context
- Links not descriptive out of context

**Impact**: Screen reader users navigating by links don't understand purpose.

**Remediation**:

```html
<!-- Before -->
<p>Read our report. <a href="/report">Click here</a></p>

<!-- After: Descriptive link -->
<p><a href="/report">Read our Q2 financial report</a></p>

<!-- Or: aria-label for context -->
<p>
  Read our Q2 report. 
  <a href="/report" aria-label="Read Q2 financial report">Learn more</a>
</p>
```

---

## Mobile-Specific Issues

### Touch Target Too Small

**Severity**: Moderate
**WCAG**: 2.5.8 Target Size (24px), Platform guidelines (44pt/48dp)

**Detection**:
- Interactive elements < 24×24 CSS pixels
- Insufficient spacing between targets

**Impact**: Users with motor impairments can't accurately tap.

**Remediation**:

```css
/* Ensure minimum touch target */
button, a, input, select {
  min-width: 44px;
  min-height: 44px;
}

/* Or use padding to achieve target size */
.icon-button {
  padding: 12px; /* 20px icon + 24px padding = 44px */
}
```

```jsx
// React Native
<TouchableOpacity
  style={{ minWidth: 44, minHeight: 44 }}
  hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
>
```

### No Alternative to Drag

**Severity**: Moderate
**WCAG**: 2.5.7 Dragging Movements

**Detection**:
- Drag-and-drop with no alternative
- Sliders without buttons
- Reorderable lists with drag only

**Impact**: Users who can't drag cannot use functionality.

**Remediation**:
- Add up/down buttons for reordering
- Add +/- buttons for sliders
- Provide click-based alternative to drag

---

## Dynamic Content Issues

### Status Messages Not Announced

**Severity**: Moderate
**WCAG**: 4.1.3 Status Messages

**Detection**:
- Success/error messages not in live region
- Loading states not announced
- Search results count not announced

**Impact**: Screen reader users don't know content changed.

**Remediation**:

```html
<!-- Success message -->
<div role="status" aria-live="polite">
  Your changes have been saved.
</div>

<!-- Error message -->
<div role="alert" aria-live="assertive">
  Error: Unable to save changes.
</div>

<!-- Loading -->
<div aria-live="polite" aria-busy="true">
  Loading results...
</div>

<!-- Search results -->
<div role="status" aria-live="polite">
  Showing 24 results for "accessibility"
</div>
```

### Auto-Playing Media

**Severity**: Moderate
**WCAG**: 1.4.2 Audio Control

**Detection**:
- Video/audio plays automatically
- No pause/stop control
- Plays longer than 3 seconds

**Impact**: Interferes with screen reader, distracting.

**Remediation**:
- Don't autoplay audio
- If autoplay necessary, provide visible pause/stop
- Limit to <3 seconds, or mute by default
