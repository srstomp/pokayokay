# UX Spec Integration

This reference provides detailed guidance on how api-design consumes UX specification artifacts from the design plugin, specifically ux-spec.md files.

## Overview

The api-design skill can discover and extract endpoint requirements from UX specifications created by the design plugin. This integration:

- Connects user flows and interactions to API endpoint design
- Identifies required endpoints from user actions and data needs
- Maps UI states to data requirements
- Ensures API design supports the intended UX flows
- Documents design artifacts used in the API specification

## UX Spec Discovery

### File Location Pattern

UX specifications are stored at:
```
.claude/design/<project-name>/ux-spec.md
```

Where `<project-name>` is the design project name (e.g., "checkout-flow", "mobile-app").

### Discovery Algorithm

```
1. Search for all files matching: .claude/design/*/ux-spec.md
2. Count results:
   - 0 files: Proceed without UX spec integration
   - 1 file: Use that ux-spec.md automatically
   - 2+ files: Ask user which project to use

3. If ux-spec.md found:
   - Read file contents
   - Extract user flows
   - Extract interaction patterns
   - Parse data requirements
   - Store for endpoint design
```

### Example Discovery

```bash
# Finding ux-spec files
$ find .claude/design -name "ux-spec.md"
.claude/design/checkout-flow/ux-spec.md

# Reading ux-spec file
$ cat .claude/design/checkout-flow/ux-spec.md
```

Result: UX spec loaded for analysis

## Endpoint Requirement Extraction

### User Flow Analysis

Extract endpoint requirements from user flows by identifying:

1. **Actions users take** - Each action likely needs an API endpoint
2. **Data displayed** - Each screen/state needs data retrieval
3. **State transitions** - Changes that persist need write operations
4. **Decision points** - May need conditional data or aggregations

### Parsing Pattern

From UX spec user flows section:

```markdown
### Primary Flow: Checkout

**Steps:**
1. User views cart with items and total
2. User selects shipping method
3. User enters payment information
4. User confirms order
5. System displays confirmation with order number
```

**Extract endpoint requirements:**

```yaml
GET /cart
  - Purpose: View cart items and total (Step 1)
  - Response: cart items, quantities, prices, total

GET /shipping-methods
  - Purpose: List available shipping options (Step 2)
  - Response: shipping methods, costs, delivery times

POST /orders
  - Purpose: Create order with payment (Step 4)
  - Request: cart_id, shipping_method, payment_info
  - Response: order_id, confirmation_number, status

GET /orders/{order_id}
  - Purpose: Display order confirmation (Step 5)
  - Response: order details, items, shipping, total
```

### Interaction Pattern Analysis

From interaction patterns section:

```markdown
**Add to Cart**
- **What:** Click "Add to Cart" button
- **Does:** Adds item to cart, updates cart count in header
- **Edge cases:** Out of stock, quantity limits
```

**Extract endpoint requirements:**

```yaml
POST /cart/items
  - Purpose: Add item to cart
  - Request: product_id, quantity
  - Response: updated cart, item_count
  - Error cases: 400 (invalid quantity), 409 (out of stock)

GET /cart/summary
  - Purpose: Get cart count for header
  - Response: item_count, total_items
```

### Data Requirements Mapping

Extract from UX spec sections that describe what users see:

```markdown
**Entry Point:** Dashboard showing recent orders, saved items, and recommendations

**Data needed:**
- Recent orders (last 5)
- Saved items (all)
- Recommended products (personalized)
```

**Map to endpoints:**

```yaml
GET /users/{user_id}/orders?limit=5&sort=created_desc
  - Purpose: Recent orders for dashboard

GET /users/{user_id}/saved-items
  - Purpose: User's saved items

GET /recommendations?user_id={user_id}&limit=6
  - Purpose: Personalized product recommendations
```

## Resource Identification

### From User Flows

Identify resources by looking for:

1. **Nouns in flows** - "cart", "order", "item", "user", "payment"
2. **Collections** - "items", "orders", "recommendations"
3. **Relationships** - "user's orders", "cart items", "order items"

### Resource Hierarchy

Build resource hierarchy from UX relationships:

```
UX: "User views their order history and clicks an order to see details"

Resources:
/users/{user_id}/orders          # Collection: user's orders
/users/{user_id}/orders/{order_id}  # Individual order
/orders/{order_id}/items         # Nested: items in order
```

