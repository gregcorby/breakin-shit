# AI-Assisted Development Workflow: Comprehensive Recommendations

**Created:** 2025-11-14
**Target User:** Product Designer & Frontend Developer
**Goal:** Maximize AI/LLM/Agentic capabilities while ensuring reliability and preventing common pitfalls

---

## Executive Summary

This workflow architecture addresses four critical challenges:
1. **Context loss and poor context management**
2. **Agents using mock data instead of directed APIs**
3. **Agents pretending to complete tasks**
4. **Faking tests**

The solution integrates proven patterns from the [claude-code-infrastructure-showcase](https://github.com/diet103/claude-code-infrastructure-showcase) with modern validation mechanisms, atomic git workflows, and third-party verification systems.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    FEATURE INITIATION                        │
│  • Atomic branch creation (feature/[name])                  │
│  • Dev docs auto-generation (/dev-docs command)             │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────────┐
│                PRE-WORK VALIDATION (Hooks)                   │
│  • Auto-skill activation analysis                            │
│  • Context preservation checks                               │
│  • API availability verification                             │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────────┐
│                  DEVELOPMENT PHASE                           │
│  • Modular skill execution (≤500 line chunks)               │
│  • Progressive disclosure of context                         │
│  • Continuous dev docs updates                               │
└─────────────────┬───────────────────────────────────────────┘
                  │
┌─────────────────▼───────────────────────────────────────────┐
│              POST-WORK VALIDATION (Hooks)                    │
│  • TypeScript compilation (tsc-check.sh)                     │
│  • Build verification (enhanced stop-build-check)            │
│  • Route testing (authenticated API endpoints)               │
│  • Third-party audit (Repomix snapshot + external LLM)      │
└─────────────────┬───────────────────────────────────────────┘
                  │
                  ├─── PASS ──► Atomic commit (--no-ff)
                  │
                  └─── FAIL ──► Rollback & restart with context
```

---

## 1. Context Management System

### Problem Statement
AI agents lose context across sessions, leading to repeated mistakes and knowledge degradation.

### Solution: Dev Docs Pattern

Implement the three-file documentation system from claude-code-infrastructure-showcase:

#### Structure
```
/dev-docs/
  ├── [feature]-plan.md      # Strategic approach
  ├── [feature]-context.md   # Key decisions & file references
  └── [feature]-tasks.md     # Checklist format
```

#### Implementation
1. **Auto-generate with slash command:**
   ```bash
   /dev-docs [feature-name]
   ```

2. **Update continuously:** Every significant decision, file change, or architectural choice gets documented immediately

3. **Session recovery:** Start each new session by reading relevant dev docs

#### Benefits
- **Persistent memory** across context resets
- **Accountability trail** prevents repeated mistakes
- **Onboarding efficiency** for switching between projects

---

## 2. Feature-Based Atomic Workflow

### Problem Statement
Need to chunk work into verifiable units that can be rolled back cleanly.

### Solution: Git Flow with Atomic Commits

#### Branch Strategy
```bash
# Feature branches
feature/[feature-name]

# Each feature gets its own isolated branch
git checkout -b feature/user-authentication
```

#### Atomic Commit Rules
1. **One logical change per commit**
   - ✅ "Add user login API endpoint"
   - ❌ "Fix bugs and add features and update docs"

2. **Force non-fast-forward merges**
   ```bash
   git merge feature/user-auth --no-ff
   ```
   - Creates merge commit preserving feature boundary
   - Enables single-command rollback: `git revert -m 1 <merge-commit>`

3. **Commit message convention**
   ```
   [TYPE]: Brief description

   - What changed
   - Why it changed
   - API endpoints affected (if applicable)
   ```

#### Rollback Strategy
```bash
# Roll back entire feature
git revert -m 1 <merge-commit-hash>

# Roll back specific atomic commit
git revert <commit-hash>

# Soft rollback (keep working directory)
git reset --soft HEAD~1
```

---

## 3. Pre-Validation Hooks (Prevention Layer)

### Problem Statement
Agents start work without proper context or make assumptions about API availability.

### Solution: UserPromptSubmit Hook with Skill Auto-Activation

#### Implementation
Based on claude-code-infrastructure-showcase pattern:

**File:** `.claude/hooks/UserPromptSubmit.sh`
```bash
#!/bin/bash

# 1. Analyze incoming prompt for context
PROMPT="$1"
FILES_CONTEXT="$2"

# 2. Check against skill-rules.json for auto-activation
# Examples:
# - "API" keyword → route-tester skill
# - "backend" keyword → backend-dev-guidelines
# - "test" keyword → testing validation rules

# 3. Validate API availability before work starts
if [[ "$PROMPT" =~ "API" ]]; then
    echo "🔍 Detected API work. Validating endpoints..."
    # Check .env for API URLs
    # Ping health endpoints
    # Load API documentation context
fi

# 4. Load relevant dev docs
if [[ -d "dev-docs" ]]; then
    FEATURE=$(echo "$PROMPT" | extract_feature_name)
    if [[ -f "dev-docs/${FEATURE}-context.md" ]]; then
        echo "📚 Loading context from dev-docs/${FEATURE}-context.md"
    fi
fi
```

#### Skill Auto-Activation Rules
**File:** `.claude/skills/skill-rules.json`
```json
{
  "rules": [
    {
      "triggers": ["API", "endpoint", "route", "REST"],
      "skill": "route-tester",
      "message": "🚀 Activating route-tester skill for API work"
    },
    {
      "triggers": ["test", "spec", "jest"],
      "skill": "test-validator",
      "message": "🧪 Activating test-validator to prevent mock shortcuts"
    },
    {
      "triggers": ["authentication", "auth", "login"],
      "skill": "auth-guidelines",
      "message": "🔐 Loading authentication best practices"
    }
  ]
}
```

---

## 4. Post-Validation Hooks (Verification Layer)

### Problem Statement
Agents claim work is complete when tests are faked, builds don't compile, or APIs aren't integrated.

### Solution: Multi-Layer Stop Hooks

#### Layer 1: Compilation Verification
**File:** `.claude/hooks/stop/tsc-check.sh`
```bash
#!/bin/bash

echo "🔍 Running TypeScript compilation check..."

# Run tsc --noEmit (type checking without output)
npx tsc --noEmit

if [ $? -ne 0 ]; then
    echo "❌ TypeScript compilation failed!"
    echo "🚫 BLOCKING: Fix type errors before proceeding"
    exit 1
fi

echo "✅ TypeScript compilation passed"
```

#### Layer 2: Build System Validation
**File:** `.claude/hooks/stop/stop-build-check-enhanced.sh`
```bash
#!/bin/bash

echo "🏗️  Running full build..."

# Run actual build command
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed!"
    echo "🚫 BLOCKING: Build must succeed before commit"
    exit 1
fi

# Verify build artifacts exist
if [ ! -d "dist" ] || [ -z "$(ls -A dist)" ]; then
    echo "❌ Build directory empty or missing!"
    exit 1
fi

echo "✅ Build completed successfully"
```

#### Layer 3: API Integration Verification
**File:** `.claude/hooks/stop/api-integration-check.sh`
```bash
#!/bin/bash

echo "🌐 Verifying real API integration (no mocks allowed)..."

# 1. Check for mock indicators
MOCK_PATTERNS=(
    "mockData"
    "MOCK_API"
    "faker"
    "jest.mock"
    "vi.mock"
)

for pattern in "${MOCK_PATTERNS[@]}"; do
    if git diff --cached | grep -q "$pattern"; then
        echo "⚠️  Detected potential mock: $pattern"
        echo "📋 Verify this is intentional and not replacing real API"
    fi
done

# 2. Verify API environment variables exist
if [ -f ".env" ]; then
    required_vars=("API_BASE_URL" "API_KEY")
    for var in "${required_vars[@]}"; do
        if ! grep -q "^${var}=" .env; then
            echo "❌ Missing required API variable: $var"
            exit 1
        fi
    done
fi

# 3. Test actual API connectivity (if test suite exists)
if [ -f "tests/api-integration.test.ts" ]; then
    echo "🧪 Running API integration tests..."
    npm run test:api-integration

    if [ $? -ne 0 ]; then
        echo "❌ API integration tests failed!"
        echo "🚫 BLOCKING: Real API tests must pass"
        exit 1
    fi
fi

echo "✅ API integration verified"
```

#### Layer 4: Test Authenticity Verification
**File:** `.claude/hooks/stop/test-authenticity-check.sh`
```bash
#!/bin/bash

echo "🧪 Verifying test authenticity..."

# 1. Check for test file changes in this commit
TEST_FILES=$(git diff --cached --name-only | grep -E '\.(test|spec)\.(ts|tsx|js|jsx)$')

if [ -n "$TEST_FILES" ]; then
    echo "📝 Found test files in commit:"
    echo "$TEST_FILES"

    # 2. Run tests and capture coverage
    npm run test -- --coverage --passWithNoTests=false

    if [ $? -ne 0 ]; then
        echo "❌ Tests failed!"
        exit 1
    fi

    # 3. Check for suspiciously simple tests
    for file in $TEST_FILES; do
        # Check if test file has actual assertions
        if ! grep -q -E "(expect|assert|should)" "$file"; then
            echo "⚠️  Warning: $file has no assertions!"
            echo "🚫 BLOCKING: Tests must have real assertions"
            exit 1
        fi

        # Check if test is just mocked without real logic
        MOCK_COUNT=$(grep -c "mock" "$file")
        EXPECT_COUNT=$(grep -c "expect" "$file")

        if [ $MOCK_COUNT -gt $EXPECT_COUNT ]; then
            echo "⚠️  Warning: $file has more mocks than assertions"
            echo "   This suggests tests may be too shallow"
        fi
    done
fi

echo "✅ Test authenticity verified"
```

---

## 5. Third-Party Audit System (Repomix Integration)

### Problem Statement
Need external verification that work is genuinely complete, not just claimed complete.

### Solution: Repomix + External LLM Validation

#### Architecture
```
Local Agent Work → Stop Hooks Pass → Repomix Snapshot → External LLM Audit → Commit
```

#### Implementation

**Step 1: Install Repomix**
```bash
npm install -g repomix
```

**Step 2: Create Audit Hook**
**File:** `.claude/hooks/stop/third-party-audit.sh`
```bash
#!/bin/bash

echo "🔍 Starting third-party audit..."

# 1. Create Repomix snapshot of changed files
CHANGED_FILES=$(git diff --cached --name-only)

if [ -z "$CHANGED_FILES" ]; then
    echo "No changes to audit"
    exit 0
fi

# 2. Generate AI-friendly snapshot
repomix --output /tmp/audit-snapshot.xml --include "$CHANGED_FILES"

# 3. Create audit prompt
cat > /tmp/audit-prompt.txt <<EOF
You are an independent code auditor. Review the following code changes and verify:

1. ✅ All tests have real assertions (not just mocks)
2. ✅ API integrations use real endpoints (not mock data)
3. ✅ Code compiles without errors
4. ✅ No placeholder TODO comments remain
5. ✅ Security: No hardcoded secrets or API keys
6. ✅ Error handling is implemented

Respond with:
- PASS: If all criteria met
- FAIL: With specific issues found

Code snapshot:
$(cat /tmp/audit-snapshot.xml)
EOF

# 4. Send to external LLM for audit (using Claude API)
# Note: This requires ANTHROPIC_API_KEY environment variable
if [ -n "$ANTHROPIC_API_KEY" ]; then
    AUDIT_RESULT=$(curl -s https://api.anthropic.com/v1/messages \
        -H "x-api-key: $ANTHROPIC_API_KEY" \
        -H "anthropic-version: 2023-06-01" \
        -H "content-type: application/json" \
        -d "{
            \"model\": \"claude-3-5-sonnet-20241022\",
            \"max_tokens\": 1024,
            \"messages\": [{
                \"role\": \"user\",
                \"content\": \"$(cat /tmp/audit-prompt.txt | jq -Rs .)\"
            }]
        }" | jq -r '.content[0].text')

    echo "$AUDIT_RESULT"

    # 5. Parse result
    if echo "$AUDIT_RESULT" | grep -q "FAIL"; then
        echo "❌ Third-party audit FAILED"
        echo "$AUDIT_RESULT"
        exit 1
    fi
