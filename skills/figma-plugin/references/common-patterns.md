# Common Figma Plugin Patterns

Reusable patterns for common plugin tasks.

## Selection Handling

### Get Typed Selection

```typescript
// Get all text nodes in selection
function getSelectedTextNodes(): TextNode[] {
  return figma.currentPage.selection.filter(
    (node): node is TextNode => node.type === 'TEXT'
  );
}

// Get all nodes with fills
function getSelectedNodesWithFills(): (SceneNode & GeometryMixin)[] {
  return figma.currentPage.selection.filter(
    (node): node is SceneNode & GeometryMixin => 'fills' in node
  );
}

// Get frames only
function getSelectedFrames(): FrameNode[] {
  return figma.currentPage.selection.filter(
    (node): node is FrameNode => node.type === 'FRAME'
  );
}
```

### Selection Guard

```typescript
function requireSelection(minCount: number = 1): SceneNode[] {
  const selection = figma.currentPage.selection;
  
  if (selection.length < minCount) {
    figma.notify(`Please select at least ${minCount} item(s)`);
    figma.closePlugin();
    return [];
  }
  
  return [...selection];
}

function requireSingleSelection(): SceneNode | null {
  const selection = figma.currentPage.selection;
  
  if (selection.length !== 1) {
    figma.notify('Please select exactly one item');
    return null;
  }
  
  return selection[0];
}

// Usage
const nodes = requireSelection(1);
if (nodes.length === 0) return;

// Process nodes...
```

### Selection Change Listener

```typescript
// Debounced selection handler
let selectionTimeout: number | null = null;

figma.on('selectionchange', () => {
  if (selectionTimeout) clearTimeout(selectionTimeout);
  
  selectionTimeout = setTimeout(() => {
    const selection = figma.currentPage.selection;
    
    figma.ui.postMessage({
      type: 'selection',
      nodes: selection.map(node => ({
        id: node.id,
        name: node.name,
        type: node.type,
      })),
    });
  }, 100);
});
```

---

## Node Traversal

### Recursive Children

```typescript
// Get all descendants
function getAllChildren(node: SceneNode): SceneNode[] {
  const children: SceneNode[] = [];
  
  function traverse(n: SceneNode) {
    children.push(n);
    if ('children' in n) {
      for (const child of n.children) {
        traverse(child);
      }
    }
  }
  
  traverse(node);
  return children;
}

// Get all descendants of a type
function findAllOfType<T extends SceneNode>(
  node: SceneNode,
  type: NodeType
): T[] {
  const results: T[] = [];
  
  function traverse(n: SceneNode) {
    if (n.type === type) {
      results.push(n as T);
    }
    if ('children' in n) {
      for (const child of n.children) {
        traverse(child);
      }
    }
  }
  
  traverse(node);
  return results;
}

// Usage
const allText = findAllOfType<TextNode>(frame, 'TEXT');
```

### Walk Up (Find Parent)

```typescript
// Find parent of type
function findParentOfType<T extends BaseNode>(
  node: SceneNode,
  type: NodeType
): T | null {
  let current: BaseNode | null = node.parent;
  
  while (current) {
    if (current.type === type) {
      return current as T;
    }
    current = current.parent;
  }
  
  return null;
}

// Find parent frame
function findParentFrame(node: SceneNode): FrameNode | null {
  return findParentOfType<FrameNode>(node, 'FRAME');
}

// Find parent component
function findParentComponent(node: SceneNode): ComponentNode | null {
  return findParentOfType<ComponentNode>(node, 'COMPONENT');
}
```

### Sibling Navigation

```typescript
function getSiblings(node: SceneNode): SceneNode[] {
  const parent = node.parent;
  if (!parent || !('children' in parent)) return [];
  return [...parent.children];
}

function getNextSibling(node: SceneNode): SceneNode | null {
  const siblings = getSiblings(node);
  const index = siblings.indexOf(node);
  return siblings[index + 1] || null;
}

function getPreviousSibling(node: SceneNode): SceneNode | null {
  const siblings = getSiblings(node);
  const index = siblings.indexOf(node);
  return siblings[index - 1] || null;
}
```

---

## Batch Operations

### Process with Progress

```typescript
async function processWithProgress<T>(
  items: T[],
  processor: (item: T, index: number) => void | Promise<void>,
  options?: { batchSize?: number; label?: string }
): Promise<void> {
  const { batchSize = 50, label = 'Processing' } = options || {};
  const total = items.length;
  
  for (let i = 0; i < total; i += batchSize) {
    const batch = items.slice(i, i + batchSize);
    
    for (let j = 0; j < batch.length; j++) {
      await processor(batch[j], i + j);
    }
    
    // Update UI with progress
    figma.ui.postMessage({
      type: 'progress',
      current: Math.min(i + batchSize, total),
      total,
      label,
    });
    
    // Yield to Figma to prevent freezing
    await new Promise(resolve => setTimeout(resolve, 0));
  }
}

// Usage
await processWithProgress(
  figma.currentPage.selection,
  (node) => {
    if ('fills' in node) {
      node.fills = [{ type: 'SOLID', color: { r: 1, g: 0, b: 0 } }];
    }
  },
  { label: 'Updating colors' }
);
```

