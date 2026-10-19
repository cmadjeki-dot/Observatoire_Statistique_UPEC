testthat::test_that("les cinq vues preservent les NA et les populations", {
  source(here::here("R", "dashboard", "dashboard.R"), local = TRUE)
  k <- data.frame(id = c("I02", "I05a", "I09", "I09"),
    annee_universitaire = c("2025-2026", "2025-2026", "2024-2025", "2024-2025"),
    type_diplome = c("non_applicable", "non_applicable", "L", "M"),
    valeur = c(100, NA, 60, 70))
  testthat::expect_length(dashboard_pages(), 5L)
  testthat::expect_identical(anyDuplicated(unlist(dashboard_pages())), 0L)
  testthat::expect_true(is.na(dashboard_filter(k, "parcours", "2025-2026")$valeur))
  testthat::expect_equal(nrow(dashboard_filter(k, "insertion", "2024-2025", "L")), 1L)
  testthat::expect_equal(nrow(dashboard_filter(k, "inscriptions", "2025-2026", "L")), 1L)
  testthat::expect_equal(nrow(dashboard_filter(k, "insertion", "2025-2026")), 0L)
  testthat::expect_error(dashboard_filter(k, "inconnue"), "inconnue")
})

testthat::test_that("le serveur actualise les filtres et retire les donnees apres un echec", {
  source(here::here("R", "dashboard", "dashboard.R"), local = TRUE)
  k <- data.frame(id = c("I02", "I05a", "I09", "I09"), libelle = c("Inscrits", "Passage", "Reponse", "Reponse"),
    annee_universitaire = c("2025-2026", "2025-2026", "2024-2025", "2024-2025"),
    type_diplome = c("non_applicable", "non_applicable", "L", "M"),
    numerateur = c(100, NA, 6, 7), denominateur = c(NA, NA, 10, 10),
    couverture_pct = c(NA, NA, 60, 70), valeur = c(100, NA, 60, 70),
    unite = c("effectif", "pourcentage", "pourcentage", "pourcentage"),
    statut = c("diffusable", "non_observable", "diffusable", "diffusable"))
  control <- new.env(); control$fail <- FALSE
  loader <- function() {
    if (control$fail) stop("source alteree")
    list(resultats = list(indicateurs = list(indicateurs = k)))
  }
  shiny::testServer(dashboard_server(loader), {
    session$setInputs(page = "parcours", year = "2025-2026", diploma = "Tous", refresh = 0)
    testthat::expect_true(is.na(filtered()$valeur))
    session$setInputs(page = "insertion", year = "2024-2025", diploma = "L")
    testthat::expect_equal(filtered()$valeur, 60)
    control$fail <- TRUE
    session$setInputs(refresh = 1)
    testthat::expect_error(filtered(), "Actualisation refusee")
    testthat::expect_null(state())
  })
})
