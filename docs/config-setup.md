# Spec Kit Configuration Guide

This guide explains how to configure Spec Kit for your project.

## Configuration File Location

The configuration file should be placed at:
```
.specify/config.json
```

## Quick Setup

### Step 1: Create Configuration File

Copy the example configuration:

```bash
# From your project root
mkdir -p .specify
cp .specify-config.example.json .specify/config.json
```

Or create it manually:

```json
{
  "azureDevOps": {
    "enabled": true,
    "organization": "your-org",
    "project": "your-project",
    "apiVersion": "7.1"
  },
  "branchNaming": {
    "useWorkItemId": true
  },
  "features": {
    "autoArchiveIssues": true
  }
}
```

### Step 2: Fill in Azure DevOps Details

Find your organization and project from your Azure DevOps URL:

**Example URL:**
```
https://dev.azure.com/contoso/MyProject/_workitems
```

**Configuration:**
```json
{
  "azureDevOps": {
    "organization": "contoso",
    "project": "MyProject"
  }
}
```

### Step 3: Set Up Authentication

Choose one of the following methods:

#### Method 1: Personal Access Token (Recommended)

1. **Create a PAT in Azure DevOps:**
   - Navigate to: Azure DevOps → User Settings (top right) → Personal Access Tokens
   - Click "New Token"
   - Name: `Spec Kit Integration`
   - Organization: Select your organization or "All accessible organizations"
   - Scopes: **Work Items (Read)** ✓
   - Expiration: Set as needed (recommend 90 days)
   - Click "Create"
   - **Copy the token immediately** (you won't see it again)

2. **Set the environment variable:**

   **Bash/Zsh (Linux/macOS):**
   ```bash
   export AZURE_DEVOPS_PAT="your-pat-token-here"
   ```

   **PowerShell (Windows):**
   ```powershell
   $env:AZURE_DEVOPS_PAT = "your-pat-token-here"
   ```

   **Make it persistent (Linux/macOS):**
   ```bash
   echo 'export AZURE_DEVOPS_PAT="your-pat-token-here"' >> ~/.bashrc
   source ~/.bashrc
   ```

   **Make it persistent (Windows PowerShell):**
   ```powershell
   [System.Environment]::SetEnvironmentVariable('AZURE_DEVOPS_PAT', 'your-pat-token-here', 'User')
   ```

#### Method 2: Azure CLI

If you have Azure CLI installed:

```bash
az login
```

The scripts will automatically use Azure CLI credentials if `AZURE_DEVOPS_PAT` is not set.

## Configuration Options

### Azure DevOps Settings

```json
{
  "azureDevOps": {
    "enabled": true,           // Enable/disable Azure DevOps integration
    "organization": "string",  // Your Azure DevOps organization name
    "project": "string",       // Your Azure DevOps project name
    "apiVersion": "7.1"        // Azure DevOps API version (default: 7.1)
  }
}
```

### Branch Naming Settings

```json
{
  "branchNaming": {
    "useWorkItemId": true  // true: use work item ID (12345-title)
                          // false: use auto-increment (001-title)
  }
}
```

**Examples:**

With `useWorkItemId: true`:
- Work item #12345 → Branch: `12345-user-auth`
- Work item #67890 → Branch: `67890-fix-bug`

With `useWorkItemId: false`:
- Any work item → Branch: `001-user-auth` (auto-incremented)

### Feature Flags

```json
{
  "features": {
    "autoArchiveIssues": true  // Archive work item data after spec creation
  }
}
```

When `autoArchiveIssues` is `true`, the work item data in `.specify/temp/current-issue.json` is automatically renamed to `last-issue.json` after running `/speckit.specify`. This prevents accidentally reusing the same work item for multiple specs.

## Complete Configuration Example

```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "description": "Spec Kit configuration for Contoso MyProject",

  "azureDevOps": {
    "enabled": true,
    "organization": "contoso",
    "project": "MyProject",
    "apiVersion": "7.1"
  },

  "branchNaming": {
    "useWorkItemId": true
  },

  "features": {
    "autoArchiveIssues": true
  }
}
```

## Verification

After setting up your configuration, verify it works:

```bash
# Test fetching a work item
/speckit.startIssue 12345
```

You should see output like:
```
✓ Work item fetched successfully!

ID:    12345
Type:  User Story
Title: Add user authentication system
State: Active

Saved to: .specify/temp/current-issue.json
```

## Troubleshooting

### Error: "Configuration file not found"

**Problem:**
```
Error: Configuration file not found at .specify/config.json
```

**Solution:**
Create the file:
```bash
mkdir -p .specify
cat > .specify/config.json << 'EOF'
{
  "azureDevOps": {
    "organization": "your-org",
    "project": "your-project"
  }
}
EOF
```

### Error: "No authentication method available"

**Problem:**
```
Error: No authentication method available
```

**Solution:**
Set up authentication:
```bash
export AZURE_DEVOPS_PAT="your-token"
# or
az login
```

### Error: "Azure DevOps organization and project must be configured"

**Problem:**
The config.json exists but `organization` or `project` fields are empty.

**Solution:**
Edit `.specify/config.json` and fill in the values:
```json
{
  "azureDevOps": {
    "organization": "contoso",  // ← Fill this in
    "project": "MyProject"      // ← Fill this in
  }
}
```

### Error: "Failed to fetch work item (HTTP 401)"

**Problem:**
Authentication failed.

**Solutions:**
1. Check PAT is set: `echo $AZURE_DEVOPS_PAT`
2. Verify PAT has "Work Items (Read)" scope
3. Check PAT hasn't expired
4. Try `az login` if using Azure CLI

### Error: "Failed to fetch work item (HTTP 404)"

**Problem:**
Work item not found.

**Solutions:**
1. Verify the work item ID exists
2. Check you have access to the work item
3. Verify organization and project names are correct

### Error: "jq is required but not installed"

**Problem:**
The bash script requires `jq` for JSON parsing.

**Solution:**
Install jq:
- **macOS:** `brew install jq`
- **Ubuntu/Debian:** `sudo apt-get install jq`
- **Windows (WSL):** `sudo apt-get install jq`

## Security Best Practices

1. **Never commit your PAT to git**
   - Use environment variables only
   - Add `.specify/temp/` to `.gitignore` (already included)

2. **Limit PAT permissions**
   - Only grant "Work Items (Read)" scope
   - No write permissions needed

3. **Set PAT expiration**
   - Use reasonable expiration dates (30-90 days)
   - Rotate tokens regularly

4. **Config file is safe to commit**
   - The `.specify/config.json` contains no secrets
   - Only organization and project names
   - Can be committed to version control

## Environment-Specific Configuration

For teams with multiple environments:

**Development:**
```json
{
  "azureDevOps": {
    "organization": "contoso-dev",
    "project": "MyProject-Dev"
  }
}
```

**Production:**
```json
{
  "azureDevOps": {
    "organization": "contoso",
    "project": "MyProject"
  }
}
```

Use different branches or separate repos for different environments.

## Next Steps

After configuration is complete:

1. Test the integration: `/speckit.startIssue 12345`
2. Create a specification: `/speckit.specify`
3. Continue with the workflow: `/speckit.plan`, `/speckit.tasks`, `/speckit.implement`

For more details, see:
- [Azure DevOps Integration Guide](./azure-devops-integration.md)
- [Spec Kit README](../README.md)
