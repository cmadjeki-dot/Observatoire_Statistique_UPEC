# Suivi descriptif : aucune absence n'est assimilee a un abandon definitif.
# Prerequis : R/analysis/descriptive.R.

.longitudinal_threshold <- function(n) {
  if (length(n) != 1L || !is.numeric(n) || is.na(n) || !is.finite(n) || n < 1 || n != floor(n))
    stop("Seuil entier positif requis.", call. = FALSE)
}

#' Reconstruire les liens annuels et identifier les cohortes L1 observees
#' @param data Table scolarite_analytique verifiee.
#' @param decisions Table decisions_diplome verifiee.
#' @param years Annees du panel, dans l'ordre chronologique.
#' @return Inscriptions enrichies et grille personne/annee des cohortes L1.
prepare_longitudinal <- function(data, decisions,
    years = c("2023-2024", "2024-2025", "2025-2026")) {
  x <- .descriptive_check(data, c("niveau", "id_formation", "id_inscription_suivante"), 10L)
  if (length(years) != 3L || anyNA(years) || anyDuplicated(years) ||
      !identical(years, sort(years)) || !all(x$annee_universitaire %in% years) ||
      anyNA(x[c("niveau", "id_formation")])) stop("Panel longitudinal invalide.", call. = FALSE)
  year <- match(x$annee_universitaire, years)
  key <- paste(x$id_etudiant, year)
  next_row <- match(paste(x$id_etudiant, year + 1L), key)
  last <- year == length(years)
  next_row[last] <- NA_integer_
  expected <- rep("autre", nrow(x))
  expected[last] <- "non_observable"
  expected[!last & is.na(next_row)] <- "sortie_observee"
  observed <- which(!last & !is.na(next_row))
  a <- observed
  b <- next_row[a]
  inter <- x$niveau[a] == "L3" & x$niveau[b] == "M1" & x$validation_annuelle[a] == "oui"
  same <- x$id_formation[a] == x$id_formation[b]
  passage <- same & paste(x$niveau[a], x$niveau[b]) %in% c("L1 L2", "L2 L3", "M1 M2") &
    x$validation_annuelle[a] == "oui"
  repeat_year <- same & x$niveau[a] == x$niveau[b] & x$validation_annuelle[a] == "non"
  expected[a[!same & !inter]] <- "reorientation"
  expected[a[inter]] <- "poursuite_intercycle"
  expected[a[passage]] <- "passage"
  expected[a[repeat_year]] <- "redoublement"
  next_id <- x$id_inscription[next_row]
  same_id <- (is.na(next_id) & is.na(x$id_inscription_suivante)) |
    (!is.na(next_id) & !is.na(x$id_inscription_suivante) & next_id == x$id_inscription_suivante)
  if (!all(expected == x$etat_transition) || !all(same_id) ||
      !identical(x$transition_observable, !last))
    stop("Transitions stockees incompatibles avec les inscriptions observees.", call. = FALSE)
  if (!all(c("id_inscription", "attribution_diplome") %in% names(decisions)) ||
      anyNA(decisions$id_inscription) || anyDuplicated(decisions$id_inscription) ||
      !all(decisions$id_inscription %in% x$id_inscription) ||
      !all(decisions$attribution_diplome %in% c("oui", "non", "inconnu")))
    stop("Decisions de diplome invalides.", call. = FALSE)
  terminal <- x$niveau %in% c("L3", "M2")
  if (!setequal(decisions$id_inscription, x$id_inscription[terminal]))
    stop("Decisions terminales incompletes.", call. = FALSE)
  x$attribution_diplome <- decisions$attribution_diplome[match(x$id_inscription, decisions$id_inscription)]
  x$attribution_diplome[!terminal] <- "non_applicable"
  x$niveau_suivant <- ifelse(last, "non_observable",
    ifelse(is.na(next_row), "absence_observee", x$niveau[next_row]))
  ordered <- x[order(year, x$id_etudiant), ]
  first <- ordered[!duplicated(ordered$id_etudiant), ]
  first <- first[c("id_etudiant", "annee_universitaire", "niveau", "id_formation")]
  names(first)[-1L] <- c("premiere_annee", "premier_niveau", "formation_initiale")
  row <- match(x$id_etudiant, first$id_etudiant)
  x$cohorte_l1 <- ifelse(first$premier_niveau[row] == "L1", first$premiere_annee[row], NA_character_)
  cohort <- first[first$premier_niveau == "L1", ]
  names(cohort)[names(cohort) == "premiere_annee"] <- "cohorte_l1"
  grid <- tidyr::expand_grid(cohort, annee_universitaire = years)
  grid$horizon <- match(grid$annee_universitaire, years) - match(grid$cohorte_l1, years)
  grid <- grid[grid$horizon >= 0L, ]
  lookup <- match(paste(grid$id_etudiant, grid$annee_universitaire),
    paste(x$id_etudiant, x$annee_universitaire))
  grid$id_inscription <- x$id_inscription[lookup]
  grid$present <- !is.na(lookup)
  grid$niveau_observe <- ifelse(grid$present, x$niveau[lookup], "absence_observee")
  grid$transition_censuree <- grid$present & grid$annee_universitaire == tail(years, 1L)
  grid$etat_transition <- x$etat_transition[lookup]
  list(inscriptions = x, premieres_observations = first, suivi_l1 = as.data.frame(grid))
}

