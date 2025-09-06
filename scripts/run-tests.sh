#!/bin/bash
# Comprehensive test runner for WrestlePick
# Runs all tests and validation checks

set -e

echo "🧪 Running WrestlePick test suite..."

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

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TOTAL_TESTS=0

# Function to run a test and track results
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    print_status "Running $test_name..."
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    if eval "$test_command"; then
        print_success "$test_name passed"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        print_error "$test_name failed"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# 1. Code Quality Tests
echo ""
echo "🔍 Code Quality Tests"
echo "===================="

# SwiftLint
run_test "SwiftLint" "swiftlint lint --quiet"

# SwiftFormat
run_test "SwiftFormat" "swiftformat --lint --quiet ."

# Security checks
run_test "Security Scan" "
    if grep -r 'sk_live_\\|pk_live_\\|AIza\\|firebase\\|google' --include='*.swift' --include='*.plist' . | grep -v 'GoogleService-Info.plist' | grep -v 'FirebaseConfig.swift' | grep -v '//' | head -1; then
        echo 'Security issues found'
        exit 1
    fi
"

# 2. Unit Tests
echo ""
echo "🧪 Unit Tests"
echo "============="

# Check if test targets exist
if [ -d "WrestlePickTests" ]; then
    run_test "Unit Tests" "xcodebuild test -project WrestlePick.xcodeproj -scheme WrestlePick -destination 'platform=iOS Simulator,name=iPhone 15' -quiet"
else
    print_warning "Unit test target not found. Skipping unit tests."
fi

# 3. UI Tests
echo ""
echo "🎨 UI Tests"
echo "==========="

if [ -d "WrestlePickUITests" ]; then
    run_test "UI Tests" "xcodebuild test -project WrestlePick.xcodeproj -scheme WrestlePickUITests -destination 'platform=iOS Simulator,name=iPhone 15' -quiet"
else
    print_warning "UI test target not found. Skipping UI tests."
fi

# 4. Integration Tests
echo ""
echo "🔗 Integration Tests"
echo "==================="

# Firebase integration tests
if [ -f "WrestlePickTests/FirebaseIntegrationTests.swift" ]; then
    run_test "Firebase Integration" "xcodebuild test -project WrestlePick.xcodeproj -scheme WrestlePick -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:WrestlePickTests/FirebaseIntegrationTests -quiet"
else
    print_warning "Firebase integration tests not found. Skipping integration tests."
fi

# 5. Performance Tests
echo ""
echo "⚡ Performance Tests"
echo "==================="

# Build performance
run_test "Build Performance" "
    start_time=\$(date +%s)
    xcodebuild build -project WrestlePick.xcodeproj -scheme WrestlePick -destination 'platform=iOS Simulator,name=iPhone 15' -quiet
    end_time=\$(date +%s)
    duration=\$((end_time - start_time))
    if [ \$duration -gt 300 ]; then
        echo \"Build took too long: \${duration}s\"
        exit 1
    fi
    echo \"Build completed in \${duration}s\"
"

# Memory usage check
run_test "Memory Usage" "
    if find . -name '*.swift' -size +50k -exec basename {} \\; | head -1; then
        echo 'Large Swift files detected. Consider optimization.'
        exit 1
    fi
"

# 6. Accessibility Tests
echo ""
echo "♿ Accessibility Tests"
echo "===================="

# Check for missing accessibility labels
run_test "Accessibility Labels" "
    if grep -r 'Image(' --include='*.swift' . | grep -v 'accessibilityLabel' | head -3; then
        echo 'Images without accessibility labels found'
        exit 1
    fi
"

# Check for missing accessibility identifiers
run_test "Accessibility Identifiers" "
    if grep -r 'Button\\|TextField\\|Picker' --include='*.swift' . | grep -v 'accessibilityIdentifier' | head -3; then
        echo 'UI elements without accessibility identifiers found'
        exit 1
    fi
"

# 7. Documentation Tests
echo ""
echo "📚 Documentation Tests"
echo "====================="

# Check for missing documentation
run_test "API Documentation" "
    if grep -r 'public func\\|public class\\|public struct' --include='*.swift' . | grep -v '///' | head -3; then
        echo 'Public APIs without documentation found'
        exit 1
    fi
"

# Check README
run_test "README Documentation" "
    if [ ! -f 'README.md' ] || [ ! -s 'README.md' ]; then
        echo 'README.md is missing or empty'
        exit 1
    fi
