# WCAG 2.2 AA Criteria Reference

Complete WCAG 2.2 Level A and AA success criteria for auditing. Organized by principle.

## How to Use This Reference

When auditing:
1. Find the relevant criterion by principle/guideline
2. Check "What to Test" for audit approach
3. Use "Common Failures" to identify issues
4. Reference criterion number in audit report (e.g., "1.1.1 Non-text Content")

---

# 1. Perceivable

Information and UI components must be presentable in ways users can perceive.

## 1.1 Text Alternatives

### 1.1.1 Non-text Content (A)

**Requirement**: All non-text content has a text alternative.

**What to Test:**
- Images have alt text (or empty alt for decorative)
- Icons have accessible names
- Charts/graphs have text descriptions
- CAPTCHA has alternatives
- Audio/video has text alternatives

**Common Failures:**
- Missing alt attribute
- Alt text says "image" or filename
- Decorative images have descriptive alt
- Icon buttons missing accessible name
- Complex images without long description

**Code Check (HTML):**
```html
<!-- FAIL: missing alt -->
<img src="hero.jpg">

<!-- FAIL: meaningless alt -->
<img src="chart.png" alt="image">

<!-- PASS: meaningful alt -->
<img src="chart.png" alt="Sales increased 40% from Q1 to Q2">

<!-- PASS: decorative -->
<img src="decoration.png" alt="">
```

---

## 1.2 Time-based Media

### 1.2.1 Audio-only and Video-only (A)

**Requirement**: Prerecorded audio-only has transcript. Prerecorded video-only has transcript or audio description.

**What to Test:**
- Audio content has text transcript
- Video without audio has transcript or audio track

### 1.2.2 Captions (Prerecorded) (A)

**Requirement**: Prerecorded video with audio has captions.

**What to Test:**
- Videos have synchronized captions
- Captions include speaker identification
- Captions include relevant sound effects

### 1.2.3 Audio Description or Media Alternative (A)

**Requirement**: Video has audio description or full text alternative.

**What to Test:**
- Visual information is described in audio
- Or full transcript is available

### 1.2.4 Captions (Live) (AA)

**Requirement**: Live video with audio has real-time captions.

**What to Test:**
- Live streams have captions
- Webinars, live events captioned

### 1.2.5 Audio Description (Prerecorded) (AA)

**Requirement**: Video has audio description.

**What to Test:**
- Audio description track available
- Key visual information is narrated

---

## 1.3 Adaptable

### 1.3.1 Info and Relationships (A)

**Requirement**: Structure and relationships conveyed visually are programmatically determinable.

**What to Test:**
- Headings use proper heading elements
- Lists use list markup
- Tables have proper headers
- Form fields have labels
- Regions are marked up (nav, main, etc.)

**Common Failures:**
- Visual headings without heading tags
- Fake tables (divs styled as tables)
- Labels only visually associated

**Code Check:**
```html
<!-- FAIL: visual-only heading -->
<div class="heading">Section Title</div>

<!-- PASS: semantic heading -->
<h2>Section Title</h2>

<!-- FAIL: missing label association -->
<label>Email</label>
<input type="email">

<!-- PASS: associated label -->
<label for="email">Email</label>
<input type="email" id="email">
```

### 1.3.2 Meaningful Sequence (A)

**Requirement**: Content sequence is programmatically determinable.

**What to Test:**
- Reading order matches visual order
- CSS doesn't create confusing order
- Flexbox/grid order doesn't break reading order

### 1.3.3 Sensory Characteristics (A)

**Requirement**: Instructions don't rely solely on sensory characteristics.

**What to Test:**
- Instructions don't reference only shape, size, location, color
- "Click the red button" → also has text label

**Common Failures:**
- "Click the button on the right"
- "Fields marked in red are required"
- Relying only on icons without text

### 1.3.4 Orientation (AA)

**Requirement**: Content doesn't restrict orientation unless essential.

**What to Test:**
- App works in portrait and landscape
- No forced orientation without essential reason

### 1.3.5 Identify Input Purpose (AA)

**Requirement**: Input purpose is programmatically determinable.

**What to Test:**
- Form inputs have autocomplete attributes
- Personal data fields properly identified

