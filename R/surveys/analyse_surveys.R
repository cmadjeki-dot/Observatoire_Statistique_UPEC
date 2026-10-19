# Enquetes synthetiques : invitations comme population de reference, sans poids.
# Prerequis pour prepare_survey_tables : check_quality() et quality_schema().

#' Preparer les deux univers d'enquete apres controle complet
#' @param dataset Onze tables normalisees et metadata du projet.
#' @return Liste evaluation, devenir et eligibilite_diplomes. Aucune ecriture.
prepare_survey_tables <- function(dataset) {
  quality <- check_quality(dataset, label = "sources_enquetes")
  if (!identical(quality$metadata$verdict, "conforme"))
    stop("Sources non conformes : analyse des enquetes bloquee.", call. = FALSE)
  academic <- dplyr::left_join(dataset$inscriptions, dataset$etudiants,
    by = "id_etudiant", relationship = "many-to-one")
  academic <- dplyr::left_join(academic, dataset$formations,
    by = "id_formation", relationship = "many-to-one")
  academic <- dplyr::left_join(academic, dataset$resultats,
    by = "id_inscription", relationship = "one-to-one")
  academic <- dplyr::select(academic, dplyr::all_of(c("id_inscription", "id_etudiant",
    "annee_universitaire", "id_formation", "libelle_formation", "niveau", "type_bac",
    "boursier", "validation_annuelle")))
  evaluation <- dplyr::left_join(dataset$invitations_evaluation, academic,
    by = "id_inscription", relationship = "one-to-one")
  evaluation <- dplyr::left_join(evaluation, dataset$evaluations,
    by = "id_invitation_evaluation", relationship = "one-to-one")
  evaluation$a_repondu <- !is.na(evaluation$id_reponse_evaluation)
  evaluation$etat_global <- ifelse(!evaluation$a_repondu, "non_reponse_vague",
    ifelse(!is.na(evaluation$satisfaction_globale), "valide", evaluation$motif_satisfaction_globale))
  graduates <- dplyr::left_join(dataset$diplomes, academic,
    by = "id_inscription", relationship = "one-to-one")
  closure <- lubridate::`%m+%`(graduates$date_diplome,
    lubridate::period(dataset$metadata$config$devenir$cloture_mois, units = "months"))
  graduates$statut_eligibilite <- ifelse(closure > dataset$metadata$config$date_gel,
    "collecte_non_close", "diplome_mature_non_retenu")
  invited <- graduates$id_diplome %in% dataset$invitations_devenir$id_diplome
  graduates$statut_eligibilite[invited] <- "invite_reference"
  devenir <- dplyr::left_join(dataset$invitations_devenir, graduates,
    by = "id_diplome", relationship = "one-to-one")
  devenir <- dplyr::left_join(devenir, dataset$devenir_diplomes,
    by = "id_invitation_devenir", relationship = "one-to-one")
  devenir$a_repondu <- !is.na(devenir$id_reponse_devenir)
  devenir$situation_connue <- !is.na(devenir$situation_six_mois)
  stopifnot(nrow(evaluation) == nrow(dataset$invitations_evaluation),
    nrow(devenir) == nrow(dataset$invitations_devenir), !anyDuplicated(devenir$id_etudiant),
    all(devenir$date_cloture <= dataset$metadata$config$date_gel))
  list(evaluation = evaluation, devenir = devenir, eligibilite_diplomes = graduates)
}

.survey_group <- function(data, groups, fields, min_denominator) {
  if (!is.data.frame(data) || !is.character(groups) || anyNA(groups) ||
      anyDuplicated(groups) || !all(c(groups, fields) %in% names(data)))
    stop("Colonnes ou groupes d'enquete invalides.", call. = FALSE)
  if (length(min_denominator) != 1L || !is.numeric(min_denominator) ||
      is.na(min_denominator) || !is.finite(min_denominator) ||
      min_denominator < 1 || min_denominator != floor(min_denominator))
    stop("Seuil entier positif requis.", call. = FALSE)
  dplyr::group_by(data, dplyr::across(dplyr::all_of(groups)))
}

.survey_rate <- function(num, den, threshold) {
  ifelse(den >= threshold, 100 * num / pmax(den, 1), NA_real_)
}

