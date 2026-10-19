longitudinal_fixture <- function() {
  x <- data.frame(id_inscription = paste0("I", 1:9),
    id_etudiant = c("A", "A", "A", "B", "B", "C", "C", "D", "E"),
    annee_universitaire = c("2023-2024", "2024-2025", "2025-2026", "2023-2024", "2025-2026",
      "2024-2025", "2025-2026", "2023-2024", "2025-2026"),
    statut_inscription = "active", niveau = c("L1", "L2", "L2", "L1", "L1", "L1", "L1", "M2", "L1"),
    id_formation = c("FL_A", "FL_A", "FL_A", "FL_A", "FL_A", "FL_A", "FL_B", "FM_A", "FL_A"),
    validation_annuelle = c("oui", "non", "inconnu", "non", "oui", "oui", "oui", "oui", "oui"),
    id_inscription_suivante = c("I2", "I3", NA, NA, NA, "I7", NA, NA, NA),
    etat_transition = c("passage", "redoublement", "non_observable", "sortie_observee", "non_observable",
      "reorientation", "non_observable", "sortie_observee", "non_observable"))
  x$transition_observable <- x$annee_universitaire != "2025-2026"
  list(data = x, decisions = data.frame(id_inscription = "I8", attribution_diplome = "oui"))
}

testthat::test_that("les cohortes distinguent absence, retour, entree tardive et censure", {
  source(here::here("R", "analysis", "descriptive.R"), local = TRUE)
  source(here::here("R", "analysis", "longitudinal.R"), local = TRUE)
  fixture <- longitudinal_fixture()
  p <- prepare_longitudinal(fixture$data, fixture$decisions)
  testthat::expect_equal(sum(is.na(p$inscriptions$cohorte_l1)), 1L)
  follow <- summarise_cohort_followup(p$suivi_l1, min_denominator = 1L)
  a <- follow[follow$cohorte_l1 == "2023-2024", ]
  testthat::expect_equal(a$n_cohorte_initiale, c(2L, 2L, 2L))
  testthat::expect_equal(a$n_presents, c(2L, 1L, 2L))
  testthat::expect_equal(a$presence_pct, c(100, 50, 100))
  testthat::expect_equal(a$n_transitions_censurees, c(0L, 0L, 2L))
  testthat::expect_equal(max(follow$horizon[follow$cohorte_l1 == "2025-2026"]), 0L)
  testthat::expect_true(all(is.na(summarise_cohort_followup(p$suivi_l1)$presence_pct)))
  transition <- describe_transitions(p$inscriptions, min_denominator = 1L)
  testthat::expect_equal(sum(transition$effectif), 5L)
  testthat::expect_false(any(transition$annee_universitaire == "2025-2026"))
  matrix <- longitudinal_matrix(p$inscriptions, min_denominator = 1L)
  testthat::expect_equal(sum(matrix$effectif), 5L)
  testthat::expect_equal(sum(matrix$effectif[matrix$niveau_suivant == "absence_observee"]), 2L)
  testthat::expect_equal(p$inscriptions$attribution_diplome[p$inscriptions$id_etudiant == "D"], "oui")
  bad <- fixture$data
  bad$etat_transition[5] <- "sortie_observee"
  testthat::expect_error(prepare_longitudinal(bad, fixture$decisions), "incompatibles")
  testthat::expect_error(prepare_longitudinal(fixture$data, fixture$decisions[FALSE, ]), "incompletes")
})

testthat::test_that("le panel complet est reconstruit sans perte et sans modification", {
  source(here::here("R", "analysis", "descriptive.R"), local = TRUE)
  source(here::here("R", "analysis", "longitudinal.R"), local = TRUE)
  d <- test_dataset()
  x <- dplyr::left_join(d$inscriptions, d$resultats, by = "id_inscription", relationship = "one-to-one")
  x <- dplyr::left_join(x, d$parcours, by = c("id_inscription" = "id_inscription_depart"), relationship = "one-to-one")
  x$transition_observable <- x$annee_universitaire != "2025-2026"
  saved <- serialize(x, NULL)
  p <- prepare_longitudinal(x, d$decisions_diplome)
  testthat::expect_identical(serialize(x, NULL), saved)
  testthat::expect_equal(nrow(p$inscriptions), 31816L)
  testthat::expect_equal(nrow(p$premieres_observations), 15000L)
  testthat::expect_equal(dplyr::n_distinct(p$suivi_l1$id_etudiant), 8000L)
  testthat::expect_equal(nrow(p$suivi_l1), 18000L)
  testthat::expect_equal(sum(p$inscriptions$transition_observable), 21633L)
  testthat::expect_equal(sum(!p$inscriptions$transition_observable), 10183L)
  testthat::expect_equal(sum(longitudinal_matrix(p$inscriptions)$effectif), 21633L)
})
