# Figma Plugin API Reference

Complete reference for the Figma Plugin API.

## Global Objects

### figma

The main API entry point, available in the main thread.

```typescript
// Document
figma.root                    // DocumentNode
figma.currentPage             // PageNode
figma.currentPage.selection   // readonly SceneNode[]

// Create nodes
figma.createRectangle()
figma.createEllipse()
figma.createPolygon()
figma.createStar()
figma.createLine()
figma.createFrame()
figma.createComponent()
figma.createComponentSet()
figma.createText()
figma.createBooleanOperation()
figma.createVector()
figma.createSlice()
figma.createConnector()        // FigJam
figma.createSticky()           // FigJam
figma.createShapeWithText()    // FigJam

// UI
figma.showUI(__html__, options?)
figma.ui.postMessage(message)
figma.ui.onmessage = (msg) => {}
figma.ui.resize(width, height)
figma.ui.close()
figma.closePlugin(message?)

// Viewport
figma.viewport.center          // Vector
figma.viewport.zoom            // number
figma.viewport.scrollAndZoomIntoView(nodes)

// Styles
figma.getLocalPaintStyles()
figma.getLocalTextStyles()
figma.getLocalEffectStyles()
figma.getLocalGridStyles()
figma.createPaintStyle()
figma.createTextStyle()
figma.createEffectStyle()
figma.createGridStyle()

// Search
figma.getNodeById(id)
figma.getStyleById(id)
figma.currentPage.findAll(callback?)
figma.currentPage.findOne(callback)
figma.currentPage.findChildren(callback?)
figma.currentPage.findAllWithCriteria({ types: [...] })

// Events
figma.on('selectionchange', callback)
figma.on('currentpagechange', callback)
figma.on('close', callback)
figma.on('run', callback)
figma.on('drop', callback)
figma.once(event, callback)
figma.off(event, callback)

// Notifications
figma.notify(message, options?)

// Storage
figma.clientStorage.getAsync(key)
figma.clientStorage.setAsync(key, value)
figma.clientStorage.deleteAsync(key)
figma.clientStorage.keysAsync()

// Fonts
figma.loadFontAsync(fontName)
figma.listAvailableFontsAsync()

// Images
figma.createImage(data)        // Uint8Array
figma.getImageByHash(hash)

// Variables (Design Tokens)
figma.variables.getLocalVariables()
figma.variables.getLocalVariableCollections()
figma.variables.createVariable(name, collectionId, type)
figma.variables.createVariableCollection(name)

// Parameters (for parameterized plugins)
figma.parameters.on('input', callback)

// Payments
figma.payments.getPluginPaymentTokenAsync()
figma.payments.initiateCheckoutAsync(options)
```

---

## Node Types

### Document Structure

```typescript
// DocumentNode (figma.root)
interface DocumentNode {
  readonly type: 'DOCUMENT';
  readonly children: readonly PageNode[];
  name: string;
}

// PageNode
interface PageNode {
  readonly type: 'PAGE';
  readonly children: readonly SceneNode[];
  name: string;
  selection: readonly SceneNode[];
  selectedTextRange: { node: TextNode; start: number; end: number } | null;
  backgrounds: readonly Paint[];
  guides: readonly Guide[];
  
  // Methods
  findAll(callback?: (node: SceneNode) => boolean): SceneNode[];
  findOne(callback: (node: SceneNode) => boolean): SceneNode | null;
  findChildren(callback?: (node: SceneNode) => boolean): SceneNode[];
  findAllWithCriteria(criteria: { types: NodeType[] }): SceneNode[];
}
```

### Frame & Group

```typescript
interface FrameNode {
  readonly type: 'FRAME';
  
  // Children
  readonly children: readonly SceneNode[];
  appendChild(child: SceneNode): void;
  insertChild(index: number, child: SceneNode): void;
  
  // Layout
  x: number;
  y: number;
  width: number;
  height: number;
  resize(width: number, height: number): void;
  resizeWithoutConstraints(width: number, height: number): void;
  
  // Auto Layout
  layoutMode: 'NONE' | 'HORIZONTAL' | 'VERTICAL';
  primaryAxisSizingMode: 'FIXED' | 'AUTO';
  counterAxisSizingMode: 'FIXED' | 'AUTO';
  primaryAxisAlignItems: 'MIN' | 'CENTER' | 'MAX' | 'SPACE_BETWEEN';
  counterAxisAlignItems: 'MIN' | 'CENTER' | 'MAX' | 'BASELINE';
  paddingLeft: number;
  paddingRight: number;
  paddingTop: number;
  paddingBottom: number;
  itemSpacing: number;
  
  // Appearance
  fills: readonly Paint[];
  strokes: readonly Paint[];
  strokeWeight: number;
  cornerRadius: number;
  opacity: number;
  effects: readonly Effect[];
  
  // Constraints
  constraints: Constraints;
  
  // Clipping
  clipsContent: boolean;
}

interface GroupNode {
  readonly type: 'GROUP';
  readonly children: readonly SceneNode[];
  // Groups cannot have fills/strokes directly
  // Transform only
}
```

