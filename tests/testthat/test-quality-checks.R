testthat::test_that("la base coherente passe sans transformer les NA attendus en erreurs", {
  source(here::here("R", "quality", "check_quality.R"), local = TRUE)
  d <- test_dataset()
  before <- serialize(d, NULL)
  report <- check_quality(d, "coherente")
  testthat::expect_identical(report$metadata$verdict, "conforme")
  testthat::expect_equal(nrow(report$details), 0L)
  testthat::expect_true(all(report$checks$statut == "conforme"))
  testthat::expect_true(sum(report$missing$n_manquants) > 0)
  testthat::expect_identical(serialize(d, NULL), before)
  testthat::expect_identical(report, check_quality(d, "coherente"))
})

testthat::test_that("chaque injection connue est reperee par sa regle cible et sa ligne", {
  source(here::here("R", "quality", "check_quality.R"), local = TRUE)
  d <- test_dataset()
  injected <- inject_quality_issues(d)
  report <- check_quality(injected$data, "anomalies")
  detection <- match_quality_injections(report, injected$issues)
  testthat::expect_identical(report$metadata$verdict, "non_conforme")
  testthat::expect_equal(nrow(detection), 50L)
  testthat::expect_true(all(detection$detectee))
  testthat::expect_true(all(detection$n_alertes_cible >= 1L))
  testthat::expect_gte(nrow(report$details), 50L)
  testthat::expect_true(all(c("regle", "table", "ligne", "cle", "champ", "valeur_observee", "severite") %in% names(report$details)))
  for (i in seq_len(nrow(detection))) {
    x <- detection[i, ]
    testthat::expect_true(any(report$details$regle == x$controle_attendu &
      report$details$table == x$table & report$details$ligne == x$ligne &
      report$details$champ == x$champ, na.rm = TRUE), info = x$id_anomalie)
  }
})

testthat::test_that("une colonne absente ou d'un mauvais type bloque les controles dependants", {
  source(here::here("R", "quality", "check_quality.R"), local = TRUE)
  d <- test_dataset()
  d$resultats$ects_acquis <- as.character(d$resultats$ects_acquis)
  d$evaluations$date_reponse <- NULL
  report <- check_quality(d)
  testthat::expect_identical(report$metadata$verdict, "non_conforme")
  testthat::expect_true(any(report$details$regle == "schema_colonne" & report$details$champ == "ects_acquis"))
  testthat::expect_true(any(report$details$regle == "schema_colonne" & report$details$champ == "date_reponse"))
  testthat::expect_true(any(report$checks$regle == "coherence_ects" & report$checks$statut == "non_execute"))
  d <- test_dataset()
  d$resultats <- NULL
  report <- check_quality(d)
  testthat::expect_true(any(report$details$regle == "schema_table" & report$details$table == "resultats"))
})

testthat::test_that("des incoherences non injectees initialement sont detectees", {
  source(here::here("R", "quality", "check_quality.R"), local = TRUE)
  d <- test_dataset()
  validated <- which(d$resultats$validation_annuelle == "oui")[1L]
  d$resultats$ects_acquis[validated] <- 30L
  unknown <- which(d$resultats$validation_annuelle == "inconnu")[1L]
  d$resultats$motif_resultat_inconnu[unknown] <- NA_character_
  d$inscriptions$annee_universitaire[1L] <- "annee_invalide"
  dip <- 1L
  d$diplomes$type_diplome[dip] <- if (d$diplomes$type_diplome[dip] == "licence") "master" else "licence"
  response <- 1L
  invitation <- match(d$evaluations$id_invitation_evaluation[response], d$invitations_evaluation$id_invitation_evaluation)
  d$evaluations$date_reponse[response] <- d$invitations_evaluation$date_cloture[invitation] + 1L
  d$invitations_devenir$date_cloture[1L] <- d$metadata$config$date_gel + 1L
  report <- check_quality(d)
  for (rule in c("coherence_ects", "coherence_manquant_motif", "domaine_categoriel",
                 "type_diplome_niveau", "chronologie_reponse", "eligibilite_devenir"))
    testthat::expect_true(rule %in% report$details$regle, info = rule)
})

testthat::test_that("les invitations manquantes ou multiples et les poids invalides sont reperes", {
  source(here::here("R", "quality", "check_quality.R"), local = TRUE)
  d <- test_dataset()
  d$formations$poids_dans_cycle[1L] <- -1
  duplicate <- d$invitations_evaluation[1L, ]
  duplicate$id_invitation_evaluation <- "INVITATION_SUPPLEMENTAIRE"
  d$invitations_evaluation <- rbind(d$invitations_evaluation, duplicate)
  d$invitations_devenir <- d$invitations_devenir[-1L, ]
  report <- check_quality(d)
  for (rule in c("poids_formation", "unicite_unite_metier", "exhaustivite_devenir"))
    testthat::expect_true(rule %in% report$details$regle, info = rule)
})

testthat::test_that("les tables vides gardent des controles executables et un rapport conforme", {
  source(here::here("R", "quality", "check_quality.R"), local = TRUE)
  cfg <- test_small_config()
  cfg$n_etudiants <- 25L
  cfg$nouveaux_etudiants[] <- c(25L, 0L, 0L)
  cfg$niveaux_initiaux[] <- c(25L, 0L, 0L, 0L, 0L)
  cfg$evaluation$probabilite_reponse_reference <- 0
  for (state in names(cfg$transitions)) {
    cfg$transitions[[state]][] <- 0
    cfg$transitions[[state]]["sortie_observee"] <- 1
  }
  report <- check_quality(generate_dataset(cfg))
  testthat::expect_identical(report$metadata$verdict, "conforme")
  testthat::expect_equal(nrow(report$details), 0L)
})

testthat::test_that("les cles obligatoires absentes comptent parmi les non comparaisons", {
  source(here::here("R", "quality", "check_quality.R"), local = TRUE)
  d <- test_dataset()
  d$resultats$id_inscription[1L] <- NA_character_
  report <- check_quality(d)
  check <- report$checks[report$checks$regle == "chronologie_resultat", ]
  testthat::expect_equal(check$n_non_evaluees, 1L)
  testthat::expect_equal(check$n_evaluees, nrow(d$resultats) - 1L)
  testthat::expect_identical(report$metadata$verdict, "non_conforme")
})
