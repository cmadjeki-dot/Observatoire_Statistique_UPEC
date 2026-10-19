# Controles deterministes, sans modification ni correction des donnees.

quality_schema <- function() {
  list(
    etudiants = c(id_etudiant = "character", type_bac = "character",
      motif_type_bac_manquant = "character", parcours_anterieur = "character"),
    formations = c(id_formation = "character", libelle_formation = "character",
      cycle = "character", poids_dans_cycle = "numeric"),
    inscriptions = c(id_inscription = "character", id_etudiant = "character",
      id_formation = "character", annee_universitaire = "character", niveau = "character",
      date_inscription = "Date", statut_inscription = "character", boursier = "logical",
      motif_boursier_manquant = "character", prerequis_valides = "logical"),
    resultats = c(id_inscription = "character", validation_annuelle = "character",
      motif_resultat_inconnu = "character", moyenne_annuelle = "numeric",
      ects_acquis = "integer", date_decision = "Date"),
    parcours = c(id_inscription_depart = "character", id_inscription_suivante = "character",
      etat_transition = "character"),
    invitations_evaluation = c(id_invitation_evaluation = "character", id_inscription = "character",
      vague = "character", date_ouverture = "Date", date_cloture = "Date", statut_reponse = "character"),
    evaluations = c(id_reponse_evaluation = "character", id_invitation_evaluation = "character",
      date_reponse = "Date", satisfaction_globale = "integer", motif_satisfaction_globale = "character",
      satisfaction_contenus = "integer", motif_satisfaction_contenus = "character",
      satisfaction_accompagnement = "integer", motif_satisfaction_accompagnement = "character"),
    decisions_diplome = c(id_inscription = "character", attribution_diplome = "character",
      date_decision_diplome = "Date"),
    diplomes = c(id_diplome = "character", id_inscription = "character",
      type_diplome = "character", date_diplome = "Date"),
    invitations_devenir = c(id_invitation_devenir = "character", id_diplome = "character",
      vague = "character", date_reference = "Date", date_ouverture = "Date",
      date_cloture = "Date", statut_reponse = "character"),
    devenir_diplomes = c(id_reponse_devenir = "character", id_invitation_devenir = "character",
      date_reponse = "Date", situation_six_mois = "character", motif_situation_manquante = "character",
      emploi_pendant_etudes = "logical", motif_emploi_pendant_etudes_manquant = "character")
  )
}

