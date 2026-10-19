# Depuis la racine : shiny::runApp('dashboard', host = '127.0.0.1').
source(here::here("R", "utils", "paths.R"))
source(here::here("R", "pipeline", "pipeline.R"))
source(here::here("R", "pipeline", "report.R"))
source(here::here("R", "dashboard", "dashboard.R"))
ui <- bslib::page_sidebar(
  title = "Observatoire statistique — demonstration independante de l'UPEC",
  theme = bslib::bs_theme(version = 5, bootswatch = "flatly"),
  sidebar = bslib::sidebar(
    shiny::strong("Donnees entierement synthetiques — aucun resultat officiel"),
    shiny::selectInput("page", "Vue", choices = c("Inscriptions" = "inscriptions",
      "Reussite" = "reussite", "Parcours" = "parcours", "Enquetes" = "enquetes", "Insertion" = "insertion")),
    shiny::selectInput("year", "Annee de reference", choices = NULL),
    shiny::conditionalPanel("input.page == 'insertion'",
      shiny::selectInput("diploma", "Diplome de reference", choices = c("Tous", "licence", "master"))),
    shiny::actionButton("refresh", "Verifier et actualiser"),
    shiny::downloadButton("download", "Telecharger la selection")),
  bslib::card(shiny::textOutput("notice")),
  bslib::card(shiny::plotOutput("chart", height = "360px")),
  bslib::card(DT::DTOutput("table")),
  bslib::card(shiny::h4("Bien lire les resultats"),
    shiny::p("Validation et diplome ont des populations differentes. Une sortie observee n'est pas un abandon."),
    shiny::p("Non-reponse et reponse negative sont distinctes. Les transitions finales sont censurees. Aucune conclusion causale."),
    shiny::p("L'actualisation relit les exports controles. Elle ne lance pas d'analyse. Les filtres par formation ne sont pas disponibles dans cette premiere synthese.")))
shiny::shinyApp(ui, dashboard_server())
