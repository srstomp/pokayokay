# Refactoring Patterns

Safe techniques for restructuring code and migrating architectures.

## Core Principles

### 1. Never Refactor Without Tests

```typescript
// Before any structural change:
// 1. Ensure tests exist for affected code
// 2. Run tests to verify they pass
// 3. Make change
// 4. Run tests again
// 5. Commit

// If no tests exist, add them first
describe('UserService', () => {
  it('creates user with valid data', async () => {
    const user = await userService.create({ email: 'test@example.com' });
    expect(user.id).toBeDefined();
  });
  
  // Add more tests to cover behavior before refactoring
});
```

### 2. Small, Incremental Changes

```
❌ Bad: One massive commit that restructures everything
✅ Good: Series of small commits, each passing tests

Commit 1: Create new folder structure
Commit 2: Move UserService to new location
Commit 3: Update imports for UserService
Commit 4: Move OrderService to new location
Commit 5: Update imports for OrderService
...
```

### 3. Parallel Structures (Strangler Fig)

```typescript
// Step 1: Create new structure alongside old
src/
├── services/           # Old location
│   └── userService.ts
└── modules/            # New location
    └── users/
        └── user.service.ts  # Copy of userService

// Step 2: New code uses new location
// Step 3: Migrate old consumers one by one
// Step 4: Delete old location when empty
```

---

## File Movement Patterns

### Safe File Move

```bash
# Step 1: Create new directory
mkdir -p src/modules/users

# Step 2: Copy file (don't move yet)
cp src/services/userService.ts src/modules/users/user.service.ts

# Step 3: Update the new file's imports
# (Fix relative paths)

# Step 4: Create re-export from old location
# src/services/userService.ts
export * from '../modules/users/user.service';

# Step 5: Run tests - everything should still work

# Step 6: Update consumers to import from new location
# (One file at a time, running tests between each)

# Step 7: When no consumers use old location, delete it
```

### Bulk File Movement Script

```typescript
// scripts/move-module.ts
import fs from 'fs';
import path from 'path';

interface MoveConfig {
  from: string;
  to: string;
  updateImports: boolean;
}

async function moveModule(config: MoveConfig): Promise<void> {
  const { from, to, updateImports } = config;
  
  // 1. Create target directory
  fs.mkdirSync(path.dirname(to), { recursive: true });
  
  // 2. Copy file
  fs.copyFileSync(from, to);
  
  // 3. Create re-export at old location
  const relativePath = path.relative(path.dirname(from), to).replace(/\.ts$/, '');
  fs.writeFileSync(from, `export * from '${relativePath}';\n`);
  
  console.log(`Moved: ${from} → ${to}`);
  console.log(`Created re-export at: ${from}`);
  
  if (updateImports) {
    // 4. Find and update all imports
    await updateAllImports(from, to);
  }
}

async function updateAllImports(oldPath: string, newPath: string): Promise<void> {
  const srcDir = './src';
  const oldImportPath = oldPath.replace(/^\.\/src\//, '').replace(/\.ts$/, '');
  const newImportPath = newPath.replace(/^\.\/src\//, '').replace(/\.ts$/, '');
  
  function walkAndUpdate(dir: string) {
    const entries = fs.readdirSync(dir, { withFileTypes: true });
    
    for (const entry of entries) {
      if (entry.name === 'node_modules') continue;
      
      const fullPath = path.join(dir, entry.name);
      
      if (entry.isDirectory()) {
        walkAndUpdate(fullPath);
      } else if (/\.(ts|tsx)$/.test(entry.name)) {
        let content = fs.readFileSync(fullPath, 'utf-8');
        const originalContent = content;
        
        // Update imports
        content = content.replace(
          new RegExp(`from ['"]([./@]*)${oldImportPath}['"]`, 'g'),
          `from '$1${newImportPath}'`
        );
        
        if (content !== originalContent) {
          fs.writeFileSync(fullPath, content);
          console.log(`Updated imports in: ${fullPath}`);
        }
      }
    }
  }
  
  walkAndUpdate(srcDir);
}
```

---

## Module Extraction Patterns

### Extract to Separate Module

```typescript
// BEFORE: God file with mixed concerns
// src/services/userService.ts (500+ lines)

