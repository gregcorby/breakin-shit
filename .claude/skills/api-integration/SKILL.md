# API Integration Skill

**Purpose:** Enforce real API usage and prevent mock data shortcuts

## Mandatory Requirements

When working with APIs, you MUST:

### 1. Use Real API Endpoints
```typescript
// ✅ CORRECT - Real API call
const response = await fetch(`${process.env.API_BASE_URL}/users`, {
  headers: {
    'Authorization': `Bearer ${process.env.API_KEY}`
  }
});

// ❌ WRONG - Mock data
const response = { data: mockUsers };
```

### 2. Environment Variables Required
Every API integration MUST have:
- `API_BASE_URL` - Base URL for the API
- `API_KEY` or authentication mechanism
- NO hardcoded URLs or keys

### 3. Error Handling Required
```typescript
try {
  const response = await fetch(endpoint);
  if (!response.ok) {
    throw new Error(`API error: ${response.status}`);
  }
  return await response.json();
} catch (error) {
  // Real error handling - not just console.log
  logger.error('API call failed:', error);
  throw error;
}
```

### 4. Integration Tests Required
For every API endpoint integration:
```typescript
describe('User API Integration', () => {
  it('should fetch real user data', async () => {
    // Must call REAL API, not mocked
    const users = await userService.getUsers();

    expect(users).toBeDefined();
    expect(Array.isArray(users)).toBe(true);
    // Verify actual data structure
    if (users.length > 0) {
      expect(users[0]).toHaveProperty('id');
      expect(users[0]).toHaveProperty('email');
    }
  });
});
```

## Forbidden Patterns

### ❌ Mock Data in Production Code
```typescript
// NEVER do this
const mockData = [
  { id: 1, name: 'Test User' }
];
return mockData;
```

### ❌ Fake API Responses
```typescript
// NEVER do this
async function getUsers() {
  return Promise.resolve({ data: [] });
}
```

### ❌ Commented Out Real API Calls
```typescript
// NEVER do this
// const response = await fetch(API_URL);
return mockResponse;
```

## Validation Checklist

Before committing API integration code:
- [ ] Real API endpoint called (no mocks in production)
- [ ] Environment variables configured
- [ ] Error handling implemented
- [ ] Integration test written and passing
- [ ] API credentials NOT hardcoded
- [ ] Response validation implemented

## When Mocking IS Allowed

Mocking is ONLY permitted for:
1. **Unit tests** of business logic (not integration tests)
2. **Third-party APIs** you don't control (Stripe, SendGrid, etc.)
3. **Development seed data** clearly marked as such

Even then, you MUST also have integration tests that hit real endpoints.

## API Integration Pattern

```typescript
// services/api.service.ts
export class ApiService {
  private baseUrl: string;
  private apiKey: string;

  constructor() {
    // Fail fast if config missing
    this.baseUrl = process.env.API_BASE_URL;
    this.apiKey = process.env.API_KEY;

    if (!this.baseUrl || !this.apiKey) {
      throw new Error('API configuration missing');
    }
  }

  async get<T>(endpoint: string): Promise<T> {
    const response = await fetch(`${this.baseUrl}${endpoint}`, {
      headers: {
        'Authorization': `Bearer ${this.apiKey}`,
        'Content-Type': 'application/json'
      }
    });

    if (!response.ok) {
      throw new Error(`API error: ${response.status} ${response.statusText}`);
    }

    return await response.json();
  }
}
```

## Auto-Activation Triggers

This skill activates when prompt contains:
- API, endpoint, route, REST
- fetch, axios, request
- backend, server, integration

## Consequences of Violation

If you use mock data instead of real APIs:
- Pre-commit hooks will BLOCK your commit
- CI/CD pipeline will FAIL
- Code review will REJECT your PR
- Third-party audit will flag the violation

**There are no shortcuts. Real APIs only.**
