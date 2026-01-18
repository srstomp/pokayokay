# UI Development for Figma Plugins

Building plugin user interfaces.

## UI Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    MAIN THREAD (code.ts)                    │
│                                                             │
│   figma.showUI(__html__)                                    │
│         │                                                   │
│         ▼                                                   │
│   ┌─────────────────────────────────────────────────────┐  │
│   │                 UI IFRAME (ui.html)                  │  │
│   │                                                      │  │
│   │   • Full browser environment                         │  │
│   │   • HTML, CSS, JavaScript                            │  │
│   │   • Can use React, Vue, Svelte, etc.                │  │
│   │   • NO access to Figma API                          │  │
│   │   • Communicates via postMessage                     │  │
│   │                                                      │  │
│   └─────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

## Showing UI

### Basic UI

```typescript
// code.ts
figma.showUI(__html__);  // __html__ is replaced with ui.html contents at build

// With options
figma.showUI(__html__, {
  width: 400,
  height: 300,
  title: 'My Plugin',
  visible: true,
  position: { x: 100, y: 100 },
  themeColors: true,  // Use Figma's theme colors
});
```

### UI Options

```typescript
interface ShowUIOptions {
  width?: number;           // Default: 300
  height?: number;          // Default: 200
  visible?: boolean;        // Default: true
  position?: { x: number; y: number };
  title?: string;
  themeColors?: boolean;    // Inject Figma CSS variables
}
```

### Resize UI

```typescript
// From main thread
figma.ui.resize(500, 400);

// From UI (request main thread to resize)
parent.postMessage({
  pluginMessage: { type: 'resize', width: 500, height: 400 }
}, '*');

// code.ts
figma.ui.onmessage = (msg) => {
  if (msg.type === 'resize') {
    figma.ui.resize(msg.width, msg.height);
  }
};
```

---

## Message Communication

### UI → Main Thread

```html
<!-- ui.html -->
<script>
// Send message to main thread
function sendMessage(type, data) {
  parent.postMessage({ pluginMessage: { type, ...data } }, '*');
}

// Examples
sendMessage('create-shape', { shape: 'rectangle', width: 100, height: 50 });
sendMessage('update-color', { color: '#FF5733' });
sendMessage('close');
</script>
```

### Main Thread → UI

```typescript
// code.ts
// Send data to UI
figma.ui.postMessage({
  type: 'selection-data',
  nodes: figma.currentPage.selection.map(node => ({
    id: node.id,
    name: node.name,
    type: node.type,
  })),
});

// Send on selection change
figma.on('selectionchange', () => {
  figma.ui.postMessage({
    type: 'selection-changed',
    count: figma.currentPage.selection.length,
  });
});
```

### Receiving in UI

```html
<script>
window.onmessage = (event) => {
  const msg = event.data.pluginMessage;
  if (!msg) return;
  
  switch (msg.type) {
    case 'selection-data':
      renderNodes(msg.nodes);
      break;
    case 'selection-changed':
      updateCount(msg.count);
      break;
    case 'error':
      showError(msg.message);
      break;
  }
};
</script>
```

### Typed Messages

```typescript
// shared/types.ts
export type MainToUI =
  | { type: 'selection-changed'; count: number }
  | { type: 'node-data'; node: SerializedNode }
  | { type: 'error'; message: string }
  | { type: 'styles-loaded'; styles: StyleData[] };

export type UIToMain =
  | { type: 'create-shape'; shape: 'rectangle' | 'ellipse'; size: number }
  | { type: 'apply-style'; styleId: string }
  | { type: 'close' };

// code.ts
figma.ui.onmessage = (msg: UIToMain) => {
  switch (msg.type) {
    case 'create-shape':
      // TypeScript knows shape and size exist
      break;
  }
};

// ui.ts
declare function postMessage(msg: UIToMain): void;
```

---

## Plain HTML/CSS/JS

### Basic Structure

