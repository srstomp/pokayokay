# SEO Essentials

Practical SEO guidance for marketing websites.

## On-Page SEO

### Title Tags

**Format:** `Primary Keyword - Secondary Info | Brand`

**Guidelines:**
- 50-60 characters (Google truncates at ~60)
- Primary keyword near the beginning
- Unique for every page
- Compelling (it's your search result headline)

**Examples:**
```html
<!-- Home page -->
<title>Project Management Software for Remote Teams | AppName</title>

<!-- Feature page -->
<title>Automated Workflows - Save 5 Hours Weekly | AppName</title>

<!-- Pricing page -->
<title>Pricing Plans - Start Free, Scale as You Grow | AppName</title>

<!-- Blog post -->
<title>How to Run Effective Remote Meetings in 2024 | AppName Blog</title>
```

### Meta Descriptions

**Guidelines:**
- 150-160 characters
- Include primary keyword naturally
- Write a compelling pitch (it's ad copy)
- Include a call to action when relevant
- Unique for every page

**Examples:**
```html
<meta name="description" content="Ship projects faster with async collaboration built for remote teams. Free for up to 10 members. Start in 2 minutes, no credit card required.">

<meta name="description" content="Compare our Starter, Pro, and Team plans. All plans include unlimited projects and 24/7 support. Start your free 14-day trial today.">
```

### Heading Structure

**Rules:**
- One H1 per page (the main title)
- H1 includes primary keyword
- Logical hierarchy: H1 → H2 → H3
- Don't skip levels (H1 → H3)
- Headings describe content, not just style

**Example:**
```html
<h1>Project Management for Remote Teams</h1>
  <h2>Why Remote Teams Choose Us</h2>
    <h3>Async-First Communication</h3>
    <h3>Time Zone Intelligence</h3>
  <h2>Features</h2>
    <h3>Task Management</h3>
    <h3>Document Collaboration</h3>
  <h2>Pricing</h2>
  <h2>FAQ</h2>
```

### Image Optimization

**Alt Text:**
```html
<!-- Descriptive, not keyword-stuffed -->
<img src="dashboard.png" alt="Project dashboard showing task progress and team activity">

<!-- For decorative images -->
<img src="decoration.png" alt="" role="presentation">
```

**File Names:**
- `project-dashboard-screenshot.png` ✓
- `IMG_2847.png` ✗
- `best-project-management-software-dashboard-2024.png` ✗ (stuffed)

**Performance:**
- Compress images (TinyPNG, ImageOptim)
- Use modern formats (WebP with fallback)
- Specify dimensions to prevent layout shift
- Lazy load below-fold images

---

## Technical SEO

### URL Structure

**Guidelines:**
- Short and descriptive
- Use hyphens, not underscores
- Lowercase only
- Include keywords naturally
- Avoid parameters when possible

**Examples:**
```
Good:
/features/automation
/pricing
/blog/remote-team-productivity

Avoid:
/features/automation/
/index.php?page=pricing
/blog/2024/01/15/post-title-here
```

### Canonical Tags

Specify the preferred URL version:
```html
<link rel="canonical" href="https://example.com/features">
```

Use when:
- Same content accessible at multiple URLs
- Parameters create duplicate pages
- HTTP/HTTPS or www/non-www variations

### Robots & Indexing

```html
<!-- Allow indexing (default) -->
<meta name="robots" content="index, follow">

<!-- Prevent indexing (staging, duplicates, private) -->
<meta name="robots" content="noindex, nofollow">
```

**robots.txt:**
```
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /api/
Sitemap: https://example.com/sitemap.xml
```

### XML Sitemap

Include:
- All indexable pages
- Last modified dates
- Priority hints (optional)

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2024-01-15</lastmod>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://example.com/features</loc>
    <lastmod>2024-01-10</lastmod>
    <priority>0.8</priority>
  </url>
</urlset>
```

---

## Core Web Vitals

Google's page experience metrics:

### LCP (Largest Contentful Paint)
Target: < 2.5 seconds

**How to improve:**
- Optimize hero images
- Preload critical resources
- Use CDN
- Eliminate render-blocking resources

### FID (First Input Delay) / INP (Interaction to Next Paint)
Target: < 100ms (FID) / < 200ms (INP)

**How to improve:**
- Minimize JavaScript
- Break up long tasks
- Use web workers for heavy computation

### CLS (Cumulative Layout Shift)
Target: < 0.1

**How to improve:**
- Set image/video dimensions
- Reserve space for ads/embeds
- Avoid inserting content above existing content
- Use transform for animations

### Quick Wins

```html
<!-- Preload critical resources -->
<link rel="preload" href="/fonts/brand.woff2" as="font" type="font/woff2" crossorigin>
<link rel="preload" href="/hero.webp" as="image">

<!-- Preconnect to external domains -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://analytics.example.com">

<!-- Async non-critical scripts -->
<script async src="/analytics.js"></script>

<!-- Defer non-critical scripts -->
<script defer src="/non-critical.js"></script>
```

---

## Structured Data

Help search engines understand your content.

### Organization (Site-wide)
```json
{
  "@context": "https://schema.org",
  "@type": "Organization",
  "name": "AppName",
  "url": "https://example.com",
  "logo": "https://example.com/logo.png",
  "sameAs": [
    "https://twitter.com/appname",
    "https://linkedin.com/company/appname"
  ]
}
```

### Product/SaaS
```json
{
  "@context": "https://schema.org",
  "@type": "SoftwareApplication",
  "name": "AppName",
  "applicationCategory": "BusinessApplication",
  "operatingSystem": "Web",
  "offers": {
    "@type": "Offer",
    "price": "29",
    "priceCurrency": "USD"
  },
  "aggregateRating": {
    "@type": "AggregateRating",
    "ratingValue": "4.8",
    "reviewCount": "1250"
  }
}
```

### FAQ Page
```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "How long does setup take?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Most teams are up and running in under 15 minutes."
      }
    }
  ]
}
```

### Breadcrumbs
```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    {
      "@type": "ListItem",
      "position": 1,
      "name": "Home",
      "item": "https://example.com"
    },
    {
      "@type": "ListItem",
      "position": 2,
      "name": "Features",
      "item": "https://example.com/features"
    }
  ]
}
```

---

## Content Strategy

### Keyword Research Basics

**Types of keywords:**
| Type | Example | Intent |
|------|---------|--------|
| Informational | "how to manage remote teams" | Learning |
| Commercial | "best project management software" | Comparing |
| Transactional | "buy asana alternative" | Ready to buy |
| Navigational | "appname login" | Finding specific site |

**Where to find keywords:**
- Google autocomplete
- "People also ask" boxes
- Competitor analysis
- Customer questions/support tickets
- Google Search Console data

### Content Mapping

Map keywords to pages:
```
Home page: "project management software"
Features: "task management features"
Pricing: "project management pricing"
Blog: "how to run remote meetings"
       "async communication best practices"
       "remote team productivity tips"