### Undo-Friendly Batching

```typescript
// Group changes for single undo
function batchChanges<T>(
  nodes: SceneNode[],
  transformer: (node: SceneNode) => void
): void {
  // Figma automatically groups rapid changes
  // Just process them quickly
  for (const node of nodes) {
    transformer(node);
  }
}

// For very large batches, use commitUndo
async function batchChangesLarge<T>(
  nodes: SceneNode[],
  transformer: (node: SceneNode) => Promise<void>
): Promise<void> {
  for (const node of nodes) {
    await transformer(node);
  }
  // Changes are automatically grouped
}
```

---

## Working with Colors

### Color Conversion Utilities

```typescript
// Hex to RGB (Figma format: 0-1)
function hexToRgb(hex: string): RGB {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  if (!result) return { r: 0, g: 0, b: 0 };
  
  return {
    r: parseInt(result[1], 16) / 255,
    g: parseInt(result[2], 16) / 255,
    b: parseInt(result[3], 16) / 255,
  };
}

// RGB to Hex
function rgbToHex(color: RGB): string {
  const r = Math.round(color.r * 255).toString(16).padStart(2, '0');
  const g = Math.round(color.g * 255).toString(16).padStart(2, '0');
  const b = Math.round(color.b * 255).toString(16).padStart(2, '0');
  return `#${r}${g}${b}`.toUpperCase();
}

// HSL to RGB
function hslToRgb(h: number, s: number, l: number): RGB {
  let r: number, g: number, b: number;
  
  if (s === 0) {
    r = g = b = l;
  } else {
    const hue2rgb = (p: number, q: number, t: number) => {
      if (t < 0) t += 1;
      if (t > 1) t -= 1;
      if (t < 1/6) return p + (q - p) * 6 * t;
      if (t < 1/2) return q;
      if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
      return p;
    };
    
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    r = hue2rgb(p, q, h + 1/3);
    g = hue2rgb(p, q, h);
    b = hue2rgb(p, q, h - 1/3);
  }
  
  return { r, g, b };
}

// Get solid fill color
function getSolidFillColor(node: GeometryMixin): RGB | null {
  const fills = node.fills;
  if (fills === figma.mixed || !Array.isArray(fills)) return null;
  
  const solidFill = fills.find((f): f is SolidPaint => f.type === 'SOLID');
  return solidFill?.color ?? null;
}

// Set solid fill
function setSolidFill(node: GeometryMixin, color: RGB, opacity?: number): void {
  node.fills = [{
    type: 'SOLID',
    color,
    opacity: opacity ?? 1,
  }];
}
```

### Color Manipulation

```typescript
// Lighten/darken color
function adjustBrightness(color: RGB, amount: number): RGB {
  return {
    r: Math.max(0, Math.min(1, color.r + amount)),
    g: Math.max(0, Math.min(1, color.g + amount)),
    b: Math.max(0, Math.min(1, color.b + amount)),
  };
}