```html
<!-- ui.html -->
<!DOCTYPE html>
<html>
<head>
  <style>
    * {
      box-sizing: border-box;
      margin: 0;
      padding: 0;
    }
    
    body {
      font-family: Inter, system-ui, sans-serif;
      font-size: 11px;
      color: var(--figma-color-text);
      background: var(--figma-color-bg);
      padding: 12px;
    }
    
    .input-group {
      margin-bottom: 12px;
    }
    
    label {
      display: block;
      margin-bottom: 4px;
      font-weight: 500;
    }
    
    input, select {
      width: 100%;
      padding: 8px;
      border: 1px solid var(--figma-color-border);
      border-radius: 4px;
      background: var(--figma-color-bg);
      color: var(--figma-color-text);
    }
    
    input:focus, select:focus {
      outline: none;
      border-color: var(--figma-color-border-brand);
    }
    
    button {
      padding: 8px 16px;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      font-weight: 500;
    }
    
    .btn-primary {
      background: var(--figma-color-bg-brand);
      color: white;
    }
    
    .btn-secondary {
      background: var(--figma-color-bg-secondary);
      color: var(--figma-color-text);
    }
    
    .btn-row {
      display: flex;
      gap: 8px;
      justify-content: flex-end;
      margin-top: 16px;
    }
  </style>
</head>
<body>
  <div class="input-group">
    <label for="name">Name</label>
    <input type="text" id="name" placeholder="Enter name">
  </div>
  
  <div class="input-group">
    <label for="size">Size</label>
    <input type="number" id="size" value="100" min="1">
  </div>
  
  <div class="btn-row">
    <button class="btn-secondary" id="cancel">Cancel</button>
    <button class="btn-primary" id="create">Create</button>
  </div>
  
  <script>
    const nameInput = document.getElementById('name');
    const sizeInput = document.getElementById('size');
    
    document.getElementById('create').onclick = () => {
      parent.postMessage({
        pluginMessage: {
          type: 'create',
          name: nameInput.value,
          size: parseInt(sizeInput.value, 10),
        }
      }, '*');
    };
    
    document.getElementById('cancel').onclick = () => {
      parent.postMessage({ pluginMessage: { type: 'close' } }, '*');
    };
    
    // Receive messages
    window.onmessage = (event) => {
      const msg = event.data.pluginMessage;
      if (msg?.type === 'update') {
        nameInput.value = msg.name || '';
      }
    };
  </script>
</body>
</html>
```

---

## Using React

### Setup with Create React App

```bash
# Using Figma plugin template
npx degit nicebook/figma-plugin-react-template my-plugin
cd my-plugin
npm install
```

### Manual React Setup

```typescript
// ui.tsx
import React, { useState, useEffect, useCallback } from 'react';
import { createRoot } from 'react-dom/client';
import './ui.css';

// Types
type Message = 
  | { type: 'selection-changed'; count: number }
  | { type: 'node-data'; node: { name: string; type: string } };

function App() {
  const [count, setCount] = useState(0);
  const [name, setName] = useState('');
  const [size, setSize] = useState(100);

  // Listen for messages from main thread
  useEffect(() => {
    const handler = (event: MessageEvent) => {
      const msg = event.data.pluginMessage as Message;
      if (!msg) return;
      
      if (msg.type === 'selection-changed') {
        setCount(msg.count);
      }
    };

    window.addEventListener('message', handler);
    return () => window.removeEventListener('message', handler);
  }, []);

  // Send message to main thread
  const postMessage = useCallback((message: any) => {
    parent.postMessage({ pluginMessage: message }, '*');
  }, []);

  const handleCreate = () => {
    postMessage({ type: 'create', name, size });
  };

  const handleClose = () => {
    postMessage({ type: 'close' });
  };

  return (
    <div className="container">
      <p className="selection-info">
        {count} items selected
      </p>
      
      <div className="input-group">
        <label>Name</label>
        <input 
          type="text" 
          value={name} 
          onChange={(e) => setName(e.target.value)}
        />
      </div>
      
      <div className="input-group">
        <label>Size</label>
        <input 
          type="number" 
          value={size} 
          onChange={(e) => setSize(parseInt(e.target.value, 10))}
        />
      </div>
      
      <div className="btn-row">
        <button className="btn-secondary" onClick={handleClose}>
          Cancel
        </button>
        <button className="btn-primary" onClick={handleCreate}>
          Create
        </button>
      </div>
    </div>
  );
}

const root = createRoot(document.getElementById('root')!);
root.render(<App />);
```

### Custom Hook for Figma Messages

```typescript
// hooks/useFigmaMessage.ts
import { useEffect, useCallback } from 'react';

type MessageHandler<T> = (message: T) => void;

export function useFigmaMessage<T>(handler: MessageHandler<T>) {
  useEffect(() => {
    const listener = (event: MessageEvent) => {
      const msg = event.data.pluginMessage;
      if (msg) {
        handler(msg as T);
      }
    };

    window.addEventListener('message', listener);
    return () => window.removeEventListener('message', listener);
  }, [handler]);
}

export function usePostMessage() {
  return useCallback((message: any) => {
    parent.postMessage({ pluginMessage: message }, '*');
  }, []);
}

// Usage
function App() {
  const [data, setData] = useState(null);
  const postMessage = usePostMessage();

  useFigmaMessage((msg) => {
    if (msg.type === 'data') {
      setData(msg.data);
    }
  });

  return (
    <button onClick={() => postMessage({ type: 'fetch-data' })}>
      Fetch Data
    </button>
  );
}
```

