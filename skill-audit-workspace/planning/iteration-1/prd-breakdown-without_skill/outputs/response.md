# Simulated Claude Response (Without Planning Skill)

## What Claude Would Do

Claude would attempt to read the PRD, fail, then improvise a plan based on the user's description of what the PRD covers. Without the planning skill's structured methodology, the response would be a reasonable but significantly weaker implementation plan.

---

## Step-by-Step Behavior

### Step 1: Attempt to Read the PRD

Claude would call `Read` on `docs/prds/billing-v2.md`. This would fail (file doesn't exist). Claude would tell the user the file wasn't found and ask for the correct path or the content directly.

**In the simulated scenario**, let's assume the user says: "Just work from my description -- subscription management, metered billing, invoicing, and payment processing for a multi-tenant system."

### Step 2: Explore the Codebase

Claude would use Glob and Grep to understand the existing project structure, tech stack, and conventions. This step is the same with or without the skill -- Claude's general instinct is to understand context before planning.

### Step 3: Produce a Plan

Without the skill, Claude would generate a plan in free-form markdown. Here is what that would likely look like:

---

## Implementation Plan: Multi-Tenant Billing System v2

### Epic 1: Tenant & Account Foundation (P0)

**Goal**: Establish multi-tenant data model and account management.
**Estimate**: ~1 week

#### Story 1.1: Tenant Data Model
- Task: Design tenant schema with isolation strategy (4h)
- Task: Create tenant CRUD API endpoints (4h)
- Task: Add tenant context middleware (3h)

#### Story 1.2: Account Management
- Task: Create account/organization model linked to tenants (3h)
- Task: Build account settings API (4h)

### Epic 2: Subscription Management (P0)

**Goal**: Users can subscribe to plans, upgrade, downgrade, cancel.
**Estimate**: ~2 weeks

#### Story 2.1: Plan Configuration
- Task: Design subscription plans schema (3h)
- Task: Create plan management API (admin) (4h)
- Task: Build plan listing endpoint (public) (2h)

#### Story 2.2: Subscription Lifecycle
- Task: Implement subscribe flow (4h)
- Task: Implement upgrade/downgrade with proration (6h)
- Task: Implement cancellation and grace period (4h)
- Task: Handle subscription renewal logic (4h)

#### Story 2.3: Trial Management
- Task: Add trial period support to subscriptions (3h)
- Task: Build trial expiration notifications (3h)

### Epic 3: Metered Billing (P0)

**Goal**: Track and bill for usage-based resources.
**Estimate**: ~2 weeks

#### Story 3.1: Usage Tracking
- Task: Design usage events schema (3h)
- Task: Create usage ingestion API (4h)
- Task: Build usage aggregation service (6h)

#### Story 3.2: Metering Configuration
- Task: Define metering rules per plan (4h)
- Task: Implement tiered/volume pricing calculations (6h)

#### Story 3.3: Usage Reporting
- Task: Build current-period usage summary API (4h)
- Task: Create usage history endpoint (3h)

### Epic 4: Invoicing (P1)

**Goal**: Generate, manage, and deliver invoices.
**Estimate**: ~1.5 weeks

#### Story 4.1: Invoice Generation
- Task: Design invoice schema with line items (4h)
- Task: Build invoice generation engine (6h)
- Task: Handle proration line items (4h)

#### Story 4.2: Invoice Delivery
- Task: Create PDF invoice renderer (4h)
- Task: Build email delivery for invoices (3h)

#### Story 4.3: Invoice Management
- Task: Create invoice listing/detail API (3h)
- Task: Implement credit notes and adjustments (4h)

### Epic 5: Payment Processing (P1)

**Goal**: Accept payments, handle failures, manage payment methods.
**Estimate**: ~1.5 weeks

#### Story 5.1: Payment Gateway Integration
- Task: Integrate Stripe (or chosen gateway) SDK (4h)
- Task: Implement payment method storage (tokenization) (4h)

#### Story 5.2: Payment Execution
- Task: Build payment execution service (4h)
- Task: Implement retry logic for failed payments (4h)
- Task: Create dunning management flow (4h)

#### Story 5.3: Payment History
- Task: Build payment history API (3h)
- Task: Create refund processing endpoint (4h)

### Dependencies

- Epic 1 blocks Epics 2-5 (tenant model is foundational)
- Epic 2 (subscription) blocks Epic 3 (metered billing needs plan context)
- Epics 2 + 3 block Epic 4 (invoicing aggregates subscription + usage charges)
- Epic 4 blocks Epic 5 (payments settle invoices)

### Rough Timeline

| Week | Focus |
|------|-------|
| 1 | Tenant foundation + subscription schemas |
| 2-3 | Subscription lifecycle + metered billing |
| 4 | Metered billing completion + invoicing start |
| 5 | Invoicing + payment integration |
| 6 | Payment processing + integration testing |

---

## Quality Issues in This Response (vs. Skill-Guided)

The above plan is what Claude would realistically produce. Comparing against the planning skill's methodology, the following deficiencies are present:

### 1. No Structured PRD Analysis Phase
- **Missing**: Gap analysis, ambiguity flagging, assumption documentation, stakeholder questions
- **Skill does**: Three-pass analysis (structure recognition, information extraction, gap analysis) with explicit "Questions for Stakeholder" and "Assumptions Made" sections
- **Impact**: Claude proceeds with assumptions it never surfaces. The user doesn't know what Claude guessed vs. what was specified.

### 2. No Priority Classification Methodology
- **Missing**: MoSCoW matrix (P0-P3), per-feature priority rationale, explicit scope boundaries
- **Skill does**: Feature-by-feature priority assessment with user impact, technical complexity, and rationale fields
- **Impact**: Claude assigned P0/P1 loosely. No P2/P3 items identified. No "Out of Scope" or "Deferred" sections.

### 3. Task Descriptions Are Not Self-Contained
- **Missing**: Behavior specifications, input/output contracts, acceptance criteria checkboxes, "Connects To" sections, "Patterns to Follow" references
- **Skill does**: Enforces 5 required sections per task description; warns that "the implementer agent receives task descriptions as its ONLY context"
- **Impact**: These tasks would fail when dispatched to yokay-implementer. "Implement upgrade/downgrade with proration (6h)" tells the implementer almost nothing about what to build.

### 4. No Story Acceptance Criteria
- **Missing**: Given/When/Then acceptance criteria, edge cases, out-of-scope items per story
- **Skill does**: Requires 3-5 acceptance criteria in Given/When/Then format, 2-3 edge cases, and explicit out-of-scope items per story
- **Impact**: Stories have no testable definition of "done."

### 5. No Complexity Assessment
- **Missing**: Scored complexity factors (integration, data, UI, business logic, performance, security, uncertainty)
- **Skill does**: 7-factor complexity scoring that drives approach decisions (standard planning vs. extra spikes)
- **Impact**: No basis for adjusting estimates or identifying where spikes are needed.

### 6. No Spike Detection
- **Missing**: High-uncertainty items not flagged as spikes
- **Skill does**: Flags "Can we...?" questions, feasibility unknowns, and technology selection as spikes that block dependent tasks
- **Impact**: Multi-tenant isolation strategy, payment gateway selection, metered billing aggregation approach -- all should be spikes. Instead they're estimated as regular tasks.

### 7. No Skill Routing
- **Missing**: No skill hints assigned to tasks
- **Skill does**: Routes every task to a skill (api-design, database-design, testing-strategy, etc.) based on keyword matching
- **Impact**: When the coordinator dispatches tasks, it won't know which skill to activate. The implementer works without domain guidance.

### 8. No JSON Output for ohno Integration
- **Missing**: Plan is free-form markdown, not structured JSON consumable by the coordinator
- **Skill does**: Returns structured JSON with epics, stories, tasks, spikes, and design_tasks -- ready for the coordinator to loop through and call `mcp__ohno__create_epic`, `create_story`, `create_task`
- **Impact**: The coordinator would need to manually parse prose to create tasks in ohno, or the user would need to create them by hand.

### 9. No ohno MCP Usage
- **Missing**: No calls to `mcp__ohno__create_epic`, `create_story`, `create_task`, `add_dependency`
- **Skill does**: The planner agent returns JSON, then the coordinator iterates it to create the full hierarchy in ohno with proper dependency links
- **Impact**: The plan exists only as text. No tracked tasks, no dependency graph, no kanban board, no automated workflow.

### 10. No Test Infrastructure Check
- **Missing**: No verification of whether test framework exists, no test setup task
- **Skill does**: Explores codebase for test config files; if none found, creates a test-setup task as the first task that all feature tasks depend on
- **Impact**: Implementation tasks may fail TDD requirements because there's no test framework configured.

### 11. Dependency Mapping Is Shallow
- **Missing**: No dependency matrix, no critical path analysis, no per-task `depends_on` references
- **Skill does**: Task-level dependency mapping with critical path identification and blockers
- **Impact**: "Epic 1 blocks Epics 2-5" is too coarse. Within epics, there's no ordering. Parallel work opportunities are invisible.

### 12. Estimates Lack Methodology
- **Missing**: No estimation adjustments for new technology, unclear requirements, integration complexity; no confidence ranges
- **Skill does**: Estimation adjustment table (+50-100% for new tech, +30-50% for unclear requirements, etc.)
- **Impact**: "Implement upgrade/downgrade with proration (6h)" is almost certainly underestimated. No buffer for the payment gateway integration learning curve.

### 13. No Design-First Detection
- **Missing**: No check for whether a design plugin is available, no design tasks before implementation
- **Skill does**: Detects design plugin availability; creates design tasks with dependencies blocking implementation tasks
- **Impact**: If the billing system has any UI (dashboard, invoice views, payment forms), implementation starts without designs.

### 14. No `.claude/` Output Artifacts
- **Missing**: No PROJECT.md, features.json, kanban.html, or tasks.db
- **Skill does**: Generates all four artifacts in `.claude/` for project tracking and coordination
- **Impact**: No shared project context file, no machine-readable feature list, no visual kanban board.

---

## Summary Scorecard

| Dimension | With Skill | Without Skill | Gap |
|-----------|-----------|---------------|-----|
| PRD Analysis Depth | 3-pass structured extraction | Skim user's description | Critical |
| Ambiguity Handling | Flagged + questions generated | Silently assumed | Critical |
| Task Description Quality | Self-contained, 5 required sections | Title + vague 1-liner | Critical |
| Story Acceptance Criteria | Given/When/Then + edge cases | None | Critical |
| Dependency Granularity | Task-level with critical path | Epic-level only | High |
| Spike Detection | Explicit spike tasks | None | High |
| Skill Routing | Per-task skill hints | None | High |
| ohno Integration | Full JSON → create_epic/story/task | None (prose only) | Critical |
| Estimation Rigor | Methodology + adjustments | Gut feel numbers | Medium |
| Test Infrastructure | Auto-detected + setup task | Not considered | Medium |
| Output Artifacts | PROJECT.md, features.json, kanban | None | Medium |
| Complexity Assessment | 7-factor scored | None | Low |

**Overall**: Without the planning skill, Claude produces a "looks reasonable" plan that would fail operationally. Tasks can't be dispatched to implementer agents (descriptions too vague), nothing gets tracked in ohno (no structured output), dependencies are too coarse for parallel execution, and critical unknowns aren't surfaced as spikes. The plan is a starting point for human refinement, not an executable work breakdown.