```

### Blog SEO

**Post structure:**
1. Compelling title with keyword
2. Meta description with CTA
3. Introduction that hooks + previews
4. Structured content with H2/H3s
5. Internal links to relevant pages
6. CTA to product/signup

**Content guidelines:**
- Answer the search query completely
- Better than existing results
- Include visuals (images, diagrams)
- Update regularly (fresh content ranks better)

---

## Local SEO (If Applicable)

For businesses with physical locations:

### Google Business Profile
- Complete all fields
- Add photos
- Collect reviews
- Post updates regularly

### Local Schema
```json
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "Business Name",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "123 Main St",
    "addressLocality": "City",
    "addressRegion": "State",
    "postalCode": "12345"
  },
  "telephone": "+1-555-555-5555",
  "openingHours": "Mo-Fr 09:00-17:00"
}
```

---

## SEO Checklist

### Every Page
- [ ] Unique, descriptive title tag (50-60 chars)
- [ ] Compelling meta description (150-160 chars)
- [ ] One H1 with primary keyword
- [ ] Logical heading hierarchy
- [ ] Descriptive image alt text
- [ ] Clean, readable URL
- [ ] Canonical tag set
- [ ] Mobile-friendly
- [ ] Fast loading

### Site-Wide
- [ ] XML sitemap submitted
- [ ] robots.txt configured
- [ ] HTTPS enabled
- [ ] Organization schema
- [ ] Google Search Console connected
- [ ] Core Web Vitals passing
- [ ] Internal linking structure
- [ ] 404 page with navigation

### Content
- [ ] Primary keyword targeted
- [ ] Search intent matched
- [ ] Better than competitors
- [ ] Internal links included
- [ ] External links to authoritative sources
- [ ] Updated/fresh content

---

## Tools

**Free:**
- Google Search Console (essential)
- Google PageSpeed Insights
- Schema Markup Validator
- Lighthouse (Chrome DevTools)

**Paid:**
- Ahrefs / SEMrush (keyword research, competitor analysis)
- Screaming Frog (technical audits)
- Clearscope / Surfer (content optimization)
