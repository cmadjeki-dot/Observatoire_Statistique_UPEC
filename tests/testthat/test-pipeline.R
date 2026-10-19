testthat::test_that("les ecritures du pipeline restent dans son espace de sorties", {
  source(here::here("R", "pipeline", "pipeline.R"), local = TRUE)
  testthat::expect_error(pipeline_output_directory("data/processed"), "Sortie reservee")
  testthat::expect_error(pipeline_output_directory("outputs/restitution"), "Sortie reservee")
  testthat::expect_error(pipeline_output_directory("outputs/pipeline/../../data"))
  testthat::expect_equal(pipeline_output_directory("outputs/pipeline"),
    as.character(output_path("pipeline")))
})

testthat::test_that("le catalogue ne peut modifier le gel ou abaisser la protection", {
  source(here::here("R", "analysis", "indicators.R"), local = TRUE)
  source(here::here("R", "pipeline", "pipeline.R"), local = TRUE)
  config <- dget(here::here("config", "simulation.R"))
  testthat::expect_silent(pipeline_read_config(here::here("config", "indicators.yml"),
    list(config = config)))
  config$date_gel <- as.Date("2026-08-30")
  testthat::expect_error(pipeline_read_config(here::here("config", "indicators.yml"),
    list(config = config)), "incompatible")
})
testthat::test_that("le chargement du graphe preserve les variables du lanceur", {
  withr::local_dir(here::here())
  env <- new.env(parent = globalenv())
  env$file <- "chemin_du_scenario_a_preserver"
  graph <- source(here::here("_targets.R"), local = env)$value
  testthat::expect_length(graph, 21L)
  testthat::expect_identical(env$file, "chemin_du_scenario_a_preserver")
  testthat::expect_false(exists(".pipeline_source_file", envir = env, inherits = FALSE))
})
