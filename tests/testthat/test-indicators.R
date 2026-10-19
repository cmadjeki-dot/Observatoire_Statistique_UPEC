testthat::test_that("le catalogue est borne, documente et refuse une definition incomplete", {
  source(here::here("R", "analysis", "indicators.R"), local = TRUE)
  cfg <- read_indicator_config()
  testthat::expect_length(cfg$indicateurs, 10L)
  testthat::expect_equal(cfg$seuil_minimum_taux, 10L)
  directory <- withr::local_tempdir()
  path <- fs::path(directory, "invalid.yml")
  cfg$indicateurs$I08$population <- NULL
  yaml::write_yaml(cfg, path)
  testthat::expect_error(read_indicator_config(path), "incomplete")
  cfg <- read_indicator_config()
  cfg$seuil_minimum_taux <- 0
  yaml::write_yaml(cfg, path)
  testthat::expect_error(read_indicator_config(path), "invalide")
})

testthat::test_that("les decisions de diplome ne sont pas remplacees par la validation annuelle", {
  source(here::here("R", "analysis", "indicators.R"), local = TRUE)
  ins <- data.frame(id_inscription = paste0("I", 1:5), annee_universitaire = "2023-2024",
    niveau = c("L1", "L3", "L3", "M2", "M2"),
    statut_inscription = c(rep("active", 4), "annulee"), validation_annuelle = "oui")
  decisions <- data.frame(id_inscription = paste0("I", 2:5),
    attribution_diplome = c("oui", "non", "inconnu", "oui"))
  result <- summarise_diploma_decisions(ins, decisions)
  testthat::expect_equal(result$n_terminaux, 3L)
  testthat::expect_equal(result$n_attribues, 1L)
  testthat::expect_equal(result$n_decisions_diplome_connues, 2L)
  testthat::expect_equal(result$n_inconnus, 1L)
  testthat::expect_error(summarise_diploma_decisions(ins, decisions[-1, ]), "manquante")
  cfg <- read_indicator_config()
  small <- .indicator_row(cfg, "I08", "2023-2024", population = 3, numerator = 1, denominator = 2)
  testthat::expect_true(is.na(small$valeur))
  testthat::expect_identical(small$statut, "effectif_insuffisant")
  zero <- .indicator_row(cfg, "I08", "2023-2024", population = 10, numerator = 0, denominator = 0)
  testthat::expect_true(is.na(zero$valeur))
  testthat::expect_identical(zero$statut, "denominateur_nul")
  testthat::expect_error(.indicator_row(cfg, "I08", "2023-2024", population = 10,
    numerator = 11, denominator = 10), "incoherent")
})

testthat::test_that("les dix series concordent avec leurs populations et respectent les censures", {
  source(here::here("R", "analysis", "descriptive.R"), local = TRUE)
  source(here::here("R", "quality", "check_quality.R"), local = TRUE)
  source(here::here("R", "surveys", "analyse_surveys.R"), local = TRUE)
  source(here::here("R", "analysis", "indicators.R"), local = TRUE)
  d <- test_dataset()
  x <- dplyr::left_join(d$inscriptions, d$resultats, by = "id_inscription", relationship = "one-to-one")
  x <- dplyr::left_join(x, d$parcours, by = c("id_inscription" = "id_inscription_depart"), relationship = "one-to-one")
  x$transition_observable <- x$annee_universitaire != "2025-2026"
  surveys <- prepare_survey_tables(d)
  result <- build_priority_indicators(x, surveys, d$decisions_diplome)
  kpi <- result$indicateurs
  testthat::expect_equal(nrow(kpi), 33L)
  testthat::expect_equal(length(unique(kpi$id)), 10L)
  testthat::expect_equal(sum(kpi$statut == "non_observable"), 2L)
  censored <- kpi[kpi$statut == "non_observable", ]
  testthat::expect_true(all(is.na(censored$valeur) & is.na(censored$numerateur) & is.na(censored$denominateur)))
  testthat::expect_equal(sum(kpi$numerateur[kpi$id == "I08"]), 6835L)
  testthat::expect_equal(sum(kpi$population_reference[kpi$id == "I08"]), 9091L)
  testthat::expect_equal(sum(kpi$numerateur[kpi$id == "I09"]), 2758L)
  testthat::expect_equal(sum(kpi$denominateur[kpi$id == "I10"]), 1573L)
  testthat::expect_equal(sum(kpi$numerateur[kpi$id == "I11"]), 1185L)
  testthat::expect_false(any(kpi$annee_universitaire[kpi$famille == "devenir"] == "2025-2026"))
  testthat::expect_true(all(kpi$valeur[kpi$unite == "pourcentage"] >= 0 &
    kpi$valeur[kpi$unite == "pourcentage"] <= 100, na.rm = TRUE))
  testthat::expect_equal(kpi$valeur[kpi$id == "I03"], result$annexes$reussite$taux_validation_connus_pct)
  testthat::expect_equal(kpi$valeur[kpi$id == "I07"], result$annexes$evaluation$satisfaction_favorable_pct)
})
