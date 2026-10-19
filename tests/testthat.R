# Projet analytique : execution directe des tests, sans installation de package.
testthat::test_dir(
  here::here("tests", "testthat"),
  reporter = "summary",
  stop_on_failure = TRUE
)
