# Browser Verification Flow

Step-by-step process for verifying UI changes in a real browser.

## Prerequisites

- Testability detection passed (all three checks)
- Task has been implemented
- Server URL and port identified

## Verification Steps

### Step 1: Navigate to Server

```
mcp__plugin_playwright_playwright__browser_navigate
url: http://localhost:{port}
```

Or if specific path is known from the task:
```
url: http://localhost:{port}/{relevant_path}
```

### Step 2: Capture Initial State

Take a screenshot for reference:

```
mcp__plugin_playwright_playwright__browser_take_screenshot
filename: task-{task_id}-initial.png
```

And get accessibility snapshot:

```
mcp__plugin_playwright_playwright__browser_snapshot
```

### Step 3: Define Expected Behavior

Based on the task description and acceptance criteria, describe:
- What should be visible
- How it should look
- What interactions should work

Example:
> "Task was to add a 'Delete' button to each task row. Expected: Each row in the task list should have a red 'Delete' button on the right side."

### Step 4: Verify Visual Elements

Using the snapshot, check:
- [ ] Expected elements are present
- [ ] Elements are in correct locations
- [ ] Styling appears correct

### Step 5: Verify Interactions (if applicable)

If the task involves interactive behavior:

1. Perform the interaction:
   ```
   mcp__plugin_playwright_playwright__browser_click
   element: "the element description"
   ref: "element ref from snapshot"
   ```

2. Take post-interaction screenshot:
   ```
   mcp__plugin_playwright_playwright__browser_take_screenshot
   filename: task-{task_id}-after-{action}.png
   ```

3. Verify expected outcome

### Step 6: Check Console Errors

```
mcp__plugin_playwright_playwright__browser_console_messages
level: error
```

Report any JavaScript errors found.

### Step 7: Report Result

#### If Verification Passes

```markdown
## Browser Verification: PASS

**Task**: {task_title}
**Server**: http://localhost:{port}

### What Was Verified
- [List of checks performed]

### Screenshots
- Initial: task-{id}-initial.png
- [Additional screenshots if interactions tested]

### Console Status
No errors detected.
```

#### If Issues Found

```markdown
## Browser Verification: ISSUE FOUND

**Task**: {task_title}
**Server**: http://localhost:{port}

### Issue Description
[Clear description of what's wrong]

### Expected vs Actual
| Expected | Actual |
|----------|--------|
| [what should happen] | [what actually happens] |

### Screenshots
- [Screenshot showing the issue]

### Console Errors (if any)
```
[error messages]
```

### Recommendation
[What needs to be fixed]
```

## Advisory Skip Handling

If user chooses to skip verification:

1. Ask for reason:
   - "Tests cover this adequately"
   - "Backend-only change"
   - "Time constraints"
   - Other (user provides)

2. Log the skip:
   ```markdown
   ## Browser Verification: SKIPPED

   **Reason**: {user_provided_reason}
   **Skipped at**: {timestamp}

   → Proceeding to review with advisory flag
   ```

3. Continue to spec review with warning flag

## Storing Screenshots

Screenshots are saved to: `.ohno/screenshots/`

Naming convention:
- `task-{task_id}-initial.png` - Initial page load
- `task-{task_id}-verify.png` - Primary verification
- `task-{task_id}-after-{action}.png` - Post-interaction

## Task Notes Format

After verification completes, append to task notes:

```markdown
## Browser Verification
- Status: ✅ Passed | ⚠️ Issue Found | ⏭️ Skipped
- Server: http://localhost:{port}
- Screenshot: .ohno/screenshots/task-{id}-verify.png
- Tested: [description of what was verified]
- Reason (if skipped): [user-provided reason]
```
