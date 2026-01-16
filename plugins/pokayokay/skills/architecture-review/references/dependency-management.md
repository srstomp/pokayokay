# Dependency Management

Managing module boundaries, circular dependencies, and coupling.

## Dependency Direction

### The Dependency Rule

```
┌─────────────────────────────────────────────────────────────┐
│                    DEPENDENCY DIRECTION                      │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│    UI Layer            →      Allowed to import from       │
│    (Components)               Services, Utils, Types       │
│         │                                                   │
│         ▼                                                   │
│    Application Layer   →      Allowed to import from       │
│    (Services, Hooks)          Repositories, Utils, Types   │
│         │                                                   │
│         ▼                                                   │
│    Data Layer          →      Allowed to import from       │
│    (Repositories)             Models, Utils, Types         │
│         │                                                   │
│         ▼                                                   │
│    Core Layer          →      No external imports          │
│    (Models, Types)            (self-contained)             │
│                                                             │
│    Utils/Shared        →      Can be imported by any layer │
│                               Must not import from layers  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Enforce with ESLint

```javascript
// .eslintrc.js
module.exports = {
  plugins: ['import'],
  rules: {
    'import/no-restricted-paths': [
      'error',
      {
        zones: [
          // Repositories cannot import from services
          {
            target: './src/repositories',
            from: './src/services',
            message: 'Repositories cannot depend on services',
          },
          // Services cannot import from controllers
          {
            target: './src/services',
            from: './src/controllers',
            message: 'Services cannot depend on controllers',
          },
          // Components cannot import from repositories
          {
            target: './src/components',
            from: './src/repositories',
            message: 'Components must not access data layer directly',
          },
          // Shared/utils cannot import from features
          {
            target: './src/shared',
            from: './src/features',
            message: 'Shared code cannot depend on features',
          },
        ],
      },
    ],
  },
};
```

---

## Circular Dependencies

### Detecting Circular Dependencies

```bash
# Using madge
npx madge --circular src/

# Using dependency-cruiser
npx depcruise --validate .dependency-cruiser.js src/
```

### Common Circular Patterns

#### Pattern 1: Service-to-Service

```typescript
// ❌ CIRCULAR
// userService.ts
import { OrderService } from './orderService';
export class UserService {
  constructor(private orderService: OrderService) {}
  getUserOrders(userId: string) {
    return this.orderService.getOrdersByUser(userId);
  }
}

// orderService.ts
import { UserService } from './userService';
export class OrderService {
  constructor(private userService: UserService) {}
  getOrderWithUser(orderId: string) {
    const order = this.getOrder(orderId);
    return { ...order, user: this.userService.getUser(order.userId) };
  }
}
```

**Fix 1: Extract Shared Logic**

```typescript
// orderUserService.ts (new)
export class OrderUserService {
  constructor(
    private userRepo: UserRepository,
    private orderRepo: OrderRepository,
  ) {}
  
  getUserOrders(userId: string) {
    return this.orderRepo.findByUser(userId);
  }
  
  getOrderWithUser(orderId: string) {
    const order = this.orderRepo.findById(orderId);
    const user = this.userRepo.findById(order.userId);
    return { ...order, user };
  }
}
```

**Fix 2: Use Events**

```typescript
// userService.ts
export class UserService {
  async deleteUser(userId: string) {
    await this.userRepo.delete(userId);
    this.eventBus.emit('user.deleted', { userId });
  }
}

// orderService.ts
export class OrderService {
  constructor(private eventBus: EventBus) {
    this.eventBus.on('user.deleted', this.handleUserDeleted.bind(this));
  }
  
  private async handleUserDeleted({ userId }: { userId: string }) {
    await this.cancelUserOrders(userId);
  }
}
```

**Fix 3: Dependency Injection with Interfaces**

```typescript
// interfaces/IOrderService.ts
export interface IOrderService {
  getOrdersByUser(userId: string): Promise<Order[]>;
}

// userService.ts
import { IOrderService } from '../interfaces/IOrderService';

export class UserService {
  private orderService?: IOrderService;
  
  setOrderService(orderService: IOrderService) {
    this.orderService = orderService;
  }
  
  getUserOrders(userId: string) {
    return this.orderService?.getOrdersByUser(userId);
  }
}

// Compose at application startup
const userService = new UserService();
const orderService = new OrderService();
userService.setOrderService(orderService);
```

#### Pattern 2: Type Imports Causing Cycles

```typescript
// ❌ types.ts imports from services for types
// types.ts
import { UserService } from './services/userService';
export type UserServiceType = typeof UserService;

