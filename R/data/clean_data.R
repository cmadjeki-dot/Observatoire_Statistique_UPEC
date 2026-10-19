# Nettoyage conservateur des anomalies controlees, sans imputation statistique.
# Prerequis : source R/quality/check_quality.R.

#' Corriger les seules injections documentees, puis recontroler toute la base
#' @param dataset Liste de tables synthetiques et metadata.
#' @param issues Journal original de inject_quality_issues(), ou NULL.
#' @return Liste data, journal, before et after. Aucune ecriture sur disque.
#' @details Les coordonnees du journal concernent la copie brute non triee.
#' Une cible modifiee, un journal incomplet ou une erreur residuelle bloque
#' le traitement. Les valeurs initiales constituent une preuve propre a cette
#' simulation ; elles ne sont pas disponibles dans une enquete reelle.
clean_data <- function(dataset, issues = NULL) {
  before <- check_quality(dataset, label = "avant_nettoyage")
  if (!identical(dataset$metadata$provenance, "entierement_synthetique_non_officiel"))
    stop("Provenance synthetique requise.", call. = FALSE)
  cleaned <- dataset
  journal <- data.frame()
  if (!is.null(issues) && !is.data.frame(issues))
    stop("Journal incomplet : une table est requise.", call. = FALSE)
  if (!is.null(issues) && nrow(issues) > 0L) {
    required <- c("type", "table", "ligne", "cle", "champ", "valeur_initiale",
      "valeur_injectee", "controle_attendu", "id_anomalie")
    if (!is.data.frame(issues) || !all(required %in% names(issues)) ||
        anyNA(issues[c("type", "table", "ligne", "cle", "champ", "valeur_injectee",
          "controle_attendu", "id_anomalie")]) || anyDuplicated(issues$id_anomalie))
      stop("Journal incomplet ou identifiants dupliques.", call. = FALSE)
    policy <- data.frame(
      type = c("doublon_cle", "reference_orpheline", "valeur_hors_domaine",
        "date_incoherente", "transition_impossible"),
      table = c("inscriptions", "inscriptions", "resultats", "decisions_diplome", "parcours"),
      champ = c("id_inscription", "id_etudiant", "moyenne_annuelle",
        "date_decision_diplome", "id_inscription_suivante"),
      regle = c("unicite_inscription", "reference_etudiant", "domaine_moyenne",
        "chronologie_diplome", "annee_transition_suivante"), stringsAsFactors = FALSE)
    p <- match(issues$type, policy$type)
    if (anyNA(p) || any(issues$table != policy$table[p]) ||
        any(issues$champ != policy$champ[p]) ||
        any(issues$controle_attendu != policy$regle[p]) ||
        anyDuplicated(paste(issues$table, issues$ligne, issues$champ)))
      stop("Politique de correction inconnue ou cibles dupliquees.", call. = FALSE)
    detection <- match_quality_injections(before, issues)
    if (!all(detection$detectee))
      stop("Journal obsolete : une anomalie cible n'est pas detectee.", call. = FALSE)
    key_fields <- c(inscriptions = "id_inscription", resultats = "id_inscription",
      decisions_diplome = "id_inscription", parcours = "id_inscription_depart")
    deleted <- integer()
    # Toutes les verifications precedent les suppressions, pour conserver les indices.
    for (i in seq_len(nrow(issues))) {
      item <- issues[i, ]
      tab <- dataset[[item$table]]
      row <- item$ligne
      if (row < 1L || row != as.integer(row) || row > nrow(tab) ||
          !identical(as.character(tab[[item$champ]][row]), item$valeur_injectee) ||
          !identical(as.character(tab[[key_fields[[item$table]]]][row]), item$cle))
        stop("Journal obsolete : coordonnee, cle ou valeur cible differente.", call. = FALSE)
      if (item$type == "doublon_cle") {
        candidates <- which(tab$id_inscription == item$cle & seq_len(nrow(tab)) < row)
        exact_copy <- any(vapply(candidates, function(j) {
          all(vapply(names(tab), function(field)
            identical(tab[[field]][j], tab[[field]][row]), logical(1)))
        }, logical(1)))
        if (!is.na(item$valeur_initiale) || !exact_copy)
          stop("Suppression refusee : doublon non strictement identique.", call. = FALSE)
        deleted <- c(deleted, row)
      } else {
        prototype <- tab[[item$champ]]
        value <- item$valeur_initiale
        if (inherits(prototype, "Date")) {
          parsed <- as.Date(value, format = "%Y-%m-%d")
          if (!is.na(value) && (is.na(parsed) || as.character(parsed) != value))
            stop("Date initiale invalide dans le journal.", call. = FALSE)
        } else if (is.numeric(prototype)) {
          parsed <- suppressWarnings(as.numeric(value))
          if (!is.na(value) && (is.na(parsed) || !is.finite(parsed)))
            stop("Nombre initial invalide dans le journal.", call. = FALSE)
          if (is.integer(prototype)) {
            if (!is.na(parsed) && parsed != as.integer(parsed))
              stop("Entier initial invalide.", call. = FALSE)
            parsed <- as.integer(parsed)
          }
        } else if (is.character(prototype)) parsed <- value
        else stop("Type de correction non pris en charge.", call. = FALSE)
        cleaned[[item$table]][[item$champ]][row] <- parsed
      }
    }
    if (length(deleted)) {
      cleaned$inscriptions <- cleaned$inscriptions[-deleted, , drop = FALSE]
      rownames(cleaned$inscriptions) <- NULL
    }
    journal <- issues
    journal$action <- ifelse(issues$type == "doublon_cle",
      "suppression_copie_stricte_documentee", "restauration_valeur_initiale_documentee")
  }
  after <- check_quality(cleaned, label = "apres_nettoyage")
  if (!identical(after$metadata$verdict, "conforme"))
    stop("Preparation bloquee : anomalies residuelles ou controles incomplets ; aucune imputation automatique.",
      call. = FALSE)
  cleaned$metadata$nettoyage <- list(version = "0.1", n_actions = nrow(journal),
    methode = "journal_injections_uniquement_sans_imputation",
    controles = after$metadata$version_controles)
  list(data = cleaned, journal = journal, before = before, after = after)
}

