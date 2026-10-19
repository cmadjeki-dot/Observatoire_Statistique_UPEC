$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$audit = Join-Path $root 'outputs/powerbi_validation'
$launch = Get-Content (Join-Path $audit 'desktop_report_launch.json') -Raw | ConvertFrom-Json
if ($launch.pid -in $launch.before_pids) { throw 'Instance preexistante refusee.' }
Add-Type -AssemblyName UIAutomationClient
$condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty,[int]$launch.pid)
$window = [System.Windows.Automation.AutomationElement]::RootElement.FindFirst([System.Windows.Automation.TreeScope]::Children,$condition)
$results = @()
foreach ($page in @('Inscriptions','Reussite','Parcours','Enquetes','Insertion')) {
  $name = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty,$page)
  $candidates = $window.FindAll([System.Windows.Automation.TreeScope]::Descendants,$name)
  $selected = $false
  foreach ($candidate in $candidates) {
    try {
      $pattern = $candidate.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern)
      $pattern.Select()
      for ($attempt=0;$attempt -lt 20;$attempt++) {
        if ($pattern.Current.IsSelected) { $selected=$true; break }
        Start-Sleep -Milliseconds 200
      }
      break
    } catch {}
    try {
      $pattern = $candidate.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
      $pattern.Invoke()
      $selected = $true
      break
    } catch {}
  }
  if (-not $selected) { throw "Onglet inaccessible : $page" }
  Start-Sleep -Seconds 2
  & (Join-Path $PSScriptRoot 'capture_powerbi_validation.ps1') -OutputName ($page + '.png')
  $results += [PSCustomObject]@{page=$page;navigation='selectionnee'}
}
$results | Export-Csv -LiteralPath (Join-Path $audit 'navigation_pages.csv') -NoTypeInformation -Encoding UTF8
$results | Format-Table -AutoSize
