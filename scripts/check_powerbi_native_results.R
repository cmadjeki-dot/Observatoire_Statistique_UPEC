# Comparaison numerique du moteur Microsoft avec les references R.
k <- readRDS(here::here("outputs", "pipeline_dashboard", "indicateurs_reference.rds"))
x <- utils::read.csv(here::here("outputs", "powerbi_validation", "dax_natif.csv"),
  fileEncoding = "UTF-8-BOM", check.names = FALSE, stringsAsFactors = FALSE)
names(x) <- c("id", "annee_universitaire", "type_diplome", "lignes", "valeur_dax", "numerateur_dax", "denominateur_dax")
for (column in c("valeur_dax", "numerateur_dax", "denominateur_dax"))
  x[[column]] <- as.numeric(sub(",", ".", x[[column]], fixed = TRUE))
joined <- merge(k, x, by = c("id", "annee_universitaire", "type_diplome"), all = TRUE)
stopifnot(nrow(joined) == 33L, all(joined$lignes == 1L),
  isTRUE(all.equal(joined$valeur, joined$valeur_dax, tolerance = 1e-10)),
  isTRUE(all.equal(joined$numerateur, joined$numerateur_dax, tolerance = 1e-10)),
  isTRUE(all.equal(joined$denominateur, joined$denominateur_dax, tolerance = 1e-10)))
utils::write.csv(joined[c("id", "annee_universitaire", "type_diplome", "valeur", "valeur_dax")],
  here::here("outputs", "powerbi_validation", "concordance_DAX_R.csv"), row.names = FALSE)
cat("33 valeurs DAX natives conformes aux references R, NA compris.\n")
