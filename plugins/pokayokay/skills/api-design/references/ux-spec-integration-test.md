# UX Spec Integration Tests

This document provides test scenarios to verify the api-design skill correctly integrates with UX specification artifacts.

## Test Overview

The api-design skill should:
1. Checks for `.claude/design/*/ux-spec.md` files
2. Parses user flows and interaction patterns
3. Extracts endpoint requirements from user actions
4. Maps flows to API endpoints
5. Documents the integration in API design output
6. Works gracefully when no ux-spec.md exists

## Test 1: Basic Discovery

**Objective:** Skill checks for `.claude/design/*/ux-spec.md` pattern

**Setup:**
```bash
mkdir -p .claude/design/my-api
echo "# UX Spec: My API" > .claude/design/my-api/ux-spec.md
```

**Test:**
Run api-design skill and verify it discovers the ux-spec.md file.

**Expected:**
- Skill finds `.claude/design/my-api/ux-spec.md`
- Skill reads the file
- No errors

**Assertions:**
```bash
assert_file_read(".claude/design/my-api/ux-spec.md")
assert_no_errors()
```

## Test 2: Flow to Endpoint Mapping

**Objective:** Skill extracts endpoints from user flows

**Setup:**
```bash
cat > .claude/design/test-project/ux-spec.md << 'EOF'
# UX Spec: E-commerce Checkout

## User Flows

### Primary Flow: Checkout

**Entry Point:** Cart page with items

**Steps:**
1. User reviews cart items (products, quantities, subtotal)
2. User selects shipping method (standard, express)
3. User enters payment information
4. User confirms order
5. System displays confirmation with order number

## Interaction Patterns

**Update Quantity:**
- **What:** Click +/- buttons
- **Does:** Updates item quantity, recalculates total
- **Edge cases:** Min quantity 1, max 99

**Apply Coupon:**
- **What:** Enter coupon code
- **Does:** Validates code, applies discount
- **Edge cases:** Invalid code, expired coupon
EOF
```

**Test:**
Run api-design skill and verify it extracts appropriate endpoints.

**Expected Endpoints:**
- `GET /cart` - View cart items (Step 1)
- `GET /shipping-methods` - List shipping options (Step 2)
- `POST /orders` - Create order (Step 4)
- `GET /orders/{id}` - View confirmation (Step 5)
- `PATCH /cart/items/{id}` - Update quantity (Interaction)
- `POST /cart/coupons` - Apply coupon (Interaction)

**Assertions:**
```bash
assert_endpoint_defined("GET /cart")
assert_endpoint_defined("GET /shipping-methods")
assert_endpoint_defined("POST /orders")
assert_endpoint_defined("GET /orders/{id}")
assert_endpoint_defined("PATCH /cart/items/{id}")
assert_endpoint_defined("POST /cart/coupons")
```

## Test 3: Resource Identification

**Objective:** Skill identifies resources from UX nouns

**Setup:**
```bash
echo "# UX Spec: Library System" > .claude/design/project/ux-spec.md
```

Add user flow:
```markdown
## User Flows

**Steps:**
1. User searches for books by title or author
2. User views book details and availability
3. User adds book to reading list
4. User checks out book
5. User views their checked-out books
```

**Test:**
Run api-design skill and verify resource identification.

**Expected Resources:**
- `books` (collection)
- `reading-lists` or `users/{id}/reading-list` (nested)
- `checkouts` or `users/{id}/checkouts` (nested)

**Assertions:**
```bash
assert_resource_identified("books")
assert_resource_identified("reading-list" OR "reading-lists")
assert_resource_identified("checkouts")
```

## Test 4: Edge Cases to Error Mapping

**Objective:** Skill maps UX edge cases to error responses

**Setup:**
```bash
cat > .claude/design/project/ux-spec.md << 'EOF'
# UX Spec: Booking System

## Interaction Patterns

**Book Appointment:**
- **What:** Select time slot and confirm
- **Does:** Creates appointment reservation
- **Edge cases:**
  - Time slot already booked → Show error
  - Outside business hours → Prevent selection
  - User already has appointment → Warn and confirm
EOF
```

**Test:**
Run api-design skill and verify error handling.

**Expected Error Mappings:**
- Time slot booked → 409 Conflict
- Outside business hours → 400 Bad Request
- Duplicate appointment → 409 Conflict with warning

**Assertions:**
```bash
assert_error_response("POST /appointments", 409, "Time slot already booked")
assert_error_response("POST /appointments", 400, "Outside business hours")
```

## Test 5: No UX Spec (Backward Compatibility)

**Objective:** Skill works normally when no ux-spec.md exists