export class UserService {
  async createUser() { /* ... */ }
  async updateUser() { /* ... */ }
  async deleteUser() { /* ... */ }
  async sendWelcomeEmail() { /* ... */ }
  async sendPasswordReset() { /* ... */ }
  async validateUserData() { /* ... */ }
  async checkPermissions() { /* ... */ }
}

// AFTER: Extracted into focused modules

// src/modules/users/user.service.ts
export class UserService {
  constructor(
    private emailService: EmailService,
    private validationService: ValidationService,
  ) {}
  
  async createUser() { /* ... */ }
  async updateUser() { /* ... */ }
  async deleteUser() { /* ... */ }
}

// src/modules/email/email.service.ts
export class EmailService {
  async sendWelcomeEmail() { /* ... */ }
  async sendPasswordReset() { /* ... */ }
}

// src/modules/validation/validation.service.ts
export class ValidationService {
  async validateUserData() { /* ... */ }
}
```

### Extract Shared Utilities

```typescript
// BEFORE: Utility functions scattered in multiple files

// src/services/userService.ts
function formatDate(date: Date): string { /* ... */ }
function generateId(): string { /* ... */ }

// src/services/orderService.ts
function formatDate(date: Date): string { /* ... */ }  // Duplicate!
function calculateTotal(items: Item[]): number { /* ... */ }

// AFTER: Shared utilities extracted

// src/shared/utils/date.ts
export function formatDate(date: Date): string { /* ... */ }

// src/shared/utils/id.ts
export function generateId(): string { /* ... */ }

// src/shared/utils/index.ts
export * from './date';
export * from './id';
```

---

## Interface Extraction

### Extract Interface for Decoupling

```typescript
// BEFORE: Direct class dependency
// src/services/orderService.ts
import { UserService } from './userService';

export class OrderService {
  constructor(private userService: UserService) {}
  
  async createOrder(userId: string) {
    const user = await this.userService.getUser(userId);
    // ...
  }
}

// AFTER: Depend on interface, not implementation

// src/interfaces/user.interface.ts
export interface IUserService {
  getUser(id: string): Promise<User>;
  createUser(data: CreateUserDto): Promise<User>;
}

// src/services/userService.ts
import { IUserService } from '../interfaces/user.interface';

export class UserService implements IUserService {
  async getUser(id: string): Promise<User> { /* ... */ }
  async createUser(data: CreateUserDto): Promise<User> { /* ... */ }
}

// src/services/orderService.ts
import { IUserService } from '../interfaces/user.interface';

export class OrderService {
  constructor(private userService: IUserService) {}  // Interface, not class
  
  async createOrder(userId: string) {
    const user = await this.userService.getUser(userId);
    // ...
  }
}
```

---

## Layer Introduction

### Add Service Layer

```typescript
// BEFORE: Business logic in controller
// src/controllers/userController.ts
export async function createUser(req: Request, res: Response) {
  const { email, name, password } = req.body;
  
  // Validation
  if (!email || !isValidEmail(email)) {
    return res.status(400).json({ error: 'Invalid email' });
  }
  
  // Check duplicate
  const existing = await prisma.user.findUnique({ where: { email } });
  if (existing) {
    return res.status(409).json({ error: 'Email already exists' });
  }
  
  // Hash password
  const hashedPassword = await bcrypt.hash(password, 10);
  
  // Create user
  const user = await prisma.user.create({
    data: { email, name, password: hashedPassword },
  });
  
  // Send welcome email
  await sendEmail(email, 'Welcome!', welcomeTemplate(name));
  
  return res.status(201).json(user);
}

