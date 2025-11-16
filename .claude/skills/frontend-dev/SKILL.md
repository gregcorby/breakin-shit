# Frontend Development Skill

**Purpose:** Ensure production-ready, accessible, responsive frontend code

## Core Principles

### 1. Component Structure
```typescript
// ✅ CORRECT - Proper component structure
interface UserProfileProps {
  userId: string;
  onUpdate?: (user: User) => void;
}

export const UserProfile: React.FC<UserProfileProps> = ({ userId, onUpdate }) => {
  // Real API integration
  const { data: user, isLoading, error } = useUser(userId);

  if (isLoading) return <LoadingSpinner />;
  if (error) return <ErrorMessage error={error} />;
  if (!user) return <NotFound />;

  return (
    <div className="user-profile">
      <h1>{user.name}</h1>
      {/* Component implementation */}
    </div>
  );
};

// ❌ WRONG - Mock data
export const UserProfile = () => {
  const user = { id: 1, name: 'Mock User' }; // NO!
  return <div>{user.name}</div>;
};
```

### 2. Real Data Integration
```typescript
// ✅ CORRECT - Real API hook
export const useUser = (userId: string) => {
  return useQuery(['user', userId], async () => {
    const response = await fetch(`${API_BASE_URL}/users/${userId}`);
    if (!response.ok) throw new Error('Failed to fetch user');
    return response.json();
  });
};

// ❌ WRONG - Fake data
export const useUser = (userId: string) => {
  return { data: mockUser, isLoading: false };
};
```

### 3. Accessibility (WCAG 2.1 AA)
```typescript
// ✅ CORRECT - Accessible button
<button
  onClick={handleSubmit}
  aria-label="Submit registration form"
  disabled={isSubmitting}
>
  {isSubmitting ? 'Submitting...' : 'Submit'}
</button>

// ❌ WRONG - Not accessible
<div onClick={handleSubmit}>Submit</div>
```

### 4. Responsive Design
```css
/* ✅ CORRECT - Mobile-first responsive */
.container {
  padding: 1rem;
  width: 100%;
}

@media (min-width: 768px) {
  .container {
    padding: 2rem;
    max-width: 1200px;
    margin: 0 auto;
  }
}

/* ❌ WRONG - Desktop-only */
.container {
  width: 1200px;
  padding: 2rem;
}
```

## Required Patterns

### Error Handling
```typescript
export const DataComponent = () => {
  const { data, error, isLoading } = useData();

  // Always handle all states
  if (isLoading) return <LoadingState />;
  if (error) return <ErrorState message={error.message} />;
  if (!data) return <EmptyState />;

  return <DataDisplay data={data} />;
};
```

### Loading States
```typescript
// ✅ CORRECT - Progressive loading
{isLoading ? (
  <Skeleton count={5} />
) : (
  <UserList users={users} />
)}

// ❌ WRONG - No loading state
<UserList users={users} /> {/* Undefined until loaded */}
```

### Form Validation
```typescript
// ✅ CORRECT - Real-time validation
const { register, handleSubmit, formState: { errors } } = useForm({
  resolver: zodResolver(userSchema)
});

<input
  {...register('email')}
  type="email"
  aria-invalid={errors.email ? 'true' : 'false'}
  aria-describedby={errors.email ? 'email-error' : undefined}
/>
{errors.email && (
  <span id="email-error" role="alert">{errors.email.message}</span>
)}

// ❌ WRONG - No validation
<input type="email" value={email} onChange={e => setEmail(e.target.value)} />
```

## Forbidden Patterns

### ❌ Inline Styles (except dynamic values)
```typescript
// WRONG
<div style={{ color: 'red', fontSize: '16px' }}>Text</div>

// ✅ CORRECT
<div className="text-error">Text</div>

// ✅ ACCEPTABLE - Dynamic value
<div style={{ width: `${progress}%` }}>Progress</div>
```

### ❌ Hardcoded Data
```typescript
// WRONG
const users = [
  { id: 1, name: 'John' },
  { id: 2, name: 'Jane' }
];

// ✅ CORRECT
const { data: users } = useUsers(); // Real API
```