### Shapes

```typescript
interface RectangleNode {
  readonly type: 'RECTANGLE';
  x: number;
  y: number;
  width: number;
  height: number;
  
  // Corner radius
  cornerRadius: number;
  topLeftRadius: number;
  topRightRadius: number;
  bottomLeftRadius: number;
  bottomRightRadius: number;
  
  // Appearance
  fills: readonly Paint[];
  strokes: readonly Paint[];
  strokeWeight: number;
  strokeAlign: 'INSIDE' | 'OUTSIDE' | 'CENTER';
  opacity: number;
  effects: readonly Effect[];
}

interface EllipseNode {
  readonly type: 'ELLIPSE';
  x: number;
  y: number;
  width: number;
  height: number;
  
  // Arc
  arcData: ArcData;
  
  // Appearance
  fills: readonly Paint[];
  strokes: readonly Paint[];
}

interface PolygonNode {
  readonly type: 'POLYGON';
  pointCount: number;  // Number of sides
  // ... same appearance properties
}

interface StarNode {
  readonly type: 'STAR';
  pointCount: number;
  innerRadius: number;  // 0-1, ratio of inner to outer radius
  // ... same appearance properties
}

interface LineNode {
  readonly type: 'LINE';
  x: number;
  y: number;
  width: number;  // Length of line
  rotation: number;
  strokes: readonly Paint[];
  strokeWeight: number;
  strokeCap: 'NONE' | 'ROUND' | 'SQUARE' | 'ARROW_LINES' | 'ARROW_EQUILATERAL';
}

interface VectorNode {
  readonly type: 'VECTOR';
  vectorNetwork: VectorNetwork;
  vectorPaths: VectorPaths;
  // For complex paths
}
```

### Text

```typescript
interface TextNode {
  readonly type: 'TEXT';
  
  // Content
  characters: string;
  
  // Must load font before setting characters
  fontName: FontName | typeof figma.mixed;
  fontSize: number | typeof figma.mixed;
  fontWeight: number | typeof figma.mixed;
  
  // Styling
  textAlignHorizontal: 'LEFT' | 'CENTER' | 'RIGHT' | 'JUSTIFIED';
  textAlignVertical: 'TOP' | 'CENTER' | 'BOTTOM';
  textAutoResize: 'NONE' | 'WIDTH_AND_HEIGHT' | 'HEIGHT' | 'TRUNCATE';
  textCase: TextCase | typeof figma.mixed;
  textDecoration: TextDecoration | typeof figma.mixed;
  letterSpacing: LetterSpacing | typeof figma.mixed;
  lineHeight: LineHeight | typeof figma.mixed;
  paragraphIndent: number;
  paragraphSpacing: number;
  
  // Range methods (for mixed styles)
  getRangeFontName(start: number, end: number): FontName | typeof figma.mixed;
  setRangeFontName(start: number, end: number, value: FontName): void;
  getRangeFontSize(start: number, end: number): number | typeof figma.mixed;
  setRangeFontSize(start: number, end: number, value: number): void;
  getRangeFills(start: number, end: number): Paint[] | typeof figma.mixed;
  setRangeFills(start: number, end: number, value: Paint[]): void;
  // ... more range methods for other properties
  
  // Hyperlinks
  getRangeHyperlink(start: number, end: number): HyperlinkTarget | null;
  setRangeHyperlink(start: number, end: number, value: HyperlinkTarget | null): void;
}

interface FontName {
  family: string;
  style: string;  // 'Regular', 'Bold', 'Italic', etc.
}

// Load font before use
await figma.loadFontAsync({ family: 'Inter', style: 'Regular' });
await figma.loadFontAsync({ family: 'Inter', style: 'Bold' });
```

### Components

```typescript
interface ComponentNode {
  readonly type: 'COMPONENT';
  
  // Same as FrameNode, plus:
  readonly key: string;  // Unique identifier
  description: string;
  documentationLinks: readonly DocumentationLink[];
  
  // Create instance
  createInstance(): InstanceNode;
}

interface ComponentSetNode {
  readonly type: 'COMPONENT_SET';
  readonly children: readonly ComponentNode[];  // Variants
  // Component set for variants
}

interface InstanceNode {
  readonly type: 'INSTANCE';
  
  // Reference to main component
  readonly mainComponent: ComponentNode | null;
  
  // Override properties
  overrides: readonly Override[];
  
  // Swap instance
  swapComponent(newComponent: ComponentNode): void;
  
  // Detach from component
  detachInstance(): FrameNode;
  
  // Reset overrides
  resetOverrides(): void;
}
```

