# Observatoire_Statistique_UPEC

Démonstrateur personnel indépendant de l'UPEC. Les futures données seront
entièrement synthétiques ; aucun résultat ne devra être présenté comme officiel.

## Contexte et problématique

Ce projet simule une commande d'observatoire universitaire inspirée des missions
de suivi étudiant, d'évaluation et de pilotage des formations de l'UPEC. Il vise
à rendre les traitements et les indicateurs compréhensibles par des utilisateurs
non spécialistes des statistiques.

**Problématique :** comment exploiter les données de scolarité et les enquêtes
étudiantes pour comprendre les parcours universitaires, évaluer les formations
et contribuer au pilotage de l'offre de formation ?

### Population et données prévues

La simulation visera environ **15 000 étudiants fictifs distincts**, suivis sur
**2023-2024, 2024-2025 et 2025-2026**. Ce volume désigne des personnes, pas un
nombre d'inscriptions par année ; les effectifs annuels dépendront des entrées
et des sorties simulées. Un identifiant stable permettra le suivi longitudinal.

Les tables prévues concernent les étudiants, formations, inscriptions,
résultats, parcours, évaluations, diplômes et devenir des diplômés. Les graines,
relations statistiques simulées et anomalies contrôlées seront documentées.
La version destinée aux tests de qualité sera séparée de la base cohérente.
Aucune donnée personnelle réelle ne sera utilisée.

| Rôle | Variables envisagées |
|---|---|
| Cible principale | Réussite académique, dont la définition opérationnelle reste à valider dans le protocole |
| Cibles secondaires | Passage, redoublement, réorientation, satisfaction, diplomation et situation des diplômés |
| Variables explicatives | Formation, niveau, année universitaire, parcours antérieur, type de baccalauréat et statut boursier fictif ; autres caractéristiques seulement si justifiées |

### Objectifs et règles d'interprétation

1. Caractériser les inscriptions et la population étudiante.
2. Décrire la réussite et comparer les cohortes et parcours.
3. Étudier les passages, redoublements et réorientations.
4. Concevoir et exploiter des enquêtes d'évaluation des formations et de devenir
   des diplômés, avec une démarche compatible avec LimeSurvey.
5. Produire des indicateurs d'autoévaluation et des restitutions de pilotage.
6. Automatiser les traitements, tracer les contrôles et tester le code métier.

Chaque indicateur devra préciser sa finalité, sa population, son unité, son
numérateur, son dénominateur, sa période, ses exclusions, le traitement des
valeurs manquantes et ses limites. Distinguer étudiants et inscriptions,
validation annuelle et diplôme, réorientation et sortie observée, non-réponse
et réponse négative. Les analyses exploratoires décriront des associations ;
elles ne fourniront pas de preuve causale. Les choix méthodologiques détaillés
seront soumis à validation lors du cadrage statistique.

## État du projet et livrables

| Élément | État actuel |
|---|---|
| Configuration VS Code, architecture et environnement `renv` | En place |
| Fonctions de chemins et tests associés | Disponibles |
| Cahier des charges, protocole et dictionnaires | À rédiger dans `docs/` |
| Données et contrôles de qualité | À construire après validation du cadrage |
| Analyses descriptives, longitudinales et d'enquêtes | À réaliser |
| Modélisation exploratoire | À justifier selon les données et les questions |
| Pipeline `targets` | Package installé ; pipeline à créer |
| Tableau de bord Shiny | À développer dans `dashboard/` |
| Notebooks et rapport Quarto | À rédiger ; CLI et package R disponibles |
| Note de pilotage et présentation orale | À produire dans `reports/` |
| Git et GitHub | Dépôt local initialisé ; premier commit et dépôt distant à préparer |

**Aucune donnée n'a encore été générée et aucun résultat statistique n'est
disponible.** La reproduction complète des analyses sera documentée à mesure
que les points d'entrée seront créés.

## Démarrage sous Windows

