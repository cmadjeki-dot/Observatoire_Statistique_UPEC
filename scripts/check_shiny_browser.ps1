# Recette navigateur sur le seul Edge headless lance avec le port 19239.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$audit = Join-Path $root 'outputs/shiny_validation'
$targets = Invoke-RestMethod -Uri 'http://127.0.0.1:19239/json/list' -TimeoutSec 10
$target = @($targets | Where-Object {$_.type -eq 'page' -and $_.url -like 'http://127.0.0.1:3838*'})[0]
if (-not $target) { throw 'Onglet Shiny headless non disponible.' }
$socket = New-Object System.Net.WebSockets.ClientWebSocket
$socket.ConnectAsync([Uri]$target.webSocketDebuggerUrl,[Threading.CancellationToken]::None).GetAwaiter().GetResult()
$script:sequence = 0
function Send-Cdp($method,$parameters) {
  $script:sequence++
  $id = $script:sequence
  $payload = @{id=$id;method=$method;params=$parameters} | ConvertTo-Json -Depth 30 -Compress
  $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
  $segment = New-Object 'ArraySegment[byte]' -ArgumentList @(,$bytes)
  $token = New-Object Threading.CancellationTokenSource
  $token.CancelAfter(30000)
  $socket.SendAsync($segment,[Net.WebSockets.WebSocketMessageType]::Text,$true,$token.Token).GetAwaiter().GetResult()
  do {
    $message = New-Object Text.StringBuilder
    do {
      $buffer = New-Object byte[] 262144
      $part = $socket.ReceiveAsync((New-Object 'ArraySegment[byte]' -ArgumentList @(,$buffer)),$token.Token).GetAwaiter().GetResult()
      [void]$message.Append([Text.Encoding]::UTF8.GetString($buffer,0,$part.Count))
    } while (-not $part.EndOfMessage)
    $response = $message.ToString() | ConvertFrom-Json
  } while ($response.id -ne $id)
  $token.Dispose()
  if ($response.error) { throw ($response.error | ConvertTo-Json -Compress) }
  $response.result
}
function Evaluate-Js($expression) {
  $result = Send-Cdp 'Runtime.evaluate' @{expression=$expression;returnByValue=$true;awaitPromise=$true}
  if ($result.exceptionDetails) { throw ($result.exceptionDetails | ConvertTo-Json -Depth 10) }
  $result.result.value
}
function Wait-Table($rows,$needle) {
  $quoted = $needle | ConvertTo-Json -Compress
  for ($attempt=0; $attempt -lt 90; $attempt++) {
    $expression = "Boolean(!document.documentElement.classList.contains('shiny-busy') && document.querySelector('#chart img')?.complete && document.querySelector('#chart img')?.naturalWidth > 0 && document.querySelectorAll('#table tbody tr').length === $rows && document.querySelector('#table')?.textContent.includes($quoted))"
    if (Evaluate-Js $expression) { return }
    Start-Sleep -Milliseconds 500
  }
  $errors = Evaluate-Js "Array.from(document.querySelectorAll('.shiny-output-error')).map(x=>x.textContent).join('; ')"
  throw "Rendu Shiny incomplet : $needle. $errors"
}
$expected = @{inscriptions=1;reussite=2;parcours=2;enquetes=2;insertion=6}
$dimensions = Import-Csv (Join-Path $root 'outputs/pipeline_dashboard/DimIndicateur.csv')
foreach ($page in @('inscriptions','reussite','parcours','enquetes','insertion')) {
  [void](Evaluate-Js "document.getElementById('page').selectize.setValue('$page')")
  $needle = @($dimensions | Where-Object {$_.page -eq $page})[0].libelle
  Wait-Table $expected[$page] $needle
  $shot = Send-Cdp 'Page.captureScreenshot' @{format='png';captureBeyondViewport=$false}
  [IO.File]::WriteAllBytes((Join-Path $audit ($page + '.png')),[Convert]::FromBase64String($shot.data))
  Write-Output "Vue navigateur validee : $page"
}
[void](Evaluate-Js "document.getElementById('diploma').selectize.setValue('licence')")
Wait-Table 3 'licence'
$result = @{statut='succes';vues=5;filtre_diplome='licence';lignes_insertion_filtrees=3}
$result | ConvertTo-Json | Set-Content (Join-Path $audit 'navigateur.json') -Encoding UTF8
try { [void](Send-Cdp 'Browser.close' @{}) } catch {}
$socket.Dispose()
