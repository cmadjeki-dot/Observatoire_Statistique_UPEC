# Charge automatiquement les fonctions pour test_dir(), sans source() prealable.
source(here::here("R", "utils", "paths.R"), local = TRUE)
source(here::here("R", "data", "simulate_data.R"), local = TRUE)

# Une seule generation complete par execution de suite ; modifications par copie.
test_dataset <- local({
  cached <- NULL
  function() {
    if (is.null(cached)) cached <<- generate_dataset()
    cached
  }
})

test_small_config <- function() {
  cfg <- dget(here::here("config", "simulation.R"))
  cfg$n_etudiants <- 120L
  cfg$nouveaux_etudiants[] <- c(100L, 10L, 10L)
  cfg$niveaux_initiaux[] <- c(40L, 20L, 20L, 10L, 10L)
  cfg
}

test_data_keys <- c(etudiants = "id_etudiant", formations = "id_formation",
  inscriptions = "id_inscription", resultats = "id_inscription",
  parcours = "id_inscription_depart", invitations_evaluation = "id_invitation_evaluation",
  evaluations = "id_reponse_evaluation", decisions_diplome = "id_inscription",
  diplomes = "id_diplome", invitations_devenir = "id_invitation_devenir",
  devenir_diplomes = "id_reponse_devenir")

test_data_schema <- list(
  etudiants = c(id_etudiant = "character", type_bac = "character",
    motif_type_bac_manquant = "character", parcours_anterieur = "character"),
  formations = c(id_formation = "character", libelle_formation = "character",
    cycle = "character", poids_dans_cycle = "numeric"),
  inscriptions = c(id_inscription = "character", id_etudiant = "character",
    id_formation = "character", annee_universitaire = "character", niveau = "character",
    date_inscription = "Date", statut_inscription = "character", boursier = "logical",
    motif_boursier_manquant = "character", prerequis_valides = "logical"),
  resultats = c(id_inscription = "character", validation_annuelle = "character",
    motif_resultat_inconnu = "character", moyenne_annuelle = "numeric",
    ects_acquis = "integer", date_decision = "Date"),
  parcours = c(id_inscription_depart = "character", id_inscription_suivante = "character",
    etat_transition = "character"),
  invitations_evaluation = c(id_invitation_evaluation = "character", id_inscription = "character",
    vague = "character", date_ouverture = "Date", date_cloture = "Date", statut_reponse = "character"),
  evaluations = c(id_reponse_evaluation = "character", id_invitation_evaluation = "character",
    date_reponse = "Date", satisfaction_globale = "integer", motif_satisfaction_globale = "character",
    satisfaction_contenus = "integer", motif_satisfaction_contenus = "character",
    satisfaction_accompagnement = "integer", motif_satisfaction_accompagnement = "character"),
  decisions_diplome = c(id_inscription = "character", attribution_diplome = "character",
    date_decision_diplome = "Date"),
  diplomes = c(id_diplome = "character", id_inscription = "character",
    type_diplome = "character", date_diplome = "Date"),
  invitations_devenir = c(id_invitation_devenir = "character", id_diplome = "character",
    vague = "character", date_reference = "Date", date_ouverture = "Date",
    date_cloture = "Date", statut_reponse = "character"),
  devenir_diplomes = c(id_reponse_devenir = "character", id_invitation_devenir = "character",
    date_reponse = "Date", situation_six_mois = "character", motif_situation_manquante = "character",
    emploi_pendant_etudes = "logical", motif_emploi_pendant_etudes_manquant = "character")
)

expect_data_schema <- function(dataset) {
  testthat::expect_setequal(names(dataset), c(names(test_data_schema), "metadata"))
  for (table in names(test_data_schema)) {
    x <- dataset[[table]]
    testthat::expect_s3_class(x, "data.frame")
    testthat::expect_identical(names(x), names(test_data_schema[[table]]), info = table)
    for (field in names(test_data_schema[[table]])) {
      testthat::expect_identical(class(x[[field]]), unname(test_data_schema[[table]][field]),
        info = paste(table, field))
    }
  }
}

expect_foreign_key <- function(values, parent, nullable = FALSE) {
  if (!nullable) testthat::expect_false(anyNA(values))
  testthat::expect_true(all(values[!is.na(values)] %in% parent))
}