#' Mesurer la presence par horizon avec le denominateur initial de chaque cohorte
#' @param grid Grille suivi_l1 issue de prepare_longitudinal().
#' @param min_denominator Seuil de diffusion des proportions.
#' @return Une ligne par cohorte et horizon observable, sans extrapolation.
summarise_cohort_followup <- function(grid, min_denominator = 10L) {
  .longitudinal_threshold(min_denominator)
  if (anyDuplicated(grid[c("id_etudiant", "annee_universitaire")]) || anyNA(grid$present))
    stop("Grille de suivi invalide.", call. = FALSE)
  out <- dplyr::summarise(dplyr::group_by(grid, .data$cohorte_l1, .data$horizon, .data$annee_universitaire),
    n_cohorte_initiale = dplyr::n(), n_presents = sum(.data$present),
    n_absents_observes = sum(!.data$present),
    n_L1 = sum(.data$niveau_observe == "L1"), n_L2 = sum(.data$niveau_observe == "L2"),
    n_L3 = sum(.data$niveau_observe == "L3"), n_M1 = sum(.data$niveau_observe == "M1"),
    n_M2 = sum(.data$niveau_observe == "M2"),
    n_transitions_censurees = sum(.data$transition_censuree), .groups = "drop")
  out$presence_pct <- .descriptive_rate(out$n_presents, out$n_cohorte_initiale, min_denominator)
  stopifnot(all(out$n_cohorte_initiale == out$n_presents + out$n_absents_observes),
    all(out$n_presents == out$n_L1 + out$n_L2 + out$n_L3 + out$n_M1 + out$n_M2))
  as.data.frame(out)
}

#' Produire une matrice longue des niveaux annuels, sorties incluses
#' @param data Inscriptions enrichies, tous niveaux et cohortes confondus.
#' @param min_denominator Seuil de diffusion.
#' @return Arcs observes et parts par annee/niveau de depart ; cellules absentes = zero.
longitudinal_matrix <- function(data, min_denominator = 10L) {
  .longitudinal_threshold(min_denominator)
  x <- data[data$transition_observable, ]
  out <- dplyr::count(x, .data$annee_universitaire, .data$niveau, .data$niveau_suivant, name = "effectif")
  out <- dplyr::mutate(dplyr::group_by(out, .data$annee_universitaire, .data$niveau),
    denominateur = sum(.data$effectif),
    part_ligne_pct = .descriptive_rate(.data$effectif, .data$denominateur, min_denominator))
  as.data.frame(dplyr::ungroup(out))
}
