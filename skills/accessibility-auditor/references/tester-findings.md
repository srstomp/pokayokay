# Interpreting Tester Findings

How to process and standardize manual accessibility testing results.

## Tester Report Formats

Manual testers provide findings in various formats. Normalize to audit report structure.

### Common Input Formats

| Format | Characteristics | Processing Needed |
|--------|-----------------|-------------------|
| Spreadsheet | Columns vary, may lack WCAG mapping | Map to WCAG, classify severity |
| Bug tickets | Developer-focused, may lack context | Add user impact, standardize format |
| Screen reader transcript | Raw observations | Interpret, group, prioritize |
| Video recording | Shows issue, no analysis | Document, screenshot, analyze |
| Narrative report | Prose description | Extract discrete issues |

### Normalization Process

1. **Extract discrete issues** (one issue per finding)
2. **Add WCAG criterion** if missing
3. **Classify severity** using standard scale
4. **Document location** (URL, screen, component)
5. **Describe impact** on users
6. **Note reproduction steps** if provided
7. **Add remediation guidance**

---

## Mapping Tester Language to WCAG

Testers may describe issues without WCAG references. Common translations:

### Perception Issues

| Tester Says | Likely WCAG Criterion |
|-------------|----------------------|
| "Screen reader didn't announce the image" | 1.1.1 Non-text Content |
| "Couldn't tell what the image was" | 1.1.1 Non-text Content |
| "Video had no captions" | 1.2.2 Captions |
| "Couldn't tell this was a heading" | 1.3.1 Info and Relationships |
| "The order was confusing" | 1.3.2 Meaningful Sequence |
| "Only knew it was an error because of the color" | 1.4.1 Use of Color |
| "Text was hard to read" | 1.4.3 Contrast |
| "Text got cut off when I zoomed" | 1.4.4 Resize Text / 1.4.10 Reflow |
| "The tooltip disappeared too fast" | 1.4.13 Content on Hover |

### Operation Issues

| Tester Says | Likely WCAG Criterion |
|-------------|----------------------|
| "Couldn't reach with keyboard" | 2.1.1 Keyboard |
| "Got stuck, couldn't Tab out" | 2.1.2 No Keyboard Trap |
| "Timed out before I could finish" | 2.2.1 Timing Adjustable |
| "The carousel kept moving" | 2.2.2 Pause, Stop, Hide |
| "No way to skip the navigation" | 2.4.1 Bypass Blocks |
| "Couldn't tell where focus was" | 2.4.7 Focus Visible |
| "Focus went behind the sticky header" | 2.4.11 Focus Not Obscured |
| "Button was too small to tap" | 2.5.8 Target Size |
| "Could only reorder by dragging" | 2.5.7 Dragging Movements |

### Understanding Issues

| Tester Says | Likely WCAG Criterion |
|-------------|----------------------|
| "Screen reader pronounced it wrong" | 3.1.1 Language of Page |
| "Selecting the dropdown submitted the form" | 3.2.2 On Input |
| "Navigation was in different order on other pages" | 3.2.3 Consistent Navigation |
| "Couldn't tell what the error was" | 3.3.1 Error Identification |
| "Didn't know the field was required" | 3.3.2 Labels or Instructions |
| "Had to enter my email twice" | 3.3.7 Redundant Entry |
| "Couldn't paste into the password field" | 3.3.8 Accessible Authentication |

### Technical Issues

| Tester Says | Likely WCAG Criterion |
|-------------|----------------------|
| "Screen reader said 'clickable' but not what it does" | 4.1.2 Name, Role, Value |
| "Custom dropdown didn't work with screen reader" | 4.1.2 Name, Role, Value |
| "Didn't announce when results loaded" | 4.1.3 Status Messages |
| "Couldn't tell the checkbox was checked" | 4.1.2 Name, Role, Value |

---

## Severity Classification from Descriptions

### Critical Indicators

Tester language suggesting **Critical** severity:

