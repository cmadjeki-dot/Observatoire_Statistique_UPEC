# Tester uniquement le moteur cree pour Observatoire.pbip.
param([string]$LaunchFile = 'desktop_launch.json', [string]$WorkspaceFile = 'workspace.txt',
  [string]$OutputPrefix = '', [switch]$RequireProject)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$audit = Join-Path $projectRoot 'outputs/powerbi_validation'
$workspace = (Get-Content -LiteralPath (Join-Path $audit $WorkspaceFile) -Raw).Trim()
$launch = Get-Content -LiteralPath (Join-Path $audit $LaunchFile) -Raw | ConvertFrom-Json
if ((Split-Path $workspace -Leaf) -in $launch.before_workspaces) { throw 'Workspace preexistant refuse.' }
$portFile = @(Get-ChildItem -LiteralPath $workspace -Recurse -Filter 'msmdsrv.port.txt')
if ($portFile.Count -ne 1) { throw 'Port du nouveau moteur non disponible.' }
$portText = Get-Content -LiteralPath $portFile[0].FullName -Raw
$port = [int]($portText -replace '[^0-9]', '')
$bin = 'C:\Program Files\Microsoft Power BI Desktop\bin'
[void][System.Reflection.Assembly]::LoadFrom((Join-Path $bin 'Microsoft.PowerBI.Tabular.dll'))
$server = New-Object Microsoft.AnalysisServices.Tabular.Server
$server.Connect("Data Source=localhost:$port")
$databases = @($server.Databases | Where-Object {$_.Model.Tables.Contains('FactIndicateur')})
if ($databases.Count -eq 1 -and $databases[0].Name -eq 'Observatoire_Validation_UPEC') {
  # Repartir de la definition actuelle, uniquement pour ce catalogue de recette.
  $databases[0].Drop()
  $databases = @()
}
if ($databases.Count -eq 0) {
  if ($RequireProject) { throw 'Le projet demande doit etre charge avant ce test.' }
  # Modele de recette cree uniquement dans le workspace neuf du processus lance.
  # Cela teste le moteur et ne prouve pas le chargement des pages dans Desktop.
  $definition = Join-Path $projectRoot 'powerbi/Observatoire.SemanticModel/definition'
  $testDatabase = [Microsoft.AnalysisServices.Tabular.TmdlSerializer]::DeserializeDatabaseFromFolder($definition)
  $testDatabase.Name = 'Observatoire_Validation_UPEC'
  $testDatabase.ID = 'Observatoire_Validation_UPEC'
  $server.Databases.Add($testDatabase)
  $testDatabase.Update([Microsoft.AnalysisServices.UpdateOptions]::ExpandFull)
  $databases = @($testDatabase)
}
if ($databases.Count -ne 1) { throw 'Plusieurs modeles Observatoire : test refuse.' }
$database = $databases[0]
$mode = if ($database.Name -eq 'Observatoire_Validation_UPEC') {'modele_recette_isole'} else {'projet_charge'}
$database.Model.RequestRefresh([Microsoft.AnalysisServices.Tabular.RefreshType]::Full)
$database.Model.SaveChanges()
[void][System.Reflection.Assembly]::LoadFrom((Join-Path $bin 'Microsoft.PowerBI.AdomdClient.dll'))
$connection = New-Object Microsoft.AnalysisServices.AdomdClient.AdomdConnection("Data Source=localhost:$port;Initial Catalog=$($database.Name)")
$connection.Open()
$command = $connection.CreateCommand()
$command.CommandText = 'EVALUATE SUMMARIZECOLUMNS(DimIndicateur[id], DimAnnee[annee_universitaire], DimDiplome[type_diplome], "Lignes", COUNTROWS(FactIndicateur), "Valeur", [Valeur controlee], "Numerateur", [Numerateur affiche], "Denominateur", [Denominateur affiche])'
$reader = $command.ExecuteReader()
$rows = @()
while ($reader.Read()) {
  $row = [ordered]@{}
  for ($i = 0; $i -lt $reader.FieldCount; $i++) {
    $row[$reader.GetName($i)] = if ($reader.IsDBNull($i)) {$null} else {$reader.GetValue($i)}
  }
  $rows += [PSCustomObject]$row
}
$reader.Close()
$rows | Export-Csv -LiteralPath (Join-Path $audit ($OutputPrefix + 'dax_natif.csv')) -NoTypeInformation -Encoding UTF8
$guard = $connection.CreateCommand()
$guard.CommandText = 'EVALUATE CALCULATETABLE(ROW("Valeur", [Valeur controlee]), TREATAS({"I03"}, DimIndicateur[id]))'
$guardReader = $guard.ExecuteReader()
if (-not $guardReader.Read() -or -not $guardReader.IsDBNull(0)) { throw 'Le garde-fou multi-annees ne fonctionne pas.' }
$guardReader.Close()
$censure = $connection.CreateCommand()
$censure.CommandText = 'EVALUATE CALCULATETABLE(SUMMARIZECOLUMNS(DimIndicateur[id], DimAnnee[annee_universitaire], "Valeur", [Valeur controlee], "Lecture", [Lecture du statut]), TREATAS({"parcours"}, DimIndicateur[page]), TREATAS({"2025-2026"}, DimAnnee[annee_universitaire]))'
$censureReader = $censure.ExecuteReader()
$censureCount = 0
while ($censureReader.Read()) {
  if (-not $censureReader.IsDBNull(2) -or $censureReader.GetString(3) -ne 'Non observable (fin de periode)') {
    throw 'Censure mal restituee dans le contexte de la page Parcours.'
  }
  $censureCount++
}
$censureReader.Close()
if ($censureCount -ne 2) { throw 'Les deux lignes censurees doivent rester visibles.' }
$connection.Close()
$server.Disconnect()
[PSCustomObject]@{statut='actualisation_et_DAX_executes'; lignes=$rows.Count; port=$port; mode=$mode; garde_multi_annees='valide'; filtre_page_censure='valide'} |
 ConvertTo-Json | Set-Content -LiteralPath (Join-Path $audit ($OutputPrefix + 'natif.json')) -Encoding UTF8
Write-Output "ACTUALISATION NATIVE ET DAX : $($rows.Count) lignes ($mode)"
