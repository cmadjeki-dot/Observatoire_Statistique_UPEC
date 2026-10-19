testthat::test_that("les inventaires preservent les types et les manquants sans mutation", {
  source(here::here("R", "data", "describe_import.R"), local = TRUE)
  x <- list(exemple = data.frame(id = c("a", "b", "c"),
    bourse = c(TRUE, FALSE, NA), date = as.Date(c("2026-01-01", NA, "2026-01-03"))),
    metadata = list(provenance = "test"))
  original <- serialize(x, NULL)
  tables <- import_table_inventory(x)
  fields <- import_variable_inventory(x)
  testthat::expect_equal(tables$lignes, 3L)
  testthat::expect_equal(tables$colonnes, 3L)
  testthat::expect_equal(tables$cellules_manquantes, 2L)
  testthat::expect_identical(fields$type, c("character", "logical", "Date"))
  testthat::expect_equal(fields$manquants, c(0, 1, 1))
  testthat::expect_equal(fields$couverture_pct, c(100, 200/3, 200/3))
  testthat::expect_identical(serialize(x, NULL), original)
})

testthat::test_that("les distributions incluent les NA et appliquent le seuil de diffusion", {
  source(here::here("R", "data", "describe_import.R"), local = TRUE)
  x <- data.frame(bac = c("general", "general", NA_character_))
  freq <- import_modalities(x, "bac", min_denominator = 1L)
  testthat::expect_equal(sum(freq$effectif), 3L)
  testthat::expect_equal(sum(freq$pourcentage), 100)
  testthat::expect_equal(freq$effectif[freq$est_manquant], 1L)
  testthat::expect_true(all(freq$denominateur == 3L))
  testthat::expect_true(all(is.na(import_modalities(x, "bac")$pourcentage)))
  testthat::expect_equal(nrow(import_modalities(x[FALSE, , drop = FALSE], "bac")), 0L)
  testthat::expect_error(import_modalities(x, "absent"), "variables")
})

testthat::test_that("les decisions inconnues et absentes restent distinctes des echecs", {
  source(here::here("R", "data", "describe_import.R"), local = TRUE)
  ins <- data.frame(id_inscription = letters[1:5], annee_universitaire = rep("2025-2026", 5),
    statut_inscription = c(rep("active", 4), "annulee"))
  res <- data.frame(id_inscription = c("a", "b", "c", "e"),
    validation_annuelle = c("oui", "non", "inconnu", "oui"))
  original <- serialize(list(ins, res), NULL)
  summary <- import_validation_summary(ins, res, min_denominator = 1L)[1, ]
  testthat::expect_equal(summary$n_inscriptions, 4L)
  testthat::expect_equal(summary$n_validees, 1L)
  testthat::expect_equal(summary$n_non_validees, 1L)
  testthat::expect_equal(summary$n_inconnues, 2L)
  testthat::expect_equal(summary$n_sans_ligne_resultat, 1L)
  testthat::expect_equal(summary$taux_validation_connus_pct, 50)
  testthat::expect_equal(summary$couverture_pct, 50)
  testthat::expect_equal(summary$borne_basse_validation_pct, 25)
  testthat::expect_true(all(is.na(import_validation_summary(ins, res)$taux_validation_connus_pct)))
  testthat::expect_identical(serialize(list(ins, res), NULL), original)
  testthat::expect_error(import_validation_summary(ins, rbind(res, res[1, ])), "Cles uniques")
  zero <- import_validation_summary(ins[FALSE, ], res, min_denominator = 1L)
  testthat::expect_equal(zero$n_inscriptions, 0L)
  testthat::expect_true(is.na(zero$taux_validation_connus_pct))
})