### Alternative: Flat Resources

```
UX: Same flow as above

Alternative design (if orders have global IDs):
/orders?user_id={user_id}        # Filter by user
/orders/{order_id}               # Global order access
/orders/{order_id}/items         # Order items
```

Document the choice and rationale in API design.

## Action to Endpoint Mapping

### Standard CRUD Actions

| User Action | HTTP Method | Endpoint Pattern |
|-------------|-------------|------------------|
| View list | GET | /resources |
| View details | GET | /resources/{id} |
| Create new | POST | /resources |
| Update existing | PUT/PATCH | /resources/{id} |
| Delete | DELETE | /resources/{id} |

### Custom Actions

Some user actions don't map to standard CRUD:

```markdown
UX: "User clicks 'Apply Coupon' and enters code"

Endpoint:
POST /cart/apply-coupon
{
  "coupon_code": "SAVE20"
}

Response:
{
  "discount_amount": 15.00,
  "cart_total": 60.00
}
```

or as a sub-resource action:

```
POST /carts/{cart_id}/coupons
{
  "code": "SAVE20"
}
```

Document both approaches and choose based on consistency.

### Bulk Operations

```markdown
UX: "User selects multiple items and clicks 'Move to Wishlist'"

Endpoint:
POST /wishlist/bulk-add
{
  "item_ids": [123, 456, 789]
}

or as individual operations:
POST /wishlist/items (called multiple times)
```

## State and Status Requirements

### From Flow States

```markdown
**Order States:**
1. Cart (not yet ordered)
2. Pending payment
3. Processing
4. Shipped
5. Delivered
6. Cancelled
```

**API implications:**

```yaml
Status field in order resource:
{
  "order_id": "123",
  "status": "processing",  # Enum: pending|processing|shipped|delivered|cancelled
  "status_updated_at": "2024-01-15T10:30:00Z"
}

State transition endpoints:
POST /orders/{order_id}/cancel
POST /orders/{order_id}/ship
PATCH /orders/{order_id} { "status": "delivered" }
```

Choose the approach that best matches your domain.

## Error States from UX

### Extract from Edge Cases

```markdown
**Edge cases:**
- Out of stock when adding to cart
- Invalid coupon code
- Payment declined
- Shipping not available to address
```

**Map to API errors:**

```yaml
POST /cart/items
  - 400 Bad Request: Invalid product_id or quantity
  - 409 Conflict: Product out of stock

POST /cart/apply-coupon
  - 404 Not Found: Invalid coupon code
  - 400 Bad Request: Coupon expired or not applicable

POST /orders
  - 402 Payment Required: Payment declined
  - 400 Bad Request: Shipping not available to address
  - 422 Unprocessable Entity: Cart empty or items unavailable
```

## Pagination and Filtering

### From UX Requirements

```markdown
**Order History:**
- Show 20 orders per page
- Filter by status (all, pending, completed, cancelled)
- Sort by date (newest first by default)
- Search by order number
```

**API design:**

```
GET /orders?page=1&limit=20&status=completed&sort=-created_at&search=ORD-123
```

Standard query parameters:
- `page`, `limit` for pagination
- `status`, other fields for filtering
- `sort` with field name (prefix `-` for descending)
- `search` for text search

## Validation Requirements

### From UX Constraints

```markdown
**Form validation:**
- Email must be valid format
- Password minimum 8 characters
- Credit card must pass Luhn check
- Quantity must be 1-99
```

**API validation:**

```json
POST /users
{
  "email": "invalid-email",
  "password": "short"
}

Response: 400 Bad Request
{
  "error": {
    "status": 400,
    "code": "VALIDATION_ERROR",
    "message": "Invalid request data",
    "details": [
      {
        "field": "email",
        "message": "Must be a valid email address"
      },
      {
        "field": "password",
        "message": "Must be at least 8 characters"
      }
    ]
  }
}
```

## Real-Time Requirements

### From Interaction Patterns

```markdown
**Live Updates:**
- Cart count updates immediately when item added
- Order status updates without page refresh
- Inventory updates when viewing product
```

**API considerations:**

```yaml
# Polling approach
GET /cart/summary (called every 5s)

# WebSocket approach
WS /ws/cart (subscribe to cart updates)

# Server-Sent Events
GET /events/orders/{order_id} (stream status updates)
```

