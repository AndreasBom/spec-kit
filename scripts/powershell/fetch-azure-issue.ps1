[CmdletBinding()]
param(
    [Parameter(Position = 0, Mandatory = $true)]
    [string]$WorkItemId,

    [Parameter()]
    [switch]$Json
)

$ErrorActionPreference = "Stop"

# Function to find repository root
function Find-RepoRoot {
    param([string]$StartPath)

    $current = $StartPath
    while ($current -ne [System.IO.Path]::GetPathRoot($current)) {
        if ((Test-Path (Join-Path $current ".git")) -or (Test-Path (Join-Path $current ".specify"))) {
            return $current
        }
        $current = Split-Path $current -Parent
    }
    throw "Could not determine repository root"
}

# Get repository root
try {
    $gitRoot = git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -eq 0) {
        $RepoRoot = $gitRoot
    } else {
        $RepoRoot = Find-RepoRoot $PSScriptRoot
    }
} catch {
    $RepoRoot = Find-RepoRoot $PSScriptRoot
}

$SpecifyDir = Join-Path $RepoRoot ".specify"
$ConfigFile = Join-Path $SpecifyDir "config.json"
$TempDir = Join-Path $SpecifyDir "temp"
$IssueFile = Join-Path $TempDir "current-issue.json"

# Create temp directory if it doesn't exist
if (-not (Test-Path $TempDir)) {
    New-Item -ItemType Directory -Path $TempDir -Force | Out-Null
}

# Read configuration
if (-not (Test-Path $ConfigFile)) {
    Write-Error @"
Configuration file not found at $ConfigFile
Please create the file with the following structure:
{
  "azureDevOps": {
    "organization": "your-org",
    "project": "your-project"
  }
}
"@
    exit 1
}

$config = Get-Content $ConfigFile -Raw | ConvertFrom-Json
$azureOrg = $config.azureDevOps.organization
$azureProject = $config.azureDevOps.project

if (-not $azureOrg -or -not $azureProject) {
    Write-Error "Azure DevOps organization and project must be configured in $ConfigFile"
    exit 1
}

# Determine authentication method
$authHeader = $null
if ($env:AZURE_DEVOPS_PAT) {
    # Use PAT authentication
    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$($env:AZURE_DEVOPS_PAT)"))
    $authHeader = @{
        Authorization = "Basic $base64AuthInfo"
    }
    if (-not $Json) {
        Write-Host "[specify] Using PAT authentication" -ForegroundColor Gray
    }
} elseif (Get-Command az -ErrorAction SilentlyContinue) {
    # Try Azure CLI authentication
    if (-not $Json) {
        Write-Host "[specify] Attempting Azure CLI authentication..." -ForegroundColor Gray
    }

    try {
        $token = az account get-access-token --resource 499b84ac-1321-427f-aa17-267ca6975798 --query accessToken -o tsv 2>$null
        if ($LASTEXITCODE -eq 0 -and $token) {
            $authHeader = @{
                Authorization = "Bearer $token"
            }
        } else {
            throw "Azure CLI authentication failed"
        }
    } catch {
        Write-Error @"
Azure CLI authentication failed. Please either:
  1. Set AZURE_DEVOPS_PAT environment variable with your Personal Access Token
  2. Run 'az login' to authenticate with Azure CLI
"@
        exit 1
    }
} else {
    Write-Error @"
No authentication method available. Please either:
  1. Set AZURE_DEVOPS_PAT environment variable with your Personal Access Token
  2. Install and login with Azure CLI (az login)
"@
    exit 1
}

# Construct API URL
$apiUrl = "https://dev.azure.com/$azureOrg/$azureProject/_apis/wit/workitems/${WorkItemId}?api-version=7.1"

# Fetch work item from Azure DevOps
if (-not $Json) {
    Write-Host "[specify] Fetching work item $WorkItemId from Azure DevOps..." -ForegroundColor Gray
}

try {
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $authHeader -Method Get
} catch {
    Write-Error "Failed to fetch work item: $($_.Exception.Message)"
    if ($_.ErrorDetails.Message) {
        $errorObj = $_.ErrorDetails.Message | ConvertFrom-Json
        Write-Error $errorObj.message
    }
    exit 1
}

# Extract relevant fields
$workItemType = $response.fields.'System.WorkItemType'
$title = $response.fields.'System.Title'
$description = $response.fields.'System.Description' ?? ""
$state = $response.fields.'System.State'
$assignedTo = $response.fields.'System.AssignedTo'.displayName ?? "Unassigned"
$acceptanceCriteria = $response.fields.'Microsoft.VSTS.Common.AcceptanceCriteria' ?? ""

# Create issue data object
$issueData = @{
    id = $WorkItemId
    type = $workItemType
    title = $title
    description = $description
    state = $state
    assignedTo = $assignedTo
    acceptanceCriteria = $acceptanceCriteria
    fetchedAt = (Get-Date).ToUniversalTime().ToString("o")
} | ConvertTo-Json -Depth 10

# Save to temp file
$issueData | Out-File -FilePath $IssueFile -Encoding UTF8 -NoNewline

if ($Json) {
    Write-Output $issueData
} else {
    Write-Host ""
    Write-Host "✓ Work item fetched successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "ID:    $WorkItemId"
    Write-Host "Type:  $workItemType"
    Write-Host "Title: $title"
    Write-Host "State: $state"
    Write-Host ""
    Write-Host "Saved to: $IssueFile"
    Write-Host ""
    Write-Host "Next step: Run /speckit.specify to create the specification" -ForegroundColor Cyan
}
