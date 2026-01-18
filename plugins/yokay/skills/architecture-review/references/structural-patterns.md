# Structural Patterns

Directory structures for different project types.

## Frontend Applications

### React/Next.js Feature-Based

```
src/
├── app/                    # Next.js App Router (or pages/)
│   ├── (auth)/
│   │   ├── login/
│   │   └── register/
│   ├── dashboard/
│   └── layout.tsx
│
├── features/               # Feature modules
│   ├── auth/
│   │   ├── components/
│   │   │   ├── LoginForm.tsx
│   │   │   ├── RegisterForm.tsx
│   │   │   └── index.ts
│   │   ├── hooks/
│   │   │   ├── useAuth.ts
│   │   │   └── useSession.ts
│   │   ├── api/
│   │   │   └── auth.api.ts
│   │   ├── types.ts
│   │   ├── utils.ts
│   │   └── index.ts
│   │
│   ├── users/
│   │   ├── components/
│   │   ├── hooks/
│   │   ├── api/
│   │   └── index.ts
│   │
│   └── orders/
│       └── ...
│
├── shared/                 # Shared across features
│   ├── components/
│   │   ├── ui/            # Generic UI (Button, Input, Modal)
│   │   │   ├── Button.tsx
│   │   │   ├── Input.tsx
│   │   │   └── index.ts
│   │   └── layout/        # Layout components
│   │       ├── Header.tsx
│   │       └── Sidebar.tsx
│   ├── hooks/
│   │   ├── useDebounce.ts
│   │   └── useLocalStorage.ts
│   ├── utils/
│   │   ├── date.ts
│   │   ├── format.ts
│   │   └── validation.ts
│   └── types/
│       └── common.ts
│
├── lib/                    # Third-party integrations
│   ├── api-client.ts      # Axios/fetch setup
│   ├── query-client.ts    # React Query setup
│   └── analytics.ts
│
├── config/
│   └── constants.ts
│
└── styles/
    └── globals.css
```

### Vue/Nuxt Feature-Based

```
src/
├── pages/                  # File-based routing
├── features/
│   ├── auth/
│   │   ├── components/
│   │   ├── composables/   # Vue composables (like hooks)
│   │   ├── stores/        # Pinia stores
│   │   └── index.ts
│   └── users/
├── shared/
│   ├── components/
│   ├── composables/
│   └── utils/
├── stores/                 # Global stores
└── plugins/
```

### Component Library

```
src/
├── components/
│   ├── Button/
│   │   ├── Button.tsx
│   │   ├── Button.test.tsx
│   │   ├── Button.stories.tsx
│   │   ├── Button.module.css
│   │   └── index.ts
│   ├── Input/
│   ├── Modal/
│   └── index.ts           # Main export
│
├── hooks/
│   ├── useClickOutside.ts
│   └── index.ts
│
├── utils/
│   └── cn.ts              # className utility
│
├── types/
│   └── common.ts
│
└── index.ts               # Package entry point
```

---

## Backend Applications

### Express/Fastify Layered

```
src/
├── controllers/            # HTTP layer
│   ├── user.controller.ts
│   ├── order.controller.ts
│   └── index.ts
│
├── services/               # Business logic
│   ├── user.service.ts
│   ├── order.service.ts
│   └── index.ts
│
├── repositories/           # Data access
│   ├── user.repository.ts
│   ├── order.repository.ts
│   └── index.ts
│
├── models/                 # Data structures
│   ├── user.model.ts
│   └── order.model.ts
│
├── middleware/
│   ├── auth.middleware.ts
│   ├── error.middleware.ts
│   └── validation.middleware.ts
│
├── routes/
│   ├── user.routes.ts
│   ├── order.routes.ts
│   └── index.ts
│
├── utils/
│   ├── logger.ts
│   └── errors.ts
│
├── types/
│   └── index.ts
│
├── config/
│   └── index.ts
│
├── database/
│   ├── migrations/
│   ├── seeds/
│   └── connection.ts
│
└── app.ts
```

### NestJS Modular

