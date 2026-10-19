# Generateur PBIP/PBIR/TMDL documente. Aucun PBIX binaire n'est fabrique.
build_powerbi_project <- function(directory = "powerbi", data_directory = "outputs/pipeline_dashboard") {
  root <- project_path(directory)
  data_directory <- project_path(data_directory)
  model <- fs::path(root, "Observatoire.SemanticModel")
  report <- fs::path(root, "Observatoire.Report")
  fs::dir_create(c(fs::path(model, "definition", "tables"), fs::path(report, "definition", "pages")))
  write_json <- function(x, path) {
    fs::dir_create(dirname(path))
    jsonlite::write_json(x, path, auto_unbox = TRUE, pretty = TRUE, null = "null")
  }
  schema <- function(kind, version) paste0("https://developer.microsoft.com/json-schemas/fabric/item/report/definition/", kind, "/", version, "/schema.json")
  write_json(list(`$schema` = "https://developer.microsoft.com/json-schemas/fabric/pbip/pbipProperties/1.0.0/schema.json",
    version = "1.0", artifacts = list(list(report = list(path = "Observatoire.Report")))),
    fs::path(root, "Observatoire.pbip"))
  write_json(list(`$schema` = "https://developer.microsoft.com/json-schemas/fabric/item/report/definitionProperties/2.0.0/schema.json",
    version = "4.0", datasetReference = list(byPath = list(path = "../Observatoire.SemanticModel"))), fs::path(report, "definition.pbir"))
  write_json(list(`$schema` = "https://developer.microsoft.com/json-schemas/fabric/item/semanticModel/definitionProperties/1.0.0/schema.json",
    version = "4.0"), fs::path(model, "definition.pbism"))
  for (kind in c("Report", "SemanticModel")) {
    write_json(list(`$schema` = "https://developer.microsoft.com/json-schemas/fabric/gitIntegration/platformProperties/2.0.0/schema.json",
      metadata = list(type = kind, displayName = "Observatoire synthetique UPEC", description = "Demonstrateur personnel independant, donnees fictives."),
      config = list(version = "2.0", logicalId = if (kind == "Report")
        "fe924df8-7f05-4620-9e86-948a4736dbb1" else "fe924df8-7f05-4620-9e86-948a4736dbb2")),
      fs::path(if (kind == "Report") report else model, ".platform"))
  }
  write_json(list(`$schema` = schema("versionMetadata", "1.0.0"), version = "2.0.0"), fs::path(report, "definition", "version.json"))
  write_json(list(`$schema` = schema("report", "2.0.0"), themeCollection = list(baseTheme = list(
    name = "CY24SU06", reportVersionAtImport = "5.55", type = "SharedResources"))),
    fs::path(report, "definition", "report.json"))
  names <- c("FactIndicateur", "DimIndicateur", "DimAnnee", "DimDiplome")
  writeLines(c("database", "\tcompatibilityLevel: 1601"), fs::path(model, "definition", "database.tmdl"))
  writeLines(c("model Model", "\tculture: fr-FR", "\tdefaultPowerBIDataSourceVersion: powerBI_V3",
    "\tsourceQueryCulture: en-US", "", paste("ref table", names), "ref expression DataFolder"), fs::path(model, "definition", "model.tmdl"))
  # Configuration locale derivee du workspace ; exclue du versionnement.
  folder <- gsub("\\", "/", as.character(data_directory), fixed = TRUE)
  writeLines(c(paste0('expression DataFolder = "', folder, '" meta [IsParameterQuery=true, Type="Text", IsParameterQueryRequired=true]')),
    fs::path(model, "definition", "expressions.tmdl"))
  measures <- c(
    "\tmeasure 'Valeur controlee' =",
    "\t\t\tVAR UniqueGrain = HASONEVALUE(DimAnnee[annee_universitaire]) && HASONEVALUE(DimIndicateur[id])",
    "\t\t\tVAR Refus = COUNTROWS(FILTER(FactIndicateur, FactIndicateur[statut] <> \"diffusable\")) > 0",
    "\t\t\tVAR N = SUM(FactIndicateur[numerateur])",
    "\t\t\tVAR D = SUM(FactIndicateur[denominateur])",
    "\t\t\tRETURN IF(NOT UniqueGrain || Refus, BLANK(), IF(SELECTEDVALUE(DimIndicateur[id]) = \"I02\", N, 100 * DIVIDE(N,D)))",
    "\t\tformatString: 0.00",
    "\tmeasure 'Lecture du statut' = SWITCH(SELECTEDVALUE(FactIndicateur[statut]), \"non_observable\", \"Non observable (fin de periode)\", \"effectif_insuffisant\", \"Effectif insuffisant\", \"denominateur_nul\", \"Denominateur nul\", \"diffusable\", \"Diffusable\", BLANK())",
    "", "\tmeasure 'Numerateur affiche' = IF(HASONEVALUE(DimAnnee[annee_universitaire]) && HASONEVALUE(DimIndicateur[id]), SUM(FactIndicateur[numerateur]))",
    "\tmeasure 'Denominateur affiche' = IF(HASONEVALUE(DimAnnee[annee_universitaire]) && HASONEVALUE(DimIndicateur[id]), SUM(FactIndicateur[denominateur]))",
    "\tmeasure 'Couverture pct' = IF(HASONEVALUE(DimAnnee[annee_universitaire]) && HASONEVALUE(DimIndicateur[id]), 100 * DIVIDE(SUM(FactIndicateur[couverture_numerateur]),SUM(FactIndicateur[couverture_denominateur])))",
    "\t\tformatString: 0.00")
  for (table in names) {
    df <- utils::read.csv(fs::path(data_directory, paste0(table, ".csv")), stringsAsFactors = FALSE)
    numeric <- names(df)[vapply(df, is.numeric, logical(1))]
    columns <- unlist(lapply(names(df), function(column) c(paste("\tcolumn", column),
      paste0("\t\tdataType: ", if (column %in% numeric) "double" else "string"),
      "\t\tsummarizeBy: none", paste0("\t\tsourceColumn: ", column), "")))
    types <- paste(vapply(names(df), function(column) paste0('{"', column, '", ',
      if (column %in% numeric) "type number" else "type text", '}'), character(1)), collapse = ", ")
    partition <- c(paste0("\tpartition ", table, " = m"), "\t\tmode: import", "\t\tsource =",
      "\t\t\tlet",
      '\t\t\t  Check = Table.PromoteHeaders(Csv.Document(File.Contents(DataFolder & "/statut.csv"), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv])),',
      '\t\t\t  SourceCheck = Table.PromoteHeaders(Csv.Document(File.Contents(DataFolder & "/../pipeline_rapport/statut.csv"), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv])),',
      paste0('\t\t\t  Raw = if Check{0}[statut] = "succes" and SourceCheck{0}[statut] = "succes" then Csv.Document(File.Contents(DataFolder & "/', table, '.csv"), [Delimiter=",", Encoding=65001, QuoteStyle=QuoteStyle.Csv]) else error "Actualisation R requise : exports non courants",'),
      "\t\t\t  Header = Table.PromoteHeaders(Raw, [PromoteAllScalars=true]),",
      "\t\t\t  Missing = Table.ReplaceValue(Header, \"\", null, Replacer.ReplaceValue, Table.ColumnNames(Header)),",
      paste0("\t\t\t  Typed = Table.TransformColumnTypes(Missing, {", types, "}, \"en-US\")"),
      "\t\t\tin Typed")
    writeLines(c(paste("table", table), "", columns, if (table == "FactIndicateur") c(measures, ""), partition),
      fs::path(model, "definition", "tables", paste0(table, ".tmdl")), useBytes = TRUE)
  }
  keys <- c(DimIndicateur = "id", DimAnnee = "annee_universitaire", DimDiplome = "type_diplome")
  relationships <- unlist(lapply(names(keys), function(dim) c(paste("relationship", paste0("rel_", dim)),
    paste0("\tfromColumn: FactIndicateur.", keys[[dim]]), paste0("\ttoColumn: ", dim, ".", keys[[dim]]),
    "\tcrossFilteringBehavior: oneDirection", "")))
  writeLines(relationships, fs::path(model, "definition", "relationships.tmdl"))
  field <- function(entity, property, measure = FALSE) {
    x <- list(Expression = list(SourceRef = list(Entity = entity)), Property = property)
    setNames(list(x), if (measure) "Measure" else "Column")
  }
  projection <- function(entity, property, measure = FALSE) list(field = field(entity, property, measure), queryRef = paste(entity, property, sep = "."))
  visual <- function(page, name, type, x, y, width, height, query = NULL, objects = NULL) {
    v <- list(visualType = type)
    if (!is.null(query)) v$query <- list(queryState = query)
    if (!is.null(objects)) v$objects <- objects
    write_json(list(`$schema` = schema("visualContainer", "2.0.0"), name = name,
      position = list(x = x, y = y, z = y, width = width, height = height, tabOrder = y), visual = v),
      fs::path(report, "definition", "pages", page, "visuals", name, "visual.json"))
  }
  pages <- dashboard_pages()
  labels <- c(inscriptions = "Inscriptions", reussite = "Reussite", parcours = "Parcours", enquetes = "Enquetes", insertion = "Insertion")
  write_json(list(`$schema` = schema("pagesMetadata", "1.0.0"), pageOrder = as.list(names(pages)), activePageName = "inscriptions"),
    fs::path(report, "definition", "pages", "pages.json"))
  for (page in names(pages)) {
    filter <- list(name = "ChampDeLaPage", field = field("DimIndicateur", "page"), type = "Categorical",
      filter = list(Version = 2, From = list(list(Name = "d", Entity = "DimIndicateur", Type = 0)),
        Where = list(list(Condition = list(In = list(Expressions = list(list(Column = list(Expression = list(SourceRef = list(Source = "d")), Property = "page"))),
          Values = list(list(list(Literal = list(Value = paste0("'", page, "'")))))))))))
    write_json(list(`$schema` = schema("page", "1.0.0"), name = page, displayName = labels[[page]],
      displayOption = "FitToPage", height = 900, width = 1440, filterConfig = list(filters = list(filter))),
      fs::path(report, "definition", "pages", page, "page.json"))
    paragraphs <- list(list(textRuns = list(list(value = paste0(labels[[page]],
      " — Donnees synthetiques, independant de l'UPEC. Gel 30/09/2026. Taux en %, sauf inscriptions en effectifs. Populations distinctes ; aucune causalite.")))))
    objects <- list(general = list(list(properties = list(paragraphs = paragraphs))))
    visual(page, "mention", "textbox", 20, 10, 1390, 80, objects = objects)
    visual(page, "annee", "slicer", 20, 100, 650, 100,
      list(Values = list(projections = list(projection("DimAnnee", "annee_universitaire")))))
    if (page == "insertion") visual(page, "diplome", "slicer", 700, 100, 690, 100,
      list(Values = list(projections = list(projection("DimDiplome", "type_diplome")))))
    visual(page, "evolution", "lineChart", 20, 220, 1390, 300,
      list(Category = list(projections = list(projection("DimAnnee", "annee_universitaire"))),
        Y = list(projections = list(projection("FactIndicateur", "Valeur controlee", TRUE))),
        Series = list(projections = list(projection("DimIndicateur", "libelle")))))
    values <- list(projection("DimAnnee", "annee_universitaire"), projection("DimIndicateur", "libelle"),
      projection("DimIndicateur", "unite"), projection("DimDiplome", "type_diplome"),
      projection("FactIndicateur", "Valeur controlee", TRUE), projection("FactIndicateur", "Numerateur affiche", TRUE),
      projection("FactIndicateur", "Denominateur affiche", TRUE), projection("FactIndicateur", "Couverture pct", TRUE),
      projection("FactIndicateur", "Lecture du statut", TRUE))
    visual(page, "detail", "tableEx", 20, 540, 1390, 340, list(Values = list(projections = values)))
  }
  invisible(root)
}
