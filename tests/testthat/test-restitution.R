restitution_fixture <- function() {
  ids <- c("I02", "I03", "I06", "I07", "I08", "I05a", "I05c", "I09", "I09", "I10", "I10", "I11", "I11")
  k <- data.frame(id = ids, annee_universitaire = c(rep("2025-2026", 5), rep("2024-2025", 8)),
    type_diplome = c(rep("non_applicable", 7), rep(c("licence", "master"), 3)),
    valeur = c(10183, 66.63, 58.82, 59.99, 77.49, 39.42, 6.89, 61.28, 62.29, 64.22, 73.58, 60.53, 9.72),
    numerateur = c(10183, 6654, 5990, 3324, 2334, 4192, 733, 864, 545, 219, 362, 523, 53),
    denominateur = c(NA, 9987, 10183, 5541, 3012, 10633, 10633, 1410, 875, 341, 492, 864, 545),
    couverture_pct = 90, n_manquants = 0, statut = "diffusable")
  list(indicateurs = k, annexes = list(
    inscriptions = data.frame(annee_universitaire = "2025-2026", variation_effectif = -450, evolution_pct = -4.23),
    transitions = data.frame(annee_universitaire = "2024-2025", etat_transition = "redoublement", taux_pct = 20.55)),
    suivi = data.frame(cohorte_l1 = c("2024-2025", "2023-2024"), horizon = 1L,
      presence_pct = c(87.35, 87.30), n_presents = c(1747L, 3492L), n_cohorte_initiale = c(2000L, 4000L)),
    performances = data.frame(modele = c("GLM_test", "reference_constante_test"),
      auc = c(0.593, 0.5), brier = c(0.2164, 0.2218), n = 2081L))
}

testthat::test_that("les constats conservent millesimes, champs et valeurs non diffusables", {
  source(here::here("R", "analysis", "restitution.R"), local = TRUE)
  e <- restitution_fixture()
  original <- e
  findings <- build_restitution_findings(e)
  testthat::expect_identical(e, original)
  testthat::expect_equal(nrow(findings), 8L)
  testthat::expect_false(anyNA(findings))
  testthat::expect_true(all(nzchar(findings$recommandation)))
  testthat::expect_match(findings$resultat[findings$id == "C04"], "87,30.*3 492/4 000.*87,35")
  testthat::expect_match(findings$millesime[findings$id == "C03"], "2024-2025")
  testthat::expect_match(findings$resultat[findings$id == "C08"], "0,593")
  e$indicateurs$statut[e$indicateurs$id == "I03"] <- "effectif_insuffisant"
  testthat::expect_error(build_restitution_findings(e), "non diffusable")
  text <- format_restitution_markdown(findings)
  testthat::expect_match(text, "donnees", ignore.case = TRUE)
  testthat::expect_match(text, "Implication metier")
  testthat::expect_match(text, "Recommandation")
})

testthat::test_that("la preuve source modifiee bloque la restitution", {
  source(here::here("R", "analysis", "restitution.R"), local = TRUE)
  path <- "R/analysis/restitution.R"
  manifest <- data.frame(fichier = path, md5 = unname(tools::md5sum(here::here(path))))
  testthat::expect_true(.verify_restitution_sources(manifest))
  manifest$md5 <- "00000000000000000000000000000000"
  testthat::expect_error(.verify_restitution_sources(manifest), "modifiees")
  testthat::expect_error(.restitution_number(NA_real_), "bloque")
})
