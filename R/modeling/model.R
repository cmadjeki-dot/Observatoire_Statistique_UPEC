# GLM exploratoire : coupe initiale, une observation par etudiant.

#' Preparer explicitement la population et les references du modele valide
#' @param data Table scolarite_analytique controlee.
#' @param year Annee initiale du protocole.
#' @return Liste data (cas complets), selection et comparaison inclus/exclus.
prepare_success_model <- function(data, year = "2023-2024") {
  fields <- c("id_etudiant", "id_inscription", "annee_universitaire", "statut_inscription",
    "validation_annuelle", "niveau", "id_formation", "type_bac", "parcours_anterieur", "boursier")
  if (!is.data.frame(data) || !all(fields %in% names(data)))
    stop("Colonnes de modelisation absentes.", call. = FALSE)
  x <- data[data$annee_universitaire == year & data$statut_inscription == "active", fields]
  if (!nrow(x) || anyNA(x[c("id_etudiant", "id_inscription", "validation_annuelle")]) ||
      anyDuplicated(x$id_etudiant) || anyDuplicated(x$id_inscription) ||
      !all(x$validation_annuelle %in% c("oui", "non", "inconnu")) || !is.logical(x$boursier))
    stop("Population initiale, cible ou cles invalides.", call. = FALSE)
  levels_list <- list(niveau = c("L1", "L2", "L3", "M1", "M2"),
    id_formation = c("FL_A", "FL_B", "FL_C", "FM_A", "FM_B"),
    type_bac = c("general", "technologique", "professionnel", "autre"),
    parcours_anterieur = c("entree_postbac", "reprise_etudes", "autre"))
  for (field in names(levels_list)) {
    if (!all(stats::na.omit(x[[field]]) %in% levels_list[[field]]))
      stop("Modalite inattendue : ", field, call. = FALSE)
  }
  known <- x$validation_annuelle != "inconnu"
  covariates <- c(names(levels_list), "boursier")
  complete <- stats::complete.cases(x[covariates])
  status <- ifelse(!known, "resultat_inconnu", ifelse(!complete, "covariable_manquante", "inclus"))
  selection <- x[c("id_etudiant", "id_inscription")]
  selection$statut <- status
  selection$decision_connue <- known
  selection$covariables_completes <- complete
  comparison <- do.call(rbind, lapply(covariates, function(field) {
    z <- data.frame(statut = status, modalite = as.character(x[[field]]),
      est_manquant = is.na(x[[field]]))
    z <- dplyr::count(z, .data$statut, .data$modalite, .data$est_manquant, name = "effectif")
    z <- dplyr::mutate(dplyr::group_by(z, .data$statut),
      denominateur = sum(.data$effectif), pourcentage = 100 * .data$effectif / .data$denominateur)
    z$variable <- field
    as.data.frame(dplyr::ungroup(z))
  }))
  x <- x[status == "inclus", ]
  x <- x[order(x$id_etudiant), ]
  if (!nrow(x)) stop("Aucun cas complet.", call. = FALSE)
  for (field in names(levels_list)) x[[field]] <- factor(x[[field]], levels = levels_list[[field]])
  licence <- x$niveau %in% c("L1", "L2", "L3")
  if (any(licence != (x$id_formation %in% c("FL_A", "FL_B", "FL_C"))))
    stop("Formation et niveau incompatibles.", call. = FALSE)
  x$validation <- as.integer(x$validation_annuelle == "oui")
  x$formation_licence_B <- as.integer(x$id_formation == "FL_B")
  x$formation_licence_C <- as.integer(x$id_formation == "FL_C")
  x$formation_master_B <- as.integer(x$id_formation == "FM_B")
  rownames(x) <- NULL
  list(data = x, selection = selection, comparaison = comparison,
    references = c(niveau = "L1", formation_licence = "FL_A", formation_master = "FM_A",
      type_bac = "general", parcours_anterieur = "entree_postbac", boursier = "FALSE"))
}

