# Skill Routing

Logic for assigning skills to features and managing the workflow between them.

> **Note:** Design work routes to design plugin via `/design:*` commands

## Skill Catalog

Available skills that can be assigned to features:

| Skill | Purpose | Input | Output |
|-------|---------|-------|--------|
| `api-design` | REST/GraphQL API design | Feature requirements | OpenAPI spec, endpoints |
| `testing-strategy` | API test suites | API spec | Test files |
| `frontend-design` | Frontend architecture | Requirements | Component structure |
| `sdk-development` | SDK/library creation | API spec | SDK package |
| `cloud-infrastructure` | AWS/cloud provisioning, IaC | Architecture requirements | CDK stacks, IAM, networking |
| `feature-audit` | Completeness audit | Codebase | Gap report |

---

## Assignment Rules

### By Feature Type

```python
def assign_skills(feature: dict) -> list[str]:
    """Assign skills based on feature characteristics."""
    
    skills = []
    title = feature['title'].lower()
    description = feature.get('description', '').lower()
    
    # API/Backend features
    if any(word in title + description for word in [
        'api', 'endpoint', 'backend', 'service', 'integration',
        'authentication', 'authorization', 'webhook', 'sync'
    ]):
        skills.append('api-design')

    # Cloud/Infrastructure features
    if any(word in title + description for word in [
        'aws', 'cloud', 'infrastructure', 'deploy', 'lambda',
        'ecs', 'fargate', 'cdk', 'terraform', 'iam', 'vpc',
        's3', 'dynamodb', 'rds', 'cloudfront', 'serverless'
    ]):
        skills.append('cloud-infrastructure')

    # SDK/Library features
    if any(word in title + description for word in [
        'sdk', 'library', 'package', 'npm', 'client'
    ]):
        skills.append('sdk-development')

    # If no skills assigned, default based on priority
    if not skills:
        skills = ['api-design']
    
    return skills
```

### Skill Order Rules

Skills should run in this order:

```
1. API
   - api-design (endpoints, contracts)
   - testing-strategy (after API implemented)

2. Implementation
   - sdk-development (if SDK needed)

3. Quality
   - feature-audit (final audit)
```

### Dependency Graph

```
      ┌──────────────┐
      │  api-design  │
      └──────┬───────┘
             │
             ▼
      ┌──────────────┐
      │  testing-strategy │
      └──────┬───────┘
             │
             ▼
      ┌──────────────┐
      │sdk-development│
      └──────┬───────┘
             │
             ▼
      ┌──────────────┐
      │feature-audit│
      └──────────────┘
```

---

## Feature to Skill Mapping

### Common Feature Types

| Feature Pattern | Primary | Secondary | Order |
|-----------------|---------|-----------|-------|
| "REST API for X" | api-design | testing-strategy | api → testing |
| "Slack Integration" | api-design | — | api |
| "SDK/Client Library" | sdk-development | — | sdk |
| "Deploy to AWS" | cloud-infrastructure | ci-cd | cloud → ci-cd |
| "Lambda + API Gateway" | cloud-infrastructure | api-design | cloud → api |

### Example Assignments

```json
{
  "features": [
    {
      "id": "F002",
      "title": "RAG Pipeline",
      "type_signals": ["api", "backend", "service"],
      "assigned_skills": ["api-design"],
      "skill_order": ["api-design"]
    },
    {
      "id": "F003",
      "title": "Chat API",
      "type_signals": ["api", "realtime"],
      "assigned_skills": ["api-design", "testing-strategy"],
      "skill_order": ["api-design", "testing-strategy"]
    },
    {
      "id": "F026",
      "title": "Mobile SDK",
      "type_signals": ["sdk", "mobile", "library"],
      "assigned_skills": ["sdk-development"],
      "skill_order": ["sdk-development"]
    }
  ]
}
```

---

## Skill State Tracking

### In ohno

ohno has no skill-specific fields, so track skill assignments on the entities it does have — never write ohno's internal database directly.

- **PROJECT.md is the source of truth** for skill assignments — keep its "Skill Assignments" table (see below) up to date.
- **Epic descriptions carry the routing state.** When planning assigns skills, append a line via `mcp__ohno__update_epic`:

```
Skills: api-design → testing-strategy | Current: api-design
```

- **Query features by skill** with the CLI (global `--json` flag):

```bash
# Epics currently routed to api-design
npx @stevestomp/ohno-cli epics --json | node -e '
const epics = JSON.parse(require("fs").readFileSync(0, "utf8"));
for (const e of epics) {
  if ((e.description || "").includes("Current: api-design")) {
    console.log(`${e.id}\t${e.priority}\t${e.title}`);
  }
}'
```

