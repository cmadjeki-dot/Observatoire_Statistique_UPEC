# Indicateurs prioritaires : configuration documentaire et calculs explicites.
# Prerequis : descriptive.R et R/surveys/analyse_surveys.R.

#' Lire et valider le catalogue YAML, sans execution d'expressions
#' @param path Chemin du catalogue.
#' @return Configuration ; les formules textuelles ne sont jamais evaluees.
read_indicator_config <- function(path = here::here("config", "indicators.yml")) {
  cfg <- yaml::read_yaml(path, eval.expr = FALSE)
  valid <- c("I02", "I03", "I05a", "I05c", "I06", "I07", "I08", "I09", "I10", "I11")
  fields <- c("libelle", "famille", "type", "finalite", "population", "unite_statistique",
    "numerateur", "denominateur", "formule", "periode", "exclusions", "manquants", "couverture", "limites")
  scalar <- function(x) is.character(x) && length(x) == 1L && !is.na(x) && nzchar(x)
  if (!identical(cfg$schema_version, "0.1") ||
      !identical(cfg$provenance, "entierement_synthetique_non_officiel") || !scalar(cfg$date_gel) ||
      !grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", cfg$date_gel) || is.na(as.Date(cfg$date_gel)) ||
      length(cfg$seuil_minimum_taux) != 1L || !is.numeric(cfg$seuil_minimum_taux) ||
      is.na(cfg$seuil_minimum_taux) || !is.finite(cfg$seuil_minimum_taux) ||
      cfg$seuil_minimum_taux < 10 || cfg$seuil_minimum_taux != floor(cfg$seuil_minimum_taux) ||
      !is.list(cfg$indicateurs) || length(cfg$indicateurs) < 5L || length(cfg$indicateurs) > 10L ||
      is.null(names(cfg$indicateurs)) || anyDuplicated(names(cfg$indicateurs)) ||
      !all(names(cfg$indicateurs) %in% valid)) stop("Catalogue d'indicateurs invalide.", call. = FALSE)
  for (id in names(cfg$indicateurs)) {
    item <- cfg$indicateurs[[id]]
    if (!all(fields %in% names(item)) || !all(vapply(item[fields], scalar, logical(1))) ||
        item$type != if (id == "I02") "effectif" else "pourcentage")
      stop("Definition incomplete ou type incompatible : ", id, call. = FALSE)
  }
  cfg
}

#' Decrire les decisions de diplome sur la seule population terminale eligible
#' @param inscriptions Inscriptions principales.
#' @param decisions Decisions oui/non/inconnu, une par inscription terminale.
#' @return Effectifs par annee ; aucune absence de decision convertie en non.
summarise_diploma_decisions <- function(inscriptions, decisions) {
  x <- inscriptions[inscriptions$statut_inscription == "active" & inscriptions$niveau %in% c("L3", "M2"), ]
  if (anyNA(x[c("id_inscription", "annee_universitaire")]) || anyDuplicated(x$id_inscription) ||
      anyDuplicated(decisions$id_inscription) || anyNA(decisions[c("id_inscription", "attribution_diplome")]) ||
      !all(decisions$attribution_diplome %in% c("oui", "non", "inconnu")))
    stop("Decisions de diplome ou cles invalides.", call. = FALSE)
  row <- match(x$id_inscription, decisions$id_inscription)
  if (anyNA(row)) stop("Decision de diplome manquante : calcul bloque.", call. = FALSE)
  x$attribution_diplome <- decisions$attribution_diplome[row]
  out <- dplyr::summarise(dplyr::group_by(x, .data$annee_universitaire),
    n_terminaux = dplyr::n(), n_attribues = sum(.data$attribution_diplome == "oui"),
    n_decisions_diplome_connues = sum(.data$attribution_diplome %in% c("oui", "non")),
    n_inconnus = sum(.data$attribution_diplome == "inconnu"), .groups = "drop")
  as.data.frame(out)
}

.indicator_row <- function(cfg, id, year, type_diplome = "non_applicable", population,
    numerator, denominator = NA_real_, missing = 0, coverage_num = NA_real_, coverage_den = NA_real_,
    observable = TRUE, reference = as.Date(NA)) {
  item <- cfg$indicateurs[[id]]
  if (is.null(item)) return(NULL)
  count <- item$type == "effectif"
  if (observable && (is.na(numerator) || !is.finite(numerator) || numerator < 0 ||
      (!count && (is.na(denominator) || !is.finite(denominator) || denominator < numerator))))
    stop("Numerateur ou denominateur incoherent : ", id, call. = FALSE)
  status <- if (!observable) "non_observable" else if (count) "diffusable" else
    if (denominator == 0) "denominateur_nul" else
      if (denominator < cfg$seuil_minimum_taux) "effectif_insuffisant" else "diffusable"
  value <- if (status != "diffusable") NA_real_ else if (count) numerator else 100 * numerator / denominator
  coverage <- if (observable && !is.na(coverage_den) && coverage_den >= cfg$seuil_minimum_taux)
    100 * coverage_num / coverage_den else NA_real_
  data.frame(id = id, libelle = item$libelle, famille = item$famille,
    annee_universitaire = year, type_diplome = type_diplome,
    population_reference = population, numerateur = numerator, denominateur = denominator,
    n_exclus = if (count) 0 else if (!observable) population else population - denominator,
    n_manquants = missing, couverture_numerateur = coverage_num, couverture_denominateur = coverage_den,
    couverture_pct = coverage, valeur = value, unite = item$type, statut = status,
    date_reference = reference, date_gel = as.Date(cfg$date_gel), stringsAsFactors = FALSE)
}

