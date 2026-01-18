# Information Architecture

Structure content so users find what they need intuitively.

## IA Fundamentals

### Core Components

1. **Organization**: How content is grouped and categorized
2. **Labeling**: What things are called
3. **Navigation**: How users move through content
4. **Search**: How users find specific content

### Mental Models

Users have expectations based on experience. Match their mental model:
- **User's model**: How they think it works
- **System's model**: How it actually works
- **Goal**: Minimize the gap

When in doubt, follow conventions. Innovation in navigation rarely pays off.

---

## Content Organization

### Organization Schemes

| Scheme | Best For | Example |
|--------|----------|---------|
| **Alphabetical** | Known-item search, reference | Glossary, directory |
| **Chronological** | Time-based content | News, blog, history |
| **Geographical** | Location-based content | Store locator, weather |
| **Topical** | Subject categorization | Documentation, e-commerce |
| **Task-based** | Action-oriented | App features, how-to |
| **Audience-based** | Distinct user groups | "For Enterprise" / "For Startups" |
| **Hybrid** | Complex content | Most real-world sites |

### Hierarchy Design

**Wide vs Deep:**
```
Wide (flat):        Deep (narrow):
├── A               └── A
├── B                   └── B
├── C                       └── C
├── D                           └── D
├── E
└── F
```

- **Wide**: More visible options, less clicking, higher cognitive load
- **Deep**: Cleaner interface, more clicking, easier choices per level
- **Recommendation**: 3-4 levels max, 5-9 items per level

### Card Sorting

**Technique to discover user mental models:**

**Open Sort:**
1. Give users content items on cards
2. Ask them to group into categories
3. Ask them to name categories
4. Reveals how users naturally organize

**Closed Sort:**
1. Provide pre-defined categories
2. Ask users to place items into categories
3. Validates proposed structure

**Hybrid Sort:**
- Start with categories, allow new ones
- Balance between discovery and validation

---

## Navigation Design

### Navigation Types

**Global Navigation:**
- Present on all pages
- Primary way to move between major sections
- Usually: top navbar (web), bottom tabs (mobile)

**Local Navigation:**
- Within a section
- Sidebar, sub-navigation
- Shows depth within current area

**Contextual Navigation:**
- Inline links, related content
- "See also", "Related articles"
- Cross-links between sections

**Utility Navigation:**
- Functional links
- Search, account, settings, help
- Usually top-right (web)

### Navigation Patterns by Platform

**Web - Top Navigation:**
```
┌─────────────────────────────────────────────────────┐
│ Logo    Nav Item   Nav Item   Nav Item    [Search] [Account] │
├─────────────────────────────────────────────────────┤
│                                                     │
│                    Content                          │
│                                                     │
└─────────────────────────────────────────────────────┘
```
Best for: Marketing sites, content sites, few top-level sections

**Web - Sidebar Navigation:**
```
┌──────────┬──────────────────────────────────────────┐
│ Logo     │  Header / Breadcrumbs                    │
├──────────┼──────────────────────────────────────────┤
│ Nav      │                                          │
│ Item     │                                          │
│ Item     │              Content                     │
│ Item     │                                          │
│ ├─Sub    │                                          │
│ └─Sub    │                                          │
│ Item     │                                          │
└──────────┴──────────────────────────────────────────┘
```
Best for: Apps, dashboards, documentation, many sections

**Mobile - Bottom Tabs:**
```
┌─────────────────────┐
│                     │
│      Content        │
│                     │
│                     │
├─────────────────────┤
│ 🏠  📊  ➕  💬  👤 │
└─────────────────────┘
```
Best for: Primary app navigation, 3-5 destinations

**Mobile - Stack Navigation:**
```
┌─────────────────────┐
│ ← Title             │
├─────────────────────┤
│                     │
│      Content        │
│                     │
└─────────────────────┘
```
Best for: Hierarchical content, drill-down interfaces

### Breadcrumbs

```
Home > Category > Subcategory > Current Page
```

**When to Use:**
- Deep hierarchies (3+ levels)
- Users arrive via search (need context)
- Large content sites

**When to Skip:**
- Flat sites
- Linear flows (use progress instead)
- Mobile (usually)

### Wayfinding Principles

Users should always know:
1. **Where am I?** (Current location indicator)
2. **Where can I go?** (Available navigation)
3. **Where have I been?** (Visited states)
4. **How do I get back?** (Home, back, breadcrumbs)

---

## Labeling

### Label Principles

- **User language**: Use their words, not internal jargon
- **Specific**: "Documentation" not "Resources"
- **Consistent**: Same label = same destination
- **Scannable**: Front-load key words

### Label Testing

