# Verification d'integration de l'etape 12, sans sauvegarde des tables brutes.
source(here::here("R", "data", "simulate_data.R"))
cfg <- dget(here::here("config", "simulation.R"))
set.seed(42)
initial_seed <- .Random.seed
initial_kind <- RNGkind()
dataset <- generate_dataset(cfg)
stopifnot(identical(.Random.seed, initial_seed), identical(RNGkind(), initial_kind))
tables <- dataset[vapply(dataset, is.data.frame, logical(1))]
stopifnot(length(tables) == 11L, nrow(dataset$etudiants) == 15000L)
keys <- c(etudiants = "id_etudiant", formations = "id_formation",
  inscriptions = "id_inscription", resultats = "id_inscription",
  parcours = "id_inscription_depart", invitations_evaluation = "id_invitation_evaluation",
  evaluations = "id_reponse_evaluation", decisions_diplome = "id_inscription",
  diplomes = "id_diplome", invitations_devenir = "id_invitation_devenir",
  devenir_diplomes = "id_reponse_devenir")
for (table in names(keys)) {
  key <- dataset[[table]][[keys[[table]]]]
  stopifnot(is.character(key), !anyNA(key), !anyDuplicated(key))
}
reference <- function(child, field, parent, key, nullable = FALSE) {
  value <- dataset[[child]][[field]]
  if (!nullable) stopifnot(!anyNA(value))
  stopifnot(all(value[!is.na(value)] %in% dataset[[parent]][[key]]))
}
reference("inscriptions", "id_etudiant", "etudiants", "id_etudiant")
reference("inscriptions", "id_formation", "formations", "id_formation")
for (table in c("resultats", "decisions_diplome", "diplomes", "invitations_evaluation"))
  reference(table, "id_inscription", "inscriptions", "id_inscription")
reference("parcours", "id_inscription_depart", "inscriptions", "id_inscription")
reference("parcours", "id_inscription_suivante", "inscriptions", "id_inscription", TRUE)
reference("evaluations", "id_invitation_evaluation", "invitations_evaluation", "id_invitation_evaluation")
reference("invitations_devenir", "id_diplome", "diplomes", "id_diplome")
reference("devenir_diplomes", "id_invitation_devenir", "invitations_devenir", "id_invitation_devenir")
ins <- dataset$inscriptions
res <- dataset$resultats
stopifnot(!anyDuplicated(ins[c("id_etudiant", "annee_universitaire")]),
  setequal(ins$id_etudiant, dataset$etudiants$id_etudiant),
  identical(ins$id_inscription, res$id_inscription),
  identical(ins$id_inscription, dataset$parcours$id_inscription_depart),
  nrow(ins) == nrow(dataset$invitations_evaluation))
stopifnot(all(ins$annee_universitaire %in% cfg$annees),
  all(res$validation_annuelle %in% c("oui", "non", "inconnu")),
  is.logical(ins$boursier), is.integer(res$ects_acquis))
for (table in tables) for (field in grep("^date_", names(table), value = TRUE))
  stopifnot(inherits(table[[field]], "Date"))
known <- res$validation_annuelle != "inconnu"
valid <- res$validation_annuelle == "oui"
stopifnot(all(res$date_decision[known] >= ins$date_inscription[known]),
  all(res$date_decision[known] <= cfg$date_gel),
  all(is.na(res$moyenne_annuelle[!known])), all(is.na(res$ects_acquis[!known])),
  all(res$moyenne_annuelle[valid] >= 10), all(res$ects_acquis[valid] == 60L),
  all(res$moyenne_annuelle[known & !valid] < 10),
  all(res$ects_acquis[known & !valid] < 60L))
cycle <- dataset$formations$cycle[match(ins$id_formation, dataset$formations$id_formation)]
stopifnot(all((cycle == "licence") == (substr(ins$niveau, 1, 1) == "L")))
path <- dataset$parcours
next_row <- match(path$id_inscription_suivante, ins$id_inscription)
observed <- !is.na(next_row)
year <- match(ins$annee_universitaire, cfg$annees)
stopifnot(all(year[next_row[observed]] == year[observed] + 1L),
  all(ins$id_etudiant[next_row[observed]] == ins$id_etudiant[observed]),
  all(path$etat_transition[year == 3L] == "non_observable"),
  all(is.na(next_row[year == 3L])),
  all(path$etat_transition[year < 3L & !observed] == "sortie_observee"))