Document the chosen approach in API design.

## Output Documentation

### API Design Section

When UX spec is used, add this section to API documentation:

```markdown
## Design Integration

**UX Specification:** `.claude/design/checkout-flow/ux-spec.md`

This API design is based on the following user flows:
- Primary checkout flow
- Saved cart recovery
- Guest checkout
- Payment retry after decline

### User Flow to Endpoint Mapping

**Checkout Flow:**
1. View cart → `GET /cart`
2. Select shipping → `GET /shipping-methods`, `PATCH /cart/shipping`
3. Enter payment → `POST /orders` (creates order with payment)
4. View confirmation → `GET /orders/{order_id}`

**Edge Case Flows:**
- Apply coupon → `POST /cart/coupons`
- Remove item → `DELETE /cart/items/{item_id}`
- Update quantity → `PATCH /cart/items/{item_id}`
```

### Endpoint Requirements Table

```markdown
| UX Action | Endpoint | Method | Request | Response |
|-----------|----------|--------|---------|----------|
| View cart | /cart | GET | - | cart object |
| Add to cart | /cart/items | POST | product_id, quantity | updated cart |
| Remove item | /cart/items/{id} | DELETE | - | 204 No Content |
| Apply coupon | /cart/coupons | POST | coupon_code | discount, total |
| Get shipping | /shipping-methods | GET | - | methods array |
| Create order | /orders | POST | cart_id, shipping, payment | order object |
| View order | /orders/{id} | GET | - | order object |
```

## Backward Compatibility

### No UX Spec File

If no `.claude/design/*/ux-spec.md` exists:

```
1. Proceed with normal API design process
2. No UX flow integration performed
3. No errors or warnings about missing UX spec
4. Optional note in output: "No UX specification found"
```

**Example output note (optional):**

```markdown
UX Integration: None found

Note: A UX specification can help inform API endpoint design. Create one using the design plugin:
  /design:ux-spec

Then re-run api-design to integrate user flows with endpoint requirements.
```

### Graceful Degradation

```
try:
  ux_spec = discover_ux_spec()
  if ux_spec:
    requirements = extract_endpoint_requirements(ux_spec)
    integrate_requirements(requirements)
except FileNotFoundError:
  # No UX spec file, continue normally
  pass
except Exception as e:
  # Log error but don't block API design
  log.warning(f"Could not load UX spec: {e}")
  pass
```

**Never block or error** if ux-spec.md is missing or malformed.

## Multiple Design Projects

### Detection

```bash
$ find .claude/design -name "ux-spec.md"
.claude/design/checkout-flow/ux-spec.md
.claude/design/mobile-app/ux-spec.md
.claude/design/admin-panel/ux-spec.md
```

### User Prompt

```
Multiple UX specifications found:
1. checkout-flow (5 flows)
2. mobile-app (8 flows)
3. admin-panel (6 flows)

Which project's UX spec should inform the API design?
[Enter number or project name]: _
```

### Selection Logic

If the API design request mentions a project name, automatically select matching UX spec.

```
User: "Design API for checkout flow"
→ Automatically use .claude/design/checkout-flow/ux-spec.md if it exists
```

## Integration Workflow

### Full Process Flow

```
1. User runs: api-design [options]

2. Skill initialization:
   ├─ Search for .claude/design/*/ux-spec.md
   ├─ If found: Parse user flows and interaction patterns
   └─ If not found: Continue without UX integration

3. Resource Identification:
   ├─ Extract resources from UX flows (nouns, collections)
   ├─ Identify resource relationships
   └─ Build resource hierarchy

4. Endpoint Design:
   ├─ Map user actions to HTTP methods
   ├─ Design URL structure from resource hierarchy
   ├─ Define request/response schemas from data needs
   └─ Identify custom actions beyond CRUD

5. Error Handling:
   ├─ Extract edge cases from UX spec
   ├─ Map to appropriate HTTP status codes
   └─ Design error response format

6. Documentation:
   ├─ Document UX spec source
   ├─ Create flow-to-endpoint mapping
   └─ Note design decisions and rationale

7. Output Generation:
   ├─ API specification document
   ├─ OpenAPI schema (if requested)
   └─ Implementation notes
```

## Quality Checklist

Before completing UX spec integration:

