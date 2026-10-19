# Synthese des resultats existants, sans nouvelle estimation ni seuil metier.

.verify_restitution_sources <- function(manifest) {
  if (!is.data.frame(manifest) || !all(c("fichier", "md5") %in% names(manifest)) ||
      anyNA(manifest[c("fichier", "md5")]) || anyDuplicated(manifest$fichier))
    stop("Manifeste de preuves invalide.", call. = FALSE)
  paths <- vapply(manifest$fichier, function(path) as.character(project_path(path)), character(1))
  if (!all(file.exists(paths)) || !identical(unname(tools::md5sum(paths)), manifest$md5))
    stop("Sources de preuves modifiees : regeneration necessaire.", call. = FALSE)
  invisible(TRUE)
}

#' Charger les preuves et verifier leur concordance sans reestimer les modeles
#' @return Liste indicateurs, annexes, suivi, performances et fichiers consultes.
#' @details Le suivi est recalcule depuis les tables controlees et rapproche de
#' l'export 08 ; les anciens documents editoriaux ne servent pas de donnees.
#' Prerequis : paths.R, descriptive.R, longitudinal.R et model.R.
load_restitution_evidence <- function() {
  files <- c(priorites = output_path("indicateurs", "indicateurs_decisionnels.rds"),
    modele = output_path("modelisation", "audit_modelisation.rds"),
    suivi = output_path("longitudinal", "analyse_longitudinale.rds"),
    causal = output_path("faisabilite_causale", "audit_faisabilite.rds"))
  if (!all(file.exists(files))) stop("Preuves manquantes : executer les notebooks precedents.", call. = FALSE)
  objects <- lapply(files, readRDS)
  .verify_restitution_sources(objects$priorites$sources)
  .verify_restitution_sources(objects$modele$tables$manifeste_sources)
  .verify_restitution_sources(objects$causal$tables$manifeste_sources)
  if (!identical(objects$causal$decision, "aucun_effet_causal_estime") ||
      !identical(objects$priorites$metadata$provenance, "entierement_synthetique_non_officiel"))
    stop("Conclusion causale ou provenance incompatible.", call. = FALSE)
  input <- load_descriptive_source()
  decisions <- readRDS(data_path("processed", "decisions_diplome.rds"))
  panel <- prepare_longitudinal(input$data, decisions, input$metadata$config$annees)
  follow <- summarise_cohort_followup(panel$suivi_l1)
  if (!isTRUE(all.equal(follow, objects$suivi$tables$suivi_cohortes, check.attributes = FALSE)))
    stop("Suivi des cohortes non concordant : regeneration necessaire.", call. = FALSE)
  prediction <- objects$modele$tables$predictions_test
  scores <- success_metrics(prediction$validation, prediction$probabilite)
  recorded <- objects$modele$tables$performances_test
  if (!isTRUE(all.equal(scores, recorded[1L, names(scores)], check.attributes = FALSE)))
    stop("Performances du modele non concordantes.", call. = FALSE)
  list(indicateurs = objects$priorites$indicateurs, annexes = objects$priorites$annexes,
    suivi = follow, performances = recorded, metadata = input$metadata, fichiers = files)
}

.restitution_number <- function(x, digits = 2L) {
  if (length(x) != 1L || is.na(x) || !is.finite(x))
    stop("Valeur absente ou non diffusable : constat chiffre bloque.", call. = FALSE)
  formatC(x, digits = digits, format = "f", big.mark = " ", decimal.mark = ",")
}

