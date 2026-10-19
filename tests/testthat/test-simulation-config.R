testthat::test_that("les volumes et le referentiel couvrent le perimetre valide", {
  cfg <- dget(here::here("config", "simulation.R"))
  testthat::expect_identical(cfg$statut, "valide")
  testthat::expect_equal(sum(cfg$nouveaux_etudiants), cfg$n_etudiants)
  testthat::expect_equal(sum(cfg$niveaux_initiaux), unname(cfg$nouveaux_etudiants[1]))
  testthat::expect_identical(names(cfg$nouveaux_etudiants), cfg$annees)
  testthat::expect_setequal(names(cfg$niveaux_initiaux), c("L1","L2","L3","M1","M2"))
  testthat::expect_true(all(cfg$niveaux_initiaux > 0))
  testthat::expect_identical(cfg$niveau_nouveaux_apres_2023, "L1")
  testthat::expect_false(anyDuplicated(cfg$formations$id_formation) > 0L)
  testthat::expect_setequal(cfg$formations$cycle, c("licence", "master"))
  for (cycle in unique(cfg$formations$cycle)) {
    weights <- cfg$formations$poids_dans_cycle[cfg$formations$cycle == cycle]
    testthat::expect_true(length(weights) >= 2L)
    testthat::expect_true(all(weights > 0))
    testthat::expect_equal(sum(weights), 1)
  }
})

testthat::test_that("les distributions et les regles de resultat sont compatibles", {
  cfg <- dget(here::here("config", "simulation.R"))
  distributions <- c(list(cfg$population$type_bac, cfg$population$parcours_anterieur,
    cfg$evaluation$satisfaction, cfg$devenir$situation_licence,
    cfg$devenir$situation_master), cfg$transitions)
  for (p in distributions) {
    testthat::expect_true(all(is.finite(p) & p >= 0 & p <= 1))
    testthat::expect_equal(sum(p), 1)
  }
  numeric_parameters <- unlist(cfg[c("population", "resultats", "evaluation", "devenir")])
  probabilities <- numeric_parameters[grepl("probabilite", names(numeric_parameters), fixed = TRUE)]
  testthat::expect_true(all(is.finite(probabilities) & probabilities >= 0 & probabilities <= 1))
  testthat::expect_setequal(names(cfg$resultats$effet_logit_bac), names(cfg$population$type_bac))
  testthat::expect_setequal(names(cfg$resultats$probabilite_reference), names(cfg$niveaux_initiaux))
  testthat::expect_true(all(cfg$resultats$probabilite_reference > 0 & cfg$resultats$probabilite_reference < 1))
  testthat::expect_true(max(cfg$resultats$moyenne_si_non_validation) < min(cfg$resultats$moyenne_si_validation))
  testthat::expect_true(all(cfg$resultats$ects_si_non_validation < cfg$resultats$ects_si_validation))
  testthat::expect_setequal(names(cfg$evaluation$satisfaction), as.character(1:5))
  testthat::expect_setequal(names(cfg$devenir$situation_licence), names(cfg$devenir$situation_master))
  testthat::expect_equal(cfg$devenir$horizon_mois, 6L)
  testthat::expect_equal(cfg$devenir$cloture_mois, 7L)
  testthat::expect_equal(cfg$date_gel, as.Date("2026-09-30"))
  testthat::expect_equal(cfg$diffusion$seuil_minimum_taux, 10L)
})

testthat::test_that("la lecture des parametres ne realise aucun tirage", {
  seed_before <- if (exists(".Random.seed", envir = .GlobalEnv)) get(".Random.seed", envir = .GlobalEnv) else NULL
  cfg <- dget(here::here("config", "simulation.R"))
  seed_after <- if (exists(".Random.seed", envir = .GlobalEnv)) get(".Random.seed", envir = .GlobalEnv) else NULL
  testthat::expect_identical(seed_before, seed_after)
  testthat::expect_equal(length(unique(cfg$graines)), 6L)
  testthat::expect_true(all(cfg$graines > 0 & cfg$graines <= .Machine$integer.max))
  testthat::expect_equal(length(unique(cfg$anomalies$types)), 5L)
  testthat::expect_equal(cfg$anomalies$nombre_par_type, 10L)
})