// AFTER: Controller delegates to service

// src/services/user.service.ts
export class UserService {
  async createUser(data: CreateUserDto): Promise<User> {
    await this.validateEmail(data.email);
    await this.checkDuplicate(data.email);
    
    const hashedPassword = await this.hashPassword(data.password);
    const user = await this.userRepository.create({
      ...data,
      password: hashedPassword,
    });
    
    await this.emailService.sendWelcome(user);
    
    return user;
  }
  
  private async validateEmail(email: string): Promise<void> {
    if (!isValidEmail(email)) {
      throw new ValidationError('Invalid email');
    }
  }
  
  private async checkDuplicate(email: string): Promise<void> {
    const existing = await this.userRepository.findByEmail(email);
    if (existing) {
      throw new ConflictError('Email already exists');
    }
  }
}

// src/controllers/userController.ts
export async function createUser(req: Request, res: Response) {
  try {
    const user = await userService.createUser(req.body);
    return res.status(201).json(user);
  } catch (error) {
    return handleError(error, res);
  }
}
```

### Add Repository Layer

```typescript
// BEFORE: Direct database access in service
// src/services/userService.ts
import { prisma } from '../lib/prisma';

export class UserService {
  async getUser(id: string) {
    return prisma.user.findUnique({ where: { id } });
  }
  
  async createUser(data: CreateUserDto) {
    return prisma.user.create({ data });
  }
}

// AFTER: Repository abstracts database access

// src/repositories/user.repository.ts
export class UserRepository {
  async findById(id: string): Promise<User | null> {
    return prisma.user.findUnique({ where: { id } });
  }
  
  async findByEmail(email: string): Promise<User | null> {
    return prisma.user.findUnique({ where: { email } });
  }
  
  async create(data: CreateUserData): Promise<User> {
    return prisma.user.create({ data });
  }
  
  async update(id: string, data: UpdateUserData): Promise<User> {
    return prisma.user.update({ where: { id }, data });
  }
  
  async delete(id: string): Promise<void> {
    await prisma.user.delete({ where: { id } });
  }
}

// src/services/userService.ts
export class UserService {
  constructor(private userRepository: UserRepository) {}
  
  async getUser(id: string) {
    return this.userRepository.findById(id);
  }
  
  async createUser(data: CreateUserDto) {
    // Business logic here
    return this.userRepository.create(data);
  }
}
```

---

## Migration Strategies

### Feature Flag Migration

```typescript
// Use feature flags to gradually migrate

// src/config/features.ts
export const features = {
  useNewUserModule: process.env.USE_NEW_USER_MODULE === 'true',
  useNewOrderFlow: process.env.USE_NEW_ORDER_FLOW === 'true',
};

// src/services/index.ts
import { features } from '../config/features';
import { UserService as OldUserService } from './legacy/userService';
import { UserService as NewUserService } from '../modules/users/user.service';

export const userService = features.useNewUserModule
  ? new NewUserService()
  : new OldUserService();

// Gradually enable in environments:
// 1. Enable in development
// 2. Enable in staging
// 3. Enable for % of production traffic
// 4. Enable for all production
// 5. Remove old code
```

### Parallel Run Validation

```typescript
// Run both old and new code, compare results

async function migratedGetUser(id: string): Promise<User> {
  const [oldResult, newResult] = await Promise.all([
    oldUserService.getUser(id),
    newUserService.getUser(id),
  ]);
  
  // Compare results
  if (JSON.stringify(oldResult) !== JSON.stringify(newResult)) {
    logger.warn('Migration mismatch', {
      userId: id,
      old: oldResult,
      new: newResult,
    });
    
    // Return old result during validation period
    return oldResult;
  }
  
  // Results match, can use new
  return newResult;
}
```

### Strangler Fig Pattern

```
Phase 1: New structure exists alongside old
┌─────────────────────────────────────┐
│  src/                               │
│  ├── services/        (OLD)         │
│  │   ├── userService.ts             │
│  │   └── orderService.ts            │
│  └── modules/         (NEW)         │
│      └── users/                     │
│          └── user.service.ts        │
└─────────────────────────────────────┘

