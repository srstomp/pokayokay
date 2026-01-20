# Framework Patterns

Scanning patterns for different frontend and mobile frameworks. Each framework has unique conventions for routes, navigation, and API integration.

## Framework Detection

### Detection Script

```bash
#!/bin/bash
# Detect project framework

detect_framework() {
    # Next.js
    if [ -f "next.config.js" ] || [ -f "next.config.mjs" ] || [ -f "next.config.ts" ]; then
        if [ -d "app" ] && [ -f "app/layout.tsx" ]; then
            echo "nextjs-app"
        else
            echo "nextjs-pages"
        fi
        return
    fi
    
    # Remix
    if [ -f "remix.config.js" ] || [ -d "app/routes" ]; then
        echo "remix"
        return
    fi
    
    # Vite-based (check for router)
    if [ -f "vite.config.ts" ] || [ -f "vite.config.js" ]; then
        if grep -q "@tanstack/react-router" package.json 2>/dev/null; then
            echo "tanstack-router"
        elif grep -q "react-router" package.json 2>/dev/null; then
            echo "react-router"
        else
            echo "vite-spa"
        fi
        return
    fi
    
    # Expo
    if [ -f "app.json" ] && grep -q "expo" app.json 2>/dev/null; then
        if [ -d "app" ] && [ -f "app/_layout.tsx" ]; then
            echo "expo-router"
        else
            echo "expo"
        fi
        return
    fi
    
    # React Native (non-Expo)
    if [ -f "react-native.config.js" ] || ([ -d "ios" ] && [ -d "android" ]); then
        echo "react-native"
        return
    fi
    
    # Astro
    if [ -f "astro.config.mjs" ]; then
        echo "astro"
        return
    fi
    
    # Generic React (Create React App or custom)
    if [ -f "package.json" ] && grep -q '"react"' package.json; then
        echo "react-generic"
        return
    fi
    
    echo "unknown"
}

detect_framework
```

---

## Next.js (App Router)

### Structure
```
app/
├── layout.tsx          # Root layout with navigation
├── page.tsx            # Home page
├── dashboard/
│   ├── layout.tsx      # Dashboard layout
│   ├── page.tsx        # /dashboard
│   └── analytics/
│       └── page.tsx    # /dashboard/analytics
├── api/
│   └── analytics/
│       └── route.ts    # API route
└── (marketing)/        # Route group
    └── about/
        └── page.tsx    # /about
```

### Route Discovery
```bash
# Find all pages (routes)
find app -name "page.tsx" -o -name "page.js" | sort

# Extract route paths
find app -name "page.tsx" | sed 's|app||; s|/page.tsx||; s|/\(.*\)|/\1|'

# Find API routes
find app/api -name "route.ts" -o -name "route.js" 2>/dev/null
```

### Navigation Discovery
```bash
# Check root layout for nav
grep -A 50 "export default" app/layout.tsx | grep -E "Link|href="

# Find navigation components
find . -path "*/components/*" -name "*[Nn]av*" -o -name "*[Ss]idebar*" -o -name "*[Mm]enu*"

# Check for nav links
grep -r "href=\"/" --include="*.tsx" app/ src/components/
```

### API Integration
```bash
# Find fetch calls
grep -r "fetch\s*(" --include="*.tsx" app/ | grep -v node_modules

# Find server actions
grep -r "use server" --include="*.ts" --include="*.tsx" app/

# Find API route usage
grep -r "/api/" --include="*.tsx" app/ src/
```

---

## Next.js (Pages Router)

### Structure
```
pages/
├── _app.tsx            # App wrapper
├── _document.tsx       # Document wrapper
├── index.tsx           # Home (/)
├── dashboard/
│   ├── index.tsx       # /dashboard
│   └── analytics.tsx   # /dashboard/analytics
└── api/
    └── analytics.ts    # /api/analytics
```

### Route Discovery
```bash
# Find all pages
find pages -name "*.tsx" -o -name "*.js" | grep -v "_app\|_document\|_error\|api/"

# API routes
find pages/api -name "*.ts" -o -name "*.js" 2>/dev/null
```

### Navigation Discovery
```bash
# Check _app for global nav
grep -A 100 "export default" pages/_app.tsx | grep -E "Link|href="

# Find nav components
find components -name "*[Nn]av*" -o -name "*[Ss]idebar*"

# Check for links
grep -r "from 'next/link'" --include="*.tsx" -l | xargs grep -l "href="
```

---

## React Router (v6)

### Structure
```
src/
├── main.tsx            # Entry with RouterProvider
├── routes.tsx          # Route definitions
├── routes/
│   ├── root.tsx        # Root layout
│   ├── dashboard.tsx   # /dashboard
│   └── analytics.tsx   # /analytics
├── components/
│   └── Navigation.tsx
└── services/
    └── api.ts
```

### Route Discovery
```bash
# Find route definitions
find src -name "routes.tsx" -o -name "router.tsx" -o -name "Routes.tsx"

# Parse routes from file
grep -E "path:\s*['\"]|<Route.*path=" src/routes.tsx src/App.tsx 2>/dev/null

# Find route components
grep -r "createBrowserRouter\|<Routes>" --include="*.tsx" src/
```

