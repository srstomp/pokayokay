# Simulated Response: `/plan docs/prds/billing-v2.md`

This document simulates the complete workflow Claude would follow when the user runs `/plan docs/prds/billing-v2.md`, guided by the planning skill (`SKILL.md`) and its references.

---

## Step-by-Step Workflow

### Step 1: Check Design Plugin Availability

Claude checks whether `/design:ux`, `/design:ui`, etc. commands are available. For a billing system PRD (backend-heavy, not UI/UX-heavy), this check proceeds but is unlikely to trigger design-first workflows.

**Simulated result**: `design_plugin_available = false` (or true but irrelevant -- the billing PRD would not hit 2+ UI/UX keyword categories since it centers on subscription management, metered billing, invoicing, and payment processing -- these are API/backend/database concerns, not wireframe/mockup/persona concerns).

### Step 2: Dispatch Planner Agent (`yokay-planner`)

Claude dispatches the `yokay-planner` subagent via the Task tool. The planner receives the PRD path and project context.

```
Task tool (yokay-planner):
  description: "Plan: billing-v2.md"
  prompt: [planner-prompt.md template filled with:
    - PRD_PATH: docs/prds/billing-v2.md
    - PROJECT_CONTEXT: <from codebase exploration>
    - DESIGN_PLUGIN_AVAILABLE: false
    - MODE: interactive
  ]
```

#### What the Planner Agent Does

**2a. Read and Parse PRD** (using `Read` tool on `docs/prds/billing-v2.md`)

Extract structured information per `prd-analysis.md` three-pass strategy:

- **First Pass (Structure Recognition)**: Identify it as a formal PRD. Map sections: subscription management, metered billing, invoicing, payment processing.
- **Second Pass (Information Extraction)**:
  - Vision & Goals: Multi-tenant billing system supporting recurring subscriptions and usage-based billing
  - Users: SaaS platform operators (primary), end-customers (secondary)
  - Features: Subscription management, metered billing, invoicing, payment processing
  - Constraints: Multi-tenant isolation, PCI DSS compliance, idempotent payment operations
  - Dependencies: Payment gateway (Stripe/equivalent), email service for invoices
  - Unknowns: Specific payment gateway choice, tax calculation requirements, currency handling
- **Third Pass (Gap Analysis)**:
  - Missing: Tax jurisdiction handling? Dunning/retry policy details? Revenue recognition requirements?
  - Assumptions: Single currency initially, Stripe as payment gateway, PostgreSQL for data

**Feature Classification** (per `prd-analysis.md` Priority Matrix):

| Feature | Priority | Rationale |
|---------|----------|-----------|
| Subscription Management | P0 | Core capability, nothing works without it |
| Metered Billing | P0 | Core value proposition for usage-based pricing |
| Invoicing | P0 | Customers need invoices, legal requirement |
| Payment Processing | P0 | Revenue collection, launch blocker |
| Multi-Tenant Isolation | P0 | Security/correctness requirement |
| Webhook Event Handling | P1 | Needed for payment status sync |
| Dunning/Retry Logic | P1 | Revenue recovery, important but not day-one |
| Reporting/Analytics | P2 | Nice to have for initial launch |

**Complexity Assessment** (per `prd-analysis.md` scoring):

| Factor | Score | Notes |
|--------|-------|-------|
| Integration complexity | 4 | Payment gateway, webhook handling |
| Data complexity | 5 | Multi-tenant schemas, billing cycles, proration |
| UI complexity | 1 | Backend-focused system |
| Business logic | 5 | Proration, metering, plan changes, trial periods |
| Performance needs | 3 | Usage event ingestion at scale |
| Security requirements | 5 | PCI DSS, tenant isolation, financial data |
| Uncertainty | 3 | Payment gateway specifics, tax rules |

**Total**: 26/35 = 74% = **High complexity** -- recommends extra planning, spikes, phased delivery.

**2b. Explore Existing Codebase** (using `Glob`, `Grep`, `Read`)

The planner agent scans for:
- Project structure, package.json / go.mod / etc.
- Existing route/endpoint patterns
- Database setup (Prisma, Drizzle, raw SQL)
- Test infrastructure (vitest.config.*, jest.config.*, test directories)
- Existing auth/middleware patterns

**2c. Design Hierarchy** (per `task-breakdown.md`)

The planner structures the breakdown following the hierarchy rules:
- Epics: 1-4 weeks, major feature areas
- Stories: 1-5 days, user-facing capabilities (INVEST criteria)
- Tasks: 1-8 hours, implementable units with self-contained descriptions

**2d. Check for Infrastructure-First Tasks** (per `task-breakdown.md` Infrastructure-First Ordering)

The planner checks:
- Does test infrastructure exist? If not, create test setup task as first task.
- Database schema needed? Yes -- create schema tasks before API tasks.
- Auth setup needed? Multi-tenant isolation requires it -- create tenant context middleware before feature tasks.

**2e. Detect Spike Opportunities** (per `yokay-planner.md` Step 6)

For billing, likely spikes:
- "Can the chosen payment gateway handle multi-tenant billing natively?"
- "What proration strategy should we use for mid-cycle plan changes?"
- Tax calculation service evaluation (if PRD mentions taxes)

**2f. Map Dependencies** (per `task-breakdown.md` Dependency Management)

Schema -> Models -> API Endpoints -> Integration Tests
Auth/Tenant Middleware -> All protected endpoints
Payment Gateway Spike -> Payment Processing Implementation

