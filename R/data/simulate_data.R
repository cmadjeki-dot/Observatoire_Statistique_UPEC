# Simulation uniquement synthetique. Aucune ecriture de fichier dans ce module.

.sim_with_seed <- function(seed, rng, code) {
  old_kind <- RNGkind()
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = .GlobalEnv)
  on.exit({
    do.call(RNGkind, as.list(old_kind))
    if (had_seed) assign(".Random.seed", old_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  do.call(RNGkind, as.list(rng))
  set.seed(seed)
  force(code)
}

.sim_sample <- function(values, n, prob = NULL) {
  if (n == 0L) return(values[integer()])
  values[sample.int(length(values), size = n, replace = TRUE, prob = prob)]
}

.sim_draw <- function(probabilities, n) {
  .sim_sample(names(probabilities), n, probabilities)
}

.sim_date <- function(annee, month_day, end = FALSE) {
  if (!length(annee)) return(as.Date(character()))
  year <- as.integer(substr(annee, 1, 4)) + as.integer(end)
  as.Date(paste0(year, "-", month_day))
}

.sim_months <- function(date, months) {
  # %m+% utilise le dernier jour valide du mois cible (31 -> 30/28/29).
  as.Date(lubridate::`%m+%`(date, lubridate::period(months, units = "months")))
}

.sim_check_config <- function(cfg) {
  if (!is.list(cfg) || !identical(cfg$statut, "valide"))
    stop("La configuration doit etre validee avant generation.", call. = FALSE)
  counts <- c(cfg$nouveaux_etudiants, cfg$niveaux_initiaux)
  if (anyNA(counts) || any(counts < 0 | counts != floor(counts)) ||
      sum(cfg$nouveaux_etudiants) != cfg$n_etudiants || cfg$n_etudiants < 1 ||
      cfg$nouveaux_etudiants[1] < 1 ||
      sum(cfg$niveaux_initiaux) != cfg$nouveaux_etudiants[1])
    stop("Volumes de population incoherents.", call. = FALSE)
  if (!identical(cfg$annees, c("2023-2024", "2024-2025", "2025-2026")) ||
      !identical(names(cfg$nouveaux_etudiants), cfg$annees) ||
      !setequal(names(cfg$niveaux_initiaux), c("L1", "L2", "L3", "M1", "M2")) ||
      !identical(cfg$niveau_nouveaux_apres_2023, "L1"))
    stop("Ce simulateur couvre les trois annees et les niveaux L/M declares.", call. = FALSE)
  f <- cfg$formations
  if (!is.data.frame(f) || anyNA(f) || anyDuplicated(f$id_formation) ||
      !setequal(f$cycle, c("licence", "master")))
    stop("Referentiel des formations invalide.", call. = FALSE)
  probabilities <- c(list(cfg$population$type_bac, cfg$population$parcours_anterieur,
    cfg$evaluation$satisfaction, cfg$devenir$situation_licence,
    cfg$devenir$situation_master), cfg$transitions,
    split(f$poids_dans_cycle, f$cycle))
  for (p in probabilities) {
    if (!length(p) || anyNA(p) || any(!is.finite(p) | p < 0 | p > 1) ||
        abs(sum(p) - 1) > 1e-8)
      stop("Une distribution de probabilites est invalide.", call. = FALSE)
  }
  transition_domains <- list(
    validation_non_terminale = c("passage", "reorientation", "sortie_observee"),
    non_validation = c("redoublement", "reorientation", "sortie_observee"),
    licence_validee = c("poursuite_intercycle", "sortie_observee"),
    master_valide = "sortie_observee",
    decision_inconnue = c("maintien_meme_niveau", "reorientation", "sortie_observee"))
  if (!setequal(names(cfg$transitions), names(transition_domains)))
    stop("Domaines de transition invalides.", call. = FALSE)
  for (state in names(transition_domains)) {
    if (!setequal(names(cfg$transitions[[state]]), transition_domains[[state]]) ||
        anyDuplicated(names(cfg$transitions[[state]])))
      stop("Modalites de transition invalides : ", state, call. = FALSE)
  }
  if (any(table(f$cycle) < 2L) || any(f$poids_dans_cycle <= 0))
    stop("Prevoir au moins deux formations de poids positif par cycle.", call. = FALSE)
  numeric_parameters <- unlist(cfg[c("population", "resultats", "evaluation", "devenir")])
  p <- numeric_parameters[grepl("probabilite", names(numeric_parameters), fixed = TRUE)]
  if (anyNA(p) || any(!is.finite(p) | p < 0 | p > 1) ||
      any(cfg$resultats$probabilite_reference %in% c(0, 1)))
    stop("Probabilite hors domaine.", call. = FALSE)
  if (!setequal(names(cfg$population$type_bac), names(cfg$resultats$effet_logit_bac)) ||
      !setequal(names(cfg$resultats$probabilite_reference), names(cfg$niveaux_initiaux)))
    stop("Domaines des coefficients incoherents.", call. = FALSE)
  intervals <- cfg$resultats[c("moyenne_si_validation", "moyenne_si_non_validation")]
  valid_interval <- function(x) is.numeric(x) && length(x) == 2L &&
    setequal(names(x), c("min", "max")) && !anyNA(x) && all(is.finite(x)) &&
    x[["min"]] >= 0 && x[["max"]] <= 20 && x[["min"]] <= x[["max"]]
  if (!all(vapply(intervals, valid_interval, logical(1))) ||
      cfg$resultats$moyenne_si_validation[["min"]] < 10 ||
      cfg$resultats$moyenne_si_non_validation[["max"]] >= 10)
    stop("Intervalles de moyenne des resultats invalides.", call. = FALSE)
  required_seeds <- c("population", "scolarite", "evaluations", "diplomes", "devenir", "anomalies")
  if (!is.numeric(cfg$graines) || length(cfg$graines) != 6L ||
      !setequal(names(cfg$graines), required_seeds) || anyNA(cfg$graines) || anyDuplicated(cfg$graines) ||
      any(cfg$graines < 1 | cfg$graines > .Machine$integer.max | cfg$graines != floor(cfg$graines)))
    stop("Les six graines doivent etre des entiers positifs distincts.", call. = FALSE)
  if (cfg$devenir$horizon_mois != 6L || cfg$devenir$cloture_mois != 7L ||
      !inherits(cfg$date_gel, "Date") || length(cfg$date_gel) != 1L || is.na(cfg$date_gel))
    stop("Calendrier de devenir invalide.", call. = FALSE)
  invisible(cfg)
}

.sim_formation <- function(levels, cfg, previous = NULL) {
  cycles <- ifelse(substr(levels, 1, 1) == "L", "licence", "master")
  out <- character(length(levels))
  if (is.null(previous)) {
    for (cycle in unique(cycles)) {
      rows <- which(cycles == cycle)
      f <- cfg$formations[cfg$formations$cycle == cycle, ]
      out[rows] <- .sim_sample(f$id_formation, length(rows), f$poids_dans_cycle)
    }
  } else {
    for (origin in unique(previous)) {
      rows <- which(previous == origin)
      cycle <- cycles[rows[1L]]
      f <- cfg$formations[cfg$formations$cycle == cycle &
                            cfg$formations$id_formation != origin, ]
      out[rows] <- .sim_sample(f$id_formation, length(rows), f$poids_dans_cycle)
    }
  }
  out
}

.sim_population <- function(cfg) {
  n <- cfg$n_etudiants
  bac <- .sim_draw(cfg$population$type_bac, n)
  prior <- .sim_draw(cfg$population$parcours_anterieur, n)
  hidden <- stats::runif(n) < cfg$population$probabilite_bac_manquant
  students <- data.frame(
    id_etudiant = sprintf("ETU%06d", seq_len(n)),
    type_bac = replace(bac, hidden, NA_character_),
    motif_type_bac_manquant = ifelse(hidden, "non_disponible", NA_character_),
    parcours_anterieur = prior, stringsAsFactors = FALSE)
  list(etudiants = students, bac = bac,
    annee_entree = rep(cfg$annees, times = cfg$nouveaux_etudiants),
    effet = stats::rnorm(n, sd = cfg$resultats$ecart_type_effet_etudiant),
    bourse = stats::runif(n) < cfg$population$probabilite_boursier)
}

.sim_scolarite <- function(pop, cfg) {
  inscriptions <- resultats <- vector("list", length(cfg$annees))
  bourse_latente <- vector("list", length(cfg$annees))
  current <- data.frame(index = integer(), id_formation = character(), niveau = character())
  bourse <- pop$bourse
  for (year in seq_along(cfg$annees)) {
    annee <- cfg$annees[year]
    if (nrow(current)) {
      change <- stats::runif(nrow(current)) >= cfg$population$probabilite_conservation_bourse
      ids <- current$index[change]
      bourse[ids] <- stats::runif(length(ids)) < cfg$population$probabilite_boursier
    }
    entrants <- which(pop$annee_entree == annee)
    levels <- if (year == 1L) rep(names(cfg$niveaux_initiaux), cfg$niveaux_initiaux)
              else rep(cfg$niveau_nouveaux_apres_2023, length(entrants))
    new <- data.frame(index = entrants, id_formation = .sim_formation(levels, cfg),
                      niveau = levels, stringsAsFactors = FALSE)
    current <- rbind(current, new)
    current <- current[order(current$index), , drop = FALSE]
    n <- nrow(current)
    if (n == 0L) {
      inscriptions[[year]] <- inscriptions[[1L]][FALSE, , drop = FALSE]
      resultats[[year]] <- resultats[[1L]][FALSE, , drop = FALSE]
      bourse_latente[[year]] <- logical()
      next
    }
    ids <- current$index
    student_ids <- pop$etudiants$id_etudiant[ids]
    hidden <- stats::runif(n) < cfg$population$probabilite_bourse_manquante
    ins <- data.frame(id_inscription = paste0("INS", substr(annee, 1, 4), "_", student_ids),
      id_etudiant = student_ids, id_formation = current$id_formation,
      annee_universitaire = rep(annee, n), niveau = current$niveau,
      date_inscription = rep(.sim_date(annee, cfg$calendrier$inscription), n),
      statut_inscription = rep("active", n), boursier = replace(bourse[ids], hidden, NA),
      motif_boursier_manquant = ifelse(hidden, "non_disponible", NA_character_),
      prerequis_valides = rep(TRUE, n), stringsAsFactors = FALSE)
    eta <- stats::qlogis(cfg$resultats$probabilite_reference[current$niveau]) +
      cfg$resultats$effet_logit_bac[pop$bac[ids]] + pop$effet[ids] +
      cfg$resultats$effet_logit_reprise * (pop$etudiants$parcours_anterieur[ids] == "reprise_etudes")
    valid <- stats::runif(n) < stats::plogis(eta)
    unknown <- stats::runif(n) < cfg$resultats$probabilite_decision_inconnue
    decision <- ifelse(unknown, "inconnu", ifelse(valid, "oui", "non"))
    means <- numeric(n)
    means[valid] <- stats::runif(sum(valid), min(cfg$resultats$moyenne_si_validation),
                                 max(cfg$resultats$moyenne_si_validation))
    means[!valid] <- stats::runif(sum(!valid), min(cfg$resultats$moyenne_si_non_validation),
                                  max(cfg$resultats$moyenne_si_non_validation))
    credits <- rep(cfg$resultats$ects_si_validation, n)
    credits[!valid] <- .sim_sample(cfg$resultats$ects_si_non_validation, sum(!valid))
    dates <- rep(.sim_date(annee, cfg$calendrier$resultat, end = TRUE), n)
    dates[unknown] <- as.Date(NA)
    res <- data.frame(id_inscription = ins$id_inscription, validation_annuelle = decision,
      motif_resultat_inconnu = ifelse(unknown, "non_disponible", NA_character_),
      moyenne_annuelle = replace(round(means, 2), unknown, NA_real_),
      ects_acquis = as.integer(replace(credits, unknown, NA_integer_)), date_decision = dates,
      stringsAsFactors = FALSE)
    inscriptions[[year]] <- ins
    resultats[[year]] <- res
    bourse_latente[[year]] <- bourse[ids]
    if (year == length(cfg$annees)) next
    group <- ifelse(decision == "inconnu", "decision_inconnue",
      ifelse(decision == "non", "non_validation",
        ifelse(current$niveau == "L3", "licence_validee",
          ifelse(current$niveau == "M2", "master_valide", "validation_non_terminale"))))
    action <- character(n)
    for (g in unique(group)) {
      rows <- which(group == g)
      action[rows] <- .sim_draw(cfg$transitions[[g]], length(rows))
    }
    next_level <- c(L1 = "L2", L2 = "L3", M1 = "M2")
    pass <- which(action == "passage")
    current$niveau[pass] <- unname(next_level[current$niveau[pass]])
    inter <- which(action == "poursuite_intercycle")
    current$niveau[inter] <- "M1"
    current$id_formation[inter] <- .sim_formation(current$niveau[inter], cfg)
    change <- which(action == "reorientation")
    current$id_formation[change] <- .sim_formation(current$niveau[change], cfg,
                                                   current$id_formation[change])
    current <- current[action != "sortie_observee", , drop = FALSE]
  }
  list(inscriptions = do.call(rbind, inscriptions), resultats = do.call(rbind, resultats),
        bourse = unlist(bourse_latente, use.names = FALSE))
}

.sim_parcours <- function(ins, res, cfg) {
  year <- match(ins$annee_universitaire, cfg$annees)
  lookup <- paste(ins$id_etudiant, year)
  next_row <- match(paste(ins$id_etudiant, year + 1L), lookup)
  last <- year == length(cfg$annees)
  state <- rep("autre", nrow(ins))
  state[last] <- "non_observable"
  state[!last & is.na(next_row)] <- "sortie_observee"
  observed <- which(!last & !is.na(next_row))
  dest <- next_row[observed]
  from <- ins$niveau[observed]
  to <- ins$niveau[dest]
  valid <- res$validation_annuelle[match(ins$id_inscription[observed], res$id_inscription)]
  same <- ins$id_formation[observed] == ins$id_formation[dest]
  inter <- from == "L3" & to == "M1" & valid == "oui"
  state[observed[!same & !inter]] <- "reorientation"
  state[observed[inter]] <- "poursuite_intercycle"
  next_level <- unname(c(L1 = "L2", L2 = "L3", M1 = "M2")[from])
  pass <- same & valid == "oui" & !is.na(next_level) & to == next_level
  state[observed[which(pass)]] <- "passage"
  repeat_year <- same & from == to & valid == "non"
  state[observed[repeat_year]] <- "redoublement"
  data.frame(id_inscription_depart = ins$id_inscription,
    id_inscription_suivante = ins$id_inscription[next_row], etat_transition = state,
    stringsAsFactors = FALSE)
}

.sim_diplomes <- function(ins, res, cfg) {
  terminal <- ins[ins$niveau %in% c("L3", "M2"), , drop = FALSE]
  decisions <- res$validation_annuelle[match(terminal$id_inscription, res$id_inscription)]
  decisions[decisions == "oui" & !terminal$prerequis_valides] <- "non"
  dates <- .sim_date(terminal$annee_universitaire, cfg$calendrier$diplome, end = TRUE)
  dates[decisions == "inconnu"] <- as.Date(NA)
  dd <- data.frame(id_inscription = terminal$id_inscription,
    attribution_diplome = decisions, date_decision_diplome = dates, stringsAsFactors = FALSE)
  selected <- which(decisions == "oui")
  dipl <- data.frame(id_diplome = sprintf("DIP%06d", seq_along(selected)),
    id_inscription = terminal$id_inscription[selected],
    type_diplome = unname(c(L3 = "licence", M2 = "master")[terminal$niveau[selected]]),
    date_diplome = dates[selected], stringsAsFactors = FALSE)
  list(decisions_diplome = dd, diplomes = dipl)
}

.sim_evaluation <- function(ins, bourse, cfg) {
  n <- nrow(ins)
  invitation <- data.frame(id_invitation_evaluation = sprintf("IEV%07d", seq_len(n)),
    id_inscription = ins$id_inscription, vague = paste0("EVAL_", ins$annee_universitaire),
    date_ouverture = .sim_date(ins$annee_universitaire, cfg$calendrier$evaluation_debut, TRUE),
    date_cloture = .sim_date(ins$annee_universitaire, cfg$calendrier$evaluation_fin, TRUE),
    statut_reponse = rep("aucune", n), stringsAsFactors = FALSE)
  eta <- stats::qlogis(cfg$evaluation$probabilite_reponse_reference) +
    cfg$evaluation$effet_logit_reponse_boursier * bourse
  rows <- which(stats::runif(n) < stats::plogis(eta))
  m <- length(rows)
  response <- data.frame(id_reponse_evaluation = sprintf("REV%07d", seq_len(m)),
    id_invitation_evaluation = invitation$id_invitation_evaluation[rows],
    date_reponse = invitation$date_ouverture[rows] +
      as.integer(floor(stats::runif(m) *
        (as.integer(invitation$date_cloture[rows] - invitation$date_ouverture[rows]) + 1L))),
    stringsAsFactors = FALSE)
  answered <- integer(m)
  for (item in c("globale", "contenus", "accompagnement")) {
    nc <- stats::runif(m) < cfg$evaluation$probabilite_non_concerne_par_item
    missing <- !nc & (stats::runif(m) < cfg$evaluation$probabilite_non_reponse_item)
    value <- as.integer(.sim_draw(cfg$evaluation$satisfaction, m))
    value[nc | missing] <- NA_integer_
    response[[paste0("satisfaction_", item)]] <- value
    response[[paste0("motif_satisfaction_", item)]] <- as.character(ifelse(nc, "non_concerne",
      ifelse(missing, "non_reponse_item", NA_character_)))
    answered <- answered + as.integer(!missing)
  }
  invitation$statut_reponse[rows] <- ifelse(answered == 0L, "aucune",
    ifelse(answered == 3L, "complete", "partielle"))
  response <- response[answered > 0L, , drop = FALSE]
  list(invitations_evaluation = invitation, evaluations = response)
}

.sim_devenir <- function(dipl, ins, cfg) {
  opening <- .sim_months(dipl$date_diplome, cfg$devenir$horizon_mois)
  closing <- .sim_months(dipl$date_diplome, cfg$devenir$cloture_mois)
  eligible <- which(closing <= cfg$date_gel)
  ids <- ins$id_etudiant[match(dipl$id_inscription, ins$id_inscription)]
  # Une vague au gel : le dernier diplome eligible de chaque personne.
  eligible <- eligible[order(ids[eligible], -as.numeric(dipl$date_diplome[eligible]),
                             dipl$id_diplome[eligible])]
  eligible <- eligible[!duplicated(ids[eligible])]
  eligible <- sort(eligible)
  n <- length(eligible)
  invitation <- data.frame(id_invitation_devenir = sprintf("IDEV%06d", seq_len(n)),
    id_diplome = dipl$id_diplome[eligible], vague = rep("DEV_GEL_2026", n),
    date_reference = opening[eligible], date_ouverture = opening[eligible],
    date_cloture = closing[eligible], statut_reponse = rep("aucune", n),
    stringsAsFactors = FALSE)
  rows <- which(stats::runif(n) < cfg$devenir$probabilite_reponse)
  m <- length(rows)
  type <- dipl$type_diplome[eligible[rows]]
  situation <- character(m)
  for (d in unique(type)) {
    j <- which(type == d)
    situation[j] <- .sim_draw(cfg$devenir[[paste0("situation_", d)]], length(j))
  }
  missing <- stats::runif(m) < cfg$devenir$probabilite_situation_manquante
  situation[missing] <- NA_character_
  studies <- !is.na(situation) & situation == "etudes"
  job <- rep(NA, m)
  job[studies] <- stats::runif(sum(studies)) < cfg$devenir$probabilite_emploi_pendant_etudes
  span <- as.integer(invitation$date_cloture[rows] - invitation$date_ouverture[rows])
  offset <- as.integer(floor(stats::runif(m) * (span + 1L)))
  response <- data.frame(id_reponse_devenir = sprintf("RDEV%06d", seq_len(m)),
    id_invitation_devenir = invitation$id_invitation_devenir[rows],
    date_reponse = invitation$date_ouverture[rows] + offset,
    situation_six_mois = situation,
    motif_situation_manquante = as.character(ifelse(missing, "non_reponse_item", NA_character_)),
    emploi_pendant_etudes = job,
    motif_emploi_pendant_etudes_manquant = as.character(ifelse(studies, NA_character_, "non_applicable")),
    stringsAsFactors = FALSE)
  invitation$statut_reponse[rows] <- ifelse(missing, "partielle", "complete")
  list(invitations_devenir = invitation, devenir_diplomes = response)
}

#' Generer les onze tables relationnelles de la base synthetique
#' @param config Liste issue de config/simulation.R, avec statut valide.
#' @return Liste nommee : onze data.frames et metadata (provenance, configuration).
#' @details Ne sauvegarde rien. Les graines et RNG sont fixes et l'etat aleatoire
#'   appelant est restaure. Les variables latentes ne sont pas exportees.
generate_dataset <- function(config = dget(here::here("config", "simulation.R"))) {
  .sim_check_config(config)
  pop <- .sim_with_seed(config$graines[["population"]], config$rng, .sim_population(config))
  school <- .sim_with_seed(config$graines[["scolarite"]], config$rng, .sim_scolarite(pop, config))
  dipl <- .sim_with_seed(config$graines[["diplomes"]], config$rng,
    .sim_diplomes(school$inscriptions, school$resultats, config))
  ev <- .sim_with_seed(config$graines[["evaluations"]], config$rng,
    .sim_evaluation(school$inscriptions, school$bourse, config))
  dev <- .sim_with_seed(config$graines[["devenir"]], config$rng,
    .sim_devenir(dipl$diplomes, school$inscriptions, config))
  out <- c(list(etudiants = pop$etudiants, formations = config$formations,
    inscriptions = school$inscriptions, resultats = school$resultats,
    parcours = .sim_parcours(school$inscriptions, school$resultats, config)), ev, dipl, dev)
  out <- lapply(out, function(x) { rownames(x) <- NULL; x })
  out$metadata <- list(provenance = "entierement_synthetique_non_officiel",
    version_simulateur = "0.1", config = config,
    donnees_personnelles_reelles = FALSE, anomalies_injectees = FALSE)
  out
}

#' Injecter des anomalies dans une copie, avec journal de tracabilite
#' @param dataset Base coherente retournee par generate_dataset().
#' @param n_per_type Nombre d'injections par type ; NULL utilise la configuration.
#' @param seed Graine d'injection ; NULL utilise la configuration.
#' @return Liste data (copie alteree) et issues (journal avant/apres, controle attendu).
#' @details Ne modifie pas l'objet appelant ni les fichiers. L'index des lignes
#'   du journal se rapporte a la copie retournee. Les types sont fixes en version 1.
inject_quality_issues <- function(dataset, n_per_type = NULL, seed = NULL) {
  if (!identical(dataset$metadata$provenance, "entierement_synthetique_non_officiel") ||
      !identical(dataset$metadata$anomalies_injectees, FALSE))
    stop("Fournir une base synthetique non encore alteree.", call. = FALSE)
  cfg <- dataset$metadata$config
  if (is.null(n_per_type)) n_per_type <- cfg$anomalies$nombre_par_type
  if (is.null(seed)) seed <- cfg$graines[["anomalies"]]
  if (length(n_per_type) != 1L || is.na(n_per_type) || !is.numeric(n_per_type) ||
      !is.finite(n_per_type) || n_per_type < 1 || n_per_type > .Machine$integer.max ||
      n_per_type != floor(n_per_type))
    stop("n_per_type doit etre un entier strictement positif.", call. = FALSE)
  if (length(seed) != 1L || is.na(seed) || !is.numeric(seed) ||
      !is.finite(seed) || seed < 1 || seed > .Machine$integer.max || seed != floor(seed))
    stop("Graine d'injection invalide.", call. = FALSE)
  .sim_with_seed(seed, cfg$rng, {
    out <- dataset
    k <- as.integer(n_per_type)
    ins <- out$inscriptions
    observed <- which(!is.na(out$parcours$id_inscription_suivante) &
      out$parcours$etat_transition != "non_observable")
    if (k > floor(nrow(ins) / 2) || nrow(out$resultats) < k || length(observed) < k)
      stop("Base trop petite pour ces injections distinctes.", call. = FALSE)
    picks <- sample.int(nrow(ins), 2L * k, replace = FALSE)
    journal <- list()
    log_issue <- function(type, table, rows, key, field, before, after, expected) {
      journal[[length(journal) + 1L]] <<- data.frame(type = type, table = table,
        ligne = as.integer(rows), cle = as.character(key), champ = field,
        valeur_initiale = as.character(before), valeur_injectee = as.character(after),
        controle_attendu = expected, stringsAsFactors = FALSE)
    }
    # Dupliquer des lignes, jamais renommer la cle de l'original.
    rows <- picks[seq_len(k)]
    added <- out$inscriptions[rows, , drop = FALSE]
    new_rows <- nrow(ins) + seq_len(k)
    out$inscriptions <- rbind(out$inscriptions, added)
    log_issue("doublon_cle", "inscriptions", new_rows, added$id_inscription,
      "id_inscription", rep(NA_character_, k), added$id_inscription, "unicite_inscription")
    rows <- picks[k + seq_len(k)]
    before <- out$inscriptions$id_etudiant[rows]
    after <- paste0("ETU_ORPHELIN_", seq_len(k))
    out$inscriptions$id_etudiant[rows] <- after
    log_issue("reference_orpheline", "inscriptions", rows, ins$id_inscription[rows],
      "id_etudiant", before, after, "reference_etudiant")
    # Les deux autres types utilisent des inscriptions non encore selectionnees.
    available <- which(!out$resultats$id_inscription %in% ins$id_inscription[picks])
    if (length(available) < k) stop("Pas assez de resultats distincts.", call. = FALSE)
    rows <- available[sample.int(length(available), k, replace = FALSE)]
    before <- out$resultats$moyenne_annuelle[rows]
    out$resultats$moyenne_annuelle[rows] <- 25
    log_issue("valeur_hors_domaine", "resultats", rows, out$resultats$id_inscription[rows],
      "moyenne_annuelle", before, rep(25, k), "domaine_moyenne")
    excluded <- c(ins$id_inscription[picks], out$resultats$id_inscription[rows])
    available <- which(!out$decisions_diplome$id_inscription %in% excluded &
                        out$decisions_diplome$attribution_diplome != "inconnu")
    if (length(available) < k) stop("Pas assez de decisions de diplome distinctes.", call. = FALSE)
    rows <- available[sample.int(length(available), k, replace = FALSE)]
    keys <- out$decisions_diplome$id_inscription[rows]
    before <- out$decisions_diplome$date_decision_diplome[rows]
    after <- ins$date_inscription[match(keys, ins$id_inscription)] - 1L
    out$decisions_diplome$date_decision_diplome[rows] <- after
    log_issue("date_incoherente", "decisions_diplome", rows, keys,
      "date_decision_diplome", before, after, "chronologie_diplome")
    excluded <- c(excluded, keys)
    # Pointer vers la meme inscription : une transition annuelle devient impossible.
    available <- observed[!out$parcours$id_inscription_depart[observed] %in% excluded]
    if (length(available) < k) stop("Pas assez de transitions distinctes.", call. = FALSE)
    rows <- available[sample.int(length(available), k, replace = FALSE)]
    before <- out$parcours$id_inscription_suivante[rows]
    keys <- out$parcours$id_inscription_depart[rows]
    out$parcours$id_inscription_suivante[rows] <- keys
    log_issue("transition_impossible", "parcours", rows, keys, "id_inscription_suivante",
      before, keys, "annee_transition_suivante")
    issues <- do.call(rbind, journal)
    issues$id_anomalie <- sprintf("ANO%04d", seq_len(nrow(issues)))
    rownames(out$inscriptions) <- NULL
    out$metadata$anomalies_injectees <- TRUE
    out$metadata$graine_anomalies <- seed
    list(data = out, issues = issues)
  })
}
