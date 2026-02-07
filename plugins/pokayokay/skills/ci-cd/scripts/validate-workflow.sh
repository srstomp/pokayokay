#!/bin/bash
# validate-workflow.sh
# Validate CI/CD workflow files for common platforms

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

usage() {
    echo "Usage: $0 <workflow-file> [--platform <platform>]"
    echo ""
    echo "Platforms: github, gitlab, circleci, azure, bitbucket, auto (default)"
    echo ""
    echo "Examples:"
    echo "  $0 .github/workflows/ci.yml"
    echo "  $0 .gitlab-ci.yml --platform gitlab"
    echo "  $0 azure-pipelines.yml --platform azure"
    exit 1
}

detect_platform() {
    local file="$1"
    
    if [[ "$file" == *".github/workflows"* ]] || [[ "$file" == *"github"* ]]; then
        echo "github"
    elif [[ "$file" == *"gitlab"* ]] || [[ "$file" == ".gitlab-ci.yml" ]]; then
        echo "gitlab"
    elif [[ "$file" == *"circleci"* ]] || [[ "$file" == *".circleci"* ]]; then
        echo "circleci"
    elif [[ "$file" == *"azure"* ]]; then
        echo "azure"
    elif [[ "$file" == *"bitbucket"* ]]; then
        echo "bitbucket"
    else
        echo "unknown"
    fi
}

validate_yaml() {
    local file="$1"
    
    if command -v yq &> /dev/null; then
        if yq eval '.' "$file" > /dev/null 2>&1; then
            echo -e "${GREEN}✓${NC} Valid YAML syntax"
            return 0
        else
            echo -e "${RED}✗${NC} Invalid YAML syntax"
            yq eval '.' "$file" 2>&1 | head -10
            return 1
        fi
    elif command -v python3 &> /dev/null; then
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Valid YAML syntax"
            return 0
        else
            echo -e "${RED}✗${NC} Invalid YAML syntax"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠${NC} No YAML validator found (install yq or python3-yaml)"
        return 0
    fi
}

validate_github() {
    local file="$1"
    echo "Validating GitHub Actions workflow..."
    
    # Check for actionlint
    if command -v actionlint &> /dev/null; then
        if actionlint "$file"; then
            echo -e "${GREEN}✓${NC} actionlint validation passed"
        else
            echo -e "${RED}✗${NC} actionlint found issues"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠${NC} actionlint not installed (brew install actionlint)"
    fi
    
    # Manual checks
    echo "Running manual checks..."
    
    # Check for unpinned actions
    if grep -E "uses:\s+[^@]+@(main|master|latest)" "$file" > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠${NC} Found unpinned actions (use SHA or version tag)"
        grep -n "uses:.*@\(main\|master\|latest\)" "$file" || true
    else
        echo -e "${GREEN}✓${NC} All actions appear pinned"
    fi
    
    # Check for hardcoded secrets
    if grep -iE "(api_key|secret|password|token)\s*[:=]\s*['\"][^$]" "$file" > /dev/null 2>&1; then
        echo -e "${RED}✗${NC} Potential hardcoded secrets detected"
        return 1
    else
        echo -e "${GREEN}✓${NC} No obvious hardcoded secrets"
    fi
    
    # Check for permissions
    if grep -q "permissions:" "$file"; then
        echo -e "${GREEN}✓${NC} Explicit permissions declared"
    else
        echo -e "${YELLOW}⚠${NC} No explicit permissions (using defaults)"
    fi
    
    # Check for required keys
    if grep -q "^on:" "$file" || grep -q "^'on':" "$file"; then
        echo -e "${GREEN}✓${NC} Trigger (on:) defined"
    else
        echo -e "${RED}✗${NC} Missing trigger (on:)"
        return 1
    fi
    
    if grep -q "^jobs:" "$file"; then
        echo -e "${GREEN}✓${NC} Jobs defined"
    else
        echo -e "${RED}✗${NC} Missing jobs section"
        return 1
    fi
}

