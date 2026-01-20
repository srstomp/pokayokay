# React Error Handling

Error boundaries, Suspense, and React-specific error patterns.

## Error Boundaries

### Full-Featured Error Boundary

```tsx
import { Component, ErrorInfo, ReactNode } from 'react';
import * as Sentry from '@sentry/react';

interface Props {
  children: ReactNode;
  fallback?: ReactNode | ((error: Error, reset: () => void) => ReactNode);
  onError?: (error: Error, errorInfo: ErrorInfo) => void;
  resetKeys?: unknown[]; // Reset when these change
}

interface State {
  hasError: boolean;
  error: Error | null;
}

class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false, error: null };

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    // Log to error tracking
    Sentry.withScope((scope) => {
      scope.setExtras({ componentStack: errorInfo.componentStack });
      Sentry.captureException(error);
    });

    // Call custom handler
    this.props.onError?.(error, errorInfo);
  }

  componentDidUpdate(prevProps: Props) {
    // Reset on key change
    if (this.state.hasError && this.props.resetKeys) {
      const keysChanged = this.props.resetKeys.some(
        (key, i) => key !== prevProps.resetKeys?.[i]
      );
      if (keysChanged) {
        this.reset();
      }
    }
  }

  reset = () => {
    this.setState({ hasError: false, error: null });
  };

  render() {
    if (this.state.hasError) {
      const { fallback } = this.props;
      const { error } = this.state;

      if (typeof fallback === 'function') {
        return fallback(error!, this.reset);
      }

      return fallback ?? <DefaultErrorFallback error={error!} reset={this.reset} />;
    }

    return this.props.children;
  }
}
```

### Default Error Fallback

```tsx
interface FallbackProps {
  error: Error;
  reset: () => void;
}

function DefaultErrorFallback({ error, reset }: FallbackProps) {
  return (
    <div role="alert" className="error-fallback">
      <h2>Something went wrong</h2>
      <pre className="error-message">{error.message}</pre>
      <button onClick={reset}>Try again</button>
    </div>
  );
}

// Styled version
function StyledErrorFallback({ error, reset }: FallbackProps) {
  return (
    <div className="flex flex-col items-center justify-center p-8 bg-red-50 rounded-lg">
      <svg className="w-16 h-16 text-red-500 mb-4" /* error icon */ />
      <h2 className="text-xl font-semibold text-red-700 mb-2">
        Oops! Something went wrong
      </h2>
      <p className="text-red-600 mb-4 text-center max-w-md">
        We've been notified and are working on it. Please try again.
      </p>
      <button
        onClick={reset}
        className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700"
      >
        Try again
      </button>
    </div>
  );
}
```

### Specialized Error Boundaries

```tsx
// Route-level: Full page error
function RouteErrorBoundary({ children }: { children: ReactNode }) {
  return (
    <ErrorBoundary
      fallback={(error, reset) => (
        <div className="min-h-screen flex items-center justify-center">
          <div className="text-center">
            <h1 className="text-4xl font-bold mb-4">Page Error</h1>
            <p className="mb-6">This page encountered an error.</p>
            <div className="space-x-4">
              <button onClick={reset}>Reload page</button>
              <Link to="/">Go home</Link>
            </div>
          </div>
        </div>
      )}
    >
      {children}
    </ErrorBoundary>
  );
}

// Widget-level: Inline error
function WidgetErrorBoundary({ 
  children, 
  name 
}: { 
  children: ReactNode; 
  name: string;
}) {
  return (
    <ErrorBoundary
      fallback={(error, reset) => (
        <div className="p-4 border border-red-200 bg-red-50 rounded">
          <p className="text-sm text-red-600">
            {name} couldn't load.{' '}
            <button onClick={reset} className="underline">Retry</button>
          </p>
        </div>
      )}
    >
      {children}
    </ErrorBoundary>
  );
}

// Data-fetching: Reset on query change
function QueryErrorBoundary({ 
  children,
  queryKey 
}: { 
  children: ReactNode;
  queryKey: unknown[];
}) {
  return (
    <ErrorBoundary resetKeys={queryKey}>
      {children}
    </ErrorBoundary>
  );
}
```

## Boundary Placement Strategy

```
App
├── AppErrorBoundary (catches catastrophic failures)
│   └── Router
│       ├── RouteErrorBoundary (per-route)
│       │   └── DashboardLayout
│       │       ├── WidgetErrorBoundary (SalesChart)
│       │       ├── WidgetErrorBoundary (RecentOrders)
│       │       └── WidgetErrorBoundary (Analytics)
│       └── RouteErrorBoundary (per-route)
│           └── SettingsPage
```

### Placement Rules

