# Anti-Pattern Examples

Concrete comparisons of AI slop versus distinctive design.

## Hero Section

### ❌ AI Slop
```tsx
<div className="bg-gradient-to-r from-purple-600 to-blue-500 min-h-screen flex items-center justify-center">
  <div className="text-center text-white p-8">
    <h1 className="text-5xl font-bold mb-4">Welcome to Our Platform</h1>
    <p className="text-xl mb-8 text-gray-200">
      The best solution for all your needs. Get started today!
    </p>
    <button className="bg-white text-purple-600 px-8 py-3 rounded-full font-semibold shadow-2xl hover:shadow-3xl transition-all">
      Get Started
    </button>
  </div>
</div>
```

Problems: Purple gradient, centered everything, generic copy, massive shadow, rounded-full button, "Get Started Today" cliché.

### ✅ Distinctive
```tsx
<section className="min-h-screen bg-stone-950 text-stone-100 px-6 py-24">
  <motion.div 
    className="max-w-2xl"
    initial={{ opacity: 0, y: 20 }}
    animate={{ opacity: 1, y: 0 }}
    transition={{ duration: 0.6, ease: [0.25, 0.1, 0.25, 1] }}
  >
    <p className="text-amber-500 font-mono text-sm tracking-wide mb-4">
      For teams shipping fast
    </p>
    <h1 className="font-display text-5xl md:text-7xl font-medium tracking-tight mb-6">
      Deploy without<br />the drama
    </h1>
    <p className="text-stone-400 text-lg max-w-md mb-10">
      One command. Zero config. Your code goes live in seconds, not sprints.
    </p>
    <a 
      href="/start" 
      className="inline-flex items-center gap-2 bg-amber-500 text-stone-950 px-5 py-2.5 font-medium hover:bg-amber-400 transition-colors"
    >
      Start deploying
      <ArrowRight className="w-4 h-4" />
    </a>
  </motion.div>
</section>
```

Why it works: Dark theme, asymmetric layout, specific copy, restrained color (stone + amber accent), subtle animation, no massive shadows.

---

## Card Component

### ❌ AI Slop
```tsx
<div className="bg-white rounded-3xl shadow-2xl p-8 hover:shadow-3xl transition-all duration-300 hover:-translate-y-2">
  <div className="w-16 h-16 bg-gradient-to-r from-blue-500 to-purple-600 rounded-2xl flex items-center justify-center mb-6">
    <Icon className="w-8 h-8 text-white" />
  </div>
  <h3 className="text-2xl font-bold text-gray-800 mb-3">Feature Title</h3>
  <p className="text-gray-600">
    Lorem ipsum dolor sit amet, consectetur adipiscing elit.
  </p>
</div>
```

Problems: Extreme rounding, purple gradient icon, massive shadow, hover-lift cliché, lorem ipsum.

### ✅ Distinctive
```tsx
<article className="group border border-stone-200 p-6 hover:border-stone-400 transition-colors">
  <div className="flex items-start justify-between mb-8">
    <span className="text-xs font-mono text-stone-500 uppercase tracking-wider">
      Analytics
    </span>
    <ArrowUpRight className="w-4 h-4 text-stone-400 group-hover:text-stone-900 transition-colors" />
  </div>
  <h3 className="font-medium text-lg mb-2">Real-time dashboards</h3>
  <p className="text-stone-600 text-sm leading-relaxed">
    See what's happening as it happens. No refresh needed, no delay.
  </p>
</article>
```

Why it works: Simple border (not shadow), subtle hover state, asymmetric content placement, real copy, restrained styling.

---

## Button Styles

### ❌ AI Slop
```tsx
// The usual suspects
<button className="bg-gradient-to-r from-purple-600 to-blue-500 text-white px-8 py-4 rounded-full shadow-2xl hover:shadow-purple-500/50 font-bold text-lg">
  Get Started Free →
</button>
```