// Calculate contrast ratio (for accessibility)
function getContrastRatio(color1: RGB, color2: RGB): number {
  const luminance = (c: RGB) => {
    const [r, g, b] = [c.r, c.g, c.b].map(v => {
      return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  };
  
  const l1 = luminance(color1);
  const l2 = luminance(color2);
  const lighter = Math.max(l1, l2);
  const darker = Math.min(l1, l2);
  
  return (lighter + 0.05) / (darker + 0.05);
}
```

---

## Working with Text

### Safe Text Operations

```typescript
// Load font before modifying text
async function setTextContent(node: TextNode, text: string): Promise<void> {
  // Load all fonts used in the text node
  if (node.fontName !== figma.mixed) {
    await figma.loadFontAsync(node.fontName);
  } else {
    // Mixed fonts - load all unique fonts
    const fonts = new Set<string>();
    const len = node.characters.length;
    
    for (let i = 0; i < len; i++) {
      const font = node.getRangeFontName(i, i + 1);
      if (font !== figma.mixed) {
        fonts.add(JSON.stringify(font));
      }
    }
    
    await Promise.all(
      [...fonts].map(f => figma.loadFontAsync(JSON.parse(f)))
    );
  }
  
  node.characters = text;
}

// Create text node with font
async function createText(
  text: string,
  font: FontName = { family: 'Inter', style: 'Regular' },
  fontSize: number = 14
): Promise<TextNode> {
  const node = figma.createText();
  await figma.loadFontAsync(font);
  node.fontName = font;
  node.fontSize = fontSize;
  node.characters = text;
  return node;
}
```

### Text Style Application

```typescript
// Apply text style to range
async function styleTextRange(
  node: TextNode,
  start: number,
  end: number,
  style: {
    fontName?: FontName;
    fontSize?: number;
    fills?: Paint[];
    textDecoration?: 'NONE' | 'UNDERLINE' | 'STRIKETHROUGH';
  }
): Promise<void> {
  if (style.fontName) {
    await figma.loadFontAsync(style.fontName);
    node.setRangeFontName(start, end, style.fontName);
  }
  
  if (style.fontSize) {
    node.setRangeFontSize(start, end, style.fontSize);
  }
  
  if (style.fills) {
    node.setRangeFills(start, end, style.fills);
  }
  
  if (style.textDecoration) {
    node.setRangeTextDecoration(start, end, style.textDecoration);
  }
}
```

---

## Positioning & Layout

### Center in Viewport

```typescript
function centerInViewport(node: SceneNode): void {
  const center = figma.viewport.center;
  node.x = center.x - node.width / 2;
  node.y = center.y - node.height / 2;
}

// Scroll to node
function scrollToNode(node: SceneNode): void {
  figma.viewport.scrollAndZoomIntoView([node]);
}
```

### Align Nodes

```typescript
type Alignment = 'left' | 'center' | 'right' | 'top' | 'middle' | 'bottom';

function alignNodes(nodes: SceneNode[], alignment: Alignment): void {
  if (nodes.length < 2) return;
  
  const bounds = nodes.map(n => ({
    left: n.x,
    right: n.x + n.width,
    top: n.y,
    bottom: n.y + n.height,
    centerX: n.x + n.width / 2,
    centerY: n.y + n.height / 2,
  }));
  
  switch (alignment) {
    case 'left': {
      const minX = Math.min(...bounds.map(b => b.left));
      nodes.forEach(n => { n.x = minX; });
      break;
    }
    case 'center': {
      const avgX = bounds.reduce((sum, b) => sum + b.centerX, 0) / bounds.length;
      nodes.forEach(n => { n.x = avgX - n.width / 2; });
      break;
    }
    case 'right': {
      const maxX = Math.max(...bounds.map(b => b.right));
      nodes.forEach(n => { n.x = maxX - n.width; });
      break;
    }
    case 'top': {
      const minY = Math.min(...bounds.map(b => b.top));
      nodes.forEach(n => { n.y = minY; });
      break;
    }
    case 'middle': {
      const avgY = bounds.reduce((sum, b) => sum + b.centerY, 0) / bounds.length;
      nodes.forEach(n => { n.y = avgY - n.height / 2; });
      break;
    }
    case 'bottom': {
      const maxY = Math.max(...bounds.map(b => b.bottom));
      nodes.forEach(n => { n.y = maxY - n.height; });
      break;
    }
  }
}
```

### Distribute Evenly

```typescript
function distributeHorizontally(nodes: SceneNode[]): void {
  if (nodes.length < 3) return;
  
  // Sort by x position
  const sorted = [...nodes].sort((a, b) => a.x - b.x);
  
  const first = sorted[0];
  const last = sorted[sorted.length - 1];
  const totalWidth = sorted.reduce((sum, n) => sum + n.width, 0);
  const totalSpace = (last.x + last.width) - first.x - totalWidth;
  const gap = totalSpace / (sorted.length - 1);
  
  let currentX = first.x + first.width + gap;
  
  for (let i = 1; i < sorted.length - 1; i++) {
    sorted[i].x = currentX;
    currentX += sorted[i].width + gap;
  }
}

function distributeVertically(nodes: SceneNode[]): void {
  if (nodes.length < 3) return;
  
  const sorted = [...nodes].sort((a, b) => a.y - b.y);
  
  const first = sorted[0];
  const last = sorted[sorted.length - 1];
  const totalHeight = sorted.reduce((sum, n) => sum + n.height, 0);
  const totalSpace = (last.y + last.height) - first.y - totalHeight;
  const gap = totalSpace / (sorted.length - 1);
  
  let currentY = first.y + first.height + gap;
  
  for (let i = 1; i < sorted.length - 1; i++) {
    sorted[i].y = currentY;
    currentY += sorted[i].height + gap;
  }
}
```

---

## Storage Patterns

### Persistent Settings

```typescript
interface PluginSettings {
  lastColor: string;
  gridSize: number;
  showGuides: boolean;
}

const DEFAULT_SETTINGS: PluginSettings = {
  lastColor: '#000000',
  gridSize: 8,
  showGuides: true,
};

async function loadSettings(): Promise<PluginSettings> {
  const stored = await figma.clientStorage.getAsync('settings');
  return { ...DEFAULT_SETTINGS, ...stored };
}

async function saveSettings(settings: Partial<PluginSettings>): Promise<void> {
  const current = await loadSettings();
  await figma.clientStorage.setAsync('settings', { ...current, ...settings });
}

// Usage
const settings = await loadSettings();
settings.lastColor = '#FF0000';
await saveSettings(settings);
```

### Node Data

```typescript
// Store data on a node (survives copy/paste)
function setNodeData<T>(node: SceneNode, key: string, data: T): void {
  node.setPluginData(key, JSON.stringify(data));
}

function getNodeData<T>(node: SceneNode, key: string): T | null {
  const data = node.getPluginData(key);
  if (!data) return null;
  try {
    return JSON.parse(data);
  } catch {
    return null;
  }
}

// Example: Track which nodes were processed
interface ProcessedMeta {
  processedAt: string;
  version: string;
}

function markAsProcessed(node: SceneNode): void {
  setNodeData<ProcessedMeta>(node, 'processed', {
    processedAt: new Date().toISOString(),
    version: '1.0.0',
  });
}

function isProcessed(node: SceneNode): boolean {
  return getNodeData<ProcessedMeta>(node, 'processed') !== null;
}
```

---

## Error Handling

### Safe Execution

```typescript
async function safeExecute<T>(
  fn: () => T | Promise<T>,
  errorMessage: string = 'An error occurred'
): Promise<T | null> {
  try {
    return await fn();
  } catch (error) {
    console.error(error);
    figma.notify(errorMessage, { error: true });
    return null;
  }
}

// Usage
const result = await safeExecute(
  () => processNodes(selection),
  'Failed to process nodes'
);

if (result === null) {
  figma.closePlugin();
  return;
}
```

### Validation

```typescript
function validateInput(input: unknown): input is ValidInput {
  if (!input || typeof input !== 'object') return false;
  // Add validation logic
  return true;
}

// With error messages
interface ValidationResult {
  valid: boolean;
  errors: string[];
}

function validateCreateInput(input: any): ValidationResult {
  const errors: string[] = [];
  
  if (!input.name || typeof input.name !== 'string') {
    errors.push('Name is required');
  }
  
  if (typeof input.size !== 'number' || input.size <= 0) {
    errors.push('Size must be a positive number');
  }
  
  return {
    valid: errors.length === 0,
    errors,
  };
}

// Usage
figma.ui.onmessage = (msg) => {
  const validation = validateCreateInput(msg);
  
  if (!validation.valid) {
    figma.ui.postMessage({
      type: 'validation-error',
      errors: validation.errors,
    });
    return;
  }
  
  // Proceed with valid input
};
```

---

## Utilities

### Generate Unique Names

```typescript
function generateUniqueName(baseName: string, existingNames: string[]): string {
  if (!existingNames.includes(baseName)) {
    return baseName;
  }
  
  let counter = 1;
  let newName = `${baseName} ${counter}`;
  
  while (existingNames.includes(newName)) {
    counter++;
    newName = `${baseName} ${counter}`;
  }
  
  return newName;
}

// Usage
const existingNames = figma.currentPage.children.map(n => n.name);
const newName = generateUniqueName('Frame', existingNames);
```

### Debounce

```typescript
function debounce<T extends (...args: any[]) => any>(
  fn: T,
  delay: number
): (...args: Parameters<T>) => void {
  let timeoutId: number | null = null;
  
  return (...args: Parameters<T>) => {
    if (timeoutId) clearTimeout(timeoutId);
    timeoutId = setTimeout(() => fn(...args), delay);
  };
}

// Usage
const debouncedUpdate = debounce((selection: SceneNode[]) => {
  figma.ui.postMessage({ type: 'selection', nodes: selection.map(n => n.name) });
}, 200);

figma.on('selectionchange', () => {
  debouncedUpdate(figma.currentPage.selection);
});
```

### Clone Properties

```typescript
// Copy visual properties from one node to another
function copyAppearance(
  source: SceneNode & GeometryMixin,
  target: SceneNode & GeometryMixin
): void {
  if ('fills' in source && 'fills' in target) {
    target.fills = [...source.fills];
  }
  
  if ('strokes' in source && 'strokes' in target) {
    target.strokes = [...source.strokes];
    target.strokeWeight = source.strokeWeight;
  }
  
  if ('effects' in source && 'effects' in target) {
    target.effects = [...source.effects];
  }
  
  if ('opacity' in source && 'opacity' in target) {
    target.opacity = source.opacity;
  }
  
  if ('cornerRadius' in source && 'cornerRadius' in target) {
    (target as RectangleNode).cornerRadius = (source as RectangleNode).cornerRadius;
  }
}
```
