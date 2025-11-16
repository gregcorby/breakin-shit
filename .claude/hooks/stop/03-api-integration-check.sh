#!/bin/bash

# API Integration Verification Hook
# Prevents commits with mock data instead of real API integrations
# This is a critical check to prevent the "mock data" problem

echo "🌐 Verifying real API integration (no mocks allowed)..."

# Get list of changed files in git staging area
if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    CHANGED_FILES=$(git diff --cached --name-only --diff-filter=ACM)
else
    echo "ℹ️  Not a git repository. Skipping API integration check."
    exit 0
fi

if [[ -z "$CHANGED_FILES" ]]; then
    echo "ℹ️  No files to check."
    exit 0
fi

# Patterns that indicate mock data (bad)
MOCK_PATTERNS=(
    "mockData"
    "MOCK_API"
    "FAKE_API"
    "const.*=.*\[.*{.*id:.*1"  # Common pattern: const data = [{ id: 1, ... }]
    "Promise\.resolve\(\{.*data:"  # Fake async: Promise.resolve({ data: ... })
    "return.*\[.*{.*id.*:.*[0-9].*name.*:.*['\"]"  # return [{ id: 1, name: 'Test' }]
)

# Patterns that indicate real API usage (good)
REAL_API_PATTERNS=(
    "fetch\("
    "axios\."
    "http\."
    "API_BASE_URL"
    "process\.env\..*API"
)

violations=()
warnings=()

echo "Checking ${CHANGED_FILES[@]}" | wc -w | xargs -I {} echo "Analyzing {} file(s)..."

for file in $CHANGED_FILES; do
    # Skip non-code files
    if [[ ! "$file" =~ \.(ts|tsx|js|jsx)$ ]]; then
        continue
    fi

    # Skip test files for mock pattern check (mocks allowed in tests)
    if [[ "$file" =~ \.(test|spec)\.(ts|tsx|js|jsx)$ ]]; then
        continue
    fi

    # Skip if file doesn't exist (deleted file)
    if [[ ! -f "$file" ]]; then
        continue
    fi

    # Get the staged content
    file_content=$(git show :"$file" 2>/dev/null)

    if [[ -z "$file_content" ]]; then
        continue
    fi

    # Check for mock patterns
    for pattern in "${MOCK_PATTERNS[@]}"; do
        if echo "$file_content" | grep -qE "$pattern"; then
            # Check if there's also real API usage
            has_real_api=false
            for api_pattern in "${REAL_API_PATTERNS[@]}"; do
                if echo "$file_content" | grep -qE "$api_pattern"; then
                    has_real_api=true
                    break
                fi
            done

            if [[ "$has_real_api" == false ]]; then
                violations+=("$file: Contains mock data pattern '$pattern' without real API integration")
            else
                warnings+=("$file: Contains mock pattern '$pattern' but also has real API - verify correct usage")
            fi
        fi
    done

    # Check for hardcoded API URLs (should use environment variables)
    if echo "$file_content" | grep -qE "https?://[^'\"]*(api|backend)"; then
        if ! echo "$file_content" | grep -qE "process\.env"; then
            violations+=("$file: Contains hardcoded API URL - use environment variables")
        fi
    fi

    # Check for missing error handling on API calls
    if echo "$file_content" | grep -qE "(fetch\(|axios\.)"; then
        if ! echo "$file_content" | grep -qE "(catch\(|try.*catch|\.catch)"; then
            warnings+=("$file: API calls found without error handling")
        fi
    fi
done

# Report warnings
if [[ ${#warnings[@]} -gt 0 ]]; then
    echo ""
    echo "⚠️  WARNINGS:"
    for warning in "${warnings[@]}"; do
        echo "   $warning"
    done
fi

# Report violations
if [[ ${#violations[@]} -gt 0 ]]; then
    echo ""
    echo "❌ API INTEGRATION VIOLATIONS DETECTED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    for violation in "${violations[@]}"; do
        echo "🚫 $violation"
    done
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "MOCK DATA IS NOT ALLOWED IN PRODUCTION CODE"
    echo ""
    echo "You must use real API integrations:"
    echo ""
    echo "  ✅ CORRECT:"
    echo "     const response = await fetch(\`\${API_BASE_URL}/users\`)"
    echo ""
    echo "  ❌ WRONG:"
    echo "     const data = [{ id: 1, name: 'Mock User' }]"
    echo ""
    echo "  ❌ WRONG:"
    echo "     return Promise.resolve({ data: mockData })"
    echo ""
    echo "If you need to use mock data for development:"
    echo "  1. Use environment-based feature flags"
    echo "  2. Keep mock data in separate .mock.ts files"
    echo "  3. Ensure real API integration exists alongside"
    echo ""
    exit 1
fi

echo "✅ API integration verified - no mock data detected"
exit 0