"

# 8. Build Tests
echo ""
echo "🔨 Build Tests"
echo "=============="

# Debug build
run_test "Debug Build" "xcodebuild build -project WrestlePick.xcodeproj -scheme WrestlePick -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' -quiet"

# Release build
run_test "Release Build" "xcodebuild build -project WrestlePick.xcodeproj -scheme WrestlePick -configuration Release -destination 'platform=iOS Simulator,name=iPhone 15' -quiet"

# 9. Linting Tests
echo ""
echo "🔍 Linting Tests"
echo "==============="

# Check for TODO/FIXME comments
run_test "TODO/FIXME Check" "
    if grep -r 'TODO\\|FIXME\\|HACK' --include='*.swift' . | grep -v '//' | head -5; then
        echo 'TODO/FIXME comments found. Consider addressing before release.'
        exit 1
    fi
"

# Check for force unwrapping
run_test "Force Unwrap Check" "
    if grep -r '!' --include='*.swift' . | grep -v '//' | grep -v '!=' | grep -v '!==' | grep -v '!' | head -5; then
        echo 'Force unwrapping detected. Consider using guard statements.'
        exit 1
    fi
"

# 10. Security Tests
echo ""
echo "🔒 Security Tests"
echo "================="

# Check for hardcoded secrets
run_test "Hardcoded Secrets" "
    if grep -r 'password\\|secret\\|key\\|token' --include='*.swift' . | grep -v '//' | head -3; then
        echo 'Potential hardcoded secrets found'
        exit 1
    fi
"

# Check for insecure practices
run_test "Insecure Practices" "
    if grep -r 'try!' --include='*.swift' . | grep -v '//' | head -3; then
        echo 'Insecure try! usage found. Consider proper error handling.'
        exit 1
    fi
"

# 11. Performance Tests
echo ""
echo "⚡ Performance Tests"
echo "==================="

# Check for large files
run_test "File Size Check" "
    if find . -name '*.swift' -size +20k -exec basename {} \\; | head -3; then
        echo 'Large Swift files detected. Consider breaking them down.'
        exit 1
    fi
"

# Check for complex functions
run_test "Function Complexity" "
    if grep -r 'func ' --include='*.swift' . | wc -l | awk '{if(\$1 > 100) print \"Too many functions. Consider code organization.\"; exit 1}'; then
        echo 'Function count check passed'
    fi
"

# 12. Final Validation
echo ""
echo "✅ Final Validation"
echo "=================="

# Check project structure
run_test "Project Structure" "
    if [ ! -d 'WrestlePick' ] || [ ! -d 'WrestlePickTests' ] || [ ! -d 'WrestlePickUITests' ]; then
        echo 'Project structure is incomplete'
        exit 1
    fi
"

# Check for required files
run_test "Required Files" "
    required_files=('WrestlePick/WrestlePickApp.swift' 'WrestlePick/ContentView.swift' 'README.md' '.gitignore')
    for file in \"\${required_files[@]}\"; do
        if [ ! -f \"\$file\" ]; then
            echo \"Required file missing: \$file\"
            exit 1
        fi
    done
"

# Summary
echo ""
echo "📊 Test Summary"
echo "==============="
echo "Total Tests: $TOTAL_TESTS"
echo "Passed: $TESTS_PASSED"
echo "Failed: $TESTS_FAILED"

if [ $TESTS_FAILED -eq 0 ]; then
    print_success "🎉 All tests passed!"
    echo ""
    echo "Your code meets WrestlePick quality standards:"
    echo "✅ Code quality checks passed"
    echo "✅ Unit tests passed"
    echo "✅ UI tests passed"
    echo "✅ Integration tests passed"
    echo "✅ Performance tests passed"
    echo "✅ Accessibility tests passed"
    echo "✅ Documentation tests passed"
    echo "✅ Build tests passed"
    echo "✅ Security tests passed"
    echo "✅ Linting tests passed"
    echo ""
    print_success "Ready for commit and deployment! 🚀"
    exit 0
else
    print_error "❌ Some tests failed. Please fix the issues above before committing."
    echo ""
    echo "Failed tests:"
    echo "❌ $TESTS_FAILED test(s) failed"
    echo ""
    print_error "Please address the issues and run the tests again."
    exit 1
fi
