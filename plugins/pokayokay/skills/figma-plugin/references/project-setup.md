# Figma Plugin Project Setup

Configuration, building, and publishing your plugin.

## Project Structure

### Minimal Structure

```
my-plugin/
├── manifest.json      # Plugin configuration
├── code.ts            # Main thread code
├── ui.html            # UI (optional)
└── package.json       # Dependencies
```

### Recommended Structure

```
my-plugin/
├── manifest.json
├── package.json
├── tsconfig.json
├── esbuild.config.js   # or webpack/vite config
│
├── src/
│   ├── code.ts         # Main entry point
│   ├── ui.tsx          # UI entry point (React)
│   ├── types.ts        # Shared types
│   │
│   ├── features/       # Feature modules
│   │   ├── rename.ts
│   │   └── export.ts
│   │
│   └── utils/          # Utilities
│       ├── colors.ts
│       └── traversal.ts
│
├── ui/
│   ├── components/     # UI components
│   ├── hooks/          # React hooks
│   └── styles/         # CSS
│
└── dist/               # Build output
    ├── code.js
    └── ui.html
```

---

## manifest.json

### Minimal Manifest

```json
{
  "name": "My Plugin",
  "id": "1234567890",
  "api": "1.0.0",
  "main": "code.js",
  "ui": "ui.html",
  "editorType": ["figma"]
}
```

### Complete Manifest

```json
{
  "name": "My Plugin",
  "id": "1234567890123456789",
  "api": "1.0.0",
  "main": "dist/code.js",
  "ui": "dist/ui.html",
  "editorType": ["figma", "figjam"],
  
  "capabilities": [],
  "enableProposedApi": false,
  "enablePrivatePluginApi": false,
  
  "menu": [
    {
      "name": "Run Plugin",
      "command": "run"
    },
    { "separator": true },
    {
      "name": "Settings",
      "command": "settings"
    },
    {
      "name": "Help",
      "command": "help"
    }
  ],
  
  "relaunchButtons": [
    {
      "command": "refresh",
      "name": "Refresh",
      "multipleSelection": true
    }
  ],
  
  "parameters": [
    {
      "name": "text",
      "key": "text",
      "description": "Text to insert",
      "allowFreeform": true
    }
  ],
  
  "parameterOnly": false,
  
  "documentAccess": "dynamic-page",
  
  "networkAccess": {
    "allowedDomains": ["api.example.com"],
    "reasoning": "Fetch data from our API"
  },
  
  "codegenLanguages": [
    {
      "label": "React",
      "value": "react"
    }
  ],
  
  "codegenPreferences": [
    {
      "itemType": "unit",
      "propertyName": "unitType",
      "label": "Unit Type",
      "options": [
        { "label": "Pixels", "value": "px", "isDefault": true },
        { "label": "REM", "value": "rem" }
      ]
    }
  ]
}
```

### Manifest Fields Reference

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Plugin name |
| `id` | Yes | Unique plugin ID (assigned by Figma) |
| `api` | Yes | API version |
| `main` | Yes | Path to main code file |
| `ui` | No | Path to UI HTML file |
| `editorType` | No | `["figma"]`, `["figjam"]`, or both |
| `menu` | No | Custom menu items |
| `relaunchButtons` | No | Buttons that persist on nodes |
| `parameters` | No | Quick action parameters |
| `documentAccess` | No | `"dynamic-page"` for large docs |
| `networkAccess` | No | Required for network requests |

### Menu Commands

```json
{
  "menu": [
    { "name": "Create Frame", "command": "create-frame" },
    { "name": "Create Text", "command": "create-text" },
    { "separator": true },
    {
      "name": "Utilities",
      "menu": [
        { "name": "Rename Layers", "command": "rename" },
        { "name": "Cleanup", "command": "cleanup" }
      ]
    }
  ]
}
```

```typescript
// code.ts
figma.on('run', ({ command }) => {
  switch (command) {
    case 'create-frame':
      createFrame();
      break;
    case 'create-text':
      createText();
      break;
    case 'rename':
      figma.showUI(__html__, { width: 300, height: 200 });
      break;
    default:
      figma.showUI(__html__);
  }
});
```

---

## TypeScript Setup

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noEmit": true,
    "skipLibCheck": true,
    "types": ["@figma/plugin-typings"]
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

### tsconfig.ui.json (for UI with DOM)

```json
{
  "extends": "./tsconfig.json",
  "compilerOptions": {
    "lib": ["ES2020", "DOM"],
    "types": ["@figma/plugin-typings"],
    "jsx": "react-jsx"
  },
  "include": ["src/ui.tsx", "ui/**/*"]
}
```

### Type Definitions

```bash
npm install --save-dev @figma/plugin-typings typescript
```

---

## Build Configuration

### esbuild (Recommended)