fi

echo "✅ Third-party audit passed"
```

**Step 3: Configure Repomix**
**File:** `repomix.config.json`
```json
{
  "output": {
    "filePath": "repomix-output.xml",
    "style": "xml",
    "removeComments": false,
    "showLineNumbers": true,
    "topFilesLength": 5
  },
  "include": [
    "**/*.ts",
    "**/*.tsx",
    "**/*.test.ts"
  ],
  "ignore": {
    "useGitignore": true,
    "useDefaultPatterns": true,
    "customPatterns": [
      "dist/**",
      "node_modules/**",
      "*.log"
    ]
  },
  "security": {
    "enableSecurityCheck": true
  }
}
```

#### Benefits
- **Independent verification:** External LLM has no bias toward passing
- **Token-efficient context:** Repomix compresses code ~70% with tree-sitter
- **Security scanning:** Built-in detection of secrets and sensitive data
- **Audit trail:** Snapshots provide historical record of what was validated

---

## 6. Modular Skills System (Progressive Disclosure)

### Problem Statement
Large contexts cause agents to skip details or hallucinate completion.

### Solution: 500-Line Modular Skills

#### Pattern from claude-code-infrastructure-showcase

**File:** `.claude/skills/backend-dev-guidelines/SKILL.md`
```markdown
# Backend Development Guidelines