#' Preparer les tables normalisees et une table inscription pour les analyses
#' @param dataset Base ayant passe les controles de qualite.
#' @return Onze tables normalisees, scolarite_analytique et metadata.
#' @details Les jointures doivent etre plusieurs-vers-un. La cible logique reste
#' NA lorsque la decision est inconnue ; aucune non-reponse n'est codee FALSE.
prepare_analytic_tables <- function(dataset) {
  report <- check_quality(dataset, label = "preparation")
  if (!identical(report$metadata$verdict, "conforme"))
    stop("Base non conforme : preparation refusee.", call. = FALSE)
  tables <- dataset[names(quality_schema())]
  academic <- dplyr::left_join(tables$inscriptions, tables$etudiants,
    by = "id_etudiant", relationship = "many-to-one")
  academic <- dplyr::left_join(academic, tables$formations,
    by = "id_formation", relationship = "many-to-one")
  academic <- dplyr::left_join(academic, tables$resultats,
    by = "id_inscription", relationship = "many-to-one")
  academic <- dplyr::left_join(academic, tables$parcours,
    by = c("id_inscription" = "id_inscription_depart"), relationship = "many-to-one")
  academic$decision_connue <- academic$validation_annuelle %in% c("oui", "non")
  academic$cible_reussite <- ifelse(academic$decision_connue,
    academic$validation_annuelle == "oui", NA)
  academic$transition_observable <- academic$annee_universitaire !=
    tail(dataset$metadata$config$annees, 1L)
  if (length(academic$transition_observable) != nrow(academic))
    stop("Configuration des annees absente.", call. = FALSE)
  stopifnot(nrow(academic) == nrow(tables$inscriptions),
    !anyDuplicated(academic$id_inscription))
  c(tables, list(scolarite_analytique = academic, metadata = dataset$metadata))
}

#' Sauvegarder la preparation et son audit sans ecrasement divergent
#' @param prepared Resultat de prepare_analytic_tables().
#' @param audit Liste contenant journal, controles et empreintes des sources.
#' @param directory Repertoire de sortie, data/processed par defaut.
#' @return Manifeste des fichiers RDS, avec tailles et empreintes.
save_processed_tables <- function(prepared, audit,
    directory = here::here("data", "processed")) {
  expected <- c(names(quality_schema()), "scolarite_analytique", "metadata")
  if (!identical(names(prepared), expected)) stop("Tables preparees incompletes.", call. = FALSE)
  objects <- c(prepared, list(audit_nettoyage = audit))
  paths <- fs::path(directory, paste0(names(objects), ".rds"))
  for (i in seq_along(objects)) {
    if (fs::file_exists(paths[i]) && !identical(readRDS(paths[i]), objects[[i]]))
      stop("Ecrasement refuse : fichier analytique different : ", basename(paths[i]), call. = FALSE)
  }
  manifest_path <- fs::path(directory, "manifest_preparation.csv")
  if (fs::file_exists(manifest_path)) {
    previous <- utils::read.csv(manifest_path, stringsAsFactors = FALSE)
    if (!all(fs::file_exists(paths)) ||
        !identical(previous$fichier, basename(paths)) ||
        !identical(previous$md5, unname(tools::md5sum(paths))))
      stop("Manifeste analytique incoherent.", call. = FALSE)
    return(previous)
  }
  fs::dir_create(directory)
  for (i in seq_along(objects)) {
    if (!fs::file_exists(paths[i])) saveRDS(objects[[i]], paths[i], version = 3)
    stopifnot(identical(readRDS(paths[i]), objects[[i]]))
  }
  manifest <- data.frame(objet = names(objects), fichier = basename(paths),
    lignes = vapply(objects, function(x) if (is.data.frame(x)) nrow(x) else NA_integer_, integer(1)),
    octets = as.numeric(file.info(paths)$size), md5 = unname(tools::md5sum(paths)),
    row.names = NULL)
  utils::write.csv(manifest, manifest_path, row.names = FALSE, na = "", fileEncoding = "UTF-8")
  manifest
}
