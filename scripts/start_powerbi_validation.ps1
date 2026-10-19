param([string]$PowerBIBin = 'C:\Program Files\Microsoft Power BI Desktop\bin')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$audit = Join-Path $root 'outputs/powerbi_validation'
New-Item -ItemType Directory -Path $audit -Force | Out-Null
$workspaces = Join-Path $env:LOCALAPPDATA 'Microsoft\Power BI Desktop\AnalysisServicesWorkspaces'
$before = @(Get-ChildItem -LiteralPath $workspaces -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
$beforePids = @(Get-Process PBIDesktop -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Id)
$file = Join-Path $root 'powerbi/Observatoire.pbip'
$process = Start-Process -FilePath (Join-Path $PowerBIBin 'PBIDesktop.exe') -ArgumentList ('"' + $file + '"') -WindowStyle Normal -PassThru
[PSCustomObject]@{pid=$process.Id;before_pids=$beforePids;before_workspaces=$before;
  start_utc=[DateTime]::UtcNow.ToString('o')} | ConvertTo-Json -Depth 5 |
  Set-Content -LiteralPath (Join-Path $audit 'desktop_report_launch.json') -Encoding UTF8
Write-Output "Instance de recette : $($process.Id). Attendre l'ouverture du rapport avant le test natif."
