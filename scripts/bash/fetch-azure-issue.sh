#!/usr/bin/env bash

set -e

# Usage: fetch-azure-issue.sh <work-item-id> [--json]
# Fetches Azure DevOps work item information and stores it for use with /speckit.specify

WORK_ITEM_ID=""
JSON_MODE=false

# Parse arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --json)
            JSON_MODE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 <work-item-id> [--json]"
            echo ""
            echo "Fetches Azure DevOps work item information for use with speckit commands"
            echo ""
            echo "Options:"
            echo "  --json              Output in JSON format"
            echo "  --help, -h          Show this help message"
            echo ""
            echo "Required environment variables (one of):"
            echo "  AZURE_DEVOPS_PAT    Personal Access Token (preferred)"
            echo "  Or use 'az login' for Azure CLI authentication"
            echo ""
            echo "Required configuration (.specify/config.json):"
            echo "  - organization: Azure DevOps organization name"
            echo "  - project: Azure DevOps project name"
            echo ""
            echo "Example:"
            echo "  $0 12345"
            exit 0
            ;;
        *)
            if [ -z "$WORK_ITEM_ID" ]; then
                WORK_ITEM_ID="$1"
            else
                echo "Error: Unexpected argument '$1'" >&2
                exit 1
            fi
            shift
            ;;
    esac
done

if [ -z "$WORK_ITEM_ID" ]; then
    echo "Error: Work item ID is required" >&2
    echo "Usage: $0 <work-item-id> [--json]" >&2
    exit 1
fi

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
        echo "Error: Could not determine repository root" >&2
        exit 1
    fi
fi

SPECIFY_DIR="$REPO_ROOT/.specify"
CONFIG_FILE="$SPECIFY_DIR/config.json"
TEMP_DIR="$SPECIFY_DIR/temp"
ISSUE_FILE="$TEMP_DIR/current-issue.json"

# Create temp directory if it doesn't exist
mkdir -p "$TEMP_DIR"

# Read configuration
if [ ! -f "$CONFIG_FILE" ]; then
    echo "" >&2
    echo "❌ Configuration file not found!" >&2
    echo "" >&2
    echo "The file $CONFIG_FILE is missing." >&2
    echo "" >&2
    echo "Please run the /speckit.startIssue command in your AI agent first." >&2
    echo "The agent will provide step-by-step setup instructions." >&2
    echo "" >&2
    echo "Quick setup:" >&2
    echo "  1. cp .specify-config.example.json .specify/config.json" >&2
    echo "  2. Edit .specify/config.json with your Azure DevOps org and project" >&2
    echo "  3. Set AZURE_DEVOPS_PAT environment variable" >&2
    echo "" >&2
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed" >&2
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)" >&2
    exit 1
fi

# Extract configuration
AZURE_ORG=$(jq -r '.azureDevOps.organization // empty' "$CONFIG_FILE")
AZURE_PROJECT=$(jq -r '.azureDevOps.project // empty' "$CONFIG_FILE")

if [ -z "$AZURE_ORG" ] || [ -z "$AZURE_PROJECT" ]; then
    echo "" >&2
    echo "❌ Azure DevOps configuration incomplete!" >&2
    echo "" >&2
    echo "The file $CONFIG_FILE exists but is missing required fields." >&2
    echo "" >&2
    echo "Please edit $CONFIG_FILE and add:" >&2
    echo '  "azureDevOps": {' >&2
    echo '    "organization": "your-org",  ← Fill this in' >&2
    echo '    "project": "your-project"     ← Fill this in' >&2
    echo '  }' >&2
    echo "" >&2
    echo "Example: If your Azure DevOps URL is https://dev.azure.com/contoso/MyProject" >&2
    echo "  organization: contoso" >&2
    echo "  project: MyProject" >&2
    echo "" >&2
    exit 1
fi

# Determine authentication method
AUTH_HEADER=""
if [ -n "${AZURE_DEVOPS_PAT:-}" ]; then
    # Use PAT authentication
    AUTH_HEADER="Authorization: Basic $(echo -n :${AZURE_DEVOPS_PAT} | base64)"
    if [ "$JSON_MODE" = false ]; then
        echo "[specify] Using PAT authentication" >&2
    fi
