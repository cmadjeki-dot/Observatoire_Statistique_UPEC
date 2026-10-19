# Etape 19 : diagnostic de faisabilite uniquement, aucun modele estime.
source(here::here("R", "analysis", "descriptive.R"))
stopifnot(isTRUE(renv::status()$synchronized))
paths <- fs::dir_ls(here::here("data", "processed"), type = "file", all = TRUE)
before <- tools::md5sum(paths)
input <- load_descriptive_source()
x <- input$data
x <- x[x$statut_inscription == "active", ]
stopifnot(!anyDuplicated(x$id_inscription), !anyNA(x$id_etudiant))
ordered <- x[order(x$annee_universitaire, x$id_etudiant), ]
first <- ordered[!duplicated(ordered$id_etudiant), ]
x$premiere_annee_observee <- first$annee_universitaire[match(x$id_etudiant, first$id_etudiant)]
baseline <- x[x$annee_universitaire == input$metadata$config$annees[1L], ]
covariates <- c("niveau", "id_formation", "type_bac", "parcours_anterieur", "boursier")
known <- baseline[baseline$validation_annuelle != "inconnu", ]
complete <- known[stats::complete.cases(known[covariates]), ]
complete$formation_licence_B <- as.integer(complete$id_formation == "FL_B")
complete$formation_licence_C <- as.integer(complete$id_formation == "FL_C")
complete$formation_master_B <- as.integer(complete$id_formation == "FM_B")
naive <- stats::model.matrix(~ niveau + id_formation + type_bac + parcours_anterieur + boursier, complete)
nested <- stats::model.matrix(~ niveau + formation_licence_B + formation_licence_C +
  formation_master_B + type_bac + parcours_anterieur + boursier, complete)
ranks <- data.frame(specification = c("niveau_plus_formation_naif", "contrastes_formation_dans_cycle"),
  colonnes = c(ncol(naive), ncol(nested)), rang = c(qr(naive)$rank, qr(nested)$rank))
flow <- data.frame(population = c("panel_inscriptions", "panel_etudiants_distincts", "baseline_inscriptions",
  "baseline_resultat_connu", "baseline_cas_complets", "baseline_cas_complets_oui", "baseline_cas_complets_non"),
  effectif = c(nrow(x), length(unique(x$id_etudiant)), nrow(baseline), nrow(known), nrow(complete),
    sum(complete$validation_annuelle == "oui"), sum(complete$validation_annuelle == "non")))
missing <- data.frame(variable = covariates,
  manquants_baseline_connue = vapply(known[covariates], function(z) sum(is.na(z)), integer(1)))
repeats <- as.data.frame(table(as.integer(table(x$id_etudiant))))
names(repeats) <- c("n_inscriptions_par_etudiant", "n_etudiants")
cells <- as.data.frame(table(complete[c("id_formation", "niveau", "validation_annuelle")]))
cells <- cells[cells$Freq > 0, ]
by_covariate <- do.call(rbind, lapply(covariates, function(field) {
  z <- as.data.frame(table(modalite = as.character(complete[[field]]),
    decision = complete$validation_annuelle))
  z$variable <- field
  z
}))
cohorts <- as.data.frame(table(first[c("annee_universitaire", "niveau")]))
cohorts$definition <- "premiere_observation_et_niveau_pas_necessairement_entree_superieur"
coverage <- as.data.frame(table(x[c("annee_universitaire", "id_formation", "validation_annuelle")]))
packages <- data.frame(package = c("stats", "lme4", "geepack", "sandwich"),
  disponible_projet = vapply(c("stats", "lme4", "geepack", "sandwich"),
    requireNamespace, logical(1), quietly = TRUE))
stopifnot(!anyDuplicated(baseline$id_etudiant), qr(nested)$rank == ncol(nested),
  all(c("oui", "non") %in% complete$validation_annuelle),
  identical(before, tools::md5sum(paths)))
out <- here::here("outputs", "choix_modele")
fs::dir_create(out)
tables <- list(effectifs = flow, repetitions = repeats, manquants = missing,
  rang_matrices = ranks, cellules_formation_niveau = cells,
  cible_par_covariable = by_covariate, premieres_observations = cohorts,
  couverture_formation_annee = coverage, packages = packages)
for (name in names(tables)) utils::write.csv(tables[[name]],
  fs::path(out, paste0(name, ".csv")), row.names = FALSE, na = "", fileEncoding = "UTF-8")
sources <- c(paths, here::here("scripts", "audit_model_choice.R"),
  here::here("config", "simulation.R"), here::here("R", "data", "simulate_data.R"),
  here::here("renv.lock"))
manifest <- data.frame(fichier = as.character(fs::path_rel(sources, start = here::here())),
  md5 = unname(tools::md5sum(sources)))
utils::write.csv(manifest, fs::path(out, "manifeste_sources.csv"), row.names = FALSE)
saveRDS(list(tables = tables, sources = manifest, session = sessionInfo()),
  fs::path(out, "audit_choix_modele.rds"))
print(flow)
print(repeats)
print(missing)
print(ranks)
print(cohorts[cohorts$Freq > 0, ])
print(packages)
cat("Minimum par modalite de covariable et decision :", min(by_covariate$Freq), "\n")
cat("Audit sans estimation ; sources preparees inchangees.\n")