---

## Figma Theme Colors

When `themeColors: true`, Figma injects CSS variables:

```css
/* Available CSS variables */
:root {
  /* Text */
  --figma-color-text: /* primary text */;
  --figma-color-text-secondary: /* secondary text */;
  --figma-color-text-tertiary: /* tertiary text */;
  --figma-color-text-disabled: /* disabled text */;
  --figma-color-text-onbrand: /* text on brand color */;
  --figma-color-text-onbrand-secondary: /* secondary text on brand */;
  --figma-color-text-danger: /* error text */;
  --figma-color-text-warning: /* warning text */;
  --figma-color-text-success: /* success text */;
  
  /* Backgrounds */
  --figma-color-bg: /* primary background */;
  --figma-color-bg-secondary: /* secondary background */;
  --figma-color-bg-tertiary: /* tertiary background */;
  --figma-color-bg-brand: /* brand background */;
  --figma-color-bg-brand-hover: /* brand hover */;
  --figma-color-bg-brand-pressed: /* brand pressed */;
  --figma-color-bg-danger: /* danger background */;
  --figma-color-bg-warning: /* warning background */;
  --figma-color-bg-success: /* success background */;
  --figma-color-bg-hover: /* hover state */;
  --figma-color-bg-pressed: /* pressed state */;
  --figma-color-bg-selected: /* selected state */;
  
  /* Borders */
  --figma-color-border: /* primary border */;
  --figma-color-border-strong: /* strong border */;
  --figma-color-border-brand: /* brand border */;
  --figma-color-border-danger: /* danger border */;
  
  /* Icons */
  --figma-color-icon: /* primary icon */;
  --figma-color-icon-secondary: /* secondary icon */;
  --figma-color-icon-tertiary: /* tertiary icon */;
  --figma-color-icon-brand: /* brand icon */;
  --figma-color-icon-danger: /* danger icon */;
}
```

### Using Theme Colors

```css
/* Automatically adapts to light/dark mode */
body {
  background: var(--figma-color-bg);
  color: var(--figma-color-text);
}

.card {
  background: var(--figma-color-bg-secondary);
  border: 1px solid var(--figma-color-border);
}

.btn-primary {
  background: var(--figma-color-bg-brand);
  color: var(--figma-color-text-onbrand);
}

.btn-primary:hover {
  background: var(--figma-color-bg-brand-hover);
}

.error {
  color: var(--figma-color-text-danger);
  background: var(--figma-color-bg-danger);
}
```

---

## Common UI Patterns

### Loading State

```html
<div id="loading" class="loading">
  <div class="spinner"></div>
  <p>Loading...</p>
</div>

<div id="content" class="hidden">
  <!-- Main content -->
</div>

<style>
.hidden { display: none; }

.loading {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 100%;
}

.spinner {
  width: 24px;
  height: 24px;
  border: 2px solid var(--figma-color-border);
  border-top-color: var(--figma-color-bg-brand);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}
</style>

<script>
window.onmessage = (event) => {
  const msg = event.data.pluginMessage;
  if (msg?.type === 'ready') {
    document.getElementById('loading').classList.add('hidden');
    document.getElementById('content').classList.remove('hidden');
  }
};
</script>
```

### Tabs

```html
<div class="tabs">
  <button class="tab active" data-tab="settings">Settings</button>
  <button class="tab" data-tab="export">Export</button>
  <button class="tab" data-tab="about">About</button>
</div>

<div class="tab-content active" id="settings">
  <!-- Settings content -->
</div>
<div class="tab-content" id="export">
  <!-- Export content -->
</div>
<div class="tab-content" id="about">
  <!-- About content -->
</div>

<style>
.tabs {
  display: flex;
  border-bottom: 1px solid var(--figma-color-border);
  margin-bottom: 12px;
}

.tab {
  padding: 8px 16px;
  background: none;
  border: none;
  cursor: pointer;
  color: var(--figma-color-text-secondary);
  border-bottom: 2px solid transparent;
  margin-bottom: -1px;
}

.tab.active {
  color: var(--figma-color-text);
  border-bottom-color: var(--figma-color-bg-brand);
}

.tab-content {
  display: none;
}

.tab-content.active {
  display: block;
}
</style>

<script>
document.querySelectorAll('.tab').forEach(tab => {
  tab.onclick = () => {
    // Update tabs
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    tab.classList.add('active');
    
    // Update content
    document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
    document.getElementById(tab.dataset.tab).classList.add('active');
  };
});
</script>
```

