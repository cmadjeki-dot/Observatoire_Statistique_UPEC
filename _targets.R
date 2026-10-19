# Pipeline aval : les sources preparees restent immuables.
for (.pipeline_source_file in c("R/utils/paths.R", "R/data/simulate_data.R",
    "R/quality/check_quality.R", "R/data/clean_data.R",
    "R/analysis/descriptive.R", "R/surveys/analyse_surveys.R",
    "R/analysis/longitudinal.R", "R/modeling/model.R",
    "R/analysis/causal_feasibility.R", "R/analysis/indicators.R",
    "R/analysis/restitution.R", "R/pipeline/pipeline.R",
    "R/pipeline/reconstruction.R", "R/pipeline/report.R")) source(.pipeline_source_file, local = TRUE)
rm(.pipeline_source_file)

targets::tar_option_set(error = "stop", seed = 20261020L)
# Ces surcharges servent uniquement aux scenarios isoles de recette.
pipeline_input <- Sys.getenv("UPEC_PIPELINE_INPUT", "data/processed")
pipeline_config <- Sys.getenv("UPEC_PIPELINE_CONFIG", "config/indicators.yml")
pipeline_output <- Sys.getenv("UPEC_PIPELINE_OUTPUT", "outputs/pipeline")
pipeline_rebuild <- identical(Sys.getenv("UPEC_PIPELINE_REBUILD", "false"), "true")
pipeline_reports <- identical(Sys.getenv("UPEC_PIPELINE_REPORTS", "false"), "true")
pipeline_report_source <- Sys.getenv("UPEC_PIPELINE_REPORT_SOURCE", "reports/rapport_pilotage.qmd")

pipeline_upstream <- if (pipeline_rebuild) list(
  targets::tar_target(simulation_file, "config/simulation.R", format = "file"),
  targets::tar_target(simulation_config, dget(simulation_file)),
  targets::tar_target(generated, generate_dataset(simulation_config)),
  targets::tar_target(injected, inject_quality_issues(generated)),
  targets::tar_target(cleaned, pipeline_clean_reconstruction(generated, injected)),
  targets::tar_target(validated, pipeline_prepare_reconstruction(cleaned, environment_files)),
  targets::tar_target(reconstruction_files, pipeline_export_reconstruction(generated,
    injected, cleaned, validated, pipeline_output), format = "file"),
  targets::tar_target(input_files, c(simulation_file, reconstruction_files), format = "file")
) else list(
  targets::tar_target(input_files, pipeline_input_files(pipeline_input), format = "file"),
  targets::tar_target(validated, pipeline_validate(input_files, environment_files))
)

c(pipeline_upstream, list(
  targets::tar_target(environment_files, c("DESCRIPTION", "renv.lock", "config/simulation.R"), format = "file"),
  targets::tar_target(indicator_file, pipeline_config, format = "file"),
  targets::tar_target(indicator_config, pipeline_read_config(indicator_file, validated$metadata)),
  targets::tar_target(description, list(inscriptions = describe_enrolments(validated$scolarite_analytique),
    caracteristiques = describe_characteristics(validated$scolarite_analytique),
    reussite = describe_success(validated$scolarite_analytique),
    transitions = describe_transitions(validated$scolarite_analytique))),
  targets::tar_target(surveys, prepare_survey_tables(validated)),
  targets::tar_target(survey_results, pipeline_surveys(surveys)),
  targets::tar_target(longitudinal, prepare_longitudinal(validated$scolarite_analytique,
    validated$decisions_diplome, validated$metadata$config$annees)),
  targets::tar_target(followup, summarise_cohort_followup(longitudinal$suivi_l1)),
  targets::tar_target(transitions_matrix, longitudinal_matrix(longitudinal$inscriptions)),
  targets::tar_target(model_population, prepare_success_model(validated$scolarite_analytique)),
  targets::tar_target(model_split, split_success_model(model_population$data, seed = 20261020L)),
  targets::tar_target(success_model, fit_success_model(model_split$train)),
  targets::tar_target(model_diagnostics, diagnose_success_model(success_model, model_split$train)),
  targets::tar_target(model_coefficients, success_coefficients(success_model)),
  targets::tar_target(model_evaluation, evaluate_success_model(success_model, model_split)),
  targets::tar_target(indicators, build_priority_indicators(validated$scolarite_analytique,
    surveys, validated$decisions_diplome, indicator_config)),
  targets::tar_target(causal_audit, audit_causal_feasibility(validated$scolarite_analytique)),
  targets::tar_target(findings, build_restitution_findings(list(indicateurs = indicators$indicateurs,
    annexes = indicators$annexes, suivi = followup, performances = model_evaluation$performances))),
  targets::tar_target(exports, pipeline_export(list(qualite = validated$pipeline_quality, description = description,
    enquetes = survey_results, suivi = followup, matrice = transitions_matrix,
    population_modele = model_population, affectations = model_split$affectations,
    diagnostics = model_diagnostics, coefficients = model_coefficients,
    evaluation = model_evaluation, indicateurs = indicators, causal = causal_audit,
    constats = findings), success_model, c(input_files, indicator_file, environment_files),
    pipeline_output), format = "file")
), if (pipeline_reports) list(
  targets::tar_target(report_code, "R/pipeline/report.R", format = "file"),
  targets::tar_target(report_source, pipeline_report_source, format = "file"),
  targets::tar_target(note_source, "reports/note_pilotage.qmd", format = "file"),
  targets::tar_target(quarto_executable, quarto::quarto_path(), format = "file"),
  targets::tar_target(report_html, render_pipeline_report(exports, report_source,
    report_code, quarto_executable, pipeline_output), format = "file"),
  targets::tar_target(note_html, render_pipeline_report(exports, note_source,
    report_code, quarto_executable, pipeline_output), format = "file")
) else list())