#' Controler les onze tables et retourner un rapport tracable
#' @param dataset Liste de tables et metadata issue de la simulation ou de l'import.
#' @param label Nom de la variante, enregistre dans le rapport.
#' @param config Configuration ; par defaut celle des metadata.
#' @return Liste checks, details, missing et metadata. Les lignes des details
#'   se rapportent a l'ordre fourni. Les NA attendus ne sont pas des erreurs.
#' @details Une structure invalide bloque les controles dependants ; ces derniers
#'   sont marques non_execute. Les jointures ne multiplient jamais les lignes.
check_quality <- function(dataset, label = "dataset", config = dataset$metadata$config) {
  if (!is.list(dataset) || is.data.frame(dataset) || !is.list(config))
    stop("Fournir les tables et leur configuration de reference.", call. = FALSE)
  schema <- quality_schema()
  keys <- vapply(schema, function(x) names(x)[1L], character(1))
  checks <- details <- missing <- list()
  ready <- setNames(rep(FALSE, length(schema)), names(schema))
  record <- function(rule, table, field, bad, message, severity = "bloquant",
                     rows = seq_along(bad), ignored = 0L, value = NULL) {
    bad[is.na(bad)] <- TRUE
    failing <- which(bad)
    checks[[length(checks) + 1L]] <<- data.frame(regle = rule, table = table, champ = field,
      severite = severity, statut = if (length(failing)) "non_conforme" else "conforme",
      n_evaluees = length(bad), n_non_evaluees = as.integer(ignored),
      n_alertes = length(failing), description = message, stringsAsFactors = FALSE)
    if (!length(failing)) return(invisible(NULL))
    row <- rows[failing]
    key <- rep(NA_character_, length(row))
    x <- dataset[[table]]
    if (is.data.frame(x) && keys[[table]] %in% names(x)) {
      valid <- !is.na(row) & row >= 1L & row <= nrow(x)
      key[valid] <- as.character(x[[keys[[table]]]][row[valid]])
    }
    if (is.null(value) && is.data.frame(x) && field %in% names(x)) value <- x[[field]][rows]
    observed <- if (is.null(value)) rep(NA_character_, length(failing)) else as.character(value[failing])
    details[[length(details) + 1L]] <<- data.frame(regle = rule, table = table, ligne = as.integer(row),
      cle = key, champ = field, valeur_observee = observed, severite = severity,
      description = message, stringsAsFactors = FALSE)
    invisible(NULL)
  }
  skip <- function(rule, table, field, message) {
    checks[[length(checks) + 1L]] <<- data.frame(regle = rule, table = table, champ = field,
      severite = "bloquant", statut = "non_execute", n_evaluees = 0L,
      n_non_evaluees = if (is.data.frame(dataset[[table]])) nrow(dataset[[table]]) else 0L,
      n_alertes = NA_integer_, description = message, stringsAsFactors = FALSE)
  }
  for (table in names(schema)) {
    x <- dataset[[table]]
    exists <- is.data.frame(x)
    record("schema_table", table, "", !exists, "Table requise presente et de type data.frame",
      rows = NA_integer_)
    if (!exists) next
    ok <- TRUE
    for (field in names(schema[[table]])) {
      present <- field %in% names(x)
      type_ok <- present && identical(class(x[[field]]), unname(schema[[table]][field]))
      record("schema_colonne", table, field, !type_ok,
        paste("Colonne requise de type", schema[[table]][[field]]), rows = NA_integer_,
        value = if (present) paste(class(x[[field]]), collapse = "/") else "ABSENTE")
      ok <- ok && type_ok
    }
    ready[[table]] <- ok
    for (field in names(x)) {
      missing[[length(missing) + 1L]] <- data.frame(table = table, champ = field,
        type = paste(class(x[[field]]), collapse = "/"), n_lignes = nrow(x),
        n_manquants = sum(is.na(x[[field]])), stringsAsFactors = FALSE)
    }
  }
  run <- function(rule, table, field, fun, parents = character(), severity = "bloquant") {
    if (!all(ready[c(table, parents)])) {
      skip(rule, table, field, "Non execute : schema de la table ou d'une dependance invalide")
    } else {
      value <- fun()
      record(rule, table, field, value$bad, value$message, severity,
        rows = if (is.null(value$rows)) seq_along(value$bad) else value$rows,
        ignored = if (is.null(value$ignored)) 0L else value$ignored, value = value$value)
    }
  }
  mandatory <- list(
    etudiants = c("id_etudiant", "parcours_anterieur"), formations = names(schema$formations),
    inscriptions = c("id_inscription", "id_etudiant", "id_formation", "annee_universitaire",
      "niveau", "date_inscription", "statut_inscription"),
    resultats = c("id_inscription", "validation_annuelle"),
    parcours = c("id_inscription_depart", "etat_transition"),
    invitations_evaluation = names(schema$invitations_evaluation),
    evaluations = c("id_reponse_evaluation", "id_invitation_evaluation", "date_reponse"),
    decisions_diplome = c("id_inscription", "attribution_diplome"),
    diplomes = names(schema$diplomes), invitations_devenir = names(schema$invitations_devenir),
    devenir_diplomes = c("id_reponse_devenir", "id_invitation_devenir", "date_reponse"))
  for (table in names(schema)) {
    run(if (table == "inscriptions") "unicite_inscription" else "unicite_cle", table, keys[[table]], function() {
      x <- dataset[[table]][[keys[[table]]]]
      list(bad = duplicated(x) | duplicated(x, fromLast = TRUE), message = "Cle primaire unique")
    })
    for (field in mandatory[[table]]) run("valeur_obligatoire", table, field, function() {
      x <- dataset[[table]][[field]]
      list(bad = is.na(x) | (is.character(x) & !nzchar(trimws(as.character(x)))),
        message = "Valeur obligatoire non manquante et non vide")
    })
  }
  domains <- list(
    etudiants = list(type_bac = names(config$population$type_bac),
      parcours_anterieur = names(config$population$parcours_anterieur), motif_type_bac_manquant = "non_disponible"),
    formations = list(cycle = c("licence", "master")),
    inscriptions = list(annee_universitaire = config$annees, niveau = c("L1", "L2", "L3", "M1", "M2"),
      statut_inscription = c("active", "annulee"), motif_boursier_manquant = "non_disponible"),
    resultats = list(validation_annuelle = c("oui", "non", "inconnu"),
      motif_resultat_inconnu = c("non_disponible", "dossier_incomplet")),
    parcours = list(etat_transition = c("passage", "redoublement", "reorientation", "sortie_observee",
      "poursuite_intercycle", "autre", "non_observable")),
    invitations_evaluation = list(statut_reponse = c("aucune", "partielle", "complete")),
    decisions_diplome = list(attribution_diplome = c("oui", "non", "inconnu")),
    diplomes = list(type_diplome = c("licence", "master")),
    invitations_devenir = list(statut_reponse = c("aucune", "partielle", "complete")),
    devenir_diplomes = list(situation_six_mois = c("etudes", "emploi_hors_etudes",
      "recherche_emploi_hors_etudes", "autre_hors_etudes"),
      motif_situation_manquante = c("non_reponse_item", "ne_sait_pas"),
      motif_emploi_pendant_etudes_manquant = c("non_applicable", "non_reponse_item")))
  for (table in names(domains)) for (field in names(domains[[table]])) {
    run("domaine_categoriel", table, field, function() {
      x <- dataset[[table]][[field]]
      list(bad = !is.na(x) & !x %in% domains[[table]][[field]], message = "Modalite du dictionnaire")
    })
  }
  run("poids_formation", "formations", "poids_dans_cycle", function() {
    x <- dataset$formations
    total <- ave(x$poids_dans_cycle, x$cycle, FUN = sum)
    list(bad = !is.finite(x$poids_dans_cycle) | x$poids_dans_cycle <= 0 |
      is.na(total) | abs(total - 1) > 1e-8, message = "Poids positifs de somme 1 dans chaque cycle")
  })
  for (spec in list(c("diplomes", "id_inscription"),
                   c("invitations_evaluation", "id_inscription", "vague"),
                   c("invitations_devenir", "id_diplome", "vague"))) {
    table <- spec[1L]
    fields <- spec[-1L]
    run("unicite_unite_metier", table, fields[1L], function() {
      x <- dataset[[table]][fields]
      list(bad = duplicated(x) | duplicated(x, fromLast = TRUE),
        message = paste("Unite metier unique :", paste(fields, collapse = "/")))
    })
  }
  reason_pair <- function(table, field, reason, required_missing = NULL) {
    run("coherence_manquant_motif", table, field, function() {
      x <- dataset[[table]][[field]]
      r <- dataset[[table]][[reason]]
      bad <- is.na(x) != !is.na(r)
      if (!is.null(required_missing)) bad <- bad | (is.na(x) != required_missing())
      list(bad = bad, message = paste("Valeur manquante coherente avec", reason))
    })
  }
  reason_pair("etudiants", "type_bac", "motif_type_bac_manquant")
  reason_pair("inscriptions", "boursier", "motif_boursier_manquant")
  reason_pair("resultats", "moyenne_annuelle", "motif_resultat_inconnu",
    function() dataset$resultats$validation_annuelle == "inconnu")
  reason_pair("devenir_diplomes", "situation_six_mois", "motif_situation_manquante")
  for (item in c("globale", "contenus", "accompagnement")) {
    field <- paste0("satisfaction_", item)
    reason <- paste0("motif_satisfaction_", item)
    reason_pair("evaluations", field, reason)
    run("domaine_satisfaction", "evaluations", field, function() {
      x <- dataset$evaluations[[field]]
      list(bad = !is.na(x) & !x %in% 1:5, message = "Satisfaction entiere de 1 a 5")
    })
    run("domaine_motif_satisfaction", "evaluations", reason, function() {
      x <- dataset$evaluations[[reason]]
      list(bad = !is.na(x) & !x %in% c("non_reponse_item", "non_concerne"), message = "Motif d'item autorise")
    })
  }
  refs <- list(
    c("reference_etudiant", "inscriptions", "id_etudiant", "etudiants", "id_etudiant"),
    c("reference_formation", "inscriptions", "id_formation", "formations", "id_formation"),
    c("reference_inscription", "resultats", "id_inscription", "inscriptions", "id_inscription"),
    c("reference_inscription", "parcours", "id_inscription_depart", "inscriptions", "id_inscription"),
    c("reference_inscription_suivante", "parcours", "id_inscription_suivante", "inscriptions", "id_inscription"),
    c("reference_inscription", "invitations_evaluation", "id_inscription", "inscriptions", "id_inscription"),
    c("reference_invitation", "evaluations", "id_invitation_evaluation", "invitations_evaluation", "id_invitation_evaluation"),
    c("reference_inscription", "decisions_diplome", "id_inscription", "inscriptions", "id_inscription"),
    c("reference_inscription", "diplomes", "id_inscription", "inscriptions", "id_inscription"),
    c("reference_diplome", "invitations_devenir", "id_diplome", "diplomes", "id_diplome"),
    c("reference_invitation", "devenir_diplomes", "id_invitation_devenir", "invitations_devenir", "id_invitation_devenir"))
  for (ref in refs) run(ref[1], ref[2], ref[3], function() {
    x <- dataset[[ref[2]]][[ref[3]]]
    list(bad = !is.na(x) & !x %in% dataset[[ref[4]]][[ref[5]]], message = paste("Reference vers", ref[4]))
  }, parents = ref[4])
  # Match sans multiplication ; une cle parent ambigue ne permet pas de comparaison.
  matched <- function(child, parent) {
    idx <- match(child, parent)
    ambiguous <- parent[duplicated(parent) | duplicated(parent, fromLast = TRUE)]
    idx[child %in% ambiguous | is.na(child)] <- NA_integer_
    idx
  }
  year_date <- function(years, month_day, end = FALSE) {
    dates <- as.Date(paste0(as.integer(substr(config$annees, 1, 4)) + as.integer(end), "-", month_day))
    dates[match(years, config$annees)]
  }
  cross <- function(rule, table, field, parent, child_key, parent_key, fun, others = character()) {
    run(rule, table, field, function() {
      idx <- matched(dataset[[table]][[child_key]], dataset[[parent]][[parent_key]])
      rows <- which(!is.na(idx))
      child <- dataset[[table]][[child_key]]
      optional <- identical(table, "parcours") && identical(child_key, "id_inscription_suivante")
      list(bad = fun(rows, idx[rows]), rows = rows,
        ignored = sum(is.na(idx) & (!is.na(child) | !optional)),
        message = "Coherence entre tables ; references absentes ou ambigues non comparees")
    }, parents = c(parent, others))
  }
  run("unicite_etudiant_annee", "inscriptions", "id_etudiant", function() {
    x <- dataset$inscriptions[c("id_etudiant", "annee_universitaire")]
    list(bad = duplicated(x) | duplicated(x, fromLast = TRUE), message = "Une inscription principale par personne et annee")
  })
  cross("coherence_cycle_niveau", "inscriptions", "niveau", "formations", "id_formation", "id_formation",
    function(a, b) (substr(dataset$inscriptions$niveau[a], 1, 1) == "L") != (dataset$formations$cycle[b] == "licence"))
  run("chronologie_inscription", "inscriptions", "date_inscription", function() {
    x <- dataset$inscriptions
    year <- match(x$annee_universitaire, config$annees)
    reference <- year_date(x$annee_universitaire, "10-31")
    list(bad = is.na(year) | is.na(x$date_inscription) | x$date_inscription > reference,
      message = "Inscription datee au plus tard a la reference annuelle")
  })
  run("domaine_moyenne", "resultats", "moyenne_annuelle", function() {
    x <- dataset$resultats$moyenne_annuelle
    list(bad = !is.na(x) & (!is.finite(x) | x < 0 | x > 20), message = "Moyenne comprise entre 0 et 20")
  })
  run("domaine_ects", "resultats", "ects_acquis", function() {
    x <- dataset$resultats$ects_acquis
    list(bad = !is.na(x) & !x %in% 0:60, message = "ECTS entiers de 0 a 60")
  })
  run("coherence_ects", "resultats", "ects_acquis", function() {
    x <- dataset$resultats
    unknown <- x$validation_annuelle == "inconnu"
    bad <- (is.na(x$ects_acquis) != unknown) |
      (!unknown & x$validation_annuelle == "oui" & x$ects_acquis != 60L) |
      (!unknown & x$validation_annuelle == "non" & x$ects_acquis >= 60L)
    list(bad = bad, message = "ECTS coherents avec la decision annuelle du simulateur")
  })
  run("coherence_moyenne_validation", "resultats", "moyenne_annuelle", function() {
    x <- dataset$resultats
    list(bad = (x$validation_annuelle == "oui" & x$moyenne_annuelle < 10) |
      (x$validation_annuelle == "non" & x$moyenne_annuelle >= 10), message = "Moyenne coherente avec la decision selon le modele simplifie")
  })
  cross("chronologie_resultat", "resultats", "date_decision", "inscriptions", "id_inscription", "id_inscription",
    function(a, b) {
      x <- dataset$resultats
      unknown <- x$validation_annuelle[a] == "inconnu"
      end <- year_date(dataset$inscriptions$annee_universitaire[b], "09-30", TRUE)
      (is.na(x$date_decision[a]) != unknown) |
        (!unknown & (x$date_decision[a] < dataset$inscriptions$date_inscription[b] |
          x$date_decision[a] > end | x$date_decision[a] > config$date_gel))
    })
  cross("chronologie_diplome", "decisions_diplome", "date_decision_diplome", "inscriptions", "id_inscription", "id_inscription",
    function(a, b) {
      x <- dataset$decisions_diplome
      unknown <- x$attribution_diplome[a] == "inconnu"
      end <- year_date(dataset$inscriptions$annee_universitaire[b], "09-30", TRUE)
      (is.na(x$date_decision_diplome[a]) != unknown) |
        (!unknown & (x$date_decision_diplome[a] < dataset$inscriptions$date_inscription[b] |
          x$date_decision_diplome[a] > end | x$date_decision_diplome[a] > config$date_gel))
    })
  cross("niveau_terminal_diplome", "decisions_diplome", "attribution_diplome", "inscriptions", "id_inscription", "id_inscription",
    function(a, b) !dataset$inscriptions$niveau[b] %in% c("L3", "M2"))
  cross("decision_diplome_validation", "decisions_diplome", "attribution_diplome", "resultats", "id_inscription", "id_inscription",
    function(a, b) {
      x <- dataset$decisions_diplome$attribution_diplome[a]
      y <- dataset$resultats$validation_annuelle[b]
      (x == "oui" & y != "oui") | (x == "inconnu" & y != "inconnu") | (y == "inconnu" & x != "inconnu")
    })
  cross("attribution_diplome", "diplomes", "date_diplome", "decisions_diplome", "id_inscription", "id_inscription",
    function(a, b) dataset$decisions_diplome$attribution_diplome[b] != "oui" |
      dataset$diplomes$date_diplome[a] != dataset$decisions_diplome$date_decision_diplome[b])
  cross("type_diplome_niveau", "diplomes", "type_diplome", "inscriptions", "id_inscription", "id_inscription",
    function(a, b) !paste(dataset$diplomes$type_diplome[a], dataset$inscriptions$niveau[b]) %in% c("licence L3", "master M2"))
  cross("prerequis_diplome", "diplomes", "id_inscription", "inscriptions", "id_inscription", "id_inscription",
    function(a, b) is.na(dataset$inscriptions$prerequis_valides[b]) | !dataset$inscriptions$prerequis_valides[b])
  for (table in c("resultats", "parcours", "invitations_evaluation", "decisions_diplome")) {
    field <- if (table == "parcours") "id_inscription_depart" else "id_inscription"
    run(paste0("exhaustivite_", table), "inscriptions", "id_inscription", function() {
      eligible <- if (table == "decisions_diplome") dataset$inscriptions$niveau %in% c("L3", "M2")
                  else dataset$inscriptions$statut_inscription == "active"
      list(bad = eligible & !dataset$inscriptions$id_inscription %in% dataset[[table]][[field]],
        message = paste("Inscription eligible representee dans", table))
    }, parents = table)
  }
  run("exhaustivite_attributions", "decisions_diplome", "id_inscription", function() {
    x <- dataset$decisions_diplome
    list(bad = x$attribution_diplome == "oui" & !x$id_inscription %in% dataset$diplomes$id_inscription,
      message = "Toute decision positive correspond a une attribution")
  }, parents = "diplomes")
  # Controles des parcours : les etats sont compares a une reconstruction independante.
  cross("annee_transition_suivante", "parcours", "id_inscription_suivante", "inscriptions", "id_inscription_suivante", "id_inscription",
    function(a, b) {
      from <- matched(dataset$parcours$id_inscription_depart[a], dataset$inscriptions$id_inscription)
      year <- match(dataset$inscriptions$annee_universitaire, config$annees)
      is.na(from) | year[b] != year[from] + 1L |
        dataset$inscriptions$id_etudiant[b] != dataset$inscriptions$id_etudiant[from]
    })
  cross("etat_transition", "parcours", "etat_transition", "inscriptions", "id_inscription_depart", "id_inscription",
    function(a, b) {
      ins <- dataset$inscriptions
      p <- dataset$parcours
      year <- match(ins$annee_universitaire, config$annees)
      next_row <- matched(p$id_inscription_suivante[a], ins$id_inscription)
      exists_next <- paste(ins$id_etudiant[b], year[b] + 1L) %in% paste(ins$id_etudiant, year)
      decision <- dataset$resultats$validation_annuelle[matched(p$id_inscription_depart[a], dataset$resultats$id_inscription)]
      last <- year[b] == length(config$annees)
      state <- p$etat_transition[a]
      bad <- (state == "non_observable") != last |
        (state == "sortie_observee") != (!last & !exists_next) |
        ((last | !exists_next) & !is.na(p$id_inscription_suivante[a])) |
        (!last & exists_next & is.na(next_row))
      rows <- which(!last & !is.na(next_row))
      dest <- next_row[rows]
      origin <- b[rows]
      expected <- rep("autre", length(rows))
      same <- ins$id_formation[origin] == ins$id_formation[dest]
      inter <- ins$niveau[origin] == "L3" & ins$niveau[dest] == "M1" & decision[rows] == "oui"
      expected[which(!same & !inter)] <- "reorientation"
      expected[which(inter)] <- "poursuite_intercycle"
      pairs <- paste(ins$niveau[origin], ins$niveau[dest])
      expected[which(same & decision[rows] == "oui" & pairs %in% c("L1 L2", "L2 L3", "M1 M2"))] <- "passage"
      expected[which(same & decision[rows] == "non" & ins$niveau[origin] == ins$niveau[dest])] <- "redoublement"
      bad[rows] <- bad[rows] | state[rows] != expected
      bad
    }, others = "resultats")
  # Regles des enquetes et eligibilite a six mois.
  for (kind in c("evaluation", "devenir")) {
    inv <- paste0("invitations_", kind)
    response <- if (kind == "evaluation") "evaluations" else "devenir_diplomes"
    field <- paste0("id_invitation_", kind)
    run("unicite_reponse_invitation", response, field, function() {
      x <- dataset[[response]][[field]]
      list(bad = duplicated(x) | duplicated(x, fromLast = TRUE), message = "Une reponse au plus par invitation")
    })
    run("fenetre_collecte", inv, "date_cloture", function() {
      x <- dataset[[inv]]
      list(bad = x$date_ouverture > x$date_cloture | x$date_cloture > config$date_gel,
        message = "Fenetre ordonnee et close au gel")
    })
    cross("chronologie_reponse", response, "date_reponse", inv, field, field,
      function(a, b) dataset[[response]]$date_reponse[a] < dataset[[inv]]$date_ouverture[b] |
        dataset[[response]]$date_reponse[a] > dataset[[inv]]$date_cloture[b])
    run("statut_reponse_presence", inv, "statut_reponse", function() {
      x <- dataset[[inv]]
      exists <- x[[field]] %in% dataset[[response]][[field]]
      list(bad = (x$statut_reponse == "aucune") != !exists,
        message = "Non reponse totale sans ligne ; autres statuts avec reponse")
    }, parents = response)
  }
  cross("completude_evaluation", "evaluations", "id_invitation_evaluation", "invitations_evaluation",
    "id_invitation_evaluation", "id_invitation_evaluation", function(a, b) {
      answered <- integer(length(a))
      for (item in c("globale", "contenus", "accompagnement")) {
        v <- dataset$evaluations[[paste0("satisfaction_", item)]][a]
        r <- dataset$evaluations[[paste0("motif_satisfaction_", item)]][a]
        answered <- answered + as.integer(!is.na(v) | (!is.na(r) & r == "non_concerne"))
      }
      status <- ifelse(answered == 3L, "complete", ifelse(answered > 0L, "partielle", "aucune"))
      dataset$invitations_evaluation$statut_reponse[b] != status | answered == 0L
    })
  cross("dates_evaluation_annuelle", "invitations_evaluation", "date_ouverture", "inscriptions", "id_inscription", "id_inscription",
    function(a, b) {
      year <- dataset$inscriptions$annee_universitaire[b]
      dataset$invitations_evaluation$date_ouverture[a] != year_date(year, config$calendrier$evaluation_debut, TRUE) |
        dataset$invitations_evaluation$date_cloture[a] != year_date(year, config$calendrier$evaluation_fin, TRUE)
    })
  cross("eligibilite_devenir", "invitations_devenir", "date_reference", "diplomes", "id_diplome", "id_diplome",
    function(a, b) {
      date <- dataset$diplomes$date_diplome[b]
      opening <- as.Date(lubridate::`%m+%`(date, lubridate::period(config$devenir$horizon_mois, units = "months")))
      closing <- as.Date(lubridate::`%m+%`(date, lubridate::period(config$devenir$cloture_mois, units = "months")))
      x <- dataset$invitations_devenir
      x$date_reference[a] != opening | x$date_ouverture[a] != opening |
        x$date_cloture[a] != closing | closing > config$date_gel
    })
  eligible_degrees <- function() {
    dip <- dataset$diplomes
    ins <- dataset$inscriptions
    parent <- matched(dip$id_inscription, ins$id_inscription)
    closing <- as.Date(lubridate::`%m+%`(dip$date_diplome,
      lubridate::period(config$devenir$cloture_mois, units = "months")))
    person <- ins$id_etudiant[parent]
    rows <- which(!is.na(parent) & !is.na(person) & !is.na(closing) & closing <= config$date_gel)
    rows <- rows[order(person[rows], -as.numeric(dip$date_diplome[rows]), dip$id_diplome[rows])]
    rows <- rows[!duplicated(person[rows])]
    list(rows = rows, person = person, unresolved = is.na(parent))
  }
  run("selection_devenir", "invitations_devenir", "id_diplome", function() {
    eligible <- eligible_degrees()
    inv <- dataset$invitations_devenir
    dip <- dataset$diplomes
    parent <- matched(inv$id_diplome, dip$id_diplome)
    rows <- which(!is.na(parent) & !eligible$unresolved[parent])
    person <- eligible$person[parent[rows]]
    unit <- paste(person, inv$vague[rows])
    list(bad = !inv$id_diplome[rows] %in% dip$id_diplome[eligible$rows] |
      duplicated(unit) | duplicated(unit, fromLast = TRUE), rows = rows,
      ignored = nrow(inv) - length(rows), message = "Dernier diplome mature par personne et une invitation par vague")
  }, parents = c("diplomes", "inscriptions"))
  run("exhaustivite_devenir", "diplomes", "id_diplome", function() {
    eligible <- eligible_degrees()
    x <- dataset$diplomes
    list(bad = seq_len(nrow(x)) %in% eligible$rows & !x$id_diplome %in% dataset$invitations_devenir$id_diplome,
      ignored = sum(eligible$unresolved), message = "Diplomes de reference eligibles tous invites")
  }, parents = c("invitations_devenir", "inscriptions"))
  run("emploi_pendant_etudes", "devenir_diplomes", "emploi_pendant_etudes", function() {
    x <- dataset$devenir_diplomes
    studies <- !is.na(x$situation_six_mois) & x$situation_six_mois == "etudes"
    bad <- (!studies & (!is.na(x$emploi_pendant_etudes) |
                         is.na(x$motif_emploi_pendant_etudes_manquant) |
                         x$motif_emploi_pendant_etudes_manquant != "non_applicable")) |
      (studies & (is.na(x$emploi_pendant_etudes) != !is.na(x$motif_emploi_pendant_etudes_manquant)))
    list(bad = bad, message = "Emploi conditionnel aux etudes ; motif requis si non applicable ou non reponse")
  })
  cross("completude_devenir", "devenir_diplomes", "situation_six_mois", "invitations_devenir",
    "id_invitation_devenir", "id_invitation_devenir", function(a, b) {
      x <- dataset$devenir_diplomes
      studies <- !is.na(x$situation_six_mois[a]) & x$situation_six_mois[a] == "etudes"
      complete <- !is.na(x$situation_six_mois[a]) & (!studies | !is.na(x$emploi_pendant_etudes[a]))
      dataset$invitations_devenir$statut_reponse[b] != ifelse(complete, "complete", "partielle")
    })
  checks <- do.call(rbind, checks)
  detail_template <- data.frame(regle = character(), table = character(), ligne = integer(),
    cle = character(), champ = character(), valeur_observee = character(), severite = character(), description = character())
  details <- if (length(details)) do.call(rbind, details) else detail_template
  missing <- if (length(missing)) do.call(rbind, missing) else data.frame()
  verdict <- if (any(checks$statut == "non_conforme" & checks$severite == "bloquant")) "non_conforme"
    else if (any(checks$statut == "non_execute") || any(checks$n_non_evaluees > 0)) "incomplet"
    else if (any(checks$statut == "non_conforme")) "a_examiner" else "conforme"
  list(checks = checks, details = details, missing = missing,
    metadata = list(variante = label, version_controles = "0.1", verdict = verdict,
      provenance = dataset$metadata$provenance, date_gel = config$date_gel,
      n_alertes = nrow(details), n_regles = nrow(checks)))
}

#' Rapprocher les injections connues des alertes effectivement produites
#' @param report Resultat de check_quality().
#' @param issues Journal de inject_quality_issues(), avant tout tri des tables.
#' @return Journal enrichi : detectee et nombre d'alertes de la regle cible.
#' @details Mesure la detection des injections connues, pas une sensibilite generale.
match_quality_injections <- function(report, issues) {
  required <- c("id_anomalie", "table", "ligne", "champ", "controle_attendu")
  if (!is.data.frame(issues) || !all(required %in% names(issues)))
    stop("Journal des injections incomplet.", call. = FALSE)
  signature <- function(rule, table, row, field) paste(rule, table, row, field, sep = "|")
  d <- report$details
  observed <- table(signature(d$regle, d$table, d$ligne, d$champ))
  target <- signature(issues$controle_attendu, issues$table, issues$ligne, issues$champ)
  n <- as.integer(observed[target])
  n[is.na(n)] <- 0L
  cbind(issues, n_alertes_cible = n, detectee = n > 0L)
}
