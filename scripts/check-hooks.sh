#!/bin/bash
# Check Git hooks status for WrestlePick

echo "🔍 Checking Git hooks status..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

check_hook() {
    local hook_name=$1
    local hook_path=".git/hooks/$hook_name"
    
    if [ -f "$hook_path" ] && [ -x "$hook_path" ]; then
        echo -e "${GREEN}✅${NC} $hook_name hook is installed and executable"
    else
        echo -e "${RED}❌${NC} $hook_name hook is missing or not executable"
    fi
}

echo "Git Hooks Status:"
echo "================="
check_hook "pre-commit"
check_hook "commit-msg"
check_hook "post-commit"
check_hook "pre-push"
check_hook "pre-receive"
check_hook "update"

echo ""
echo "Hook Files:"
echo "==========="
ls -la .git/hooks/ | grep -E "(pre-commit|commit-msg|post-commit|pre-push|pre-receive|update)"

echo ""
echo "To test hooks:"
echo "=============="
echo "1. Test pre-commit: Make a change and run 'git add . && git commit -m \"test: test commit\"'"
echo "2. Test commit-msg: Try committing with invalid message format"
echo "3. Test pre-push: Run 'git push' to trigger pre-push checks"