// services/userService.ts
import { User } from '../types';  // Circular!
```

**Fix: Separate Type Files**

```typescript
// types/user.types.ts (no imports from services)
export interface User {
  id: string;
  email: string;
}

// services/userService.ts
import { User } from '../types/user.types';  // No cycle
```

#### Pattern 3: Index File Cycles

```typescript
// ❌ Barrel file creates cycle
// features/index.ts
export * from './users';
export * from './orders';

// features/users/index.ts
export * from './UserList';

// features/users/UserList.tsx
import { OrderSummary } from '../orders';  // Goes through barrel → cycle!
```

**Fix: Direct Imports**

```typescript
// features/users/UserList.tsx
import { OrderSummary } from '../orders/OrderSummary';  // Direct import
```

---

## Coupling Reduction

### Tight vs Loose Coupling

```typescript
// ❌ TIGHT COUPLING
// Direct dependency on concrete class and its internals
class OrderService {
  async createOrder(data: CreateOrderDto) {
    const user = await prisma.user.findUnique({ where: { id: data.userId } });
    if (!user) throw new Error('User not found');
    
    const product = await prisma.product.findUnique({ where: { id: data.productId } });
    if (product.stock < data.quantity) throw new Error('Insufficient stock');
    
    await prisma.product.update({
      where: { id: data.productId },
      data: { stock: product.stock - data.quantity },
    });
    
    const order = await prisma.order.create({ data });
    
    await sendEmail(user.email, 'Order Confirmation', orderTemplate(order));
    
    return order;
  }
}

// ✅ LOOSE COUPLING
// Depends on interfaces, single responsibility
class OrderService {
  constructor(
    private userRepository: IUserRepository,
    private productRepository: IProductRepository,
    private orderRepository: IOrderRepository,
    private inventoryService: IInventoryService,
    private notificationService: INotificationService,
  ) {}
  
  async createOrder(data: CreateOrderDto) {
    const user = await this.userRepository.findById(data.userId);
    if (!user) throw new UserNotFoundError(data.userId);
    
    await this.inventoryService.reserveStock(data.productId, data.quantity);
    
    const order = await this.orderRepository.create(data);
    
    await this.notificationService.sendOrderConfirmation(user, order);
    
    return order;
  }
}
```

### Dependency Injection

```typescript
// container.ts
import { Container } from 'inversify';

const container = new Container();

// Bind interfaces to implementations
container.bind<IUserRepository>('IUserRepository').to(UserRepository);
container.bind<IOrderRepository>('IOrderRepository').to(OrderRepository);
container.bind<IEmailService>('IEmailService').to(EmailService);
container.bind<UserService>('UserService').to(UserService);
container.bind<OrderService>('OrderService').to(OrderService);

export { container };

// Usage
const orderService = container.get<OrderService>('OrderService');
```

### Feature Isolation

```typescript
// ❌ Features tightly coupled
// features/orders/OrderForm.tsx
import { useUser } from '../users/hooks/useUser';
import { UserAvatar } from '../users/components/UserAvatar';
import { ProductCard } from '../products/components/ProductCard';
import { useProducts } from '../products/hooks/useProducts';
import { calculateShipping } from '../shipping/utils';

// ✅ Features loosely coupled via shared interfaces

// shared/types/index.ts
export interface UserInfo {
  id: string;
  name: string;
  avatar: string;
}

// features/orders/OrderForm.tsx
import { UserInfo } from '@/shared/types';

interface OrderFormProps {
  user: UserInfo;  // Receives data, doesn't fetch
  products: Product[];
  onSubmit: (order: OrderData) => void;
}

// Parent component composes features
// pages/checkout.tsx
import { useUser } from '@/features/users';
import { useProducts } from '@/features/products';
import { OrderForm } from '@/features/orders';

function CheckoutPage() {
  const user = useUser();
  const products = useProducts();
  
  return <OrderForm user={user} products={products} />;
}
```

---

## Module Boundaries

### Public API Definition

```typescript
// features/users/index.ts
// Only export what other features should use

// ✅ Public API
export { UserList } from './components/UserList';
export { UserCard } from './components/UserCard';
export { useUser } from './hooks/useUser';
export { useUsers } from './hooks/useUsers';
export type { User, CreateUserDto } from './types';