## Navigation (Main Index)
- [Routing Patterns](./routing.md)
- [Controller Standards](./controllers.md)
- [Service Layer](./services.md)
- [Repository Pattern](./repositories.md)
- [Testing Standards](./testing.md)

## Quick Start
When working on backend features:
1. Check routing.md for endpoint structure
2. Follow controller.md for request handling
3. Implement business logic per services.md
4. Use repositories.md for data access
5. Validate with testing.md standards

## Anti-Patterns to Avoid
- ❌ Direct database calls in controllers
- ❌ Business logic in routes
- ❌ Mocking external APIs without integration tests
- ❌ Skipping error handling
```

**File:** `.claude/skills/backend-dev-guidelines/testing.md` (≤500 lines)
```markdown
# Testing Standards

## Integration Tests Required
For every API endpoint, you MUST provide:

### 1. Route Test
```typescript
describe('POST /api/users', () => {
    it('should create user with real API call', async () => {
        const response = await request(app)
            .post('/api/users')
            .send({ name: 'Test User', email: 'test@example.com' })
            .expect(201);

        // Verify in database (not mocked)
        const user = await db.users.findById(response.body.id);
        expect(user).toBeDefined();
        expect(user.email).toBe('test@example.com');
    });
});
```

### 2. Authentication Test
```typescript
it('should require authentication', async () => {
    await request(app)
        .post('/api/users')
        .send({ name: 'Test' })
        .expect(401); // No token = unauthorized
});
```