#' Separer les etudiants, avec stratification de la cible et restauration RNG
#' @param data Cas complets prepares, une ligne par etudiant.
#' @param seed Graine fixee avant estimation.
#' @param proportion Part d'apprentissage.
#' @return Listes train/test et journal d'affectation.
split_success_model <- function(data, seed = 20261020L, proportion = 0.8) {
  if (!all(c("id_etudiant", "id_inscription", "validation") %in% names(data)) ||
      anyNA(data[c("id_etudiant", "id_inscription", "validation")]) ||
      anyDuplicated(data$id_etudiant) || !setequal(unique(data$validation), c(0L, 1L)) ||
      length(proportion) != 1L || !is.finite(proportion) || proportion <= 0 || proportion >= 1)
    stop("Population ou proportion de separation invalide.", call. = FALSE)
  if (any(table(data$validation) < 2L)) stop("Deux observations minimum par classe.", call. = FALSE)
  data <- data[order(data$id_etudiant), ]
  indices <- withr::with_seed(seed, {
    unlist(lapply(c(0L, 1L), function(value) {
      rows <- which(data$validation == value)
      size <- min(length(rows) - 1L, max(1L, floor(proportion * length(rows))))
      rows[sample.int(length(rows), size)]
    }), use.names = FALSE)
  }, .rng_kind = "Mersenne-Twister", .rng_normal_kind = "Inversion", .rng_sample_kind = "Rejection")
  train <- seq_len(nrow(data)) %in% indices
  assignment <- data[c("id_etudiant", "id_inscription", "validation")]
  assignment$echantillon <- ifelse(train, "apprentissage", "test")
  list(train = data[train, ], test = data[!train, ], affectations = assignment, seed = seed)
}

#' Estimer la formule validee sur l'apprentissage uniquement
#' @param train Cas complets d'apprentissage.
#' @return Objet glm ; arret sur avertissement d'estimation ou anomalie numerique.
fit_success_model <- function(train) {
  formula <- validation ~ niveau + formation_licence_B + formation_licence_C +
    formation_master_B + type_bac + parcours_anterieur + boursier
  environment(formula) <- baseenv()
  if (anyNA(train[all.vars(formula)]) || anyDuplicated(train$id_etudiant) ||
      !setequal(unique(train$validation), c(0L, 1L)))
    stop("Apprentissage incomplet ou cible invalide.", call. = FALSE)
  matrix <- stats::model.matrix(formula, train,
    contrasts.arg = list(niveau = "contr.treatment", type_bac = "contr.treatment",
      parcours_anterieur = "contr.treatment"))
  if (qr(matrix)$rank != ncol(matrix)) stop("Matrice de rang deficient.", call. = FALSE)
  model <- withCallingHandlers(stats::glm(formula, family = stats::binomial("logit"),
    data = train, na.action = stats::na.fail, singular.ok = FALSE,
    contrasts = list(niveau = "contr.treatment", type_bac = "contr.treatment",
      parcours_anterieur = "contr.treatment")), warning = function(w)
      stop("Avertissement glm a investiguer : ", conditionMessage(w), call. = FALSE))
  if (!isTRUE(model$converged) || isTRUE(model$boundary) ||
      any(!is.finite(stats::coef(model))) || any(!is.finite(stats::vcov(model))) ||
      any(stats::fitted(model) < 1e-8 | stats::fitted(model) > 1 - 1e-8))
    stop("Convergence, frontiere ou probabilites extremes : investigation requise.", call. = FALSE)
  model
}

#' Extraire coefficients et IC de Wald a 95 pour cent
#' @param model GLM estime.
#' @return Table log-odds, erreur standard, odds ratio et IC (approximation asymptotique).
success_coefficients <- function(model) {
  beta <- stats::coef(model)
  se <- sqrt(diag(stats::vcov(model)))
  z <- stats::qnorm(0.975)
  data.frame(terme = names(beta), coefficient = unname(beta), erreur_standard = unname(se),
    odds_ratio = unname(exp(beta)), ic95_bas = unname(exp(beta - z * se)),
    ic95_haut = unname(exp(beta + z * se)), methode_ic = "Wald_asymptotique_95pct",
    row.names = NULL)
}

#' Mesurer AUC, Brier et log-loss sans ajuster les predictions
#' @param y Cible binaire ; 1 = validation.
#' @param probability Probabilite de validation.
#' @return Une ligne de performances ; AUC NA si une seule classe.
success_metrics <- function(y, probability) {
  if (!length(y) || length(y) != length(probability) || anyNA(y) ||
      !all(y %in% c(0, 1)) || anyNA(probability) ||
      any(!is.finite(probability) | probability < 0 | probability > 1))
    stop("Cibles ou probabilites invalides.", call. = FALSE)
  yes <- sum(y == 1)
  no <- sum(y == 0)
  auc <- if (yes && no) (sum(rank(probability, ties.method = "average")[y == 1]) -
    yes * (yes + 1) / 2) / (yes * no) else NA_real_
  clipped <- pmin(1 - 1e-15, pmax(1e-15, probability))
  data.frame(n = length(y), n_validations = yes, auc = auc,
    brier = mean((y - probability)^2),
    log_loss = -mean(y * log(clipped) + (1 - y) * log1p(-clipped)),
    frequence_observee = mean(y), probabilite_moyenne = mean(probability),
    ecart_calibration_moyen = mean(probability) - mean(y))
}

