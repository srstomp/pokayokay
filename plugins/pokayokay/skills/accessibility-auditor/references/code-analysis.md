# Code Analysis Patterns

Platform-specific accessibility code analysis for auditing.

## HTML / Web

### Document Structure

```html
<!-- CHECK: Language declaration -->
<html lang="en">

<!-- CHECK: Viewport allows zoom -->
<meta name="viewport" content="width=device-width, initial-scale=1">
<!-- FAIL: prevents zoom -->
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">

<!-- CHECK: Page title -->
<title>Descriptive Page Title | Site Name</title>
```

### Landmarks

```html
<!-- CHECK: Proper landmarks -->
<header role="banner">...</header>
<nav role="navigation" aria-label="Main">...</nav>
<main role="main">...</main>
<aside role="complementary">...</aside>
<footer role="contentinfo">...</footer>

<!-- CHECK: Skip link (first focusable element) -->
<a href="#main-content" class="skip-link">Skip to main content</a>
```

### Headings

```html
<!-- CHECK: Logical hierarchy -->
<h1>Page Title</h1>           <!-- One per page -->
  <h2>Section</h2>            <!-- Major sections -->
    <h3>Subsection</h3>       <!-- Within sections -->
    <h3>Another Subsection</h3>

<!-- FAIL: Skipped levels -->
<h1>Title</h1>
<h3>Jumped to h3</h3>         <!-- Missing h2 -->

<!-- FAIL: Visual-only heading -->
<div class="h2-style">Section Title</div>
```

### Images

```html
<!-- CHECK: Meaningful images have descriptive alt -->
<img src="chart.png" alt="Sales grew 40% in Q2 compared to Q1">

<!-- CHECK: Decorative images have empty alt -->
<img src="decoration.png" alt="">

<!-- CHECK: Complex images have long description -->
<figure>
  <img src="complex-chart.png" alt="Q2 Revenue Breakdown">
  <figcaption>
    Detailed breakdown: Product A (45%), Product B (30%), Services (25%)...
  </figcaption>
</figure>

<!-- FAIL: Missing alt -->
<img src="hero.jpg">

<!-- FAIL: Unhelpful alt -->
<img src="team.jpg" alt="image">
<img src="photo.jpg" alt="IMG_2847.jpg">
```

### Links

```html
<!-- CHECK: Descriptive link text -->
<a href="/report">View Q2 Financial Report</a>

<!-- CHECK: Opens in new window warning -->
<a href="/external" target="_blank">
  External Site <span class="visually-hidden">(opens in new tab)</span>
</a>

<!-- FAIL: Vague link text -->
<a href="/report">Click here</a>
<a href="/more">Read more</a>

<!-- FAIL: No indication of new window -->
<a href="/external" target="_blank">External Site</a>
```

### Forms

```html
<!-- CHECK: Labels associated with inputs -->
<label for="email">Email address</label>
<input type="email" id="email" autocomplete="email">

<!-- CHECK: Required fields indicated -->
<label for="name">
  Name <span aria-hidden="true">*</span>
  <span class="visually-hidden">(required)</span>
</label>
<input type="text" id="name" required aria-required="true">

<!-- CHECK: Error messages associated -->
<label for="password">Password</label>
<input type="password" id="password" aria-describedby="password-error" aria-invalid="true">
<span id="password-error" role="alert">Password must be at least 8 characters</span>

<!-- CHECK: Fieldset for grouped inputs -->
<fieldset>
  <legend>Shipping Address</legend>
  <label for="street">Street</label>
  <input type="text" id="street" autocomplete="street-address">
  ...
</fieldset>

<!-- FAIL: Placeholder as label -->
<input type="email" placeholder="Email address">

<!-- FAIL: No label association -->
<label>Email</label>
<input type="email">
```

### Buttons

```html
<!-- CHECK: Button has accessible name -->
<button>Submit Application</button>
<button aria-label="Close dialog">×</button>

<!-- CHECK: Icon buttons have labels -->
<button aria-label="Search">
  <svg>...</svg>
</button>

<!-- FAIL: Empty button -->
<button><svg>...</svg></button>

<!-- FAIL: Div as button -->
<div class="btn" onclick="submit()">Submit</div>

<!-- FIX: If must use div -->
<div role="button" tabindex="0" onclick="submit()" onkeydown="handleKey(event)">Submit</div>
```