**Setup:**
```bash
rm -rf .claude/design
```

**Test:**
Run api-design skill with normal inputs (no ux-spec.md available).

**Expected:**
- Skill proceeds with standard API design process
- No errors about missing ux-spec.md
- Optional info message: "No UX specification found"
- API design output is complete and valid

**Assertions:**
```bash
assert_no_errors()
assert_optional_message("No UX specification found" OR "No design artifacts")
assert_output_complete()
```

## Test 6: Multiple UX Specs

**Objective:** Skill handles multiple design projects

**Setup:**
```bash
mkdir -p .claude/design/project-a
mkdir -p .claude/design/project-b
echo "# UX Spec: Project A" > .claude/design/project-a/ux-spec.md
echo "# UX Spec: Project B" > .claude/design/project-b/ux-spec.md
```

**Test:**
Run api-design skill without specifying which project.

**Expected:**
- Skill finds both ux-spec.md files
- Skill prompts user to select which project
- User selects project-a
- Skill uses `.claude/design/project-a/ux-spec.md`

**Assertions:**
```bash
assert_files_found(2)
assert_user_prompted("Which project")
assert_selected_file(".claude/design/project-a/ux-spec.md")
```

## Test 7: Automatic Selection by Context

**Objective:** Skill auto-selects UX spec based on context

**Setup:**
```bash
mkdir -p .claude/design/checkout
mkdir -p .claude/design/admin
echo "# UX Spec: Checkout" > .claude/design/checkout/ux-spec.md
echo "# UX Spec: Admin" > .claude/design/admin/ux-spec.md
```

**Test:**
Run api-design with request: "Design API for checkout flow"

**Expected:**
- Skill finds both ux-spec.md files
- Skill auto-selects `.claude/design/checkout/ux-spec.md` (matches "checkout")
- No user prompt needed

**Assertions:**
```bash
assert_auto_selected(".claude/design/checkout/ux-spec.md")
assert_no_user_prompt()
```

## Test 8: Documentation Output

**Objective:** Skill documents UX integration in API design

**Setup:**
```bash
echo "# UX Spec: API" > .claude/design/my-api/ux-spec.md
```

Add simple flow:
```markdown
## User Flows
**Steps:**
1. User creates account
2. User verifies email
```

**Test:**
Run api-design skill and verify output documentation.

**Expected Output Sections:**
```markdown
## Design Integration

**UX Specification:** `.claude/design/my-api/ux-spec.md`

### User Flow Mapping

| Flow Step | API Endpoint | Notes |
|-----------|--------------|-------|
| Create account | POST /users | Creates user account |
| Verify email | POST /users/{id}/verify-email | Verifies email with token |
```

**Assertions:**
```bash
assert_output_contains("Design Integration")
assert_output_contains("UX Specification: \`.claude/design/my-api/ux-spec.md\`")
assert_output_contains("User Flow Mapping")
```

## Test 9: Data Requirements Extraction

**Objective:** Skill extracts data requirements for response schemas

**Setup:**
```bash
cat > .claude/design/project/ux-spec.md << 'EOF'
# UX Spec: Dashboard

## User Flows

**Entry Point:** Dashboard showing:
- Recent orders (last 5, with status and total)
- Saved items (product name, image, price)
- Recommendations (6 products)
EOF
```

**Test:**
Run api-design skill and verify response schema design.

**Expected:**
- `GET /users/{id}/orders?limit=5&sort=-created_at`
  - Response includes: order_id, status, total, created_at
- `GET /users/{id}/saved-items`
  - Response includes: product_name, image_url, price
- `GET /recommendations?user_id={id}&limit=6`
  - Response includes: product details

**Assertions:**
```bash
assert_endpoint_has_query_params("GET /users/{id}/orders", "limit", "sort")
assert_response_field("GET /users/{id}/orders", "status")
assert_response_field("GET /users/{id}/saved-items", "product_name")
```

## Test 10: Graceful Degradation (Malformed UX Spec)

**Objective:** Skill handles malformed ux-spec.md gracefully

**Setup:**
```bash
cat > .claude/design/project/ux-spec.md << 'EOF'
# This is not a proper UX spec
Just some random text without proper structure.
No flows, no patterns.
EOF
```

**Test:**
Run api-design skill with malformed ux-spec.md.

**Expected:**
- Skill attempts to read file
- Skill gracefully handles missing sections
- Skill proceeds with standard API design
- Warning logged (optional): "Could not parse UX spec"
- No blocking errors

**Assertions:**
```bash
assert_no_fatal_errors()
assert_optional_warning("Could not parse" OR "Invalid format")
assert_api_design_completes()
```

## Integration Test Checklist