Installer R, Visual Studio Code, Git et le CLI Quarto si nécessaire. La référence
actuellement verrouillée est **R 4.6.1**, avec **Quarto CLI 1.10.18** vérifié.
Installer l'extension R `REditorSupport.r` et l'extension Quarto `quarto.quarto`
depuis les recommandations VS Code. Aucun fichier `.Rproj` n'est nécessaire.
Rtools n'est requis que si des packages doivent être compilés depuis leurs sources.

Ouvrir ce dossier dans VS Code, puis ouvrir un **nouveau** terminal PowerShell
pour appliquer les variables de locale définies dans `.vscode/settings.json`.
L'extension R utilise le chemin local configuré dans ce fichier. Adapter ce chemin
si R est installé ailleurs ; aucun chemin absolu ne doit entrer dans le code métier.

Dans R, à la racine du projet :

```r
renv::restore()
renv::status()
```

Au démarrage normal, le chargeur `renv` peut télécharger sa version requise si
elle manque. Une première restauration nécessite un accès réseau et des droits
d'écriture dans la bibliothèque et le cache locaux. Ne pas copier les secrets
d'une autre machine ; `.Renviron.example` fournit seulement un exemple de locale.

`DESCRIPTION` déclare les dépendances actuellement nécessaires. Les dépendances
d'analyse, de pipeline et de restitution seront ajoutées lors de leur utilisation.
Le socle de la phase A comprend `renv`, `here`, `fs`, `tidyverse`, `janitor`,
`testthat`, `targets` et `quarto`. Leurs dépendances sont gérées par `renv`.
`renv.lock` fixe les versions ; les bibliothèques locales ne sont pas versionnées.
L'extension Quarto est recommandée dans `.vscode/extensions.json`.

### Gestion des dépendances avec renv

Le projet possède déjà son environnement : ne pas relancer `renv::init()`.
Au démarrage normal de R depuis la racine, `.Rprofile` charge
`renv/activate.R`, puis la bibliothèque isolée du projet. Un lancement avec
`--vanilla` ignore cette activation ; les packages visibles peuvent alors différer.

- `renv::restore()` remet la bibliothèque du projet en conformité avec
  `renv.lock`. À utiliser après récupération du dépôt ou d'un nouveau verrouillage ;
  examiner les changements proposés avant de les accepter.
- `renv::snapshot()` enregistre dans `renv.lock` les versions des dépendances
  déclarées dans `DESCRIPTION`, selon le mode `explicit` configuré ici. À utiliser
  après un ajout ou une mise à jour volontaire, puis contrôler le diff Git.
- `renv::status()` compare les dépendances déclarées, la bibliothèque et le
  verrouillage. Il doit être exécuté dans l'environnement activé du projet.

Versionner `.Rprofile`, `DESCRIPTION`, `renv.lock`, `renv/activate.R` et
`renv/settings.json`. La bibliothèque et les caches restent locaux et ignorés
par Git. Le verrouillage ne remplace pas l'installation de la version de R
requise ni celle du CLI Quarto. Le cache de packages peut se trouver hors du
dossier projet ; un terminal restreint peut nécessiter une autorisation d'accès.

### Tâches VS Code

Dans **Terminal > Exécuter la tâche**, choisir :

- **R : diagnostic sans activation renv** pour exécuter `scripts/check_environment.R`
  dans le terminal intégré et vérifier R et Quarto indépendamment de `renv`.
- **R : executer le script actif** pour lancer le fichier R ouvert, à la racine
  du projet, avec activation normale de `.Rprofile` et de `renv`.
- **Quarto : version** pour vérifier le CLI.
- **Quarto : rendre le document actif** pour rendre le fichier `.qmd` ouvert.

Les tâches R attendent un fichier `.R` enregistré ; la tâche de rendu attend un
fichier `.qmd` enregistré. Le diagnostic de base ne valide pas la bibliothèque
isolée de `renv`, qui fait l'objet d'un contrôle distinct.

