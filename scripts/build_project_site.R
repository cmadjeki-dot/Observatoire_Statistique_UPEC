# Site statique GitHub Pages : uniquement des resultats synthetiques controles.
local({
  source(here::here("R", "utils", "paths.R"), local = TRUE)
  source(here::here("R", "pipeline", "pipeline.R"), local = TRUE)
  source(here::here("R", "pipeline", "report.R"), local = TRUE)
  evidence <- load_pipeline_report("outputs/pipeline_rapport")
  source(here::here("scripts", "check_dashboard_exports.R"), local = TRUE)
  destination <- output_path("site_github")
  fs::dir_create(destination)
  for (name in c("index.html", "style.css", "app.js"))
    fs::file_copy(project_path("site", name), fs::path(destination, name), overwrite = TRUE)
  facts <- utils::read.csv(output_path("pipeline_dashboard", "FactIndicateur.csv"),
    stringsAsFactors = FALSE)
  indicators <- utils::read.csv(output_path("pipeline_dashboard", "DimIndicateur.csv"),
    stringsAsFactors = FALSE)
  stopifnot(nrow(facts) == 33L, isTRUE(all.equal(facts$valeur,
    evidence$resultats$indicateurs$indicateurs$valeur, tolerance = 1e-12)))
  jsonlite::write_json(list(rows = facts, indicators = indicators,
    date_gel = evidence$resultats$qualite$metadata$date_gel,
    generated = format(Sys.Date(), "%Y-%m-%d")), fs::path(destination, "data.json"),
    dataframe = "rows", auto_unbox = TRUE, na = "null", digits = NA, pretty = TRUE)
  report <- output_path("rapport_final", "rapport_final.html")
  withr::with_envvar(c(QUARTO_R = fs::path(R.home(), "bin")),
    quarto::quarto_render("docs/rapport_final.qmd", output_format = "html",
      quarto_args = c("--output-dir", "../outputs/rapport_final"),
      execute_dir = here::here(), quiet = FALSE))
  stopifnot(file.exists(report))
  inputs <- c("docs/rapport_final.qmd", "outputs/rapport_final/rapport_final.html",
    "outputs/pipeline_rapport/produits.csv", "outputs/pipeline_rapport/sources.csv",
    "R/pipeline/report.R", "renv.lock")
  utils::write.csv(data.frame(fichier = inputs, md5 = unname(tools::md5sum(inputs))),
    output_path("rapport_final", "manifeste_rendu.csv"), row.names = FALSE)
  manifest <- utils::read.csv(output_path("rapport_final", "manifeste_rendu.csv"))
  stopifnot(identical(unname(tools::md5sum(manifest$fichier)), manifest$md5))
  fs::file_copy(report, fs::path(destination, "rapport_final.html"), overwrite = TRUE)
  writeLines(character(), fs::path(destination, ".nojekyll"))
  cat("Site genere dans outputs/site_github : 33 valeurs controlees et rapport autonome.\n")
})
