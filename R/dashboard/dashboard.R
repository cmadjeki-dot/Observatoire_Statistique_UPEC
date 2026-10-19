# Vues partagees par Shiny et Power BI : pas de moyenne de taux.
dashboard_pages <- function() list(inscriptions = c("I02"), reussite = c("I03", "I08"),
  parcours = c("I05a", "I05c"), enquetes = c("I06", "I07"), insertion = c("I09", "I10", "I11"))

#' Filtrer une vue sans modifier les denominateurs ni remplacer les NA
dashboard_filter <- function(kpi, page, year = NULL, diploma = NULL) {
  if (!page %in% names(dashboard_pages())) stop("Page inconnue.", call. = FALSE)
  x <- kpi[kpi$id %in% dashboard_pages()[[page]], ]
  if (!is.null(year)) x <- x[x$annee_universitaire %in% year, ]
  if (page == "insertion" && !is.null(diploma) && diploma != "Tous")
    x <- x[x$type_diplome %in% diploma, ]
  x
}

#' Exporter une etoile relationnelle pour les deux tableaux de bord
export_dashboard_tables <- function(evidence, directory = "outputs/pipeline_dashboard") {
  directory <- pipeline_output_directory(directory)
  fs::dir_create(directory)
  k <- evidence$resultats$indicateurs$indicateurs
  pages <- dashboard_pages()
  k$page <- vapply(k$id, function(id) names(pages)[vapply(pages, function(ids) id %in% ids, logical(1))], character(1))
  dims <- list(DimIndicateur = unique(k[c("id", "libelle", "famille", "unite", "page")]),
    DimAnnee = data.frame(annee_universitaire = sort(unique(k$annee_universitaire))),
    DimDiplome = data.frame(type_diplome = sort(unique(k$type_diplome))))
  fact <- k[setdiff(names(k), c("libelle", "famille", "unite", "page"))]
  objects <- c(list(FactIndicateur = fact), dims)
  files <- as.character(fs::path(directory, paste0(names(objects), ".csv")))
  for (i in seq_along(objects)) utils::write.csv(objects[[i]], files[i], row.names = FALSE,
    na = "", fileEncoding = "UTF-8")
  reference <- fs::path(directory, "indicateurs_reference.rds")
  saveRDS(k, reference, version = 3)
  files <- c(files, as.character(reference))
  manifest <- fs::path(directory, "manifest_dashboard.csv")
  utils::write.csv(data.frame(fichier = basename(files), md5 = unname(tools::md5sum(files))),
    manifest, row.names = FALSE)
  c(files, as.character(manifest))
}

#' Serveur testable ; une actualisation echouee retire les anciens resultats
dashboard_server <- function(loader = function() load_pipeline_report("outputs/pipeline_rapport")) {
 function(input, output, session) {
  state <- shiny::reactiveVal(NULL)
  error <- shiny::reactiveVal(NULL)
  refresh <- function() {
    tryCatch({ state(loader()); error(NULL) }, error = function(e) {
      state(NULL); error(conditionMessage(e))
    })
  }
  shiny::observeEvent(input$refresh, refresh(), ignoreNULL = FALSE)
  data <- shiny::reactive({
    shiny::validate(shiny::need(is.null(error()), paste("Actualisation refusee :", error())))
    shiny::req(state())
    state()$resultats$indicateurs$indicateurs
  })
  shiny::observe({
    shiny::req(input$page)
    years <- sort(unique(dashboard_filter(data(), input$page)$annee_universitaire))
    shiny::updateSelectInput(session, "year", choices = years, selected = tail(years, 1L))
  })
  shiny::observeEvent(data(), shiny::updateSelectInput(session, "diploma",
    choices = c("Tous", sort(unique(dashboard_filter(data(), "insertion")$type_diplome)))))
  filtered <- shiny::reactive({
    shiny::req(input$page, input$year)
    dashboard_filter(data(), input$page, input$year, input$diploma)
  })
  output$notice <- shiny::renderText(if (is.null(error()))
    "Exports verifies. Donnees synthetiques, gel au 30/09/2026." else
    paste("Donnees indisponibles :", error()))
  output$table <- DT::renderDT({
    x <- filtered()
    x$type_diplome[x$type_diplome == "non_applicable"] <- "Champ scolaire"
    labels <- c(diffusable = "Diffusable", non_observable = "Non observable (fin de période)",
      effectif_insuffisant = "Effectif insuffisant", denominateur_nul = "Dénominateur nul")
    x$statut <- unname(labels[x$statut])
    x <- x[c("libelle", "annee_universitaire", "type_diplome", "numerateur", "denominateur",
      "couverture_pct", "valeur", "unite", "statut")]
    names(x) <- c("Indicateur", "Année", "Diplôme", "Numérateur", "Dénominateur",
      "Couverture (%)", "Valeur", "Unité", "Diffusion")
    widget <- DT::datatable(x, rownames = FALSE, options = list(pageLength = 10, scrollX = TRUE,
      columnDefs = list(list(targets = "_all", defaultContent = "Non disponible")),
      language = list(search = "Rechercher :", lengthMenu = "Afficher _MENU_ lignes",
        info = "_START_ à _END_ sur _TOTAL_ lignes", infoEmpty = "Aucune ligne",
        zeroRecords = "Aucune observation", paginate = list(previous = "Précédent", "next" = "Suivant"))),
      caption = "Les valeurs absentes restent non disponibles. Le statut précise les censures et les exclusions.")
    DT::formatRound(widget, columns = c("Couverture (%)", "Valeur"), digits = 2, mark = " ", dec.mark = ",")
  })
  output$chart <- shiny::renderPlot({
    x <- filtered()
    shiny::validate(shiny::need(nrow(x) > 0L, "Aucune observation pour ces filtres."))
    x$type_diplome[x$type_diplome == "non_applicable"] <- "Champ scolaire"
    plot <- ggplot2::ggplot(x, ggplot2::aes(type_diplome, valeur, fill = libelle)) +
      ggplot2::geom_col(position = "dodge", na.rm = TRUE) +
      ggplot2::facet_wrap(~libelle, labeller = ggplot2::label_wrap_gen(width = 30)) +
      ggplot2::labs(x = "Champ", y = if (all(x$id == "I02")) "Inscriptions (effectif)" else "Taux (%)", fill = NULL) +
      ggplot2::theme_minimal(base_size = 14) + ggplot2::theme(legend.position = "none", strip.text = ggplot2::element_text(size = 12))
    if (!all(x$id == "I02")) plot <- plot + ggplot2::scale_y_continuous(limits = c(0, 100))
    plot
  })
  output$download <- shiny::downloadHandler(filename = function() "indicateurs_selection.csv",
    content = function(file) utils::write.csv(filtered(), file, row.names = FALSE, na = "", fileEncoding = "UTF-8"))
 }
}
