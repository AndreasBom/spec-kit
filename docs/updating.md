# Updating Spec Kit in Existing Projects

This guide explains how to update your existing Spec Kit project with new features without losing your existing data.

## Overview

When Spec Kit releases new features (like Azure DevOps integration), you have several options to update your existing project:

1. **Option 1: Use `specify init --here --force`** (Recommended for most updates)
2. **Option 2: Manual file copying** (For specific features only)
3. **Option 3: Selective merge** (For advanced users)

## Option 1: Using `specify init --here --force`

This is the safest and most comprehensive way to update your project. The `--here` flag tells Spec Kit to merge new files into your current directory instead of creating a new one.

### How it Works

The `specify init --here` command:
- ✅ Preserves all your existing content in `.specify/`
- ✅ Merges new files with existing files
- ✅ Updates templates with new features
- ✅ Keeps your existing specs, plans, and tasks
- ✅ Merges JSON files intelligently (like `.vscode/settings.json`)
- ✅ Adds new command templates

### Steps

```bash
# 1. Make sure you're in your project directory
cd /path/to/your/project

# 2. Commit any uncommitted changes (recommended)
git add .
git commit -m "Save work before updating Spec Kit"

# 3. Update Spec Kit to the latest version
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git

# 4. Merge the latest templates into your project
specify init --here --force --ai <your-ai-agent>

# For example, if you're using Claude:
specify init --here --force --ai claude
```

### What Gets Updated

- **New command templates** added to `.specify/templates/commands/`
- **New scripts** added to `.specify/scripts/`
- **Template updates** merged into existing templates
- **Config templates** added if they don't exist
- **Documentation** updated

### What Stays the Same (Protected Files)

- **Your specs** in `specs/` directory
- **Your constitution** in `.specify/memory/constitution.md` ✅ **Protected - never overwritten**
- **Your branches** and git history
- **Your work item data** in `.specify/temp/` (if it exists)
- **Your custom modifications** to templates
- **.vscode/settings.json** ✅ **Merged instead of overwritten**