| Level | Catches | Fallback | User Impact |
|-------|---------|----------|-------------|
| App | Render crashes | "App error, refresh" | Full app down |
| Route | Page crashes | Error page, nav works | One page down |
| Layout | Section crashes | Section placeholder | Part of page down |
| Widget | Component crash | Inline error | Single widget down |

## Error Boundaries with Suspense

### Combined Pattern

```tsx
import { Suspense } from 'react';

function AsyncComponent({ id }: { id: string }) {
  return (
    <ErrorBoundary
      fallback={(error, reset) => (
        <ErrorMessage error={error} onRetry={reset} />
      )}
      resetKeys={[id]}
    >
      <Suspense fallback={<LoadingSpinner />}>
        <DataComponent id={id} />
      </Suspense>
    </ErrorBoundary>
  );
}

// Order matters: ErrorBoundary outside Suspense
// Errors in suspended components bubble to ErrorBoundary
```

### With React Query / SWR

```tsx
// React Query integration
function useUserQuery(userId: string) {
  return useQuery({
    queryKey: ['user', userId],
    queryFn: () => fetchUser(userId),
    useErrorBoundary: true, // Throw to boundary
    retry: 2,
  });
}

function UserProfile({ userId }: { userId: string }) {
  return (
    <ErrorBoundary
      resetKeys={[userId]}
      fallback={(error, reset) => (
        <ProfileError error={error} onRetry={reset} />
      )}
    >
      <Suspense fallback={<ProfileSkeleton />}>
        <UserProfileContent userId={userId} />
      </Suspense>
    </ErrorBoundary>
  );
}

function UserProfileContent({ userId }: { userId: string }) {
  const { data: user } = useUserQuery(userId);
  return <div>{user.name}</div>;
}
```

## Async Error Handling

### In Event Handlers

```tsx
function SubmitButton() {
  const [error, setError] = useState<Error | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async () => {
    setError(null);
    setIsLoading(true);
    
    try {
      await submitForm();
    } catch (e) {
      setError(e as Error);
      // Optionally report to Sentry
      Sentry.captureException(e);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div>
      <button onClick={handleSubmit} disabled={isLoading}>
        {isLoading ? 'Submitting...' : 'Submit'}
      </button>
      {error && <ErrorMessage error={error} />}
    </div>
  );
}
```

### In useEffect

```tsx
function DataFetcher({ id }: { id: string }) {
  const [data, setData] = useState(null);
  const [error, setError] = useState<Error | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;

    async function fetchData() {
      setLoading(true);
      setError(null);

      try {
        const result = await fetch(`/api/data/${id}`);
        if (!result.ok) throw new Error('Fetch failed');
        if (!cancelled) {
          setData(await result.json());
        }
      } catch (e) {
        if (!cancelled) {
          setError(e as Error);
        }
      } finally {
        if (!cancelled) {
          setLoading(false);
        }
      }
    }

    fetchData();
    return () => { cancelled = true; };
  }, [id]);

  if (loading) return <Loading />;
  if (error) return <ErrorMessage error={error} />;
  return <DataDisplay data={data} />;
}
```

## Form Error Handling

### With React Hook Form

```tsx
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

const schema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(8, 'Password must be 8+ characters'),
});

function LoginForm() {
  const [serverError, setServerError] = useState<string | null>(null);
  
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    setError,
  } = useForm({
    resolver: zodResolver(schema),
  });

  const onSubmit = async (data: FormData) => {
    setServerError(null);
    
    try {
      await login(data);
    } catch (e) {
      if (e instanceof ValidationError) {
        // Field-specific error from server
        setError(e.field as any, { message: e.message });
      } else {
        // General error
        setServerError('Login failed. Please try again.');
      }
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)}>
      {serverError && (
        <div className="alert alert-error">{serverError}</div>
      )}
      
      <div>
        <input {...register('email')} placeholder="Email" />
        {errors.email && (
          <span className="error">{errors.email.message}</span>
        )}
      </div>
      
      <div>
        <input {...register('password')} type="password" />
        {errors.password && (
          <span className="error">{errors.password.message}</span>
        )}
      </div>
      
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Logging in...' : 'Login'}
      </button>
    </form>
  );
}
```

## Toast Notifications

### Error Toast Pattern

```tsx
import { toast } from 'sonner'; // or react-hot-toast

// Simple error toast
function showError(message: string) {
  toast.error(message);
}

// Error toast with action
function showErrorWithRetry(message: string, onRetry: () => void) {
  toast.error(message, {
    action: {
      label: 'Retry',
      onClick: onRetry,
    },
  });
}

// Usage in async handler
async function handleDelete() {
  try {
    await deleteItem(id);
    toast.success('Item deleted');
  } catch (e) {
    toast.error('Failed to delete item', {
      action: {
        label: 'Retry',
        onClick: handleDelete,
      },
    });
  }
}
```

