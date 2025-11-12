---
description: Fetch Azure DevOps work item and prepare it for specification with /speckit.specify
scripts:
  sh: scripts/bash/fetch-azure-issue.sh "{ARGS}"
  ps: scripts/powershell/fetch-azure-issue.ps1 "{ARGS}"
---

## User Input

```text
$ARGUMENTS
```

You **MUST** consider the user input before proceeding (if not empty).

## Outline

The text the user typed after `/speckit.startIssue` in the triggering message **is** the Azure DevOps work item ID. Assume you always have it available in this conversation even if `{ARGS}` appears literally below. Do not ask the user to repeat it unless they provided an empty command.

Given the work item ID, do this:

1. **Validate work item ID**:
   - Check that the user provided a numeric work item ID
   - If empty or invalid, ERROR: "Please provide a valid Azure DevOps work item ID"

2. **Ensure configuration exists**:

   a. **Check if `.specify/config.json` exists**:
      ```bash
      ls -la .specify/config.json
      ```

   b. **If file does NOT exist**:
      - Inform the user they need to create the config file first
      - Display these step-by-step setup instructions:

      ```markdown
      ## Azure DevOps Setup Required

      The `.specify/config.json` file is missing. Please complete these steps first:

      ### Step 1: Create Configuration File

      ```bash
      # Copy the example config
      cp .specify-config.example.json .specify/config.json
      ```

      ### Step 2: Edit Configuration

      Open `.specify/config.json` and fill in your Azure DevOps details:

      ```json
      {
        "azureDevOps": {
          "enabled": true,
          "organization": "your-organization",
          "project": "your-project"
        }
      }
      ```

      **How to find your organization and project:**
      - Look at your Azure DevOps URL: `https://dev.azure.com/{organization}/{project}`
      - Example: If your URL is `https://dev.azure.com/contoso/MyProject`
        - organization: `contoso`
        - project: `MyProject`

      ### Step 3: Set Authentication

      Choose one authentication method:

      **Option A: Personal Access Token (Recommended)**
      ```bash
      export AZURE_DEVOPS_PAT="your-token-here"
      ```

      To create a PAT:
      1. Go to Azure DevOps → User Settings → Personal Access Tokens
      2. Click "New Token"
      3. Name: "Spec Kit Integration"
      4. Scope: **Work Items (Read)** ✓
      5. Copy the token

      **Option B: Azure CLI**
      ```bash
      az login
      ```

      ### Step 4: Try Again

      Once setup is complete, run:
      ```
      /speckit.startIssue {WORK_ITEM_ID}
      ```
      ```

      - **STOP HERE** - Do not proceed with the work item fetch
      - Exit and wait for the user to complete the setup

   c. **If file EXISTS**:
      - Read the config file to verify it has the required fields
      - Check that `azureDevOps.organization` and `azureDevOps.project` are not empty
      - If fields are empty or missing, show the same setup instructions as above

3. **Check authentication**:
   - Inform the user about authentication options:
     - **Option 1 (Recommended)**: Set `AZURE_DEVOPS_PAT` environment variable with a Personal Access Token
     - **Option 2**: Use Azure CLI authentication (requires `az login`)
   - The script will automatically try PAT first, then fall back to Azure CLI

4. **Run the fetch script**:
   - Execute `{SCRIPT}` with the work item ID
   - The script will:
     - Fetch the work item from Azure DevOps API
     - Extract: ID, Type, Title, Description, State, Assigned To, Acceptance Criteria
     - Save the data to `.specify/temp/current-issue.json`
   - Examples:
     - Bash: `scripts/bash/fetch-azure-issue.sh 12345`
     - PowerShell: `scripts/powershell/fetch-azure-issue.ps1 12345`

5. **Display work item information**:
   - Show the fetched work item details to the user:
     - Work Item ID
     - Type (User Story, Task, Bug, etc.)
     - Title
     - State
     - Description (if available)
     - Acceptance Criteria (if available)

6. **Guide next steps**:
   - Inform the user that the work item information has been saved
   - Explain that they should now run `/speckit.specify` to create the specification
   - The `/speckit.specify` command will automatically:
     - Use the work item title and description as the feature description
     - Create a branch named: `{work-item-id}-{sanitized-title}`
     - Include acceptance criteria in the specification

## Important Notes

- The work item data is stored in `.specify/temp/current-issue.json` and will be used by `/speckit.specify`
- If the user runs `/speckit.specify` without arguments after this command, it should automatically use the stored work item data
- The work item ID will become part of the branch name, making it easy to track which branch corresponds to which Azure DevOps work item
- Make sure to handle HTML formatting in the description and acceptance criteria fields (Azure DevOps stores these as HTML)

## Authentication Setup

### Personal Access Token (PAT)

To create a PAT:
1. Go to Azure DevOps → User Settings → Personal Access Tokens
2. Create a new token with "Work Items (Read)" scope
3. Set the environment variable:
   ```bash
   export AZURE_DEVOPS_PAT="your-pat-here"
   ```
   Or in PowerShell:
   ```powershell
   $env:AZURE_DEVOPS_PAT = "your-pat-here"
   ```

### Azure CLI

If Azure CLI is installed and configured:
```bash
az login
```

The script will automatically use the Azure CLI token as a fallback.

## Error Handling

If the script fails:
- **Configuration missing**: Create `.specify/config.json` with organization and project
- **Authentication failed**: Set `AZURE_DEVOPS_PAT` or run `az login`
- **Work item not found**: Verify the work item ID exists and you have access
- **Network errors**: Check your internet connection and Azure DevOps availability

## Example Workflow

```
User: /speckit.startIssue 12345