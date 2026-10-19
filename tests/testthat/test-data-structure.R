testthat::test_that("les dimensions respectent les personnes et les inscriptions", {
  d <- test_dataset()
  cfg <- d$metadata$config
  ins <- d$inscriptions
  testthat::expect_equal(nrow(d$etudiants), 15000L)
  testthat::expect_equal(nrow(d$formations), 5L)
  testthat::expect_setequal(unique(ins$annee_universitaire), cfg$annees)
  testthat::expect_true(nrow(ins) >= 15000L && nrow(ins) <= 45000L)
  testthat::expect_equal(nrow(ins), nrow(d$resultats))
  testthat::expect_equal(nrow(ins), nrow(d$parcours))
  testthat::expect_equal(nrow(ins), nrow(d$invitations_evaluation))
  testthat::expect_setequal(ins$id_etudiant, d$etudiants$id_etudiant)
  testthat::expect_equal(nrow(d$decisions_diplome), sum(ins$niveau %in% c("L3", "M2")))
  testthat::expect_equal(nrow(d$diplomes), sum(d$decisions_diplome$attribution_diplome == "oui"))
  first <- ins[!duplicated(ins$id_etudiant), ]
  testthat::expect_identical(as.integer(table(factor(first$annee_universitaire, cfg$annees))),
    unname(cfg$nouveaux_etudiants))
  baseline <- ins[ins$annee_universitaire == cfg$annees[1L], ]
  testthat::expect_identical(as.integer(table(factor(baseline$niveau, names(cfg$niveaux_initiaux)))),
    unname(cfg$niveaux_initiaux))
})

testthat::test_that("toutes les tables respectent les types du contrat", {
  expect_data_schema(test_dataset())
})

testthat::test_that("les cles primaires et les unites secondaires sont uniques", {
  d <- test_dataset()
  for (table in names(test_data_keys)) {
    key <- d[[table]][[test_data_keys[[table]]]]
    testthat::expect_false(anyNA(key), info = table)
    testthat::expect_true(all(nzchar(key)), info = table)
    testthat::expect_equal(anyDuplicated(key), 0L, info = table)
  }
  testthat::expect_equal(anyDuplicated(d$inscriptions[c("id_etudiant", "annee_universitaire")]), 0L)
  testthat::expect_equal(anyDuplicated(d$evaluations$id_invitation_evaluation), 0L)
  testthat::expect_equal(anyDuplicated(d$devenir_diplomes$id_invitation_devenir), 0L)
  testthat::expect_equal(anyDuplicated(d$diplomes$id_inscription), 0L)
})

testthat::test_that("les relations ne contiennent aucune reference orpheline", {
  d <- test_dataset()
  expect_foreign_key(d$inscriptions$id_etudiant, d$etudiants$id_etudiant)
  expect_foreign_key(d$inscriptions$id_formation, d$formations$id_formation)
  for (table in c("resultats", "decisions_diplome", "diplomes", "invitations_evaluation"))
    expect_foreign_key(d[[table]]$id_inscription, d$inscriptions$id_inscription)
  expect_foreign_key(d$parcours$id_inscription_depart, d$inscriptions$id_inscription)
  expect_foreign_key(d$parcours$id_inscription_suivante, d$inscriptions$id_inscription, TRUE)
  expect_foreign_key(d$evaluations$id_invitation_evaluation, d$invitations_evaluation$id_invitation_evaluation)
  expect_foreign_key(d$invitations_devenir$id_diplome, d$diplomes$id_diplome)
  expect_foreign_key(d$devenir_diplomes$id_invitation_devenir, d$invitations_devenir$id_invitation_devenir)
  testthat::expect_setequal(d$resultats$id_inscription, d$inscriptions$id_inscription)
  testthat::expect_setequal(d$parcours$id_inscription_depart, d$inscriptions$id_inscription)
  testthat::expect_setequal(d$invitations_evaluation$id_inscription, d$inscriptions$id_inscription)
})

testthat::test_that("les domaines et les motifs de valeurs manquantes sont explicites", {
  d <- test_dataset()
  cfg <- d$metadata$config
  testthat::expect_true(all(na.omit(d$etudiants$type_bac) %in% names(cfg$population$type_bac)))
  testthat::expect_true(all(d$etudiants$parcours_anterieur %in% names(cfg$population$parcours_anterieur)))
  testthat::expect_identical(is.na(d$etudiants$type_bac), !is.na(d$etudiants$motif_type_bac_manquant))
  testthat::expect_identical(is.na(d$inscriptions$boursier), !is.na(d$inscriptions$motif_boursier_manquant))
  testthat::expect_true(all(d$inscriptions$niveau %in% c("L1", "L2", "L3", "M1", "M2")))
  testthat::expect_true(all(d$inscriptions$statut_inscription %in% c("active", "annulee")))
  testthat::expect_true(all(d$resultats$validation_annuelle %in% c("oui", "non", "inconnu")))
  testthat::expect_true(all(na.omit(d$resultats$moyenne_annuelle) >= 0 & na.omit(d$resultats$moyenne_annuelle) <= 20))
  testthat::expect_true(all(na.omit(d$resultats$ects_acquis) %in% 0:60))
  testthat::expect_true(all(d$parcours$etat_transition %in% c("passage", "redoublement",
    "reorientation", "sortie_observee", "poursuite_intercycle", "autre", "non_observable")))
  testthat::expect_true(all(d$decisions_diplome$attribution_diplome %in% c("oui", "non", "inconnu")))
  testthat::expect_true(all(d$diplomes$type_diplome %in% c("licence", "master")))
  for (kind in c("evaluation", "devenir")) {
    testthat::expect_true(all(d[[paste0("invitations_", kind)]]$statut_reponse %in%
      c("aucune", "partielle", "complete")))
  }
  testthat::expect_true(all(na.omit(d$devenir_diplomes$situation_six_mois) %in%
    c("etudes", "emploi_hors_etudes", "recherche_emploi_hors_etudes", "autre_hors_etudes")))
})