**Code Check:**
```html
<!-- PASS: autocomplete specified -->
<input type="email" autocomplete="email">
<input type="text" autocomplete="name">
<input type="tel" autocomplete="tel">
```

---

## 1.4 Distinguishable

### 1.4.1 Use of Color (A)

**Requirement**: Color is not the only visual means of conveying information.

**What to Test:**
- Links distinguishable without color (underline, etc.)
- Form errors not indicated by color alone
- Charts don't rely on color alone

**Common Failures:**
- Red text only for errors
- Links distinguished only by color
- Required fields marked only with color

### 1.4.2 Audio Control (A)

**Requirement**: Audio playing >3 seconds can be paused/stopped.

**What to Test:**
- Auto-playing audio has controls
- Or stops within 3 seconds

### 1.4.3 Contrast (Minimum) (AA)

**Requirement**: 4.5:1 for normal text, 3:1 for large text.

**What to Test:**
- Body text ≥ 4.5:1 contrast
- Large text (18pt+ or 14pt bold+) ≥ 3:1
- Check all color combinations

**Large Text Definition:**
- 18pt (24px) regular weight
- 14pt (18.5px) bold weight

**Common Failures:**
- Light gray text on white
- Placeholder text too light
- Disabled states (exempt but verify)

### 1.4.4 Resize Text (AA)

**Requirement**: Text can be resized up to 200% without loss of content or function.

**What to Test:**
- Zoom to 200% in browser
- Text doesn't overflow containers
- No horizontal scrolling on single column
- All content still accessible

### 1.4.5 Images of Text (AA)

**Requirement**: Text is used instead of images of text (with exceptions).

**What to Test:**
- Logos (exception) are the only images of text
- Text isn't embedded in images
- User can customize text presentation

### 1.4.10 Reflow (AA)

**Requirement**: Content reflows at 400% zoom without horizontal scrolling.

**What to Test:**
- At 320px viewport width (or 400% zoom)
- No horizontal scrolling required
- Content remains usable
- Exception: data tables, maps, diagrams

### 1.4.11 Non-text Contrast (AA)

**Requirement**: UI components and graphics have 3:1 contrast.

**What to Test:**
- Buttons, inputs, icons have 3:1 against background
- Focus indicators have 3:1
- Meaningful graphics have 3:1

**Common Failures:**
- Light gray icons
- Form field borders too light
- Focus rings not visible enough

### 1.4.12 Text Spacing (AA)

**Requirement**: No loss of content when user adjusts text spacing.

**What to Test (apply these overrides):**
- Line height: 1.5x font size
- Paragraph spacing: 2x font size
- Letter spacing: 0.12x font size
- Word spacing: 0.16x font size

Content shouldn't be clipped or overlap.

### 1.4.13 Content on Hover or Focus (AA)

**Requirement**: Hoverable/focusable content is dismissible, hoverable, and persistent.

**What to Test:**
- Tooltips/popovers dismissible without moving focus
- User can hover over the tooltip content
- Content stays visible until dismissed

**Common Failures:**
- Tooltips disappear too quickly
- Can't mouse into tooltip to read it
- No way to dismiss without moving focus

---

# 2. Operable

UI components and navigation must be operable.

## 2.1 Keyboard Accessible

### 2.1.1 Keyboard (A)

**Requirement**: All functionality available via keyboard.

**What to Test:**
- Tab through entire page
- All interactive elements reachable
- All functionality triggerable (Enter, Space)
- No keyboard traps

**Common Failures:**
- Custom controls not keyboard accessible
- onClick without onKeyDown
- Drag-and-drop without alternative
- Mouse-only interactions

### 2.1.2 No Keyboard Trap (A)

**Requirement**: Keyboard focus can be moved away from any component.

**What to Test:**
- Can Tab in and out of all components
- Modals can be closed via keyboard
- Embedded content (iframes) doesn't trap

### 2.1.4 Character Key Shortcuts (A)

**Requirement**: Single character shortcuts can be turned off or remapped.

**What to Test:**
- Single key shortcuts (letters, numbers, punctuation)
- Must be disableable or remappable
- Or only active when component focused

---

## 2.2 Enough Time

### 2.2.1 Timing Adjustable (A)

**Requirement**: Time limits can be turned off, adjusted, or extended.

**What to Test:**
- Session timeouts can be extended
- User warned before timeout
- At least 20 seconds to extend