---

## Paint Types

```typescript
type Paint = SolidPaint | GradientPaint | ImagePaint | VideoPaint;

interface SolidPaint {
  type: 'SOLID';
  color: RGB;
  opacity?: number;  // 0-1
  visible?: boolean;
  blendMode?: BlendMode;
}

interface GradientPaint {
  type: 'GRADIENT_LINEAR' | 'GRADIENT_RADIAL' | 'GRADIENT_ANGULAR' | 'GRADIENT_DIAMOND';
  gradientStops: readonly ColorStop[];
  gradientTransform: Transform;
  opacity?: number;
  visible?: boolean;
}

interface ColorStop {
  position: number;  // 0-1
  color: RGBA;
}

interface ImagePaint {
  type: 'IMAGE';
  imageHash: string | null;
  scaleMode: 'FILL' | 'FIT' | 'CROP' | 'TILE';
  imageTransform?: Transform;
  scalingFactor?: number;
  rotation?: number;
  filters?: ImageFilters;
  opacity?: number;
  visible?: boolean;
}

// Create image paint
const imageData: Uint8Array = /* load image bytes */;
const image = figma.createImage(imageData);
node.fills = [{
  type: 'IMAGE',
  imageHash: image.hash,
  scaleMode: 'FILL',
}];
```

---

## Effects

```typescript
type Effect = DropShadowEffect | InnerShadowEffect | BlurEffect | BackgroundBlurEffect;

interface DropShadowEffect {
  type: 'DROP_SHADOW';
  color: RGBA;
  offset: Vector;
  radius: number;
  spread?: number;
  visible: boolean;
  blendMode: BlendMode;
  showShadowBehindNode?: boolean;
}

interface InnerShadowEffect {
  type: 'INNER_SHADOW';
  color: RGBA;
  offset: Vector;
  radius: number;
  spread?: number;
  visible: boolean;
  blendMode: BlendMode;
}

interface BlurEffect {
  type: 'LAYER_BLUR';
  radius: number;
  visible: boolean;
}

interface BackgroundBlurEffect {
  type: 'BACKGROUND_BLUR';
  radius: number;
  visible: boolean;
}

// Example
node.effects = [
  {
    type: 'DROP_SHADOW',
    color: { r: 0, g: 0, b: 0, a: 0.25 },
    offset: { x: 0, y: 4 },
    radius: 8,
    spread: 0,
    visible: true,
    blendMode: 'NORMAL',
  }
];
```

---

## Auto Layout

```typescript
// Enable auto layout
frame.layoutMode = 'VERTICAL';  // or 'HORIZONTAL'

// Direction and alignment
frame.primaryAxisAlignItems = 'CENTER';     // Main axis: MIN, CENTER, MAX, SPACE_BETWEEN
frame.counterAxisAlignItems = 'CENTER';     // Cross axis: MIN, CENTER, MAX, BASELINE

// Sizing
frame.primaryAxisSizingMode = 'AUTO';       // FIXED or AUTO (hug)
frame.counterAxisSizingMode = 'AUTO';       // FIXED or AUTO (hug)

// Padding
frame.paddingTop = 16;
frame.paddingBottom = 16;
frame.paddingLeft = 16;
frame.paddingRight = 16;

// Gap between items
frame.itemSpacing = 8;

// Wrap (if supported)
frame.layoutWrap = 'WRAP';  // or 'NO_WRAP'

// Child properties (when parent has auto layout)
child.layoutPositioning = 'AUTO';           // or 'ABSOLUTE'
child.layoutAlign = 'STRETCH';              // INHERIT, STRETCH, MIN, CENTER, MAX
child.layoutGrow = 1;                       // Flex grow

// Fill container
child.layoutSizingHorizontal = 'FILL';      // FIXED, HUG, or FILL
child.layoutSizingVertical = 'HUG';
```

---

## Styles

```typescript
// Get existing styles
const paintStyles = figma.getLocalPaintStyles();
const textStyles = figma.getLocalTextStyles();
const effectStyles = figma.getLocalEffectStyles();

// Create paint style
const style = figma.createPaintStyle();
style.name = 'Brand/Primary';
style.paints = [{ type: 'SOLID', color: { r: 0, g: 0.5, b: 1 } }];

// Apply style to node
node.fillStyleId = style.id;

// Create text style
const textStyle = figma.createTextStyle();
textStyle.name = 'Heading/H1';
textStyle.fontName = { family: 'Inter', style: 'Bold' };
textStyle.fontSize = 32;
textStyle.lineHeight = { value: 40, unit: 'PIXELS' };

// Apply text style
textNode.textStyleId = textStyle.id;

// Create effect style
const effectStyle = figma.createEffectStyle();
effectStyle.name = 'Shadow/Medium';
effectStyle.effects = [
  {
    type: 'DROP_SHADOW',
    color: { r: 0, g: 0, b: 0, a: 0.15 },
    offset: { x: 0, y: 4 },
    radius: 12,
    visible: true,
    blendMode: 'NORMAL',
  }
];

// Apply effect style
node.effectStyleId = effectStyle.id;
```