for (state in c("passage", "redoublement", "reorientation", "poursuite_intercycle")) {
  i <- which(path$etat_transition == state)
  j <- next_row[i]
  stopifnot(!anyNA(j))
  if (state == "passage") stopifnot(all(valid[i]), all(ins$id_formation[i] == ins$id_formation[j]),
    all(as.integer(substr(ins$niveau[j], 2, 2)) == as.integer(substr(ins$niveau[i], 2, 2)) + 1L))
  if (state == "redoublement") stopifnot(all(res$validation_annuelle[i] == "non"),
    all(ins$niveau[i] == ins$niveau[j]), all(ins$id_formation[i] == ins$id_formation[j]))
  if (state == "reorientation") stopifnot(all(ins$id_formation[i] != ins$id_formation[j]),
    all(ins$niveau[i] == ins$niveau[j]))
  if (state == "poursuite_intercycle") stopifnot(all(ins$niveau[i] == "L3"),
    all(ins$niveau[j] == "M1"), all(valid[i]))
}
dd <- dataset$decisions_diplome
dipl <- dataset$diplomes
stopifnot(setequal(dipl$id_inscription, dd$id_inscription[dd$attribution_diplome == "oui"]),
  all(ins$niveau[match(dd$id_inscription, ins$id_inscription)] %in% c("L3", "M2")),
  all(res$validation_annuelle[match(dipl$id_inscription, res$id_inscription)] == "oui"))
for (kind in c("evaluation", "devenir")) {
  inv <- dataset[[paste0("invitations_", kind)]]
  resp <- dataset[[if (kind == "evaluation") "evaluations" else "devenir_diplomes"]]
  field <- paste0("id_invitation_", kind)
  stopifnot(!anyDuplicated(resp[[field]]))
  pos <- match(resp[[field]], inv[[field]])
  stopifnot(all(resp$date_reponse >= inv$date_ouverture[pos]),
    all(resp$date_reponse <= inv$date_cloture[pos]),
    setequal(inv[[field]][inv$statut_reponse != "aucune"], resp[[field]]))
}
dev <- dataset$invitations_devenir
dip_row <- match(dev$id_diplome, dipl$id_diplome)
dev_ids <- ins$id_etudiant[match(dipl$id_inscription[dip_row], ins$id_inscription)]
stopifnot(!anyDuplicated(dev_ids), all(dev$date_cloture <= cfg$date_gel),
  all(dev$date_reference > dipl$date_diplome[dip_row]))
stopifnot(identical(dataset, generate_dataset(cfg)), identical(.Random.seed, initial_seed))
serialized <- serialize(dataset, NULL)
altered <- inject_quality_issues(dataset)
stopifnot(identical(serialized, serialize(dataset, NULL)),
  identical(.Random.seed, initial_seed), identical(altered, inject_quality_issues(dataset)),
  nrow(altered$issues) == 5L * cfg$anomalies$nombre_par_type,
  all(table(altered$issues$type) == cfg$anomalies$nombre_par_type),
  nrow(altered$data$inscriptions) == nrow(ins) + cfg$anomalies$nombre_par_type)
for (i in seq_len(nrow(altered$issues))) {
  entry <- altered$issues[i, ]
  actual <- altered$data[[entry$table]][[entry$champ]][entry$ligne]
  stopifnot(identical(as.character(actual), entry$valeur_injectee))
}
cat("SIMULATION : CONTROLES D'INTEGRATION REUSSIS\n")
print(data.frame(table = names(tables), lignes = vapply(tables, nrow, integer(1))), row.names = FALSE)
print(table(ins$annee_universitaire))
print(table(path$etat_transition))
cat("ANOMALIES CONTROLEES :", nrow(altered$issues), "\n")
small <- cfg
small$n_etudiants <- 25L
small$nouveaux_etudiants[] <- c(25L, 0L, 0L)
small$niveaux_initiaux[] <- c(25L, 0L, 0L, 0L, 0L)
small$evaluation$probabilite_reponse_reference <- 0
small$devenir$probabilite_reponse <- 0
for (state in names(small$transitions)) {
  small$transitions[[state]][] <- 0
  small$transitions[[state]]["sortie_observee"] <- 1
}
edge <- generate_dataset(small)
stopifnot(nrow(edge$inscriptions) == 25L, nrow(edge$diplomes) == 0L,
  nrow(edge$evaluations) == 0L, nrow(edge$invitations_devenir) == 0L,
  nrow(edge$devenir_diplomes) == 0L)
for (table in names(tables)) {
  stopifnot(identical(vapply(edge[[table]], class, character(1)),
                      vapply(dataset[[table]], class, character(1))))
}
stopifnot(identical(.sim_months(as.Date(c("2023-01-31", "2024-01-31")), 1L),
  as.Date(c("2023-02-28", "2024-02-29"))))
rm(".Random.seed", envir = .GlobalEnv)
invisible(generate_dataset(small))
stopifnot(!exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE))
assign(".Random.seed", initial_seed, envir = .GlobalEnv)
cat("CAS LIMITES : periodes et tables vides, fins de mois et RNG absent verifies\n")
cat("Aucune table brute sauvegardee ; sauvegarde prevue a l'etape 14.\n")