**Exceptions**: Real-time events, essential time limits

### 2.2.2 Pause, Stop, Hide (A)

**Requirement**: Moving, blinking, scrolling content can be controlled.

**What to Test:**
- Carousels have pause control
- Animations can be stopped
- Auto-updating content can be paused

---

## 2.3 Seizures and Physical Reactions

### 2.3.1 Three Flashes or Below Threshold (A)

**Requirement**: Nothing flashes more than 3 times per second.

**What to Test:**
- No rapidly flashing content
- Videos checked for flash sequences

---

## 2.4 Navigable

### 2.4.1 Bypass Blocks (A)

**Requirement**: Mechanism to skip repeated blocks.

**What to Test:**
- Skip to main content link
- ARIA landmarks present
- Proper heading structure

### 2.4.2 Page Titled (A)

**Requirement**: Pages have descriptive titles.

**What to Test:**
- `<title>` is descriptive
- Titles are unique per page
- Includes site name and page purpose

### 2.4.3 Focus Order (A)

**Requirement**: Focus order preserves meaning and operability.

**What to Test:**
- Tab order matches visual order
- Focus doesn't jump unexpectedly
- Modal focus is trapped appropriately

**Common Failures:**
- tabindex > 0 creating wrong order
- CSS changing visual order
- Off-screen elements receiving focus

### 2.4.4 Link Purpose (In Context) (A)

**Requirement**: Link purpose determinable from text or context.

**What to Test:**
- Link text is descriptive
- Or context provides meaning
- Avoid "click here", "read more" alone

**Common Failures:**
- "Click here" with no context
- "Read more" repeated without distinction
- Icon links without accessible name

### 2.4.5 Multiple Ways (AA)

**Requirement**: More than one way to locate pages.

**What to Test:**
- Site has navigation AND one of: search, sitemap, table of contents, links

### 2.4.6 Headings and Labels (AA)

**Requirement**: Headings and labels are descriptive.

**What to Test:**
- Headings describe content below
- Form labels describe expected input
- Not vague ("Miscellaneous", "Other")

### 2.4.7 Focus Visible (AA)

**Requirement**: Keyboard focus indicator is visible.

**What to Test:**
- Every focusable element shows focus
- Focus indicator is visible (not subtle)
- Custom focus styles meet contrast

**Common Failures:**
- `outline: none` without replacement
- Focus ring same color as background
- Focus indicator too subtle

### 2.4.11 Focus Not Obscured (Minimum) (AA) — *New in 2.2*

**Requirement**: Focused element is not entirely hidden.

**What to Test:**
- Sticky headers don't cover focused elements
- Modals don't hide focused content
- Scroll position reveals focused item

### 2.4.12 Focus Not Obscured (Enhanced) (AAA)

*Beyond AA scope — note if found but not required.*

### 2.4.13 Focus Appearance (AAA)

*Beyond AA scope — note if found but not required.*

---

## 2.5 Input Modalities

### 2.5.1 Pointer Gestures (A)

**Requirement**: Multipoint/path gestures have single-pointer alternatives.

**What to Test:**
- Pinch-zoom has button alternatives
- Swipe has button alternatives
- Drawing gestures have alternatives

### 2.5.2 Pointer Cancellation (A)

**Requirement**: Functions don't trigger on down-event (with exceptions).

**What to Test:**
- Actions trigger on click/up, not mousedown
- Or can be aborted by moving off target
- Or can be undone

### 2.5.3 Label in Name (A)

**Requirement**: Visible label is part of accessible name.

**What to Test:**
- Button text matches accessible name
- aria-label includes visible text
- Voice control users can speak what they see

**Common Failures:**
- Visible: "Search" | aria-label: "Find products"
- Icon + text where aria-label ignores text

### 2.5.4 Motion Actuation (A)

**Requirement**: Motion-triggered functions have UI alternatives.

**What to Test:**
- Shake to undo has button alternative
- Tilt controls have alternatives
- Can be disabled

### 2.5.7 Dragging Movements (AA) — *New in 2.2*

**Requirement**: Dragging has single-pointer alternative.

**What to Test:**
- Drag-and-drop has click/tap alternative
- Sliders can be adjusted without dragging
- Reordering possible without drag

