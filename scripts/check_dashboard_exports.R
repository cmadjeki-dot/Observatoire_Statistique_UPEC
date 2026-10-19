source(here::here("R", "utils", "paths.R"))
source(here::here("R", "dashboard", "dashboard.R"))
directory <- output_path("pipeline_dashboard")
k <- readRDS(fs::path(directory, "indicateurs_reference.rds"))
fact <- utils::read.csv(fs::path(directory, "FactIndicateur.csv"), stringsAsFactors = FALSE)
dims <- lapply(c("DimIndicateur", "DimAnnee", "DimDiplome"), function(name)
  utils::read.csv(fs::path(directory, paste0(name, ".csv")), stringsAsFactors = FALSE))
stopifnot(nrow(fact) == 33L, !anyDuplicated(fact[c("id", "annee_universitaire", "type_diplome")]),
  !anyDuplicated(dims[[1]]$id), !anyDuplicated(dims[[2]]$annee_universitaire), !anyDuplicated(dims[[3]]$type_diplome),
  all(fact$id %in% dims[[1]]$id), all(fact$annee_universitaire %in% dims[[2]]$annee_universitaire),
  all(fact$type_diplome %in% dims[[3]]$type_diplome))
value <- ifelse(fact$id == "I02", fact$numerateur, 100 * fact$numerateur / fact$denominateur)
value[fact$statut != "diffusable"] <- NA_real_
stopifnot(isTRUE(all.equal(value, k$valeur)), all(is.na(value[fact$statut == "non_observable"])))
manifest <- utils::read.csv(fs::path(directory, "manifest_dashboard.csv"))
stopifnot(identical(unname(tools::md5sum(fs::path(directory, manifest$fichier))), manifest$md5))
utils::write.csv(data.frame(id = k$id, annee = k$annee_universitaire, diplome = k$type_diplome,
  attendu = k$valeur, recalcule_depuis_csv = value), fs::path(directory, "recette_mesures_R.csv"), row.names = FALSE)
cat("EXPORTS CONFORMES : cles, relations, 33 valeurs, censures et empreintes.\n")
