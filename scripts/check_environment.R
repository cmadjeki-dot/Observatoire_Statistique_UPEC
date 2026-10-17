# Diagnostic de base sans package externe ni fichier de sortie.
# La tache VS Code utilise --vanilla pour isoler R du demarrage renv.
cat("Diagnostic R / VS Code\n")
cat("Version :", R.version.string, "\n")
cat("R_HOME :", R.home(), "\n")
cat("Dossier courant :", getwd(), "\n")
stopifnot(file.exists("DESCRIPTION"), dir.exists(".vscode"))
quarto <- Sys.which("quarto")
if (!nzchar(quarto)) {
  stop("Quarto CLI introuvable dans le PATH du processus R.")
}
cat("Quarto CLI :", quarto, "\n")
quarto_version <- system2(quarto, "--version", stdout = TRUE, stderr = TRUE)
if (!is.null(attr(quarto_version, "status"))) {
  stop(paste("Echec de Quarto :", paste(quarto_version, collapse = "\n")))
}
cat("Version Quarto :", quarto_version, "\n")
print(sessionInfo())
cat("Diagnostic termine sans erreur.\n")
