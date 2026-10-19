# Orchestration du pipeline aval, sources et anciens rapports preserves.
pipeline_input_files <- function(directory) {
  directory <- project_path(directory)
  files <- c(fs::path(directory, paste0(c(names(quality_schema()),
    "scolarite_analytique", "metadata", "audit_nettoyage"), ".rds")),
    fs::path(directory, "manifest_preparation.csv"))
  if (!all(file.exists(files))) stop("Entrees preparees incompletes.", call. = FALSE)
  as.character(files)
}

#' Bloquer les analyses si qualite ou reconstruction divergent
pipeline_validate <- function(files, environment_files) {
  stopifnot(all(file.exists(environment_files)))
  input <- load_descriptive_source(dirname(files[1L]))
  if (!setequal(input$sources$fichier, basename(files)[basename(files) != "manifest_preparation.csv"]))
    stop("Manifeste et fichiers suivis divergents.", call. = FALSE)
  dataset <- setNames(lapply(names(quality_schema()), function(name)
    readRDS(fs::path(dirname(files[1L]), paste0(name, ".rds")))), names(quality_schema()))
  dataset$metadata <- input$metadata
  report <- check_quality(dataset, label = "pipeline")
  if (!identical(report$metadata$verdict, "conforme"))
    stop("Qualite non conforme : analyses bloquees (", report$metadata$n_alertes,
      " alertes).", call. = FALSE)
  prepared <- prepare_analytic_tables(dataset)
  if (!identical(prepared$scolarite_analytique, input$data))
    stop("Reconstruction analytique divergente.", call. = FALSE)
  prepared$pipeline_quality <- report
  prepared
}

#' Verifier le gel et la protection de diffusion
pipeline_read_config <- function(file, metadata) {
  config <- read_indicator_config(file)
  if (!identical(config$date_gel, as.character(metadata$config$date_gel)) ||
      config$seuil_minimum_taux < metadata$config$diffusion$seuil_minimum_taux)
    stop("Configuration incompatible avec le gel ou le seuil source.", call. = FALSE)
  config
}

#' Restitutions d'enquete sans lecture d'anciens exports
pipeline_surveys <- function(surveys) {
  list(evaluation_annuelle = summarise_evaluation(surveys$evaluation),
    distribution_globale = evaluation_distribution(surveys$evaluation),
    non_reponse = survey_nonresponse(surveys$evaluation),
    relations_items = survey_item_relations(surveys$evaluation),
    devenir_cohortes = summarise_graduate_survey(surveys$devenir))
}

#' Limiter les ecritures aux sorties propres au pipeline
pipeline_output_directory <- function(directory) {
  path <- as.character(project_path(directory))
  relative <- as.character(fs::path_rel(path, project_path("outputs")))
  if (!grepl("^pipeline($|[_/\\\\])", relative))
    stop("Sortie reservee a outputs/pipeline ou outputs/pipeline_*.", call. = FALSE)
  path
}

#' Exporter et retourner tous les chemins suivis
pipeline_export <- function(results, model, sources, directory) {
  directory <- pipeline_output_directory(directory)
  fs::dir_create(directory)
  products <- c("resultats.rds", "modele_reussite.rds", "indicateurs.csv",
    "constats.csv", "synthese_pilotage.md", "sources.csv")
  files <- as.character(fs::path(directory, products))
  saveRDS(results, files[1L], version = 3)
  saveRDS(model, files[2L], version = 3)
  utils::write.csv(results$indicateurs$indicateurs, files[3L], row.names = FALSE,
    na = "", fileEncoding = "UTF-8")
  utils::write.csv(results$constats, files[4L], row.names = FALSE, fileEncoding = "UTF-8")
  writeLines(enc2utf8(format_restitution_markdown(results$constats)), files[5L], useBytes = TRUE)
  manifest <- data.frame(fichier = as.character(fs::path_rel(sources, here::here())),
    md5 = unname(tools::md5sum(sources)))
  utils::write.csv(manifest, files[6L], row.names = FALSE)
  output_manifest <- fs::path(directory, "produits.csv")
  utils::write.csv(data.frame(fichier = basename(files), md5 = unname(tools::md5sum(files))),
    output_manifest, row.names = FALSE)
  c(files, as.character(output_manifest))
}

#' Executer et journaliser succes ou echec
#' @details Un ancien export ne vaut pas succes si le dernier statut est echec.
run_project_pipeline <- function(store = "_targets", directory = Sys.getenv(
    "UPEC_PIPELINE_OUTPUT", "outputs/pipeline"), callr_function) {
  directory <- pipeline_output_directory(directory)
  fs::dir_create(directory)
  started <- format(Sys.time(), tz = "UTC", usetz = TRUE)
  journal <- function(status, message = "") {
    record <- data.frame(debut_utc = started,
      fin_utc = format(Sys.time(), tz = "UTC", usetz = TRUE), statut = status,
      message = message, store = store)
    utils::write.csv(record, fs::path(directory, "statut.csv"), row.names = FALSE,
      fileEncoding = "UTF-8")
    history <- fs::path(directory, "journal.csv")
    utils::write.table(record, history, sep = ",", row.names = FALSE,
      col.names = !file.exists(history), append = file.exists(history), fileEncoding = "UTF-8")
  }
  journal("en_cours")
  tryCatch({
    if (!isTRUE(renv::status()$synchronized)) stop("renv non synchronise.", call. = FALSE)
    # Environnement racine identique pour lancement et diagnostic.
    # Sans surcharge, targets utilise son processus R isole par defaut.
    arguments <- list(store = store, envir = globalenv())
    if (!missing(callr_function)) arguments["callr_function"] <- list(callr_function)
    do.call(targets::tar_make, arguments)
    if (length(do.call(targets::tar_outdated, arguments))) stop("Cibles encore perimees.")
    journal("succes")
  }, error = function(e) {
    journal("echec", conditionMessage(e))
    stop(e)
  })
  invisible(TRUE)
}