### Skill Transition

When a skill completes its work on an epic, advance the `Current:` marker to the next skill in the `Skills:` chain via `mcp__ohno__update_epic` (or remove the marker when the chain is done), and update the PROJECT.md skill assignments table in the same pass.

---

## Routing Logic for Claude Code

### Reading Assigned Work

When a skill is invoked, it should:

1. Read `.claude/PROJECT.md` and find its rows in the "Skill Assignments" table.
2. Confirm against ohno — `mcp__ohno__get_epics` (or the CLI query above), filtering for epics whose description lists it as `Current:` and whose status isn't done.
3. Work highest priority first (P0 → P1 → P2 → P3).

### Marking Work Complete

When a skill finishes an epic:

1. Advance the `Current:` marker to the next skill in the `Skills:` chain via `mcp__ohno__update_epic` — or, if it was the last skill, remove the marker.
2. Log what was done via `mcp__ohno__add_task_activity` on the affected tasks.
3. Update PROJECT.md ("Skill Assignments" table and "Next Actions").

---

## PROJECT.md Skill Section

### Template

```markdown
## Skill Assignments

### By Skill

| Skill | Features | Priority | Status |
|-------|----------|----------|--------|
| api-design | F002, F007, F008 | P0, P0, P0 | pending |
| testing-strategy | F002, F007 | P0, P0 | blocked |
| sdk-development | F026 | P1 | not started |
| feature-audit | All features | — | not started |

### Skill Dependencies

```
api-design ──────────────────► testing-strategy
                                     │
                                     ▼
                              sdk-development
                                     │
                                     ▼
                              feature-audit
```

### Next Skill to Run

Based on dependencies and P0 priorities:
1. **api-design** for F002 (RAG Pipeline) — no blockers

After those complete:
2. **testing-strategy** for F002, F007
```

---

## Automation Helpers

### Pending Work by Skill

```bash
# Group open epics by their Current: skill marker
npx @stevestomp/ohno-cli epics --json | node -e '
const epics = JSON.parse(require("fs").readFileSync(0, "utf8"));
const groups = {};
for (const e of epics) {
  const m = (e.description || "").match(/Current: ([a-z-]+)/);
  if (!m || e.status === "done") continue;
  (groups[m[1]] ||= []).push(`${e.id} (${e.priority})`);
}
for (const [skill, features] of Object.entries(groups)) {
  console.log(`${skill}: ${features.join(", ")}`);
}'
```

### Bash: Check Next Skill

```bash
#!/bin/bash
# next-skill.sh - Determine which skill to run next

echo "=== Next Skill to Run ==="

# First open P0 epic with a pending skill marker
npx @stevestomp/ohno-cli epics --json | node -e '
const epics = JSON.parse(require("fs").readFileSync(0, "utf8"));
const next = epics.find(e => e.priority === "P0" && e.status !== "done" &&
  /Current: [a-z-]+/.test(e.description || ""));
if (next) {
  console.log(`${next.description.match(/Current: ([a-z-]+)/)[1]} — ${next.id}: ${next.title}`);
} else {
  console.log("No pending P0 skill work");
}'
```

---

## Edge Cases

### Feature Needs Multiple Skills Simultaneously

Some features may need parallel work:
- API design + testing can happen after implementation

Handle with:
```json
{
  "skill_order": [
    "api-design",      // sequential
    "testing-strategy"      // sequential
  ]
}
```

### Skill Not Available

If a skill isn't in the user's collection:
1. Check `.claude/skills/` for available skills
2. Suggest alternative or manual approach
3. Log gap in PROJECT.md

### Feature Doesn't Need Any Skills

Pure configuration or documentation features:
```json
{
  "assigned_skills": [],
  "skill_order": [],
  "notes": "Manual configuration, no skill needed"
}
```

---

## Integration Checklist

### planning Output
- [ ] Every feature has assigned skills and a skill order
- [ ] Each epic's `Skills:` line sets `Current:` to the first skill in its chain (via `mcp__ohno__update_epic`)
- [ ] PROJECT.md includes skill assignments section

### Skill Invocation
- [ ] Skill reads PROJECT.md first
- [ ] Skill queries ohno for assigned work (`mcp__ohno__get_epics` / `npx @stevestomp/ohno-cli epics --json`)
- [ ] Skill updates status when complete
- [ ] Skill transitions to next skill in order

### feature-audit Audit
- [ ] Runs after all skills complete
- [ ] Checks implementation matches assignments
- [ ] Records audit results in ohno (see feature-audit's gap-analysis reference)
- [ ] Adds remediation tasks if gaps found