### ❌ Non-Semantic HTML
```typescript
// WRONG
<div onClick={handleClick}>Click me</div>

// ✅ CORRECT
<button onClick={handleClick}>Click me</button>
```

### ❌ Missing Key Props in Lists
```typescript
// WRONG
{users.map(user => <UserCard user={user} />)}

// ✅ CORRECT
{users.map(user => <UserCard key={user.id} user={user} />)}
```

## Required Checklist

Before committing frontend code:
- [ ] Real API integration (no mock data)
- [ ] Loading states implemented
- [ ] Error states implemented
- [ ] Empty states implemented
- [ ] Accessibility: ARIA labels, keyboard navigation
- [ ] Responsive: Mobile, tablet, desktop tested
- [ ] Form validation (if forms present)
- [ ] TypeScript types defined (no `any`)
- [ ] Performance: No unnecessary re-renders
- [ ] Browser tested: Chrome, Firefox, Safari

## Performance Requirements

### Code Splitting
```typescript
// ✅ CORRECT - Lazy load heavy components
const HeavyChart = lazy(() => import('./HeavyChart'));

<Suspense fallback={<ChartSkeleton />}>
  <HeavyChart data={data} />
</Suspense>
```

### Memoization
```typescript
// ✅ CORRECT - Memoize expensive computations
const filteredData = useMemo(
  () => data.filter(item => item.active),
  [data]
);

// ✅ CORRECT - Memoize callbacks
const handleClick = useCallback(
  () => onUpdate(item.id),
  [item.id, onUpdate]
);
```

## Design System Integration

### Use Design Tokens
```typescript
// ✅ CORRECT
import { colors, spacing, typography } from '@/design-system';

const styles = {
  color: colors.primary,
  padding: spacing.md,
  fontSize: typography.body
};

// ❌ WRONG - Magic numbers
const styles = {
  color: '#3B82F6',
  padding: '16px',
  fontSize: '14px'
};
```

### Component Library
```typescript
// ✅ CORRECT - Use design system components
import { Button, Input, Card } from '@/components/ui';

<Card>
  <Input label="Email" {...register('email')} />
  <Button variant="primary" onClick={handleSubmit}>Submit</Button>
</Card>

// ❌ WRONG - Custom implementations of standard components
<div className="custom-card">
  <div className="custom-input">...</div>
  <div className="custom-button">...</div>
</div>
```

## Testing Requirements

### Component Tests
```typescript
describe('UserProfile', () => {
  it('should fetch and display real user data', async () => {
    render(<UserProfile userId="123" />);

    // Shows loading state
    expect(screen.getByTestId('loading-spinner')).toBeInTheDocument();

    // Waits for real API response
    const userName = await screen.findByText('John Doe');
    expect(userName).toBeInTheDocument();
  });

  it('should handle API errors', async () => {
    // Mock API failure
    server.use(
      rest.get('/api/users/:id', (req, res, ctx) => {
        return res(ctx.status(500));
      })
    );

    render(<UserProfile userId="123" />);

    const errorMessage = await screen.findByText(/failed to load/i);
    expect(errorMessage).toBeInTheDocument();
  });
});
```

### Accessibility Tests
```typescript
import { axe } from 'jest-axe';

it('should have no accessibility violations', async () => {
  const { container } = render(<UserForm />);
  const results = await axe(container);
  expect(results).toHaveNoViolations();
});
```

## Auto-Activation Triggers

This skill activates when prompt contains:
- component, React, Vue, Svelte
- frontend, UI, interface
- design, styling, CSS
- responsive, mobile, accessibility

## Integration with API Skill

When building frontend components that fetch data:
1. **api-integration** skill loads automatically
2. Both skills enforce: NO MOCK DATA
3. Real API endpoints required
4. Error handling mandatory
5. Loading states required

## Remember

**Frontend code is user-facing. Every shortcut is visible to users.**

- Mock data breaks user trust
- Missing error states confuse users
- Poor accessibility excludes users
- Unresponsive design frustrates users

Build for real users, with real data, in real browsers.