### 2.5.8 Target Size (Minimum) (AA) — *New in 2.2*

**Requirement**: Touch targets at least 24×24 CSS pixels.

**What to Test:**
- Interactive elements ≥ 24×24px
- Or spacing provides equivalent target area
- Exceptions: inline links, user-agent controlled

**Note**: WCAG says 24px, but platform guidelines recommend 44pt (iOS) / 48dp (Android). Recommend larger.

---

# 3. Understandable

Information and UI operation must be understandable.

## 3.1 Readable

### 3.1.1 Language of Page (A)

**Requirement**: Page language is programmatically set.

**What to Test:**
- `<html lang="xx">` present and correct
- Language code matches content

### 3.1.2 Language of Parts (AA)

**Requirement**: Language changes within page are identified.

**What to Test:**
- Foreign phrases have `lang` attribute
- Quoted content in other language marked

```html
<p>The French phrase <span lang="fr">c'est la vie</span> means...</p>
```

---

## 3.2 Predictable

### 3.2.1 On Focus (A)

**Requirement**: Focus doesn't trigger unexpected context change.

**What to Test:**
- Focusing a field doesn't submit form
- Focusing doesn't open new window
- Focusing doesn't move focus elsewhere

### 3.2.2 On Input (A)

**Requirement**: Changing input doesn't cause unexpected context change.

**What to Test:**
- Selecting dropdown doesn't auto-submit
- Checkbox doesn't navigate away
- Radio selection doesn't trigger action

**Exception**: User is warned beforehand.

### 3.2.3 Consistent Navigation (AA)

**Requirement**: Navigation is consistent across pages.

**What to Test:**
- Nav menu in same location
- Nav items in same order
- Same elements used across site

### 3.2.4 Consistent Identification (AA)

**Requirement**: Same functions have same labels.

**What to Test:**
- Search always called "Search" (not sometimes "Find")
- Submit buttons consistently labeled
- Icons used consistently

---

## 3.3 Input Assistance

### 3.3.1 Error Identification (A)

**Requirement**: Errors are identified and described in text.

**What to Test:**
- Errors communicated in text, not just color
- Error messages are clear
- Error associated with field

### 3.3.2 Labels or Instructions (A)

**Requirement**: Labels or instructions provided for input.

**What to Test:**
- All fields have visible labels
- Complex inputs have instructions
- Required fields indicated

### 3.3.3 Error Suggestion (AA)

**Requirement**: Errors include suggestions for correction (if known).

**What to Test:**
- "Invalid email" → "Please include @ symbol"
- Specific, actionable suggestions
- Not just "invalid input"

### 3.3.4 Error Prevention (Legal, Financial, Data) (AA)

**Requirement**: Submissions are reversible, checked, or confirmed.

**What to Test:**
- Legal/financial submissions are reversible
- Or user can review before submit
- Or confirmation step exists

### 3.3.7 Redundant Entry (AA) — *New in 2.2*

**Requirement**: Don't ask for same information twice in same process.

**What to Test:**
- Email not asked again in same form
- Shipping/billing address can be copied
- Previously entered info auto-populated

**Exceptions**: Security purposes, expired info

### 3.3.8 Accessible Authentication (Minimum) (AA) — *New in 2.2*

**Requirement**: Authentication doesn't require cognitive function tests.

**What to Test:**
- Password managers can fill credentials
- No CAPTCHAs requiring transcription
- Copy-paste allowed in auth fields
- Alternative to memory-based auth

**Cognitive function tests**: Remembering passwords, transcribing, solving puzzles

---

# 4. Robust

Content must be robust enough to work with assistive technologies.

## 4.1 Compatible

### 4.1.1 Parsing (Obsolete in 2.2)

*This criterion was removed in WCAG 2.2 — no longer applicable.*

### 4.1.2 Name, Role, Value (A)

**Requirement**: All UI components have accessible name, role, and state.

**What to Test:**
- Custom controls have correct role
- Accessible name matches function
- States (expanded, selected, checked) exposed

**Common Failures:**
- Custom dropdown without role="listbox"
- Toggle without aria-pressed
- Tab widget without proper ARIA

