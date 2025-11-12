# Quick Update Guide - Azure DevOps Integration

Since the new Azure DevOps integration features are not yet part of a GitHub release, you need to manually copy the files from this repository to your project.

## Quick Steps

```bash
# 1. Navigate to your spec-kit project
cd /path/to/your/project

# 2. Set the path to this spec-kit repository
SPEC_KIT_REPO="/Users/andreasbom/Code/AzureRepos/spec-kit"

# 3. Copy Azure DevOps scripts
mkdir -p .specify/scripts/bash
mkdir -p .specify/scripts/powershell
cp "$SPEC_KIT_REPO/scripts/bash/fetch-azure-issue.sh" .specify/scripts/bash/
cp "$SPEC_KIT_REPO/scripts/powershell/fetch-azure-issue.ps1" .specify/scripts/powershell/
chmod +x .specify/scripts/bash/fetch-azure-issue.sh

# 4. Copy command template
mkdir -p .specify/templates/commands
cp "$SPEC_KIT_REPO/templates/commands/startIssue.md" .specify/templates/commands/

# 5. Copy and update specify.md template with Azure DevOps integration
cp "$SPEC_KIT_REPO/templates/commands/specify.md" .specify/templates/commands/

# 6. Copy config templates
mkdir -p .specify/templates
cp "$SPEC_KIT_REPO/templates/config-template.json" .specify/templates/
cp "$SPEC_KIT_REPO/.specify-config.example.json" .

# 7. Update .gitignore
if ! grep -q ".specify/temp/" .gitignore 2>/dev/null; then
    echo "" >> .gitignore
    echo "# Spec Kit Azure DevOps integration" >> .gitignore
    echo ".specify/temp/" >> .gitignore
fi

echo "✓ Azure DevOps integration files copied!"
echo ""
echo "Next steps:"
echo "  1. cp .specify-config.example.json .specify/config.json"
echo "  2. Edit .specify/config.json with your Azure DevOps org and project"
echo "  3. export AZURE_DEVOPS_PAT='your-token'"
echo "  4. Test with: /speckit.startIssue <work-item-id>"
```

## Verification

Check that the files are in place:

```bash
ls -la .specify/scripts/bash/fetch-azure-issue.sh
ls -la .specify/scripts/powershell/fetch-azure-issue.ps1
ls -la .specify/templates/commands/startIssue.md
ls -la .specify-config.example.json
```

All files should exist.

## Test the Integration

```bash
# Start your AI agent (e.g., Claude)
claude

# In the agent, the new command should appear
/speckit.startIssue --help
```

If the command doesn't appear, restart your AI agent.

## Configuration

1. **Create config file:**
   ```bash
   cp .specify-config.example.json .specify/config.json
   ```

2. **Edit `.specify/config.json`:**
   ```json
   {
     "azureDevOps": {
       "enabled": true,
       "organization": "your-org",
       "project": "your-project"
     }
   }
   ```

3. **Set authentication:**
   ```bash
   export AZURE_DEVOPS_PAT="your-personal-access-token"
   ```

See [docs/azure-devops-integration.md](docs/azure-devops-integration.md) for detailed setup instructions.
