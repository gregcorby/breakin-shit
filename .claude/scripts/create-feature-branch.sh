#!/bin/bash

# Feature Branch Creation Script
# Creates a new feature branch and initializes dev docs
# Implements atomic commit workflow

FEATURE_NAME="$1"

if [[ -z "$FEATURE_NAME" ]]; then
    echo "Usage: ./create-feature-branch.sh [feature-name]"
    echo ""
    echo "Example: ./create-feature-branch.sh user-authentication"
    exit 1
fi

# Sanitize feature name
FEATURE_NAME=$(echo "$FEATURE_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
BRANCH_NAME="feature/${FEATURE_NAME}"

echo "🌿 Creating feature branch: $BRANCH_NAME"
echo ""

# Check if in git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Not in a git repository"
    exit 1
fi

# Check if branch already exists
if git rev-parse --verify "$BRANCH_NAME" > /dev/null 2>&1; then
    echo "⚠️  Branch already exists: $BRANCH_NAME"
    echo ""
    read -p "Switch to existing branch? (y/n) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        git checkout "$BRANCH_NAME"
    fi
    exit 0
fi

# Create and switch to new branch
git checkout -b "$BRANCH_NAME"

if [[ $? -ne 0 ]]; then
    echo "❌ Failed to create branch"
    exit 1
fi

echo "✅ Created and switched to: $BRANCH_NAME"
echo ""

# Create dev docs
echo "📚 Setting up dev docs..."
bash .claude/scripts/create-dev-docs.sh "$FEATURE_NAME"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Feature branch ready: $BRANCH_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Workflow:"
echo "  1. Work on your feature in atomic commits"
echo "  2. Update dev docs as you make decisions"
echo "  3. Each commit will be validated by hooks"
echo "  4. When complete, merge with: git merge --no-ff"
echo ""
echo "Rollback safety:"
echo "  - Each atomic commit can be reverted individually"
echo "  - Entire feature can be rolled back after merge"
echo ""
echo "Start coding! 🚀"
echo ""
