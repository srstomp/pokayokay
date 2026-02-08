# React Testing Library

Component and integration testing patterns for React applications.

## Core Philosophy

RTL enforces testing from the user's perspective:

| Avoid | Prefer | Why |
|-------|--------|-----|
| `container.querySelector` | `screen.getByRole` | Users see roles, not classes |
| `wrapper.instance()` | `screen.getByText` | Users see text, not instances |
| `component.state()` | `screen.getByDisplayValue` | Users see values, not state |

## Query Priority

Use queries in this order (most to least preferred):

```typescript
// 1. Accessible by everyone
screen.getByRole('button', { name: /submit/i });
screen.getByLabelText(/username/i);
screen.getByPlaceholderText(/search/i);
screen.getByText(/welcome/i);
screen.getByDisplayValue(/john/i);

// 2. Semantic queries
screen.getByAltText(/profile/i);
screen.getByTitle(/close/i);

// 3. Test IDs (last resort)
screen.getByTestId('custom-element');
```

## Query Types

| Query Type | No Match | 1 Match | >1 Match | Await? |
|------------|----------|---------|----------|--------|
| `getBy` | Throw | Return | Throw | No |
| `queryBy` | null | Return | Throw | No |
| `findBy` | Throw | Return | Throw | Yes |
| `getAllBy` | Throw | Array | Array | No |
| `queryAllBy` | [] | Array | Array | No |
| `findAllBy` | Throw | Array | Array | Yes |

```typescript
// Checking element exists
expect(screen.getByRole('button')).toBeInTheDocument();

// Checking element doesn't exist
expect(screen.queryByRole('dialog')).not.toBeInTheDocument();

// Waiting for element to appear
await screen.findByText('Success');

// Getting all matching elements
const items = screen.getAllByRole('listitem');
expect(items).toHaveLength(3);
```

## User Events

```typescript
import userEvent from '@testing-library/user-event';

describe('Form', () => {
  it('submits with valid data', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();
    render(<LoginForm onSubmit={onSubmit} />);

    // Type in inputs
    await user.type(screen.getByLabelText(/email/i), 'test@example.com');
    await user.type(screen.getByLabelText(/password/i), 'password123');

    // Click submit
    await user.click(screen.getByRole('button', { name: /sign in/i }));

    expect(onSubmit).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'password123',
    });
  });

  it('shows validation error on blur', async () => {
    const user = userEvent.setup();
    render(<LoginForm />);

    // Focus and blur empty field
    await user.click(screen.getByLabelText(/email/i));
    await user.tab();

    expect(screen.getByText(/email is required/i)).toBeInTheDocument();
  });
});
```

## Common User Actions

```typescript
const user = userEvent.setup();

// Typing
await user.type(input, 'hello');
await user.clear(input);
await user.type(input, 'new value');

// Clicking
await user.click(button);
await user.dblClick(element);
await user.tripleClick(element);

// Keyboard
await user.keyboard('{Enter}');
await user.keyboard('{Shift>}A{/Shift}'); // Shift+A
await user.tab();

// Selection
await user.selectOptions(select, ['option1', 'option2']);
await user.deselectOptions(select, 'option1');

// File upload
const file = new File(['content'], 'test.png', { type: 'image/png' });
await user.upload(input, file);

// Hover
await user.hover(element);
await user.unhover(element);

// Clipboard
await user.copy();
await user.paste('text');
```

## Testing Async Behavior

```typescript
describe('AsyncComponent', () => {
  it('shows loading then data', async () => {
    render(<UserProfile userId="1" />);

    // Initially loading
    expect(screen.getByText(/loading/i)).toBeInTheDocument();

    // Wait for data
    await waitFor(() => {
      expect(screen.queryByText(/loading/i)).not.toBeInTheDocument();
    });

    // Data displayed
    expect(screen.getByText('John Doe')).toBeInTheDocument();
  });

  it('handles error state', async () => {
    server.use(
      http.get('/api/users/:id', () => {
        return HttpResponse.json({ error: 'Not found' }, { status: 404 });
      })
    );

    render(<UserProfile userId="999" />);

    await waitFor(() => {
      expect(screen.getByRole('alert')).toHaveTextContent(/not found/i);
    });
  });
});
```

## Testing Custom Hooks

```typescript
import { renderHook, act } from '@testing-library/react';

describe('useCounter', () => {
  it('increments value', () => {
    const { result } = renderHook(() => useCounter());

    expect(result.current.count).toBe(0);

    act(() => {
      result.current.increment();
    });

    expect(result.current.count).toBe(1);
  });

  it('accepts initial value', () => {
    const { result } = renderHook(() => useCounter(10));
    expect(result.current.count).toBe(10);
  });

  it('updates on rerender with new props', () => {
    const { result, rerender } = renderHook(
      ({ step }) => useCounter(0, step),
      { initialProps: { step: 1 } }
    );

    act(() => result.current.increment());
    expect(result.current.count).toBe(1);

    rerender({ step: 5 });
    act(() => result.current.increment());
    expect(result.current.count).toBe(6);
  });
});

// Hooks with context
describe('useAuth', () => {
  it('returns user from context', () => {
    const wrapper = ({ children }) => (
      <AuthProvider initialUser={mockUser}>{children}</AuthProvider>
    );

    const { result } = renderHook(() => useAuth(), { wrapper });

    expect(result.current.user).toEqual(mockUser);
  });
});
```

## Component States Pattern

```typescript
describe('Button', () => {
  it('renders default state', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByRole('button')).toBeEnabled();
  });

  it('renders loading state', () => {
    render(<Button loading>Click me</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
    expect(screen.getByRole('progressbar')).toBeInTheDocument();
  });

  it('renders disabled state', () => {
    render(<Button disabled>Click me</Button>);
    expect(screen.getByRole('button')).toBeDisabled();
  });

  it('renders error state', () => {
    render(<Button error="Something went wrong">Click me</Button>);
    expect(screen.getByRole('alert')).toHaveTextContent(/something went wrong/i);
  });
});
```

## Form Testing Patterns

```typescript
describe('RegistrationForm', () => {
  it('validates required fields on submit', async () => {
    const user = userEvent.setup();
    render(<RegistrationForm />);

    await user.click(screen.getByRole('button', { name: /register/i }));

    expect(screen.getByText(/name is required/i)).toBeInTheDocument();
    expect(screen.getByText(/email is required/i)).toBeInTheDocument();
  });

  it('validates email format', async () => {
    const user = userEvent.setup();
    render(<RegistrationForm />);

    await user.type(screen.getByLabelText(/email/i), 'invalid-email');
    await user.tab();

    expect(screen.getByText(/invalid email/i)).toBeInTheDocument();
  });

  it('submits valid form', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn();
    render(<RegistrationForm onSubmit={onSubmit} />);

    await user.type(screen.getByLabelText(/name/i), 'John Doe');
    await user.type(screen.getByLabelText(/email/i), 'john@example.com');
    await user.type(screen.getByLabelText(/password/i), 'secure123');
    await user.click(screen.getByRole('button', { name: /register/i }));

    await waitFor(() => {
      expect(onSubmit).toHaveBeenCalled();
    });
  });

  it('disables submit while processing', async () => {
    const user = userEvent.setup();
    const onSubmit = vi.fn(() => new Promise(r => setTimeout(r, 1000)));
    render(<RegistrationForm onSubmit={onSubmit} />);

    // Fill form...
    await user.click(screen.getByRole('button', { name: /register/i }));

    expect(screen.getByRole('button', { name: /register/i })).toBeDisabled();
  });
});
```
