# TDD Patterns: Error Handling

## Test-First Workflow for Error Paths

1. Write test that triggers the error condition
2. Assert the specific error type, message, and recovery behavior
3. Run test — confirm it fails (error not thrown or wrong type)
4. Implement the error handling
5. Run test — confirm error is correctly thrown and caught

## What to Test

| Test Case | Pattern | Example |
|-----------|---------|---------|
| Error thrown | Direct throw | Invalid input throws ValidationError |
| Error type | instanceof | Caught error is AppError subclass |
| Error message | Content check | Message includes what failed and why |
| Error propagation | Middleware chain | Error reaches error handler with context |
| Recovery | Retry/fallback | Service retries 3x then falls back |
| User message | Response shape | API returns structured error, not stack trace |
| Error boundary | Component crash | React boundary catches and shows fallback |

## Error Path Test Template

```typescript
describe('UserService.create', () => {
  it('throws ValidationError for invalid email', async () => {
    await expect(
      userService.create({ name: 'Test', email: 'not-an-email' })
    ).rejects.toThrow(ValidationError);
  });

  it('includes field name in error', async () => {
    try {
      await userService.create({ name: 'Test', email: 'bad' });
    } catch (e) {
      expect(e.field).toBe('email');
      expect(e.message).toContain('valid email');
    }
  });
});
```

## Retry Logic Test Pattern

```typescript
it('retries 3 times then throws', async () => {
  const mockFetch = jest.fn().mockRejectedValue(new Error('timeout'));

  await expect(fetchWithRetry(mockFetch, { retries: 3 }))
    .rejects.toThrow('timeout');

  expect(mockFetch).toHaveBeenCalledTimes(3);
});

it('succeeds on second attempt', async () => {
  const mockFetch = jest.fn()
    .mockRejectedValueOnce(new Error('timeout'))
    .mockResolvedValueOnce({ data: 'ok' });

  const result = await fetchWithRetry(mockFetch, { retries: 3 });
  expect(result.data).toBe('ok');
  expect(mockFetch).toHaveBeenCalledTimes(2);
});
```

## Error Boundary Test Pattern

```tsx
it('shows fallback UI on error', () => {
  const ThrowingComponent = () => { throw new Error('crash'); };

  render(
    <ErrorBoundary fallback={<div>Something went wrong</div>}>
      <ThrowingComponent />
    </ErrorBoundary>
  );

  expect(screen.getByText('Something went wrong')).toBeInTheDocument();
});
```

## Test the Error, Not Just the Happy Path

For every function that can fail, write at least one test that:
1. Forces the failure condition
2. Verifies the error type and message
3. Confirms no side effects occurred (no partial writes, no leaked state)
