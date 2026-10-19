testthat::test_that("les corrections documentees restaurent les tables sans imputation", {
  source(here::here("R", "quality", "check_quality.R"), local = TRUE)
  source(here::here("R", "data", "clean_data.R"), local = TRUE)
  base <- test_dataset()
  injected <- inject_quality_issues(base)
  snapshot <- injected
  result <- clean_data(injected$data, injected$issues)
  testthat::expect_identical(injected, snapshot)
  for (table in names(quality_schema())) {
    testthat::expect_identical(result$data[[table]], base[[table]], info = table)
  }
  testthat::expect_equal(nrow(result$journal), 50L)
  testthat::expect_equal(result$after$metadata$n_alertes, 0L)
  testthat::expect_identical(result$data$metadata$anomalies_injectees, TRUE)
  testthat::expect_error(clean_data(injected$data), "Preparation bloquee")
  incomplete <- injected$issues[-1L, ]
  testthat::expect_error(clean_data(injected$data, incomplete), "Preparation bloquee")
  stale <- injected$issues
  stale$valeur_injectee[1L] <- "invalide"
  testthat::expect_error(clean_data(injected$data, stale), "Journal obsolete")
  conflict <- injected$data
  row <- injected$issues$ligne[injected$issues$type == "doublon_cle"][1L]
  conflict$inscriptions$boursier[row] <- !isTRUE(conflict$inscriptions$boursier[row])
  testthat::expect_error(clean_data(conflict, injected$issues), "doublon non strictement")
})

testthat::test_that("preparation et stockage conservent les inconnus et les sources", {
  source(here::here("R", "quality", "check_quality.R"), local = TRUE)
  source(here::here("R", "data", "clean_data.R"), local = TRUE)
  base <- test_dataset()
  cleaned <- clean_data(base)
  prepared <- prepare_analytic_tables(cleaned$data)
  x <- prepared$scolarite_analytique
  testthat::expect_equal(nrow(x), nrow(base$inscriptions))
  testthat::expect_false(anyDuplicated(x$id_inscription) > 0L)
  testthat::expect_identical(is.na(x$cible_reussite), x$validation_annuelle == "inconnu")
  testthat::expect_identical(x$transition_observable, x$annee_universitaire != "2025-2026")
  for (table in names(quality_schema()))
    testthat::expect_identical(prepared[[table]], base[[table]])
  directory <- withr::local_tempdir()
  manifest <- save_processed_tables(prepared, list(journal = cleaned$journal), directory)
  testthat::expect_equal(nrow(manifest), 14L)
  testthat::expect_identical(readRDS(fs::path(directory, "scolarite_analytique.rds")), x)
  testthat::expect_equal(save_processed_tables(prepared, list(journal = cleaned$journal), directory), manifest)
  different <- prepared
  different$scolarite_analytique$cible_reussite[1L] <- NA
  different$metadata$test <- TRUE
  testthat::expect_error(save_processed_tables(different, list(journal = cleaned$journal), directory),
    "Ecrasement refuse")
  testthat::expect_identical(readRDS(fs::path(directory, "metadata.rds")), prepared$metadata)
})