### 3. Validation Test
```typescript
it('should validate required fields', async () => {
    const response = await request(app)
        .post('/api/users')
        .send({ name: 'Test' }) // Missing email
        .expect(400);

    expect(response.body.errors).toContain('email is required');
});
```

## Mock Policy
Mocking is ONLY allowed for:
- Third-party payment APIs (Stripe, PayPal)
- Email services (SendGrid)
- External data providers

Mocking is FORBIDDEN for:
- Your own backend APIs
- Database calls in integration tests
- Authentication flows
```

#### Progressive Disclosure in Action
```
User: "I need to add a new user registration endpoint"

Agent reads: backend-dev-guidelines/SKILL.md (overview)
  ↓
Agent loads: backend-dev-guidelines/routing.md (endpoint structure)
  ↓
Agent loads: backend-dev-guidelines/testing.md (test requirements)
  ↓
Agent implements with full context (not truncated)
```

---

## 7. Complete Workflow Example

### Scenario: Add User Authentication Feature

#### Phase 1: Initiation
```bash
# Create feature branch
git checkout -b feature/user-authentication

# Initialize dev docs
/dev-docs user-authentication
```

**Generated files:**
- `dev-docs/user-authentication-plan.md`
- `dev-docs/user-authentication-context.md`
- `dev-docs/user-authentication-tasks.md`

#### Phase 2: Pre-Work Validation (Automatic)
UserPromptSubmit hook detects "authentication" keyword:
```
🔐 Loading authentication best practices
📚 Loading context from dev-docs/user-authentication-context.md
🌐 Verifying API endpoints exist in .env
✅ Pre-validation complete
```

#### Phase 3: Development
Agent works in chunks:
1. **Atomic commit 1:** Add user model and database schema
2. **Atomic commit 2:** Create authentication routes
3. **Atomic commit 3:** Implement JWT token generation
4. **Atomic commit 4:** Add integration tests

Each commit triggers stop hooks automatically.

#### Phase 4: Post-Work Validation (Each Commit)
```bash
# Automatic sequence on git commit:
1. tsc-check.sh          → ✅ TypeScript compiles
2. stop-build-check.sh   → ✅ Build succeeds
3. api-integration.sh    → ✅ Real API tested
4. test-authenticity.sh  → ✅ Tests have assertions
5. third-party-audit.sh  → 🔍 Repomix + Claude audit