```javascript
// esbuild.config.js
const esbuild = require('esbuild');
const fs = require('fs');

// Build main thread code
esbuild.buildSync({
  entryPoints: ['src/code.ts'],
  bundle: true,
  outfile: 'dist/code.js',
  target: 'es2020',
  format: 'iife',
});

// Build UI
esbuild.buildSync({
  entryPoints: ['src/ui.tsx'],
  bundle: true,
  outfile: 'dist/ui.js',
  target: 'es2020',
  format: 'iife',
  loader: {
    '.tsx': 'tsx',
    '.css': 'css',
  },
});

// Inline JS into HTML
const uiJs = fs.readFileSync('dist/ui.js', 'utf8');
const uiHtml = `
<!DOCTYPE html>
<html>
<head>
  <style>
    ${fs.readFileSync('ui/styles/main.css', 'utf8')}
  </style>
</head>
<body>
  <div id="root"></div>
  <script>${uiJs}</script>
</body>
</html>
`;
fs.writeFileSync('dist/ui.html', uiHtml);
```

### package.json Scripts

```json
{
  "scripts": {
    "build": "node esbuild.config.js",
    "watch": "node esbuild.config.js --watch",
    "dev": "npm run watch",
    "typecheck": "tsc --noEmit",
    "lint": "eslint src/**/*.ts"
  },
  "devDependencies": {
    "@figma/plugin-typings": "^1.0.0",
    "esbuild": "^0.19.0",
    "typescript": "^5.0.0"
  }
}
```

### Vite Configuration

```typescript
// vite.config.ts
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      input: {
        ui: resolve(__dirname, 'src/ui.tsx'),
      },
      output: {
        entryFileNames: '[name].js',
      },
    },
    outDir: 'dist',
    emptyOutDir: false,
  },
});
```

### Webpack Configuration

```javascript
// webpack.config.js
const HtmlWebpackPlugin = require('html-webpack-plugin');
const HtmlInlineScriptPlugin = require('html-inline-script-webpack-plugin');
const path = require('path');

module.exports = [
  // Main thread
  {
    entry: './src/code.ts',
    output: {
      filename: 'code.js',
      path: path.resolve(__dirname, 'dist'),
    },
    module: {
      rules: [
        {
          test: /\.tsx?$/,
          use: 'ts-loader',
          exclude: /node_modules/,
        },
      ],
    },
    resolve: {
      extensions: ['.tsx', '.ts', '.js'],
    },
  },
  // UI
  {
    entry: './src/ui.tsx',
    output: {
      filename: 'ui.js',
      path: path.resolve(__dirname, 'dist'),
    },
    module: {
      rules: [
        {
          test: /\.tsx?$/,
          use: 'ts-loader',
          exclude: /node_modules/,
        },
        {
          test: /\.css$/,
          use: ['style-loader', 'css-loader'],
        },
      ],
    },
    resolve: {
      extensions: ['.tsx', '.ts', '.js'],
    },
    plugins: [
      new HtmlWebpackPlugin({
        template: './src/ui.html',
        filename: 'ui.html',
        inject: 'body',
      }),
      new HtmlInlineScriptPlugin(),
    ],
  },
];
```

---

## Development Workflow

### Local Development

1. **Open Figma Desktop**
2. **Plugins → Development → Import plugin from manifest**
3. **Select your `manifest.json`**
4. **Run `npm run watch`** in terminal
5. **Make changes** → Save → **Plugins → Development → Your Plugin**
6. **Use Console** (Plugins → Development → Show/Hide Console)

### Hot Reload (Sort of)

Figma doesn't support true hot reload. Workaround:

```typescript
// code.ts - During development
figma.showUI(__html__, { width: 400, height: 300 });

// Close and reopen to see changes
// Keyboard shortcut: Cmd/Ctrl + Alt + P (run last plugin)
```

### Console Logging

```typescript
// Main thread - appears in Figma console
console.log('Main thread log');

// UI thread - appears in browser console
// View with: Plugins → Development → Show/Hide Console
console.log('UI log');
```

---

## Testing

### Manual Testing Checklist

- [ ] Plugin loads without errors
- [ ] UI displays correctly
- [ ] Selection handling works
- [ ] Empty selection handled
- [ ] Large selection handled
- [ ] Error states handled
- [ ] Cancel/close works
- [ ] Undo works after plugin actions
- [ ] Works in both light and dark themes

### Automated Testing

```typescript
// __tests__/utils.test.ts
import { hexToRgb, rgbToHex } from '../src/utils/colors';

describe('hexToRgb', () => {
  test('converts hex to RGB', () => {
    expect(hexToRgb('#FF0000')).toEqual({ r: 1, g: 0, b: 0 });
    expect(hexToRgb('#00FF00')).toEqual({ r: 0, g: 1, b: 0 });
    expect(hexToRgb('#0000FF')).toEqual({ r: 0, g: 0, b: 1 });
  });
});
```

