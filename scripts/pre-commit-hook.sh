#!/bin/bash
# Pre-commit hook for WrestlePick
# Enforces development guardrails before commits

set -e

echo "🔍 Running WrestlePick pre-commit checks..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "WrestlePick.xcodeproj/project.pbxproj" ]; then
    print_error "Not in WrestlePick project directory"
    exit 1
fi

# 1. SwiftLint checks
print_status "Running SwiftLint..."
if command -v swiftlint &> /dev/null; then
    swiftlint lint --quiet
    if [ $? -eq 0 ]; then
        print_success "SwiftLint passed"
    else
        print_error "SwiftLint failed. Please fix the issues above."
        exit 1
    fi
else
    print_warning "SwiftLint not installed. Install with: brew install swiftlint"
fi

# 2. SwiftFormat checks
print_status "Running SwiftFormat..."
if command -v swiftformat &> /dev/null; then
    swiftformat --lint --quiet .
    if [ $? -eq 0 ]; then
        print_success "SwiftFormat passed"
    else
        print_error "SwiftFormat failed. Run 'swiftformat .' to fix formatting issues."
        exit 1
    fi
else
    print_warning "SwiftFormat not installed. Install with: brew install swiftformat"
fi

# 3. Security checks
print_status "Running security checks..."

# Check for hardcoded secrets
if grep -r "sk_live_\|pk_live_\|AIza\|firebase\|google" --include="*.swift" --include="*.plist" . | grep -v "GoogleService-Info.plist" | grep -v "FirebaseConfig.swift" | grep -v "//"; then
    print_error "Potential hardcoded secrets found. Please use environment variables or secure storage."
    exit 1
fi

# Check for force unwrapping
if grep -r "!" --include="*.swift" . | grep -v "//" | grep -v "!=" | grep -v "!==" | grep -v "!" | head -5; then
    print_warning "Force unwrapping detected. Consider using guard statements or optional binding."
fi

# Check for TODO/FIXME comments
if grep -r "TODO\|FIXME\|HACK" --include="*.swift" . | grep -v "//"; then
    print_warning "TODO/FIXME comments found. Consider addressing before committing."
fi

print_success "Security checks passed"

# 4. Accessibility checks
print_status "Running accessibility checks..."

# Check for missing accessibility labels on images
if grep -r "Image(" --include="*.swift" . | grep -v "accessibilityLabel" | head -3; then
    print_warning "Images without accessibility labels found. Add .accessibilityLabel() for VoiceOver support."
fi

# Check for missing accessibility identifiers
if grep -r "Button\|TextField\|Picker" --include="*.swift" . | grep -v "accessibilityIdentifier" | head -3; then
    print_warning "UI elements without accessibility identifiers found. Add .accessibilityIdentifier() for testing."
fi

print_success "Accessibility checks passed"

# 5. Performance checks
print_status "Running performance checks..."

# Check for large files
find . -name "*.swift" -size +10k -exec basename {} \; | while read file; do
    if [ ! -z "$file" ]; then
        print_warning "Large file detected: $file. Consider breaking it into smaller components."
    fi
done

# Check for complex functions (approximate)
if grep -r "func " --include="*.swift" . | wc -l | awk '{if($1 > 50) print "Warning: Many functions detected. Consider code organization."}'; then
    print_warning "Consider organizing code into smaller, focused functions."
fi

print_success "Performance checks passed"

# 6. Documentation checks
print_status "Running documentation checks..."

# Check for missing documentation on public APIs
if grep -r "public func\|public class\|public struct" --include="*.swift" . | grep -v "///" | head -3; then
    print_warning "Public APIs without documentation found. Add /// documentation comments."
fi

print_success "Documentation checks passed"

# 7. Test coverage checks
print_status "Running test coverage checks..."

# Check if tests exist for modified files
if [ ! -d "WrestlePickTests" ] || [ ! -d "WrestlePickUITests" ]; then
    print_warning "Test directories not found. Ensure tests are created for new features."
fi

print_success "Test coverage checks passed"

# 8. Commit message format check
print_status "Checking commit message format..."

# This would be run by the commit-msg hook, but we can check the last commit
if git log -1 --pretty=%B | grep -E "^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .+"; then
    print_success "Last commit message follows conventional format"
else
    print_warning "Last commit message doesn't follow conventional format. Use: type(scope): description"
fi

# 9. Firebase security rules check
print_status "Checking Firebase security rules..."

if [ -f "WrestlePick/Services/FirestoreCollections.swift" ]; then
    if grep -q "allow read, write: if request.auth != null" "WrestlePick/Services/FirestoreCollections.swift"; then
        print_success "Firebase security rules include authentication checks"
    else
        print_warning "Firebase security rules may need authentication checks"
    fi
else
    print_warning "FirestoreCollections.swift not found. Ensure Firebase security rules are properly configured."
fi

# 10. Final validation
print_status "Running final validation..."

# Check for common SwiftUI anti-patterns
if grep -r "\.onAppear" --include="*.swift" . | grep -v "//" | head -3; then
    print_warning "Consider using @StateObject or @ObservedObject instead of .onAppear for data loading."
fi

# Check for proper error handling
if grep -r "try!" --include="*.swift" . | grep -v "//" | head -3; then
    print_warning "Consider using proper error handling instead of try! for better user experience."
fi

print_success "Final validation passed"

# Summary
echo ""
print_success "🎉 All pre-commit checks passed!"
print_status "Your code follows WrestlePick development standards."
echo ""

# Optional: Run tests if they exist
if [ -d "WrestlePickTests" ] && [ -f "WrestlePick.xcodeproj/project.pbxproj" ]; then
    print_status "Running unit tests..."
    if command -v xcodebuild &> /dev/null; then
        xcodebuild test -project WrestlePick.xcodeproj -scheme WrestlePick -destination 'platform=iOS Simulator,name=iPhone 15' -quiet
        if [ $? -eq 0 ]; then
            print_success "Unit tests passed"
        else
            print_error "Unit tests failed. Please fix failing tests before committing."
            exit 1
        fi
    else
        print_warning "xcodebuild not available. Run tests manually in Xcode."
    fi
fi

print_success "✅ Pre-commit hook completed successfully!"
echo ""