validate_gitlab() {
    local file="$1"
    echo "Validating GitLab CI configuration..."
    
    # Check for required structure
    if grep -qE "^(stages:|[a-zA-Z_-]+:)" "$file"; then
        echo -e "${GREEN}✓${NC} Jobs or stages found"
    else
        echo -e "${RED}✗${NC} No jobs or stages found"
        return 1
    fi
    
    # Check for script in jobs
    if grep -q "script:" "$file"; then
        echo -e "${GREEN}✓${NC} Script sections found"
    else
        echo -e "${YELLOW}⚠${NC} No script sections (might be using includes)"
    fi
    
    # Check for hardcoded secrets
    if grep -iE "(api_key|secret|password|token)\s*[:=]\s*['\"][^$]" "$file" > /dev/null 2>&1; then
        echo -e "${RED}✗${NC} Potential hardcoded secrets detected"
        return 1
    else
        echo -e "${GREEN}✓${NC} No obvious hardcoded secrets"
    fi
    
    echo -e "${YELLOW}⚠${NC} For full validation, use GitLab's CI Lint feature"
}

validate_circleci() {
    local file="$1"
    echo "Validating CircleCI configuration..."
    
    # Check for circleci CLI
    if command -v circleci &> /dev/null; then
        if circleci config validate "$file"; then
            echo -e "${GREEN}✓${NC} CircleCI validation passed"
        else
            echo -e "${RED}✗${NC} CircleCI validation failed"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠${NC} circleci CLI not installed"
    fi
    
    # Check for version
    if grep -q "^version:" "$file"; then
        echo -e "${GREEN}✓${NC} Version specified"
    else
        echo -e "${RED}✗${NC} Missing version"
        return 1
    fi
    
    # Check for jobs or workflows
    if grep -qE "^(jobs:|workflows:)" "$file"; then
        echo -e "${GREEN}✓${NC} Jobs or workflows found"
    else
        echo -e "${RED}✗${NC} Missing jobs or workflows"
        return 1
    fi
}

validate_azure() {
    local file="$1"
    echo "Validating Azure DevOps pipeline..."
    
    # Check for trigger or pr
    if grep -qE "^(trigger:|pr:)" "$file"; then
        echo -e "${GREEN}✓${NC} Trigger defined"
    else
        echo -e "${YELLOW}⚠${NC} No trigger defined (will use defaults)"
    fi
    
    # Check for pool or stages
    if grep -qE "^(pool:|stages:|jobs:|steps:)" "$file"; then
        echo -e "${GREEN}✓${NC} Pipeline structure found"
    else
        echo -e "${RED}✗${NC} Missing pipeline structure"
        return 1
    fi
    
    echo -e "${YELLOW}⚠${NC} For full validation, use Azure DevOps pipeline editor"
}

validate_bitbucket() {
    local file="$1"
    echo "Validating Bitbucket Pipelines configuration..."
    
    # Check for pipelines key
    if grep -q "^pipelines:" "$file"; then
        echo -e "${GREEN}✓${NC} Pipelines section found"
    else
        echo -e "${RED}✗${NC} Missing pipelines section"
        return 1
    fi
    
    # Check for image
    if grep -q "^image:" "$file"; then
        echo -e "${GREEN}✓${NC} Default image specified"
    else
        echo -e "${YELLOW}⚠${NC} No default image (steps must specify images)"
    fi
    
    echo -e "${YELLOW}⚠${NC} For full validation, use Bitbucket's pipeline validator"
}

# Main
if [ $# -lt 1 ]; then
    usage
fi

FILE="$1"
PLATFORM="auto"

# Parse arguments
while [[ $# -gt 1 ]]; do
    case $2 in
        --platform)
            PLATFORM="$3"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

if [ ! -f "$FILE" ]; then
    echo -e "${RED}Error: File not found: $FILE${NC}"
    exit 1
fi

echo "============================================"
echo "Validating: $FILE"
echo "============================================"

# YAML validation first
if ! validate_yaml "$FILE"; then
    exit 1
fi

# Detect platform if auto
if [ "$PLATFORM" = "auto" ]; then
    PLATFORM=$(detect_platform "$FILE")
    echo "Detected platform: $PLATFORM"
fi

echo ""

# Platform-specific validation
case "$PLATFORM" in
    github)
        validate_github "$FILE"
        ;;
    gitlab)
        validate_gitlab "$FILE"
        ;;
    circleci)
        validate_circleci "$FILE"
        ;;
    azure)
        validate_azure "$FILE"
        ;;
    bitbucket)
        validate_bitbucket "$FILE"
        ;;
    *)
        echo -e "${YELLOW}Unknown platform, running basic checks only${NC}"
        ;;
esac

echo ""
echo "============================================"
echo "Validation complete"
echo "============================================"