#' Produire huit constats tracables et leurs recommandations methodologiques
#' @param evidence Resultat de load_restitution_evidence().
#' @return Table resultat/interpretation/implication/recommandation avec millesime et source.
build_restitution_findings <- function(evidence) {
  k <- evidence$indicateurs
  number <- .restitution_number
  get <- function(id, year, degree = "non_applicable") {
    row <- k[k$id == id & k$annee_universitaire == year & k$type_diplome == degree, ]
    if (nrow(row) != 1L || row$statut != "diffusable" || is.na(row$valeur))
      stop("Indicateur requis absent ou non diffusable : ", id, call. = FALSE)
    row
  }
  year <- max(k$annee_universitaire[k$type_diplome == "non_applicable"])
  enrol <- get("I02", year)
  success <- get("I03", year)
  eval <- get("I06", year)
  satisfaction <- get("I07", year)
  diploma <- get("I08", year)
  depart <- max(k$annee_universitaire[k$id == "I05a" & k$statut == "diffusable"])
  passage <- get("I05a", depart)
  reorientation <- get("I05c", depart)
  future_year <- max(k$annee_universitaire[k$id == "I09"])
  licence <- get("I10", future_year, "licence")
  master <- get("I10", future_year, "master")
  studies_l <- get("I11", future_year, "licence")
  studies_m <- get("I11", future_year, "master")
  annual <- evidence$annexes$inscriptions
  annual <- annual[annual$annee_universitaire == year, ]
  if (nrow(annual) != 1L) stop("Volume annuel absent.", call. = FALSE)
  h1 <- evidence$suivi[evidence$suivi$horizon == 1L, ]
  h1 <- h1[order(h1$cohorte_l1), ]
  if (nrow(h1) != 2L || !identical(h1$cohorte_l1, c("2023-2024", "2024-2025")))
    stop("Deux cohortes a horizon comparable sont requises.", call. = FALSE)
  transition <- evidence$annexes$transitions
  repeat_row <- transition[transition$annee_universitaire == depart & transition$etat_transition == "redoublement", ]
  if (nrow(repeat_row) != 1L) stop("Redoublements absents.", call. = FALSE)
  p <- evidence$performances
  if (nrow(p) != 2L || !identical(p$modele, c("GLM_test", "reference_constante_test")))
    stop("Performances comparatives absentes.", call. = FALSE)
  rows <- list()
  add <- function(id, titre, millesime, resultat, interpretation, implication, recommandation, source) {
    rows[[length(rows) + 1L]] <<- data.frame(id = id, titre = titre, millesime = millesime,
      resultat = resultat, interpretation = interpretation, implication_metier = implication,
      recommandation = recommandation, source = source, stringsAsFactors = FALSE)
  }
  add("C01", "Volumes et capacites d'accueil", year,
    paste0(number(enrol$valeur, 0), " inscriptions ; variation annuelle de ", number(annual$variation_effectif, 0),
      " inscriptions (", number(annual$evolution_pct), " %)."),
    "La variation combine entrees, sorties et progression du panel ; elle ne mesure pas seule l'attractivite.",
    "Une evolution du volume peut modifier les besoins de capacite, mais sa composition doit etre examinee.",
    "Ventiler les volumes par formation et niveau avant de formuler une hypothese sur les capacites ou l'attractivite.",
    "I02 ; annexe_inscriptions ; notebooks 05 et 10")
  add("C02", "Reussite et couverture des decisions", year,
    paste0(number(success$valeur), " % de validations : ", number(success$numerateur, 0), "/",
      number(success$denominateur, 0), " decisions connues ; couverture ", number(success$couverture_pct),
      " %, avec ", number(success$n_manquants, 0), " decisions inconnues."),
    "Le taux porte sur les decisions connues ; les inconnus ne sont pas des echecs.",
    "Des ecarts de composition ou de couverture peuvent modifier les comparaisons de reussite.",
    "Lire ensemble validation, couverture et profils ; examiner les dossiers inconnus avant d'interpreter une evolution.",
    "I03 ; annexe_reussite ; notebooks 05 et 10")
  add("C03", "Transitions et limite d'observation", paste0("Depart ", depart),
    paste0("Passage ", number(passage$valeur), " %, redoublement ", number(repeat_row$taux_pct),
      " %, reorientation ", number(reorientation$valeur), " % ; denominateur ",
      number(passage$denominateur, 0), " inscriptions de depart. Les transitions 2025-2026 sont censurees."),
    "Les sorties restent au denominateur ; la poursuite intercycle est distincte du passage et de la reorientation.",
    "Le dernier millesime scolaire ne dispose pas encore d'une transition suivante dans ce panel.",
    "Afficher le depart et l'arrivee observables ; garder les transitions finales absentes et distinguer sortie et abandon.",
    "I05a/I05c ; annexe_transitions ; notebook 08")
  add("C04", "Cohortes comparees a duree egale", "Presence a horizon 1 des cohortes L1 2023-2024 et 2024-2025",
    paste0(number(h1$presence_pct[1]), " % (", number(h1$n_presents[1], 0), "/",
      number(h1$n_cohorte_initiale[1], 0), ") et ", number(h1$presence_pct[2]), " % (",
      number(h1$n_presents[2], 0), "/", number(h1$n_cohorte_initiale[2], 0), ")."),
    "La presence dans le champ est tres proche a un an ; une absence ne prouve pas un abandon definitif.",
    "La cohorte 2025-2026 ne peut pas etre comparee a un an faute de suivi disponible.",
    "Comparer les cohortes a horizon egal et rechercher d'autres sources pour qualifier les absences dans un dispositif reel.",
    "L01 ; suivi_cohortes du notebook 08, recalcule et verifie")
  add("C05", "Satisfaction et participation", paste0("Evaluation de ", year),
    paste0("Participation ", number(eval$valeur), " % (", number(eval$numerateur, 0), "/",
      number(eval$denominateur, 0), ") ; satisfaction favorable ", number(satisfaction$valeur), " % (",
      number(satisfaction$numerateur, 0), "/", number(satisfaction$denominateur, 0),
      " reponses valides), couverture numerique ", number(satisfaction$couverture_pct), " %."),
    "La satisfaction est celle des repondants valides, pas de tous les inscrits ; non-reponse et NC sont distincts.",
    "La participation et la couverture des items doivent accompagner toute comparaison entre formations.",
    "Examiner composition des repondants, accessibilite et calendrier ; tester les relances sans supposer qu'elles corrigent tout biais.",
    "I06/I07 ; annexe_evaluation ; notebook 07")
  add("C06", "Diplome : une mesure terminale distincte", year,
    paste0(number(diploma$valeur), " % d'attributions : ", number(diploma$numerateur, 0), "/",
      number(diploma$denominateur, 0), " decisions terminales connues ; couverture ", number(diploma$couverture_pct), " %."),
    "La population est limitee aux L3/M2 avec decision connue ; il ne s'agit pas d'une diplomation a trois ans des entrants.",
    "Validation annuelle et attribution du diplome repondent a des questions differentes.",
    "Conserver les deux definitions et examiner le type de diplome et les decisions inconnues avant de comparer les resultats.",
    "I08 ; annexe_diplomes ; notebook 10")
  add("C07", "Devenir : lire ensemble emploi, etudes et couverture", paste0("Diplomes ", future_year, " ; situation a six mois"),
    paste0("Emploi parmi situations connues hors etudes : licence ", number(licence$valeur), " % (",
      number(licence$numerateur, 0), "/", number(licence$denominateur, 0), "), master ", number(master$valeur),
      " % (", number(master$numerateur, 0), "/", number(master$denominateur, 0), "). Etudes parmi situations connues : ",
      number(studies_l$valeur), " % et ", number(studies_m$valeur), " %. Couvertures : ",
      number(licence$couverture_pct), " % et ", number(master$couverture_pct), " %."),
    "Les champs emploi et etudes ont des denominateurs differents ; les distributions sont programmees dans la simulation.",
    "Un taux d'emploi hors etudes ne peut etre lu comme le resultat de tous les diplomes ni comme un effet du diplome.",
    "Presenter I09, I10 et I11 ensemble par type et cohorte, sans additionner les taux ; exclure les collectes non closes.",
    "I09/I10/I11 ; annexe_devenir ; notebooks 07 et 10")
  add("C08", "Modele exploratoire : usage limite", "Validation interne sur la coupe 2023-2024",
    paste0("AUC ", number(p$auc[1], 3), " ; Brier ", number(p$brier[1], 4), " contre ",
      number(p$brier[2], 4), " pour la reference constante ; ", number(p$n[1], 0), " etudiants de test."),
    "La discrimination est limitee et le gain predictif modeste ; la validation n'est ni temporelle ni externe.",
    "Ces performances et les associations du modele n'etablissent aucun effet causal ni seuil de decision individuelle.",
    "Reserver le modele a l'illustration methodologique ; definir l'usage et une validation adaptee avant toute application reelle.",
    "audit_modelisation ; notebooks 06 et 09")
  dplyr::bind_rows(rows)
}

