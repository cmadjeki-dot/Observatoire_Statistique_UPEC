testthat::test_that("l'audit causal reste descriptif et distingue support et identification", {
  source(here::here("R", "analysis", "causal_feasibility.R"), local = TRUE)
  x <- data.frame(id_inscription = c("I1", "I2", "I3"), id_etudiant = c("A", "A", "B"),
    annee_universitaire = c("2023-2024", "2024-2025", "2023-2024"),
    statut_inscription = "active", niveau = c("L1", "L2", "M1"),
    id_formation = c("FL_A", "FL_A", "FM_A"), validation_annuelle = c("oui", "oui", "inconnu"),
    boursier = c(TRUE, TRUE, NA))
  original <- x
  a <- audit_causal_feasibility(x)
  testthat::expect_identical(x, original)
  testthat::expect_equal(a$disponibilite$effectif, c(3L, 2L, 2L, 1L, 1L, 1L))
  testthat::expect_equal(nrow(a$support_formation_niveau), 25L)
  testthat::expect_equal(sum(a$support_formation_niveau$effectif), 2L)
  testthat::expect_true(all(a$support_formation_niveau$effectif[a$support_formation_niveau$hors_cycle] == 0L))
  testthat::expect_equal(a$inventaire$n_manquants[a$inventaire$variable == "boursier"], 1L)
  testthat::expect_error(audit_causal_feasibility(rbind(x, x[1L, ])), "invalide")
  testthat::expect_error(audit_causal_feasibility(x[-1L]), "invalide")
  testthat::expect_identical(names(a), c("inventaire", "disponibilite", "support_formation_niveau"))
})