- "Couldn't complete the task"
- "Couldn't access at all"
- "Page was completely unusable"
- "Blocked from proceeding"
- "No way to..."
- "Impossible to..."

### Serious Indicators

Tester language suggesting **Serious** severity:

- "Very difficult to..."
- "Took a long time to figure out"
- "Had to use a workaround"
- "Almost gave up"
- "Confusing but eventually..."
- "Missed important information"

### Moderate Indicators

Tester language suggesting **Moderate** severity:

- "Confusing at first"
- "Unexpected behavior"
- "Minor annoyance"
- "Would be better if..."
- "Not ideal but workable"

### Minor Indicators

Tester language suggesting **Minor** severity:

- "Slight inconvenience"
- "Redundant announcement"
- "Could be clearer"
- "Minor issue"
- "Polish item"

---

## Processing Screen Reader Testing

### Common Screen Reader Findings

| Finding | Interpretation |
|---------|----------------|
| "Announced 'image'" | Missing alt text or generic alt (1.1.1) |
| "Announced 'button' with no label" | Empty button (4.1.2) |
| "Announced 'link link link'" | Likely nested links or empty links (4.1.2) |
| "Announced 'clickable'" | Non-semantic element with click handler (4.1.2) |
| "Announced wrong role" | Incorrect ARIA or missing semantic element (4.1.2) |
| "Didn't announce state change" | Missing live region (4.1.3) |
| "Read in wrong order" | DOM order doesn't match visual (1.3.2) |
| "Skipped content" | Content may be hidden from AT (various) |
| "Announced hidden content" | Improper hiding method (various) |

### Screen Reader Issues → Code Problems

| Screen Reader Behavior | Likely Code Issue |
|------------------------|-------------------|
| Image says "graphic" or filename | `alt` missing or equals filename |
| Button says only "button" | No text content, no aria-label |
| Says "clickable" | `<div onclick>` without role="button" |
| Doesn't announce expanded/collapsed | Missing aria-expanded |
| Can't interact with custom widget | Missing ARIA roles and keyboard handling |
| Announces "blank" | Empty element receiving focus |
| Repeated announcements | Duplicate aria-label and visible text |

---

## Processing Keyboard Testing

### Common Keyboard Findings

| Finding | Likely Issue |
|---------|--------------|
| "Couldn't Tab to X" | Not focusable, missing tabindex or not interactive element |
| "Tab order jumped around" | Visual order doesn't match DOM, or tabindex > 0 used |
| "Focus disappeared" | Focus moved to hidden element, or outline removed |
| "Got stuck in X" | Keyboard trap, usually in modal, iframe, or custom widget |
| "Enter didn't activate" | Missing keyboard handler or wrong element |
| "Space scrolled page instead" | Button using `<a>` or custom element |
| "Couldn't close modal with Escape" | No Escape key handler |
| "Focus didn't move to modal" | Focus management not implemented |
| "Focus stayed in modal after close" | Focus not returned to trigger |

### Keyboard Issues → Code Problems

| Keyboard Behavior | Likely Code Issue |
|-------------------|-------------------|
| Can't reach element | Not a focusable element (div/span without tabindex) |
| Focus disappears | `visibility: hidden` or `display: none` element focused |
| Can't activate | `onclick` without `onkeydown` / `onkeyup` |
| Can't exit modal | No Escape handler, focus not trapped properly |
| Space doesn't activate | Using anchor instead of button |
| Arrow keys don't work | Custom widget missing arrow key navigation |

---

## Processing Mobile Testing

### iOS VoiceOver Findings

| Finding | Interpretation |
|---------|----------------|
| "Swiped over but nothing announced" | Missing accessibilityLabel |
| "Said 'button' but didn't describe it" | Empty label on button |
| "Couldn't activate" | Not accessible element or gesture issue |
| "Read elements in wrong order" | View hierarchy doesn't match visual |
| "Didn't announce selected/checked" | Missing accessibilityTraits or state |
| "Double-tap didn't work" | Accessibility action not implemented |
| "Announced 'dimmed'" | Disabled but maybe shouldn't be |

