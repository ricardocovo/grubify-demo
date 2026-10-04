#Requires -Version 7.0
param(
    [Parameter(Mandatory)][string]$ResourceGroup,
    [Parameter(Mandatory)][string]$AgentName,
    [Parameter(Mandatory)][string]$BackupDirectory
)

$ErrorActionPreference = 'Stop'
$lab = Split-Path $PSScriptRoot -Parent
New-Item -ItemType Directory -Force -Path $BackupDirectory | Out-Null

function Invoke-AzJson([string[]]$Arguments) {
    $result = & az @Arguments --output json
    if ($LASTEXITCODE -ne 0) { throw "Azure command failed: $($Arguments[0..1] -join ' ')" }
    if ($result) { $result | ConvertFrom-Json -Depth 60 }
}

function Save-Original([string]$Name, $Value) {
    $path = Join-Path $BackupDirectory "$Name.json"
    if (!(Test-Path $path)) {
        $Value | ConvertTo-Json -Depth 60 | Set-Content $path
    }
}

function Set-ArmProperties([string]$Id, [string]$Version, $Properties) {
    $bodyPath = Join-Path $BackupDirectory 'arm-update.json'
    @{ properties = $Properties } | ConvertTo-Json -Depth 30 | Set-Content $bodyPath
    $null = Invoke-AzJson @('rest', '--method', 'patch', '--url', "https://management.azure.com${Id}?api-version=$Version", '--body', "@$bodyPath")
}

$agent = Invoke-AzJson @('resource', 'show', '-g', $ResourceGroup, '-n', $AgentName,
    '--resource-type', 'Microsoft.App/agents', '--api-version', '2025-05-01-preview')
Save-Original 'agent' $agent
$endpoint = $agent.properties.agentEndpoint.TrimEnd('/')
$identityId = $agent.properties.actionConfiguration.identity
$identity = Invoke-AzJson @('identity', 'show', '--ids', $identityId)
$assignments = @(Invoke-AzJson @('role', 'assignment', 'list', '--assignee', $identity.principalId, '--all', '--include-inherited'))
Save-Original 'role-assignments' $assignments
$subscription = Invoke-AzJson @('account', 'show')
$scope = "/subscriptions/$($subscription.id)"
$null = Invoke-AzJson @('role', 'assignment', 'create', '--assignee-object-id', $identity.principalId,
    '--assignee-principal-type', 'ServicePrincipal', '--role', 'Monitoring Reader', '--scope', $scope)
foreach ($assignment in $assignments) {
    if ($assignment.roleDefinitionName -in @('Monitoring Contributor', 'Container Apps Contributor')) {
        & az role assignment delete --ids $assignment.id
        if ($LASTEXITCODE -ne 0) { throw "Failed to remove $($assignment.roleDefinitionName)" }
    } elseif ($assignment.roleDefinitionName -notin @('Reader', 'Monitoring Reader', 'Log Analytics Reader')) {
        throw "Unexpected role requires review before fault injection: $($assignment.roleDefinitionName)"
    }
}

$agent.properties.actionConfiguration.mode = 'review'
Set-ArmProperties $agent.id '2025-05-01-preview' @{ actionConfiguration = $agent.properties.actionConfiguration }

$token = & az account get-access-token --resource https://azuresre.dev --query accessToken -o tsv
if ($LASTEXITCODE -ne 0) { throw 'Could not authenticate to SRE Agent' }
$headers = @{ Authorization = "Bearer $token" }
try {
    $settingsResponse = Invoke-WebRequest "$endpoint/api/v2/agent/settings/global" -Headers $headers
    $settings = $settingsResponse.Content | ConvertFrom-Json -AsHashtable
    Save-Original 'global-settings' $settings
    $settings.permissions = Get-Content (Join-Path $lab 'sre-config\demo-tool-permissions.json') -Raw | ConvertFrom-Json -AsHashtable
    $etag = [string]$settingsResponse.Headers.ETag
    $putHeaders = $headers.Clone()
    $putHeaders['If-Match'] = if ($etag) { $etag } else { '*' }
    $null = Invoke-RestMethod "$endpoint/api/v2/agent/settings/global" -Method Put -Headers $putHeaders `
        -ContentType 'application/json' -Body ($settings | ConvertTo-Json -Depth 30)

    $originalPlans = Invoke-RestMethod "$endpoint/api/v2/extendedAgent/incidentFilters" -Headers $headers
    Save-Original 'response-plans' $originalPlans
    $otherPlans = @($originalPlans.value | Where-Object { $_.name -ne 'grubify-http-errors' -and $_.properties.isEnabled })
    if ($otherPlans.Count) { throw 'Other active response plans must be reviewed before running this demo' }

    $json = & python (Join-Path $PSScriptRoot 'yaml-to-api-json.py') `
        (Join-Path $lab 'sre-config\agents\demo-rca.yaml') '-' 'ricardocovo/grubify-demo'
    if ($LASTEXITCODE -ne 0) { throw 'Demo agent configuration conversion failed' }
    $handler = $json | ConvertFrom-Json
    $handler.properties.enableSkills = $false
    $null = Invoke-RestMethod "$endpoint/api/v2/extendedAgent/agents/demo-rca" -Method Put `
        -Headers $headers -ContentType 'application/json' -Body ($handler | ConvertTo-Json -Depth 30)
    $plan = @{
        name = 'grubify-http-errors'; type = 'IncidentFilter'; tags = @()
        properties = @{
            incidentPlatform = 'AzMonitor'; priorities = @('Sev0', 'Sev1', 'Sev2', 'Sev3', 'Sev4')
            titleContains = 'alert-http-5xx-sre-lab'; handlingAgent = 'demo-rca'; agentMode = 'Review'
            maxAutomatedInvestigationAttempts = 1; mergeEnabled = $true; mergeWindowHours = 3; isEnabled = $true
        }
    }
    $null = Invoke-RestMethod "$endpoint/api/v2/extendedAgent/incidentFilters/grubify-http-errors" `
        -Method Put -Headers $headers -ContentType 'application/json' -Body ($plan | ConvertTo-Json -Depth 20)

    $check = Invoke-RestMethod "$endpoint/api/v2/extendedAgent/incidentFilters/grubify-http-errors" -Headers $headers
    if ($check.properties.agentMode -ne 'Review' -or $check.properties.handlingAgent -ne 'demo-rca') {
        throw 'Read-only response routing verification failed'
    }
    $check = Invoke-RestMethod "$endpoint/api/v2/agent/settings/global" -Headers $headers
    if ('RunAzCliWriteCommands' -notin $check.permissions.deny -or 'CreateGithubIssue' -notin $check.permissions.allow) {
        throw 'Tool policy verification failed'
    }
} finally {
    $headers = $null
    $putHeaders = $null
    $token = $null
}

$alert = Invoke-AzJson @('monitor', 'metrics', 'alert', 'show', '-g', $ResourceGroup, '-n', 'alert-http-5xx-sre-lab')
Save-Original 'alert' $alert
# A stateless demo alert remains visible for the handoff instead of auto-resolving when test traffic stops.
Set-ArmProperties $alert.id '2018-03-01' @{ autoMitigate = $false }
$roles = @(Invoke-AzJson @('role', 'assignment', 'list', '--assignee', $identity.principalId, '--all', '--include-inherited'))
if (@($roles | Where-Object { $_.roleDefinitionName -notin @('Reader', 'Monitoring Reader', 'Log Analytics Reader') }).Count) {
    throw 'The SRE identity still has non-reader roles'
}
Write-Output 'Verified: Review mode, read-only Azure roles, remediation tools denied, GitHub issue creation allowed.'
