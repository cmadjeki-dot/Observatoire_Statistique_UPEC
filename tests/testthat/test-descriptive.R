descriptive_fixture <- function() {
  n <- c(12L, 10L, 5L)
  data.frame(id_inscription = paste0("I", seq_len(sum(n))),
    id_etudiant = paste0("E", unlist(lapply(n, seq_len))),
    annee_universitaire = rep(c("2023-2024", "2024-2025", "2025-2026"), n),
    statut_inscription = "active",
    validation_annuelle = c(rep("oui", 6), rep("non", 3), rep("inconnu", 13), rep("oui", 5)),
    etat_transition = c(rep("passage", 6), rep("redoublement", 3),
      rep("sortie_observee", 13), rep("non_observable", 5)),
    transition_observable = rep(c(TRUE, TRUE, FALSE), n),
    type_bac = c(NA_character_, rep("general", sum(n) - 1L)),
    niveau = "L1", stringsAsFactors = FALSE)
}

testthat::test_that("les denominateurs, inconnus et seuils suivent I01-I04", {
  source(here::here("R", "analysis", "descriptive.R"), local = TRUE)
  x <- descriptive_fixture()
  enrolments <- describe_enrolments(x)
  testthat::expect_equal(enrolments$panel$n_etudiants, 12L)
  testthat::expect_equal(enrolments$panel$n_inscriptions, 27L)
  testthat::expect_equal(enrolments$annuel$evolution_pct, c(NA, -100 / 6, -50))
  success <- describe_success(x)
  testthat::expect_equal(success$n_decisions_connues, c(9L, 0L, 5L))
  testthat::expect_true(all(is.na(success$taux_validation_connus_pct)))
  testthat::expect_equal(success$borne_basse_validation_pct, c(50, 0, NA))
  unmasked <- describe_success(x, min_denominator = 1L)
  testthat::expect_equal(unmasked$taux_validation_connus_pct, c(200 / 3, NA, 100))
  testthat::expect_equal(unmasked$couverture_pct, c(75, 0, 100))
  characteristics <- describe_characteristics(x, "type_bac")
  missing <- characteristics[characteristics$est_manquant, ]
  testthat::expect_equal(missing$effectif, 1L)
  testthat::expect_equal(missing$denominateur, 12L)
  testthat::expect_equal(missing$pourcentage, 100 / 12)
  x$statut_inscription[1] <- "annulee"
  testthat::expect_equal(describe_enrolments(x)$panel$n_inscriptions, 26L)
  testthat::expect_error(describe_success(rbind(x, x[2, ])), "cles")
  testthat::expect_error(describe_success(x, min_denominator = 0L), "Seuil")
})

testthat::test_that("les sorties restent au denominateur et la derniere annee est exclue", {
  source(here::here("R", "analysis", "descriptive.R"), local = TRUE)
  x <- descriptive_fixture()
  out <- describe_transitions(x)
  testthat::expect_equal(nrow(out), 12L)
  testthat::expect_setequal(out$annee_universitaire, c("2023-2024", "2024-2025"))
  testthat::expect_equal(out$taux_pct[out$annee_universitaire == "2023-2024"], c(50, 25, 0, 25, 0, 0))
  testthat::expect_equal(as.numeric(tapply(out$taux_pct, out$annee_universitaire, sum)), c(100, 100))
  testthat::expect_equal(sum(out$effectif), 22L)
  testthat::expect_true(all(is.na(describe_transitions(x, min_denominator = 15L)$taux_pct)))
  testthat::expect_error(describe_transitions(x, groups = "niveau"), "Annee")
})

testthat::test_that("une source analytique alteree est refusee avant analyse", {
  source(here::here("R", "analysis", "descriptive.R"), local = TRUE)
  directory <- withr::local_tempdir()
  objects <- list(scolarite_analytique = descriptive_fixture(),
    metadata = list(provenance = "entierement_synthetique_non_officiel"))
  paths <- fs::path(directory, paste0(names(objects), ".rds"))
  for (i in seq_along(objects)) saveRDS(objects[[i]], paths[i])
  manifest <- data.frame(objet = names(objects), fichier = basename(paths),
    md5 = unname(tools::md5sum(paths)), octets = as.numeric(file.info(paths)$size))
  utils::write.csv(manifest, fs::path(directory, "manifest_preparation.csv"), row.names = FALSE)
  testthat::expect_identical(load_descriptive_source(directory)$data, objects$scolarite_analytique)
  saveRDS("alteration", paths[1L])
  testthat::expect_error(load_descriptive_source(directory), "Integrite")
  manifest$fichier[1L] <- "../externe.rds"
  utils::write.csv(manifest, fs::path(directory, "manifest_preparation.csv"), row.names = FALSE)
  testthat::expect_error(load_descriptive_source(directory), "Fichiers")
})