### Android TalkBack Findings

| Finding | Interpretation |
|---------|----------------|
| "Announced 'unlabeled'" | Missing contentDescription |
| "Couldn't focus on X" | Not importantForAccessibility |
| "Explore by touch missed element" | Element too small or overlapped |
| "Announced wrong type" | Incorrect className or missing role |
| "Action menu was empty" | Custom actions not implemented |

---

## Handling Ambiguous Findings

### When Finding Is Unclear

1. **Check for reproduction steps**: Can you reproduce the issue?
2. **Request clarification**: Ask tester for specifics
3. **Note assumptions**: Document your interpretation
4. **Flag uncertainty**: Mark confidence level in report

### Clarification Questions to Ask

- "What were you trying to do when this happened?"
- "What screen/page were you on?"
- "What assistive technology were you using?"
- "What did you expect to happen?"
- "Can you provide a screenshot or recording?"
- "Does this happen every time?"
- "Did any workaround help?"

### Documenting Uncertainty

```markdown
### [Issue ID]: Navigation not announced

**WCAG Criterion**: 1.3.1 (tentative) or 4.1.2
**Severity**: Serious (estimated)
**Location**: Main navigation (needs confirmation)
**Description**: Tester reported "navigation wasn't working" with VoiceOver.
**Confidence**: Low — needs reproduction

**Clarification Needed**:
- [ ] Which navigation (header, footer, mobile)?
- [ ] "Wasn't working" = not announced, or not focusable?
- [ ] iOS version and VoiceOver settings?

**Preliminary Assessment**: Likely missing nav landmark or ARIA label.
```

---

## Consolidating Multiple Tester Reports

### Deduplication Process

1. **Group by location**: Same screen/component
2. **Group by symptom**: Same observed behavior
3. **Identify root cause**: Multiple symptoms, one cause
4. **Merge findings**: One issue per root cause
5. **Note frequency**: How many testers found it

### Example Consolidation

**Tester 1**: "Modal didn't close when I pressed Escape"
**Tester 2**: "Got stuck in the popup, couldn't Tab out"
**Tester 3**: "Focus went behind the modal to the page"

**Consolidated Issue**:
```markdown
### MODAL-001: Modal keyboard trap and focus management

**WCAG Criteria**: 2.1.2 No Keyboard Trap, 2.4.3 Focus Order
**Severity**: Critical
**Frequency**: 3/3 testers reported

**Findings**:
- Escape key doesn't close modal
- Cannot Tab out of modal (trap)
- Focus not constrained to modal

**Root Cause**: Modal lacks proper focus trap and keyboard handling

**Remediation**:
1. Add Escape key handler to close modal
2. Implement focus trap (first/last element cycling)
3. Move focus to modal on open
4. Return focus to trigger on close
```

---

## Tester Finding Intake Template

Use this template when receiving tester reports:

```markdown
## Tester Finding Intake

**Source**: [Tester name / report date]
**Testing Method**: [VoiceOver/TalkBack/Keyboard/JAWS/NVDA]
**Platform**: [iOS/Android/Web/Desktop]

### Original Finding
> [Copy tester's description verbatim]

### Normalized Issue

**Issue ID**: [Assign ID]
**Title**: [Brief descriptive title]
**WCAG Criterion**: [X.X.X Name]
**Severity**: [Critical/Serious/Moderate/Minor]
**Location**: [URL/Screen/Component]

**Description**: [Standardized description]

**User Impact**: [Who is affected and how]

**Reproduction Steps**:
1. [Step]
2. [Step]
3. [Observe issue]

**Expected Behavior**: [What should happen]

**Actual Behavior**: [What currently happens]

**Remediation**: [How to fix]

**Notes**: [Any clarifications, assumptions, uncertainties]
```