---

## Variables (Design Tokens)

```typescript
// Get variables
const variables = figma.variables.getLocalVariables();
const collections = figma.variables.getLocalVariableCollections();

// Create collection
const collection = figma.variables.createVariableCollection('Colors');

// Add mode (for themes)
const darkModeId = collection.addMode('Dark');
const lightModeId = collection.defaultModeId;  // Already exists

// Create variable
const primaryColor = figma.variables.createVariable(
  'color/primary',
  collection.id,
  'COLOR'
);

// Set values per mode
primaryColor.setValueForMode(lightModeId, { r: 0, g: 0.5, b: 1 });
primaryColor.setValueForMode(darkModeId, { r: 0.3, g: 0.7, b: 1 });

// Bind variable to node
node.setBoundVariable('fills', primaryColor.id);

// Variable types
type VariableResolvedDataType = 
  | 'BOOLEAN'
  | 'FLOAT'
  | 'STRING'
  | 'COLOR';
```

---

## Events

```typescript
// Selection changed
figma.on('selectionchange', () => {
  console.log('Selection:', figma.currentPage.selection);
});

// Page changed
figma.on('currentpagechange', () => {
  console.log('Current page:', figma.currentPage.name);
});

// Document changed (for tracking specific changes)
figma.on('documentchange', (event) => {
  for (const change of event.documentChanges) {
    console.log(change.type, change.id);
  }
});

// Plugin close
figma.on('close', () => {
  // Cleanup
});

// Drop event (drag and drop onto canvas)
figma.on('drop', (event) => {
  const { items, dropMetadata } = event;
  // items: dropped files/data
  // dropMetadata: position info
  return false;  // Return false to let Figma handle it, true to cancel
});

// Timer events (use setTimeout/setInterval carefully)
// Available but can block UI - use sparingly

// Remove listener
const handler = () => {};
figma.on('selectionchange', handler);
figma.off('selectionchange', handler);

// Once (auto-removes after first call)
figma.once('selectionchange', () => {
  console.log('First selection change only');
});
```

---

## Export

```typescript
// Export settings
interface ExportSettings {
  format: 'PNG' | 'JPG' | 'SVG' | 'PDF';
  suffix?: string;
  contentsOnly?: boolean;
  constraint?: {
    type: 'SCALE' | 'WIDTH' | 'HEIGHT';
    value: number;
  };
}

// Export node
const bytes = await node.exportAsync({
  format: 'PNG',
  constraint: { type: 'SCALE', value: 2 },  // 2x
});

// Export as SVG string
const svgString = await node.exportAsync({ format: 'SVG' });
const svg = String.fromCharCode(...svgString);

// Send to UI for download
figma.ui.postMessage({
  type: 'export',
  data: Array.from(bytes),
  filename: `${node.name}.png`,
});
```

---

## Helpers

### Figma Mixed

```typescript
// When a property has different values across selection
if (textNode.fontSize === figma.mixed) {
  // Multiple font sizes in this text node
  console.log('Mixed font sizes');
} else {
  console.log('Font size:', textNode.fontSize);
}
```

### Clone

```typescript
// Clone a node
const clone = node.clone();

// Clone returns same type
const rectClone = rectangleNode.clone();  // RectangleNode
```

### Find Nodes

```typescript
// Find all text nodes in page
const textNodes = figma.currentPage.findAll(
  (node) => node.type === 'TEXT'
) as TextNode[];

// Find first frame with name
const header = figma.currentPage.findOne(
  (node) => node.type === 'FRAME' && node.name === 'Header'
) as FrameNode | null;

// Find by type (faster)
const allFrames = figma.currentPage.findAllWithCriteria({
  types: ['FRAME']
});

// Find children (direct only)
const directTextChildren = parentFrame.findChildren(
  (node) => node.type === 'TEXT'
);
```

### Absolute Position

```typescript
// Get absolute position (relative to page)
const absoluteX = node.absoluteTransform[0][2];
const absoluteY = node.absoluteTransform[1][2];

// Or use absoluteBoundingBox
const bounds = node.absoluteBoundingBox;
if (bounds) {
  console.log(bounds.x, bounds.y, bounds.width, bounds.height);
}
```
