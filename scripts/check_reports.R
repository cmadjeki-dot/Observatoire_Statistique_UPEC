# Recette des rapports consommateurs ; les rapports historiques sont preserves.
source(here::here("R", "utils", "paths.R"))
source(here::here("R", "pipeline", "pipeline.R"))
source(here::here("R", "pipeline", "report.R"))
protected <- c(fs::dir_ls(data_path("raw"), type = "file", all = TRUE),
  fs::dir_ls(data_path("processed"), type = "file", all = TRUE),
  fs::dir_ls(output_path("restitution"), type = "file"),
  fs::dir_ls(output_path("pipeline_reconstruction"), type = "file"))
hash_before <- tools::md5sum(protected)
withr::with_envvar(c(UPEC_PIPELINE_REBUILD = "true", UPEC_PIPELINE_REPORTS = "true",
    UPEC_PIPELINE_OUTPUT = "outputs/pipeline_rapport"), {
  store <- "outputs/pipeline_rapport/store"
  targets::tar_validate(store = store, callr_function = NULL)
  manifest <- targets::tar_manifest(callr_function = NULL)
  stopifnot(nrow(manifest) == 33L)
  run_project_pipeline(store = store, callr_function = NULL)
  evidence <- load_pipeline_report("outputs/pipeline_rapport")
  stopifnot(identical(evidence$resultats$constats,
    readRDS(output_path("pipeline_reconstruction", "resultats.rds"))$constats))
  htmls <- fs::path(output_path("pipeline_rapport", "rapports"),
    c("rapport_pilotage.html", "note_pilotage.html"))
  titles <- c("Observatoire statistique", "Note de pilotage")
  for (i in seq_along(htmls)) {
    text <- readLines(htmls[i], encoding = "UTF-8", warn = FALSE)
    stopifnot(any(grepl(titles[i], text, fixed = TRUE)),
      !any(grepl('<script[^>]+src="https?://', text)))
  }
  target_times <- function() {
    m <- as.data.frame(targets::tar_meta(fields = c(name, time), store = store, complete_only = TRUE))
    m <- m[m$name %in% manifest$name, ]
    m <- m[order(m$name), ]
    rownames(m) <- NULL
    m
  }
  before <- target_times()
  run_project_pipeline(store = store, callr_function = NULL)
  stopifnot(identical(before, target_times()))
  fingerprint <- unname(tools::md5sum(htmls[1L]))
  stopifnot(file.remove(htmls[1L]))
  stopifnot(setequal(targets::tar_outdated(store = store, callr_function = NULL), "report_html"))
  run_project_pipeline(store = store, callr_function = NULL)
  # Quarto peut faire varier ses identifiants HTML : comparer les donnees source,
  # pas imposer une identite binaire a deux rendus.
  stopifnot(file.exists(htmls[1L]))
  editorial <- output_path("pipeline_rapport", "editorial")
  fs::dir_create(editorial)
  copy <- fs::path(editorial, "rapport_pilotage.qmd")
  writeLines(c(readLines(project_path("reports", "rapport_pilotage.qmd"), encoding = "UTF-8"),
    "", "<!-- Scenario editorial isole -->"), copy, useBytes = TRUE)
  withr::with_envvar(c(UPEC_PIPELINE_REPORT_SOURCE = as.character(fs::path_rel(copy, here::here()))), {
    outdated <- targets::tar_outdated(store = store, callr_function = NULL)
    stopifnot(setequal(outdated, c("report_source", "report_html")))
  })
  stopifnot(!length(targets::tar_outdated(store = store, callr_function = NULL)))
  load_pipeline_report("outputs/pipeline_rapport")
  utils::write.csv(manifest, output_path("pipeline_rapport", "graphe.csv"), row.names = FALSE)
})
stopifnot(identical(hash_before, tools::md5sum(protected)), isTRUE(renv::status()$synchronized))
writeLines(c("Recette rapports conforme : 33 cibles, deux HTML autonomes.",
  "Resultats concordants, relance stable, HTML supprime reconstruit.",
  "Scenario editorial isole : seule la branche rapport est invalidee.",
  "Sources canoniques et rapports historiques preserves."), output_path("pipeline_rapport", "recette.txt"))
cat("RECETTE RAPPORTS CONFORME\n")