### Tables

```html
<!-- CHECK: Data tables have headers -->
<table>
  <caption>Q2 Sales by Region</caption>
  <thead>
    <tr>
      <th scope="col">Region</th>
      <th scope="col">Sales</th>
      <th scope="col">Growth</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <th scope="row">North</th>
      <td>$1.2M</td>
      <td>+15%</td>
    </tr>
  </tbody>
</table>

<!-- FAIL: No headers -->
<table>
  <tr><td>Region</td><td>Sales</td></tr>
  <tr><td>North</td><td>$1.2M</td></tr>
</table>
```

### Focus Management

```html
<!-- CHECK: Focus visible -->
button:focus {
  outline: 2px solid #005fcc;
  outline-offset: 2px;
}

/* FAIL: Focus removed without replacement */
*:focus {
  outline: none;
}

<!-- CHECK: Focus trap in modals -->
<div role="dialog" aria-modal="true" aria-labelledby="dialog-title">
  <h2 id="dialog-title">Confirm Action</h2>
  <!-- Focus stays within dialog until closed -->
</div>
```

### Live Regions

```html
<!-- CHECK: Status messages announced -->
<div role="status" aria-live="polite">
  3 items added to cart
</div>

<!-- CHECK: Urgent messages use alert -->
<div role="alert" aria-live="assertive">
  Session expiring in 2 minutes
</div>

<!-- CHECK: Loading states announced -->
<div aria-busy="true" aria-live="polite">
  Loading results...
</div>
```

---

## React / JSX

### Component Patterns

```jsx
// CHECK: Forward refs for custom components
const Button = React.forwardRef((props, ref) => (
  <button ref={ref} {...props}>{props.children}</button>
));

// CHECK: Semantic elements over divs
// FAIL
const Card = () => <div onClick={handleClick}>...</div>

// PASS
const Card = () => (
  <article>
    <button onClick={handleClick}>...</button>
  </article>
);

// CHECK: Keyboard handlers with click
<div 
  role="button"
  tabIndex={0}
  onClick={handleClick}
  onKeyDown={(e) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      handleClick();
    }
  }}
>
  Clickable Div
</div>
```

### Form Handling

```jsx
// CHECK: Labels connected
<label htmlFor="username">Username</label>
<input id="username" type="text" />

// CHECK: Error states
<input 
  id="email"
  type="email"
  aria-invalid={!!errors.email}
  aria-describedby={errors.email ? "email-error" : undefined}
/>
{errors.email && (
  <span id="email-error" role="alert">{errors.email}</span>
)}

// CHECK: Autocomplete attributes
<input 
  type="text" 
  autoComplete="name"
  name="fullName"
/>
```

### Focus Management

```jsx
// CHECK: Focus on route change
useEffect(() => {
  // Focus main content after navigation
  mainRef.current?.focus();
}, [location]);

// CHECK: Focus trap in modals
import { FocusTrap } from '@headlessui/react';

<FocusTrap>
  <div role="dialog" aria-modal="true">
    {/* Modal content */}
  </div>
</FocusTrap>

// CHECK: Skip link
<a href="#main" className="sr-only focus:not-sr-only">
  Skip to main content
</a>
```

### Conditional Rendering

```jsx
// CHECK: Screen reader announcements for dynamic content
const [message, setMessage] = useState('');

<div role="status" aria-live="polite">
  {message}
</div>

// CHECK: Loading states
{isLoading ? (
  <div aria-busy="true" aria-live="polite">Loading...</div>
) : (
  <Results />
)}
```

### Common React Anti-Patterns

```jsx
// FAIL: Positive tabindex
<div tabIndex={1}>...</div>  // Never use positive tabindex

// FAIL: Autofocus without reason
<input autoFocus />  // Disorients screen reader users

// FAIL: Click without keyboard
<div onClick={handleClick}>...</div>  // Needs keyboard handler

// FAIL: Generic role overuse
<div role="button">Not actually a button</div>  // Use <button>

// FAIL: Index as key (harms screen reader experience)
{items.map((item, index) => <li key={index}>{item}</li>)}
// PASS
{items.map((item) => <li key={item.id}>{item.name}</li>)}
```

---

## React Native

