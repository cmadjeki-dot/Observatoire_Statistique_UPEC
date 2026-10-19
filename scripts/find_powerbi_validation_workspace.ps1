$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$audit = Join-Path $root 'outputs/powerbi_validation'
$launch = Get-Content (Join-Path $audit 'desktop_report_launch.json') -Raw | ConvertFrom-Json
$folder = Join-Path $env:LOCALAPPDATA 'Microsoft\Power BI Desktop\AnalysisServicesWorkspaces'
$new = @(Get-ChildItem -LiteralPath $folder -Directory | Where-Object {$_.Name -notin $launch.before_workspaces})
if ($new.Count -ne 1) { throw 'Workspace de recette absent ou ambigu : aucune instance existante ne sera utilisee.' }
$new[0].FullName | Set-Content -LiteralPath (Join-Path $audit 'workspace_report.txt')
Write-Output 'Workspace de recette identifie.'
