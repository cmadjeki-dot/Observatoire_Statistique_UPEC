# A executer depuis la racine avec Rscript --no-save --no-restore.
source(here::here("R", "utils", "paths.R"))
source(here::here("R", "pipeline", "pipeline.R"))
run_project_pipeline()
