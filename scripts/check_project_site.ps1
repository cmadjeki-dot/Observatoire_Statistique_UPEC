param([string]$Url = 'http://127.0.0.1:4173')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$audit = Join-Path $root 'outputs/site_validation'
New-Item -ItemType Directory -Path $audit -Force | Out-Null
$siteBrowserProfile = Join-Path $audit 'browser'
Start-Process 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe' -WindowStyle Hidden -ArgumentList @('--headless','--disable-gpu','--no-first-run','--remote-debugging-port=19241',('--user-data-dir="'+$siteBrowserProfile+'"'),'--window-size=1440,1000',$Url) | Out-Null
$target = $null
for ($attempt=0;$attempt -lt 60;$attempt++) {
  try {
    $siteTargets = Invoke-RestMethod 'http://127.0.0.1:19241/json/list'
    $target = @($siteTargets | Where-Object {$_.type -eq 'page' -and $_.url -like ($Url+'*')})[0]
  } catch {}
  if ($target) { break }; Start-Sleep -Milliseconds 500
}
if (-not $target) { throw 'Apercu navigateur indisponible' }
$socket = New-Object Net.WebSockets.ClientWebSocket
$socket.ConnectAsync([Uri]$target.webSocketDebuggerUrl,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
$script:sequence = 0
function Send-Cdp($method,$parameters) {
  $script:sequence++;$id=$script:sequence
  $bytes=[Text.Encoding]::UTF8.GetBytes((@{id=$id;method=$method;params=$parameters}|ConvertTo-Json -Depth 25 -Compress))
  $token=New-Object Threading.CancellationTokenSource;$token.CancelAfter(30000)
  $socket.SendAsync((New-Object 'ArraySegment[byte]' -ArgumentList @(,$bytes)),[Net.WebSockets.WebSocketMessageType]::Text,$true,$token.Token).GetAwaiter().GetResult()
  do {
    $message=New-Object Text.StringBuilder
    do {
      $buffer=New-Object byte[] 262144
      $part=$socket.ReceiveAsync((New-Object 'ArraySegment[byte]' -ArgumentList @(,$buffer)),$token.Token).GetAwaiter().GetResult()
      [void]$message.Append([Text.Encoding]::UTF8.GetString($buffer,0,$part.Count))
    } while(-not $part.EndOfMessage)
    $response=$message.ToString()|ConvertFrom-Json
  } while($response.id -ne $id)
  $token.Dispose()
  if($response.error){throw ($response.error|ConvertTo-Json -Compress)}
  $response.result
}
function Evaluate-Js($expression) {
  $value=Send-Cdp 'Runtime.evaluate' @{expression=$expression;returnByValue=$true;awaitPromise=$true}
  if($value.exceptionDetails){throw ($value.exceptionDetails|ConvertTo-Json -Depth 10)}
  $value.result.value
}
function Wait-Rows($count) {
  for($attempt=0;$attempt -lt 60;$attempt++) {
    if(Evaluate-Js "document.querySelectorAll('#rows tr').length === $count"){return}
    Start-Sleep -Milliseconds 500
  }
  throw "Nombre de lignes incorrect : $count"
}
try {
  Wait-Rows 1
  $shot=Send-Cdp 'Page.captureScreenshot' @{format='png'}
  [IO.File]::WriteAllBytes((Join-Path $audit 'accueil.png'),[Convert]::FromBase64String($shot.data))
  $expected=@{inscriptions=1;reussite=2;parcours=2;enquetes=2;insertion=6}
  foreach($page in @('inscriptions','reussite','parcours','enquetes','insertion')) {
    [void](Evaluate-Js "document.querySelector('[data-page=$page]').click()")
    Wait-Rows $expected[$page]
    Write-Output "Vue web validee : $page"
  }
  [void](Evaluate-Js "document.getElementById('diploma').value='licence';document.getElementById('diploma').dispatchEvent(new Event('change'))")
  Wait-Rows 3
  $values=Evaluate-Js 'selected().map(r=>r.valeur)'
  if($values.Count -ne 3){throw 'Filtre diplome invalide'}
  [void](Evaluate-Js "document.documentElement.style.scrollBehavior='auto';document.getElementById('explorer').scrollIntoView({behavior:'instant'})")
  $shot=Send-Cdp 'Page.captureScreenshot' @{format='png'}
  [IO.File]::WriteAllBytes((Join-Path $audit 'insertion.png'),[Convert]::FromBase64String($shot.data))
  [void](Evaluate-Js "document.querySelector('[data-page=parcours]').click();document.getElementById('year').value='2025-2026';document.getElementById('year').dispatchEvent(new Event('change'))")
  if(-not (Evaluate-Js 'selected().length === 2 && selected().every(r=>r.valeur===null && r.statut==="non_observable")')){throw 'Censures incorrectes'}
  [void](Send-Cdp 'Emulation.setDeviceMetricsOverride' @{width=390;height=844;deviceScaleFactor=1;mobile=$true})
  if(-not (Evaluate-Js 'document.documentElement.scrollWidth <= window.innerWidth')){throw 'Debordement mobile'}
  $result=@{statut='succes';url=$Url;vues=5;filtre_licence=3;censures=2;mobile='conforme'}
  $result|ConvertTo-Json|Set-Content (Join-Path $audit 'navigateur.json') -Encoding UTF8
} finally {
  try{[void](Send-Cdp 'Browser.close' @{})}catch{}
  $socket.Dispose()
}