Before releasing UX spec integration:

- [ ] Skill discovers single ux-spec.md file
- [ ] Skill handles multiple ux-spec.md files (prompts user)
- [ ] Skill auto-selects based on context when possible
- [ ] User flows correctly parsed
- [ ] User actions mapped to endpoints
- [ ] Interaction patterns mapped to endpoints
- [ ] Resources identified from UX nouns
- [ ] Edge cases mapped to error responses
- [ ] Data requirements inform response schemas
- [ ] API design output documents UX integration
- [ ] Flow-to-endpoint mapping table generated
- [ ] No ux-spec.md → works normally (backward compatible)
- [ ] Malformed ux-spec.md → graceful degradation
- [ ] No fatal errors if ux-spec.md missing or invalid
- [ ] Clear, actionable output

## Manual Testing Procedure

### Setup

```bash
# Create test workspace
cd /tmp/api-design-test
rm -rf .claude
mkdir -p .claude/design/test-api
```

### Test Case: Complete Integration

1. **Create UX Spec:**

```bash
cat > .claude/design/test-api/ux-spec.md << 'EOF'
# UX Spec: Task Management API

## User Flows

### Primary Flow: Create Task

**Entry Point:** Task list view

**Steps:**
1. User clicks "New Task" button
2. User enters task title and description
3. User sets due date (optional)
4. User assigns to team member (optional)
5. User clicks "Create"
6. System creates task and displays it in list

### Secondary Flow: Update Task Status

**Steps:**
1. User views task details
2. User changes status (todo → in-progress → done)
3. System updates task and notifies assignee

## Interaction Patterns

**Quick Status Change:**
- **What:** Drag task between columns (kanban style)
- **Does:** Updates task status
- **Edge cases:** Cannot move to done if incomplete subtasks

**Bulk Operations:**
- **What:** Select multiple tasks, apply action
- **Does:** Updates all selected tasks
- **Edge cases:** Max 50 tasks at once
EOF
```

2. **Run API Design:**

```bash
# Use api-design skill with the test directory
# Should discover .claude/design/test-api/ux-spec.md
```

3. **Verify Output:**

Expected endpoints:
- `GET /tasks` - List tasks
- `POST /tasks` - Create task (Flow step 5)
- `GET /tasks/{id}` - View task details (Flow step 1)
- `PATCH /tasks/{id}` - Update task status (Flow step 2)
- `POST /tasks/bulk-update` - Bulk operations

Expected documentation:
- "Design Integration" section
- Reference to `.claude/design/test-api/ux-spec.md`
- Flow mapping table

4. **Verify Error Handling:**

Expected error mappings:
- 400 Bad Request: Invalid status transition
- 422 Unprocessable Entity: Cannot complete with incomplete subtasks
- 400 Bad Request: Bulk operation exceeds 50 tasks

### Cleanup

```bash
rm -rf /tmp/api-design-test
```

## Automated Test Template

```bash
#!/bin/bash

# Test: UX Spec Integration
# Run this script to verify api-design skill UX integration

set -e

TEST_DIR="/tmp/api-design-integration-test-$$"
mkdir -p "$TEST_DIR/.claude/design/test-project"
cd "$TEST_DIR"

# Create test UX spec
cat > .claude/design/test-project/ux-spec.md << 'EOF'
# UX Spec: Test API

## User Flows
1. User creates resource
2. User views resource
3. User updates resource
4. User deletes resource
EOF

echo "✓ Created test UX spec"

# Run api-design skill (mock)
# TODO: Replace with actual skill invocation
echo "Running api-design skill..."

# Verify file was read
if [ -f ".claude/design/test-project/ux-spec.md" ]; then
  echo "✓ UX spec file exists"
else
  echo "✗ UX spec file not found"
  exit 1
fi

# Verify expected endpoints would be generated
# TODO: Add actual endpoint verification

echo "✓ All tests passed"

# Cleanup
cd /
rm -rf "$TEST_DIR"
```

## Test Coverage Summary

| Scenario | Coverage |
|----------|----------|
| Discovery | Single file, multiple files, no files |
| Parsing | User flows, interaction patterns, edge cases |
| Extraction | Endpoints, resources, errors, data requirements |
| Selection | Auto-select by context, user prompt |
| Documentation | Integration section, flow mapping, design notes |
| Compatibility | No ux-spec.md, malformed ux-spec.md |
| Edge Cases | Empty file, missing sections, invalid structure |

## Notes

- Tests should not require actual UX spec parsing implementation details
- Focus on behavior and output, not internal logic
- All tests should pass with or without ux-spec.md (backward compatibility)
- Error conditions should never block API design process
