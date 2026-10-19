# Lecture et presentation uniquement : aucun calcul statistique ni estimation.

#' Lire des produits controles, en refusant un dernier lancement echoue
#' @param rendering TRUE uniquement pour le rendu interne durant tar_make().
load_pipeline_report <- function(directory, rendering = FALSE) {
  directory <- pipeline_output_directory(directory)
  status <- utils::read.csv(fs::path(directory, "statut.csv"), stringsAsFactors = FALSE)
  allowed <- if (isTRUE(rendering)) c("en_cours", "succes") else "succes"
  if (nrow(status) != 1L || !status$statut %in% allowed)
    stop("Produits non courants : dernier lancement non reussi.", call. = FALSE)
  products <- utils::read.csv(fs::path(directory, "produits.csv"), stringsAsFactors = FALSE)
  expected <- c("resultats.rds", "modele_reussite.rds", "indicateurs.csv", "constats.csv",
    "synthese_pilotage.md", "sources.csv")
  if (!identical(names(products), c("fichier", "md5")) || anyNA(products) ||
      anyDuplicated(products$fichier) || !setequal(products$fichier, expected))
    stop("Manifeste des produits invalide.", call. = FALSE)
  files <- fs::path(directory, products$fichier)
  if (!all(file.exists(files)) || !identical(unname(tools::md5sum(files)), products$md5))
    stop("Integrite des produits invalide.", call. = FALSE)
  sources <- utils::read.csv(fs::path(directory, "sources.csv"), stringsAsFactors = FALSE)
  if (!all(c("fichier", "md5") %in% names(sources)) || !nrow(sources) || anyNA(sources))
    stop("Manifeste des sources invalide.", call. = FALSE)
  paths <- vapply(sources$fichier, function(x) as.character(project_path(x)), character(1))
  if (!all(file.exists(paths)) || !identical(unname(tools::md5sum(paths)), sources$md5))
    stop("Sources modifiees : recalculer le pipeline.", call. = FALSE)
  result <- readRDS(fs::path(directory, "resultats.rds"))
  if (!identical(result$qualite$metadata$verdict, "conforme"))
    stop("Qualite non conforme : rapport refuse.", call. = FALSE)
  list(resultats = result, sources = sources, produits = products)
}

#' Rendre un document Quarto consommateur et tracer ses sources
#' @return HTML autonome et manifeste des entrees du rendu, suivis par targets.
render_pipeline_report <- function(exports, source, code, executable, directory) {
  directory <- pipeline_output_directory(directory)
  stopifnot(all(file.exists(c(exports, source, code, executable))))
  load_pipeline_report(as.character(fs::path_rel(directory, here::here())), rendering = TRUE)
  destination <- fs::path(directory, "rapports")
  fs::dir_create(destination)
  name <- tools::file_path_sans_ext(basename(source))
  withr::with_envvar(c(QUARTO_R = as.character(fs::path(R.home(), "bin"))),
    quarto::quarto_render(input = source, output_format = "html",
    output_file = paste0(name, ".html"),
    quarto_args = c("--output-dir", as.character(fs::path_rel(destination,
      dirname(project_path(source))))),
    execute_dir = here::here(), execute_params = list(
      pipeline_directory = as.character(fs::path_rel(directory, here::here())), rendering = TRUE),
    quiet = FALSE))
  html <- fs::path(destination, paste0(name, ".html"))
  if (!file.exists(html)) stop("HTML attendu absent apres Quarto.", call. = FALSE)
  inputs <- c(exports, source, code, executable)
  trace <- fs::path(destination, paste0(name, "_sources.csv"))
  utils::write.csv(data.frame(fichier = as.character(fs::path_rel(inputs, here::here())),
    md5 = unname(tools::md5sum(inputs)), version_r = R.version.string,
    version_quarto = as.character(quarto::quarto_version())), trace, row.names = FALSE)
  c(as.character(html), as.character(trace))
}
