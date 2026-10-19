# Arreter uniquement l'apercu de ce workspace, jamais un PID reutilise ailleurs.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$pidFile = Join-Path $root 'outputs/shiny_validation/pid.txt'
if (-not (Test-Path -LiteralPath $pidFile)) { Write-Output 'Aucun apercu enregistre.'; exit 0 }
$previewPid = [int](Get-Content -LiteralPath $pidFile)
$process = Get-CimInstance Win32_Process -Filter "ProcessId=$previewPid"
if (-not $process) { Write-Output 'Apercu deja arrete.'; exit 0 }
$expected = [IO.Path]::GetFullPath((Join-Path $root 'scripts/run_shiny.R')).Replace('/','\')
$command = $process.CommandLine.Replace('/','\')
if ($process.Name -ne 'Rscript.exe' -or $command.IndexOf($expected,[StringComparison]::OrdinalIgnoreCase) -lt 0) {
  throw 'Le PID ne correspond pas a l apercu de ce projet : aucun arret.'
}
Stop-Process -Id $previewPid
Write-Output 'Apercu Shiny arrete.'