## Organisation

- `config/` : paramètres de simulation et de traitement à définir.
- `R/` : fonctions métier réutilisables.
- `scripts/` : points d'entrée des traitements.
- `data/raw/`, `data/interim/`, `data/processed/` : données originales, intermédiaires et finales.
- `data/public/synthetic/` : sélection documentée de CSV synthétiques publiables.
- `docs/` : cahier des charges, protocole et dictionnaires.
- `notebooks/` : analyses Quarto.
- `tests/testthat/` : tests métier.
- `dashboard/` : futur tableau de bord Shiny.
- `app/` : dossier initial conservé, contenant uniquement `.gitkeep` ; utiliser
  `dashboard/` pour les développements Shiny à venir.
- `reports/` : sources des restitutions.
- `outputs/` : résultats générés.

Les données de travail et les résultats générés sont exclus de Git et devront
être reproductibles. Une exception explicite autorise les petits CSV entièrement
synthétiques sélectionnés dans `data/public/synthetic/`, avec leur documentation.
Ce dossier ne contient encore aucune donnée. Son README précise les informations
à fournir avant publication ; les règles Git ne vérifient pas le contenu des CSV.
Les secrets (`.Renviron`, `.env`, clés, dossiers de secrets) et la configuration
`config/local/` sont exclus. Les fichiers exemples sans secret peuvent être suivis.
Utiliser `here::here()` pour les chemins dans R et `fs` pour les opérations sur les fichiers.
Les fonctions communes sont dans `R/utils/paths.R` :

```r
source(here::here("R", "utils", "paths.R"))
data_path("raw", "etudiants.csv")
data_path("processed", "indicateurs.csv")
output_path("figures", "reussite.png")
```

Ces exemples construisent des chemins ; ils ne créent pas les fichiers.
Les composants absolus et `..` sont refusés. Aucun chemin Windows propre à
la machine ne doit figurer dans les fonctions métier.
Pour vérifier les fonctions depuis R activé à la racine du projet :

```r
source(here::here("R", "utils", "paths.R"))
testthat::test_file(
  here::here("tests", "testthat", "test-paths.R"),
  stop_on_failure = TRUE
)
```

## Reproduire les contrôles disponibles

Depuis la racine, dans un nouveau terminal PowerShell de VS Code, le diagnostic
de base peut être lancé avec le chemin R configuré localement :

```powershell
$settings = Get-Content .vscode/settings.json -Raw | ConvertFrom-Json
& $settings.'r.rpath.windows' --vanilla --slave --file=scripts/check_environment.R
quarto --version
git status --short --branch
```

Le diagnostic utilise `--vanilla` pour contrôler R et Quarto indépendamment de
`renv`. Pour contrôler l'environnement du projet, ouvrir ensuite une session R
normale à la racine, vérifier `renv::status()`, puis exécuter les tests de chemins
présentés ci-dessus. Sur une nouvelle machine, commencer par `renv::restore()`.

### Pipeline, tableau de bord et rapports à venir

Le futur fichier `_targets.R` orchestrera les traitements. Une fois ce fichier
créé et validé, `targets::tar_make()` lancera le pipeline depuis la racine.
Cette commande ne constitue pas encore un point d'entrée exécutable du projet.

Le tableau de bord sera lancé avec `shiny::runApp("dashboard")` après création
de l'application et ajout de `shiny`, `bslib` et `DT` aux dépendances du projet.
La présence éventuelle d'un package dans une bibliothèque générale ne suffit
pas à le rendre disponible dans `renv`.

Les documents `.qmd` seront placés dans `notebooks/` et `reports/`. Leur rendu
passera par la tâche VS Code **Quarto : rendre le document actif** ou par
`quarto render` suivi du chemin du document existant. Les calculs réutilisables
resteront dans `R/` ; les notebooks expliqueront les méthodes et résultats.

Les définitions des indicateurs et les règles de simulation restent à valider
avant toute génération de données.
