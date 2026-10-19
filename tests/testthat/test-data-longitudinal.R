testthat::test_that("les decisions annuelles respectent dates, ECTS et inconnus", {
  d <- test_dataset()
  ins <- d$inscriptions[match(d$resultats$id_inscription, d$inscriptions$id_inscription), ]
  res <- d$resultats
  unknown <- res$validation_annuelle == "inconnu"
  valid <- res$validation_annuelle == "oui"
  failed <- res$validation_annuelle == "non"
  testthat::expect_identical(!is.na(res$motif_resultat_inconnu), unknown)
  testthat::expect_identical(is.na(res$date_decision), unknown)
  testthat::expect_identical(is.na(res$moyenne_annuelle), unknown)
  testthat::expect_identical(is.na(res$ects_acquis), unknown)
  testthat::expect_true(all(res$moyenne_annuelle[valid] >= 10))
  testthat::expect_true(all(res$ects_acquis[valid] == 60L))
  testthat::expect_true(all(res$moyenne_annuelle[failed] < 10))
  testthat::expect_true(all(res$ects_acquis[failed] < 60L))
  testthat::expect_true(all(res$date_decision[!unknown] >= ins$date_inscription[!unknown]))
  testthat::expect_true(all(res$date_decision[!unknown] <= d$metadata$config$date_gel))
  start_year <- as.integer(substr(ins$annee_universitaire, 1, 4))
  reference <- as.Date(paste0(start_year, "-10-31"))
  end <- as.Date(paste0(start_year + 1L, "-09-30"))
  testthat::expect_true(all(ins$date_inscription <= reference))
  testthat::expect_true(all(res$date_decision[!unknown] <= end[!unknown]))
})

testthat::test_that("les inscriptions et parcours suivent les niveaux et le calendrier", {
  d <- test_dataset()
  ins <- d$inscriptions
  p <- d$parcours
  from <- match(p$id_inscription_depart, ins$id_inscription)
  to <- match(p$id_inscription_suivante, ins$id_inscription)
  years <- match(ins$annee_universitaire, d$metadata$config$annees)
  cycle <- d$formations$cycle[match(ins$id_formation, d$formations$id_formation)]
  testthat::expect_identical(cycle == "licence", substr(ins$niveau, 1, 1) == "L")
  last <- years[from] == 3L
  testthat::expect_true(all(p$etat_transition[last] == "non_observable"))
  testthat::expect_true(all(is.na(to[last])))
  observable <- !last & !is.na(to)
  testthat::expect_true(all(years[to[observable]] == years[from[observable]] + 1L))
  testthat::expect_true(all(ins$id_etudiant[to[observable]] == ins$id_etudiant[from[observable]]))
  # Reconstruire l'existence d'une inscription suivante independamment du parcours.
  lookup <- paste(ins$id_etudiant, years)
  has_next <- paste(ins$id_etudiant[from], years[from] + 1L) %in% lookup
  testthat::expect_identical(p$etat_transition == "sortie_observee", !last & !has_next)
  testthat::expect_identical(is.na(to), last | !has_next)
  res <- d$resultats$validation_annuelle[match(p$id_inscription_depart, d$resultats$id_inscription)]
  for (state in c("passage", "redoublement", "reorientation", "poursuite_intercycle", "autre")) {
    rows <- which(p$etat_transition == state)
    testthat::expect_true(length(rows) > 0L, info = state)
    a <- from[rows]
    b <- to[rows]
    testthat::expect_false(anyNA(b), info = state)
    if (state == "passage") {
      testthat::expect_true(all(res[rows] == "oui"))
      testthat::expect_true(all(ins$id_formation[a] == ins$id_formation[b]))
      edges <- paste(ins$niveau[a], ins$niveau[b])
      testthat::expect_true(all(edges %in% c("L1 L2", "L2 L3", "M1 M2")))
    } else if (state == "redoublement") {
      testthat::expect_true(all(res[rows] == "non"))
      testthat::expect_true(all(ins$niveau[a] == ins$niveau[b]))
      testthat::expect_true(all(ins$id_formation[a] == ins$id_formation[b]))
    } else if (state == "reorientation") {
      testthat::expect_true(all(ins$id_formation[a] != ins$id_formation[b]))
      testthat::expect_true(all(ins$niveau[a] == ins$niveau[b]))
    } else if (state == "poursuite_intercycle") {
      testthat::expect_true(all(ins$niveau[a] == "L3" & ins$niveau[b] == "M1"))
      testthat::expect_true(all(res[rows] == "oui"))
    } else {
      testthat::expect_true(all(res[rows] == "inconnu"))
      testthat::expect_true(all(ins$niveau[a] == ins$niveau[b]))
    }
  }
})

testthat::test_that("les diplomes reposent sur une decision terminale valide", {
  d <- test_dataset()
  dd <- d$decisions_diplome
  ins <- d$inscriptions[match(dd$id_inscription, d$inscriptions$id_inscription), ]
  res <- d$resultats$validation_annuelle[match(dd$id_inscription, d$resultats$id_inscription)]
  testthat::expect_setequal(dd$id_inscription,
    d$inscriptions$id_inscription[d$inscriptions$niveau %in% c("L3", "M2")])
  unknown <- dd$attribution_diplome == "inconnu"
  testthat::expect_identical(is.na(dd$date_decision_diplome), unknown)
  testthat::expect_true(all(dd$date_decision_diplome[!unknown] >= ins$date_inscription[!unknown]))
  testthat::expect_true(all(dd$date_decision_diplome[!unknown] <= d$metadata$config$date_gel))
  attributed <- dd$attribution_diplome == "oui"
  testthat::expect_true(all(res[attributed] == "oui" & ins$prerequis_valides[attributed]))
  testthat::expect_setequal(d$diplomes$id_inscription, dd$id_inscription[attributed])
  row <- match(d$diplomes$id_inscription, dd$id_inscription)
  testthat::expect_identical(d$diplomes$date_diplome, dd$date_decision_diplome[row])
  testthat::expect_true(all(ins$niveau[row][d$diplomes$type_diplome == "licence"] == "L3"))
  testthat::expect_true(all(ins$niveau[row][d$diplomes$type_diplome == "master"] == "M2"))
})