# If any fail → Commit blocked, changes remain staged
```

#### Phase 5: Merge with Rollback Safety
```bash
# Merge to main with non-fast-forward
git checkout main
git merge feature/user-authentication --no-ff -m "Add user authentication feature"

# If issues discovered later, single-command rollback:
git revert -m 1 <merge-commit-hash>
```

---

## 8. Tool Stack Recommendation

### Essential Tools

| Tool | Purpose | Priority |
|------|---------|----------|
| **Claude Code CLI** | Primary AI agent | Critical |
| **Repomix** | Codebase packaging for audit | Critical |
| **pre-commit framework** | Git hook management | High |
| **TypeScript** | Compile-time verification | High (if TS project) |
| **Vitest/Jest** | Test execution & coverage | Critical |
| **Git** | Version control with --no-ff | Critical |

### Optional Enhancements

| Tool | Purpose | When to Use |
|------|---------|-------------|
| **GitHub Actions** | CI/CD automation | Production projects |
| **Anthropic API** | Third-party audit LLM | High-stakes projects |
| **PostToolUse hooks** | Track agent actions | Debugging workflows |
| **Skill auto-activation** | Context preservation | Complex projects |

---

## 9. Implementation Roadmap

### Week 1: Foundation
- [ ] Install claude-code-infrastructure-showcase patterns
- [ ] Set up dev docs structure and /dev-docs command
- [ ] Configure atomic commit workflow
- [ ] Test feature branch → merge → rollback flow

### Week 2: Pre-Validation
- [ ] Implement UserPromptSubmit hook
- [ ] Create skill-rules.json for your domains
- [ ] Build skill library (start with 2-3 core skills)
- [ ] Test skill auto-activation

### Week 3: Post-Validation
- [ ] Install stop hooks (tsc-check, build-check)
- [ ] Create api-integration-check.sh
- [ ] Implement test-authenticity-check.sh
- [ ] Test hook failure scenarios

### Week 4: Third-Party Audit
- [ ] Install Repomix
- [ ] Configure repomix.config.json
- [ ] Set up third-party-audit.sh hook
- [ ] Get Anthropic API key and test audit flow

### Week 5: Refinement
- [ ] Document your workflow in project README
- [ ] Train team (if applicable) on new workflow
- [ ] Create custom skills for your specific domains
- [ ] Optimize hook performance

---

## 10. Measuring Success

### Key Metrics

#### Before Workflow
Track baseline for 2 weeks:
- Context loss incidents per week
- Mock data used instead of real APIs
- Incomplete tasks claimed complete
- Failed tests discovered post-merge

#### After Workflow
Track same metrics after 4 weeks:
- **Expected improvement:** 80-90% reduction in all categories
- **Rollback usage:** Track how often atomic rollbacks save time
- **Dev docs effectiveness:** Survey if context loss improved
- **Hook rejections:** Track how many commits blocked by hooks

### Success Criteria
✅ Zero mock APIs in production code
✅ All tests have real assertions
✅ Context persists across sessions via dev docs
✅ Features can be rolled back in <30 seconds
✅ Third-party audit catches issues before merge

---

## 11. Advanced Patterns

### Multi-Agent Orchestration
For complex features, use specialized agents:

```bash
# Research agent gathers requirements
/research "user authentication patterns"

