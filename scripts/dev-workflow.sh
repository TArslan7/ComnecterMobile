#!/bin/bash

# 🚀 Comnecter Development Workflow Script
# Usage: ./scripts/dev-workflow.sh [command]

set -e

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

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to run flutter commands with error handling
run_flutter() {
    print_status "Running: $1"
    if flutter $2; then
        print_success "$1 completed successfully"
    else
        print_error "$1 failed"
        exit 1
    fi
}

# Function to check git status
check_git_status() {
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "You have uncommitted changes. Please commit or stash them first."
        git status --short
        exit 1
    fi
}

# Function to run tests
run_tests() {
    print_status "Running tests..."
    run_flutter "Unit Tests" "test"
    
    print_status "Running static analysis..."
    run_flutter "Static Analysis" "analyze"
    
    print_status "Checking code formatting..."
    if dart format --set-exit-if-changed .; then
        print_success "Code formatting is correct"
    else
        print_warning "Code formatting issues found. Run 'dart format .' to fix."
    fi
}

# Function to test on devices
test_devices() {
    print_status "Testing on iOS..."
    if flutter run -d "iPhone van Tolga" --no-sound-null-safety --debug --hot; then
        print_success "iOS test completed"
    else
        print_warning "iOS test failed or was interrupted"
    fi
    
    print_status "Testing on Android..."
    if flutter run -d "Pixel 9" --no-sound-null-safety --debug --hot; then
        print_success "Android test completed"
    else
        print_warning "Android test failed or was interrupted"
    fi
}

# Function to create feature branch
create_feature() {
    if [ -z "$1" ]; then
        print_error "Please provide a feature name: ./dev-workflow.sh create-feature feature-name"
        exit 1
    fi
    
    check_git_status
    
    print_status "Creating feature branch: feature/$1"
    git checkout develop
    git pull origin develop
    git checkout -b "feature/$1"
    print_success "Feature branch 'feature/$1' created"
}

# Function to test feature
test_feature() {
    print_status "Testing current feature..."
    run_tests
    test_devices
    print_success "Feature testing completed"
}

# Function to merge to testing
merge_to_testing() {
    check_git_status
    
    print_status "Merging to testing branch..."
    git checkout testing
    git pull origin testing
    git merge "$(git branch --show-current)"
    git push origin testing
    print_success "Merged to testing branch"
}

# Function to merge to develop
merge_to_develop() {
    print_status "Merging to develop branch..."
    git checkout develop
    git pull origin develop
    git merge testing
    git push origin develop
    print_success "Merged to develop branch"
}

# Function to release to master
release_to_master() {
    if [ -z "$1" ]; then
        print_error "Please provide a version tag: ./dev-workflow.sh release v1.0.0"
        exit 1
    fi
    
    print_status "Releasing version $1 to master..."
    git checkout master
    git pull origin master
    git merge develop
    git tag "$1"
    git push origin master --tags
    print_success "Released version $1 to master"
}

# Function to show help
show_help() {
    echo "🚀 Comnecter Development Workflow Script"
    echo ""
    echo "Usage: ./scripts/dev-workflow.sh [command]"
    echo ""
    echo "Commands:"
    echo "  create-feature <name>  Create a new feature branch"
    echo "  test                   Run all tests and device testing"
    echo "  test-feature           Test current feature branch"
    echo "  merge-testing          Merge current branch to testing"
    echo "  merge-develop          Merge testing to develop"
    echo "  release <version>      Release to master with version tag"
    echo "  help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./scripts/dev-workflow.sh create-feature user-profile"
    echo "  ./scripts/dev-workflow.sh test"
    echo "  ./scripts/dev-workflow.sh release v1.2.0"
}

# Main script logic
case "$1" in
    "create-feature")
        create_feature "$2"
        ;;
    "test")
        run_tests
        test_devices
        ;;
    "test-feature")
        test_feature
        ;;
    "merge-testing")
        merge_to_testing
        ;;
    "merge-develop")
        merge_to_develop
        ;;
    "release")
        release_to_master "$2"
        ;;
    "help"|"--help"|"-h"|"")
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac 