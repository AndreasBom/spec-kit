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
   - Check if `.specify/config.json` exists
   - If not, create it by asking the user for:
     - Azure DevOps organization name
     - Azure DevOps project name

   Example config structure:
   ```json
   {
     "azureDevOps": {
       "organization": "your-org",
       "project": "your-project"
     }
   }
   ```

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