```
src/
├── modules/
│   ├── auth/
│   │   ├── auth.module.ts
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── strategies/
│   │   │   ├── jwt.strategy.ts
│   │   │   └── local.strategy.ts
│   │   ├── guards/
│   │   │   └── jwt-auth.guard.ts
│   │   ├── dto/
│   │   │   ├── login.dto.ts
│   │   │   └── register.dto.ts
│   │   └── interfaces/
│   │
│   ├── users/
│   │   ├── users.module.ts
│   │   ├── users.controller.ts
│   │   ├── users.service.ts
│   │   ├── users.repository.ts
│   │   ├── entities/
│   │   │   └── user.entity.ts
│   │   └── dto/
│   │
│   └── orders/
│       └── ...
│
├── common/                 # Shared across modules
│   ├── decorators/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   ├── pipes/
│   └── utils/
│
├── config/
│   └── configuration.ts
│
├── database/
│   ├── migrations/
│   └── database.module.ts
│
├── app.module.ts
└── main.ts
```

### Domain-Driven Design (DDD)

```
src/
├── domain/                 # Core business logic
│   ├── user/
│   │   ├── entities/
│   │   │   └── User.ts
│   │   ├── value-objects/
│   │   │   ├── Email.ts
│   │   │   └── UserId.ts
│   │   ├── repositories/
│   │   │   └── IUserRepository.ts
│   │   ├── services/
│   │   │   └── UserDomainService.ts
│   │   └── events/
│   │       └── UserCreatedEvent.ts
│   │
│   └── order/
│       └── ...
│
├── application/            # Use cases
│   ├── user/
│   │   ├── commands/
│   │   │   ├── CreateUserCommand.ts
│   │   │   └── CreateUserHandler.ts
│   │   └── queries/
│   │       ├── GetUserQuery.ts
│   │       └── GetUserHandler.ts
│   │
│   └── order/
│
├── infrastructure/         # External concerns
│   ├── persistence/
│   │   ├── repositories/
│   │   │   └── UserRepository.ts  # Implements IUserRepository
│   │   └── orm/
│   │       └── prisma/
│   ├── messaging/
│   │   └── EventBus.ts
│   └── external-services/
│       └── EmailService.ts
│
├── presentation/           # HTTP/API layer
│   ├── controllers/
│   ├── middleware/
│   └── dto/
│
└── shared/
    ├── kernel/            # Base classes
    │   ├── Entity.ts
    │   ├── ValueObject.ts
    │   └── AggregateRoot.ts
    └── utils/
```

---

## Full-Stack Applications

### Next.js Full-Stack

```
src/
├── app/                    # Frontend pages + API routes
│   ├── api/
│   │   ├── users/
│   │   │   └── route.ts
│   │   └── orders/
│   │       └── route.ts
│   ├── (marketing)/
│   │   └── page.tsx
│   └── (app)/
│       ├── dashboard/
│       └── settings/
│
├── features/               # Shared frontend features
│   └── ...
│
├── server/                 # Backend logic
│   ├── services/
│   ├── repositories/
│   └── db/
│       └── schema.ts      # Drizzle/Prisma schema
│
├── shared/                 # Shared between client/server
│   ├── types/
│   └── validation/        # Zod schemas
│
└── lib/
    ├── db.ts
    └── auth.ts
```

### T3 Stack (Next.js + tRPC)

```
src/
├── app/
│   └── ...
│
├── server/
│   ├── api/
│   │   ├── routers/
│   │   │   ├── user.ts
│   │   │   ├── order.ts
│   │   │   └── index.ts
│   │   ├── trpc.ts
│   │   └── root.ts
│   └── db/
│       └── schema.ts
│
├── features/
│   └── ...
│
└── shared/
    └── ...
```

---

## Monorepo Structures

### Turborepo/Nx Monorepo

```
my-monorepo/
├── apps/
│   ├── web/               # Next.js frontend
│   │   ├── src/
│   │   ├── package.json
│   │   └── tsconfig.json
│   ├── api/               # Backend API
│   │   ├── src/
│   │   └── package.json
│   └── admin/             # Admin dashboard
│       └── ...
│
├── packages/
│   ├── ui/                # Shared UI components
│   │   ├── src/
│   │   │   ├── Button.tsx
│   │   │   └── index.ts
│   │   └── package.json
│   ├── config/            # Shared configs
│   │   ├── eslint/
│   │   └── typescript/
│   ├── utils/             # Shared utilities
│   │   └── src/
│   └── types/             # Shared types
│       └── src/
│
├── package.json
├── turbo.json
└── pnpm-workspace.yaml
```