#' Calculer I06 et I07 avec exclusions exhaustives et couverture de l'item
#' @param data Table evaluation issue de prepare_survey_tables().
#' @param groups Dimensions de restitution, character() pour le cumul.
#' @param min_denominator Seuil de diffusion des taux.
#' @return Effectifs, taux et denominateurs ; aucune non-reponse codee negative.
summarise_evaluation <- function(data, groups = "annee_universitaire", min_denominator = 10L) {
  x <- .survey_group(data, groups, c("a_repondu", "statut_reponse", "etat_global",
    "satisfaction_globale"), min_denominator)
  if (anyNA(data[c("a_repondu", "etat_global")]) ||
      !all(data$etat_global %in% c("valide", "non_reponse_vague", "non_reponse_item", "non_concerne")))
    stop("Etats d'evaluation invalides.", call. = FALSE)
  out <- dplyr::summarise(x, n_invites = dplyr::n(), n_repondants = sum(.data$a_repondu),
    n_complets = sum(.data$statut_reponse == "complete"),
    n_non_reponse_vague = sum(.data$etat_global == "non_reponse_vague"),
    n_non_reponse_item = sum(.data$etat_global == "non_reponse_item"),
    n_non_concerne = sum(.data$etat_global == "non_concerne"),
    n_valides_global = sum(.data$etat_global == "valide"),
    n_favorables = sum(.data$satisfaction_globale %in% c(4L, 5L)), .groups = "drop")
  stopifnot(all(out$n_invites == out$n_valides_global + out$n_non_reponse_vague +
    out$n_non_reponse_item + out$n_non_concerne))
  out$taux_reponse_pct <- .survey_rate(out$n_repondants, out$n_invites, min_denominator)
  out$couverture_item_pct <- .survey_rate(out$n_valides_global, out$n_invites, min_denominator)
  out$satisfaction_favorable_pct <- .survey_rate(out$n_favorables, out$n_valides_global, min_denominator)
  out$statut_satisfaction <- ifelse(out$n_valides_global < min_denominator, "effectif insuffisant", "diffusable")
  as.data.frame(out)
}

#' Decrire les cinq modalites de satisfaction et les trois exclusions
#' @param data Table evaluation preparee.
#' @param groups Dimensions de restitution.
#' @param min_denominator Seuil de diffusion.
#' @return Distribution exhaustive sur invitations et distribution sur items valides.
evaluation_distribution <- function(data, groups = "annee_universitaire", min_denominator = 10L) {
  .survey_group(data, groups, c("etat_global", "satisfaction_globale"), min_denominator)
  z <- as.data.frame(data[groups])
  z$modalite <- ifelse(data$etat_global == "valide", as.character(data$satisfaction_globale), data$etat_global)
  modalities <- c(as.character(1:5), "non_concerne", "non_reponse_item", "non_reponse_vague")
  counts <- dplyr::count(z, dplyr::across(dplyr::all_of(c(groups, "modalite"))), name = "effectif")
  grid <- if (length(groups)) tidyr::expand_grid(unique(z[groups]), modalite = modalities)
    else data.frame(modalite = modalities)
  out <- dplyr::left_join(grid, counts, by = c(groups, "modalite"), relationship = "one-to-one")
  out$effectif[is.na(out$effectif)] <- 0L
  out <- dplyr::mutate(dplyr::group_by(out, dplyr::across(dplyr::all_of(groups))),
    n_invites = sum(.data$effectif),
    n_valides = sum(.data$effectif[.data$modalite %in% as.character(1:5)]),
    part_invites_pct = .survey_rate(.data$effectif, .data$n_invites, min_denominator),
    part_valides_pct = ifelse(.data$modalite %in% as.character(1:5),
      .survey_rate(.data$effectif, .data$n_valides, min_denominator), NA_real_))
  as.data.frame(dplyr::ungroup(out))
}

#' Comparer composition et participation sur les caracteristiques observees
#' @param data Table evaluation preparee.
#' @param variables Caracteristiques a comparer ; NA conserve comme modalite.
#' @param min_denominator Seuil de diffusion.
#' @return Parts eligibles/repondants et ecart en points par annee, sans redressement.
survey_nonresponse <- function(data,
    variables = c("boursier", "type_bac", "niveau", "libelle_formation", "validation_annuelle"),
    min_denominator = 10L) {
  .survey_group(data, variables, c("annee_universitaire", "a_repondu"), min_denominator)
  if (!length(variables)) stop("Caracteristiques requises.", call. = FALSE)
  out <- lapply(variables, function(field) {
    x <- data.frame(annee_universitaire = data$annee_universitaire,
      modalite = as.character(data[[field]]), est_manquant = is.na(data[[field]]),
      a_repondu = data$a_repondu)
    z <- dplyr::summarise(dplyr::group_by(x, .data$annee_universitaire, .data$modalite, .data$est_manquant),
      n_eligibles_modalite = dplyr::n(), n_repondants_modalite = sum(.data$a_repondu), .groups = "drop")
    z <- dplyr::mutate(dplyr::group_by(z, .data$annee_universitaire),
      n_eligibles_annee = sum(.data$n_eligibles_modalite),
      n_repondants_annee = sum(.data$n_repondants_modalite),
      part_eligibles_pct = .survey_rate(.data$n_eligibles_modalite, .data$n_eligibles_annee, min_denominator),
      part_repondants_pct = .survey_rate(.data$n_repondants_modalite, .data$n_repondants_annee, min_denominator),
      taux_reponse_modalite_pct = .survey_rate(.data$n_repondants_modalite, .data$n_eligibles_modalite, min_denominator),
      ecart_composition_points = .data$part_repondants_pct - .data$part_eligibles_pct)
    z$variable <- field
    as.data.frame(dplyr::ungroup(z))
  })
  dplyr::bind_rows(out)
}