#' Construire les dix series prioritaires sans moyenner des taux de sous-groupes
#' @param data Table scolarite_analytique controlee.
#' @param surveys Univers prepares par prepare_survey_tables().
#' @param decisions Table des decisions de diplome.
#' @param config Catalogue valide par read_indicator_config().
#' @return Liste indicateurs (format long) et annexes (calculs et exclusions).
#' @details Series scolaires au niveau ensemble du champ ; devenir par annee et type du diplome.
build_priority_indicators <- function(data, surveys, decisions, config = read_indicator_config()) {
  threshold <- config$seuil_minimum_taux
  annual <- describe_enrolments(data)
  success <- describe_success(data, min_denominator = threshold)
  transitions <- describe_transitions(data, min_denominator = threshold)
  evaluation <- summarise_evaluation(surveys$evaluation, min_denominator = threshold)
  diplomas <- summarise_diploma_decisions(data, decisions)
  future <- summarise_graduate_survey(surveys$devenir, min_denominator = threshold)
  rows <- list()
  add <- function(...) rows[[length(rows) + 1L]] <<- .indicator_row(config, ...)
  for (year in annual$annuel$annee_universitaire) {
    n <- annual$annuel$n_inscriptions[annual$annuel$annee_universitaire == year]
    s <- success[success$annee_universitaire == year, ]
    e <- evaluation[evaluation$annee_universitaire == year, ]
    dp <- diplomas[diplomas$annee_universitaire == year, ]
    if (nrow(s) != 1L || nrow(e) != 1L || nrow(dp) != 1L)
      stop("Millesime incomplet pour les indicateurs annuels.", call. = FALSE)
    start <- as.integer(substr(year, 1L, 4L))
    end <- start + 1L
    result_date <- as.Date(paste0(end, "-09-30"))
    survey_date <- as.Date(paste0(end, "-06-30"))
    add(id = "I02", year = year, population = n, numerator = n, reference = as.Date(paste0(start, "-10-31")))
    add(id = "I03", year = year, population = n, numerator = s$n_validees,
      denominator = s$n_decisions_connues, missing = s$n_inconnues,
      coverage_num = s$n_decisions_connues, coverage_den = n, reference = result_date)
    for (id in c("I05a", "I05c")) {
      state <- if (id == "I05a") "passage" else "reorientation"
      tr <- transitions[transitions$annee_universitaire == year & transitions$etat_transition == state, ]
      observable <- nrow(tr) == 1L
      add(id = id, year = year, population = n,
        numerator = if (observable) tr$effectif else NA_real_,
        denominator = if (observable) tr$denominateur else NA_real_,
        missing = if (observable) 0 else NA_real_,
        coverage_num = if (observable) tr$denominateur else NA_real_, coverage_den = n,
        observable = observable, reference = if (observable) as.Date(paste0(end, "-10-31")) else as.Date(NA))
    }
    add(id = "I06", year = year, population = e$n_invites, numerator = e$n_repondants,
      denominator = e$n_invites, missing = e$n_non_reponse_vague,
      coverage_num = e$n_repondants, coverage_den = e$n_invites, reference = survey_date)
    add(id = "I07", year = year, population = e$n_invites, numerator = e$n_favorables,
      denominator = e$n_valides_global, missing = e$n_non_reponse_vague + e$n_non_reponse_item,
      coverage_num = e$n_valides_global, coverage_den = e$n_invites, reference = survey_date)
    add(id = "I08", year = year, population = dp$n_terminaux, numerator = dp$n_attribues,
      denominator = dp$n_decisions_diplome_connues, missing = dp$n_inconnus,
      coverage_num = dp$n_decisions_diplome_connues, coverage_den = dp$n_terminaux, reference = result_date)
  }
  for (i in seq_len(nrow(future))) {
    f <- future[i, ]
    dates <- surveys$devenir$date_reference[surveys$devenir$annee_universitaire == f$annee_universitaire &
      surveys$devenir$type_diplome == f$type_diplome]
    if (length(unique(dates)) != 1L) stop("Plusieurs dates de reference : ventilation requise.", call. = FALSE)
    unknown <- f$n_invites - f$n_situations_connues
    for (id in c("I09", "I10", "I11")) {
      numerator <- switch(id, I09 = f$n_situations_connues, I10 = f$n_emploi_hors_etudes, I11 = f$n_etudes)
      denominator <- switch(id, I09 = f$n_invites, I10 = f$n_hors_etudes, I11 = f$n_situations_connues)
      add(id = id, year = f$annee_universitaire, type_diplome = f$type_diplome,
        population = f$n_invites, numerator = numerator, denominator = denominator,
        missing = unknown, coverage_num = f$n_situations_connues, coverage_den = f$n_invites,
        reference = unique(dates))
    }
  }
  out <- dplyr::bind_rows(rows)
  out <- out[order(match(out$id, names(config$indicateurs)), out$annee_universitaire, out$type_diplome), ]
  rownames(out) <- NULL
  stopifnot(!anyDuplicated(out[c("id", "annee_universitaire", "type_diplome")]),
    all(out$numerateur[out$unite == "pourcentage"] <= out$denominateur[out$unite == "pourcentage"], na.rm = TRUE))
  list(indicateurs = as.data.frame(out), annexes = list(inscriptions = annual$annuel,
    etudiants_distincts = annual$panel, reussite = success, transitions = transitions,
    evaluation = evaluation, diplomes = diplomas, devenir = future,
    eligibilite_devenir = dplyr::count(surveys$eligibilite_diplomes,
      .data$annee_universitaire, .data$type_diplome, .data$statut_eligibilite, name = "n_diplomes")))
}