### Navigation Discovery
```bash
# Find Link usage
grep -r "from 'react-router-dom'" --include="*.tsx" -l | xargs grep -E "<Link|<NavLink"

# Find useNavigate
grep -r "useNavigate" --include="*.tsx" src/

# Navigation components
find src/components -name "*[Nn]av*"
```

### API Integration
```bash
# Find loaders and actions
grep -r "loader:\|action:" --include="*.tsx" src/routes/

# Find fetch/axios usage
grep -r "fetch\|axios\|useMutation\|useQuery" --include="*.tsx" src/
```

---

## TanStack Router

### Structure
```
src/
├── main.tsx
├── routes/
│   ├── __root.tsx      # Root layout
│   ├── index.tsx       # Home
│   ├── dashboard/
│   │   ├── index.tsx   # /dashboard
│   │   └── analytics.tsx  # /dashboard/analytics
│   └── _authenticated/  # Route group (requires auth)
│       └── settings.tsx
├── routeTree.gen.ts    # Generated route tree
└── components/
```

### Route Discovery
```bash
# Find route files
find src/routes -name "*.tsx" | sort

# Check generated route tree
cat src/routeTree.gen.ts 2>/dev/null | grep "path:"

# Find route definitions
grep -r "createFileRoute\|createRootRoute" --include="*.tsx" src/routes/
```

### Navigation Discovery
```bash
# Find Link usage
grep -r "from '@tanstack/react-router'" --include="*.tsx" -l | xargs grep "<Link"

# Find useNavigate
grep -r "useNavigate\|useRouter" --include="*.tsx" src/

# Check root layout
grep -A 50 "createRootRoute" src/routes/__root.tsx
```

---

## Remix

### Structure
```
app/
├── root.tsx            # Root with navigation
├── routes/
│   ├── _index.tsx      # Home (/)
│   ├── dashboard.tsx   # /dashboard (layout)
│   ├── dashboard._index.tsx  # /dashboard
│   ├── dashboard.analytics.tsx  # /dashboard/analytics
│   └── api.analytics.tsx  # /api/analytics
└── components/
```

### Route Discovery
```bash
# Find all routes
find app/routes -name "*.tsx" | sort

# Parse route paths from filenames
find app/routes -name "*.tsx" | sed 's|app/routes/||; s|\.tsx||; s|\.|/|g; s|_index||'

# Find loaders/actions (data functions)
grep -r "export.*loader\|export.*action" --include="*.tsx" app/routes/
```

### Navigation Discovery
```bash
# Check root.tsx for nav
grep -A 100 "export default" app/root.tsx | grep -E "Link|NavLink"

# Find Link usage
grep -r "from '@remix-run/react'" --include="*.tsx" -l | xargs grep -E "<Link|<NavLink"
```

---

## React Native (Vanilla)

### Structure
```
src/
├── App.tsx
├── navigation/
│   ├── index.tsx       # Navigator setup
│   ├── MainNavigator.tsx
│   └── types.ts
├── screens/
│   ├── HomeScreen.tsx
│   ├── DashboardScreen.tsx
│   └── AnalyticsScreen.tsx
├── components/
└── services/
    └── api.ts
```

### Screen Discovery
```bash
# Find all screens
find src/screens -name "*Screen.tsx" -o -name "*Screen.js"

# Find screen registrations in navigator
grep -r "Screen\s*name=\|createStackNavigator\|createBottomTabNavigator" --include="*.tsx" src/navigation/
```

### Navigation Discovery
```bash
# Find navigator files
find src/navigation -name "*.tsx"

# Find tab bar items
grep -r "Tab.Screen\|tabBarIcon\|tabBarLabel" --include="*.tsx" src/

# Find navigation.navigate calls
grep -r "navigation.navigate\|useNavigation" --include="*.tsx" src/
```

### API Integration
```bash
# Find API calls
grep -r "fetch\|axios" --include="*.tsx" --include="*.ts" src/services/ src/api/

# Find React Query usage
grep -r "useQuery\|useMutation" --include="*.tsx" src/
```

---

## Expo (with React Navigation)

### Structure
```
src/
├── app/                # or just screens at root
│   └── ...
├── navigation/
│   ├── index.tsx
│   └── MainTabNavigator.tsx
├── screens/
│   ├── HomeScreen.tsx
│   └── AnalyticsScreen.tsx
└── services/
```

### Detection
```bash
# Check app.json for expo
grep -q '"expo"' app.json && echo "expo detected"

# Check for Expo Router
[ -d "app" ] && [ -f "app/_layout.tsx" ] && echo "expo-router"
```

### Screen Discovery
```bash
# Same as React Native
find src/screens -name "*Screen.tsx"
find . -path "*/screens/*" -name "*.tsx"
```

---

## Expo Router