### ✅ Distinctive Options
```tsx
// Minimal with intent
<button className="bg-stone-900 text-stone-100 px-5 py-2.5 text-sm font-medium hover:bg-stone-800 transition-colors">
  Continue
</button>

// Border emphasis  
<button className="border-2 border-current px-5 py-2.5 font-medium hover:bg-stone-900 hover:text-white transition-all">
  View case study
</button>

// Subtle with icon
<button className="inline-flex items-center gap-2 text-stone-600 hover:text-stone-900 font-medium transition-colors">
  Learn more
  <ArrowRight className="w-4 h-4" />
</button>
```

---

## Typography Pairing

### ❌ AI Slop
```css
/* Generic stack */
font-family: Inter, system-ui, sans-serif;
```

### ✅ Distinctive Pairings
```css
/* Editorial */
--font-display: 'Playfair Display', serif;
--font-body: 'Source Sans 3', sans-serif;

/* Modern tech */
--font-display: 'Cabinet Grotesk', sans-serif;
--font-body: 'IBM Plex Sans', sans-serif;

/* Bold statement */
--font-display: 'Bebas Neue', sans-serif;
--font-body: 'DM Sans', sans-serif;

/* Sophisticated minimal */
--font-display: 'Syne', sans-serif;
--font-body: 'Manrope', sans-serif;
```

---

## Color Systems

### ❌ AI Slop
```css
/* The purple plague */
--primary: #8B5CF6;
--secondary: #3B82F6;
--background: #FFFFFF;
--text: #1F2937;
```

### ✅ Distinctive Palettes
```css
/* Warm dark */
--bg: #1C1917;
--surface: #292524;
--text: #F5F5F4;
--accent: #F59E0B;

/* Editorial cream */
--bg: #FAFAF9;
--surface: #FFFFFF;
--text: #1C1917;
--accent: #0F766E;

/* High contrast */
--bg: #09090B;
--surface: #18181B;
--text: #FAFAFA;
--accent: #22D3EE;

/* Forest */
--bg: #14532D;
--surface: #166534;
--text: #F0FDF4;
--accent: #FDE047;
```

---

## Animation Patterns

### ❌ AI Slop
```tsx
// Everything bounces and scales
<motion.div
  whileHover={{ scale: 1.1 }}
  whileTap={{ scale: 0.95 }}
  animate={{ y: [0, -10, 0] }}
  transition={{ repeat: Infinity, duration: 2 }}
>
```

### ✅ Purposeful Motion
```tsx
// Page load: staggered reveal
const stagger = {
  show: { transition: { staggerChildren: 0.08 } }
};

const fadeUp = {
  hidden: { opacity: 0, y: 16 },
  show: { 
    opacity: 1, 
    y: 0,
    transition: { duration: 0.4, ease: [0.25, 0.1, 0.25, 1] }
  }
};

// Interaction: subtle feedback
<motion.button whileTap={{ scale: 0.98 }}>

// Hover: gentle shift
<motion.a whileHover={{ x: 4 }} transition={{ duration: 0.2 }}>
```

---

---

## React Native Anti-Patterns

### ❌ AI Slop
```tsx
<View style={{
  backgroundColor: '#8B5CF6',
  borderRadius: 24,
  shadowColor: '#000',
  shadowOffset: { width: 0, height: 10 },
  shadowOpacity: 0.5,
  shadowRadius: 20,
  elevation: 15,
  padding: 24,
}}>
  <Text style={{ 
    fontFamily: 'System',
    fontSize: 28,
    fontWeight: 'bold',
    color: 'white',
    textAlign: 'center'
  }}>
    Welcome Back!
  </Text>
  <TouchableOpacity style={{
    backgroundColor: 'white',
    borderRadius: 100,
    paddingVertical: 16,
    marginTop: 20,
  }}>
    <Text style={{ color: '#8B5CF6', fontWeight: 'bold', textAlign: 'center' }}>
      Get Started
    </Text>
  </TouchableOpacity>
</View>
```

