testthat::test_that("les anomalies sont distinctes, reproductibles et tracees", {
  d <- test_dataset()
  original <- serialize(d, NULL)
  altered <- inject_quality_issues(d)
  testthat::expect_identical(inject_quality_issues(d), altered)
  testthat::expect_identical(serialize(d, NULL), original)
  testthat::expect_false(d$metadata$anomalies_injectees)
  testthat::expect_true(altered$data$metadata$anomalies_injectees)
  log <- altered$issues
  testthat::expect_equal(nrow(log), 50L)
  testthat::expect_setequal(log$type, d$metadata$config$anomalies$types)
  testthat::expect_true(all(table(log$type) == 10L))
  testthat::expect_equal(anyDuplicated(log$id_anomalie), 0L)
  testthat::expect_equal(anyDuplicated(log$cle), 0L)
  for (i in seq_len(nrow(log))) {
    row <- log[i, ]
    actual <- altered$data[[row$table]][[row$champ]][row$ligne]
    testthat::expect_identical(as.character(actual), row$valeur_injectee,
      info = row$id_anomalie)
    if (row$type != "doublon_cle") {
      before <- d[[row$table]][[row$champ]][row$ligne]
      testthat::expect_identical(as.character(before), row$valeur_initiale,
        info = row$id_anomalie)
    }
  }
})

testthat::test_that("les cinq types violent effectivement leur regle cible", {
  d <- test_dataset()
  injected <- inject_quality_issues(d, n_per_type = 2L)
  a <- injected$data
  log <- injected$issues
  testthat::expect_equal(nrow(log), 10L)
  testthat::expect_equal(nrow(a$inscriptions), nrow(d$inscriptions) + 2L)
  testthat::expect_equal(sum(duplicated(a$inscriptions$id_inscription)), 2L)
  testthat::expect_equal(sum(!a$inscriptions$id_etudiant %in% a$etudiants$id_etudiant), 2L)
  testthat::expect_equal(sum(a$resultats$moyenne_annuelle > 20, na.rm = TRUE), 2L)
  dates <- a$decisions_diplome$date_decision_diplome
  enrolled <- a$inscriptions$date_inscription[match(a$decisions_diplome$id_inscription, a$inscriptions$id_inscription)]
  testthat::expect_equal(sum(dates < enrolled, na.rm = TRUE), 2L)
  testthat::expect_equal(sum(a$parcours$id_inscription_depart == a$parcours$id_inscription_suivante, na.rm = TRUE), 2L)
  for (table in c("etudiants", "formations", "diplomes", "evaluations", "devenir_diplomes"))
    testthat::expect_identical(a[[table]], d[[table]], info = table)
})

testthat::test_that("l'injection refuse les entrees invalides et la double alteration", {
  d <- test_dataset()
  for (n in list(NA_real_, 0, -1, 1.5, Inf, "deux", c(1, 2)))
    testthat::expect_error(inject_quality_issues(d, n_per_type = n), "entier")
  for (seed in list(NA_real_, 0, -1, 1.5, Inf, "seed", c(1, 2)))
    testthat::expect_error(inject_quality_issues(d, seed = seed), "Graine")
  a <- inject_quality_issues(d, n_per_type = 1L)
  testthat::expect_error(inject_quality_issues(a$data), "non encore alteree")
  testthat::expect_error(inject_quality_issues(d, n_per_type = 1000000L), "trop petite")
})

testthat::test_that("un echec apres tirage laisse la base et le RNG intacts", {
  cfg <- test_small_config()
  cfg$resultats$probabilite_decision_inconnue <- 1
  d <- generate_dataset(cfg)
  original <- serialize(d, NULL)
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  seed_before <- if (had_seed) get(".Random.seed", envir = .GlobalEnv) else NULL
  kind_before <- RNGkind()
  testthat::expect_error(inject_quality_issues(d, n_per_type = 1L), "decisions de diplome")
  testthat::expect_identical(serialize(d, NULL), original)
  testthat::expect_identical(RNGkind(), kind_before)
  testthat::expect_identical(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE), had_seed)
  if (had_seed) testthat::expect_identical(get(".Random.seed", envir = .GlobalEnv), seed_before)
})
