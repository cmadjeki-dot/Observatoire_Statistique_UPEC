testthat::test_that("les memes graines reproduisent exactement les onze tables", {
  d <- test_dataset()
  testthat::expect_identical(generate_dataset(), d)
  testthat::expect_identical(d$metadata$provenance, "entierement_synthetique_non_officiel")
  testthat::expect_false(d$metadata$donnees_personnelles_reelles)
  testthat::expect_false(d$metadata$anomalies_injectees)
  testthat::expect_false(any(c("nom", "prenom", "email", "effet_individuel", "bac_latent") %in%
    unlist(lapply(d[vapply(d, is.data.frame, logical(1))], names))))
})

testthat::test_that("changer une graine affecte son domaine sans changer la scolarite", {
  cfg <- test_small_config()
  a <- generate_dataset(cfg)
  cfg$graines["evaluations"] <- cfg$graines["evaluations"] + 100L
  b <- generate_dataset(cfg)
  for (table in c("etudiants", "formations", "inscriptions", "resultats", "parcours", "diplomes"))
    testthat::expect_identical(a[[table]], b[[table]], info = table)
  testthat::expect_false(identical(a$evaluations, b$evaluations))
})

testthat::test_that("la generation preserve le RNG appelant, meme sans graine initiale", {
  had_seed <- exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
  if (had_seed) original_seed <- get(".Random.seed", envir = .GlobalEnv)
  original_kind <- RNGkind()
  on.exit({
    do.call(RNGkind, as.list(original_kind))
    if (had_seed) assign(".Random.seed", original_seed, envir = .GlobalEnv)
    else if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
      rm(".Random.seed", envir = .GlobalEnv)
  }, add = TRUE)
  set.seed(731)
  seed_before <- get(".Random.seed", envir = .GlobalEnv)
  kind_before <- RNGkind()
  invisible(generate_dataset(test_small_config()))
  testthat::expect_identical(get(".Random.seed", envir = .GlobalEnv), seed_before)
  testthat::expect_identical(RNGkind(), kind_before)
  rm(".Random.seed", envir = .GlobalEnv)
  invisible(generate_dataset(test_small_config()))
  testthat::expect_false(exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
})

testthat::test_that("les periodes vides et zero reponse gardent le schema complet", {
  cfg <- test_small_config()
  cfg$n_etudiants <- 25L
  cfg$nouveaux_etudiants[] <- c(25L, 0L, 0L)
  cfg$niveaux_initiaux[] <- c(25L, 0L, 0L, 0L, 0L)
  cfg$evaluation$probabilite_reponse_reference <- 0
  cfg$devenir$probabilite_reponse <- 0
  for (state in names(cfg$transitions)) {
    cfg$transitions[[state]][] <- 0
    cfg$transitions[[state]]["sortie_observee"] <- 1
  }
  d <- generate_dataset(cfg)
  testthat::expect_equal(nrow(d$inscriptions), 25L)
  for (table in c("diplomes", "decisions_diplome", "evaluations", "invitations_devenir", "devenir_diplomes"))
    testthat::expect_equal(nrow(d[[table]]), 0L, info = table)
  expect_data_schema(d)
  testthat::expect_true(all(d$parcours$etat_transition == "sortie_observee"))
})

testthat::test_that("les resultats inconnus ne deviennent ni echecs ni diplomes", {
  cfg <- test_small_config()
  cfg$resultats$probabilite_decision_inconnue <- 1
  d <- generate_dataset(cfg)
  testthat::expect_true(all(d$resultats$validation_annuelle == "inconnu"))
  testthat::expect_true(all(is.na(d$resultats$moyenne_annuelle)))
  testthat::expect_true(all(is.na(d$resultats$ects_acquis)))
  testthat::expect_equal(nrow(d$diplomes), 0L)
  testthat::expect_false(any(d$parcours$etat_transition %in% c("passage", "redoublement", "poursuite_intercycle")))
  testthat::expect_identical(.sim_months(as.Date(c("2023-01-31", "2024-01-31")), 1L),
    as.Date(c("2023-02-28", "2024-02-29")))
})
