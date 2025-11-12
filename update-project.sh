#!/usr/bin/env bash

set -e

# Quick update script to add Azure DevOps integration to an existing spec-kit project
# Usage: ./update-project.sh /path/to/your/project

if [ $# -eq 0 ]; then
    echo "Usage: $0 /path/to/your/project"
    echo ""
    echo "Example:"
    echo "  $0 ~/myproject"
    exit 1
fi

PROJECT_PATH="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "═══════════════════════════════════════════════════════════"
echo "  Azure DevOps Integration - Quick Update"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Source: $SCRIPT_DIR"
echo "Target: $PROJECT_PATH"
echo ""

# Verify project exists
if [ ! -d "$PROJECT_PATH" ]; then
    echo "❌ Error: Project directory not found: $PROJECT_PATH"
    exit 1
fi

# Verify it's a spec-kit project
if [ ! -d "$PROJECT_PATH/.specify" ]; then
    echo "❌ Error: Not a spec-kit project (no .specify directory found)"
    echo "   Run 'specify init' first in the target directory"
    exit 1
fi

echo "Files to be copied:"
echo "  ✓ scripts/bash/fetch-azure-issue.sh"
echo "  ✓ scripts/powershell/fetch-azure-issue.ps1"
echo "  ✓ templates/commands/startIssue.md"
echo "  ✓ templates/commands/specify.md (updated)"
echo "  ✓ templates/config-template.json"
echo "  ✓ .specify-config.example.json"
echo ""

read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo "Copying files..."

# Create directories
mkdir -p "$PROJECT_PATH/.specify/scripts/bash"
mkdir -p "$PROJECT_PATH/.specify/scripts/powershell"
mkdir -p "$PROJECT_PATH/.specify/templates/commands"
mkdir -p "$PROJECT_PATH/.specify/templates"

# Copy scripts
if [ -f "$SCRIPT_DIR/scripts/bash/fetch-azure-issue.sh" ]; then
    cp "$SCRIPT_DIR/scripts/bash/fetch-azure-issue.sh" "$PROJECT_PATH/.specify/scripts/bash/"
    chmod +x "$PROJECT_PATH/.specify/scripts/bash/fetch-azure-issue.sh"
    echo "  ✓ fetch-azure-issue.sh"
else
    echo "  ⚠ fetch-azure-issue.sh not found"
fi

if [ -f "$SCRIPT_DIR/scripts/powershell/fetch-azure-issue.ps1" ]; then
    cp "$SCRIPT_DIR/scripts/powershell/fetch-azure-issue.ps1" "$PROJECT_PATH/.specify/scripts/powershell/"
    echo "  ✓ fetch-azure-issue.ps1"
else
    echo "  ⚠ fetch-azure-issue.ps1 not found"
fi

# Copy command templates
if [ -f "$SCRIPT_DIR/templates/commands/startIssue.md" ]; then
    cp "$SCRIPT_DIR/templates/commands/startIssue.md" "$PROJECT_PATH/.specify/templates/commands/"
    echo "  ✓ startIssue.md"
else
    echo "  ⚠ startIssue.md not found"
fi

if [ -f "$SCRIPT_DIR/templates/commands/specify.md" ]; then
    # Backup existing specify.md first
    if [ -f "$PROJECT_PATH/.specify/templates/commands/specify.md" ]; then
        cp "$PROJECT_PATH/.specify/templates/commands/specify.md" "$PROJECT_PATH/.specify/templates/commands/specify.md.backup"
        echo "  ℹ Backed up existing specify.md to specify.md.backup"
    fi
    cp "$SCRIPT_DIR/templates/commands/specify.md" "$PROJECT_PATH/.specify/templates/commands/"
    echo "  ✓ specify.md (updated with Azure DevOps integration)"
else
    echo "  ⚠ specify.md not found"
fi

# Copy config templates
if [ -f "$SCRIPT_DIR/templates/config-template.json" ]; then
    cp "$SCRIPT_DIR/templates/config-template.json" "$PROJECT_PATH/.specify/templates/"
    echo "  ✓ config-template.json"
else
    echo "  ⚠ config-template.json not found"
fi

if [ -f "$SCRIPT_DIR/.specify-config.example.json" ]; then
    cp "$SCRIPT_DIR/.specify-config.example.json" "$PROJECT_PATH/"
    echo "  ✓ .specify-config.example.json"
else
    echo "  ⚠ .specify-config.example.json not found"
fi

# Update .gitignore
GITIGNORE="$PROJECT_PATH/.gitignore"
if [ -f "$GITIGNORE" ]; then
    if ! grep -q ".specify/temp/" "$GITIGNORE"; then
        echo "" >> "$GITIGNORE"
        echo "# Spec Kit Azure DevOps integration" >> "$GITIGNORE"
        echo ".specify/temp/" >> "$GITIGNORE"
        echo "  ✓ Updated .gitignore"
    else
        echo "  ✓ .gitignore already up to date"
    fi
else
    echo "  ⚠ .gitignore not found"
fi

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  Update Complete! ✓"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "Next steps:"
echo ""
echo "  1. Configure Azure DevOps:"
echo "     cd $PROJECT_PATH"
echo "     cp .specify-config.example.json .specify/config.json"
echo "     # Edit .specify/config.json with your org and project"
echo ""
echo "  2. Set authentication:"
echo "     export AZURE_DEVOPS_PAT='your-token'"
echo ""
echo "  3. Test the integration:"
echo "     claude  # or your AI agent"
echo "     /speckit.startIssue 12345"
echo ""
echo "For detailed setup, see:"
echo "  $SCRIPT_DIR/docs/azure-devops-integration.md"
echo "  $SCRIPT_DIR/docs/config-setup.md"
echo ""