#' Evaluer uniquement sur test, avec reference constante apprise sur train
#' @param model GLM d'apprentissage.
#' @param split Resultat de split_success_model().
#' @return Performances comparatives, calibration par quintiles et predictions test.
evaluate_success_model <- function(model, split) {
  if (length(intersect(split$train$id_etudiant, split$test$id_etudiant)))
    stop("Fuite : etudiants partages entre apprentissage et test.", call. = FALSE)
  if (stats::nobs(model) != nrow(split$train) ||
      !identical(rownames(stats::model.frame(model)), rownames(split$train)))
    stop("Modele et echantillon d'apprentissage incompatibles.", call. = FALSE)
  probability <- as.numeric(stats::predict(model, newdata = split$test, type = "response"))
  constant <- mean(split$train$validation)
  metrics <- rbind(success_metrics(split$test$validation, probability),
    success_metrics(split$test$validation, rep(constant, nrow(split$test))))
  metrics$modele <- c("GLM_test", "reference_constante_test")
  # Bornes de risque apprises sur train ; ex aequo conserves dans le meme groupe.
  train_p <- stats::fitted(model)
  inner <- unique(as.numeric(stats::quantile(train_p, probs = seq(0.2, 0.8, 0.2), names = FALSE)))
  risk_group <- cut(probability, breaks = c(-Inf, inner, Inf), labels = FALSE, include.lowest = TRUE)
  predictions <- data.frame(id_etudiant = split$test$id_etudiant,
    id_inscription = split$test$id_inscription, validation = split$test$validation,
    probabilite = probability, groupe_risque = risk_group)
  calibration <- dplyr::summarise(dplyr::group_by(predictions, .data$groupe_risque),
    n = dplyr::n(), probabilite_moyenne = mean(.data$probabilite),
    frequence_observee = mean(.data$validation), .groups = "drop")
  calibration$diffusable <- calibration$n >= 10L
  calibration$probabilite_moyenne[!calibration$diffusable] <- NA_real_
  calibration$frequence_observee[!calibration$diffusable] <- NA_real_
  list(performances = metrics, calibration = as.data.frame(calibration),
    predictions_test = predictions, bornes_risque_train = inner)
}

#' Diagnostiquer influence et residus sur apprentissage, sans exclusion automatique
#' @param model GLM estime.
#' @param train Donnees d'apprentissage alignees au modele.
#' @return Liste resume et detail ; seuils indicatifs 2p/n, 4/n et |residu| > 3.
diagnose_success_model <- function(model, train) {
  if (stats::nobs(model) != nrow(train) ||
      !identical(rownames(stats::model.frame(model)), rownames(train)))
    stop("Alignement du diagnostic invalide.", call. = FALSE)
  n <- stats::nobs(model)
  p <- model$rank
  detail <- data.frame(id_etudiant = train$id_etudiant, id_inscription = train$id_inscription,
    probabilite = as.numeric(stats::fitted(model)),
    residu_deviance = as.numeric(stats::residuals(model, type = "deviance")),
    residu_pearson = as.numeric(stats::residuals(model, type = "pearson")),
    levier = as.numeric(stats::hatvalues(model)), cook = as.numeric(stats::cooks.distance(model)))
  detail$alerte_levier <- detail$levier > 2 * p / n
  detail$alerte_cook <- detail$cook > 4 / n
  detail$alerte_residu <- abs(detail$residu_pearson) > 3
  summary <- data.frame(n = n, parametres = p, convergence = model$converged,
    iterations = model$iter, probabilite_min = min(detail$probabilite),
    probabilite_max = max(detail$probabilite),
    n_leviers_signales = sum(detail$alerte_levier), n_cook_signales = sum(detail$alerte_cook),
    n_residus_signales = sum(detail$alerte_residu),
    coefficient_absolu_max = max(abs(stats::coef(model))),
    erreur_standard_max = max(sqrt(diag(stats::vcov(model)))))
  list(resume = summary, detail = detail)
}