elif command -v az &> /dev/null; then
    # Try Azure CLI authentication
    if [ "$JSON_MODE" = false ]; then
        echo "[specify] Attempting Azure CLI authentication..." >&2
    fi

    # Get Azure CLI token
    TOKEN=$(az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv 2>/dev/null || echo "")

    if [ -z "$TOKEN" ]; then
        echo "Error: Azure CLI authentication failed. Please run 'az login' or set AZURE_DEVOPS_PAT" >&2
        exit 1
    fi

    AUTH_HEADER="Authorization: Bearer $TOKEN"
else
    echo "Error: No authentication method available" >&2
    echo "Please either:" >&2
    echo "  1. Set AZURE_DEVOPS_PAT environment variable with your Personal Access Token" >&2
    echo "  2. Install and login with Azure CLI (az login)" >&2
    exit 1
fi

# Construct API URL
API_URL="https://dev.azure.com/${AZURE_ORG}/${AZURE_PROJECT}/_apis/wit/workitems/${WORK_ITEM_ID}?api-version=7.1"

# Fetch work item from Azure DevOps
if [ "$JSON_MODE" = false ]; then
    echo "[specify] Fetching work item $WORK_ITEM_ID from Azure DevOps..." >&2
fi

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" -H "$AUTH_HEADER" "$API_URL")
HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n 1)

if [ "$HTTP_CODE" != "200" ]; then
    echo "Error: Failed to fetch work item (HTTP $HTTP_CODE)" >&2
    if [ "$JSON_MODE" = false ]; then
        echo "$HTTP_BODY" | jq -r '.message // .error.message // "Unknown error"' >&2
    fi
    exit 1
fi

# Extract common fields
WORK_ITEM_TYPE=$(echo "$HTTP_BODY" | jq -r '.fields["System.WorkItemType"] // "Unknown"')
TITLE=$(echo "$HTTP_BODY" | jq -r '.fields["System.Title"] // ""')
STATE=$(echo "$HTTP_BODY" | jq -r '.fields["System.State"] // "Unknown"')
ASSIGNED_TO=$(echo "$HTTP_BODY" | jq -r '.fields["System.AssignedTo"].displayName // "Unassigned"')

# Get AI Prompt custom field
AI_PROMPT=$(echo "$HTTP_BODY" | jq -r '.fields["Custom.AIPrompt"] // ""')

# Extract fields based on work item type
if [ "$WORK_ITEM_TYPE" = "Bug" ]; then
    # Bug: Repro Steps, System Info
    DESCRIPTION=$(echo "$HTTP_BODY" | jq -r '.fields["Microsoft.VSTS.TCM.ReproSteps"] // ""')
    SYSTEM_INFO=$(echo "$HTTP_BODY" | jq -r '.fields["Microsoft.VSTS.TCM.SystemInfo"] // ""')
    ACCEPTANCE_CRITERIA=""

    # Determine prompt and context for Bug
    if [ -n "$AI_PROMPT" ] && [ "$AI_PROMPT" != "null" ]; then
        PROMPT="$AI_PROMPT"
        CONTEXT="$DESCRIPTION"
        ADDITIONAL_CONTEXT="$SYSTEM_INFO"
    else
        PROMPT="$DESCRIPTION"
        CONTEXT=""
        ADDITIONAL_CONTEXT="$SYSTEM_INFO"
    fi
else
    # User Story, Task, Feature, etc: Description, Acceptance Criteria
    DESCRIPTION=$(echo "$HTTP_BODY" | jq -r '.fields["System.Description"] // ""')
    ACCEPTANCE_CRITERIA=$(echo "$HTTP_BODY" | jq -r '.fields["Microsoft.VSTS.Common.AcceptanceCriteria"] // ""')
    SYSTEM_INFO=""

    # Determine prompt and context for User Story/Feature/Task
    if [ -n "$AI_PROMPT" ] && [ "$AI_PROMPT" != "null" ]; then
        PROMPT="$AI_PROMPT"
        CONTEXT="$DESCRIPTION"
        ADDITIONAL_CONTEXT="$ACCEPTANCE_CRITERIA"
    else
        PROMPT="$DESCRIPTION"
        CONTEXT=""
        ADDITIONAL_CONTEXT="$ACCEPTANCE_CRITERIA"
    fi
