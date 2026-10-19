# Reconstruction puis rapports consommateurs, dans un magasin isole.
source(here::here("R", "utils", "paths.R"))
source(here::here("R", "pipeline", "pipeline.R"))
withr::with_envvar(c(UPEC_PIPELINE_REBUILD = "true", UPEC_PIPELINE_REPORTS = "true",
    UPEC_PIPELINE_OUTPUT = "outputs/pipeline_rapport"),
  run_project_pipeline(store = "outputs/pipeline_rapport/store"))