- [ ] UX spec discovery attempted
- [ ] User flows correctly parsed
- [ ] Actions mapped to endpoints
- [ ] Data requirements identified
- [ ] Resources and hierarchy defined
- [ ] Error states from edge cases mapped to status codes
- [ ] Custom actions (beyond CRUD) identified
- [ ] Multiple projects handled (user prompted if needed)
- [ ] API design document references UX spec source
- [ ] Flow-to-endpoint mapping documented
- [ ] Backward compatible (works without ux-spec.md)
- [ ] No errors or blocking if ux-spec.md missing
- [ ] Design decisions justified with UX rationale

## Example End-to-End

### Input: UX Spec

**.claude/design/checkout/ux-spec.md:**

```markdown
## User Flows

### Primary Flow: Checkout

**Entry Point:** Cart page with items

**Steps:**
1. User reviews cart items (products, quantities, subtotal)
2. User clicks "Proceed to Checkout"
3. User selects shipping method (standard, express, overnight)
4. User enters payment information (card or saved payment)
5. User reviews order summary
6. User confirms order
7. System displays confirmation with order number and estimated delivery

**Exit Points:**
- User removes all items → returns to shopping
- Payment fails → retry payment or change method
- Shipping unavailable → suggest alternatives

### Alternative Flow: Apply Coupon

**Trigger:** User clicks "Have a coupon?" in cart

**Steps:**
1. User enters coupon code
2. System validates code
3. If valid: updates cart total with discount
4. If invalid: shows error message

## Interaction Patterns

**Update Quantity:**
- **What:** Click +/- buttons or enter quantity
- **Does:** Updates item quantity, recalculates total
- **Edge cases:** Min quantity 1, max 99, out of stock
```

### Processing

```
1. Discover ux-spec.md → Found: .claude/design/checkout/ux-spec.md
2. Extract flows → Primary checkout flow, coupon flow
3. Identify resources → cart, cart_items, shipping_methods, orders, coupons
4. Map actions to endpoints:
   - View cart → GET /cart
   - Update quantity → PATCH /cart/items/{id}
   - Remove item → DELETE /cart/items/{id}
   - Get shipping methods → GET /shipping-methods
   - Apply coupon → POST /cart/coupons
   - Create order → POST /orders
   - View order → GET /orders/{id}
```

### Output: API Design Document

```markdown
# Checkout API Specification

## Design Integration

**UX Specification:** `.claude/design/checkout/ux-spec.md`

This API supports the checkout user flow defined in the UX specification.

### User Flow Mapping

| Flow Step | API Endpoint | Notes |
|-----------|--------------|-------|
| Review cart | GET /cart | Returns items, quantities, subtotal |
| Proceed to checkout | - | Client-side navigation |
| Select shipping | GET /shipping-methods | Returns available options with costs |
| Select shipping | PATCH /cart/shipping | Updates cart with selected method |
| Enter payment | - | Payment handled in order creation |
| Confirm order | POST /orders | Creates order, processes payment |
| View confirmation | GET /orders/{id} | Returns order details |

### Edge Case Endpoints

| Edge Case | Endpoint | Error Response |
|-----------|----------|----------------|
| Remove all items | DELETE /cart/items/{id} | - |
| Payment fails | POST /orders | 402 Payment Required |
| Shipping unavailable | GET /shipping-methods | Empty array or alternatives |
| Invalid coupon | POST /cart/coupons | 404 Not Found |

## Resources

### Cart

```yaml
GET /cart
  Description: Get current user's cart
  Response: 200 OK
    {
      "id": "cart_123",
      "items": [...],
      "subtotal": 99.99,
      "discount": 10.00,
      "shipping_cost": 5.99,
      "total": 95.98
    }

PATCH /cart/shipping
  Description: Update shipping method
  Request:
    {
      "shipping_method_id": "express"
    }
  Response: 200 OK (updated cart)

### Cart Items

POST /cart/items
  Description: Add item to cart
  Request:
    {
      "product_id": "prod_123",
      "quantity": 2
    }
  Response: 201 Created (updated cart)
  Errors:
    - 400: Invalid quantity (min 1, max 99)
    - 409: Product out of stock

PATCH /cart/items/{item_id}
  Description: Update item quantity
  Request:
    {
      "quantity": 3
    }
  Response: 200 OK (updated cart)
  Errors:
    - 400: Invalid quantity
    - 404: Item not in cart

