# Validation locale finale, sans installation ni mutation Git.
# Lancer depuis la racine avec Rscript --no-save --no-restore.
source(here::here("R", "utils", "paths.R"))
validation_directory <- output_path("validation_finale")
fs::dir_create(validation_directory)
records <- data.frame(controle = character(), statut = character(),
  detail = character(), avertissements = character(), secondes = numeric())
check <- function(name, action) {
  cat("\nCONTROLE :", name, "\n")
  start <- Sys.time()
  warnings <- character()
  error <- NULL
  result <- tryCatch(withCallingHandlers(action(), warning = function(w) {
    warnings <<- c(warnings, conditionMessage(w))
    # Les avertissements restent visibles ; leur presence est enregistree.
  }), error = function(e) { error <<- conditionMessage(e); NULL })
  records <<- rbind(records, data.frame(controle = name,
    statut = if (is.null(error)) "succes" else "echec",
    detail = if (is.null(error)) paste(result, collapse = " ; ") else error,
    avertissements = paste(unique(warnings), collapse = " ; "),
    secondes = as.numeric(difftime(Sys.time(), start, units = "secs"))))
  utils::write.csv(records, fs::path(validation_directory, "resultats_R.csv"), row.names = FALSE)
  cat(tail(records$statut, 1L), "\n")
  is.null(error)
}

code_ok <- check("audit_code", function() {
  files <- c(list.files(here::here("R"), pattern = "[.]R$", recursive = TRUE,
    full.names = TRUE), list.files(here::here("scripts"), pattern = "[.]R$",
    full.names = TRUE), here::here("_targets.R"), list.files(here::here("tests"),
    pattern = "[.]R$", recursive = TRUE, full.names = TRUE))
  invisible(lapply(files, parse))
  business <- list.files(here::here("R"), pattern = "[.]R$", recursive = TRUE,
    full.names = TRUE)
  risky <- vapply(business, function(f) any(grepl(
    "setwd\\s*\\(|install[.]packages\\s*\\(|(?<![[:alnum:]])[A-Za-z]:[/\\\\]",
    readLines(f, warn = FALSE), perl = TRUE)), logical(1))
  # Certaines expressions de controle peuvent mentionner les chemins interdits.
  utils::write.csv(data.frame(fichier = as.character(fs::path_rel(files, here::here())),
    md5 = unname(tools::md5sum(files))), fs::path(validation_directory, "inventaire_code.csv"),
    row.names = FALSE)
  flagged <- business[risky]
  if (length(flagged)) stop("Revue requise : ", paste(flagged, collapse = ", "))
  paste(length(files), "fichiers parses ; aucun motif interdit dans R/")
})
tests_ok <- check("tests_complets", function() {
  result <- testthat::test_dir(here::here("tests", "testthat"), reporter = "summary",
    stop_on_failure = TRUE)
  totals <- colSums(as.data.frame(result)[c("passed", "failed", "error", "warning")])
  utils::write.csv(data.frame(mesure = names(totals), valeur = unname(totals)),
    fs::path(validation_directory, "tests.csv"), row.names = FALSE)
  paste(names(totals), totals, collapse = ", ")
})
pipeline_ok <- check("targets_et_exports", function() {
  source(here::here("scripts", "refresh_dashboards.R"))
  source(here::here("scripts", "check_dashboard_exports.R"))
  "tar_make via lanceur ; reconstruction, rapports et 33 valeurs exportees conformes"
})
documents <- c("docs/rapport_final.qmd", "reports/presentation_orale.qmd",
  "notebooks/13_presentation_orale.qmd", "reports/discours_oral.qmd",
  "docs/simulation_jury.qmd")
if (pipeline_ok) for (document in documents) {
  check(paste0("quarto_", basename(document)), local({
    input <- document
    function() {
      destination <- if (basename(input) == "rapport_final.qmd")
        "outputs/rapport_final" else "outputs/presentation"
      format <- if (basename(input) == "presentation_orale.qmd") "revealjs" else "html"
      withr::with_envvar(c(QUARTO_R = fs::path(R.home(), "bin")),
        quarto::quarto_render(input, output_format = format,
          quarto_args = c("--output-dir", as.character(fs::path_rel(
            here::here(destination), dirname(here::here(input))))),
          execute_dir = here::here(), quiet = FALSE))
      html <- here::here(destination, paste0(tools::file_path_sans_ext(basename(input)), ".html"))
      stopifnot(file.exists(html), file.info(html)$size > 10000)
      as.character(fs::path_rel(html, here::here()))
    }
  }))
}
check("integrite_et_renv", function() {
  source(here::here("R", "pipeline", "pipeline.R"))
  source(here::here("R", "pipeline", "report.R"))
  load_pipeline_report("outputs/pipeline_rapport")
  stopifnot(isTRUE(renv::status()$synchronized))
  "Sources et produits conformes ; renv synchronise"
})
if (any(records$statut != "succes")) stop("Validation incomplete : consulter resultats_R.csv")
cat("\nVALIDATION R TERMINEE ; Shiny et Git a controler separement.\n")
