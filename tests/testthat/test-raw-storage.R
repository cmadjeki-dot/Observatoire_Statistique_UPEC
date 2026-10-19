testthat::test_that("la sauvegarde brute conserve exactement les objets et les types", {
  source(here::here("R", "data", "raw_storage.R"), local = TRUE)
  d <- test_dataset()
  a <- inject_quality_issues(d)
  directory <- withr::local_tempdir()
  manifest <- save_raw_dataset(d, a, directory)
  restored <- load_raw_dataset(directory)
  testthat::expect_identical(restored$dataset, d)
  testthat::expect_identical(restored$anomalies, a$data)
  testthat::expect_identical(restored$issues, a$issues)
  testthat::expect_equal(nrow(manifest), 3L)
  testthat::expect_true(all(file.exists(file.path(directory, manifest$fichier))))
  before <- file.info(file.path(directory, manifest$fichier))$mtime
  second <- save_raw_dataset(d, a, directory)
  testthat::expect_identical(second$md5, manifest$md5)
  testthat::expect_identical(file.info(file.path(directory, manifest$fichier))$mtime, before)
})

testthat::test_that("un objet different ne remplace jamais un fichier brut existant", {
  source(here::here("R", "data", "raw_storage.R"), local = TRUE)
  d <- test_dataset()
  a <- inject_quality_issues(d)
  directory <- withr::local_tempdir()
  save_raw_dataset(d, a, directory)
  paths <- list.files(directory, full.names = TRUE)
  before <- tools::md5sum(paths)
  modified <- d
  modified$etudiants$type_bac[1] <- "autre_valeur"
  testthat::expect_error(save_raw_dataset(modified, a, directory), "Ecrasement refuse")
  testthat::expect_identical(tools::md5sum(paths), before)
})

testthat::test_that("la relecture detecte un fichier corrompu ou manquant", {
  source(here::here("R", "data", "raw_storage.R"), local = TRUE)
  d <- test_dataset()
  a <- inject_quality_issues(d)
  directory <- withr::local_tempdir()
  save_raw_dataset(d, a, directory)
  writeLines("corruption de test", file.path(directory, "journal_anomalies.rds"))
  testthat::expect_error(load_raw_dataset(directory), "Integrite MD5")
  testthat::expect_error(load_raw_dataset(file.path(directory, "absent")), "Manifeste brut introuvable")
})
