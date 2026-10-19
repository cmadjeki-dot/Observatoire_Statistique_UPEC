# Audit descriptif de faisabilite ; aucune estimation d'effet ou de propension.

#' Documenter les informations presentes et le support des formations par niveau
#' @param data Table scolarite_analytique controlee par son manifeste.
#' @return Inventaire, flux de disponibilite et cellules formation/niveau initiales.
#' @details Les comptes ne verifient pas l'echangeabilite ni la positivite causale.
audit_causal_feasibility <- function(data) {
  required <- c("id_inscription", "id_etudiant", "annee_universitaire", "statut_inscription",
    "niveau", "id_formation", "validation_annuelle", "boursier")
  if (!is.data.frame(data) || !all(required %in% names(data)) ||
      anyNA(data[setdiff(required, "boursier")]) || anyDuplicated(data$id_inscription) ||
      anyDuplicated(data[c("id_etudiant", "annee_universitaire")]))
    stop("Source analytique invalide.", call. = FALSE)
  x <- data[data$statut_inscription == "active", ]
  baseline <- x[x$annee_universitaire == "2023-2024", ]
  if (!nrow(baseline)) stop("Coupe initiale absente.", call. = FALSE)
  inventory <- data.frame(variable = names(data),
    type = vapply(data, function(z) paste(class(z), collapse = "/"), character(1)),
    n_manquants = vapply(data, function(z) sum(is.na(z)), integer(1)), row.names = NULL)
  support <- as.data.frame(table(niveau = factor(baseline$niveau, levels = c("L1", "L2", "L3", "M1", "M2")),
    id_formation = factor(baseline$id_formation, levels = c("FL_A", "FL_B", "FL_C", "FM_A", "FM_B"))))
  names(support)[3L] <- "effectif"
  support$hors_cycle <- (support$niveau %in% c("L1", "L2", "L3")) !=
    (support$id_formation %in% c("FL_A", "FL_B", "FL_C"))
  flow <- data.frame(controle = c("inscriptions_panel", "etudiants_distincts", "inscriptions_initiales",
    "L1_initiales", "decisions_initiales_inconnues", "bourse_initiale_manquante"),
    effectif = c(nrow(x), length(unique(x$id_etudiant)), nrow(baseline),
      sum(baseline$niveau == "L1"), sum(baseline$validation_annuelle == "inconnu"),
      sum(is.na(baseline$boursier))))
  list(inventaire = inventory, disponibilite = flow, support_formation_niveau = support)
}