```json
// package.json
{
  "scripts": {
    "test": "jest"
  },
  "devDependencies": {
    "jest": "^29.0.0",
    "@types/jest": "^29.0.0",
    "ts-jest": "^29.0.0"
  }
}
```

### Mock Figma API

```typescript
// __mocks__/figma.ts
export const figma = {
  currentPage: {
    selection: [],
    findAll: jest.fn(() => []),
    findOne: jest.fn(() => null),
  },
  createRectangle: jest.fn(() => ({
    type: 'RECTANGLE',
    x: 0,
    y: 0,
    resize: jest.fn(),
  })),
  notify: jest.fn(),
  closePlugin: jest.fn(),
  ui: {
    postMessage: jest.fn(),
    onmessage: null,
  },
};

// jest.setup.ts
(global as any).figma = figma;
```

---

## Publishing

### Prepare for Publishing

1. **Create cover image** (1920×960)
2. **Create icon** (128×128)
3. **Write description**
4. **Test thoroughly**
5. **Build production bundle**

### manifest.json for Publishing

```json
{
  "name": "My Awesome Plugin",
  "id": "1234567890123456789",
  "api": "1.0.0",
  "main": "dist/code.js",
  "ui": "dist/ui.html",
  "editorType": ["figma"]
}
```

### Publishing Steps

1. **Go to Figma** → Plugins → Manage plugins
2. **Find your development plugin**
3. **Click "Publish"**
4. **Fill in details:**
   - Name (up to 50 characters)
   - Tagline (up to 100 characters)
   - Description (markdown supported)
   - Cover image
   - Categories
   - Tags
5. **Submit for review**

### Review Guidelines

Figma reviews plugins for:
- **Security**: No malicious code
- **Privacy**: Clear data handling
- **Quality**: Works as described
- **Guidelines**: Follows community guidelines

Common rejection reasons:
- Plugin crashes or has major bugs
- Missing or misleading description
- Inappropriate content
- Privacy policy issues (if collecting data)

### Updating Published Plugin

1. **Update version** in code if tracking
2. **Build production bundle**
3. **Go to Figma** → Plugins → Manage plugins
4. **Click "Edit"** on your plugin
5. **Upload new files**
6. **Update description if needed**
7. **Submit update**

---

## Common Issues

### "Plugin timed out"

```typescript
// PROBLEM: Long-running operation
for (let i = 0; i < 10000; i++) {
  figma.createRectangle();
}

// SOLUTION: Batch with yields
async function createMany(count: number) {
  for (let i = 0; i < count; i += 100) {
    for (let j = 0; j < Math.min(100, count - i); j++) {
      figma.createRectangle();
    }
    await new Promise(r => setTimeout(r, 0));
  }
}
```

### "Cannot read properties of null"

```typescript
// PROBLEM: Not checking for null
const node = figma.currentPage.selection[0];
node.name = 'New name'; // Crashes if nothing selected

// SOLUTION: Check first
const selection = figma.currentPage.selection;
if (selection.length === 0) {
  figma.notify('Select something first');
  return;
}
const node = selection[0];
```

### "Font not loaded"

```typescript
// PROBLEM: Modifying text without loading font
const text = figma.createText();
text.characters = 'Hello'; // Error!

// SOLUTION: Load font first
const text = figma.createText();
await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
text.characters = 'Hello';
```

### UI Not Showing

```typescript
// PROBLEM: Missing __html__
figma.showUI('<html>...</html>'); // Won't work

// SOLUTION: Use __html__ (replaced at build time)
figma.showUI(__html__);

// Or for inline HTML (development only)
figma.showUI(`<html><body>Hello</body></html>`, { width: 200, height: 100 });
```

### Network Requests Blocked

```json
// manifest.json - Add network access
{
  "networkAccess": {
    "allowedDomains": ["api.example.com"],
    "reasoning": "Fetch data from our API"
  }
}
```

---

## Templates & Starters

### Official Templates

```bash
# Create React App template
npx create-react-app my-plugin --template figma-plugin

# Figma's official starter
# Download from: https://www.figma.com/plugin-docs/setup/
```

### Community Templates

```bash
# TypeScript + esbuild
npx degit nicebook/figma-plugin-typescript-template my-plugin

# React + TypeScript
npx degit nicebook/figma-plugin-react-template my-plugin

# Svelte
npx degit nicebook/figma-plugin-svelte-template my-plugin
```

### Minimal Starter

```bash
mkdir my-plugin && cd my-plugin
npm init -y
npm install --save-dev @figma/plugin-typings typescript esbuild
```

Create files:
- `manifest.json` (copy from above)
- `src/code.ts`
- `tsconfig.json` (copy from above)
- `esbuild.config.js` (copy from above)
