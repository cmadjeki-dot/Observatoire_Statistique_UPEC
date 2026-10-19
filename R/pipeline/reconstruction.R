# Reconstruction en memoire ; aucune ecriture dans data/raw ou data/processed.

#' Verifier la detection, reparer le journal et rapprocher les tables originales
pipeline_clean_reconstruction <- function(generated, injected) {
  original <- check_quality(generated, label = "generation")
  if (!identical(original$metadata$verdict, "conforme"))
    stop("Generation non conforme.", call. = FALSE)
  detection <- match_quality_injections(check_quality(injected$data), injected$issues)
  if (!all(detection$detectee)) stop("Injection non detectee.", call. = FALSE)
  cleaned <- clean_data(injected$data, injected$issues)
  tables <- names(quality_schema())
  if (!identical(cleaned$data[tables], generated[tables]))
    stop("Restauration des tables divergente.", call. = FALSE)
  cleaned$detection <- detection
  cleaned
}

#' Preparer les tables depuis le nettoyage controle sans lire de donnees sur disque
pipeline_prepare_reconstruction <- function(cleaned, environment_files = character()) {
  stopifnot(all(file.exists(environment_files)))
  prepared <- prepare_analytic_tables(cleaned$data)
  prepared$pipeline_quality <- cleaned$after
  prepared
}

#' Archiver les etats de reconstruction dans les sorties regenerables du pipeline
pipeline_export_reconstruction <- function(generated, injected, cleaned, prepared, directory) {
  directory <- fs::path(pipeline_output_directory(directory), "reconstruction")
  fs::dir_create(directory)
  objects <- list(base_synthetique = generated, base_synthetique_anomalies = injected$data,
    journal_anomalies = injected$issues, tables_preparees = prepared,
    audit_nettoyage = cleaned[c("journal", "before", "after", "detection")])
  paths <- as.character(fs::path(directory, paste0(names(objects), ".rds")))
  for (i in seq_along(objects)) saveRDS(objects[[i]], paths[i], version = 3)
  checks <- fs::path(directory, "controles.csv")
  utils::write.csv(rbind(transform(cleaned$before$checks, phase = "avant"),
    transform(cleaned$after$checks, phase = "apres")), checks, row.names = FALSE)
  files <- c(paths, as.character(checks))
  manifest <- fs::path(directory, "manifeste.csv")
  utils::write.csv(data.frame(fichier = basename(files), md5 = unname(tools::md5sum(files))),
    manifest, row.names = FALSE)
  c(files, as.character(manifest))
}
