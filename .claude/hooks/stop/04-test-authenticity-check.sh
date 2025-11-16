#!/bin/bash

# Test Authenticity Verification Hook
# Prevents fake tests that don't actually validate behavior
# Ensures tests have real assertions and aren't just mocks

echo "🧪 Verifying test authenticity..."

# Get list of changed test files
if command -v git &> /dev/null && git rev-parse --git-dir > /dev/null 2>&1; then
    TEST_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(test|spec)\.(ts|tsx|js|jsx)$')
else
    echo "ℹ️  Not a git repository. Skipping test check."
    exit 0
fi

if [[ -z "$TEST_FILES" ]]; then
    echo "ℹ️  No test files changed."
    exit 0
fi

violations=()
warnings=()
test_count=0

echo "Analyzing test files..."

for file in $TEST_FILES; do
    if [[ ! -f "$file" ]]; then
        continue
    fi

    file_content=$(git show :"$file" 2>/dev/null)

    if [[ -z "$file_content" ]]; then
        continue
    fi

    ((test_count++))

    # Check 1: Test file must have assertions
    assertion_patterns=(
        "expect\("
        "assert\("
        "should\."
        "toBe\("
        "toEqual\("
        "toHaveBeenCalled"
    )

    has_assertions=false
    assertion_count=0
    for pattern in "${assertion_patterns[@]}"; do
        count=$(echo "$file_content" | grep -cE "$pattern" || true)
        if [[ $count -gt 0 ]]; then
            has_assertions=true
            assertion_count=$((assertion_count + count))
        fi
    done

    if [[ "$has_assertions" == false ]]; then
        violations+=("$file: No assertions found - test doesn't validate anything")
        continue
    fi

    # Check 2: Count mocks vs assertions (mock ratio check)
    mock_patterns=(
        "jest\.fn\(\)"
        "jest\.mock\("
        "vi\.fn\(\)"
        "vi\.mock\("
        "\.mockReturnValue"
        "\.mockResolvedValue"
        "\.mockRejectedValue"
    )

    mock_count=0
    for pattern in "${mock_patterns[@]}"; do
        count=$(echo "$file_content" | grep -cE "$pattern" || true)
        mock_count=$((mock_count + count))
    done

    # Rule: Should have at least 2 assertions per mock
    if [[ $mock_count -gt 0 ]]; then
        required_assertions=$((mock_count * 2))
        if [[ $assertion_count -lt $required_assertions ]]; then
            warnings+=("$file: $mock_count mocks but only $assertion_count assertions (need $required_assertions+)")
        fi
    fi

    # Check 3: No skipped tests
    if echo "$file_content" | grep -qE "(it\.skip|test\.skip|describe\.skip|xit|xtest|xdescribe)"; then
        violations+=("$file: Contains skipped tests - cannot commit with .skip()")
    fi

    # Check 4: No TODO tests without implementation
    if echo "$file_content" | grep -qE "(it\.todo|test\.todo)"; then
        violations+=("$file: Contains TODO tests - implement or remove before commit")
    fi

    # Check 5: No tests that always pass
    always_pass_patterns=(
        "expect\(true\)\.toBe\(true\)"
        "expect\(1\)\.toBe\(1\)"
        "expect\(false\)\.toBe\(false\)"
    )

    for pattern in "${always_pass_patterns[@]}"; do
        if echo "$file_content" | grep -qE "$pattern"; then
            violations+=("$file: Contains test that always passes - not validating real behavior")
        fi
    done

    # Check 6: Warn if test has no cleanup (beforeEach/afterEach)
    if echo "$file_content" | grep -qE "(database|db|api|server)"; then
        if ! echo "$file_content" | grep -qE "(afterEach|afterAll|cleanup)"; then
            warnings+=("$file: Database/API test without cleanup - may pollute test state")
        fi
    fi

    # Check 7: Integration tests should use real APIs
    if echo "$file_content" | grep -qE "(integration|e2e)" || [[ "$file" =~ integration|e2e ]]; then
        # Integration tests should NOT mock the API layer
        if echo "$file_content" | grep -qE "jest\.mock.*['\"].*/(api|services|client)"; then
            violations+=("$file: Integration test mocking API layer - should use real API calls")
        fi
    fi

    # Check 8: Tests should actually run code under test
    if ! echo "$file_content" | grep -qE "(await|\.then\(|expect\()"; then
        violations+=("$file: Test doesn't appear to execute code under test")
    fi
done

# Run tests if test script exists
if [[ -f "package.json" ]] && jq -e '.scripts.test' package.json > /dev/null 2>&1; then
    echo ""
    echo "Running tests..."

    # Run tests with coverage
    if npm run test -- --passWithNoTests=false --coverage 2>&1 | tee /tmp/test-output.txt; then
        echo "✅ All tests passed"

        # Check coverage if available
        if [[ -f "coverage/coverage-summary.json" ]]; then
            line_coverage=$(jq '.total.lines.pct' coverage/coverage-summary.json 2>/dev/null || echo "0")
            branch_coverage=$(jq '.total.branches.pct' coverage/coverage-summary.json 2>/dev/null || echo "0")

            echo "   Line coverage: ${line_coverage}%"
            echo "   Branch coverage: ${branch_coverage}%"

            # Warn if coverage is too low
            if (( $(echo "$line_coverage < 80" | bc -l) )); then
                warnings+=("Test coverage below 80% (current: ${line_coverage}%)")
            fi
        fi
    else
        echo ""
        echo "❌ TESTS FAILED"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        tail -100 /tmp/test-output.txt
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🚫 BLOCKING: All tests must pass before commit"
        echo ""
        exit 1
    fi
fi

# Report warnings
if [[ ${#warnings[@]} -gt 0 ]]; then
    echo ""
    echo "⚠️  TEST WARNINGS:"
    for warning in "${warnings[@]}"; do
        echo "   $warning"
    done
    echo ""
fi

# Report violations
if [[ ${#violations[@]} -gt 0 ]]; then
    echo ""
    echo "❌ TEST AUTHENTICITY VIOLATIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    for violation in "${violations[@]}"; do
        echo "🚫 $violation"
    done
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "FAKE TESTS ARE NOT ALLOWED"
    echo ""
    echo "Tests must:"
    echo "  ✅ Have real assertions (expect/assert)"
    echo "  ✅ Test actual behavior, not just mocks"
    echo "  ✅ Have cleanup code (afterEach/afterAll)"
    echo "  ✅ Not be skipped (.skip) or TODO"
    echo "  ✅ Execute the code under test"
    echo ""
    echo "Example of REAL test:"
    echo ""
    echo "  it('should save user to database', async () => {"
    echo "    const user = await createUser({ email: 'test@example.com' })"
    echo ""
    echo "    // Real assertion"
    echo "    expect(user.id).toBeDefined()"
    echo ""
    echo "    // Verify in actual database"
    echo "    const saved = await db.users.findById(user.id)"
    echo "    expect(saved.email).toBe('test@example.com')"
    echo ""
    echo "    // Cleanup"
    echo "    await db.users.delete(user.id)"
    echo "  })"
    echo ""
    exit 1
fi

echo "✅ Test authenticity verified"
echo "   Analyzed $test_count test file(s)"
exit 0
