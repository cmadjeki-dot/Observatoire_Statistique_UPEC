# Recette avec scenarios isoles : ne modifie aucune source canonique.
source(here::here("R", "utils", "paths.R"))
source(here::here("R", "pipeline", "pipeline.R"))
protected <- c(fs::dir_ls(data_path("raw"), type = "file", all = TRUE),
  fs::dir_ls(project_path("R"), recurse = TRUE, type = "file"),
  project_path("_targets.R"), project_path("scripts", "check_pipeline.R"),
  project_path("config", "indicators.yml"),
  fs::dir_ls(data_path("processed"), type = "file", all = TRUE),
  fs::dir_ls(output_path("descriptive"), type = "file"),
  fs::dir_ls(output_path("enquetes"), type = "file"),
  fs::dir_ls(output_path("longitudinal"), type = "file"),
  fs::dir_ls(output_path("modelisation"), type = "file"),
  fs::dir_ls(output_path("indicateurs"), type = "file"),
  fs::dir_ls(output_path("restitution"), type = "file"))
before <- tools::md5sum(protected)
targets::tar_validate(callr_function = NULL)
manifest <- targets::tar_manifest(callr_function = NULL)
utils::write.csv(manifest, output_path("pipeline", "graphe.csv"), row.names = FALSE)
run_project_pipeline(callr_function = NULL)
result <- readRDS(output_path("pipeline", "resultats.rds"))
same <- function(x, y) stopifnot(isTRUE(all.equal(x, y, check.attributes = FALSE)))
same(result$indicateurs$indicateurs,
  readRDS(output_path("indicateurs", "indicateurs_decisionnels.rds"))$indicateurs)
same(result$suivi, readRDS(output_path("longitudinal", "analyse_longitudinale.rds"))$tables$suivi_cohortes)
same(result$evaluation$performances,
  readRDS(output_path("modelisation", "audit_modelisation.rds"))$tables$performances_test)
same(result$coefficients,
  readRDS(output_path("modelisation", "audit_modelisation.rds"))$tables$coefficients)
same(result$enquetes$evaluation_annuelle,
  readRDS(output_path("enquetes", "analyse_enquetes.rds"))$tables$evaluation_annuelle)
same(result$enquetes$relations_items,
  readRDS(output_path("enquetes", "analyse_enquetes.rds"))$tables$relations_items)
same(result$constats, readRDS(output_path("restitution", "restitution_decisionnelle.rds"))$constats)
stopifnot(identical(result$qualite$metadata$verdict, "conforme"))
meta_before <- targets::tar_meta(fields = c(name, time), complete_only = TRUE)
run_project_pipeline(callr_function = NULL)
same(meta_before, targets::tar_meta(fields = c(name, time), complete_only = TRUE))
stopifnot(!length(targets::tar_outdated(callr_function = NULL)))
# Suppression limitee a un export calcule de recette, jamais aux sources.
missing <- output_path("pipeline", "indicateurs.csv")
hash <- unname(tools::md5sum(missing))
stopifnot(file.remove(missing))
stopifnot(identical(targets::tar_outdated(callr_function = NULL), "exports"))
run_project_pipeline(callr_function = NULL)
stopifnot(identical(unname(tools::md5sum(missing)), hash))

# Scenario independant ; un nouveau dossier evite tout ecrasement d'une recette.
scenario <- as.character(fs::path_rel(tempfile("recette_", tmpdir = output_path("pipeline")), here::here()))
fs::dir_create(scenario)
input <- fs::path(scenario, "prepared")
fs::dir_create(input)
fs::file_copy(fs::dir_ls(data_path("processed"), type = "file"), input)
config <- fs::path(scenario, "indicators.yml")
fs::file_copy(project_path("config", "indicators.yml"), config)
withr::with_envvar(c(UPEC_PIPELINE_INPUT = input, UPEC_PIPELINE_CONFIG = config,
    UPEC_PIPELINE_OUTPUT = fs::path(scenario, "exports")), {
  store <- fs::path(scenario, "store")
  run_project_pipeline(store = store, callr_function = NULL)
  text <- readLines(config, encoding = "UTF-8")
  changed <- sub("seuil_minimum_taux: 10", "seuil_minimum_taux: 11", text, fixed = TRUE)
  stopifnot(!identical(text, changed))
  writeLines(changed, config, useBytes = TRUE)
  outdated <- targets::tar_outdated(store = store, callr_function = NULL)
  stopifnot(all(c("indicator_file", "indicator_config", "indicators", "findings", "exports") %in% outdated),
    !any(c("validated", "success_model", "followup", "surveys") %in% outdated))
  run_project_pipeline(store = store, callr_function = NULL)
  # Une anomalie avec manifeste remis en coherence teste bien la porte qualite.
  file <- fs::path(input, "resultats.rds")
  original <- readRDS(file)
  broken <- original
  broken$moyenne_annuelle[1L] <- 25
  saveRDS(broken, file, version = 3)
  update_manifest <- function() {
    path <- fs::path(input, "manifest_preparation.csv")
    m <- utils::read.csv(path, stringsAsFactors = FALSE)
    paths <- fs::path(input, m$fichier)
    m$octets <- as.numeric(file.info(paths)$size)
    m$md5 <- unname(tools::md5sum(paths))
    utils::write.csv(m, path, row.names = FALSE, na = "")
  }
  update_manifest()
  export_hash <- tools::md5sum(fs::path(scenario, "exports", "resultats.rds"))
  error <- tryCatch({run_project_pipeline(store = store, callr_function = NULL); NULL}, error = identity)
  stopifnot(inherits(error, "error"), grepl("Qualite non conforme", conditionMessage(error)),
    utils::read.csv(fs::path(scenario, "exports", "statut.csv"))$statut == "echec",
    identical(export_hash, tools::md5sum(fs::path(scenario, "exports", "resultats.rds"))))
  saveRDS(original, file, version = 3)
  update_manifest()
  run_project_pipeline(store = store, callr_function = NULL)
  stopifnot(utils::read.csv(fs::path(scenario, "exports", "statut.csv"))$statut == "succes")
})
stopifnot(identical(before, tools::md5sum(protected)), isTRUE(renv::status()$synchronized))
writeLines(c("Recette conforme : concordance, relance stable, export reconstruit,",
  "configuration isolee, qualite bloquante, reprise, sources preservees.",
  paste("Scenario conserve :", scenario)), output_path("pipeline", "recette.txt"))
cat("RECETTE PIPELINE CONFORME\n")
