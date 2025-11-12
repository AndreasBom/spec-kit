#!/usr/bin/env bash

set -e

# Script to manually add Azure DevOps integration files to an existing spec-kit project
# without reinitializing the entire project

echo "═══════════════════════════════════════════════════════════"
echo "  Azure DevOps Integration Update Script"
echo "═══════════════════════════════════════════════════════════"
echo ""

# Function to find repository root
find_repo_root() {
    local dir="$1"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.git" ] || [ -d "$dir/.specify" ]; then
            echo "$dir"
            return 0
        fi
        dir="$(dirname "$dir")"
    done
    return 1
}

# Get repository root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if git rev-parse --show-toplevel >/dev/null 2>&1; then
    REPO_ROOT=$(git rev-parse --show-toplevel)
else
    REPO_ROOT="$(find_repo_root "$SCRIPT_DIR")"
    if [ -z "$REPO_ROOT" ]; then
        echo "❌ Error: Could not determine repository root"
        exit 1
    fi
fi

SPECIFY_DIR="$REPO_ROOT/.specify"
TEMPLATES_DIR="$REPO_ROOT/templates"

echo "Repository root: $REPO_ROOT"
echo ""

# Check if we're in a spec-kit repo (templates should exist)
if [ ! -d "$TEMPLATES_DIR" ]; then
    echo "❌ Error: This doesn't appear to be the spec-kit repository"
    echo "   Expected to find: $TEMPLATES_DIR"
    exit 1
fi

# Check if target project has .specify directory
if [ ! -d "$SPECIFY_DIR" ]; then
    echo "❌ Error: No .specify directory found"
    echo "   This script should be run from a spec-kit initialized project"
    exit 1
fi

echo "Files to be added/updated:"
echo "  ✓ scripts/bash/fetch-azure-issue.sh"
echo "  ✓ scripts/powershell/fetch-azure-issue.ps1"
echo "  ✓ templates/commands/startIssue.md"
echo "  ✓ templates/config-template.json"
echo "  ✓ .specify-config.example.json"
echo ""

read -p "Continue with update? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Update cancelled"
    exit 0
fi

echo ""
echo "Updating files..."

# Copy scripts
mkdir -p "$SPECIFY_DIR/scripts/bash"
mkdir -p "$SPECIFY_DIR/scripts/powershell"

if [ -f "$SCRIPT_DIR/fetch-azure-issue.sh" ]; then
    cp "$SCRIPT_DIR/fetch-azure-issue.sh" "$SPECIFY_DIR/scripts/bash/"
    chmod +x "$SPECIFY_DIR/scripts/bash/fetch-azure-issue.sh"
    echo "✓ Copied fetch-azure-issue.sh"
else
    echo "⚠ Warning: fetch-azure-issue.sh not found"
fi

if [ -f "$SCRIPT_DIR/../powershell/fetch-azure-issue.ps1" ]; then
    cp "$SCRIPT_DIR/../powershell/fetch-azure-issue.ps1" "$SPECIFY_DIR/scripts/powershell/"
    echo "✓ Copied fetch-azure-issue.ps1"
else
    echo "⚠ Warning: fetch-azure-issue.ps1 not found"
fi

# Copy command template
mkdir -p "$SPECIFY_DIR/templates/commands"

if [ -f "$TEMPLATES_DIR/commands/startIssue.md" ]; then
    cp "$TEMPLATES_DIR/commands/startIssue.md" "$SPECIFY_DIR/templates/commands/"
    echo "✓ Copied startIssue.md command template"
else
    echo "⚠ Warning: startIssue.md not found"
fi

# Copy config template
if [ -f "$TEMPLATES_DIR/config-template.json" ]; then
    cp "$TEMPLATES_DIR/config-template.json" "$SPECIFY_DIR/templates/"
    echo "✓ Copied config-template.json"
else
    echo "⚠ Warning: config-template.json not found"
fi

# Copy example config to root
if [ -f "$REPO_ROOT/.specify-config.example.json" ]; then
    cp "$REPO_ROOT/.specify-config.example.json" "$REPO_ROOT/"
    echo "✓ Copied .specify-config.example.json"
else
    echo "⚠ Warning: .specify-config.example.json not found"
fi

# Update .gitignore if needed
GITIGNORE="$REPO_ROOT/.gitignore"
if [ -f "$GITIGNORE" ]; then
    if ! grep -q ".specify/temp/" "$GITIGNORE"; then
        echo "" >> "$GITIGNORE"
        echo "# Spec Kit Azure DevOps integration temp files" >> "$GITIGNORE"
        echo ".specify/temp/" >> "$GITIGNORE"
        echo "✓ Updated .gitignore"
    else
        echo "✓ .gitignore already up to date"
    fi
else
    echo "⚠ Warning: .gitignore not found"
fi

# Update specify.md template to include Azure DevOps integration
SPECIFY_TEMPLATE="$SPECIFY_DIR/templates/commands/specify.md"
if [ -f "$SPECIFY_TEMPLATE" ]; then
    if grep -q "Azure DevOps Integration" "$SPECIFY_TEMPLATE"; then
        echo "✓ specify.md template already includes Azure DevOps integration"
    else
        echo "⚠ Warning: specify.md template needs manual update"
        echo "   See: templates/commands/specify.md for the updated version"
    fi
else
    echo "⚠ Warning: specify.md template not found"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Update Complete!"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo "  1. Create config file: cp .specify-config.example.json .specify/config.json"
echo "  2. Edit .specify/config.json with your Azure DevOps organization and project"
echo "  3. Set authentication: export AZURE_DEVOPS_PAT='your-token'"
echo "  4. Test: /speckit.startIssue <work-item-id>"
echo ""
echo "For detailed setup instructions, see:"
echo "  docs/azure-devops-integration.md"
echo "  docs/config-setup.md"
echo ""