### Basic Accessibility Props

```jsx
// CHECK: Touchables have labels
<TouchableOpacity
  accessibilityLabel="Submit form"
  accessibilityRole="button"
>
  <Text>Submit</Text>
</TouchableOpacity>

// CHECK: Images have labels
<Image
  source={icon}
  accessibilityLabel="User profile"
/>

// CHECK: Decorative images hidden
<Image
  source={decoration}
  accessibilityElementsHidden={true}
  importantForAccessibility="no-hide-descendants"
/>
```

### Roles and States

```jsx
// CHECK: Correct role
<TouchableOpacity accessibilityRole="button">
<TouchableOpacity accessibilityRole="link">
<TouchableOpacity accessibilityRole="checkbox">
<View accessibilityRole="header">
<View accessibilityRole="alert">

// CHECK: States communicated
<TouchableOpacity
  accessibilityRole="checkbox"
  accessibilityState={{ checked: isChecked }}
>

<TouchableOpacity
  accessibilityRole="button"
  accessibilityState={{ 
    disabled: isDisabled,
    selected: isSelected,
    expanded: isExpanded 
  }}
>

// CHECK: Value for sliders/progress
<Slider
  accessibilityRole="adjustable"
  accessibilityValue={{
    min: 0,
    max: 100,
    now: currentValue,
    text: `${currentValue} percent`
  }}
/>
```

### Hints and Labels

```jsx
// CHECK: Hints for non-obvious actions
<TouchableOpacity
  accessibilityLabel="Product image"
  accessibilityHint="Double tap to view full screen"
>

// CHECK: Concatenated elements
<View
  accessible={true}
  accessibilityLabel={`${productName}, ${price}, ${rating} stars`}
>
  <Text>{productName}</Text>
  <Text>{price}</Text>
  <Text>{rating} ★</Text>
</View>
```

### Focus and Announcements

```jsx
// CHECK: Focus management
const myRef = useRef(null);
<View ref={myRef} accessible={true}>

// Move focus programmatically
AccessibilityInfo.setAccessibilityFocus(myRef.current);

// CHECK: Announcements
AccessibilityInfo.announceForAccessibility('Item added to cart');

// CHECK: Screen reader status
const [screenReaderEnabled, setScreenReaderEnabled] = useState(false);
useEffect(() => {
  AccessibilityInfo.isScreenReaderEnabled().then(setScreenReaderEnabled);
}, []);
```

### Touch Targets

```jsx
// CHECK: Minimum 44pt touch targets
<TouchableOpacity
  style={{ minWidth: 44, minHeight: 44 }}
  hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
>

// Or ensure padding provides 44pt total
<TouchableOpacity style={{ padding: 12 }}>
  <Icon size={20} />  {/* 20 + 12 + 12 = 44 */}
</TouchableOpacity>
```

### React Native Anti-Patterns

```jsx
// FAIL: Missing label
<TouchableOpacity onPress={handlePress}>
  <Image source={icon} />
</TouchableOpacity>

// FAIL: Redundant info
<TouchableOpacity
  accessibilityLabel="Button Submit button"  // "button" redundant with role
  accessibilityRole="button"
>

// FAIL: Dynamic content not announced
setItems(newItems);  // Screen reader doesn't know

// FIX
setItems(newItems);
AccessibilityInfo.announceForAccessibility(`${newItems.length} items loaded`);

// FAIL: Small touch targets
<TouchableOpacity style={{ width: 24, height: 24 }}>
```

---

## SwiftUI / iOS

### Basic Modifiers

```swift
// CHECK: Labels on controls
Button(action: submit) {
    Image(systemName: "paperplane")
}
.accessibilityLabel("Send message")

// CHECK: Images
Image("chart")
    .accessibilityLabel("Sales chart showing 40% growth")

// Decorative image
Image(decorative: "background")
// or
Image("background")
    .accessibilityHidden(true)
```

### Traits and Values

```swift
// CHECK: Correct traits
Text("Section Header")
    .accessibilityAddTraits(.isHeader)

Button("More options") { }
    .accessibilityAddTraits(.isButton)  // Automatic for Button

// CHECK: States
Toggle("Notifications", isOn: $notificationsOn)
    .accessibilityValue(notificationsOn ? "On" : "Off")

// CHECK: Custom actions
Image("photo")
    .accessibilityLabel("Beach photo")
    .accessibilityHint("Double tap to view full screen")
    .accessibilityAction {
        showFullScreen()
    }
```

