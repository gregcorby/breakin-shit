# Test Validator Skill

**Purpose:** Prevent fake tests and ensure real test coverage

## Mandatory Test Requirements

### 1. Real Assertions Required
```typescript
// ✅ CORRECT - Real assertion
it('should validate user email', () => {
  const result = validateEmail('test@example.com');
  expect(result).toBe(true);
});

// ❌ WRONG - No assertion
it('should validate user email', () => {
  validateEmail('test@example.com');
  // Test passes but validates nothing
});
```

### 2. Test Real Behavior, Not Mocks
```typescript
// ✅ CORRECT - Tests real integration
it('should save user to database', async () => {
  const user = await userService.createUser({ email: 'test@example.com' });

  // Verify in actual database
  const saved = await db.users.findById(user.id);
  expect(saved).toBeDefined();
  expect(saved.email).toBe('test@example.com');
});

// ❌ WRONG - Only tests mocks
it('should save user to database', async () => {
  const mockSave = jest.fn().mockResolvedValue({ id: 1 });
  db.users.save = mockSave;

  await userService.createUser({ email: 'test@example.com' });
  expect(mockSave).toHaveBeenCalled();
  // This doesn't test if it ACTUALLY saves!
});
```

### 3. Assertion Ratio Rule
**For every mock, you need 2+ assertions testing real behavior**

```typescript
// ✅ CORRECT - Balanced
it('should handle API errors gracefully', async () => {
  // Mock external API (acceptable)
  nock('https://api.example.com')
    .get('/users')
    .reply(500);

  // Multiple assertions on real behavior
  await expect(userService.getUsers()).rejects.toThrow();
  expect(logger.error).toHaveBeenCalled();
  const retryCount = await cache.get('retry-count');
  expect(retryCount).toBe(1);
});

// ❌ WRONG - More mocks than assertions
it('should handle API errors', async () => {
  jest.fn().mockRejectedValue(new Error());
  // No real assertions about behavior
});
```

### 4. Coverage Requirements
- **Minimum:** 80% line coverage
- **Target:** 90% branch coverage
- **Critical paths:** 100% coverage (auth, payments, data mutations)

## Forbidden Test Patterns

### ❌ Empty Tests
```typescript
it('should work', () => {
  // TODO: Write test
});
```

### ❌ Tests That Always Pass
```typescript
it('should process payment', () => {
  expect(true).toBe(true);
});
```

### ❌ Tests Without Cleanup
```typescript
it('should create user', async () => {
  await createUser({ email: 'test@example.com' });
  // ❌ User left in database, pollutes other tests
});

// ✅ CORRECT
it('should create user', async () => {
  const user = await createUser({ email: 'test@example.com' });
  expect(user).toBeDefined();

  // Cleanup
  await deleteUser(user.id);
});
```

### ❌ Skipped Tests in Commits
```typescript
it.skip('should validate input', () => {
  // ❌ Can't commit skipped tests
});
```

## Required Test Types

### Unit Tests
Test individual functions in isolation:
```typescript
describe('validateEmail', () => {
  it('should accept valid emails', () => {
    expect(validateEmail('user@example.com')).toBe(true);
  });

  it('should reject invalid emails', () => {
    expect(validateEmail('invalid')).toBe(false);
  });

  it('should handle edge cases', () => {
    expect(validateEmail('')).toBe(false);
    expect(validateEmail(null)).toBe(false);
  });
});
```

### Integration Tests
Test real system interactions:
```typescript
describe('User Registration Flow', () => {
  it('should register user end-to-end', async () => {
    // Real HTTP request
    const response = await request(app)
      .post('/api/register')
      .send({ email: 'test@example.com', password: 'secure123' });

    expect(response.status).toBe(201);

    // Verify in real database
    const user = await db.users.findByEmail('test@example.com');
    expect(user).toBeDefined();
    expect(user.passwordHash).not.toBe('secure123'); // Hashed

    // Cleanup
    await db.users.delete(user.id);
  });
});
```

### E2E Tests (for critical flows)
```typescript
describe('Complete Purchase Flow', () => {
  it('should complete purchase from cart to confirmation', async () => {
    // Real browser automation
    await page.goto('/products');
    await page.click('[data-testid="add-to-cart"]');
    await page.goto('/checkout');
    // ... real user flow
  });
});
```

## Test Quality Checklist

Before committing tests:
- [ ] Every test has at least 1 real assertion
- [ ] Integration tests use real database/API
- [ ] No skipped tests (`.skip`, `.todo`)
- [ ] Mock ratio: 2+ assertions per mock
- [ ] Cleanup code present (teardown, afterEach)
- [ ] Tests are deterministic (no random data without seeds)
- [ ] Coverage meets minimum thresholds

## When Mocking IS Required

Mock ONLY:
1. **Time/dates** - Use fixed timestamps
2. **Random generators** - Use seeded random
3. **External APIs** - Third-party services you don't control
4. **File system** - In unit tests (not integration)
5. **Network calls** - In unit tests (not integration)

## Test Structure Template

```typescript
describe('[Component/Function Name]', () => {
  // Setup
  beforeEach(() => {
    // Initialize test environment
  });

  // Teardown
  afterEach(() => {
    // Clean up resources
  });

  describe('[Feature/Method]', () => {
    it('should [expected behavior] when [condition]', () => {
      // Arrange
      const input = createTestData();

      // Act
      const result = functionUnderTest(input);

      // Assert
      expect(result).toBe(expectedOutput);
    });

    it('should handle [edge case]', () => {
      // Test edge case
    });

    it('should throw error when [invalid input]', () => {
      expect(() => functionUnderTest(invalidInput)).toThrow();
    });
  });
});
```

## Validation Enforcement

The test-authenticity-check hook will:
1. Count assertions vs mocks
2. Verify tests actually run (not skipped)
3. Check coverage thresholds
4. Detect empty or always-passing tests
5. **BLOCK commits** if violations found

## Auto-Activation Triggers

This skill activates when prompt contains:
- test, spec, testing
- jest, vitest, mocha
- assert, expect, should
- coverage, TDD, unit test

## Remember

**A test that doesn't test real behavior is worse than no test - it gives false confidence.**

Write tests that would fail if your code is broken.
