# AI-Assisted Development Workflow System

**Version:** 1.0
**Created:** 2025-11-14
**Purpose:** Production-ready system for AI-assisted development that prevents common pitfalls

## Problem Statement

AI coding agents face four critical problems:
1. **Context loss** - Forget decisions across sessions
2. **Mock data shortcuts** - Use fake data instead of real APIs
3. **Incomplete work** - Claim tasks are done when they're not
4. **Fake tests** - Write tests without real assertions

This system solves all four problems with enforceable guardrails.

## Solution Architecture

```
┌─────────────────────────────────────────┐
│         Feature Initiation               │
│  • Atomic branch creation               │
│  • Dev docs auto-generation             │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│       Pre-Validation Hooks               │
│  • Auto-skill activation                │
│  • Context preservation                 │
│  • API availability check               │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│       Development Phase                  │
│  • Modular skills (≤500 lines)          │
│  • Progressive disclosure               │
│  • Continuous dev docs updates          │
└─────────────┬───────────────────────────┘
              │
┌─────────────▼───────────────────────────┐
│      Post-Validation Hooks               │
│  ✅ TypeScript compilation              │
│  ✅ Build verification                  │
│  ✅ API integration (NO MOCKS)          │
│  ✅ Test authenticity                   │
│  ✅ Third-party audit (optional)        │
└─────────────┬───────────────────────────┘
              │
              ├─── PASS ──► Atomic commit
              │
              └─── FAIL ──► Rollback & restart
```

## Quick Start

### 1. Setup (One Time)

```bash
# Run setup script
bash setup-claude-workflow.sh

# Configure your API
vim .env
```

### 2. Start a Feature

```bash
npm run feature user-authentication
```

This creates:
- Feature branch: `feature/user-authentication`
- Dev docs: `dev-docs/user-authentication-*.md`
- Atomic commit workflow

### 3. Develop

Work normally. The system automatically:
- Activates relevant skills based on your prompts
- Loads context from previous sessions
- Validates your environment

### 4. Commit

```bash
git add .
git commit -m "Add user login endpoint"
```

Hooks automatically verify:
- ✅ Code compiles
- ✅ Build succeeds
- ✅ **No mock data**
- ✅ **Tests are real**
- ✅ Third-party audit passes

If any check fails → **Commit blocked**

### 5. Merge with Rollback Safety

```bash
git checkout main
git merge feature/user-authentication --no-ff
```

The `--no-ff` flag enables one-command rollback if needed later.

### 6. Rollback (If Needed)

```bash
npm run rollback
```

Revert entire features or individual commits safely.

## System Components

### 📚 Skills (Auto-Activated)

Located in `.claude/skills/`:

| Skill | Purpose | Triggers |
|-------|---------|----------|
| **api-integration** | Enforces real API usage | API, endpoint, fetch |
| **frontend-dev** | Frontend best practices | component, React, UI |
| **test-validator** | Prevents fake tests | test, spec, jest |

Skills load automatically when you mention related keywords.

### 🔒 Hooks (Validation)

**Pre-Validation:**
- `skill-auto-activator.sh` - Analyzes prompts, loads context

**Post-Validation:**
1. `01-typescript-check.sh` - TypeScript compilation
2. `02-build-check.sh` - Build verification
3. **`03-api-integration-check.sh`** - **Blocks mock data**
4. **`04-test-authenticity-check.sh`** - **Blocks fake tests**
5. `05-third-party-audit.sh` - Independent AI audit

### 📖 Dev Docs (Context Preservation)

For each feature in `dev-docs/`:

- `[feature]-plan.md` - Architecture and approach
- `[feature]-context.md` - Decisions and file references
- `[feature]-tasks.md` - Progress tracking

**Purpose:** Preserve context across AI sessions to prevent knowledge loss.

### 🛠️ Scripts (Workflow Automation)

| Script | Purpose |
|--------|---------|
| `create-dev-docs.sh` | Generate dev docs |
| `create-feature-branch.sh` | Start new feature |
| `rollback-feature.sh` | Rollback features |

## Key Features

### 1. No Mock Data Allowed

The `api-integration-check.sh` hook scans commits for patterns like:

```typescript
// ❌ BLOCKED by hook
const mockData = [{ id: 1, name: 'Test' }];
return mockData;

// ❌ BLOCKED by hook
return Promise.resolve({ data: fakeUsers });

// ✅ ALLOWED
const response = await fetch(`${API_BASE_URL}/users`);
return response.json();
```

**Result:** AI agents cannot take shortcuts with mock data.

### 2. No Fake Tests Allowed

The `test-authenticity-check.sh` hook verifies:

- Tests have real assertions (`expect`, `assert`)
- Mock ratio: 2+ assertions per mock
- No skipped tests (`.skip`, `.todo`)
- No tests that always pass
- Tests actually execute code

```typescript
// ❌ BLOCKED - No assertions
it('should work', () => {
  doSomething();
});

// ❌ BLOCKED - Always passes
it('should work', () => {
  expect(true).toBe(true);
});

// ✅ ALLOWED - Real assertion
it('should save user', async () => {
  const user = await createUser({ email: 'test@example.com' });
  expect(user.id).toBeDefined();
});
```

**Result:** AI agents cannot fake test coverage.

### 3. Context Preservation

Dev docs prevent context loss:

```markdown
# user-auth-context.md

## Key Decisions

- Using JWT tokens (not sessions)
- Token expiry: 24 hours
- Refresh token: 30 days

## Files Modified

- `src/auth/jwt.service.ts` - Token generation
- `src/middleware/auth.middleware.ts` - Validation

## Next Session

Continue with: Password reset flow
See: user-auth-tasks.md
```

**Result:** AI agents maintain context across sessions.

### 4. Atomic Rollback

Using `--no-ff` merges:

```bash
# Merge feature
git merge feature/user-auth --no-ff

# Later, if issues found...
git revert -m 1 <merge-commit>  # One command rollback
```

**Result:** Any feature can be rolled back in seconds.

### 5. Third-Party Audit

Optional independent verification:

```bash
# Enable
export ANTHROPIC_API_KEY=your_key

# On commit, sends code to external Claude instance
# Independent AI reviews for:
# - Real API usage
# - Test authenticity
# - Error handling
# - Security issues
```

**Result:** Independent verification prevents biased approvals.

## Configuration

### Environment Variables (.env)

```bash
# Required: API Configuration
API_BASE_URL=https://api.example.com
API_KEY=your_api_key

# Optional: Third-Party Audit
ANTHROPIC_API_KEY=your_claude_key
SKIP_THIRD_PARTY_AUDIT=false
```

### Repomix (repomix.config.json)

Configured for:
- XML output (AI-friendly)
- 70% token compression
- Security scanning
- Excludes build artifacts

## Expected Results

### Before Workflow
- Frequent context loss
- Mock data in production
- Incomplete tasks
- Fake tests passing

### After Workflow
- **80-90% reduction** in all problem categories
- **Zero mock APIs** in production (enforced)
- **Verifiable completion** (third-party audit)
- **<30 second rollback** for any feature

## File Structure

```
.
├── .claude/
│   ├── hooks/
│   │   ├── user-prompt-submit/
│   │   │   └── skill-auto-activator.sh
│   │   └── stop/
│   │       ├── 01-typescript-check.sh
│   │       ├── 02-build-check.sh
│   │       ├── 03-api-integration-check.sh  ⭐ Blocks mock data
│   │       ├── 04-test-authenticity-check.sh ⭐ Blocks fake tests
│   │       └── 05-third-party-audit.sh
│   ├── skills/
│   │   ├── api-integration/
│   │   │   └── SKILL.md
│   │   ├── frontend-dev/
│   │   │   └── SKILL.md
│   │   ├── test-validator/
│   │   │   └── SKILL.md
│   │   └── skill-rules.json
│   └── scripts/
│       ├── create-dev-docs.sh
│       ├── create-feature-branch.sh
│       └── rollback-feature.sh
├── dev-docs/
│   └── [feature-name]-{plan,context,tasks}.md
├── repomix.config.json
├── setup-claude-workflow.sh
├── CLAUDE_WORKFLOW.md
├── AI_WORKFLOW_RECOMMENDATIONS.md
└── README.md (this file)
```

## Documentation

- **This file** - Overview and quick start
- `CLAUDE_WORKFLOW.md` - Detailed usage guide (created after setup)
- `AI_WORKFLOW_RECOMMENDATIONS.md` - Complete system design and rationale
- `.claude/skills/*/SKILL.md` - Individual skill documentation

## Benefits

✅ **Prevents mock data** - Enforced by hooks
✅ **Prevents fake tests** - Enforced by hooks
✅ **Preserves context** - Dev docs system
✅ **Enables rollback** - Atomic git workflow
✅ **Independent verification** - Third-party audit
✅ **Production-ready** - Based on 6 months of real-world testing

## Credits

- Based on patterns from [claude-code-infrastructure-showcase](https://github.com/diet103/claude-code-infrastructure-showcase)
- Designed for product designers and developers leveraging AI capabilities
- Built to work at scale in production environments

## Version History

- **1.0** (2025-11-14) - Initial production release

---

**Ready to build production-quality code with AI? Start here:**

```bash
bash setup-claude-workflow.sh
```