### Structure
```
app/
├── _layout.tsx         # Root layout
├── index.tsx           # Home
├── (tabs)/             # Tab group
│   ├── _layout.tsx     # Tab layout
│   ├── index.tsx       # First tab
│   └── analytics.tsx   # Analytics tab
├── dashboard/
│   └── index.tsx
└── [...missing].tsx    # 404
```

### Route Discovery
```bash
# Find all routes
find app -name "*.tsx" -not -name "_*" | sort

# Find layouts (contain navigation)
find app -name "_layout.tsx"

# Parse routes from structure
find app -name "*.tsx" -not -name "_*" | sed 's|^app||; s|/index\.tsx$||; s|\.tsx$||'
```

### Navigation Discovery
```bash
# Check layouts for tabs/navigation
grep -r "Tabs\|Stack\|Drawer" --include="_layout.tsx" app/

# Find Link usage
grep -r "from 'expo-router'" --include="*.tsx" -l | xargs grep -E "<Link|useRouter"

# Find tab definitions
grep -r "Tabs.Screen" --include="*.tsx" app/
```

---

## Astro

### Structure
```
src/
├── layouts/
│   └── MainLayout.astro
├── pages/
│   ├── index.astro     # Home
│   ├── dashboard/
│   │   └── index.astro
│   └── api/
│       └── analytics.ts
├── components/
│   └── Navigation.astro
└── content/
```

### Route Discovery
```bash
# Find pages
find src/pages -name "*.astro" -o -name "*.md" -o -name "*.mdx"

# Find API routes
find src/pages/api -name "*.ts" -o -name "*.js"
```

### Navigation Discovery
```bash
# Check layouts for nav
grep -A 50 "<nav\|<Nav" src/layouts/*.astro

# Find navigation components
find src/components -iname "*nav*"

# Find links
grep -r 'href="/' --include="*.astro" src/
```

---

## Backend Patterns

### Separate Backend (Express/Fastify/Hono)

```
backend/
├── src/
│   ├── index.ts        # Entry
│   ├── routes/         # Route handlers
│   │   ├── analytics.ts
│   │   └── users.ts
│   ├── handlers/       # Alternative structure
│   ├── services/       # Business logic
│   │   └── analytics-service.ts
│   ├── models/         # Data models
│   └── middleware/
└── package.json
```

### Discovery
```bash
# Find services
find backend/src/services -name "*.ts" | sort

# Find route definitions
grep -r "router\.\|app\.\(get\|post\|put\|delete\)" --include="*.ts" backend/src/

# Find handler exports
grep -r "export.*function\|export.*const.*=" --include="*.ts" backend/src/handlers/
```

---

## API Integration Patterns

### How Frontend Calls Backend

| Framework | Typical Pattern |
|-----------|-----------------|
| Next.js (App) | Server Components, Server Actions, Route Handlers |
| Next.js (Pages) | getServerSideProps, API routes, client fetch |
| React Router | Loaders/Actions, fetch in components |
| TanStack Router | Loaders, React Query |
| Remix | Loaders/Actions (server-side) |
| React Native | fetch, axios, React Query |
| Expo | Same as React Native |

### Finding API Calls

```bash
# Generic fetch
grep -r "fetch\s*(" --include="*.tsx" --include="*.ts" src/

# Axios
grep -r "axios\." --include="*.tsx" --include="*.ts" src/

# React Query / TanStack Query
grep -r "useQuery\|useMutation\|queryClient" --include="*.tsx" src/

# SWR
grep -r "useSWR" --include="*.tsx" src/

# tRPC
grep -r "trpc\." --include="*.tsx" src/

# GraphQL
grep -r "useQuery\|useMutation\|gql\`" --include="*.tsx" src/
```

---

## Quick Reference: Scanning Commands

### Find Routes

| Framework | Command |
|-----------|---------|
| Next.js App | `find app -name "page.tsx"` |
| Next.js Pages | `find pages -name "*.tsx" \| grep -v "^_"` |
| React Router | `grep -E "path:" src/routes.tsx` |
| TanStack | `find src/routes -name "*.tsx"` |
| Remix | `find app/routes -name "*.tsx"` |
| Expo Router | `find app -name "*.tsx" -not -name "_*"` |
| React Native | `find src/screens -name "*Screen.tsx"` |

### Find Navigation

| Framework | Command |
|-----------|---------|
| Next.js | `grep -r "href=" app/layout.tsx src/components/*nav*` |
| React Router | `grep -r "<Link\|<NavLink" src/components/` |
| Remix | `grep -r "<Link\|<NavLink" app/root.tsx` |
| React Native | `grep -r "Tab.Screen\|navigation.navigate" src/navigation/` |
| Expo Router | `grep -r "Tabs.Screen\|<Link" app/` |

### Find API Connections

| Pattern | Command |
|---------|---------|
| Fetch to backend | `grep -r "fetch.*api/\|fetch.*localhost" --include="*.tsx" src/` |
| Service imports | `grep -r "from.*services\|from.*api" --include="*.tsx" src/` |
| Endpoint URLs | `grep -rE "https?://\|/api/" --include="*.tsx" src/` |