**Protected Files**: The following files are automatically protected during updates:
- `.specify/memory/constitution.md` - Your existing constitution is preserved (only copied if file is empty or doesn't exist)
- `.vscode/settings.json` - Settings are merged intelligently

## Option 2: Manual File Copying (Azure DevOps Integration Only)

If you only want to add the Azure DevOps integration without running the full update, you can manually copy the required files.

### Using the Update Script

We provide a helper script for this:

```bash
# From the spec-kit repository root
./scripts/bash/update-azure-devops-integration.sh
```

This script will:
1. Copy new Azure DevOps scripts to your `.specify/scripts/` directory
2. Add the `/speckit.startIssue` command template
3. Add config templates
4. Update your `.gitignore`

### Manual Copying

If you prefer to copy files manually:

```bash
# 1. Copy Azure DevOps scripts
cp /path/to/spec-kit/scripts/bash/fetch-azure-issue.sh .specify/scripts/bash/
cp /path/to/spec-kit/scripts/powershell/fetch-azure-issue.ps1 .specify/scripts/powershell/
chmod +x .specify/scripts/bash/fetch-azure-issue.sh

# 2. Copy command template
cp /path/to/spec-kit/templates/commands/startIssue.md .specify/templates/commands/

# 3. Copy config templates
cp /path/to/spec-kit/templates/config-template.json .specify/templates/
cp /path/to/spec-kit/.specify-config.example.json .

# 4. Update .gitignore
echo ".specify/temp/" >> .gitignore
```

### Update specify.md Template

The `/speckit.specify` command template needs to be updated to use Azure DevOps work item data. You can either:

1. **Copy the updated template:**
   ```bash
   cp /path/to/spec-kit/templates/commands/specify.md .specify/templates/commands/
   ```

2. **Or manually merge** the Azure DevOps integration section from the updated template into your existing one.

## Option 3: Selective Merge (Advanced)

For advanced users who want fine-grained control:

### Step 1: Download Latest Template

```bash
# Get the latest release
cd /tmp
git clone https://github.com/github/spec-kit.git spec-kit-latest
cd spec-kit-latest
```

### Step 2: Identify Changes

```bash
# Compare your project with the latest template
diff -r /path/to/your/project/.specify /tmp/spec-kit-latest/templates/
```

### Step 3: Selectively Merge

Use a merge tool like `meld`, `kdiff3`, or VSCode to selectively merge changes:

```bash
# Using VSCode
code --diff /path/to/your/project/.specify /tmp/spec-kit-latest/templates/
```

## After Updating

Regardless of which method you used, after updating:

### 1. Verify the Update

Check that new files are in place:

```bash
# Check for Azure DevOps integration files
ls -la .specify/scripts/bash/fetch-azure-issue.sh
ls -la .specify/templates/commands/startIssue.md
ls -la .specify-config.example.json
```

### 2. Test New Commands

Try the new `/speckit.startIssue` command:

```bash
# Start your AI agent
claude  # or your preferred AI agent

# In the agent, test the command
/speckit.startIssue --help
```

### 3. Configure Azure DevOps (if using that feature)

```bash
# Create config file
cp .specify-config.example.json .specify/config.json

# Edit with your details
# organization: your-org
# project: your-project
```

See [Configuration Setup Guide](./config-setup.md) for detailed instructions.

## Troubleshooting

### "Directory not empty" Warning

This is normal when using `--here`. Use `--force` to skip the confirmation:

```bash
specify init --here --force --ai claude
```

### Lost Customizations

If you've customized templates and they got overwritten:

```bash
# Restore from git history
git checkout HEAD -- .specify/templates/commands/yourfile.md

# Or view the diff
git diff .specify/templates/
```

### Merge Conflicts

If files have conflicts after merging:

```bash
# Check what changed
git diff .specify/

# Manually resolve conflicts in affected files
# Then commit the merge
git add .
git commit -m "Merged Spec Kit updates"
```

### Command Not Found

If `/speckit.startIssue` doesn't appear:

1. Check the file exists: `ls .specify/templates/commands/startIssue.md`
2. Restart your AI agent
3. Verify you're in the project root directory

## Version History

To see what changed between versions:

```bash
# View Spec Kit changelog
cat /path/to/spec-kit/CHANGELOG.md

# Or on GitHub
# https://github.com/github/spec-kit/blob/main/CHANGELOG.md
```

## Best Practices

1. **Always commit before updating** to make it easy to roll back
2. **Use `--force` with `--here`** to skip confirmation prompts
3. **Test in a feature branch first** if you're concerned about disruption
4. **Read the changelog** to see what's new
5. **Update regularly** to get the latest features and bug fixes

## Getting Help

If you encounter issues:

1. Check the [Troubleshooting](#troubleshooting) section above
2. Review the [Configuration Setup Guide](./config-setup.md)
3. Open an issue at https://github.com/github/spec-kit/issues

## Example: Complete Update Workflow

```bash
# 1. Save current work
git add .
git commit -m "WIP: before Spec Kit update"

# 2. Update Spec Kit CLI
uv tool install specify-cli --force --from git+https://github.com/github/spec-kit.git

# 3. Create a feature branch for the update (optional but recommended)
git checkout -b update-spec-kit

# 4. Merge latest templates
specify init --here --force --ai claude

# 5. Review changes
git diff

# 6. Configure new features (if any)
cp .specify-config.example.json .specify/config.json
# Edit config.json with your settings

# 7. Test the update
claude
# Try new commands like /speckit.startIssue

# 8. Commit the update
git add .
git commit -m "Updated Spec Kit with Azure DevOps integration"

# 9. Merge back to main branch
git checkout main
git merge update-spec-kit
```

This workflow ensures you can easily roll back if something goes wrong.
