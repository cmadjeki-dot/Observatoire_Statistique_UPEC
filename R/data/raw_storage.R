# Sauvegarde brute : aucune correction, conversion de colonnes ou suppression.

.raw_file_names <- c(dataset = "base_synthetique.rds",
  anomalies = "base_synthetique_anomalies.rds", issues = "journal_anomalies.rds")

#' Sauvegarder deux bases et leur journal sans ecraser l'existant
#' @param dataset Base coherente produite par generate_dataset().
#' @param injected Resultat de inject_quality_issues(dataset).
#' @param directory Dossier de sortie ; data/raw par defaut.
#' @return Manifeste des trois fichiers, avec effectifs, tailles et empreintes MD5.
#' @details Un fichier identique est reutilise. Une difference provoque une erreur
#'   avant toute ecriture. Un changement volontaire demande un nouveau dossier.
save_raw_dataset <- function(dataset, injected, directory = here::here("data", "raw")) {
  if (!identical(dataset$metadata$provenance, "entierement_synthetique_non_officiel") ||
      !identical(dataset$metadata$anomalies_injectees, FALSE) ||
      !identical(injected$data$metadata$anomalies_injectees, TRUE) ||
      !is.data.frame(injected$issues) ||
      !identical(dataset$metadata$config, injected$data$metadata$config))
    stop("Bases et journal de provenance synthetique compatibles requis.", call. = FALSE)
  objects <- list(dataset = dataset, anomalies = injected$data, issues = injected$issues)
  directory <- fs::path_abs(directory)
  paths <- fs::path(directory, unname(.raw_file_names))
  names(paths) <- names(objects)
  manifest_path <- fs::path(directory, "manifest_generation.csv")
  existing <- fs::file_exists(paths)
  # Verifier tous les fichiers existants avant de creer les fichiers manquants.
  for (key in names(objects)[existing]) {
    if (!identical(readRDS(paths[[key]]), objects[[key]]))
      stop("Ecrasement refuse : fichier brut different : ", basename(paths[[key]]), call. = FALSE)
  }
  if (fs::file_exists(manifest_path)) {
    if (!all(existing)) stop("Manifeste present mais fichier brut manquant.", call. = FALSE)
    previous <- load_raw_dataset(directory)$manifest
    return(previous)
  }
  fs::dir_create(directory)
  for (key in names(objects)[!existing]) saveRDS(objects[[key]], paths[[key]], version = 3, compress = "gzip")
  for (key in names(objects)) {
    if (!identical(readRDS(paths[[key]]), objects[[key]]))
      stop("Echec de relecture du fichier brut : ", basename(paths[[key]]), call. = FALSE)
  }
  manifest <- data.frame(
    objet = names(objects), fichier = unname(.raw_file_names),
    provenance = rep("entierement_synthetique_non_officiel", 3L),
    version_simulateur = rep(dataset$metadata$version_simulateur, 3L),
    date_gel = rep(as.character(dataset$metadata$config$date_gel), 3L),
    version_r_ecriture = rep(R.version.string, 3L),
    n_etudiants = c(nrow(dataset$etudiants), nrow(injected$data$etudiants), NA_integer_),
    n_inscriptions = c(nrow(dataset$inscriptions), nrow(injected$data$inscriptions), NA_integer_),
    n_anomalies = c(0L, nrow(injected$issues), nrow(injected$issues)),
    octets = as.numeric(file.info(paths)$size), md5 = unname(tools::md5sum(paths)),
    stringsAsFactors = FALSE)
  utils::write.csv(manifest, manifest_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  manifest
}

#' Relire les sauvegardes brutes avec verification d'integrite
#' @param directory Dossier cree par save_raw_dataset().
#' @return Liste dataset, anomalies, issues et manifest ; aucun nettoyage.
load_raw_dataset <- function(directory = here::here("data", "raw")) {
  manifest_path <- fs::path(directory, "manifest_generation.csv")
  if (!fs::file_exists(manifest_path)) stop("Manifeste brut introuvable.", call. = FALSE)
  manifest <- utils::read.csv(manifest_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8")
  required <- c("objet", "fichier", "provenance", "version_simulateur", "date_gel",
    "version_r_ecriture", "n_etudiants", "n_inscriptions", "n_anomalies", "octets", "md5")
  if (!identical(names(manifest), required) || nrow(manifest) != 3L ||
      !identical(manifest$objet, names(.raw_file_names)) ||
      !identical(manifest$fichier, unname(.raw_file_names)) || anyNA(manifest$md5) ||
      !all(manifest$provenance == "entierement_synthetique_non_officiel"))
    stop("Structure du manifeste brut invalide.", call. = FALSE)
  paths <- fs::path(directory, manifest$fichier)
  if (!all(fs::file_exists(paths))) stop("Fichier brut manquant.", call. = FALSE)
  if (!identical(unname(tools::md5sum(paths)), manifest$md5) ||
      !all(as.numeric(file.info(paths)$size) == manifest$octets))
    stop("Integrite MD5 ou taille des fichiers bruts invalide.", call. = FALSE)
  objects <- setNames(lapply(paths, readRDS), names(.raw_file_names))
  c(objects, list(manifest = manifest))
}
