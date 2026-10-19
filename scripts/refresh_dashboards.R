# Point d'entree d'actualisation : calculs controles, puis exports.
source(here::here("R", "utils", "paths.R"))
directory <- output_path("pipeline_dashboard")
fs::dir_create(directory)
status <- function(value, message = "") utils::write.csv(data.frame(statut = value,
  instant_utc = format(Sys.time(), tz = "UTC", usetz = TRUE), message = message),
  fs::path(directory, "statut.csv"), row.names = FALSE)
status("en_cours")
tryCatch({
  source(here::here("scripts", "run_reports.R"))
  source(here::here("scripts", "run_dashboard_exports.R"))
  status("succes")
}, error = function(e) { status("echec", conditionMessage(e)); stop(e) })
