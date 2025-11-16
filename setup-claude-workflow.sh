#!/bin/bash

# Claude Workflow Setup Script
# Installs and configures the complete AI-assisted development workflow
# Author: Claude
# Version: 1.0

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Claude AI Workflow Setup"
echo "  Production-Ready System for AI Development"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if in git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    print_error "Not in a git repository. Initialize git first:"
    echo "  git init"
    exit 1
fi

print_success "Git repository detected"

# Step 1: Make all hooks executable
echo ""
print_info "Making hooks executable..."

chmod +x .claude/hooks/user-prompt-submit/*.sh
chmod +x .claude/hooks/stop/*.sh
chmod +x .claude/scripts/*.sh

print_success "Hooks are now executable"

# Step 2: Install dependencies
echo ""
print_info "Checking dependencies..."

# Check for Node.js
if ! command -v node &> /dev/null; then
    print_warning "Node.js not found. Please install Node.js first."
    echo "  Visit: https://nodejs.org"
else
    print_success "Node.js found: $(node --version)"
fi

# Check for npm
if ! command -v npm &> /dev/null; then
    print_warning "npm not found. Please install npm first."
else
    print_success "npm found: $(npm --version)"
fi

# Check for jq (needed for JSON parsing in hooks)
if ! command -v jq &> /dev/null; then
    print_warning "jq not found. Installing..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install jq
            print_success "jq installed via Homebrew"
        else
            print_error "Homebrew not found. Install jq manually: brew install jq"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y jq
            print_success "jq installed via apt-get"
        elif command -v yum &> /dev/null; then
            sudo yum install -y jq
            print_success "jq installed via yum"
        else
            print_error "Package manager not found. Install jq manually."
        fi
    else
        print_warning "Please install jq manually for your OS"
    fi
else
    print_success "jq found: $(jq --version)"
fi

# Step 3: Install Repomix
echo ""
print_info "Installing Repomix..."

if command -v repomix &> /dev/null; then
    print_success "Repomix already installed: $(repomix --version)"
else
    if command -v npm &> /dev/null; then
        npm install -g repomix
        print_success "Repomix installed"
    else
        print_warning "Cannot install Repomix - npm not available"
    fi
fi

# Step 4: Configure environment
echo ""
print_info "Configuring environment..."

if [[ ! -f ".env" ]]; then
    cat > .env <<EOF
# API Configuration
API_BASE_URL=https://api.example.com
# API_KEY=your_api_key_here

# Third-Party Audit (Optional)
# ANTHROPIC_API_KEY=your_anthropic_key_here
# SKIP_THIRD_PARTY_AUDIT=false

# Development
NODE_ENV=development
EOF
    print_success "Created .env file (configure your API settings)"
else
    print_info ".env file already exists"
fi

# Add .env to .gitignore if not already there
if [[ ! -f ".gitignore" ]]; then
    echo ".env" > .gitignore
    print_success "Created .gitignore with .env"
elif ! grep -q "^\.env$" .gitignore; then
    echo ".env" >> .gitignore
    print_success "Added .env to .gitignore"
else
    print_info ".env already in .gitignore"
fi

# Step 5: Create initial dev-docs directory
echo ""
print_info "Setting up dev-docs directory..."

mkdir -p dev-docs
cat > dev-docs/README.md <<EOF
# Development Documentation

This directory contains context-preserving documentation for all features.

## Structure

For each feature, there are three files:

- \`[feature]-plan.md\` - Strategic approach and architecture
- \`[feature]-context.md\` - Key decisions and file references
- \`[feature]-tasks.md\` - Task checklist and progress tracking

## Creating Dev Docs

\`\`\`bash
bash .claude/scripts/create-dev-docs.sh [feature-name]
\`\`\`

## Purpose

These docs prevent context loss across AI agent sessions by:
- Preserving architectural decisions
- Tracking file changes and reasons
- Maintaining task progress
- Providing recovery context for new sessions

## Best Practices

1. Update context.md whenever you make a key decision
2. Check off tasks in tasks.md as you complete them
3. Start each session by reading relevant dev docs
4. Keep docs concise but complete
EOF

print_success "Dev docs directory created"

# Step 6: Create package.json scripts if they don't exist
echo ""
print_info "Setting up npm scripts..."

if [[ -f "package.json" ]]; then
    # Add helper scripts
    if ! jq -e '.scripts["dev-docs"]' package.json > /dev/null 2>&1; then
        jq '.scripts["dev-docs"] = "bash .claude/scripts/create-dev-docs.sh"' package.json > package.json.tmp
        mv package.json.tmp package.json
        print_success "Added 'dev-docs' script"
    fi

    if ! jq -e '.scripts["feature"]' package.json > /dev/null 2>&1; then
        jq '.scripts["feature"] = "bash .claude/scripts/create-feature-branch.sh"' package.json > package.json.tmp
        mv package.json.tmp package.json
        print_success "Added 'feature' script"
    fi

    if ! jq -e '.scripts["rollback"]' package.json > /dev/null 2>&1; then
        jq '.scripts["rollback"] = "bash .claude/scripts/rollback-feature.sh"' package.json > package.json.tmp
        mv package.json.tmp package.json
        print_success "Added 'rollback' script"
    fi
else
    print_warning "No package.json found - skipping npm scripts setup"
fi

# Step 7: Create README
echo ""
print_info "Creating workflow documentation..."

if [[ ! -f "CLAUDE_WORKFLOW.md" ]]; then
    cat > CLAUDE_WORKFLOW.md <<'EOF'
# Claude AI Workflow Guide

This project uses a production-ready AI-assisted development workflow.

## Quick Start

### 1. Start a New Feature

```bash
npm run feature user-authentication
# or
bash .claude/scripts/create-feature-branch.sh user-authentication
```

This creates:
- Feature branch: `feature/user-authentication`
- Dev docs for context preservation
- Atomic commit workflow setup

### 2. Develop with AI

As you work, the system automatically:
- ✅ Activates relevant skills based on your prompts
- ✅ Loads context from dev docs
- ✅ Validates API configuration

### 3. Commit Changes

When you commit, hooks automatically verify:
- ✅ TypeScript compiles without errors
- ✅ Build succeeds
- ✅ No mock data in production code
- ✅ Tests have real assertions
- ✅ Third-party audit passes (if enabled)

If any check fails, your commit is blocked.

### 4. Rollback if Needed

```bash
npm run rollback
# or
bash .claude/scripts/rollback-feature.sh
```

Safely revert entire features or individual commits.

## System Components

### Skills (Auto-Activated)

Located in `.claude/skills/`:

- **api-integration** - Enforces real API usage, prevents mock data
- **frontend-dev** - Frontend best practices, accessibility, responsive design
- **test-validator** - Ensures tests have real assertions, prevents fake tests

Skills activate automatically based on your prompts.

### Hooks (Validation)

**Pre-validation:**
- `user-prompt-submit/skill-auto-activator.sh` - Loads relevant context

**Post-validation:**
- `stop/01-typescript-check.sh` - TypeScript compilation
- `stop/02-build-check.sh` - Build verification
- `stop/03-api-integration-check.sh` - **Prevents mock data**
- `stop/04-test-authenticity-check.sh` - **Prevents fake tests**
- `stop/05-third-party-audit.sh` - Independent AI audit (optional)

### Dev Docs (Context Preservation)

Located in `dev-docs/`:

Prevents context loss across sessions:
- `[feature]-plan.md` - Architecture and approach
- `[feature]-context.md` - Decisions and file references
- `[feature]-tasks.md` - Progress tracking

### Scripts (Workflow Automation)

- `create-dev-docs.sh` - Generate dev docs for a feature
- `create-feature-branch.sh` - Start a new feature with proper setup
- `rollback-feature.sh` - Safely rollback features

## Configuration

### Environment Variables

Edit `.env`:

```bash
# Required for API integration
API_BASE_URL=https://api.example.com
API_KEY=your_key_here

# Optional: Enable third-party audit
ANTHROPIC_API_KEY=your_claude_key
SKIP_THIRD_PARTY_AUDIT=false
```

### Repomix

Configuration in `repomix.config.json`:
- Used for third-party audit
- Packages code for AI review
- Compresses by ~70% with tree-sitter

## Best Practices

### ✅ DO

- Use real API endpoints with environment variables
- Write tests with real assertions
- Update dev docs as you make decisions
- Commit in atomic chunks (one logical change per commit)
- Merge features with `--no-ff` for rollback safety

### ❌ DON'T

- Use mock data in production code
- Fake tests or skip assertions
- Hardcode API URLs or keys
- Commit without running hooks
- Skip dev docs updates

## Troubleshooting

### Hook Fails

If a hook blocks your commit:
1. Read the error message carefully
2. Fix the specific issue
3. Try committing again

Common issues:
- TypeScript errors → Fix type issues
- Build fails → Check dependencies
- Mock data detected → Use real API
- Fake tests → Add real assertions

### Bypass Hooks (Emergency Only)

```bash
# NOT RECOMMENDED
git commit --no-verify
```

Only use in emergencies. Bypassing hooks defeats the purpose of the system.

### Third-Party Audit

To enable:
```bash
export ANTHROPIC_API_KEY=your_key
```

To disable:
```bash
export SKIP_THIRD_PARTY_AUDIT=true
```

## Architecture

```
Feature Initiation
  ↓
Pre-Validation (Context + Skills)
  ↓
Development (Atomic Commits)
  ↓
Post-Validation (5 Hook Checks)
  ↓
Third-Party Audit (Optional)
  ↓
Commit Success ✅
```

## Support

- Issues with hooks: Check `.claude/hooks/stop/*.sh`
- Issues with skills: Check `.claude/skills/*/SKILL.md`
- Context loss: Read dev docs in `dev-docs/`
- General questions: See `AI_WORKFLOW_RECOMMENDATIONS.md`

## Version

Workflow Version: 1.0
Created: 2025-11-14
EOF

    print_success "Created CLAUDE_WORKFLOW.md"
else
    print_info "CLAUDE_WORKFLOW.md already exists"
fi

# Step 8: Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup Complete! 🎉"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_success "Claude AI Workflow is ready to use"
echo ""
echo "Next steps:"
echo ""
echo "1. Configure your API settings in .env"
echo "   ${BLUE}vim .env${NC}"
echo ""
echo "2. (Optional) Add Anthropic API key for third-party audit"
echo "   ${BLUE}export ANTHROPIC_API_KEY=your_key${NC}"
echo ""
echo "3. Start your first feature:"
echo "   ${BLUE}npm run feature my-feature${NC}"
echo ""
echo "4. Read the workflow guide:"
echo "   ${BLUE}cat CLAUDE_WORKFLOW.md${NC}"
echo ""
echo "Documentation:"
echo "  • Workflow guide: ${BLUE}CLAUDE_WORKFLOW.md${NC}"
echo "  • Detailed recommendations: ${BLUE}AI_WORKFLOW_RECOMMENDATIONS.md${NC}"
echo "  • Dev docs: ${BLUE}dev-docs/${NC}"
echo ""
echo "The system will now:"
echo "  ✅ Auto-activate skills based on context"
echo "  ✅ Prevent mock data in production code"
echo "  ✅ Prevent fake tests"
echo "  ✅ Preserve context across sessions"
echo "  ✅ Enable atomic rollbacks"
echo ""
print_success "Happy coding! 🚀"
echo ""
