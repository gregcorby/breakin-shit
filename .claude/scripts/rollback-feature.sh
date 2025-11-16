#!/bin/bash

# Feature Rollback Script
# Safely rolls back a feature using atomic git operations
# Works with --no-ff merges to revert entire features

echo "🔄 Feature Rollback Utility"
echo ""

# Check if in git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo "❌ Not in a git repository"
    exit 1
fi

# Show recent merges
echo "Recent feature merges:"
echo ""
git log --oneline --merges -10 --pretty=format:"%h - %s (%cr)"
echo ""
echo ""

# Get commit to rollback
read -p "Enter merge commit hash to rollback: " COMMIT_HASH

if [[ -z "$COMMIT_HASH" ]]; then
    echo "❌ No commit hash provided"
    exit 1
fi

# Verify it's a merge commit
if ! git rev-parse "$COMMIT_HASH^2" > /dev/null 2>&1; then
    echo "⚠️  Warning: This doesn't appear to be a merge commit"
    echo "   Regular commits should be reverted differently"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi

    # Regular commit revert
    echo "Reverting single commit: $COMMIT_HASH"
    git revert "$COMMIT_HASH"
    exit $?
fi

# Show what will be rolled back
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Merge commit details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
git show --stat "$COMMIT_HASH"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Show files that will be affected
echo "Files that will be reverted:"
git show --pretty="" --name-only "$COMMIT_HASH"
echo ""

# Confirm rollback
read -p "⚠️  Rollback this feature merge? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Rollback cancelled"
    exit 0
fi

# Perform rollback
echo ""
echo "Rolling back feature merge..."
echo ""

# Revert merge commit (keeping mainline)
git revert -m 1 "$COMMIT_HASH"

if [[ $? -eq 0 ]]; then
    echo ""
    echo "✅ Feature successfully rolled back"
    echo ""
    echo "A new commit has been created that undoes the merge."
    echo ""
    echo "Next steps:"
    echo "  1. Review changes: git show HEAD"
    echo "  2. Run tests to verify rollback didn't break anything"
    echo "  3. Push if on shared branch: git push"
    echo ""
    echo "To re-apply the feature later:"
    echo "  1. Revert the revert: git revert HEAD"
    echo "  2. Or merge the feature branch again"
    echo ""
else
    echo ""
    echo "❌ Rollback failed"
    echo ""
    echo "Possible reasons:"
    echo "  - Conflicts with subsequent changes"
    echo "  - Invalid commit hash"
    echo ""
    echo "Manual rollback options:"
    echo "  1. git revert -m 1 $COMMIT_HASH (try again)"
    echo "  2. git reset --hard $COMMIT_HASH^ (destructive!)"
    echo "  3. Create new branch from before merge"
    echo ""
    exit 1
fi
