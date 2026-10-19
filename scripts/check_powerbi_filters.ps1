$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$audit = Join-Path $root 'outputs/powerbi_validation'
$launch = Get-Content (Join-Path $audit 'desktop_report_launch.json') -Raw | ConvertFrom-Json
if ($launch.pid -in $launch.before_pids) { throw 'Instance preexistante refusee.' }
Add-Type -AssemblyName UIAutomationClient
$condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty,[int]$launch.pid)
$window = [System.Windows.Automation.AutomationElement]::RootElement.FindFirst([System.Windows.Automation.TreeScope]::Children,$condition)
function Select-Control($name,$type) {
  $nodes=$window.FindAll([System.Windows.Automation.TreeScope]::Descendants,[System.Windows.Automation.Condition]::TrueCondition)
  $node=@($nodes | Where-Object {$_.Current.Name -eq $name -and $_.Current.ControlType -eq $type})[0]
  if (-not $node) { throw "Controle absent : $name" }
  $node.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern).Select()
  Start-Sleep -Seconds 2
}
Select-Control 'Insertion' ([System.Windows.Automation.ControlType]::TabItem)
Select-Control '2024-2025' ([System.Windows.Automation.ControlType]::ListItem)
Select-Control 'licence' ([System.Windows.Automation.ControlType]::ListItem)
$nodes=$window.FindAll([System.Windows.Automation.TreeScope]::Descendants,[System.Windows.Automation.Condition]::TrueCondition)
$rows=@($nodes | Where-Object {$_.Current.Name -match '^S.lectionner la ligne ' -and $_.Current.ControlType -eq [System.Windows.Automation.ControlType]::DataItem} |
  ForEach-Object {$_.Current.Name} | Select-Object -Unique)
if ($rows.Count -ne 3) { throw "Trois lignes attendues apres filtres : $($rows.Count)" }
foreach ($row in $rows) {
  if ($row -notmatch '2024-2025' -or $row -notmatch 'licence' -or $row -match 'master') { throw 'Ligne hors filtre.' }
}
@{statut='succes';page='Insertion';annee='2024-2025';diplome='licence';lignes=$rows.Count;lecture=$rows} |
 ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $audit 'filtres_interface.json') -Encoding UTF8
& (Join-Path $PSScriptRoot 'capture_powerbi_validation.ps1') -OutputName 'Insertion_filtree.png'
Write-Output 'Filtres Desktop annee + licence : trois lignes conformes.'
