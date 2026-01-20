---
description: Build high-converting marketing pages
argument-hint: <page-description>
skill: marketing-website
---

# Marketing Page Workflow

Create marketing page for: `$ARGUMENTS`

## Steps

### 1. Identify Page Type
From `$ARGUMENTS`, determine:
- **Landing page**: Campaign-specific conversion
- **Product page**: Feature showcase
- **Pricing page**: Plan comparison
- **Homepage**: Brand overview
- **About page**: Company story

### 2. Define Goals
- **Primary CTA**: What action should users take?
- **Success metric**: How will we measure success?
- **Target audience**: Who is this page for?

### 3. Design Page Structure

**Landing Page Structure:**
```
Hero Section
├── Headline (value proposition)
├── Subheadline (clarification)
├── CTA button
└── Hero image/video

Problem Section
└── Pain points addressed

Solution Section
├── Key features
├── Benefits
└── Screenshots/demos

Social Proof
├── Testimonials
├── Logos
└── Stats

CTA Section
└── Final conversion push

Footer
└── Trust signals
```

**Pricing Page Structure:**
```
Pricing Header
└── Value-based headline

Plan Comparison
├── Feature matrix
├── Price points
├── Recommended plan highlight
└── CTAs per plan

FAQ
└── Common objections

Enterprise CTA
└── Contact sales
```

### 4. Copywriting Guidelines
- **Headlines**: Clear benefit, not feature
- **Body**: Scannable, benefit-focused
- **CTAs**: Action-oriented, specific
- **Social proof**: Specific, credible

### 5. SEO Considerations
- Meta title and description
- Header hierarchy (H1, H2, H3)
- Image alt text
- Schema markup

### 6. Create Implementation Tasks
```bash
npx @stevestomp/ohno-cli create "Marketing: [page section]" -t feature
```

## Covers
- Page structure design
- Conversion optimization
- Copywriting guidelines
- Visual hierarchy
- CTA design
- Social proof
- SEO basics

## Related Commands

- `/pokayokay:ux` - User flow design
- `/pokayokay:ui` - Visual design
- `/pokayokay:a11y` - Accessible marketing
- `/pokayokay:work` - Implement page

## Skill Integration

When marketing work involves:
- **UX patterns** → Also load `ux-design` skill
- **Visual design** → Also load `aesthetic-ui-designer` skill
- **Accessibility** → Also load `accessibility-auditor` skill
