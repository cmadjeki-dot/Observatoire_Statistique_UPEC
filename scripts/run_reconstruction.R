# Reconstruction complete, magasin et sorties distincts du pipeline aval.
source(here::here("R", "utils", "paths.R"))
source(here::here("R", "pipeline", "pipeline.R"))
withr::with_envvar(c(UPEC_PIPELINE_REBUILD = "true",
    UPEC_PIPELINE_OUTPUT = "outputs/pipeline_reconstruction"),
  run_project_pipeline(store = "outputs/pipeline_reconstruction/store"))