**Code Check:**
```html
<!-- FAIL: custom button, no role -->
<div class="btn" onclick="submit()">Submit</div>

<!-- PASS: proper button -->
<button onclick="submit()">Submit</button>

<!-- PASS: custom with ARIA -->
<div role="button" tabindex="0" onclick="submit()" onkeydown="handleKey(event)">Submit</div>
```

### 4.1.3 Status Messages (AA)

**Requirement**: Status messages announced without focus.

**What to Test:**
- Success/error messages announced to screen reader
- Search results count announced
- Progress updates announced

**Implementation:**
```html
<div role="status" aria-live="polite">
  3 items added to cart
</div>

<div role="alert" aria-live="assertive">
  Error: Please fix the following issues
</div>
```

---

## WCAG 2.2 New Criteria Summary

New in 2.2 (all at AA level):

| Criterion | Key Test |
|-----------|----------|
| 2.4.11 Focus Not Obscured | Focused item not hidden by sticky elements |
| 2.5.7 Dragging Movements | Single-pointer alternative to drag |
| 2.5.8 Target Size (Minimum) | 24×24px minimum touch targets |
| 3.3.7 Redundant Entry | Don't ask same info twice |
| 3.3.8 Accessible Authentication | No cognitive tests for login |

---

## Audit Checklist by Criterion

Quick checklist format for audits:

```markdown
## Perceivable
- [ ] 1.1.1 Non-text Content
- [ ] 1.2.1 Audio-only / Video-only
- [ ] 1.2.2 Captions (Prerecorded)
- [ ] 1.2.3 Audio Description or Alternative
- [ ] 1.2.4 Captions (Live) — AA
- [ ] 1.2.5 Audio Description — AA
- [ ] 1.3.1 Info and Relationships
- [ ] 1.3.2 Meaningful Sequence
- [ ] 1.3.3 Sensory Characteristics
- [ ] 1.3.4 Orientation — AA
- [ ] 1.3.5 Identify Input Purpose — AA
- [ ] 1.4.1 Use of Color
- [ ] 1.4.2 Audio Control
- [ ] 1.4.3 Contrast (Minimum) — AA
- [ ] 1.4.4 Resize Text — AA
- [ ] 1.4.5 Images of Text — AA
- [ ] 1.4.10 Reflow — AA
- [ ] 1.4.11 Non-text Contrast — AA
- [ ] 1.4.12 Text Spacing — AA
- [ ] 1.4.13 Content on Hover or Focus — AA

## Operable
- [ ] 2.1.1 Keyboard
- [ ] 2.1.2 No Keyboard Trap
- [ ] 2.1.4 Character Key Shortcuts
- [ ] 2.2.1 Timing Adjustable
- [ ] 2.2.2 Pause, Stop, Hide
- [ ] 2.3.1 Three Flashes
- [ ] 2.4.1 Bypass Blocks
- [ ] 2.4.2 Page Titled
- [ ] 2.4.3 Focus Order
- [ ] 2.4.4 Link Purpose
- [ ] 2.4.5 Multiple Ways — AA
- [ ] 2.4.6 Headings and Labels — AA
- [ ] 2.4.7 Focus Visible — AA
- [ ] 2.4.11 Focus Not Obscured — AA (2.2)
- [ ] 2.5.1 Pointer Gestures
- [ ] 2.5.2 Pointer Cancellation
- [ ] 2.5.3 Label in Name
- [ ] 2.5.4 Motion Actuation
- [ ] 2.5.7 Dragging Movements — AA (2.2)
- [ ] 2.5.8 Target Size — AA (2.2)

## Understandable
- [ ] 3.1.1 Language of Page
- [ ] 3.1.2 Language of Parts — AA
- [ ] 3.2.1 On Focus
- [ ] 3.2.2 On Input
- [ ] 3.2.3 Consistent Navigation — AA
- [ ] 3.2.4 Consistent Identification — AA
- [ ] 3.3.1 Error Identification
- [ ] 3.3.2 Labels or Instructions
- [ ] 3.3.3 Error Suggestion — AA
- [ ] 3.3.4 Error Prevention — AA
- [ ] 3.3.7 Redundant Entry — AA (2.2)
- [ ] 3.3.8 Accessible Authentication — AA (2.2)

## Robust
- [ ] 4.1.2 Name, Role, Value
- [ ] 4.1.3 Status Messages — AA
```
