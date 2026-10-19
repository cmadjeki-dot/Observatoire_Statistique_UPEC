survey_fixture <- function() {
  data.frame(annee_universitaire = "2023-2024", a_repondu = c(rep(TRUE, 10), rep(FALSE, 10)),
    statut_reponse = c(rep("complete", 10), rep("aucune", 10)),
    etat_global = c(rep("valide", 8), "non_concerne", "non_reponse_item", rep("non_reponse_vague", 10)),
    satisfaction_globale = c(1L, 2L, 3L, 3L, 4L, 4L, 5L, 5L, rep(NA_integer_, 12)),
    boursier = c(rep(TRUE, 10), rep(FALSE, 10)))
}

testthat::test_that("participation, satisfaction et distributions ont leurs propres denominateurs", {
  source(here::here("R", "surveys", "analyse_surveys.R"), local = TRUE)
  x <- survey_fixture()
  a <- summarise_evaluation(x, min_denominator = 1L)
  testthat::expect_equal(a$n_invites, 20L)
  testthat::expect_equal(a$n_repondants, 10L)
  testthat::expect_equal(a$n_valides_global, 8L)
  testthat::expect_equal(a$taux_reponse_pct, 50)
  testthat::expect_equal(a$couverture_item_pct, 40)
  testthat::expect_equal(a$satisfaction_favorable_pct, 50)
  testthat::expect_true(is.na(summarise_evaluation(x)$satisfaction_favorable_pct))
  testthat::expect_equal(a$n_non_reponse_vague + a$n_non_reponse_item + a$n_non_concerne, 12L)
  distribution <- evaluation_distribution(x, min_denominator = 1L)
  testthat::expect_equal(nrow(distribution), 8L)
  testthat::expect_equal(sum(distribution$effectif), 20L)
  testthat::expect_equal(sum(distribution$part_invites_pct), 100)
  testthat::expect_equal(sum(distribution$part_valides_pct, na.rm = TRUE), 100)
  testthat::expect_equal(nrow(evaluation_distribution(x, groups = character())), 8L)
  composition <- survey_nonresponse(x, variables = "boursier")
  testthat::expect_equal(composition$ecart_composition_points[composition$modalite == "TRUE"], 50)
  testthat::expect_equal(composition$taux_reponse_modalite_pct[composition$modalite == "FALSE"], 0)
  testthat::expect_error(summarise_evaluation(x, min_denominator = 0), "Seuil")
})

testthat::test_that("devenir distingue situations connues, etudes et non reponse", {
  source(here::here("R", "surveys", "analyse_surveys.R"), local = TRUE)
  x <- data.frame(annee_universitaire = "2023-2024", type_diplome = "licence",
    a_repondu = c(TRUE, TRUE, TRUE, TRUE, FALSE), situation_connue = c(TRUE, TRUE, TRUE, FALSE, FALSE),
    situation_six_mois = c("etudes", "emploi_hors_etudes", "autre_hors_etudes", NA, NA),
    emploi_pendant_etudes = c(TRUE, NA, NA, NA, NA),
    motif_situation_manquante = c(NA, NA, NA, "ne_sait_pas", NA))
  a <- summarise_graduate_survey(x, min_denominator = 1L)
  testthat::expect_equal(a$taux_questionnaires_pct, 80)
  testthat::expect_equal(a$taux_reponse_situation_pct, 60)
  testthat::expect_equal(a$emploi_parmi_hors_etudes_pct, 50)
  testthat::expect_equal(a$poursuite_etudes_pct, 100 / 3)
  testthat::expect_equal(a$n_ne_sait_pas, 1L)
  testthat::expect_equal(a$n_non_reponse_vague, 1L)
  testthat::expect_equal(a$emploi_pendant_etudes_pct, 100)
  testthat::expect_true(is.na(summarise_graduate_survey(x)$emploi_parmi_hors_etudes_pct))
  x$situation_six_mois[] <- NA
  x$situation_connue[] <- FALSE
  testthat::expect_true(is.na(summarise_graduate_survey(x, min_denominator = 1L)$poursuite_etudes_pct))
})

testthat::test_that("les univers controles preservent cles, invites et diplomes non observables", {
  source(here::here("R", "quality", "check_quality.R"), local = TRUE)
  source(here::here("R", "surveys", "analyse_surveys.R"), local = TRUE)
  base <- test_dataset()
  before <- serialize(base, NULL)
  tables <- prepare_survey_tables(base)
  testthat::expect_identical(serialize(base, NULL), before)
  testthat::expect_equal(nrow(tables$evaluation), 31816L)
  testthat::expect_equal(sum(tables$evaluation$a_repondu), nrow(base$evaluations))
  testthat::expect_equal(sum(tables$devenir$a_repondu), nrow(base$devenir_diplomes))
  testthat::expect_equal(anyDuplicated(tables$devenir$id_etudiant), 0L)
  testthat::expect_true(all(tables$devenir$date_cloture <= base$metadata$config$date_gel))
  testthat::expect_equal(sum(tables$eligibilite_diplomes$statut_eligibilite == "invite_reference"), 4501L)
  testthat::expect_false(any(tables$devenir$annee_universitaire == "2025-2026"))
  correlations <- survey_item_relations(tables$evaluation)
  testthat::expect_equal(nrow(correlations), 9L)
  testthat::expect_true(all(abs(correlations$rho_spearman) <= 1))
  testthat::expect_true(all(correlations$n_paires_valides >= 10L))
  bad <- base
  bad$evaluations <- rbind(bad$evaluations, bad$evaluations[1, ])
  testthat::expect_error(prepare_survey_tables(bad), "non conformes")
})
