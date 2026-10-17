#' Construire un chemin depuis la racine du projet
#'
#' @param ... Composants relatifs, chacun sous forme d'une chaine non vide.
#'   Les chemins absolus et les composants `..` sont refuses, y compris avec
#'   les separateurs Windows. Sans argument, retourne la racine du projet.
#' @return Un chemin calcule avec here et fs, sans creer de fichier ou dossier.
#' @details Demarrer R dans le projet ou un de ses sous-dossiers. Ces fonctions
#'   servent a construire les chemins ; elles ne controlent pas les cibles
#'   physiques des liens symboliques et ne constituent pas un bac a sable.
project_path <- function(...) {
  parts <- list(...)
  for (part in parts) {
    if (!is.character(part) || length(part) != 1L ||
        is.na(part) || !nzchar(trimws(part))) {
      stop("Chaque composant doit etre une chaine non vide unique.", call. = FALSE)
    }
    # Normaliser aussi les separateurs Windows sur les autres plateformes.
    portable <- chartr("\\", "/", part)
    if (fs::is_absolute_path(portable) || grepl("^([A-Za-z]:|/|~)", portable)) {
      stop("Les chemins absolus ou lies au dossier personnel sont interdits.",
           call. = FALSE)
    }
    if (any(strsplit(portable, "/", fixed = TRUE)[[1L]] == "..")) {
      stop("Les composants '..' sont interdits.", call. = FALSE)
    }
  }
  relative <- vapply(parts, function(x) chartr("\\", "/", x), character(1))
  if (!length(relative)) return(fs::path_norm(here::here()))
  fs::path_norm(do.call(fs::path, c(list(here::here()), as.list(relative))))
}

#' Construire un chemin de donnees dans raw, interim ou processed
#' @param stage Etape de traitement : raw, interim ou processed.
#' @param ... Composants relatifs sous le dossier choisi.
#' @return Un chemin, sans creation ni modification de donnees.
data_path <- function(stage = c("raw", "interim", "processed"), ...) {
  stage <- match.arg(stage)
  project_path("data", stage, ...)
}

#' Construire un chemin de resultat dans outputs
#' @param ... Composants relatifs sous outputs.
#' @return Un chemin, sans creation ni modification de resultat.
output_path <- function(...) {
  project_path("outputs", ...)
}
