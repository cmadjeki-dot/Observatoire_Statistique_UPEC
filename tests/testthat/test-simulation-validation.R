testthat::test_that("une configuration invalide est rejetee avant generation", {
  cfg <- test_small_config()
  bad <- cfg
  bad$statut <- "proposition_a_valider"
  testthat::expect_error(generate_dataset(bad), "validee")
  bad <- cfg
  bad$n_etudiants <- bad$n_etudiants + 1L
  testthat::expect_error(generate_dataset(bad), "Volumes")
  bad <- cfg
  bad$population$type_bac[1] <- -0.5
  testthat::expect_error(generate_dataset(bad), "distribution")
  bad <- cfg
  bad$graines[2] <- bad$graines[1]
  testthat::expect_error(generate_dataset(bad), "graines")
  bad <- cfg
  names(bad$graines)[1] <- "inconnue"
  testthat::expect_error(generate_dataset(bad), "graines")
  bad <- cfg
  bad$transitions$non_validation <- c(teleportation = 1)
  testthat::expect_error(generate_dataset(bad), "transition")
  bad <- cfg
  bad$resultats$moyenne_si_validation <- c(min = 21, max = 25)
  testthat::expect_error(generate_dataset(bad), "resultat|moyenne")
})