Phase 2: New consumers use new structure
┌─────────────────────────────────────┐
│  New code imports from modules/     │
│  Old code still imports from        │
│  services/ (re-exports to modules/) │
└─────────────────────────────────────┘

Phase 3: Migrate existing consumers
┌─────────────────────────────────────┐
│  Update imports one by one          │
│  Run tests after each change        │
└─────────────────────────────────────┘

Phase 4: Remove old structure
┌─────────────────────────────────────┐
│  src/                               │
│  └── modules/         (ONLY)        │
│      ├── users/                     │
│      └── orders/                    │
└─────────────────────────────────────┘
```

---

## Common Refactoring Recipes

### Recipe: Split God File

```typescript
// 1. Identify responsibilities in the file
// src/services/userService.ts has:
// - User CRUD
// - Email sending
// - Permission checking
// - Password hashing

// 2. Create new files for each responsibility
// src/services/email.service.ts
// src/services/permission.service.ts
// src/utils/password.ts

// 3. Extract functions one at a time
// Move sendEmail to email.service.ts
// Update imports in userService.ts
// Run tests

// 4. Repeat for each responsibility

// 5. Final userService.ts only has user CRUD
// and depends on extracted services
```

### Recipe: Flatten Deep Nesting

```typescript
// BEFORE: 6 levels deep
src/features/users/components/forms/inputs/text/TextInput.tsx

// Step 1: Identify actual usage patterns
// - Is TextInput used only in user forms? → Keep nested
// - Is TextInput used everywhere? → Move to shared

// Step 2: If shared, move to shared/components
src/shared/components/TextInput.tsx

// Step 3: Update re-export for backward compatibility
// src/features/users/components/forms/inputs/text/TextInput.tsx
export { TextInput } from '@/shared/components/TextInput';

// Step 4: Update consumers gradually

// Step 5: Remove re-export when all updated
```

### Recipe: Consolidate Duplicates

```typescript
// 1. Find duplicates
grep -r "function formatDate" src/

// 2. Compare implementations
// Are they identical? Slightly different? Very different?

// 3. If identical: extract to shared
// src/shared/utils/date.ts
export function formatDate(date: Date): string { /* ... */ }

// 4. If slightly different: merge with options
export function formatDate(date: Date, options?: FormatOptions): string {
  const { locale = 'en-US', format = 'short' } = options ?? {};
  // ...
}

// 5. Update all usages
// 6. Delete duplicates
```

### Recipe: Introduce Barrel Files

```typescript
// BEFORE: Import each file individually
import { UserService } from '../services/userService';
import { OrderService } from '../services/orderService';
import { ProductService } from '../services/productService';

// AFTER: Single import from barrel

// src/services/index.ts (barrel file)
export { UserService } from './userService';
export { OrderService } from './orderService';
export { ProductService } from './productService';

// Consumer
import { UserService, OrderService, ProductService } from '../services';

// ⚠️ Warning: Don't overuse barrels
// Only create barrels for commonly imported together items
// Avoid re-exporting everything (causes bundle bloat)
```

---

## Safety Checklist

### Before Refactoring

- [ ] Tests exist and pass
- [ ] Git working directory is clean
- [ ] Branch created for refactoring
- [ ] Team informed of changes

### During Refactoring

- [ ] One change at a time
- [ ] Tests run after each change
- [ ] Commit after each successful change
- [ ] No behavior changes (only structural)

### After Refactoring

- [ ] All tests still pass
- [ ] Application runs correctly
- [ ] No console errors
- [ ] PR reviewed by team
- [ ] Documentation updated if needed
