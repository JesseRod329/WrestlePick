#!/bin/bash
# Setup Git hooks for WrestlePick
# Installs pre-commit and commit-msg hooks

set -e

echo "🔧 Setting up Git hooks for WrestlePick..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    print_error "Not in a Git repository. Please run 'git init' first."
    exit 1
fi

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Install pre-commit hook
print_status "Installing pre-commit hook..."
cp scripts/pre-commit-hook.sh .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
print_success "Pre-commit hook installed"

# Install commit-msg hook
print_status "Installing commit-msg hook..."
cp scripts/commit-msg-hook.sh .git/hooks/commit-msg
chmod +x .git/hooks/commit-msg
print_success "Commit-msg hook installed"

# Create post-commit hook for additional checks
print_status "Creating post-commit hook..."
cat > .git/hooks/post-commit << 'EOF'
#!/bin/bash
# Post-commit hook for WrestlePick
# Runs additional checks after successful commit

echo "🎉 Commit successful! Running post-commit checks..."

# Check if this is a release commit
if git log -1 --pretty=%B | grep -q "release:"; then
    echo "📦 Release commit detected. Consider creating a tag."
fi

# Check if this is a breaking change
if git log -1 --pretty=%B | grep -q "BREAKING CHANGE:"; then
    echo "⚠️  Breaking change detected. Update version number and changelog."
fi

# Check if tests should be run
if git log -1 --pretty=%B | grep -q "test:"; then
    echo "🧪 Test-related commit detected. Consider running full test suite."
fi

echo "✅ Post-commit checks completed."
EOF

chmod +x .git/hooks/post-commit
print_success "Post-commit hook installed"

# Create pre-push hook for additional validation
print_status "Creating pre-push hook..."
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash
# Pre-push hook for WrestlePick
# Runs additional checks before pushing to remote

echo "🚀 Running pre-push checks..."

# Check if tests pass
if [ -d "WrestlePickTests" ]; then
    echo "🧪 Running tests before push..."
    if command -v xcodebuild &> /dev/null; then
        xcodebuild test -project WrestlePick.xcodeproj -scheme WrestlePick -destination 'platform=iOS Simulator,name=iPhone 15' -quiet
        if [ $? -ne 0 ]; then
            echo "❌ Tests failed. Please fix failing tests before pushing."
            exit 1
        fi
    else
        echo "⚠️  xcodebuild not available. Run tests manually in Xcode."
    fi
fi

# Check for large files
echo "📏 Checking for large files..."
if git ls-files | xargs ls -la | awk '$5 > 1000000 {print $9 " (" $5 " bytes)"}' | head -5; then
    echo "⚠️  Large files detected. Consider using Git LFS for binary files."
fi

# Check for sensitive data
echo "🔒 Checking for sensitive data..."
if git diff --cached --name-only | xargs grep -l "password\|secret\|key\|token" 2>/dev/null | head -3; then
    echo "❌ Potential sensitive data detected. Please remove before pushing."
    exit 1
fi

echo "✅ Pre-push checks passed!"
EOF

chmod +x .git/hooks/pre-push
print_success "Pre-push hook installed"

# Create a hook to check for proper branch naming
print_status "Creating branch naming hook..."
cat > .git/hooks/pre-receive << 'EOF'
#!/bin/bash
# Pre-receive hook for WrestlePick
# Validates branch names and commit messages

echo "🔍 Validating branch names and commits..."

# Check branch naming convention
while read oldrev newrev refname; do
    branch=$(git rev-parse --symbolic --abbrev-ref $refname)
    
    # Skip if it's a tag or not a branch
    if [[ $refname =~ refs/tags/ ]]; then
        continue
    fi
    
    # Check branch naming convention
    if [[ ! $branch =~ ^(main|master|develop|feature/|bugfix/|hotfix/|release/|chore/) ]]; then
        echo "❌ Invalid branch name: $branch"
        echo "Valid branch names: main, master, develop, feature/*, bugfix/*, hotfix/*, release/*, chore/*"
        exit 1
    fi
    
    # Check commit messages
    git rev-list $oldrev..$newrev | while read commit; do
        commit_msg=$(git log --format=%B -n 1 $commit)
        if [[ ! $commit_msg =~ ^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+ ]]; then
            echo "❌ Invalid commit message: $commit"
            echo "Commit: $commit_msg"
            echo "Expected format: type(scope): description"
            exit 1
        fi
    done
done

echo "✅ Branch and commit validation passed!"
EOF

chmod +x .git/hooks/pre-receive
print_success "Branch naming hook installed"

# Create a hook to validate pull requests
print_status "Creating pull request validation hook..."
cat > .git/hooks/update << 'EOF'
#!/bin/bash
# Update hook for WrestlePick
# Validates updates to branches

echo "🔄 Validating branch updates..."

# Get the branch name
branch=$1
oldrev=$2
newrev=$3

# Check if it's a force push
if git rev-list --count $oldrev..$newrev | grep -q "^-"; then
    echo "⚠️  Force push detected on branch: $branch"
    echo "Force pushes can cause issues for other developers."
fi

# Check for merge commits
if git rev-list --merges $oldrev..$newrev | wc -l | grep -q "[1-9]"; then
    echo "ℹ️  Merge commits detected. Consider using rebase for cleaner history."
fi

