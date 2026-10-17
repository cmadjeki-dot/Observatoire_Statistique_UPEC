testthat::test_that("les chemins suivent la racine du projet depuis un sous-dossier", {
  root <- here::here()
  previous <- setwd(file.path(root, "notebooks"))
  on.exit(setwd(previous), add = TRUE)
  testthat::expect_equal(as.character(project_path()), as.character(fs::path_norm(root)))
  for (stage in c("raw", "interim", "processed")) {
    testthat::expect_equal(
      as.character(data_path(stage, "etudiants.csv")),
      as.character(fs::path(root, "data", stage, "etudiants.csv"))
    )
  }
  testthat::expect_equal(
    as.character(output_path("figures", "reussite.png")),
    as.character(fs::path(root, "outputs", "figures", "reussite.png"))
  )
  testthat::expect_equal(project_path("data\\raw"), project_path("data/raw"))
})

testthat::test_that("les chemins absolus et les remontees sont refuses", {
  invalid <- c("C:/externe", "D:\\externe", "C:relatif", "/tmp/externe",
               "\\\\serveur\\partage", "~/secret", "..", "data/../../externe",
               "data\\..\\externe")
  for (value in invalid) {
    testthat::expect_error(project_path(value))
    testthat::expect_error(data_path("raw", value))
    testthat::expect_error(output_path(value))
  }
  testthat::expect_error(data_path("inconnu"))
  for (value in list(NA_character_, "", "  ", 1, c("a", "b"), NULL)) {
    testthat::expect_error(project_path(value), "chaine non vide unique")
  }
})