### Package Naming Convention

```
@myorg/ui           # Shared UI
@myorg/utils        # Shared utilities
@myorg/config       # Shared configuration
@myorg/types        # Shared types
@myorg/api-client   # Generated API client
@myorg/database     # Database schema/client
```

---

## Library/Package Structure

### npm Package

```
my-package/
├── src/
│   ├── index.ts           # Main entry
│   ├── core/
│   │   ├── Client.ts
│   │   └── types.ts
│   ├── utils/
│   │   └── helpers.ts
│   └── errors/
│       └── CustomError.ts
│
├── tests/
│   ├── Client.test.ts
│   └── helpers.test.ts
│
├── dist/                   # Built output
│   ├── index.js
│   ├── index.d.ts
│   └── index.mjs
│
├── package.json
├── tsconfig.json
├── tsup.config.ts         # Build config
└── README.md
```

### CLI Tool

```
my-cli/
├── src/
│   ├── index.ts           # Entry point
│   ├── cli.ts             # CLI setup (commander/yargs)
│   ├── commands/
│   │   ├── init.ts
│   │   ├── build.ts
│   │   └── deploy.ts
│   ├── utils/
│   │   ├── fs.ts
│   │   └── logger.ts
│   └── types/
│       └── config.ts
│
├── templates/             # Template files for init
│   └── ...
│
├── bin/
│   └── cli.js            # Executable entry
│
└── package.json
```

---

## Test Organization

### Colocated Tests (Recommended)

```
src/
├── features/
│   └── users/
│       ├── components/
│       │   ├── UserList.tsx
│       │   └── UserList.test.tsx    # Next to component
│       ├── hooks/
│       │   ├── useUsers.ts
│       │   └── useUsers.test.ts
│       └── user.service.ts
│           user.service.test.ts
```

### Separate Test Directory

```
src/
├── features/
│   └── users/
│       ├── components/
│       └── hooks/
│
tests/
├── unit/
│   └── features/
│       └── users/
│           ├── UserList.test.tsx
│           └── useUsers.test.ts
├── integration/
│   └── api/
│       └── users.test.ts
└── e2e/
    └── user-flow.test.ts
```

---

## Configuration Files Organization

### Root Level (Standard)

```
my-project/
├── .env                   # Environment (git-ignored)
├── .env.example           # Template
├── .eslintrc.js
├── .prettierrc
├── .gitignore
├── tsconfig.json
├── package.json
├── vitest.config.ts
├── tailwind.config.js
└── next.config.js
```

### Config Directory (For Complex)

```
my-project/
├── config/
│   ├── eslint/
│   │   ├── base.js
│   │   └── react.js
│   ├── typescript/
│   │   ├── base.json
│   │   └── react.json
│   └── vitest/
│       └── setup.ts
│
├── .eslintrc.js          # extends from config/
├── tsconfig.json         # extends from config/
└── vitest.config.ts      # references config/
```

---

## When to Choose Which Pattern

| Project Type | Recommended Structure |
|--------------|----------------------|
| Small app (<20 components) | Flat/simple |
| Medium app (20-100 components) | Feature-based |
| Large app (100+ components) | Feature-based with strict boundaries |
| Component library | Component-per-folder |
| REST API | Layered (controllers/services/repos) |
| Complex domain | DDD |
| Multiple apps | Monorepo |
| npm package | Standard package structure |

### Decision Factors

**Use Feature-Based when:**
- Multiple developers/teams
- Features are independent
- Features may be removed/added frequently
- Code ownership matters

**Use Layer-Based when:**
- Small team
- Features share lots of code
- Traditional MVC background
- Simpler mental model needed

**Use DDD when:**
- Complex business rules
- Domain experts involved
- Long-term maintainability critical
- Multiple bounded contexts