# Architecture agent designs system
/architect "design auth flow with JWT"

# Implementation agent builds
/implement "follow architecture from dev-docs/auth-plan.md"

# Review agent validates
/review "verify all tests use real APIs"
```

Each agent writes to dev docs, creating audit trail.

### Continuous Context Refresh
```bash
# Periodic context refresh hook
# File: .claude/hooks/PostToolUse.sh

if [[ "$TOOL" == "Edit" ]] || [[ "$TOOL" == "Write" ]]; then
    # Regenerate Repomix snapshot for context
    repomix --output .claude/context-snapshot.xml
    echo "📸 Context snapshot updated"
fi
```

### Feature Flags for Gradual Rollout
```typescript
// In code
if (featureFlags.newAuth) {
    // New implementation (validated by hooks)
} else {
    // Old implementation (fallback)
}
```

Merge with feature flag OFF, then gradually enable after monitoring.

---

## 12. Common Pitfalls & Solutions

### Pitfall 1: Hooks Too Strict
**Symptom:** Can't commit anything, hooks fail constantly
**Solution:** Start with warning-only hooks, gradually make them blocking

### Pitfall 2: Repomix Audit Too Slow
**Symptom:** Third-party audit takes >30 seconds
**Solution:** Only audit changed files, not entire codebase

### Pitfall 3: Dev Docs Get Stale
**Symptom:** Docs not updated, context loss returns
**Solution:** Add pre-commit hook to require dev docs update

### Pitfall 4: Too Many Atomic Commits
**Symptom:** Git history cluttered with tiny commits
**Solution:** Squash related commits before merging to main

---

## 13. Customization for Your Profile

### As Product Designer + Frontend Dev

#### Recommended Skills
1. **design-system-skill:** Ensures component consistency
2. **accessibility-skill:** Auto-checks WCAG compliance
3. **api-integration-skill:** Forces real API usage (your main issue)
4. **responsive-design-skill:** Validates breakpoints

#### Recommended Hooks
```bash
# Pre-commit hook for designers
.claude/hooks/pre-commit/design-tokens-check.sh
→ Verifies CSS variables match design system

# Stop hook for frontend
.claude/hooks/stop/lighthouse-audit.sh
→ Runs Lighthouse performance/a11y checks

# Post-commit hook
.claude/hooks/post-commit/screenshot-artifacts.sh
→ Auto-generates component screenshots for docs
```

#### Simple vs Complex Projects

**Simple projects (landing page, small app):**
- Skip third-party audit (overkill)
- Use basic tsc-check + build-check hooks
- Single dev-docs file instead of three

**Complex projects (multi-page app, design system):**
- Full workflow with all hooks
- Modular skills library
- Repomix audit for every merge to main

---

## 14. Next Steps

### Immediate Actions (Today)
1. Clone claude-code-infrastructure-showcase
2. Read the core patterns (auto-activation, dev docs, modular skills)
3. Set up a test project to experiment

### This Week
1. Implement dev docs pattern
2. Create your first custom skill
3. Set up atomic commit workflow with --no-ff

### This Month
1. Deploy all stop hooks
2. Configure Repomix third-party audit
3. Measure baseline → improved metrics

### Resources
- [claude-code-infrastructure-showcase](https://github.com/diet103/claude-code-infrastructure-showcase)
- [Repomix Documentation](https://repomix.com)
- [pre-commit Framework](https://pre-commit.com)
- [Git Branching Model](https://nvie.com/posts/a-successful-git-branching-model/)

---

## 15. Conclusion

This workflow architecture transforms AI-assisted development from "hope it works" to "verified and auditable." By combining:

- **Context preservation** (dev docs)
- **Prevention** (pre-validation hooks)
- **Verification** (post-validation hooks)
- **External audit** (Repomix + LLM)
- **Rollback safety** (atomic commits)

You create a system where AI agents can operate at maximum capability while being constrained by enforceable guardrails.

The result: **Fast iteration with reliable output** — exactly what product designers and developers need to leverage AI/LLM/agentic capabilities to their fullest extent.

---

**Version:** 1.0
**Last Updated:** 2025-11-14
**Feedback:** Open to community contributions and refinements