#' Formatter la restitution en Markdown partageable, sans nouvelle statistique
#' @param findings Constats de build_restitution_findings().
#' @return Chaine Markdown avec synthese et quatre rubriques par constat.
format_restitution_markdown <- function(findings) {
  required <- c("id", "titre", "millesime", "resultat", "interpretation", "implication_metier", "recommandation", "source")
  if (!is.data.frame(findings) || !all(required %in% names(findings)) ||
      anyNA(findings[required]) || anyDuplicated(findings$id)) stop("Constats invalides.", call. = FALSE)
  head <- c("# Synthese de pilotage — demonstrateur personnel", "",
    "Donnees entierement synthetiques ; projet independant de l'UPEC. Gel d'observation : 30 septembre 2026.", "",
    "Aucune recommandation ne constitue une action sur une formation reelle ou un etudiant.", "",
    "## Lecture rapide", "", paste0("- ", findings$titre, " : ", findings$resultat), "",
    "Priorite proposee : verifier les champs et la couverture, examiner la collecte, puis automatiser une restitution controlee.", "")
  body <- unlist(lapply(seq_len(nrow(findings)), function(i) {
    x <- findings[i, ]
    c(paste0("## ", x$id, " — ", x$titre), "", paste0("**Perimetre :** ", x$millesime), "",
      paste0("**Resultat :** ", x$resultat), "", paste0("**Interpretation :** ", x$interpretation), "",
      paste0("**Implication metier :** ", x$implication_metier), "",
      paste0("**Recommandation :** ", x$recommandation), "", paste0("**Source :** ", x$source), "")
  }), use.names = FALSE)
  paste(c(head, body), collapse = "\n")
}
