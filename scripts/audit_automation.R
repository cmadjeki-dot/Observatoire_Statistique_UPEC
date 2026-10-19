# Cadrage de l'automatisation : aucun pipeline lance, aucune installation.
stopifnot(isTRUE(renv::status()$synchronized))
packages <- c("targets", "tarchetypes", "quarto", "shiny", "bslib", "DT", "yaml")
available <- vapply(packages, requireNamespace, logical(1), quietly = TRUE)
inventory <- data.frame(package = packages, disponible_projet = available,
  version = vapply(packages, function(name) if (requireNamespace(name, quietly = TRUE))
    as.character(utils::packageVersion(name)) else NA_character_, character(1)))
entrypoints <- c("_targets.R", "_quarto.yml", "dashboard/app.R", "dashboard/ui.R", "dashboard/server.R")
entrypoints <- data.frame(fichier = entrypoints,
  existe = file.exists(here::here(entrypoints)))
api <- c("tar_make", "tar_manifest", "tar_outdated", "tar_validate", "tar_meta", "tar_target")
api <- data.frame(fonction = api, exportee = api %in% getNamespaceExports("targets"))
stopifnot(all(api$exportee))
input_files <- c(fs::dir_ls(here::here("data", "raw"), type = "file", all = TRUE),
  fs::dir_ls(here::here("data", "processed"), type = "file", all = TRUE))
manifest <- data.frame(fichier = as.character(fs::path_rel(input_files, start = here::here())),
  md5 = unname(tools::md5sum(input_files)))
out <- here::here("outputs", "cadrage_automatisation")
fs::dir_create(out)
utils::write.csv(inventory, fs::path(out, "packages.csv"), row.names = FALSE, na = "")
utils::write.csv(entrypoints, fs::path(out, "points_entree.csv"), row.names = FALSE)
utils::write.csv(api, fs::path(out, "api_targets.csv"), row.names = FALSE)
utils::write.csv(manifest, fs::path(out, "manifeste_donnees.csv"), row.names = FALSE)
saveRDS(list(packages = inventory, points_entree = entrypoints, api_targets = api,
  sources = manifest, session = sessionInfo()), fs::path(out, "audit_automatisation.rds"))
print(inventory)
print(entrypoints)
print(api)
cat("Store targets existant :", dir.exists(here::here("_targets")), "\n")
cat("Aucun pipeline execute ; aucun package installe.\n")
