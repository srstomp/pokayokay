# Accessibility Essentials

Quick reference for building accessible interfaces. For comprehensive WCAG 2.2 AA audits, use the `accessibility-auditor` skill.

## Quick Checklist

### Perceivable
- [ ] Images have meaningful `alt` text (empty `alt=""` for decorative)
- [ ] Video has captions, audio has transcripts
- [ ] Text contrast ≥4.5:1 (≥3:1 for large text)
- [ ] Information not conveyed by color alone

### Operable
- [ ] All interactive elements keyboard accessible
- [ ] Visible focus indicators on all focusable elements
- [ ] Tab order follows logical reading order
- [ ] No keyboard traps
- [ ] Touch targets ≥44×44px

### Understandable
- [ ] All form inputs have visible labels
- [ ] Error messages identify field and explain fix
- [ ] Navigation consistent across pages
- [ ] No unexpected context changes

### Robust
- [ ] Valid semantic HTML
- [ ] ARIA only when native HTML insufficient
- [ ] Works with screen readers

---

## Essential Patterns

### Images

```html
<!-- Informative image -->
<img src="chart.png" alt="Sales increased 40% in Q3">

<!-- Decorative image -->
<img src="border.png" alt="" role="presentation">

<!-- Icon button (no visible text) -->
<button aria-label="Close dialog">
  <svg aria-hidden="true">...</svg>
</button>

<!-- Icon with visible label (icon decorative) -->
<button>
  <svg aria-hidden="true">...</svg>
  Save
</button>
```

### Form Fields

```html
<!-- Basic labeled input -->
<label for="email">Email address</label>
<input type="email" id="email">

<!-- With error state -->
<label for="password">Password</label>
<input 
  type="password" 
  id="password" 
  aria-invalid="true"
  aria-describedby="password-error"
>
<p id="password-error">Must be at least 8 characters</p>

<!-- With helper text -->
<input 
  type="text" 
  aria-describedby="username-hint"
>
<p id="username-hint">Letters and numbers only</p>
```

### Focus Management

```css
/* Never remove focus without replacement */
:focus { outline: none; } /* ❌ */

/* Custom focus style */
:focus-visible {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}
```

```html
<!-- Tab order follows visual order -->
<!-- Use tabindex="0" to add to tab order -->
<!-- Use tabindex="-1" for programmatic focus only -->
<!-- Never use tabindex > 0 -->
```

### Live Regions (Dynamic Updates)

```html
<!-- Polite: Announced when convenient -->
<div aria-live="polite">3 items in cart</div>

<!-- Assertive: Announced immediately (errors) -->
<div aria-live="assertive" role="alert">
  Payment failed. Please try again.
</div>

<!-- Status messages -->
<div role="status">Saving...</div>
```

### Modal Accessibility

```html
<div 
  role="dialog" 
  aria-modal="true"
  aria-labelledby="modal-title"
>
  <h2 id="modal-title">Confirm deletion</h2>
  <!-- Focus trapped inside modal -->
  <!-- Escape key closes -->
  <!-- Return focus to trigger on close -->
</div>
```

---

## Color Contrast

| Element | Minimum Ratio |
|---------|---------------|
| Normal text | 4.5:1 |
| Large text (≥18px or ≥14px bold) | 3:1 |
| UI components, icons | 3:1 |

**Tools:** WebAIM Contrast Checker, Stark (Figma), Chrome DevTools

---

## Keyboard Patterns

| Element | Keys |
|---------|------|
| Links, buttons | Enter activates |
| Checkboxes | Space toggles |
| Radio buttons | Arrows navigate, Space selects |
| Tabs | Arrows navigate between tabs |
| Menus | Arrows navigate, Enter selects, Escape closes |
| Modals | Tab trapped inside, Escape closes |

---

## Testing

### Automated (catches ~30%)
- axe DevTools (browser extension)
- WAVE (browser extension)
- Lighthouse (Chrome DevTools)

### Manual (required)
1. **Keyboard:** Tab through entire page
2. **Screen reader:** VoiceOver (Mac), NVDA (Windows)
3. **Zoom:** Test at 200%
4. **Color:** Check with colorblind simulator

### Quick Keyboard Test
- [ ] Can reach all interactive elements with Tab
- [ ] Focus always visible
- [ ] Can activate everything with Enter/Space
- [ ] Can escape any component
- [ ] Order makes sense

---

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| No `alt` on images | Add descriptive or empty alt |
| Placeholder as only label | Add visible `<label>` |
| `outline: none` without replacement | Custom `:focus-visible` style |
| Color-only error indication | Add icon + text |
| Mouse-only interactions | Add keyboard handlers |
| Low contrast text | Use 4.5:1 minimum |
| Skipped heading levels | Use h1 → h2 → h3 in order |
| Clickable `<div>` | Use `<button>` or `<a>` |

---

## Screen Reader Only (Visually Hidden)

```css
.sr-only {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0, 0, 0, 0);
  white-space: nowrap;
  border: 0;
}
```

Use for: Additional context for screen readers that's redundant visually.

---

## Resources

- [WebAIM](https://webaim.org) — Practical accessibility guides
- [A11y Project](https://a11yproject.com) — Checklist and patterns
- [MDN Accessibility](https://developer.mozilla.org/en-US/docs/Web/Accessibility)
- [WCAG Quick Reference](https://www.w3.org/WAI/WCAG21/quickref/)

**For comprehensive audits:** Use the `accessibility-auditor` skill for full WCAG 2.2 AA compliance reviews.
