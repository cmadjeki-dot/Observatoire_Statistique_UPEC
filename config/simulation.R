# Configuration validee au demarrage de la phase B, le 18 octobre 2026.
# Lecture : dget(here::here("config", "simulation.R"))
# Aucun tirage aleatoire ni ecriture de donnees dans ce fichier.
list(
  version = "0.1", statut = "valide",
  n_etudiants = 15000L,
  annees = c("2023-2024", "2024-2025", "2025-2026"),
  nouveaux_etudiants = c("2023-2024" = 11000L, "2024-2025" = 2000L,
                         "2025-2026" = 2000L),
  niveaux_initiaux = c(L1 = 4000L, L2 = 2500L, L3 = 2000L, M1 = 1500L, M2 = 1000L),
  niveau_nouveaux_apres_2023 = "L1",
  date_gel = as.Date("2026-09-30"),
  calendrier = list(inscription = "09-15", reference_annuelle = "10-31",
    resultat = "09-30", diplome = "09-30",
    evaluation_debut = "06-01", evaluation_fin = "06-30"),
  rng = c(kind = "Mersenne-Twister", normal.kind = "Inversion", sample.kind = "Rejection"),
  graines = c(population = 20261001L, scolarite = 20261002L,
    evaluations = 20261003L, diplomes = 20261004L,
    devenir = 20261005L, anomalies = 20261006L),
  formations = data.frame(
    id_formation = c("FL_A", "FL_B", "FL_C", "FM_A", "FM_B"),
    libelle_formation = c("Licence fictive A", "Licence fictive B",
      "Licence fictive C", "Master fictif A", "Master fictif B"),
    cycle = c("licence", "licence", "licence", "master", "master"),
    poids_dans_cycle = c(0.40, 0.35, 0.25, 0.60, 0.40), stringsAsFactors = FALSE),
  population = list(
    type_bac = c(general = 0.70, technologique = 0.18, professionnel = 0.08, autre = 0.04),
    parcours_anterieur = c(entree_postbac = 0.85, reprise_etudes = 0.10, autre = 0.05),
    probabilite_boursier = 0.35, probabilite_conservation_bourse = 0.90,
    probabilite_bac_manquant = 0.01, probabilite_bourse_manquante = 0.02),
  resultats = list(
    probabilite_reference = c(L1 = 0.62, L2 = 0.70, L3 = 0.78, M1 = 0.75, M2 = 0.82),
    effet_logit_bac = c(general = 0, technologique = -0.30, professionnel = -0.60, autre = -0.10),
    effet_logit_reprise = -0.10, ecart_type_effet_etudiant = 0.55,
    probabilite_decision_inconnue = 0.02,
    moyenne_si_validation = c(min = 10, max = 18),
    moyenne_si_non_validation = c(min = 0, max = 9.99),
    ects_si_validation = 60L, ects_si_non_validation = c(0L, 10L, 20L, 30L, 40L, 50L)),
  transitions = list(
    validation_non_terminale = c(passage = 0.90, reorientation = 0.04, sortie_observee = 0.06),
    non_validation = c(redoublement = 0.65, reorientation = 0.15, sortie_observee = 0.20),
    licence_validee = c(poursuite_intercycle = 0.65, sortie_observee = 0.35),
    master_valide = c(sortie_observee = 1),
    decision_inconnue = c(maintien_meme_niveau = 0.70, reorientation = 0.05, sortie_observee = 0.25)),
  evaluation = list(
    probabilite_reponse_reference = 0.60, effet_logit_reponse_boursier = -0.20,
    satisfaction = c("1" = 0.06, "2" = 0.10, "3" = 0.24, "4" = 0.38, "5" = 0.22),
    probabilite_non_concerne_par_item = 0.03, probabilite_non_reponse_item = 0.05),
  devenir = list(
    horizon_mois = 6L, cloture_mois = 7L, probabilite_reponse = 0.65,
    probabilite_situation_manquante = 0.04,
    situation_licence = c(etudes = 0.60, emploi_hors_etudes = 0.25,
      recherche_emploi_hors_etudes = 0.10, autre_hors_etudes = 0.05),
    situation_master = c(etudes = 0.10, emploi_hors_etudes = 0.65,
      recherche_emploi_hors_etudes = 0.18, autre_hors_etudes = 0.07),
    probabilite_emploi_pendant_etudes = 0.20),
  diffusion = list(seuil_minimum_taux = 10L),
  anomalies = list(nombre_par_type = 10L,
    types = c("doublon_cle", "reference_orpheline", "valeur_hors_domaine",
      "date_incoherente", "transition_impossible"))
)
