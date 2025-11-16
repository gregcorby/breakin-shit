#!/bin/bash

# Skill Auto-Activation Hook
# Analyzes user prompts and automatically loads relevant skills
# Prevents context loss by ensuring proper skill context is loaded

PROMPT="$1"
SKILLS_DIR=".claude/skills"
RULES_FILE="$SKILLS_DIR/skill-rules.json"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if rules file exists
if [[ ! -f "$RULES_FILE" ]]; then
    echo -e "${YELLOW}⚠️  Skill rules not found. Skipping auto-activation.${NC}"
    exit 0
fi

# Function to check if prompt contains trigger words
check_triggers() {
    local triggers="$1"
    local prompt_lower=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

    # Parse triggers array from JSON and check each
    echo "$triggers" | jq -r '.[]' | while read -r trigger; do
        trigger_lower=$(echo "$trigger" | tr '[:upper:]' '[:lower:]')
        if echo "$prompt_lower" | grep -qi "$trigger_lower"; then
            echo "match"
            return 0
        fi
    done
}

# Parse rules and activate skills
activated_skills=()

# Read rules from JSON
num_rules=$(jq '.rules | length' "$RULES_FILE")

for ((i=0; i<num_rules; i++)); do
    rule=$(jq ".rules[$i]" "$RULES_FILE")

    skill_name=$(echo "$rule" | jq -r '.skill')
    triggers=$(echo "$rule" | jq -r '.triggers')
    message=$(echo "$rule" | jq -r '.message')
    priority=$(echo "$rule" | jq -r '.priority')

    # Check if any trigger matches
    if echo "$triggers" | jq -r '.[]' | grep -qiF -f - <(echo "$PROMPT"); then
        activated_skills+=("$skill_name")

        # Display activation message
        if [[ "$priority" == "high" ]]; then
            echo -e "${BLUE}${message}${NC}"
        else
            echo -e "${GREEN}${message}${NC}"
        fi

        # Load skill context
        skill_file="$SKILLS_DIR/$skill_name/SKILL.md"
        if [[ -f "$skill_file" ]]; then
            echo -e "${GREEN}📚 Loaded: $skill_file${NC}"
        fi
    fi
done

# Load existing dev docs if they exist
if [[ -d "dev-docs" ]]; then
    # Try to extract feature name from prompt
    # Simple heuristic: look for common patterns
    if [[ "$PROMPT" =~ (feature|implement|add|create|build).*(for|called|named)?[[:space:]]+([a-zA-Z-]+) ]]; then
        feature_name="${BASH_REMATCH[3]}"

        # Check if dev docs exist for this feature
        if [[ -f "dev-docs/${feature_name}-context.md" ]]; then
            echo -e "${BLUE}📖 Loading context: dev-docs/${feature_name}-context.md${NC}"
        fi

        if [[ -f "dev-docs/${feature_name}-plan.md" ]]; then
            echo -e "${BLUE}📋 Loading plan: dev-docs/${feature_name}-plan.md${NC}"
        fi

        if [[ -f "dev-docs/${feature_name}-tasks.md" ]]; then
            echo -e "${BLUE}✅ Loading tasks: dev-docs/${feature_name}-tasks.md${NC}"
        fi
    fi
fi

# Check API configuration if API work detected
if [[ "$PROMPT" =~ (API|api|endpoint|fetch|request) ]]; then
    echo -e "${BLUE}🔍 Detected API work. Validating configuration...${NC}"

    # Check for .env file
    if [[ -f ".env" ]]; then
        required_vars=("API_BASE_URL")
        missing_vars=()

        for var in "${required_vars[@]}"; do
            if ! grep -q "^${var}=" .env; then
                missing_vars+=("$var")
            fi
        done

        if [[ ${#missing_vars[@]} -gt 0 ]]; then
            echo -e "${YELLOW}⚠️  Missing environment variables: ${missing_vars[*]}${NC}"
            echo -e "${YELLOW}   You may need to configure these before API integration will work.${NC}"
        else
            echo -e "${GREEN}✅ API configuration validated${NC}"
        fi
    else
        echo -e "${YELLOW}⚠️  No .env file found. API configuration may be needed.${NC}"
    fi
fi

# Summary
if [[ ${#activated_skills[@]} -gt 0 ]]; then
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Activated ${#activated_skills[@]} skill(s): ${activated_skills[*]}${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
fi

exit 0
