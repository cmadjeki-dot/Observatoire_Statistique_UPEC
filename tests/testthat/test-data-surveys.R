testthat::test_that("les invitations et reponses respectent leur fenetre et leur cardinalite", {
  d <- test_dataset()
  for (kind in c("evaluation", "devenir")) {
    inv <- d[[paste0("invitations_", kind)]]
    response <- d[[if (kind == "evaluation") "evaluations" else "devenir_diplomes"]]
    key <- paste0("id_invitation_", kind)
    row <- match(response[[key]], inv[[key]])
    testthat::expect_false(anyNA(row))
    testthat::expect_equal(anyDuplicated(response[[key]]), 0L)
    testthat::expect_true(all(inv$date_ouverture <= inv$date_cloture))
    testthat::expect_true(all(response$date_reponse >= inv$date_ouverture[row]))
    testthat::expect_true(all(response$date_reponse <= inv$date_cloture[row]))
    testthat::expect_setequal(inv[[key]][inv$statut_reponse != "aucune"], response[[key]])
    testthat::expect_gt(sum(inv$statut_reponse == "aucune"), 0L)
  }
})

testthat::test_that("la satisfaction distingue modalites, non concerne et non reponse", {
  d <- test_dataset()
  response <- d$evaluations
  inv <- d$invitations_evaluation
  answered <- integer(nrow(response))
  for (item in c("globale", "contenus", "accompagnement")) {
    value <- response[[paste0("satisfaction_", item)]]
    reason <- response[[paste0("motif_satisfaction_", item)]]
    testthat::expect_true(all(na.omit(value) %in% 1:5))
    testthat::expect_identical(is.na(value), !is.na(reason))
    testthat::expect_true(all(na.omit(reason) %in% c("non_reponse_item", "non_concerne")))
    testthat::expect_gt(sum(reason == "non_concerne", na.rm = TRUE), 0L)
    testthat::expect_gt(sum(reason == "non_reponse_item", na.rm = TRUE), 0L)
    answered <- answered + as.integer(!is.na(value) | (!is.na(reason) & reason == "non_concerne"))
  }
  row <- match(response$id_invitation_evaluation, inv$id_invitation_evaluation)
  testthat::expect_true(all(answered > 0L))
  testthat::expect_identical(inv$statut_reponse[row] == "complete", answered == 3L)
  testthat::expect_identical(inv$statut_reponse[row] == "partielle", answered %in% 1:2)
})

testthat::test_that("seuls les derniers diplomes matures par personne sont invites", {
  d <- test_dataset()
  dip <- d$diplomes
  inv <- d$invitations_devenir
  person <- d$inscriptions$id_etudiant[match(dip$id_inscription, d$inscriptions$id_inscription)]
  # Tous les diplomes du modele sont dates du 30 septembre : six et sept mois
  # donnent respectivement le 30 mars et le 30 avril de l'annee suivante.
  y <- as.integer(format(dip$date_diplome, "%Y")) + 1L
  opening <- as.Date(paste0(y, "-03-30"))
  closing <- as.Date(paste0(y, "-04-30"))
  mature <- closing <= d$metadata$config$date_gel
  selected <- match(inv$id_diplome, dip$id_diplome)
  testthat::expect_true(all(mature[selected]))
  testthat::expect_identical(inv$date_reference, opening[selected])
  testthat::expect_identical(inv$date_ouverture, opening[selected])
  testthat::expect_identical(inv$date_cloture, closing[selected])
  testthat::expect_equal(anyDuplicated(person[selected]), 0L)
  testthat::expect_setequal(person[selected], person[mature])
  latest <- tapply(as.numeric(dip$date_diplome[mature]), person[mature], max)
  testthat::expect_equal(as.numeric(dip$date_diplome[selected]), as.numeric(latest[person[selected]]))
  testthat::expect_false(any(inv$id_diplome %in% dip$id_diplome[!mature]))
  testthat::expect_true(all(inv$date_cloture <= d$metadata$config$date_gel))
})

testthat::test_that("le devenir distingue etudes, emploi et situation inconnue", {
  d <- test_dataset()
  response <- d$devenir_diplomes
  inv <- d$invitations_devenir
  missing <- is.na(response$situation_six_mois)
  studies <- !missing & response$situation_six_mois == "etudes"
  testthat::expect_identical(!is.na(response$motif_situation_manquante), missing)
  testthat::expect_true(all(response$motif_situation_manquante[missing] == "non_reponse_item"))
  testthat::expect_true(all(is.na(response$emploi_pendant_etudes[!studies])))
  testthat::expect_true(all(response$motif_emploi_pendant_etudes_manquant[!studies] == "non_applicable"))
  testthat::expect_true(all(is.na(response$motif_emploi_pendant_etudes_manquant[studies])))
  testthat::expect_false(anyNA(response$emploi_pendant_etudes[studies]))
  row <- match(response$id_invitation_devenir, inv$id_invitation_devenir)
  testthat::expect_identical(inv$statut_reponse[row] == "complete", !missing)
  testthat::expect_identical(inv$statut_reponse[row] == "partielle", missing)
})