fi

# Create issue data JSON with new structure
ISSUE_DATA=$(jq -n \
    --arg id "$WORK_ITEM_ID" \
    --arg type "$WORK_ITEM_TYPE" \
    --arg title "$TITLE" \
    --arg state "$STATE" \
    --arg assignedTo "$ASSIGNED_TO" \
    --arg prompt "$PROMPT" \
    --arg context "$CONTEXT" \
    --arg additionalContext "$ADDITIONAL_CONTEXT" \
    --arg description "$DESCRIPTION" \
    --arg acceptanceCriteria "$ACCEPTANCE_CRITERIA" \
    --arg systemInfo "$SYSTEM_INFO" \
    --arg aiPrompt "$AI_PROMPT" \
    '{
        id: $id,
        type: $type,
        title: $title,
        state: $state,
        assignedTo: $assignedTo,
        prompt: $prompt,
        context: $context,
        additionalContext: $additionalContext,
        rawFields: {
            description: $description,
            acceptanceCriteria: $acceptanceCriteria,
            systemInfo: $systemInfo,
            aiPrompt: $aiPrompt
        },
        fetchedAt: (now | todate)
    }')

# Save to temp file
echo "$ISSUE_DATA" > "$ISSUE_FILE"

# Update work item state to "Active" if not already
if [ "$STATE" != "Active" ]; then
    if [ "$JSON_MODE" = false ]; then
        echo "[specify] Updating work item state to Active..." >&2
    fi

    # Construct PATCH request body
    PATCH_BODY='[
        {
            "op": "add",
            "path": "/fields/System.State",
            "value": "Active"
        }
    ]'

    # Make PATCH request
    PATCH_RESPONSE=$(curl -s -w "\n%{http_code}" \
        -X PATCH \
        -H "$AUTH_HEADER" \
        -H "Content-Type: application/json-patch+json" \
        -d "$PATCH_BODY" \
        "$API_URL")

    PATCH_BODY_RESPONSE=$(echo "$PATCH_RESPONSE" | sed '$d')
    PATCH_CODE=$(echo "$PATCH_RESPONSE" | tail -n 1)

    if [ "$PATCH_CODE" = "200" ]; then
        if [ "$JSON_MODE" = false ]; then
            echo "[specify] ✓ State updated: $STATE → Active" >&2
        fi
        STATE="Active"

        # Update the saved JSON with new state
        ISSUE_DATA=$(echo "$ISSUE_DATA" | jq '.state = "Active"')
        echo "$ISSUE_DATA" > "$ISSUE_FILE"
    else
        if [ "$JSON_MODE" = false ]; then
            echo "[specify] ⚠ Warning: Could not update state (HTTP $PATCH_CODE)" >&2
        fi
    fi
fi

if $JSON_MODE; then
    echo "$ISSUE_DATA"
else
    echo ""
    echo "✓ Work item fetched successfully!"
    echo ""
    echo "ID:    $WORK_ITEM_ID"
    echo "Type:  $WORK_ITEM_TYPE"
    echo "Title: $TITLE"
    echo "State: $STATE"
    echo ""

    # Show what will be used as prompt
    if [ -n "$AI_PROMPT" ] && [ "$AI_PROMPT" != "null" ]; then
        echo "Prompt source: AI Prompt (custom field)"
        if [ "$WORK_ITEM_TYPE" = "Bug" ]; then
            echo "Context:       Repro Steps + System Info"
        else
            echo "Context:       Description + Acceptance Criteria"
        fi
    else
        if [ "$WORK_ITEM_TYPE" = "Bug" ]; then
            echo "Prompt source: Repro Steps"
            echo "Context:       System Info"
        else
            echo "Prompt source: Description"
            echo "Context:       Acceptance Criteria"
        fi
    fi

    echo ""
    echo "Saved to: $ISSUE_FILE"
    echo ""
    echo "Next step: Run /speckit.specify to create the specification"
fi