#!/usr/bin/env bash

# Debug script to troubleshoot Azure DevOps API issues

set -e

echo "=== Azure DevOps API Debug ==="
echo ""

# Read config
CONFIG_FILE=".specify/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "❌ jq is required but not installed"
    exit 1
fi

AZURE_ORG=$(jq -r '.azureDevOps.organization // empty' "$CONFIG_FILE")
AZURE_PROJECT=$(jq -r '.azureDevOps.project // empty' "$CONFIG_FILE")
WORK_ITEM_ID="${1:-969}"

echo "Configuration:"
echo "  Organization: $AZURE_ORG"
echo "  Project:      $AZURE_PROJECT"
echo "  Work Item:    $WORK_ITEM_ID"
echo ""

# Check Azure CLI
if command -v az &> /dev/null; then
    echo "Azure CLI: ✓ Installed"

    if az account show &>/dev/null; then
        ACCOUNT=$(az account show --query '{name:name, id:id}' -o json 2>/dev/null || echo "{}")
        echo "  Logged in: ✓"
        echo "  Account:   $(echo $ACCOUNT | jq -r '.name // "Unknown"')"
    else
        echo "  Logged in: ❌ (run 'az login')"
    fi
else
    echo "Azure CLI: ❌ Not installed"
fi
echo ""

# Try to get token
if [ -n "${AZURE_DEVOPS_PAT:-}" ]; then
    echo "Authentication: PAT (from AZURE_DEVOPS_PAT)"
    AUTH_HEADER="Authorization: Basic $(echo -n :${AZURE_DEVOPS_PAT} | base64)"
elif command -v az &> /dev/null; then
    echo "Authentication: Azure CLI"
    TOKEN=$(az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv 2>/dev/null || echo "")

    if [ -z "$TOKEN" ]; then
        echo "  ❌ Failed to get token from Azure CLI"
        echo ""
        echo "Try running: az login"
        exit 1
    fi

    AUTH_HEADER="Authorization: Bearer $TOKEN"
    echo "  Token obtained: ✓"
else
    echo "❌ No authentication method available"
    exit 1
fi
echo ""

# Build API URL
API_URL="https://dev.azure.com/${AZURE_ORG}/${AZURE_PROJECT}/_apis/wit/workitems/${WORK_ITEM_ID}?api-version=7.1"

echo "API URL:"
echo "  $API_URL"
echo ""

# Make request with verbose output
echo "Making API request..."
echo ""

HTTP_RESPONSE=$(curl -v -H "$AUTH_HEADER" "$API_URL" 2>&1)

echo "=== Response ==="
echo "$HTTP_RESPONSE"
echo ""
echo "=== End Response ==="