#' Examiner les relations entre items sans fabriquer d'echelle composite
#' @param data Table evaluation preparee.
#' @return Correlations de Spearman par annee, avec effectifs de paires completes.
survey_item_relations <- function(data) {
  items <- paste0("satisfaction_", c("globale", "contenus", "accompagnement"))
  .survey_group(data, "annee_universitaire", items, 10L)
  pairs <- utils::combn(items, 2L)
  out <- lapply(sort(unique(data$annee_universitaire)), function(year) {
    x <- data[data$annee_universitaire == year, ]
    do.call(rbind, lapply(seq_len(ncol(pairs)), function(j) {
      fields <- pairs[, j]
      valid <- stats::complete.cases(x[fields])
      n <- sum(valid)
      rho <- if (n >= 10L && length(unique(x[[fields[1]]][valid])) > 1L &&
        length(unique(x[[fields[2]]][valid])) > 1L)
        stats::cor(x[[fields[1]]][valid], x[[fields[2]]][valid], method = "spearman") else NA_real_
      data.frame(annee_universitaire = year, item_1 = fields[1], item_2 = fields[2],
        n_paires_valides = n, rho_spearman = rho)
    }))
  })
  dplyr::bind_rows(out)
}

#' Calculer I09-I11 et decrire la situation connue a six mois
#' @param data Invitations devenir preparees, une personne par diplome de reference.
#' @param groups Dimensions de restitution (type et annee du diplome par defaut).
#' @param min_denominator Seuil de diffusion.
#' @return Effectifs et taux, avec etudes prioritaires et non-reponse distincte.
summarise_graduate_survey <- function(data,
    groups = c("annee_universitaire", "type_diplome"), min_denominator = 10L) {
  x <- .survey_group(data, groups, c("a_repondu", "situation_connue", "situation_six_mois",
    "emploi_pendant_etudes", "motif_situation_manquante"), min_denominator)
  out <- dplyr::summarise(x, n_invites = dplyr::n(), n_questionnaires = sum(.data$a_repondu),
    n_situations_connues = sum(.data$situation_connue), n_non_reponse_vague = sum(!.data$a_repondu),
    n_situations_inconnues_repondants = sum(.data$a_repondu & !.data$situation_connue),
    n_item_vide = sum(.data$motif_situation_manquante == "non_reponse_item", na.rm = TRUE),
    n_ne_sait_pas = sum(.data$motif_situation_manquante == "ne_sait_pas", na.rm = TRUE),
    n_etudes = sum(.data$situation_six_mois == "etudes", na.rm = TRUE),
    n_emploi_hors_etudes = sum(.data$situation_six_mois == "emploi_hors_etudes", na.rm = TRUE),
    n_recherche_emploi = sum(.data$situation_six_mois == "recherche_emploi_hors_etudes", na.rm = TRUE),
    n_autre_hors_etudes = sum(.data$situation_six_mois == "autre_hors_etudes", na.rm = TRUE),
    n_emploi_etudes_connu = sum(.data$situation_six_mois == "etudes" & !is.na(.data$emploi_pendant_etudes), na.rm = TRUE),
    n_emploi_pendant_etudes = sum(.data$situation_six_mois == "etudes" & .data$emploi_pendant_etudes, na.rm = TRUE),
    .groups = "drop")
  out$n_hors_etudes <- out$n_emploi_hors_etudes + out$n_recherche_emploi + out$n_autre_hors_etudes
  stopifnot(all(out$n_situations_connues == out$n_etudes + out$n_hors_etudes),
    all(out$n_invites == out$n_situations_connues + out$n_situations_inconnues_repondants + out$n_non_reponse_vague))
  out$taux_questionnaires_pct <- .survey_rate(out$n_questionnaires, out$n_invites, min_denominator)
  out$taux_reponse_situation_pct <- .survey_rate(out$n_situations_connues, out$n_invites, min_denominator)
  out$emploi_parmi_hors_etudes_pct <- .survey_rate(out$n_emploi_hors_etudes, out$n_hors_etudes, min_denominator)
  out$poursuite_etudes_pct <- .survey_rate(out$n_etudes, out$n_situations_connues, min_denominator)
  out$emploi_pendant_etudes_pct <- .survey_rate(out$n_emploi_pendant_etudes, out$n_emploi_etudes_connu, min_denominator)
  out$couverture_emploi_etudes_pct <- .survey_rate(out$n_emploi_etudes_connu, out$n_etudes, min_denominator)
  as.data.frame(out)
}
