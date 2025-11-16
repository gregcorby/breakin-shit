#!/bin/bash

# TypeScript Compilation Check Hook
# Ensures all TypeScript code compiles without errors
# Prevents commits with type errors

echo "🔍 Running TypeScript compilation check..."

# Check if this is a TypeScript project
if [[ ! -f "tsconfig.json" ]] && [[ ! -f "package.json" ]]; then
    echo "ℹ️  Not a TypeScript project. Skipping."
    exit 0
fi

# Check if TypeScript is installed
if ! command -v npx &> /dev/null; then
    echo "⚠️  npx not found. Skipping TypeScript check."
    exit 0
fi

# Run TypeScript compiler in check mode (no emit)
if npx tsc --noEmit 2>&1 | tee /tmp/tsc-output.txt; then
    echo "✅ TypeScript compilation passed"
    exit 0
else
    echo ""
    echo "❌ TypeScript compilation FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Type errors detected:"
    cat /tmp/tsc-output.txt
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚫 BLOCKING: You must fix type errors before proceeding"
    echo ""
    echo "Common fixes:"
    echo "  • Add type annotations to function parameters"
    echo "  • Remove usage of 'any' types"
    echo "  • Ensure imports are correct"
    echo "  • Check for typos in property names"
    echo ""
    exit 1
fi
