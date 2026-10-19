# Statistiques descriptives I01-I05. Aucun modele ni interpretation causale.

#' Relire la source analytique apres verification du manifeste et des empreintes
#' @param directory Repertoire de preparation.
#' @return Liste data, metadata et sources (manifeste verifie).
load_descriptive_source <- function(directory = here::here("data", "processed")) {
  manifest <- utils::read.csv(fs::path(directory, "manifest_preparation.csv"),
    stringsAsFactors = FALSE)
  if (!all(c("objet", "fichier", "md5", "octets") %in% names(manifest)) ||
      anyNA(manifest[c("objet", "fichier", "md5", "octets")]))
    stop("Manifeste analytique invalide.", call. = FALSE)
  if (anyDuplicated(manifest$objet) || anyDuplicated(manifest$fichier) ||
      !all(grepl("^[A-Za-z_]+[.]rds$", manifest$fichier)) ||
      !all(c("scolarite_analytique", "metadata") %in% manifest$objet))
    stop("Fichiers analytiques invalides.", call. = FALSE)
  paths <- fs::path(directory, manifest$fichier)
  if (!all(fs::file_exists(paths)) ||
      !identical(unname(tools::md5sum(paths)), manifest$md5) ||
      !all(as.numeric(file.info(paths)$size) == manifest$octets))
    stop("Integrite analytique invalide.", call. = FALSE)
  get <- function(name) readRDS(paths[match(name, manifest$objet)])
  metadata <- get("metadata")
  if (!identical(metadata$provenance, "entierement_synthetique_non_officiel"))
    stop("Provenance synthetique requise.", call. = FALSE)
  list(data = get("scolarite_analytique"), metadata = metadata, sources = manifest)
}

.descriptive_check <- function(data, groups, min_denominator) {
  required <- c("id_inscription", "id_etudiant", "annee_universitaire",
    "statut_inscription", "validation_annuelle", "etat_transition", "transition_observable")
  if (!is.data.frame(data) || !all(c(required, groups) %in% names(data)) ||
      !is.character(groups) || anyNA(groups) || anyDuplicated(groups) ||
      anyNA(data[required]) || anyDuplicated(data$id_inscription) ||
      anyDuplicated(data[c("id_etudiant", "annee_universitaire")]) ||
      !all(data$statut_inscription %in% c("active", "annulee")) ||
      !all(data$validation_annuelle %in% c("oui", "non", "inconnu")) ||
      !is.logical(data$transition_observable))
    stop("Schema, domaines ou cles analytiques invalides.", call. = FALSE)
  if (length(min_denominator) != 1L || !is.numeric(min_denominator) ||
      is.na(min_denominator) || !is.finite(min_denominator) ||
      min_denominator < 1 || min_denominator != floor(min_denominator))
    stop("Seuil entier positif requis.", call. = FALSE)
  data[data$statut_inscription == "active", , drop = FALSE]
}

.descriptive_rate <- function(num, den, threshold) {
  ifelse(den >= threshold, 100 * num / pmax(den, 1), NA_real_)
}

#' Compter inscriptions et etudiants distincts sans sommer les annees
#' @param data Table scolarite_analytique.
#' @return Liste annuel et panel ; evolution sur l'effectif de l'annee precedente.
describe_enrolments <- function(data) {
  x <- .descriptive_check(data, character(), 10L)
  annual <- dplyr::summarise(dplyr::group_by(x, .data$annee_universitaire),
    n_inscriptions = dplyr::n(), n_etudiants = dplyr::n_distinct(.data$id_etudiant),
    .groups = "drop")
  annual <- dplyr::arrange(annual, .data$annee_universitaire)
  annual$n_precedent <- dplyr::lag(annual$n_inscriptions)
  annual$variation_effectif <- annual$n_inscriptions - annual$n_precedent
  annual$evolution_pct <- .descriptive_rate(annual$variation_effectif, annual$n_precedent, 10L)
  list(annuel = as.data.frame(annual), panel = data.frame(
    periode = "Union des annees observees", n_inscriptions = nrow(x),
    n_etudiants = dplyr::n_distinct(x$id_etudiant)))
}

#' Decrire les caracteristiques annuelles, NA inclus au denominateur
#' @param data Table scolarite_analytique.
#' @param variables Caracteristiques a compter ; unite inscription annuelle.
#' @param min_denominator Seuil de diffusion des pourcentages.
#' @return Table longue avec modalites manquantes explicitement marquees.
describe_characteristics <- function(data,
    variables = c("type_bac", "boursier", "parcours_anterieur", "niveau", "libelle_formation"),
    min_denominator = 10L) {
  if (!length(variables)) stop("Une caracteristique est requise.", call. = FALSE)
  x <- .descriptive_check(data, variables, min_denominator)
  out <- lapply(variables, function(variable) {
    z <- data.frame(annee_universitaire = x$annee_universitaire,
      modalite = as.character(x[[variable]]), est_manquant = is.na(x[[variable]]))
    z <- dplyr::count(z, .data$annee_universitaire, .data$modalite, .data$est_manquant,
      name = "effectif")
    z <- dplyr::mutate(dplyr::group_by(z, .data$annee_universitaire),
      denominateur = sum(.data$effectif),
      pourcentage = .descriptive_rate(.data$effectif, .data$denominateur, min_denominator))
    z <- dplyr::ungroup(z)
    z$variable <- variable
    as.data.frame(z)
  })
  dplyr::bind_rows(out)
}