# Check for large commits
if git diff --stat $oldrev..$newrev | tail -1 | grep -q "files changed"; then
    changes=$(git diff --stat $oldrev..$newrev | tail -1 | awk '{print $4}')
    if [ $changes -gt 50 ]; then
        echo "⚠️  Large commit detected: $changes files changed"
        echo "Consider breaking large commits into smaller, focused commits."
    fi
fi

echo "✅ Branch update validation passed!"
EOF

chmod +x .git/hooks/update
print_success "Pull request validation hook installed"

# Create a comprehensive hook status checker
print_status "Creating hook status checker..."
cat > scripts/check-hooks.sh << 'EOF'
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
EOF

chmod +x scripts/check-hooks.sh
print_success "Hook status checker created"

# Create a hook installation script for new developers
print_status "Creating developer setup script..."
cat > scripts/setup-dev-environment.sh << 'EOF'
#!/bin/bash
# Setup development environment for WrestlePick

echo "🚀 Setting up WrestlePick development environment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "WrestlePick.xcodeproj/project.pbxproj" ]; then
    print_error "Not in WrestlePick project directory"
    exit 1
fi

# Install Git hooks
print_status "Installing Git hooks..."
./scripts/setup-git-hooks.sh

# Check for required tools
print_status "Checking for required tools..."

# Check for SwiftLint
if command -v swiftlint &> /dev/null; then
    print_success "SwiftLint is installed"
else
    print_error "SwiftLint not found. Install with: brew install swiftlint"
fi

# Check for SwiftFormat
if command -v swiftformat &> /dev/null; then
    print_success "SwiftFormat is installed"
else
    print_error "SwiftFormat not found. Install with: brew install swiftformat"
fi

# Check for Xcode
if command -v xcodebuild &> /dev/null; then
    print_success "Xcode command line tools are installed"
else
    print_error "Xcode command line tools not found. Install from Xcode preferences"
fi

# Check for CocoaPods (if needed)
if command -v pod &> /dev/null; then
    print_success "CocoaPods is installed"
else
    print_warning "CocoaPods not found. Install with: sudo gem install cocoapods"
fi

# Check for Firebase CLI (if needed)
if command -v firebase &> /dev/null; then
    print_success "Firebase CLI is installed"
else
    print_warning "Firebase CLI not found. Install with: npm install -g firebase-tools"
fi

# Create .env file template
print_status "Creating environment file template..."
cat > .env.template << 'ENVEOF'
# WrestlePick Environment Variables
# Copy this file to .env and fill in your values

# Firebase Configuration
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
FIREBASE_STORAGE_BUCKET=your-project.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your-sender-id
FIREBASE_APP_ID=your-app-id

# API Keys (if needed)
NEWS_API_KEY=your-news-api-key
SOCIAL_MEDIA_API_KEY=your-social-api-key

# Development Settings
DEBUG_MODE=true
LOG_LEVEL=debug
ENABLE_ANALYTICS=false
ENABLE_CRASH_REPORTING=false
ENVEOF

print_success "Environment file template created"

# Create development documentation
print_status "Creating development documentation..."
cat > DEVELOPER_GUIDE.md << 'DOCEOF'
# WrestlePick Developer Guide

## Getting Started

1. Clone the repository
2. Run `./scripts/setup-dev-environment.sh`
3. Copy `.env.template` to `.env` and fill in your values
4. Open `WrestlePick.xcodeproj` in Xcode
5. Build and run the project

## Development Standards

- Follow the guardrails in `DEVELOPMENT_GUARDRAILS.md`
- Use conventional commit messages
- Run tests before committing
- Follow SwiftUI best practices
- Ensure accessibility compliance

## Git Workflow

1. Create feature branch: `git checkout -b feature/your-feature`
2. Make changes and commit: `git commit -m "feat(feature): add new feature"`
3. Push branch: `git push origin feature/your-feature`
4. Create pull request
5. Merge after review

## Testing

- Run unit tests: `xcodebuild test -project WrestlePick.xcodeproj -scheme WrestlePick`
- Run UI tests: `xcodebuild test -project WrestlePick.xcodeproj -scheme WrestlePickUITests`
- Run all tests: `./scripts/run-tests.sh`

## Code Quality

- Run SwiftLint: `swiftlint lint`
- Run SwiftFormat: `swiftformat .`
- Check hooks: `./scripts/check-hooks.sh`

## Troubleshooting

- If hooks aren't working: `./scripts/setup-git-hooks.sh`
- If tests fail: Check Xcode for specific errors
- If build fails: Clean build folder in Xcode
DOCEOF

print_success "Developer guide created"

# Final status
echo ""
print_success "🎉 Development environment setup complete!"
echo ""
echo "Next steps:"
echo "1. Copy .env.template to .env and fill in your values"
echo "2. Open WrestlePick.xcodeproj in Xcode"
echo "3. Build and run the project"
echo "4. Read DEVELOPER_GUIDE.md for more information"
echo ""
EOF

chmod +x scripts/setup-dev-environment.sh
print_success "Developer setup script created"

# Final status
echo ""
print_success "🎉 Git hooks setup complete!"
echo ""
echo "Installed hooks:"
echo "✅ pre-commit - Code quality and security checks"
echo "✅ commit-msg - Conventional commit message validation"
echo "✅ post-commit - Additional post-commit checks"
echo "✅ pre-push - Pre-push validation and testing"
echo "✅ pre-receive - Branch and commit validation"
echo "✅ update - Branch update validation"
echo ""
echo "To check hook status: ./scripts/check-hooks.sh"
echo "To setup dev environment: ./scripts/setup-dev-environment.sh"
echo ""
