param([string]$LaunchFile = 'desktop_report_launch.json', [string]$OutputName = 'rapport.png')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$audit = Join-Path $root 'outputs/powerbi_validation'
$launch = Get-Content (Join-Path $audit $LaunchFile) -Raw | ConvertFrom-Json
if ($launch.pid -in $launch.before_pids) { throw 'Instance preexistante refusee.' }
Add-Type -AssemblyName System.Drawing
if (-not ('UpecReportShot' -as [type])) {
  Add-Type -TypeDefinition 'using System; using System.Runtime.InteropServices; public class UpecReportShot { [StructLayout(LayoutKind.Sequential)] public struct RECT {public int L,T,R,B;} [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h,out RECT r); [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h,IntPtr dc,uint f); }'
}
$handle = (Get-Process -Id $launch.pid).MainWindowHandle
if ($handle -eq [IntPtr]::Zero) {
  Add-Type -AssemblyName UIAutomationClient
  $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty,[int]$launch.pid)
  $window = [System.Windows.Automation.AutomationElement]::RootElement.FindFirst([System.Windows.Automation.TreeScope]::Children,$condition)
  if (-not $window) { throw 'Fenetre du rapport non disponible.' }
  $handle = [IntPtr]$window.Current.NativeWindowHandle
}
$rect = New-Object UpecReportShot+RECT
[void][UpecReportShot]::GetWindowRect($handle,[ref]$rect)
$bitmap = New-Object System.Drawing.Bitmap(($rect.R-$rect.L),($rect.B-$rect.T))
$graphics = [System.Drawing.Graphics]::FromImage($bitmap)
$dc = $graphics.GetHdc()
[void][UpecReportShot]::PrintWindow($handle,$dc,2)
$graphics.ReleaseHdc($dc)
$bitmap.Save((Join-Path $audit $OutputName))
$graphics.Dispose()
$bitmap.Dispose()