**Tree Testing:**
1. Show only navigation labels (no design)
2. Give users tasks: "Find X"
3. Track where they click
4. Reveals label clarity issues

**First-Click Testing:**
- Show page/navigation
- Ask "Where would you click to [task]?"
- Measures if labels communicate destination

### Common Labeling Mistakes

| Mistake | Problem | Better |
|---------|---------|--------|
| "Solutions" | Too vague | "Products" or specific names |
| "Resources" | Catch-all | "Documentation", "Templates" |
| "Get Started" | Where does it go? | "Sign Up" or "Quick Start Guide" |
| "Learn More" | Generic | Specific action: "See Pricing" |
| Internal acronyms | Users don't know them | Spell out or use common terms |

---

## Search

### Search Best Practices

**Search Box:**
- Prominent placement (header)
- Adequate width (27+ characters visible)
- Placeholder text: "Search..." or "Search [site name]"
- Search icon as affordance

**Search Results:**
- Show query in results page
- Number of results
- Clear result titles and snippets
- Highlight matched terms
- Faceted filtering for large result sets

**No Results:**
- Confirm what was searched
- Suggest alternatives
- Check spelling
- Offer browse navigation

### Search vs Browse

| User Behavior | Offer |
|---------------|-------|
| Knows exactly what they want | Search |
| Exploring, learning options | Navigation |
| Somewhat knows | Search with suggestions |

Most users use a combination. Support both well.

---

## Site Maps & Content Inventory

### Site Map Template

```
Home
├── Products
│   ├── Product A
│   ├── Product B
│   └── Pricing
├── Solutions
│   ├── By Industry
│   └── By Use Case
├── Resources
│   ├── Documentation
│   ├── Blog
│   └── Webinars
├── Company
│   ├── About
│   ├── Careers
│   └── Contact
└── [Footer Links]
    ├── Privacy
    ├── Terms
    └── Security
```

### Content Inventory Fields

For each page/content item:
- **ID**: Unique identifier
- **Title**: Page/content name
- **URL**: Current location
- **Type**: Page, blog post, product, etc.
- **Owner**: Who maintains it
- **Last Updated**: Date
- **Traffic**: Analytics data
- **Notes**: Migration/action notes

### Content Audit Questions

1. Is this content still accurate?
2. Is anyone using it? (Analytics)
3. Does it duplicate other content?
4. Does it serve a user need?
5. Keep, update, merge, or delete?

---

## URL Design

### URL Principles

- **Readable**: `/products/widget-pro` not `/p?id=12847`
- **Predictable**: Users can guess URLs
- **Persistent**: URLs shouldn't break over time
- **Shallow**: Fewer segments better

### URL Patterns

```
# Good
/blog/2024/ux-design-principles
/products/enterprise
/docs/getting-started/installation

# Avoid
/blog/post.php?id=847&cat=3
/products/prod_847261_v2_final
/page/page/page/content
```

### Trailing Slashes

Pick one convention and stick to it:
- `/about/` (directory style)
- `/about` (file style)

Redirect the other to your canonical version.

---

## Mobile IA Considerations

### Simplification Strategies

- **Reduce top-level items**: 5 max for bottom tabs
- **Progressive disclosure**: Show less, reveal on demand
- **Priority+**: Show top items, overflow to "More"
- **Contextual nav**: Show nav relevant to current section

### Mobile Navigation Patterns

**Priority+ Pattern:**
```
┌────────────────────────────────┐
│ Item  Item  Item  Item  •••   │
└────────────────────────────────┘
```
Shows what fits, rest in overflow menu.

**Contextual Bottom Sheet:**
```
┌─────────────────────┐
│      Content        │
├─────────────────────┤
│ ┌─────────────────┐ │
│ │  Related Nav    │ │
│ │  Option 1       │ │
│ │  Option 2       │ │
│ └─────────────────┘ │
└─────────────────────┘
```

### Mobile vs Desktop IA

| Aspect | Desktop | Mobile |
|--------|---------|--------|
| Top-level items | 5-9 | 3-5 |
| Navigation depth | 3-4 levels | 2-3 levels |
| Search prominence | Important | Critical |
| Breadcrumbs | Often useful | Usually skip |
| Sidebar | Common | Rare (use bottom sheet) |

---

## IA Documentation

### Deliverables

1. **Site map**: Visual hierarchy
2. **Navigation spec**: What appears where, behavior
3. **URL schema**: Patterns and examples
4. **Labeling guide**: Terminology standards
5. **Content model**: Types and relationships

### Maintenance

IA evolves. Plan for:
- Regular content audits
- Analytics review
- User feedback integration
- Redirect management for changes
