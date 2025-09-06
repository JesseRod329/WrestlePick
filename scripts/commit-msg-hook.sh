#!/bin/bash
# Commit message hook for WrestlePick
# Enforces conventional commit message format

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Read the commit message
commit_message=$(cat "$1")

# Conventional commit format regex
# Format: type(scope): description
# Types: feat, fix, docs, style, refactor, test, chore
# Scopes: auth, news, predictions, social, merch, premium, ui, api, etc.
conventional_regex="^(feat|fix|docs|style|refactor|test|chore)(\([a-z-]+\))?: .+"

if [[ $commit_message =~ $conventional_regex ]]; then
    print_success "Commit message follows conventional format"
    
    # Extract type and scope
    type=$(echo "$commit_message" | sed -n 's/^\([a-z]*\).*/\1/p')
    scope=$(echo "$commit_message" | sed -n 's/^[a-z]*(\([a-z-]*\)):.*/\1/p')
    description=$(echo "$commit_message" | sed -n 's/^[a-z]*(\([a-z-]*\)): \(.*\)/\2/p')
    
    # Validate type
    case $type in
        feat|fix|docs|style|refactor|test|chore)
            print_info "Type: $type"
            ;;
        *)
            print_error "Invalid commit type: $type"
            print_info "Valid types: feat, fix, docs, style, refactor, test, chore"
            exit 1
            ;;
    esac
    
    # Validate scope (if provided)
    if [ ! -z "$scope" ]; then
        case $scope in
            auth|news|predictions|social|merch|premium|ui|api|services|models|views|utils|tests|config|docs|ci|chore)
                print_info "Scope: $scope"
                ;;
            *)
                print_error "Invalid commit scope: $scope"
                print_info "Valid scopes: auth, news, predictions, social, merch, premium, ui, api, services, models, views, utils, tests, config, docs, ci, chore"
                exit 1
                ;;
        esac
    fi
    
    # Validate description length
    if [ ${#description} -lt 10 ]; then
        print_error "Commit description too short. Please provide a more descriptive message."
        exit 1
    fi
    
    if [ ${#description} -gt 100 ]; then
        print_error "Commit description too long. Keep it under 100 characters."
        exit 1
    fi
    
    # Check for common issues
    if [[ $description =~ ^[a-z] ]]; then
        print_error "Commit description should start with a capital letter."
        exit 1
    fi
    
    if [[ $description =~ \.$ ]]; then
        print_error "Commit description should not end with a period."
        exit 1
    fi
    
    # Check for specific patterns
    if [[ $description =~ (WIP|wip|TODO|todo|FIXME|fixme) ]]; then
        print_error "Commit message contains WIP/TODO/FIXME. Please complete the work before committing."
        exit 1
    fi
    
    if [[ $description =~ (test|testing) ]]; then
        if [ "$type" != "test" ]; then
            print_warning "Commit mentions testing but type is not 'test'. Consider using 'test' type for test-related commits."
        fi
    fi
    
    # Success
    print_success "✅ Commit message validation passed!"
    print_info "Type: $type"
    if [ ! -z "$scope" ]; then
        print_info "Scope: $scope"
    fi
    print_info "Description: $description"
    
else
    print_error "Commit message does not follow conventional format"
    echo ""
    print_info "Expected format: type(scope): description"
    echo ""
    print_info "Examples:"
    echo "  feat(auth): add Apple Sign In integration"
    echo "  fix(predictions): resolve scoring calculation bug"
    echo "  docs(api): update Firebase integration guide"
    echo "  style(ui): improve accessibility for VoiceOver users"
    echo "  refactor(services): extract common error handling logic"
    echo "  test(predictions): add unit tests for scoring algorithm"
    echo "  chore(deps): update Firebase SDK to latest version"
    echo ""
    print_info "Types: feat, fix, docs, style, refactor, test, chore"
    print_info "Scopes: auth, news, predictions, social, merch, premium, ui, api, services, models, views, utils, tests, config, docs, ci, chore"
    echo ""
    exit 1
fi