#' Calculer I03/I04 par groupes avec couverture et borne basse
#' @param data Table scolarite_analytique.
#' @param groups Dimensions de ventilation ; character() pour le cumul.
#' @param min_denominator Seuil de diffusion.
#' @return Effectifs et taux ; inconnus exclus uniquement du taux principal.
describe_success <- function(data, groups = "annee_universitaire", min_denominator = 10L) {
  x <- .descriptive_check(data, groups, min_denominator)
  x <- dplyr::group_by(x, dplyr::across(dplyr::all_of(groups)))
  out <- dplyr::summarise(x, n_inscriptions = dplyr::n(),
    n_validees = sum(.data$validation_annuelle == "oui"),
    n_non_validees = sum(.data$validation_annuelle == "non"),
    n_inconnues = sum(.data$validation_annuelle == "inconnu"), .groups = "drop")
  out$n_decisions_connues <- out$n_validees + out$n_non_validees
  out$couverture_pct <- .descriptive_rate(out$n_decisions_connues, out$n_inscriptions, min_denominator)
  out$part_inconnues_pct <- .descriptive_rate(out$n_inconnues, out$n_inscriptions, min_denominator)
  out$taux_validation_connus_pct <- .descriptive_rate(out$n_validees, out$n_decisions_connues, min_denominator)
  out$borne_basse_validation_pct <- .descriptive_rate(out$n_validees, out$n_inscriptions, min_denominator)
  out$statut_diffusion <- ifelse(out$n_decisions_connues < min_denominator,
    "effectif insuffisant", "diffusable")
  as.data.frame(out)
}

#' Decrire les six transitions I05, sans les departs censures
#' @param data Table scolarite_analytique.
#' @param groups Dimensions contenant obligatoirement l'annee de depart.
#' @param min_denominator Seuil de diffusion.
#' @return Six lignes par groupe observable ; denominateur incluant les sorties.
describe_transitions <- function(data, groups = "annee_universitaire", min_denominator = 10L) {
  states <- c("passage", "redoublement", "reorientation", "sortie_observee", "poursuite_intercycle", "autre")
  x <- .descriptive_check(data, groups, min_denominator)
  if (!"annee_universitaire" %in% groups || !all(x$etat_transition[x$transition_observable] %in% states))
    stop("Annee de depart et transitions valides requises.", call. = FALSE)
  x <- x[x$transition_observable, , drop = FALSE]
  counts <- dplyr::count(x, dplyr::across(dplyr::all_of(c(groups, "etat_transition"))), name = "effectif")
  grid <- tidyr::expand_grid(unique(x[groups]), etat_transition = states)
  out <- dplyr::left_join(grid, counts, by = c(groups, "etat_transition"), relationship = "one-to-one")
  out$effectif[is.na(out$effectif)] <- 0L
  out <- dplyr::mutate(dplyr::group_by(out, dplyr::across(dplyr::all_of(groups))),
    denominateur = sum(.data$effectif),
    taux_pct = .descriptive_rate(.data$effectif, .data$denominateur, min_denominator),
    statut_diffusion = ifelse(.data$denominateur < min_denominator, "effectif insuffisant", "diffusable"))
  as.data.frame(dplyr::ungroup(out))
}

#' Construire les graphiques descriptifs a partir des tables calculees
#' @param enrolments Sortie de describe_enrolments().
#' @param success Validation par annee et niveau.
#' @param transitions Transitions par annee.
#' @return Liste de trois objets ggplot ; aucune ecriture.
plot_descriptive <- function(enrolments, success, transitions) {
  list(inscriptions = ggplot2::ggplot(enrolments$annuel,
      ggplot2::aes(x = .data$annee_universitaire, y = .data$n_inscriptions)) +
      ggplot2::geom_col(fill = "#22577A") + ggplot2::labs(x = NULL, y = "Inscriptions principales",
        title = "Inscriptions annuelles simulees") + ggplot2::theme_minimal(),
    reussite = ggplot2::ggplot(success,
      ggplot2::aes(x = .data$annee_universitaire, y = .data$taux_validation_connus_pct,
        colour = .data$niveau, group = .data$niveau)) +
      ggplot2::geom_line(na.rm = TRUE) + ggplot2::geom_point(na.rm = TRUE) +
      ggplot2::scale_y_continuous(limits = c(0, 100)) + ggplot2::labs(x = NULL,
        y = "Validation parmi decisions connues (%)", colour = "Niveau",
        title = "Validation annuelle simulee par niveau") + ggplot2::theme_minimal(),
    parcours = ggplot2::ggplot(transitions,
      ggplot2::aes(x = .data$annee_universitaire, y = .data$taux_pct, fill = .data$etat_transition)) +
      ggplot2::geom_col(na.rm = TRUE) + ggplot2::labs(x = "Annee de depart",
        y = "Part des inscriptions de depart (%)", fill = "Transition",
        title = "Transitions observees dans le panel synthetique") + ggplot2::theme_minimal())
}