### Grouping and Order

```swift
// CHECK: Logical grouping
HStack {
    Image("product")
    VStack {
        Text(productName)
        Text(price)
    }
}
.accessibilityElement(children: .combine)

// Or custom grouping
.accessibilityElement(children: .ignore)
.accessibilityLabel("\(productName), \(price)")

// CHECK: Custom order
VStack {
    Text("Title")
        .accessibilityOrder(1)
    Text("Description")
        .accessibilityOrder(2)
    Button("Action")
        .accessibilityOrder(3)
}
```

### Dynamic Type Support

```swift
// CHECK: Scalable text
Text("Body text")
    .font(.body)  // System fonts scale automatically

// Custom fonts need scaling
Text("Custom")
    .font(.custom("MyFont", size: 16, relativeTo: .body))

// CHECK: Layout adapts
@Environment(\.sizeCategory) var sizeCategory

if sizeCategory >= .accessibilityMedium {
    // Stack vertically for large text
    VStack { content }
} else {
    HStack { content }
}

// CHECK: Not disabled
// FAIL
Text("Fixed")
    .dynamicTypeSize(.medium)  // Prevents scaling
```

### Focus Management

```swift
// CHECK: Focus state
@FocusState private var isFieldFocused: Bool

TextField("Name", text: $name)
    .focused($isFieldFocused)

// Move focus
Button("Continue") {
    isFieldFocused = false
    // Focus next field
}

// CHECK: Announcements
UIAccessibility.post(notification: .announcement, 
                     argument: "Form submitted successfully")

// CHECK: Screen change
UIAccessibility.post(notification: .screenChanged, 
                     argument: newScreenView)
```

### SwiftUI Anti-Patterns

```swift
// FAIL: Image without label
Image("icon")
    .onTapGesture { }

// FAIL: Fixed text size
Text("Important")
    .font(.system(size: 14))  // Won't scale

// FAIL: Insufficient contrast in custom colors
Text("Light gray")
    .foregroundColor(Color(white: 0.7))  // Check contrast!

// FAIL: Custom gesture without accessible alternative
View()
    .gesture(
        DragGesture()
            .onEnded { /* reorder */ }
    )
// Missing: accessibilityAction for reordering

// FAIL: Missing header traits
Text("Settings")
    .font(.headline)
// Missing: .accessibilityAddTraits(.isHeader)
```

---

## Analysis Checklist by Platform

### Web/HTML Checklist

| Category | Check |
|----------|-------|
| Document | `lang` attribute, `<title>`, viewport zoom allowed |
| Structure | Landmarks, heading hierarchy, skip link |
| Images | Alt text (meaningful or empty for decorative) |
| Links | Descriptive text, new window indication |
| Forms | Labels, error messages, autocomplete |
| Keyboard | All interactive elements focusable, no traps |
| Focus | Visible focus indicator |
| Color | 4.5:1 text contrast, not sole indicator |
| Dynamic | Live regions for updates |

### React Checklist

| Category | Check |
|----------|-------|
| Components | Semantic elements, forwarded refs |
| Interactivity | Click + keyboard handlers |
| Forms | htmlFor labels, error association |
| Focus | Route change management, modal trapping |
| State | aria-invalid, aria-expanded, etc. |
| Announcements | role="status", role="alert" |

### React Native Checklist

| Category | Check |
|----------|-------|
| Touchables | accessibilityLabel, accessibilityRole |
| Images | Labels or hidden if decorative |
| States | accessibilityState for all states |
| Hints | accessibilityHint for non-obvious |
| Grouping | accessible={true} for related elements |
| Touch | 44pt minimum targets |
| Announcements | announceForAccessibility |

### SwiftUI/iOS Checklist

| Category | Check |
|----------|-------|
| Labels | accessibilityLabel on all controls |
| Images | Labels or .accessibilityHidden |
| Traits | .isHeader, .isButton where needed |
| Values | accessibilityValue for state |
| Grouping | .accessibilityElement(children:) |
| Dynamic Type | System fonts, relativeTo for custom |
| Announcements | UIAccessibility.post |
