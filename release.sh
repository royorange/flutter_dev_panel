#!/bin/bash

# Release helper script for Flutter Dev Panel
# This script helps update versions and create tags for GitHub Actions publishing

set -e

# Color output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_info() { echo -e "${YELLOW}➜ $1${NC}"; }

# Function to update version in pubspec.yaml
update_version() {
    local file=$1
    local new_version=$2
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/^version: .*/version: $new_version/" "$file"
    else
        sed -i "s/^version: .*/version: $new_version/" "$file"
    fi
}

# Function to update changelog
update_changelog() {
    local changelog=$1
    local version=$2
    local package_name=$3
    
    print_info "Please update $changelog with changes for version $version"
    print_info "Opening in default editor..."
    ${EDITOR:-nano} "$changelog"
}

# Main menu
main() {
    print_info "Flutter Dev Panel Release Helper"
    echo "================================"
    echo ""
    echo "Select package to release:"
    echo "1. flutter_dev_panel (main)"
    echo "2. flutter_dev_panel_console"
    echo "3. flutter_dev_panel_network"
    echo "4. flutter_dev_panel_device"
    echo "5. flutter_dev_panel_performance"
    echo "0. Exit"
    echo ""
    
    read -p "Enter choice (0-5): " choice
    
    case $choice in
        1) release_package "." "flutter_dev_panel" ;;
        2) release_package "packages/flutter_dev_panel_console" "flutter_dev_panel_console" ;;
        3) release_package "packages/flutter_dev_panel_network" "flutter_dev_panel_network" ;;
        4) release_package "packages/flutter_dev_panel_device" "flutter_dev_panel_device" ;;
        5) release_package "packages/flutter_dev_panel_performance" "flutter_dev_panel_performance" ;;
        0) exit 0 ;;
        *) print_error "Invalid choice"; exit 1 ;;
    esac
}

# Function to release a package
release_package() {
    local package_path=$1
    local package_name=$2
    
    cd "$package_path"
    
    # Get current version
    current_version=$(grep "^version:" pubspec.yaml | cut -d' ' -f2)
    print_info "Current version: $current_version"
    
    # Ask for new version
    echo ""
    read -p "Enter new version (or press Enter to keep current): " new_version
    
    if [[ -z "$new_version" ]]; then
        new_version=$current_version
    fi
    
    # Update version if changed
    if [[ "$new_version" != "$current_version" ]]; then
        print_info "Updating version to $new_version..."
        update_version "pubspec.yaml" "$new_version"
        print_success "Version updated"
    fi
    
    # Update CHANGELOG
    if [[ -f "CHANGELOG.md" ]]; then
        read -p "Update CHANGELOG.md? [Y/n] " -r
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            update_changelog "CHANGELOG.md" "$new_version" "$package_name"
        fi
    fi
    
    # Run tests
    print_info "Running tests..."
    if flutter test > /dev/null 2>&1; then
        print_success "Tests passed"
    else
        print_error "Tests failed"
        read -p "Continue anyway? [y/N] " -r
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Commit changes
    if [[ -n $(git status -s) ]]; then
        print_info "Committing changes..."
        git add -A
        git commit -m "chore: release $package_name v$new_version"
        print_success "Changes committed"
    fi
    
    # Create tag with shorter prefix
    case "$package_name" in
        "flutter_dev_panel")
            tag_name="v$new_version"
            ;;
        "flutter_dev_panel_console")
            tag_name="console-v$new_version"
            ;;
        "flutter_dev_panel_network")
            tag_name="network-v$new_version"
            ;;
        "flutter_dev_panel_device")
            tag_name="device-v$new_version"
            ;;
        "flutter_dev_panel_performance")
            tag_name="performance-v$new_version"
            ;;
    esac
    
    read -p "Create tag '$tag_name' and push? [Y/n] " -r
    if [[ ! $REPLY =~ ^[Nn]$ ]]; then
        git tag -a "$tag_name" -m "Release $package_name v$new_version"
        print_success "Tag created: $tag_name"
        
        read -p "Push to origin? [Y/n] " -r
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            git push origin main
            git push origin "$tag_name"
            print_success "Pushed to origin"
            print_info "GitHub Actions will automatically publish to pub.dev"
        fi
    fi
    
    print_success "Release preparation complete!"
    echo ""
    echo "Next steps:"
    echo "1. Check GitHub Actions: https://github.com/yourusername/flutter_dev_panel/actions"
    echo "2. Verify on pub.dev: https://pub.dev/packages/$package_name"
}

# Run main
main