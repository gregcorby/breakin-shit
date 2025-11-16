#!/bin/bash

# Third-Party Audit Hook
# Uses Repomix to package changes and sends to external LLM for independent verification
# This prevents agents from claiming work is complete when it's not

echo "🔍 Starting third-party audit..."

# Check if audit is enabled
if [[ "$SKIP_THIRD_PARTY_AUDIT" == "true" ]]; then
    echo "ℹ️  Third-party audit skipped (SKIP_THIRD_PARTY_AUDIT=true)"
    exit 0
fi

# Check if Anthropic API key is configured
if [[ -z "$ANTHROPIC_API_KEY" ]]; then
    echo "⚠️  ANTHROPIC_API_KEY not set. Skipping third-party audit."
    echo "   To enable audit: export ANTHROPIC_API_KEY=your_key"
    echo "   To disable this warning: export SKIP_THIRD_PARTY_AUDIT=true"
    exit 0
fi

# Check if repomix is installed
if ! command -v repomix &> /dev/null; then
    echo "⚠️  Repomix not installed. Installing..."
    npm install -g repomix || {
        echo "❌ Failed to install repomix. Skipping audit."
        echo "   Install manually: npm install -g repomix"
        exit 0
    }
fi

# Get list of changed files
if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)
else
    echo "ℹ️  Not a git repository. Skipping audit."
    exit 0
fi

if [[ -z "$CHANGED_FILES" ]]; then
    echo "ℹ️  No changes to audit."
    exit 0
fi

# Create temporary directory for audit
AUDIT_DIR="/tmp/claude-audit-$$"
mkdir -p "$AUDIT_DIR"

# Generate Repomix snapshot of changed files
echo "📸 Creating code snapshot..."

# Create file list for repomix
echo "$CHANGED_FILES" > "$AUDIT_DIR/files.txt"

# Generate snapshot
repomix \
    --output "$AUDIT_DIR/snapshot.xml" \
    --style xml \
    --include "$(echo "$CHANGED_FILES" | tr '\n' ',' | sed 's/,$//')" \
    2>/dev/null || {
        echo "⚠️  Failed to generate snapshot. Skipping audit."
        rm -rf "$AUDIT_DIR"
        exit 0
    }

# Create audit prompt
cat > "$AUDIT_DIR/audit-prompt.txt" <<'EOF'
You are an independent code auditor. Your job is to verify that code changes are genuine and complete.

Review the following code changes and check for:

1. ✅ **Real API Integration**
   - Are real API endpoints being called?
   - Or is it using mock/fake data?
   - Are environment variables used for configuration?

2. ✅ **Test Authenticity**
   - Do tests have real assertions?
   - Are tests actually testing behavior (not just mocks)?
   - Is there proper cleanup code?

3. ✅ **Error Handling**
   - Are API calls wrapped in try/catch?
   - Are error states handled in UI?
   - Are errors logged properly?

4. ✅ **Type Safety**
   - Are types properly defined (no 'any')?
   - Are null/undefined cases handled?

5. ✅ **Security**
   - No hardcoded secrets or API keys?
   - No SQL injection vulnerabilities?
   - No XSS vulnerabilities?

6. ✅ **Completeness**
   - No TODO comments that block functionality?
   - No placeholder implementations?
   - All functions have real implementations?

Respond ONLY with:

**PASS** - If all criteria are met

OR

**FAIL** - Followed by specific issues found:
- [Issue 1]
- [Issue 2]
- [etc]

Be strict. If you see mock data, fake tests, or incomplete implementations, you MUST fail the audit.

Code snapshot:
EOF

# Append snapshot to prompt
cat "$AUDIT_DIR/snapshot.xml" >> "$AUDIT_DIR/audit-prompt.txt"

# Send to Claude API for audit
echo "🤖 Requesting independent audit..."

AUDIT_RESULT=$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "{
        \"model\": \"claude-3-5-sonnet-20241022\",
        \"max_tokens\": 2048,
        \"messages\": [{
            \"role\": \"user\",
            \"content\": $(cat "$AUDIT_DIR/audit-prompt.txt" | jq -Rs .)
        }]
    }" 2>/dev/null)

# Parse response
if [[ -z "$AUDIT_RESULT" ]]; then
    echo "⚠️  API request failed. Skipping audit."
    rm -rf "$AUDIT_DIR"
    exit 0
fi

# Extract audit result
AUDIT_TEXT=$(echo "$AUDIT_RESULT" | jq -r '.content[0].text' 2>/dev/null)

if [[ -z "$AUDIT_TEXT" ]]; then
    echo "⚠️  Failed to parse audit result. Skipping."
    rm -rf "$AUDIT_DIR"
    exit 0
fi

# Save audit result
echo "$AUDIT_TEXT" > "$AUDIT_DIR/audit-result.txt"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Third-Party Audit Result:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "$AUDIT_TEXT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if audit passed
if echo "$AUDIT_TEXT" | grep -qi "^PASS"; then
    echo "✅ Third-party audit PASSED"
    rm -rf "$AUDIT_DIR"
    exit 0
else
    echo "❌ Third-party audit FAILED"
    echo ""
    echo "An independent AI auditor has reviewed your code and found issues."
    echo "You must address these concerns before committing."
    echo ""
    echo "Audit details saved to: $AUDIT_DIR/audit-result.txt"
    echo ""
    echo "To bypass this check (NOT RECOMMENDED):"
    echo "  export SKIP_THIRD_PARTY_AUDIT=true"
    echo ""
    exit 1
fi