DELETE /cart/items/{item_id}
  Description: Remove item from cart
  Response: 204 No Content

### Shipping Methods

GET /shipping-methods
  Description: Get available shipping methods
  Response: 200 OK
    [
      {
        "id": "standard",
        "name": "Standard Shipping",
        "cost": 5.99,
        "delivery_days": "5-7"
      },
      {
        "id": "express",
        "name": "Express Shipping",
        "cost": 12.99,
        "delivery_days": "2-3"
      }
    ]

### Coupons

POST /cart/coupons
  Description: Apply coupon to cart
  Request:
    {
      "code": "SAVE20"
    }
  Response: 200 OK (updated cart with discount)
  Errors:
    - 404: Invalid coupon code
    - 400: Coupon expired or not applicable

DELETE /cart/coupons/{code}
  Description: Remove applied coupon
  Response: 204 No Content

### Orders

POST /orders
  Description: Create order from cart
  Request:
    {
      "shipping_address": {...},
      "payment_method": {...}
    }
  Response: 201 Created
    {
      "order_id": "ord_123",
      "confirmation_number": "ABC123",
      "status": "processing",
      "estimated_delivery": "2024-01-25"
    }
  Errors:
    - 400: Invalid shipping address
    - 402: Payment declined
    - 422: Cart empty or items unavailable

GET /orders/{order_id}
  Description: Get order details
  Response: 200 OK
    {
      "order_id": "ord_123",
      "items": [...],
      "status": "shipped",
      "tracking_number": "1Z999AA10123456784"
    }
```

## Design Decisions

**Resource Hierarchy:**
- Chose nested `/cart/items` over flat `/cart-items` for clarity
- Orders are top-level (not nested under users) since they have global IDs

**Shipping Selection:**
- PATCH `/cart/shipping` instead of storing in order creation
- Allows cart total to update before payment

**Coupon Application:**
- POST `/cart/coupons` creates a coupon application
- DELETE removes it (rather than PATCH cart with coupon field)
- Explicit action makes UX clearer

**Error Handling:**
- 402 Payment Required for payment failures (distinct from 400/422)
- 409 Conflict for out-of-stock (resource state conflict)
- 404 for invalid coupon codes (resource not found)
```

## Anti-Patterns

### DON'T: Ignore UX edge cases

```
❌ BAD:
Only design happy path endpoints

✓ GOOD:
Map edge cases and errors from UX spec to error responses and alternative endpoints
```

### DON'T: One-to-one action mapping without thinking

```
❌ BAD:
Every button click = new endpoint
POST /proceedToCheckout
POST /reviewOrder
POST /confirmOrder

✓ GOOD:
Group actions into resource-oriented endpoints
POST /orders (handles confirm and payment)
Client handles navigation for review
```

### DON'T: Ignore UX data requirements

```
❌ BAD:
GET /orders → returns minimal data
UX needs shipping info, items, tracking → requires multiple calls

✓ GOOD:
GET /orders/{id} → returns complete data needed for confirmation screen
Optionally support sparse fieldsets: GET /orders/{id}?fields=status,tracking
```

### DON'T: Copy UX structure literally

```
❌ BAD:
UX has 5 separate screens → 5 separate endpoints for each screen state

✓ GOOD:
Design resources based on domain entities
One resource may support multiple UX views with query parameters or fields
```

## Testing Checklist

Verify these scenarios:

- [ ] Single ux-spec.md file discovered and used
- [ ] Multiple projects prompt user for selection
- [ ] No ux-spec.md → proceeds without integration
- [ ] User flows correctly parsed
- [ ] Actions mapped to appropriate endpoints
- [ ] Data requirements extracted
- [ ] Resources identified and hierarchized
- [ ] Edge cases mapped to error responses
- [ ] Custom actions (beyond CRUD) identified
- [ ] API design document references UX spec
- [ ] Flow-to-endpoint mapping documented
- [ ] No errors if ux-spec.md missing
- [ ] No errors if ux-spec.md malformed (graceful degradation)
- [ ] Design decisions justified with UX rationale

## References

- [Design Plugin: UX Spec Template](../../../../toyoda/plugins/design/templates/ux-spec.md)
- [API Design: Endpoints Reference](endpoints.md)
- [API Design: Request/Response Formats](requests-responses.md)
- [API Design: Status Codes](status-codes.md)