### Color Picker

```html
<div class="color-picker">
  <input type="color" id="color" value="#0066FF">
  <input type="text" id="color-hex" value="#0066FF" maxlength="7">
</div>

<style>
.color-picker {
  display: flex;
  gap: 8px;
}

input[type="color"] {
  width: 32px;
  height: 32px;
  padding: 0;
  border: 1px solid var(--figma-color-border);
  border-radius: 4px;
  cursor: pointer;
}

input[type="color"]::-webkit-color-swatch-wrapper {
  padding: 2px;
}

input[type="color"]::-webkit-color-swatch {
  border-radius: 2px;
  border: none;
}
</style>

<script>
const colorInput = document.getElementById('color');
const hexInput = document.getElementById('color-hex');

colorInput.oninput = () => {
  hexInput.value = colorInput.value.toUpperCase();
};

hexInput.oninput = () => {
  if (/^#[0-9A-Fa-f]{6}$/.test(hexInput.value)) {
    colorInput.value = hexInput.value;
  }
};
</script>
```

### Node List

```html
<ul id="node-list" class="node-list"></ul>

<style>
.node-list {
  list-style: none;
  max-height: 200px;
  overflow-y: auto;
  border: 1px solid var(--figma-color-border);
  border-radius: 4px;
}

.node-item {
  padding: 8px 12px;
  display: flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  border-bottom: 1px solid var(--figma-color-border);
}

.node-item:last-child {
  border-bottom: none;
}

.node-item:hover {
  background: var(--figma-color-bg-hover);
}

.node-item.selected {
  background: var(--figma-color-bg-selected);
}

.node-icon {
  width: 16px;
  height: 16px;
  opacity: 0.6;
}

.node-name {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
</style>

<script>
window.onmessage = (event) => {
  const msg = event.data.pluginMessage;
  if (msg?.type === 'nodes') {
    renderNodes(msg.nodes);
  }
};

function renderNodes(nodes) {
  const list = document.getElementById('node-list');
  list.innerHTML = nodes.map(node => `
    <li class="node-item" data-id="${node.id}">
      <span class="node-icon">${getIcon(node.type)}</span>
      <span class="node-name">${node.name}</span>
    </li>
  `).join('');
  
  list.querySelectorAll('.node-item').forEach(item => {
    item.onclick = () => {
      parent.postMessage({
        pluginMessage: { type: 'select-node', id: item.dataset.id }
      }, '*');
    };
  });
}

function getIcon(type) {
  const icons = {
    FRAME: '⬜',
    TEXT: 'T',
    RECTANGLE: '▢',
    ELLIPSE: '○',
    COMPONENT: '◇',
    INSTANCE: '◆',
  };
  return icons[type] || '•';
}
</script>
```

---

## File Downloads

```typescript
// code.ts - Export and send to UI
const bytes = await node.exportAsync({ format: 'PNG' });
figma.ui.postMessage({
  type: 'download',
  bytes: Array.from(bytes),
  filename: `${node.name}.png`,
  mimeType: 'image/png',
});
```

```html
<!-- ui.html -->
<script>
window.onmessage = (event) => {
  const msg = event.data.pluginMessage;
  if (msg?.type === 'download') {
    downloadFile(msg.bytes, msg.filename, msg.mimeType);
  }
};

function downloadFile(bytes, filename, mimeType) {
  const blob = new Blob([new Uint8Array(bytes)], { type: mimeType });
  const url = URL.createObjectURL(blob);
  
  const link = document.createElement('a');
  link.href = url;
  link.download = filename;
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  
  URL.revokeObjectURL(url);
}
</script>
```

---

## External Resources

```html
<!-- Load external fonts -->
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600&display=swap" rel="stylesheet">

<!-- Load external scripts (bundled is preferred) -->
<script src="https://cdn.jsdelivr.net/npm/lodash@4.17.21/lodash.min.js"></script>

<!-- Note: Be careful with external resources -->
<!-- - They require internet connection -->
<!-- - May slow down plugin load -->
<!-- - Bundle when possible for better UX -->
```