Problems: System font, purple background, extreme shadows, pill button, centered everything, generic copy.

### ✅ Distinctive
```tsx
import Animated, { FadeInDown } from 'react-native-reanimated';

<Animated.View 
  entering={FadeInDown.duration(500).easing(Easing.out(Easing.cubic))}
  style={styles.container}
>
  <Text style={styles.eyebrow}>Welcome back</Text>
  <Text style={styles.heading}>Ready to{'\n'}continue?</Text>
  
  <Pressable style={({ pressed }) => [
    styles.button,
    pressed && styles.buttonPressed
  ]}>
    <Text style={styles.buttonText}>Open workspace</Text>
    <ArrowRight color={colors.stone[900]} size={18} />
  </Pressable>
</Animated.View>

// styles.ts
const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: colors.stone[950],
    paddingHorizontal: 24,
    paddingTop: 80,
  },
  eyebrow: {
    fontFamily: 'JetBrainsMono-Regular',
    fontSize: 12,
    color: colors.stone[500],
    letterSpacing: 1,
    textTransform: 'uppercase',
    marginBottom: 12,
  },
  heading: {
    fontFamily: 'Syne-SemiBold',
    fontSize: 42,
    color: colors.stone[100],
    lineHeight: 48,
    marginBottom: 32,
  },
  button: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    backgroundColor: colors.amber[400],
    alignSelf: 'flex-start',
    paddingVertical: 12,
    paddingHorizontal: 20,
  },
  buttonPressed: {
    backgroundColor: colors.amber[500],
  },
  buttonText: {
    fontFamily: 'Syne-Medium',
    fontSize: 15,
    color: colors.stone[900],
  },
});
```

Why it works: Custom fonts, dark theme, left-aligned, sharp corners, subtle press state, purposeful animation on mount only.

### React Native Specific Issues

| Pattern | AI Slop | Distinctive |
|---------|---------|-------------|
| Font | `fontFamily: 'System'` | Custom loaded font |
| Shadows | `elevation: 15`, massive shadowRadius | Subtle or border-based |
| Buttons | `borderRadius: 100` (pill) | Sharp or subtle radius |
| Animation | Animated.loop on everything | `entering`/`exiting` on mount |
| Lists | Default FlatList | Custom separators, staggered entering |
| Icons | Colorful gradient backgrounds | Monochrome, contextual |

### ❌ List AI Slop
```tsx
<FlatList
  data={items}
  renderItem={({ item }) => (
    <View style={{
      backgroundColor: 'white',
      borderRadius: 16,
      padding: 16,
      marginBottom: 12,
      shadowColor: '#000',
      shadowOpacity: 0.1,
      shadowRadius: 10,
      elevation: 5,
    }}>
      <Text style={{ fontWeight: 'bold' }}>{item.title}</Text>
    </View>
  )}
/>
```

### ✅ Distinctive List
```tsx
<Animated.FlatList
  data={items}
  contentContainerStyle={{ paddingHorizontal: 20 }}
  ItemSeparatorComponent={() => <View style={styles.separator} />}
  renderItem={({ item, index }) => (
    <Animated.View 
      entering={FadeInUp.delay(index * 50).duration(400)}
      style={styles.listItem}
    >
      <View style={styles.listItemContent}>
        <Text style={styles.listTitle}>{item.title}</Text>
        <Text style={styles.listMeta}>{item.meta}</Text>
      </View>
      <ChevronRight color={colors.stone[400]} size={20} />
    </Animated.View>
  )}
/>

// Styles
separator: {
  height: 1,
  backgroundColor: colors.stone[200],
},
listItem: {
  flexDirection: 'row',
  alignItems: 'center',
  justifyContent: 'space-between',
  paddingVertical: 16,
},
```

---

## SwiftUI Anti-Patterns

