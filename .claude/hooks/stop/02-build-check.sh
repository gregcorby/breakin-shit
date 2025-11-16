#!/bin/bash

# Build Verification Hook
# Ensures the project builds successfully
# Prevents commits with broken builds

echo "🏗️  Running build verification..."

# Check if package.json exists
if [[ ! -f "package.json" ]]; then
    echo "ℹ️  No package.json found. Skipping build check."
    exit 0
fi

# Check if build script exists
if ! jq -e '.scripts.build' package.json > /dev/null 2>&1; then
    echo "ℹ️  No build script found. Skipping build check."
    exit 0
fi

# Run build
echo "Building project..."
if npm run build 2>&1 | tee /tmp/build-output.txt; then
    echo ""
    echo "✅ Build completed successfully"

    # Verify build artifacts exist
    if [[ -d "dist" ]]; then
        file_count=$(find dist -type f | wc -l)
        echo "   Generated $file_count file(s) in dist/"
    elif [[ -d "build" ]]; then
        file_count=$(find build -type f | wc -l)
        echo "   Generated $file_count file(s) in build/"
    elif [[ -d "out" ]]; then
        file_count=$(find out -type f | wc -l)
        echo "   Generated $file_count file(s) in out/"
    fi

    exit 0
else
    echo ""
    echo "❌ Build FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Build errors:"
    tail -50 /tmp/build-output.txt
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚫 BLOCKING: Build must succeed before commit"
    echo ""
    echo "Common fixes:"
    echo "  • Check for missing dependencies (npm install)"
    echo "  • Verify all imports are correct"
    echo "  • Fix syntax errors"
    echo "  • Check build configuration files"
    echo ""
    exit 1
fi
