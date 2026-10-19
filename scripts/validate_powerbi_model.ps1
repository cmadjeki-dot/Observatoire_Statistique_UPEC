param([string]$PowerBIBin = 'C:\Program Files\Microsoft Power BI Desktop\bin')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
[void][System.Reflection.Assembly]::LoadFrom((Join-Path $PowerBIBin 'Microsoft.PowerBI.Tabular.dll'))
$modelPath = Join-Path $projectRoot 'powerbi/Observatoire.SemanticModel/definition'
$database = [Microsoft.AnalysisServices.Tabular.TmdlSerializer]::DeserializeDatabaseFromFolder($modelPath)
if ($database.Model.Tables.Count -ne 4 -or $database.Model.Relationships.Count -ne 3) {
  throw 'Nombre de tables ou de relations incorrect.'
}
foreach ($table in $database.Model.Tables) {
  $duplicates = @(@($table.Columns.Name) + @($table.Measures.Name) | Group-Object | Where-Object {$_.Count -gt 1})
  if ($duplicates.Count) { throw "Noms de colonnes et mesures ambigus : $($table.Name)" }
}
$result = [PSCustomObject]@{statut='modele_deserialise'; tables=$database.Model.Tables.Count;
  relations=$database.Model.Relationships.Count; mesures=$database.Model.Tables['FactIndicateur'].Measures.Count;
  limite='Ce controle ne compile pas DAX et ne rafraichit pas Power Query.'}
$result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $projectRoot 'outputs/powerbi_validation/modele.json') -Encoding UTF8
$result | Format-List