### Global Error Handler

```tsx
// API client with toast integration
const api = {
  async request<T>(url: string, options?: RequestInit): Promise<T> {
    try {
      const res = await fetch(url, options);
      if (!res.ok) {
        const error = await res.json();
        throw new APIError(error.message, error.code);
      }
      return res.json();
    } catch (e) {
      if (e instanceof APIError) {
        toast.error(e.userMessage);
      } else {
        toast.error('Network error. Please try again.');
      }
      throw e;
    }
  },
};
```

## Error Context

### Centralized Error State

```tsx
interface ErrorState {
  error: Error | null;
  setError: (error: Error | null) => void;
  clearError: () => void;
}

const ErrorContext = createContext<ErrorState | null>(null);

function ErrorProvider({ children }: { children: ReactNode }) {
  const [error, setErrorState] = useState<Error | null>(null);

  const setError = useCallback((error: Error | null) => {
    setErrorState(error);
    if (error) {
      Sentry.captureException(error);
    }
  }, []);

  const clearError = useCallback(() => {
    setErrorState(null);
  }, []);

  return (
    <ErrorContext.Provider value={{ error, setError, clearError }}>
      {children}
      {error && <GlobalErrorModal error={error} onDismiss={clearError} />}
    </ErrorContext.Provider>
  );
}

function useError() {
  const context = useContext(ErrorContext);
  if (!context) throw new Error('useError must be within ErrorProvider');
  return context;
}
```

## Testing Error Boundaries

```tsx
import { render, screen } from '@testing-library/react';

// Component that throws
function ThrowingComponent({ shouldThrow }: { shouldThrow: boolean }) {
  if (shouldThrow) {
    throw new Error('Test error');
  }
  return <div>Content</div>;
}

describe('ErrorBoundary', () => {
  // Suppress error boundary console errors in tests
  beforeEach(() => {
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('renders children when no error', () => {
    render(
      <ErrorBoundary fallback={<div>Error</div>}>
        <ThrowingComponent shouldThrow={false} />
      </ErrorBoundary>
    );
    
    expect(screen.getByText('Content')).toBeInTheDocument();
  });

  it('renders fallback when error occurs', () => {
    render(
      <ErrorBoundary fallback={<div>Error fallback</div>}>
        <ThrowingComponent shouldThrow={true} />
      </ErrorBoundary>
    );
    
    expect(screen.getByText('Error fallback')).toBeInTheDocument();
  });

  it('calls onError callback', () => {
    const onError = jest.fn();
    
    render(
      <ErrorBoundary fallback={<div>Error</div>} onError={onError}>
        <ThrowingComponent shouldThrow={true} />
      </ErrorBoundary>
    );
    
    expect(onError).toHaveBeenCalled();
  });

  it('resets when reset is called', async () => {
    let reset: () => void;
    
    render(
      <ErrorBoundary
        fallback={(error, resetFn) => {
          reset = resetFn;
          return <button onClick={resetFn}>Reset</button>;
        }}
      >
        <ThrowingComponent shouldThrow={true} />
      </ErrorBoundary>
    );
    
    expect(screen.getByText('Reset')).toBeInTheDocument();
    
    // Change props so it won't throw on re-render
    // Then call reset
  });
});
```

## Anti-Patterns

### ❌ Error Boundary for Async Errors

```tsx
// Error boundaries DON'T catch:
// - Event handler errors
// - Async code (setTimeout, promises)
// - Server-side rendering
// - Errors in the boundary itself

// ❌ Won't be caught by boundary
function BadComponent() {
  useEffect(() => {
    setTimeout(() => {
      throw new Error('Async error'); // Not caught!
    }, 1000);
  }, []);
}

// ✅ Handle async errors with state
function GoodComponent() {
  const [error, setError] = useState<Error | null>(null);
  
  useEffect(() => {
    fetchData().catch(setError);
  }, []);
  
  if (error) throw error; // Now caught by boundary
}
```

### ❌ Single Boundary for Everything

```tsx
// ❌ One crash takes down entire app
function App() {
  return (
    <ErrorBoundary>
      <Header />
      <Sidebar />
      <MainContent />
      <Footer />
    </ErrorBoundary>
  );
}

// ✅ Isolated failures
function App() {
  return (
    <ErrorBoundary fallback={<AppError />}>
      <Header />
      <div className="layout">
        <ErrorBoundary fallback={<SidebarError />}>
          <Sidebar />
        </ErrorBoundary>
        <ErrorBoundary fallback={<ContentError />}>
          <MainContent />
        </ErrorBoundary>
      </div>
      <Footer />
    </ErrorBoundary>
  );
}
```
