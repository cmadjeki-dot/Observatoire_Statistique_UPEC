testthat::test_that("le lecteur refuse les echecs et les produits alteres", {
  source(here::here("R", "pipeline", "pipeline.R"), local = TRUE)
  source(here::here("R", "pipeline", "report.R"), local = TRUE)
  directory <- withr::local_tempdir(pattern = "pipeline_test_", tmpdir = here::here("outputs"))
  relative <- as.character(fs::path_rel(directory, here::here()))
  products <- c("resultats.rds", "modele_reussite.rds", "indicateurs.csv", "constats.csv",
    "synthese_pilotage.md", "sources.csv")
  paths <- fs::path(directory, products)
  saveRDS(list(qualite = list(metadata = list(verdict = "conforme"))), paths[1L])
  for (i in 2:5) writeLines("fixture", paths[i])
  file <- "config/simulation.R"
  utils::write.csv(data.frame(fichier = file, md5 = unname(tools::md5sum(here::here(file)))),
    paths[6L], row.names = FALSE)
  utils::write.csv(data.frame(fichier = products, md5 = unname(tools::md5sum(paths))),
    fs::path(directory, "produits.csv"), row.names = FALSE)
  status <- function(value) utils::write.csv(data.frame(statut = value),
    fs::path(directory, "statut.csv"), row.names = FALSE)
  status("echec")
  testthat::expect_error(load_pipeline_report(relative), "non courants")
  testthat::expect_error(load_pipeline_report(relative, rendering = TRUE), "non courants")
  status("en_cours")
  testthat::expect_error(load_pipeline_report(relative), "non courants")
  testthat::expect_silent(load_pipeline_report(relative, rendering = TRUE))
  status("succes")
  testthat::expect_silent(load_pipeline_report(relative))
  writeLines("modification", paths[3L])
  testthat::expect_error(load_pipeline_report(relative), "Integrite")
})