// ❌ Don't export internals
// export { UserListItem } from './components/UserListItem';  // Internal
// export { formatUserName } from './utils';  // Internal
// export { userApi } from './api';  // Internal
```

### Enforce Boundaries with ESLint

```javascript
// .eslintrc.js
module.exports = {
  rules: {
    'no-restricted-imports': [
      'error',
      {
        patterns: [
          {
            group: ['@/features/*/components/*'],
            message: 'Import from feature index instead: @/features/featureName',
          },
          {
            group: ['@/features/*/hooks/*'],
            message: 'Import from feature index instead',
          },
          {
            group: ['@/features/*/api*'],
            message: 'Feature APIs are internal, use exported hooks',
          },
        ],
      },
    ],
  },
};
```

### Package-Based Boundaries (Monorepo)

```json
// packages/users/package.json
{
  "name": "@myorg/users",
  "main": "src/index.ts",
  "exports": {
    ".": "./src/index.ts",
    "./components": "./src/components/index.ts",
    "./hooks": "./src/hooks/index.ts"
  }
}

// Only what's in exports is accessible
// import { UserList } from '@myorg/users/components';  // ✅ Allowed
// import { UserListItem } from '@myorg/users/components/UserListItem';  // ❌ Not exported
```

---

## Import Organization

### Consistent Import Order

```typescript
// Recommended order:
// 1. Node built-ins
// 2. External packages
// 3. Internal packages (monorepo)
// 4. Absolute imports from src
// 5. Relative imports

// Example:
import path from 'path';                              // 1. Node
import React, { useState } from 'react';              // 2. External
import { Button } from '@myorg/ui';                   // 3. Internal package
import { useAuth } from '@/features/auth';            // 4. Absolute
import { formatDate } from '../../utils/date';        // 5. Relative
import { UserCard } from './UserCard';                // 5. Relative (same dir)
```

### ESLint Import Order

```javascript
// .eslintrc.js
module.exports = {
  plugins: ['import'],
  rules: {
    'import/order': [
      'error',
      {
        groups: [
          'builtin',
          'external',
          'internal',
          ['parent', 'sibling', 'index'],
        ],
        pathGroups: [
          { pattern: '@myorg/**', group: 'internal' },
          { pattern: '@/**', group: 'internal' },
        ],
        'newlines-between': 'always',
        alphabetize: { order: 'asc' },
      },
    ],
  },
};
```

---

## Dependency Graphs

### Visualizing Dependencies

```bash
# Generate SVG graph
npx madge --image deps.svg src/index.ts

# Generate for specific directory
npx madge --image users-deps.svg src/features/users/

# Show only circular
npx madge --circular --image circular.svg src/

# JSON output for processing
npx madge --json src/ > deps.json
```

### Analyzing Graph

```typescript
// scripts/analyze-deps.ts
import madge from 'madge';

async function analyzeDependencies() {
  const result = await madge('src/index.ts', {
    fileExtensions: ['ts', 'tsx'],
    excludeRegExp: [/\.test\.ts$/, /\.spec\.ts$/],
  });
  
  // Circular dependencies
  const circular = result.circular();
  if (circular.length > 0) {
    console.log('⚠️  Circular dependencies found:');
    circular.forEach(cycle => {
      console.log('  ', cycle.join(' → '));
    });
  }
  
  // Orphans (not imported anywhere)
  const orphans = result.orphans();
  if (orphans.length > 0) {
    console.log('\n📦 Orphan files (not imported):');
    orphans.forEach(file => console.log('  ', file));
  }
  
  // Most depended upon (potential god modules)
  const deps = result.obj();
  const dependedUpon = new Map<string, number>();
  
  Object.values(deps).forEach(imports => {
    imports.forEach(imp => {
      dependedUpon.set(imp, (dependedUpon.get(imp) || 0) + 1);
    });
  });
  
  const sorted = [...dependedUpon.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10);
  
  console.log('\n🏆 Most imported files:');
  sorted.forEach(([file, count]) => {
    console.log(`  ${count.toString().padStart(3)} imports: ${file}`);
  });
}

analyzeDependencies();
```

---

## Breaking Dependency Cycles

### Step-by-Step Process

```
1. Identify the cycle
   madge --circular src/

2. Understand WHY the cycle exists
   - Shared types?
   - Shared utilities?
   - Bidirectional relationship?

3. Choose resolution strategy:
   - Extract shared code
   - Use dependency injection
   - Use events/callbacks
   - Restructure modules

4. Implement fix in stages
   - Create new module/interface
   - Update one side of cycle
   - Run tests
   - Update other side
   - Run tests
   - Remove old imports

5. Verify cycle is broken
   madge --circular src/
```

### Common Resolutions

| Cycle Pattern | Resolution |
|---------------|------------|
| A → B → A (direct) | Extract common code to C, both import C |
| A ↔ B (types only) | Move shared types to separate file |
| A → B → C → A | Extract interface, use DI |
| Service ↔ Service | Use events or mediator |
| Feature ↔ Feature | Pass data via props/context |