### ❌ AI Slop
```swift
struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Welcome to Our App")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("The best solution for all your needs")
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            Button(action: {}) {
                Text("Get Started")
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(30)
                    .shadow(color: .purple.opacity(0.4), radius: 15, y: 10)
            }
        }
        .padding(40)
    }
}
```

Problems: System fonts, purple gradient, massive shadow, pill button, centered layout, generic copy.

### ✅ Distinctive
```swift
struct WelcomeView: View {
    @State private var appeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("CONTINUE WHERE YOU LEFT OFF")
                .font(.custom("JetBrainsMono-Regular", size: 11))
                .tracking(1.5)
                .foregroundColor(Color("stone500"))
                .padding(.bottom, 16)
            
            Text("Ready to\nbuild?")
                .font(.custom("Syne-SemiBold", size: 48))
                .foregroundColor(Color("stone100"))
                .lineSpacing(-4)
                .padding(.bottom, 32)
            
            Button(action: {}) {
                HStack(spacing: 8) {
                    Text("Open project")
                        .font(.custom("Syne-Medium", size: 15))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(Color("stone900"))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color("amber400"))
            }
            .buttonStyle(.plain)
            
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color("stone950"))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                appeared = true
            }
        }
    }
}
```

Why it works: Custom fonts, dark theme, left-aligned, sharp button, specific copy, single subtle entrance animation.

### SwiftUI Specific Issues

| Pattern | AI Slop | Distinctive |
|---------|---------|-------------|
| Font | `.font(.title)` system | `.font(.custom("...", size:))` |
| Colors | `.purple`, `.blue` | Asset Catalog semantic colors |
| Gradients | `LinearGradient(colors: [.purple, .blue])` | Single color or subtle same-hue |
| Corners | `.cornerRadius(30)` | Sharp or `.cornerRadius(8)` |
| Shadow | `.shadow(radius: 15)` | None or very subtle |
| Animation | `.animation(.spring())` on everything | Intentional `.onAppear` transitions |
| Layout | `VStack` centered | Explicit alignment: `.leading` |

### ❌ Card AI Slop
```swift
struct FeatureCard: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "star.fill")
                .font(.largeTitle)
                .foregroundStyle(
                    LinearGradient(colors: [.purple, .blue], startPoint: .top, endPoint: .bottom)
                )
            
            Text("Amazing Feature")
                .font(.headline)
            
            Text("Lorem ipsum dolor sit amet")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(.white)
        .cornerRadius(24)
        .shadow(color: .black.opacity(0.1), radius: 20, y: 10)
    }
}
```

### ✅ Distinctive Card
```swift
struct FeatureCard: View {
    let category: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(category.uppercased())
                    .font(.custom("JetBrainsMono-Regular", size: 10))
                    .tracking(1)
                    .foregroundColor(Color("stone500"))
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color("stone400"))
            }
            .padding(.bottom, 24)
            
            Text(title)
                .font(.custom("Syne-Medium", size: 17))
                .foregroundColor(Color("stone900"))
                .padding(.bottom, 6)
            
            Text(description)
                .font(.custom("DMSans-Regular", size: 14))
                .foregroundColor(Color("stone600"))
                .lineSpacing(2)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(
            RoundedRectangle(cornerRadius: 2)
                .stroke(Color("stone200"), lineWidth: 1)
        )
    }
}
```

---

## Quick Reference

| Element | AI Slop | Distinctive |
|---------|---------|-------------|
| Shadows | `shadow-2xl`, `shadow-3xl` | `shadow-sm` or border only |
| Radius | `rounded-3xl`, `rounded-full` | `rounded`, `rounded-lg`, or sharp |
| Gradients | Purple-to-blue | Single color or subtle same-hue |
| Font | Inter, Roboto | Project-specific choice |
| Hover | Scale + shadow + translate | Color shift or subtle transform |
| CTA | "Get Started Today!" | Action-specific verb |
