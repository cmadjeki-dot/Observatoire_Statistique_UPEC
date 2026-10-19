# Recette complete depuis les graines, puis rapprochement aux references.
source(here::here("R", "utils", "paths.R"))
source(here::here("R", "pipeline", "pipeline.R"))
protected <- c(fs::dir_ls(data_path("raw"), type = "file", all = TRUE),
  fs::dir_ls(data_path("processed"), type = "file", all = TRUE),
  fs::dir_ls(output_path("pipeline"), type = "file"),
  fs::dir_ls(output_path("restitution"), type = "file"))
hash_before <- tools::md5sum(protected)
withr::with_envvar(c(UPEC_PIPELINE_REBUILD = "true",
    UPEC_PIPELINE_OUTPUT = "outputs/pipeline_reconstruction"), {
  store <- "outputs/pipeline_reconstruction/store"
  targets::tar_validate(store = store, callr_function = NULL)
  manifest <- targets::tar_manifest(callr_function = NULL)
  stopifnot(nrow(manifest) == 27L,
    !any(grepl("pipeline_validate|pipeline_input_files", manifest$command)))
  run_project_pipeline(store = store, callr_function = NULL)
  same <- function(x, y) stopifnot(isTRUE(all.equal(x, y, check.attributes = TRUE)))
  directory <- output_path("pipeline_reconstruction", "reconstruction")
  same(readRDS(fs::path(directory, "base_synthetique.rds")),
    readRDS(data_path("raw", "base_synthetique.rds")))
  same(readRDS(fs::path(directory, "base_synthetique_anomalies.rds")),
    readRDS(data_path("raw", "base_synthetique_anomalies.rds")))
  same(readRDS(fs::path(directory, "journal_anomalies.rds")),
    readRDS(data_path("raw", "journal_anomalies.rds")))
  prepared <- readRDS(fs::path(directory, "tables_preparees.rds"))
  for (object in setdiff(names(prepared), "pipeline_quality"))
    same(prepared[[object]], readRDS(data_path("processed", paste0(object, ".rds"))))
  result <- readRDS(output_path("pipeline_reconstruction", "resultats.rds"))
  reference <- readRDS(output_path("pipeline", "resultats.rds"))
  same(result$indicateurs, reference$indicateurs)
  same(result$evaluation, reference$evaluation)
  same(result$constats, reference$constats)
  audit <- readRDS(fs::path(directory, "audit_nettoyage.rds"))
  stopifnot(nrow(audit$journal) == 50L, all(audit$detection$detectee),
    identical(audit$after$metadata$verdict, "conforme"))
  target_times <- function() {
    metadata <- targets::tar_meta(fields = c(name, time), store = store, complete_only = TRUE)
    metadata <- metadata[metadata$name %in% manifest$name, ]
    metadata <- metadata[order(metadata$name), ]
    rownames(metadata) <- NULL
    metadata
  }
  metadata <- target_times()
  run_project_pipeline(store = store, callr_function = NULL)
  same(metadata, target_times())
  stopifnot(!length(targets::tar_outdated(store = store, callr_function = NULL)))
  missing <- fs::path(directory, "journal_anomalies.rds")
  fingerprint <- unname(tools::md5sum(missing))
  stopifnot(file.remove(missing))
  stopifnot("reconstruction_files" %in% targets::tar_outdated(store = store, callr_function = NULL))
  run_project_pipeline(store = store, callr_function = NULL)
  stopifnot(identical(fingerprint, unname(tools::md5sum(missing))))
  utils::write.csv(manifest, output_path("pipeline_reconstruction", "graphe.csv"), row.names = FALSE)
})
stopifnot(identical(hash_before, tools::md5sum(protected)), isTRUE(renv::status()$synchronized))
writeLines(c("Reconstruction conforme depuis les graines : 27 cibles.",
  "Bases brutes, anomalies, journal et tables preparees concordants.",
  "Indicateurs, evaluation et constats concordants ; 50 anomalies reparees.",
  "Relance stable et archive manquante reconstruite ; sources preservees."),
  output_path("pipeline_reconstruction", "recette.txt"))
cat("RECETTE RECONSTRUCTION CONFORME\n")
