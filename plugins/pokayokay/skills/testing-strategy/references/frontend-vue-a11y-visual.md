# Vue Testing, Accessibility, and Visual Testing

Vue Test Utils, accessibility testing, visual state testing, and anti-patterns.

## Vue Test Utils

### Basic Component Testing

```typescript
import { mount, shallowMount } from '@vue/test-utils';
import MyComponent from './MyComponent.vue';

describe('MyComponent', () => {
  it('renders message', () => {
    const wrapper = mount(MyComponent, {
      props: { message: 'Hello' },
    });

    expect(wrapper.text()).toContain('Hello');
  });

  it('emits event on click', async () => {
    const wrapper = mount(MyComponent);

    await wrapper.find('button').trigger('click');

    expect(wrapper.emitted('submit')).toBeTruthy();
    expect(wrapper.emitted('submit')[0]).toEqual([{ data: 'value' }]);
  });
});
```

### Testing with Pinia

```typescript
import { setActivePinia, createPinia } from 'pinia';
import { useUserStore } from './stores/user';

describe('UserStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it('fetches user', async () => {
    const store = useUserStore();

    await store.fetchUser('1');

    expect(store.user).toEqual({ id: '1', name: 'John' });
  });
});

// Component with store
describe('UserProfile', () => {
  it('displays user from store', () => {
    const wrapper = mount(UserProfile, {
      global: {
        plugins: [createTestingPinia({
          initialState: {
            user: { user: { id: '1', name: 'John' } },
          },
        })],
      },
    });

    expect(wrapper.text()).toContain('John');
  });
});
```

### Testing Vue Router

```typescript
import { mount } from '@vue/test-utils';
import { createRouter, createMemoryHistory } from 'vue-router';

describe('Navigation', () => {
  it('navigates to profile', async () => {
    const router = createRouter({
      history: createMemoryHistory(),
      routes: [
        { path: '/', component: Home },
        { path: '/profile', component: Profile },
      ],
    });

    const wrapper = mount(App, {
      global: { plugins: [router] },
    });

    await router.isReady();
    await wrapper.find('[data-test="profile-link"]').trigger('click');
    await router.isReady();

    expect(router.currentRoute.value.path).toBe('/profile');
  });
});
```

---

## Accessibility Testing

### Basic A11y Assertions

```typescript
import { axe, toHaveNoViolations } from 'jest-axe';

expect.extend(toHaveNoViolations);

describe('Accessibility', () => {
  it('has no violations', async () => {
    const { container } = render(<MyComponent />);
    const results = await axe(container);
    expect(results).toHaveNoViolations();
  });

  it('has no violations in specific rules', async () => {
    const { container } = render(<MyComponent />);
    const results = await axe(container, {
      rules: {
        'color-contrast': { enabled: false }, // Skip color contrast
      },
    });
    expect(results).toHaveNoViolations();
  });
});
```

### Testing Keyboard Navigation

```typescript
describe('Modal', () => {
  it('traps focus within modal', async () => {
    const user = userEvent.setup();
    render(<Modal isOpen />);

    const closeButton = screen.getByRole('button', { name: /close/i });
    const confirmButton = screen.getByRole('button', { name: /confirm/i });

    // Focus should cycle within modal
    closeButton.focus();
    await user.tab();
    expect(confirmButton).toHaveFocus();

    await user.tab();
    expect(closeButton).toHaveFocus(); // Cycles back
  });

  it('closes on Escape key', async () => {
    const user = userEvent.setup();
    const onClose = vi.fn();
    render(<Modal isOpen onClose={onClose} />);

    await user.keyboard('{Escape}');

    expect(onClose).toHaveBeenCalled();
  });
});
```

### Testing ARIA

```typescript
describe('Accordion', () => {
  it('has correct ARIA attributes', async () => {
    const user = userEvent.setup();
    render(<Accordion items={items} />);

    const button = screen.getByRole('button', { name: /section 1/i });
    const panel = screen.getByRole('region', { name: /section 1/i });

    // Initially collapsed
    expect(button).toHaveAttribute('aria-expanded', 'false');
    expect(panel).not.toBeVisible();

    // After click, expanded
    await user.click(button);
    expect(button).toHaveAttribute('aria-expanded', 'true');
    expect(panel).toBeVisible();
  });

  it('announces live region updates', async () => {
    render(<NotificationCenter />);

    const liveRegion = screen.getByRole('status');
    expect(liveRegion).toHaveAttribute('aria-live', 'polite');
  });
});
```

---

## Visual State Testing

### Testing with Storybook

```typescript
// Button.stories.tsx
import type { Meta, StoryObj } from '@storybook/react';
import { Button } from './Button';

const meta: Meta<typeof Button> = {
  component: Button,
  argTypes: {
    variant: { control: 'select', options: ['primary', 'secondary'] },
  },
};

export default meta;
type Story = StoryObj<typeof Button>;

export const Primary: Story = {
  args: { variant: 'primary', children: 'Click me' },
};

export const Loading: Story = {
  args: { loading: true, children: 'Loading...' },
};

export const Disabled: Story = {
  args: { disabled: true, children: 'Disabled' },
};

// Interaction testing in Storybook
export const FormSubmit: Story = {
  play: async ({ canvasElement }) => {
    const canvas = within(canvasElement);
    await userEvent.type(canvas.getByLabelText(/email/i), 'test@example.com');
    await userEvent.click(canvas.getByRole('button'));
    await expect(canvas.getByText(/success/i)).toBeInTheDocument();
  },
};
```

### Snapshot Testing (Judicious Use)

```typescript
// Good: Snapshot for generated output
it('generates correct markdown', () => {
  const markdown = generateMarkdown(data);
  expect(markdown).toMatchSnapshot();
});

// Good: Inline snapshot for small output
it('formats currency', () => {
  expect(formatCurrency(1234.5)).toMatchInlineSnapshot(`"$1,234.50"`);
});

// Avoid: Full component snapshots
it('renders', () => {
  expect(render(<ComplexPage />)).toMatchSnapshot(); // Too brittle
});
```

---

## Anti-Patterns to Avoid

### Testing Implementation

```typescript
// Testing internal methods
it('calls internal validate', () => {
  const wrapper = mount(Form);
  const validateSpy = vi.spyOn(wrapper.vm, 'validate');
  wrapper.find('form').trigger('submit');
  expect(validateSpy).toHaveBeenCalled();
});

// Testing behavior instead
it('shows validation error', async () => {
  const user = userEvent.setup();
  render(<Form />);
  await user.click(screen.getByRole('button', { name: /submit/i }));
  expect(screen.getByText(/required/i)).toBeInTheDocument();
});
```

### Over-Mocking

```typescript
// Mocking everything
vi.mock('./useUser');
vi.mock('./api');
vi.mock('./utils');
// What are we even testing?

// Mock only external boundaries
server.use(
  http.get('/api/user', () => HttpResponse.json(mockUser))
);
```

### Waiting Arbitrarily

```typescript
// Arbitrary timeout
await new Promise(r => setTimeout(r, 500));
expect(screen.getByText('Done')).toBeInTheDocument();

// Wait for condition
await waitFor(() => {
  expect(screen.getByText('Done')).toBeInTheDocument();
});
```
