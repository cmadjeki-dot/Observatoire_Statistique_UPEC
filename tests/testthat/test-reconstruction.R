testthat::test_that("la reconstruction utilise les graines et restaure les tables", {
  withr::local_dir(here::here())
  env <- new.env(parent = globalenv())
  graph <- withr::with_envvar(c(UPEC_PIPELINE_REBUILD = "true"),
    source(here::here("_targets.R"), local = env)$value)
  testthat::expect_length(graph, 27L)
  generated <- env$generate_dataset(test_small_config())
  injected <- env$inject_quality_issues(generated, n_per_type = 1L)
  cleaned <- env$pipeline_clean_reconstruction(generated, injected)
  testthat::expect_true(all(cleaned$detection$detectee))
  testthat::expect_identical(cleaned$data[names(env$quality_schema())],
    generated[names(env$quality_schema())])
  prepared <- env$pipeline_prepare_reconstruction(cleaned)
  testthat::expect_identical(nrow(prepared$scolarite_analytique), nrow(generated$inscriptions))
  testthat::expect_identical(prepared$pipeline_quality$metadata$verdict, "conforme")
  injected$issues$valeur_injectee[1L] <- "journal_perime"
  testthat::expect_error(env$pipeline_clean_reconstruction(generated, injected), "obsolete")
})