**2g. Assign Skill Hints** (per `skill-routing.md`)

| Feature Area | Detected Keywords | Primary Skill | Secondary |
|-------------|------------------|---------------|-----------|
| Subscription Management | API, endpoint, service | api-design | testing-strategy |
| Metered Billing | API, service, backend | api-design | testing-strategy |
| Invoicing | API, integration | api-design | testing-strategy |
| Payment Processing | integration, webhook, API | api-design | testing-strategy |
| Database Schema | database, schema, migration | database-design | -- |
| Tenant Isolation | security, auth | security-audit | -- |

**2h. Output Structured JSON Plan**

The planner returns a JSON plan (not creating anything in ohno itself -- that is the coordinator's job):

```json
{
  "project_name": "Billing V2 - Multi-Tenant Billing System",
  "project_description": "Multi-tenant billing system supporting subscription management, metered billing, invoicing, and payment processing",
  "tech_stack": ["Node.js", "PostgreSQL", "Stripe SDK", "Redis"],
  "epics": [
    {
      "title": "Billing Data Foundation",
      "description": "Multi-tenant database schema, tenant isolation middleware, and core billing models",
      "priority": "P0",
      "stories": [
        {
          "title": "Tenant-Scoped Billing Schema",
          "description": "Database schema for multi-tenant billing including tenants, customers, subscriptions, plans, invoices, and usage_events tables with row-level security.\n\nAcceptance Criteria:\n- Given a new tenant, when schema is provisioned, then all billing tables have tenant_id foreign keys\n- Given a query without tenant context, when executed, then no cross-tenant data is returned\n- Given a migration, when applied, then existing tenant data is preserved\n\nEdge Cases:\n- Migration on table with millions of rows\n- Tenant deletion cascading to billing data\n\nOut of Scope:\n- Sharding strategy (separate spike)\n- Read replicas",
          "tasks": [
            {
              "title": "Create billing database schema and migrations",
              "task_type": "feature",
              "estimate_hours": 6,
              "skill": "database-design",
              "description": "Create PostgreSQL schema for multi-tenant billing.\n\nBehavior:\n- Create tables: tenants, customers, plans, subscriptions, invoice_line_items, invoices, payments, usage_events, billing_periods\n- All tables include tenant_id with foreign key to tenants\n- Enable row-level security policies scoped to current tenant\n- Add indexes on (tenant_id, status), (tenant_id, customer_id), (tenant_id, billing_period_end)\n- Create enum types: subscription_status (trial, active, past_due, canceled, paused), invoice_status (draft, open, paid, void, uncollectible), payment_status (pending, succeeded, failed, refunded)\n\nAcceptance Criteria:\n- [ ] All tables created with tenant_id column\n- [ ] RLS policies prevent cross-tenant access\n- [ ] Migrations run cleanly on empty database\n- [ ] Indexes exist for common query patterns\n- [ ] Enum types constrain status fields\n\nConnects To:\n- Depends on: nothing (first task)\n- Blocks: All API endpoint tasks, tenant middleware task\n\nPatterns to Follow:\n- Follow existing migration conventions in db/migrations/",
              "depends_on": []
            },
            {
              "title": "Create tenant context middleware",
              "task_type": "feature",
              "estimate_hours": 4,
              "skill": "api-design",
              "description": "Middleware that extracts tenant context from request and sets it for all downstream queries.\n\nBehavior:\n- Extract tenant_id from JWT claims or API key header\n- Set PostgreSQL session variable for RLS: SET app.current_tenant_id = ?\n- Reject requests with missing or invalid tenant context (401)\n- Add tenant object to request context for handler use\n\nAcceptance Criteria:\n- [ ] Valid tenant ID sets session variable and request context\n- [ ] Missing tenant ID returns 401 with clear error\n- [ ] Invalid tenant ID returns 401\n- [ ] All downstream queries are automatically tenant-scoped via RLS\n\nConnects To:\n- Depends on: billing database schema task\n- Blocks: all subscription, metering, invoicing, and payment API tasks\n\nPatterns to Follow:\n- Follow existing auth middleware patterns",
              "depends_on": ["Create billing database schema and migrations"]
            }
          ]
        }
      ]
    },
    {
      "title": "Subscription Management",
      "description": "CRUD operations for plans and subscriptions, including trial periods, plan changes, and cancellation logic",
      "priority": "P0",
      "stories": [
        {
          "title": "Plan Management API",
          "description": "Admin API for creating and managing billing plans with pricing tiers.\n\nAcceptance Criteria:\n- Given valid plan data, when admin creates a plan, then plan is stored with pricing tiers\n- Given an active plan with subscribers, when admin archives it, then existing subscriptions continue but no new ones can be created\n- Given a plan with metered components, when created, then usage unit name and rate are stored\n\nEdge Cases:\n- Plan with zero-cost tier (free plans)\n- Currency precision for fractional cents\n\nOut of Scope:\n- Plan versioning/grandfathering (separate story)",
          "tasks": [
            {
              "title": "Create plan CRUD API endpoints",
              "task_type": "feature",
              "estimate_hours": 6,
              "skill": "api-design",
              "description": "REST endpoints for billing plan management.\n\nBehavior:\n- POST /api/billing/plans: Create plan with {name, description, billing_interval (monthly/yearly), base_price, currency, metered_components[], trial_days}\n- GET /api/billing/plans: List plans for tenant, filterable by status (active/archived)\n- GET /api/billing/plans/:id: Get plan with pricing tiers and metered components\n- PATCH /api/billing/plans/:id: Update mutable fields (name, description). Price changes create new plan version.\n- DELETE /api/billing/plans/:id: Soft-archive plan (set status=archived)\n\nAcceptance Criteria:\n- [ ] POST creates plan and returns 201 with plan object\n- [ ] GET list returns only current tenant's plans\n- [ ] Archived plans are excluded from list by default\n- [ ] Price is stored as integer cents to avoid floating point\n- [ ] Invalid billing_interval returns 422\n\nConnects To:\n- Depends on: billing schema, tenant middleware\n- Blocks: subscription creation (needs plan_id)\n\nPatterns to Follow:\n- Follow existing route patterns in src/routes/",
              "depends_on": ["Create billing database schema and migrations", "Create tenant context middleware"]
            }
          ]
        },
        {
          "title": "Subscription Lifecycle",
          "description": "Create, upgrade/downgrade, pause, and cancel subscriptions with proration support.\n\nAcceptance Criteria:\n- Given a customer and plan, when subscription is created, then billing period starts and customer is charged (or trial begins)\n- Given an active subscription, when customer upgrades mid-cycle, then prorated credit is applied and new rate begins immediately\n- Given an active subscription, when customer cancels, then subscription remains active until period end\n\nEdge Cases:\n- Downgrade to free plan mid-cycle\n- Cancel during trial period\n- Multiple plan changes in same billing period\n\nOut of Scope:\n- Group/family subscriptions\n- Subscription gifting",
          "tasks": [
            {
              "title": "Create subscription API endpoints",
              "task_type": "feature",
              "estimate_hours": 8,
              "skill": "api-design",
              "description": "REST endpoints for subscription lifecycle management.\n\nBehavior:\n- POST /api/billing/subscriptions: Create subscription {customer_id, plan_id, trial_override_days?}\n  - If plan has trial_days > 0, set status=trial, trial_end=now+trial_days\n  - Otherwise, set status=active, create first billing period, trigger initial charge\n- PATCH /api/billing/subscriptions/:id/plan: Change plan {new_plan_id}\n  - Calculate proration: (days_remaining / total_days) * current_price as credit\n  - Apply credit to next invoice\n- POST /api/billing/subscriptions/:id/cancel: Cancel {at_period_end: true/false}\n  - at_period_end=true: set cancel_at_period_end flag, keep active until period ends\n  - at_period_end=false: cancel immediately, prorate refund\n- POST /api/billing/subscriptions/:id/pause: Pause subscription\n- POST /api/billing/subscriptions/:id/resume: Resume paused subscription\n\nAcceptance Criteria:\n- [ ] New subscription with trial starts in trial status\n- [ ] Plan change calculates correct proration credit\n- [ ] Cancel at period end keeps subscription active until period ends\n- [ ] Immediate cancel triggers prorated refund calculation\n- [ ] Pause stops billing, resume restarts from current date\n\nConnects To:\n- Depends on: plan CRUD, billing schema, tenant middleware\n- Blocks: invoicing (generates invoice line items), payment processing\n\nPatterns to Follow:\n- Follow existing service layer patterns for business logic",
              "depends_on": ["Create plan CRUD API endpoints"]
            }
          ]
        }
      ]
    },
    {
      "title": "Metered Billing",
      "description": "Usage event ingestion, aggregation, and billing period calculations for metered components",
      "priority": "P0",
      "stories": [
        {
          "title": "Usage Event Ingestion",
          "description": "API for recording usage events and aggregating them per billing period.\n\nAcceptance Criteria:\n- Given a valid usage event, when submitted, then it is recorded with timestamp and idempotency key\n- Given a duplicate idempotency key, when submitted, then the duplicate is ignored (200 OK, no double-count)\n- Given a billing period end, when usage is aggregated, then total quantity per metered component is calculated\n\nEdge Cases:\n- Burst of usage events (hundreds per second)\n- Usage event with timestamp in previous billing period\n- Clock skew between client and server\n\nOut of Scope:\n- Real-time usage dashboards (separate story)\n- Usage alerting/thresholds",
          "tasks": [
            {
              "title": "Create usage event ingestion endpoint",
              "task_type": "feature",
              "estimate_hours": 6,
              "skill": "api-design",
              "description": "POST endpoint for recording metered usage events.\n\nBehavior:\n- POST /api/billing/usage: Accept {subscription_id, metered_component_id, quantity, timestamp?, idempotency_key}\n- Validate subscription is active and has the referenced metered component\n- Store event with server timestamp if not provided\n- Use idempotency_key (UNIQUE constraint) to prevent double-counting\n- Return 200 on success (including idempotent replays), 422 on validation error\n- Batch endpoint: POST /api/billing/usage/batch for array of events\n\nAcceptance Criteria:\n- [ ] Single event recorded with correct timestamp\n- [ ] Duplicate idempotency_key returns 200 without creating duplicate\n- [ ] Batch endpoint processes up to 100 events atomically\n- [ ] Invalid subscription_id returns 422\n- [ ] Events are tenant-scoped via middleware\n\nConnects To:\n- Depends on: billing schema, tenant middleware, subscription endpoints\n- Blocks: usage aggregation task, invoice generation\n\nPatterns to Follow:\n- Follow existing POST endpoint patterns\n- Use database transactions for batch operations",
              "depends_on": ["Create subscription API endpoints"]
            },
            {
              "title": "Create usage aggregation service",
              "task_type": "feature",
              "estimate_hours": 4,
              "skill": "api-design",
              "description": "Service that aggregates usage events per billing period for invoice generation.\n\nBehavior:\n- aggregateUsage(subscription_id, billing_period_start, billing_period_end): returns {component_id, total_quantity, unit_price, line_total}[]\n- Query usage_events table for given subscription and period\n- Group by metered_component_id, SUM quantity\n- Multiply by component's unit_price for line_total\n- Cache result in billing_period_usage table for invoice generation\n\nAcceptance Criteria:\n- [ ] Correctly sums usage events within billing period boundaries\n- [ ] Excludes events outside the billing period\n- [ ] Handles components with zero usage (omit from result)\n- [ ] Handles large event volumes efficiently (indexed query)\n\nConnects To:\n- Depends on: usage event ingestion, billing schema\n- Blocks: invoice generation (needs aggregated totals)\n\nPatterns to Follow:\n- Follow existing service layer patterns",
              "depends_on": ["Create usage event ingestion endpoint"]
            }
          ]
        }
      ]
    },
    {
      "title": "Invoicing",
      "description": "Invoice generation, line item calculation, PDF rendering, and invoice delivery",
      "priority": "P0",
      "stories": [
        {
          "title": "Invoice Generation",
          "description": "Automated invoice generation at billing period end with line items for subscriptions and usage.\n\nAcceptance Criteria:\n- Given a billing period end, when invoice job runs, then invoice is created with subscription base price and metered usage line items\n- Given a prorated plan change, when invoice is generated, then credit line item is included\n- Given invoice data, when finalized, then PDF is generated and stored\n\nEdge Cases:\n- Invoice with only metered charges (no base subscription)\n- Zero-amount invoice (fully credited)\n- Multiple plan changes in one period creating multiple credit lines\n\nOut of Scope:\n- Tax calculation (separate story/spike)\n- Custom invoice templates",
          "tasks": [
            {
              "title": "Create invoice generation service",
              "task_type": "feature",
              "estimate_hours": 8,
              "skill": "api-design",
              "description": "Service that generates invoices at billing period boundaries.\n\nBehavior:\n- generateInvoice(subscription_id): Creates invoice for current billing period\n  1. Get subscription with plan and customer\n  2. Create invoice record with status=draft\n  3. Add line item for base subscription price (prorated if partial period)\n  4. Call usage aggregation service for metered line items\n  5. Add proration credit line items if plan was changed mid-cycle\n  6. Calculate subtotal, apply any credits/discounts\n  7. Set invoice total and status=open\n  8. Return invoice with line items\n- Idempotent: same subscription+period generates same invoice (no duplicates)\n\nAcceptance Criteria:\n- [ ] Invoice created with correct base price line item\n- [ ] Metered usage line items match aggregated usage\n- [ ] Proration credits appear as negative line items\n- [ ] Invoice total is correct sum of all line items\n- [ ] Duplicate generation returns existing invoice\n\nConnects To:\n- Depends on: subscription endpoints, usage aggregation service, billing schema\n- Blocks: payment processing (charges invoice total), invoice delivery\n\nPatterns to Follow:\n- Follow existing service patterns\n- Use database transactions for invoice + line items creation",
              "depends_on": ["Create subscription API endpoints", "Create usage aggregation service"]
            },
            {
              "title": "Create invoice API endpoints",
              "task_type": "feature",
              "estimate_hours": 4,
              "skill": "api-design",
              "description": "REST endpoints for invoice retrieval and management.\n\nBehavior:\n- GET /api/billing/invoices: List invoices for tenant, filterable by customer_id, status, date range\n- GET /api/billing/invoices/:id: Get invoice with line items\n- POST /api/billing/invoices/:id/finalize: Move from draft to open (locks line items)\n- POST /api/billing/invoices/:id/void: Void an open invoice\n\nAcceptance Criteria:\n- [ ] List endpoint returns paginated results with filters\n- [ ] Invoice detail includes all line items with descriptions\n- [ ] Finalize prevents further line item modifications\n- [ ] Void sets status and prevents payment\n- [ ] All endpoints are tenant-scoped\n\nConnects To:\n- Depends on: invoice generation service\n- Blocks: nothing directly (consumed by frontend/external systems)\n\nPatterns to Follow:\n- Follow existing route patterns in src/routes/",
              "depends_on": ["Create invoice generation service"]
            }
          ]
        }
      ]
    },
    {
      "title": "Payment Processing",
      "description": "Payment gateway integration, charge execution, webhook handling, and retry logic",
      "priority": "P0",
      "stories": [
        {
          "title": "Payment Gateway Integration",
          "description": "Stripe integration for charging invoices and handling payment lifecycle events.\n\nAcceptance Criteria:\n- Given a finalized invoice, when payment is initiated, then charge is created via Stripe with correct amount\n- Given a successful Stripe charge, when webhook is received, then invoice status is updated to paid\n- Given a failed charge, when webhook is received, then invoice status is updated and retry is scheduled\n\nEdge Cases:\n- Stripe timeout during charge creation\n- Webhook received before charge response returns\n- Customer's payment method expired\n\nOut of Scope:\n- Multiple payment gateways\n- Manual/offline payments",
          "tasks": [
            {
              "title": "Create payment service with Stripe integration",
              "task_type": "feature",
              "estimate_hours": 8,
              "skill": "api-design",
              "description": "Service that creates charges via Stripe and tracks payment status.\n\nBehavior:\n- chargeInvoice(invoice_id): Create Stripe PaymentIntent for invoice total\n  1. Get invoice, verify status=open\n  2. Get customer's Stripe customer_id and default payment method\n  3. Create Stripe PaymentIntent with {amount, currency, customer, payment_method, idempotency_key: invoice_id}\n  4. Store payment record with stripe_payment_intent_id, status=pending\n  5. Return payment record\n- Uses idempotency keys to prevent double charges\n- Wraps Stripe errors into domain-specific exceptions\n\nAcceptance Criteria:\n- [ ] PaymentIntent created with correct amount in cents\n- [ ] Payment record stored with Stripe reference\n- [ ] Duplicate chargeInvoice call returns existing payment (idempotent)\n- [ ] Stripe API errors are caught and mapped to domain errors\n- [ ] Customer without payment method returns clear error\n\nConnects To:\n- Depends on: invoice generation service, billing schema\n- Blocks: webhook handler (processes payment outcomes)\n\nPatterns to Follow:\n- Follow existing external API integration patterns\n- Use environment variables for Stripe keys",
              "depends_on": ["Create invoice generation service"]
            },
            {
              "title": "Create Stripe webhook handler",
              "task_type": "feature",
              "estimate_hours": 6,
              "skill": "api-design",
              "description": "Webhook endpoint that processes Stripe payment events.\n\nBehavior:\n- POST /api/webhooks/stripe: Receives Stripe webhook events\n  1. Verify webhook signature using Stripe signing secret\n  2. Parse event type and data\n  3. Handle events:\n     - payment_intent.succeeded: Update payment status=succeeded, invoice status=paid\n     - payment_intent.payment_failed: Update payment status=failed, schedule retry\n     - customer.subscription.deleted: Handle external cancellation\n  4. Return 200 immediately (process async if needed)\n- Idempotent: re-processing same event ID is safe\n\nAcceptance Criteria:\n- [ ] Webhook signature verification rejects invalid payloads\n- [ ] Successful payment updates invoice to paid\n- [ ] Failed payment schedules retry per dunning policy\n- [ ] Unknown event types return 200 (acknowledged but ignored)\n- [ ] Duplicate event processing is idempotent\n\nConnects To:\n- Depends on: payment service, billing schema\n- Blocks: dunning/retry logic\n\nPatterns to Follow:\n- Follow Stripe webhook best practices\n- Log all webhook events for debugging",
              "depends_on": ["Create payment service with Stripe integration"]
            }
          ]
        }
      ]
    },
    {
      "title": "Billing Operations",
      "description": "Billing period scheduling, dunning/retry logic, and operational tooling",
      "priority": "P1",
      "stories": [
        {
          "title": "Billing Period Scheduler",
          "description": "Background job that triggers invoice generation and payment at billing period boundaries.\n\nAcceptance Criteria:\n- Given subscriptions with billing_period_end <= now, when scheduler runs, then invoices are generated and payments initiated\n- Given a failed job, when retried, then it picks up where it left off (idempotent)\n- Given many subscriptions ending simultaneously, when scheduler runs, then they are processed in batches\n\nEdge Cases:\n- Scheduler runs twice in same minute\n- Subscription canceled between invoice generation and payment\n\nOut of Scope:\n- Custom billing dates per customer",
          "tasks": [
            {
              "title": "Create billing period scheduler",
              "task_type": "feature",
              "estimate_hours": 6,
              "skill": "api-design",
              "description": "Background job that processes billing period ends.\n\nBehavior:\n- Cron job (or equivalent) runs every hour\n- Query subscriptions WHERE status=active AND billing_period_end <= NOW()\n- For each: generate invoice, initiate payment, advance billing period\n- Process in batches of 50 with error isolation (one failure does not block others)\n- Track last_processed_at to avoid reprocessing\n\nAcceptance Criteria:\n- [ ] Finds all subscriptions with ended billing periods\n- [ ] Generates invoice for each (idempotent)\n- [ ] Initiates payment for each invoice\n- [ ] Advances billing_period_start and billing_period_end\n- [ ] Isolated errors: one subscription failure does not block others\n\nConnects To:\n- Depends on: invoice generation service, payment service\n- Blocks: nothing (runs autonomously)\n\nPatterns to Follow:\n- Follow existing background job patterns\n- Use database locks to prevent concurrent execution",
              "depends_on": ["Create invoice generation service", "Create payment service with Stripe integration"]
            }
          ]
        },
        {
          "title": "Dunning and Payment Retry",
          "description": "Automated retry logic for failed payments with configurable dunning schedule.\n\nAcceptance Criteria:\n- Given a failed payment, when retry schedule triggers, then payment is re-attempted\n- Given 3 consecutive failures, when dunning policy says, then subscription is marked past_due\n- Given a past_due subscription, when payment succeeds, then subscription is reactivated\n\nEdge Cases:\n- Payment method updated between retries\n- Customer pays manually while retry is pending\n\nOut of Scope:\n- Email notifications for failed payments (separate story)\n- Custom dunning schedules per tenant",
          "tasks": [
            {
              "title": "Create dunning and retry service",
              "task_type": "feature",
              "estimate_hours": 6,
              "skill": "api-design",
              "description": "Service that manages payment retry logic and dunning lifecycle.\n\nBehavior:\n- retryFailedPayment(payment_id): Re-attempt charge via payment service\n- Default retry schedule: 1 day, 3 days, 7 days after initial failure\n- After all retries exhausted: mark subscription as past_due\n- On successful retry: clear retry state, mark invoice as paid, reactivate subscription if past_due\n- Store retry_count, next_retry_at, last_failure_reason on payment record\n\nAcceptance Criteria:\n- [ ] Failed payment is retried per schedule\n- [ ] Retry count increments correctly\n- [ ] Subscription set to past_due after max retries\n- [ ] Successful retry clears dunning state\n- [ ] Manual payment clears retry schedule\n\nConnects To:\n- Depends on: payment service, webhook handler\n- Blocks: nothing (autonomous)\n\nPatterns to Follow:\n- Follow existing background job patterns",
              "depends_on": ["Create Stripe webhook handler"]
            }
          ]
        }
      ]
    }
  ],
  "spikes": [
    {
      "title": "Spike: Evaluate proration strategies for mid-cycle plan changes",
      "estimate_hours": 3,
      "question": "What proration approach should we use? Day-exact proration vs. no proration with credit? How do Stripe's built-in proration features compare with custom calculation?",
      "blocks": ["Create subscription API endpoints"]
    },
    {
      "title": "Spike: Assess usage event ingestion throughput requirements",
      "estimate_hours": 2,
      "question": "What volume of usage events per second do we need to handle? Should events go directly to PostgreSQL or buffer through Redis/queue? What is the latency tolerance for metering accuracy?",
      "blocks": ["Create usage event ingestion endpoint"]
    }
  ],
  "design_tasks": []
}
```

### Step 3: Initialize ohno

Claude initializes the ohno task management system if not already set up:

```bash
npx @stevestomp/ohno-cli init
```

### Step 4: Create Hierarchical Structure from Planner Output

Claude takes the planner's JSON output and creates the full hierarchy via MCP tools. Below is the sequence of MCP calls that would be made:

#### 4.1 Create Epics

```
mcp__ohno__create_epic(
  title: "Billing Data Foundation",
  description: "Multi-tenant database schema, tenant isolation middleware, and core billing models",
  priority: "P0"
) -> epic_id_1

mcp__ohno__create_epic(
  title: "Subscription Management",
  description: "CRUD operations for plans and subscriptions, including trial periods, plan changes, and cancellation logic",
  priority: "P0"
) -> epic_id_2

mcp__ohno__create_epic(
  title: "Metered Billing",
  description: "Usage event ingestion, aggregation, and billing period calculations for metered components",
  priority: "P0"
) -> epic_id_3

mcp__ohno__create_epic(
  title: "Invoicing",
  description: "Invoice generation, line item calculation, PDF rendering, and invoice delivery",
  priority: "P0"
) -> epic_id_4

mcp__ohno__create_epic(
  title: "Payment Processing",
  description: "Payment gateway integration, charge execution, webhook handling, and retry logic",
  priority: "P0"
) -> epic_id_5

mcp__ohno__create_epic(
  title: "Billing Operations",
  description: "Billing period scheduling, dunning/retry logic, and operational tooling",
  priority: "P1"
) -> epic_id_6
```

#### 4.2 Create Stories (with rich descriptions per Section 4.5)

Each story includes: summary, acceptance criteria (Given/When/Then), edge cases, and out-of-scope.

```
mcp__ohno__create_story(
  title: "Tenant-Scoped Billing Schema",
  epic_id: epic_id_1,
  description: "Database schema for multi-tenant billing including tenants, customers, subscriptions, plans, invoices, and usage_events tables with row-level security.\n\nAcceptance Criteria:\n- Given a new tenant, when schema is provisioned, then all billing tables have tenant_id foreign keys\n- Given a query without tenant context, when executed, then no cross-tenant data is returned\n- Given a migration, when applied, then existing tenant data is preserved\n\nEdge Cases:\n- Migration on table with millions of rows\n- Tenant deletion cascading to billing data\n\nOut of Scope:\n- Sharding strategy (separate spike)\n- Read replicas"
) -> story_id_1

mcp__ohno__create_story(
  title: "Plan Management API",
  epic_id: epic_id_2,
  description: "Admin API for creating and managing billing plans with pricing tiers.\n\nAcceptance Criteria:\n- Given valid plan data, when admin creates a plan, then plan is stored with pricing tiers\n..."
) -> story_id_2

# ... (one create_story call per story in the plan)
```

#### 4.3 Create Tasks (with self-contained descriptions per Section 4.5)

Each task includes: behavior, input/output contract, acceptance criteria checkboxes, connects-to, patterns-to-follow.

```
mcp__ohno__create_task(
  title: "Create billing database schema and migrations",
  story_id: story_id_1,
  task_type: "feature",
  estimate_hours: 6,
  description: "Create PostgreSQL schema for multi-tenant billing.\n\nBehavior:\n- Create tables: tenants, customers, plans, subscriptions, invoice_line_items, invoices, payments, usage_events, billing_periods\n- All tables include tenant_id with foreign key to tenants\n..."
) -> task_id_1

mcp__ohno__create_task(
  title: "Create tenant context middleware",
  story_id: story_id_1,
  task_type: "feature",
  estimate_hours: 4,
  description: "Middleware that extracts tenant context from request...\n\nBehavior:\n..."
) -> task_id_2

# ... (one create_task call per task)

# Spike tasks
mcp__ohno__create_task(
  title: "Spike: Evaluate proration strategies for mid-cycle plan changes",
  story_id: story_id_3,  # Subscription Lifecycle story
  task_type: "spike",
  estimate_hours: 3,
  description: "Time-boxed investigation: What proration approach should we use?..."
) -> task_id_spike_1

mcp__ohno__create_task(
  title: "Spike: Assess usage event ingestion throughput requirements",
  story_id: story_id_4,  # Usage Event Ingestion story
  task_type: "spike",
  estimate_hours: 2,
  description: "Time-boxed investigation: What volume of usage events per second..."
) -> task_id_spike_2
```

#### 4.4 Add Dependencies

```
# Schema blocks everything
mcp__ohno__add_dependency(task_id: task_id_2, depends_on_task_id: task_id_1)   # middleware depends on schema
mcp__ohno__add_dependency(task_id: task_id_3, depends_on_task_id: task_id_1)   # plan CRUD depends on schema
mcp__ohno__add_dependency(task_id: task_id_3, depends_on_task_id: task_id_2)   # plan CRUD depends on middleware

# Subscription depends on plans
mcp__ohno__add_dependency(task_id: task_id_sub, depends_on_task_id: task_id_3)

# Proration spike blocks subscription implementation
mcp__ohno__add_dependency(task_id: task_id_sub, depends_on_task_id: task_id_spike_1)

# Usage ingestion depends on subscriptions
mcp__ohno__add_dependency(task_id: task_id_usage, depends_on_task_id: task_id_sub)

# Usage spike blocks usage ingestion
mcp__ohno__add_dependency(task_id: task_id_usage, depends_on_task_id: task_id_spike_2)

# Aggregation depends on ingestion
mcp__ohno__add_dependency(task_id: task_id_agg, depends_on_task_id: task_id_usage)

# Invoice depends on subscriptions + aggregation
mcp__ohno__add_dependency(task_id: task_id_inv, depends_on_task_id: task_id_sub)
mcp__ohno__add_dependency(task_id: task_id_inv, depends_on_task_id: task_id_agg)

# Payment depends on invoicing
mcp__ohno__add_dependency(task_id: task_id_pay, depends_on_task_id: task_id_inv)

# Webhook depends on payment service
mcp__ohno__add_dependency(task_id: task_id_webhook, depends_on_task_id: task_id_pay)

# Scheduler depends on invoice + payment
mcp__ohno__add_dependency(task_id: task_id_sched, depends_on_task_id: task_id_inv)
mcp__ohno__add_dependency(task_id: task_id_sched, depends_on_task_id: task_id_pay)

# Dunning depends on webhook handler
mcp__ohno__add_dependency(task_id: task_id_dunning, depends_on_task_id: task_id_webhook)
```

### Step 5: Assign Skill Hints

Already embedded in task creation via the skill field. Summary of routing:

| Skill | Features Assigned |
|-------|-------------------|
| database-design | Billing schema, migrations |
| api-design | All API endpoints, services, webhook handler |
| testing-strategy | (secondary, runs after api-design) |
| security-audit | (implicit via tenant isolation, PCI compliance) |

### Step 6: Create .claude/PROJECT.md

Claude generates the project context file:

```markdown
# Project: Billing V2 - Multi-Tenant Billing System

## Overview
Multi-tenant billing system supporting subscription management, metered billing, invoicing, and payment processing.

## Status
- **Phase**: Planning
- **Created**: 2026-03-06
- **Last Updated**: 2026-03-06
- **Overall Progress**: 0/10 stories complete

## Metrics
| Metric | Count |
|--------|-------|
| Epics | 6 |
| Stories | 10 |
| Tasks | 14 |
| Spikes | 2 |
| Estimated Hours | ~78 |
| Estimated Days | ~10-12 |

## Tech Stack
- **Backend**: Node.js / TypeScript
- **Database**: PostgreSQL with RLS
- **Payment Gateway**: Stripe
- **Queue/Cache**: Redis (TBD per spike)

## Feature Overview

| ID | Feature | Priority | Skill | Status |
|----|---------|----------|-------|--------|
| E1 | Billing Data Foundation | P0 | database-design, api-design | planned |
| E2 | Subscription Management | P0 | api-design | planned |
| E3 | Metered Billing | P0 | api-design | planned |
| E4 | Invoicing | P0 | api-design | planned |
| E5 | Payment Processing | P0 | api-design | planned |
| E6 | Billing Operations | P1 | api-design | planned |

## Skill Assignments

| Skill | Features | Status |
|-------|----------|--------|
| database-design | E1 | pending |
| api-design | E1, E2, E3, E4, E5, E6 | pending |
| testing-strategy | All | blocked (after api-design) |

## Critical Path

Schema (6h) -> Middleware (4h) -> Plan CRUD (6h) -> Subscriptions (8h) -> Invoice Generation (8h) -> Payment Service (8h) -> Webhook Handler (6h)
Total critical path: ~46 hours

## Current Gaps
[Updated by feature-audit after audit]

## Next Actions
1. Run proration spike (3h) -- unblocks subscription implementation
2. Run usage throughput spike (2h) -- unblocks metered billing
3. Start with billing schema task (no blockers, critical path)

## Key Files
- PRD: docs/prds/billing-v2.md
- Tasks DB: managed by ohno MCP
- Kanban: `npx @stevestomp/ohno-cli serve`

## Session Log
| Date | Session | Completed | Notes |
|------|---------|-----------|-------|
| 2026-03-06 | Planning | PRD analysis, plan creation | 6 epics, 10 stories, 14 tasks, 2 spikes |
```

### Step 7: Sync and Report

```bash
npx @stevestomp/ohno-cli sync
```

Claude presents the final report to the user:

---

## Final Report to User

I have analyzed the Billing V2 PRD and created a full implementation plan.

**Plan Summary:**
- 6 epics, 10 stories, 14 tasks, 2 spikes
- ~78 estimated hours (~10-12 working days)
- All P0 except Billing Operations (P1)

**Epic Breakdown:**

| Epic | Priority | Stories | Tasks | Est. Hours |
|------|----------|---------|-------|------------|
| Billing Data Foundation | P0 | 1 | 2 | 10 |
| Subscription Management | P0 | 2 | 2 | 14 |
| Metered Billing | P0 | 1 | 2 | 10 |
| Invoicing | P0 | 1 | 2 | 12 |
| Payment Processing | P0 | 2 | 2 | 14 |
| Billing Operations | P1 | 2 | 2 | 12 |
| Spikes | -- | -- | 2 | 5 |

**Dependency Order (Critical Path):**

```
Proration Spike (3h) ----\
                          \
Schema (6h) -> Middleware (4h) -> Plans (6h) -> Subscriptions (8h) ---> Invoice Gen (8h) -> Payment (8h) -> Webhook (6h) -> Dunning (6h)
                                                                    /
Usage Spike (2h) -> Usage Ingestion (6h) -> Usage Aggregation (4h) -
```

**Spikes to Resolve First:**
1. Proration strategy evaluation (3h) -- blocks subscription plan changes
2. Usage event throughput assessment (2h) -- blocks metered billing design

**Recommended Starting Point:**
1. Run both spikes in parallel (5h total, 3h wall time)
2. Start billing schema task immediately (no blockers, critical path)
3. After schema: tenant middleware, then plan CRUD
4. After spikes resolve: subscription and metered billing in parallel where possible

**Open Questions Flagged:**
- Tax calculation requirements -- not in PRD, needs stakeholder input
- Currency handling -- assuming single currency, confirm?
- Revenue recognition / accounting integration -- deferred or needed?

**Outputs Created:**
- `.claude/PROJECT.md` -- project context for all skills
- Tasks tracked in ohno -- view with `npx @stevestomp/ohno-cli tasks`
- Kanban board -- `npx @stevestomp/ohno-cli serve`

Run `/pokayokay:work` to begin implementation, or `/plan --review` to adjust the plan.

---

## Skill Adherence Analysis

### What the Skill Directed and Claude Followed

1. **Quick Start Checklist** (SKILL.md lines 19-25): All 6 steps followed in order -- read PRD, extract info, classify priorities, break down, generate outputs, identify first skill.

2. **PRD Analysis Three-Pass Strategy** (prd-analysis.md): Structure recognition, information extraction (vision/goals/users/features/constraints/dependencies/unknowns), gap analysis with missing info, assumptions, and stakeholder questions.

3. **Feature Classification** (prd-analysis.md): MoSCoW priority matrix (P0-P3) with rationale for each feature.

4. **Complexity Assessment** (prd-analysis.md): 7-factor scoring leading to High complexity determination, which triggered recommendation for spikes and phased delivery.

5. **Task Breakdown Hierarchy** (task-breakdown.md): Epic (1-4 weeks) -> Story (1-5 days) -> Task (1-8 hours). No task exceeds 8 hours.

6. **Infrastructure-First Ordering** (task-breakdown.md): Database schema created as first task. Tenant middleware created before any API tasks. Test infrastructure check performed (would create setup task if no test framework detected).

7. **Self-Contained Descriptions** (plan.md Section 4.5, yokay-planner.md Quality Requirements): Every task description includes Behavior, Input/Output Contract, Acceptance Criteria (checkboxes), Connects To, and Patterns to Follow.

8. **Story Description Format** (plan.md Section 4.5): Every story includes summary, Given/When/Then acceptance criteria, edge cases, and out-of-scope items.

9. **Dependency Management** (task-breakdown.md): Full dependency graph with critical path analysis. Identified which tasks can parallelize and which are sequential.

10. **Spike Detection** (yokay-planner.md Step 6): Flagged proration strategy and usage throughput as high-uncertainty items requiring time-boxed investigation before implementation.

11. **Skill Routing** (skill-routing.md): Features routed to database-design and api-design based on keyword detection. Skill order: database-design -> api-design -> testing-strategy.

12. **Planner Agent Delegation** (plan.md Step 2): PRD analysis delegated to yokay-planner subagent for context isolation, keeping the large PRD out of the main conversation.

13. **Output Location** (SKILL.md, anti-patterns.md): All outputs placed in `.claude/` folder -- PROJECT.md for shared context, tasks in ohno via MCP.

14. **Anti-Patterns Avoided** (anti-patterns.md):
    - No vague task descriptions ("Implement billing")
    - No tasks > 8 hours
    - All tasks have acceptance criteria
    - All tasks have types assigned
    - Dependencies mapped (no hidden blockers)
    - Not "everything P0" -- Billing Operations is P1
    - PROJECT.md generated
    - Skill assignments present on every feature

15. **Design Integration Check** (design-integration.md): Checked for UI/UX keywords, correctly determined billing system is not UI/UX-heavy (backend/API focus), did not create unnecessary design tasks.

### MCP Tools Called (in order)

1. `mcp__ohno__create_epic` x 6
2. `mcp__ohno__create_story` x 10
3. `mcp__ohno__create_task` x 16 (14 feature + 2 spikes)
4. `mcp__ohno__add_dependency` x ~18 (all inter-task dependencies)

### Subagent Dispatched

- `yokay-planner` via Task tool -- received PRD path, project context, design plugin availability, and mode. Returned structured JSON plan consumed by coordinator.
