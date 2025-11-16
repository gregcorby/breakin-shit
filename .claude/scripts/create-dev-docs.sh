#!/bin/bash

# Dev Docs Creation Script
# Creates the three-file dev docs structure for context preservation
# Usage: ./create-dev-docs.sh [feature-name]

FEATURE_NAME="$1"

if [[ -z "$FEATURE_NAME" ]]; then
    echo "Usage: ./create-dev-docs.sh [feature-name]"
    echo ""
    echo "Example: ./create-dev-docs.sh user-authentication"
    exit 1
fi

# Create dev-docs directory if it doesn't exist
mkdir -p dev-docs

# Sanitize feature name (lowercase, replace spaces with hyphens)
FEATURE_NAME=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

PLAN_FILE="dev-docs/${FEATURE_NAME}-plan.md"
CONTEXT_FILE="dev-docs/${FEATURE_NAME}-context.md"
TASKS_FILE="dev-docs/${FEATURE_NAME}-tasks.md"

echo "📚 Creating dev docs for feature: $FEATURE_NAME"
echo ""

# Create plan file
if [[ ! -f "$PLAN_FILE" ]]; then
    cat > "$PLAN_FILE" <<EOF
# ${FEATURE_NAME^} - Plan

**Created:** $(date +%Y-%m-%d)
**Status:** Planning

## Objective

[Describe what this feature does and why it's needed]

## Approach

### 1. Architecture
[Describe the architectural approach]

### 2. Components/Modules
[List main components or modules to be created/modified]

### 3. Data Flow
[Describe how data flows through the system]

### 4. API Integration
[List API endpoints that will be used - MUST be real APIs, no mocks]

- GET /api/...
- POST /api/...

### 5. Testing Strategy
[Describe how this will be tested]

- Unit tests: [what will be tested]
- Integration tests: [what will be tested]
- E2E tests: [if applicable]

## Dependencies

- [List external dependencies or prerequisites]

## Risks & Mitigations

- **Risk:** [potential issue]
  - **Mitigation:** [how to address it]

## Success Criteria

- [ ] Feature works as expected
- [ ] All tests pass
- [ ] No mock data in production code
- [ ] Error handling implemented
- [ ] Accessible (WCAG 2.1 AA)
- [ ] Responsive design
- [ ] Performance benchmarks met

---

**Next Steps:**
1. Review this plan
2. Update ${CONTEXT_FILE} with decisions
3. Break down into tasks in ${TASKS_FILE}
EOF

    echo "✅ Created: $PLAN_FILE"
else
    echo "ℹ️  Already exists: $PLAN_FILE"
fi

# Create context file
if [[ ! -f "$CONTEXT_FILE" ]]; then
    cat > "$CONTEXT_FILE" <<EOF
# ${FEATURE_NAME^} - Context

**Last Updated:** $(date +%Y-%m-%d)

## Key Decisions

### Decision Log

| Date | Decision | Rationale | Impact |
|------|----------|-----------|--------|
| $(date +%Y-%m-%d) | [Decision] | [Why] | [Files affected] |

## File References

### Created Files
- \`path/to/file.ts\` - [Purpose]

### Modified Files
- \`path/to/file.ts\` - [What changed and why]

## API Endpoints Used

> ⚠️ All endpoints must be REAL - no mock data

| Endpoint | Method | Purpose | Auth Required |
|----------|--------|---------|---------------|
| /api/... | GET | [Purpose] | Yes/No |

## Environment Variables

| Variable | Purpose | Example Value |
|----------|---------|---------------|
| API_BASE_URL | Base URL for API | https://api.example.com |

## Technical Notes

### Challenges Encountered
- [Challenge]: [How it was resolved]

### Learnings
- [What was learned during implementation]

### Performance Considerations
- [Any performance optimizations or concerns]

## Context for Next Session

If you're resuming work on this feature:

1. **Current State:** [Where things stand]
2. **Next Task:** [What to work on next - see ${TASKS_FILE}]
3. **Blockers:** [Any blockers or dependencies]
4. **Important Context:** [Anything critical to know]

---

**Related Files:**
- Plan: ${PLAN_FILE}
- Tasks: ${TASKS_FILE}
EOF

    echo "✅ Created: $CONTEXT_FILE"
else
    echo "ℹ️  Already exists: $CONTEXT_FILE"
fi

# Create tasks file
if [[ ! -f "$TASKS_FILE" ]]; then
    cat > "$TASKS_FILE" <<EOF
# ${FEATURE_NAME^} - Tasks

**Last Updated:** $(date +%Y-%m-%d)

## Task Checklist

### Phase 1: Setup
- [ ] Create feature branch: \`feature/${FEATURE_NAME}\`
- [ ] Set up environment variables
- [ ] Review API documentation
- [ ] Create initial file structure

### Phase 2: Implementation
- [ ] Implement core functionality
- [ ] Add error handling
- [ ] Add loading states
- [ ] Add empty states
- [ ] Validate with real API (no mocks)

### Phase 3: Testing
- [ ] Write unit tests (with real assertions)
- [ ] Write integration tests (with real API calls)
- [ ] Test error scenarios
- [ ] Test edge cases
- [ ] Verify accessibility (WCAG 2.1 AA)
- [ ] Test responsive design (mobile, tablet, desktop)

### Phase 4: Quality Assurance
- [ ] TypeScript compilation passes
- [ ] Build succeeds
- [ ] All tests pass
- [ ] No mock data in production code
- [ ] Code review completed
- [ ] Third-party audit passed

### Phase 5: Deployment
- [ ] Merge to main with \`--no-ff\`
- [ ] Verify in staging environment
- [ ] Update documentation
- [ ] Mark feature as complete

## Detailed Tasks

### Task: [Task Name]
**Status:** 🔴 Not Started | 🟡 In Progress | 🟢 Complete

**Description:** [What needs to be done]

**Files Involved:**
- \`path/to/file.ts\`

**Acceptance Criteria:**
- [ ] [Criterion 1]
- [ ] [Criterion 2]

**Notes:**
- [Any important notes]

---

## Blocked Tasks

| Task | Blocked By | Status |
|------|-----------|--------|
| [Task] | [Blocker] | [Status] |

## Completed Tasks

| Task | Completed Date | Notes |
|------|---------------|-------|
| [Task] | $(date +%Y-%m-%d) | [Notes] |

---

**Related Files:**
- Plan: ${PLAN_FILE}
- Context: ${CONTEXT_FILE}
EOF

    echo "✅ Created: $TASKS_FILE"
else
    echo "ℹ️  Already exists: $TASKS_FILE"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Dev docs created for: $FEATURE_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Files:"
echo "  📋 $PLAN_FILE"
echo "  📖 $CONTEXT_FILE"
echo "  ✅ $TASKS_FILE"
echo ""
echo "Next steps:"
echo "  1. Edit the plan file to describe your approach"
echo "  2. Use the context file to track decisions and file changes"
echo "  3. Use the tasks file to track progress"
echo ""
echo "These files preserve context across sessions and prevent knowledge loss."
echo ""
