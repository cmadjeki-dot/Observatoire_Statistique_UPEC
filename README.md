# Observatoire_Statistique_UPEC

**Démonstrateur personnel indépendant de l’UPEC. Toutes les données sont synthétiques et tous les résultats sont non officiels.**

Le projet simule une commande d’observatoire universitaire : suivre les inscriptions,
la réussite et les parcours, exploiter les enquêtes et restituer des indicateurs
accessibles aux responsables sans compétence statistique.

**Problématique :** comment articuler données de scolarité et enquêtes pour comprendre
les parcours, évaluer les formations et contribuer au pilotage de l’offre de formation ?

## Données et règles de lecture

La simulation couvre **15 000 étudiants distincts**, **31 816 inscriptions** et trois
années universitaires : 2023-2024, 2024-2025 et 2025-2026. Onze tables normalisées
relient étudiants, formations, inscriptions, résultats, parcours, invitations et
réponses d’évaluation, décisions de diplôme, diplômes et devenir des diplômés.
Les identifiants restent stables. Les graines et règles sont définies dans
[config/simulation.R](config/simulation.R) et le [plan de simulation](docs/plan_simulation.md).
Une copie avec 50 anomalies contrôlées est distincte de la base cohérente.

La cible principale est la validation annuelle parmi les décisions connues ; la
couverture est publiée séparément. Les cibles secondaires sont passage,
redoublement, réorientation, satisfaction, diplomation et devenir. Formation,
niveau, baccalauréat, parcours antérieur et statut boursier fictif servent aux
analyses descriptives ou exploratoires.

- Une inscription annuelle n’est pas une personne distincte sur toute la période.
- Une validation annuelle n’est pas une obtention de diplôme.
- Une sortie observée n’est pas une preuve d’abandon ; la dernière transition est censurée.
- Une non-réponse n’est pas une réponse négative ; les diplômés non encore éligibles ne sont pas des non-répondants.
- Un dénominateur nul ou une observation indisponible reste manquant, jamais zéro.
- Les associations simulées ne démontrent aucune causalité ni propriété de l’UPEC réelle.

## Livrables effectivement réalisés

| Livrable | État et point d’entrée |
|---|---|
| Environnement VS Code et `renv` | Configuration, dépendances déclarées et lockfile disponibles |
| Cadrage professionnel | [Cahier des charges](docs/cahier_des_charges.md), [protocole](docs/protocole_statistique.md), [données](docs/dictionnaire_donnees.md) et [indicateurs](docs/dictionnaire_indicateurs.md) |
| Génération, qualité et préparation | Fonctions R, anomalies tracées, contrôles avant/après et tests |
| Analyses descriptives, longitudinales et enquêtes | Notebooks 01 à 11 et fonctions métier réutilisables |
| Modélisation | GLM logistique exploratoire, diagnostics, test interne et modèle RDS |
| Faisabilité causale | Hypothèses examinées ; aucun effet causal estimé |
| Indicateurs et recommandations | Dix indicateurs, 33 lignes contrôlées et huit constats de pilotage |
| Pipeline `targets` | Modes préparé, reconstruction et reconstruction avec rapports consommateurs |
| Shiny | Cinq vues, filtres, tableaux, graphiques et téléchargement |
| Power BI | Projet PBIP/PBIR/TMDL : quatre tables, trois relations et cinq mesures ; cinq pages testées dans Desktop |
| Rapports et note de pilotage | Deux sources dans `reports/`, HTML et manifestes produits par le pipeline |
| Rapport final | [Source Quarto](docs/rapport_final.qmd), HTML rendu et vérifié ; PDF non produit faute de LaTeX |
| Présentation orale | [Diaporama Quarto](reports/presentation_orale.qmd), notes orateur et rendu HTML Reveal.js |
| Git/GitHub | Sources publiées sur [GitHub](https://github.com/cmadjeki-dot/Observatoire_Statistique_UPEC), branche `main`, historiques local et distant conservés |

## Installation dans VS Code sous Windows

L’environnement utilisé est **R 4.6.1** et **Quarto CLI 1.10.18**.
`DESCRIPTION` exige R >= 4.6.0 ; privilégier la version de référence pour reproduire
le verrouillage. Installer séparément R, VS Code, Git et Quarto CLI.
L’extension R `REditorSupport.r` et l’extension Quarto `quarto.quarto` sont
recommandées dans `.vscode/extensions.json`. Aucun `.Rproj` n’est nécessaire.
Rtools n’est nécessaire que pour compiler des packages depuis leurs sources.
Power BI Desktop est requis pour ouvrir et actualiser le projet Power BI.
LaTeX reste optionnel pour le PDF. Python ne sert qu’à la recette optionnelle des
schémas Power BI, pas au pipeline analytique.

Ouvrir la racine du projet dans VS Code. Adapter les chemins des exécutables
locaux dans `.vscode/settings.json` et, si nécessaire, `.vscode/tasks.json`.
Les fonctions métier utilisent `here` et `fs`, sans chemin Windows propre au poste.
Un nouveau terminal intégré applique la locale configurée ; hors de ce terminal :

```powershell
$env:LANG = 'fr_FR.UTF-8'
$env:LC_ALL = 'fr_FR.UTF-8'
```

Ouvrir une session R normale **depuis la racine**, puis :

```r
renv::restore()
renv::status()
```

`.Rprofile` active la bibliothèque isolée via `renv/activate.R`. Ne pas réinitialiser
avec `renv::init()`. Une première restauration nécessite le réseau et des droits
d’écriture dans la bibliothèque et le cache locaux. Un lancement `--vanilla`
ignore cette activation et ne convient pas aux traitements habituels.

`DESCRIPTION` déclare `renv`, `here`, `fs`, `lubridate`, `tidyverse`, `janitor`,
`knitr`, `rmarkdown`, `skimr`, `testthat`, `targets`, `quarto`, `withr`, `yaml`,
`shiny`, `bslib`, `DT` et `jsonlite`. `renv.lock` fixe leurs versions et dépendances.
Le package R `quarto` ne remplace pas le CLI Quarto.

- `renv::restore()` restaure les versions du lockfile.
- `renv::status()` contrôle la cohérence de la bibliothèque, des déclarations et du lockfile.
- `renv::snapshot()` met à jour le lockfile après un changement volontaire de dépendances ; contrôler ensuite le diff Git.

## Reproduction complète depuis les graines

Après restauration, dans R à la racine :

```r
testthat::test_dir("tests/testthat", stop_on_failure = TRUE)
source("scripts/refresh_dashboards.R")
```

Ce point d’entrée reconstruit les données, injecte et contrôle les anomalies,
nettoie, prépare les tables, recalcule les analyses et les rapports de pilotage,
puis exporte les tables des tableaux de bord. **Il ne nécessite pas de données
préexistantes dans `data/raw/` ou `data/processed/`.** Il ne rend pas le rapport
final et ne lance pas les interfaces.

Les calculs et leur magasin sont dans `outputs/pipeline_rapport/` ; les quatre
CSV destinés aux tableaux de bord sont dans `outputs/pipeline_dashboard/`.
Les sauvegardes canoniques de `data/` restent préservées. Ne pas lancer deux
processus sur le même magasin `targets` simultanément.

Pour lancer séparément les modes disponibles :

| Script R à exécuter avec `source()` | Entrée | Sortie |
|---|---|---|
| `scripts/run_pipeline.R` | Tables déjà préparées dans `data/processed/` | `outputs/pipeline/` |
| `scripts/run_reconstruction.R` | Graines et configuration | `outputs/pipeline_reconstruction/` |
| `scripts/run_reports.R` | Graines et configuration, avec rapports consommateurs | `outputs/pipeline_rapport/` |
| `scripts/refresh_dashboards.R` | Mode précédent puis exports | `outputs/pipeline_rapport/` et `outputs/pipeline_dashboard/` |

Les lanceurs configurent `_targets.R`, vérifient `renv` et enregistrent statut et
journal. Préférer ces points d’entrée à un `targets::tar_make()` nu, qui ne met
pas à jour le journal d’orchestration. Les relances réutilisent les cibles valides.
Seuls un dernier statut `succes`, des empreintes conformes et un contrôle qualité
conforme autorisent la consommation des exports. Un échec peut laisser des
anciens fichiers sur disque : leur présence ne vaut pas succès.
Détails : [pipeline targets](docs/pipeline_targets.md).

## Tests et contrôles

```r
testthat::test_dir("tests/testthat", stop_on_failure = TRUE)
source("scripts/check_dashboard_exports.R")
renv::status()
```

La suite vérifie dimensions, clés, types, domaines, temporalité, reproductibilité,
anomalies, nettoyage, indicateurs, modèles, pipeline et comportement Shiny.
La dernière recette complète des tableaux de bord a obtenu **976 assertions
réussies, sans échec, erreur ni avertissement**. Après création du rapport final,
les six assertions ciblées du lecteur de rapports ont également réussi.
Ces nombres décrivent les recettes exécutées, pas une garantie des exécutions futures.

Les recettes complémentaires `scripts/check_pipeline.R`,
`scripts/check_reconstruction.R` et `scripts/check_reports.R` testent les relances,
la concordance et les échecs contrôlés ; consulter leurs prérequis dans la
documentation avant lancement. Certains scénarios comparent des archives de
notebooks, absentes d’un dossier neuf. Le parcours de reproduction principal
ci-dessus ne dépend pas de ces archives.

## Notebooks pédagogiques et données canoniques

Les fonctions métier sont dans `R/` ; les notebooks expliquent les méthodes sans
les dupliquer. Pour reconstruire aussi les sauvegardes canoniques et les archives
pédagogiques, rendre les notebooks dans l’ordre depuis la racine :

| Notebook | Contenu | Dossier HTML sous `outputs/` |
|---|---|---|
| [00](notebooks/00_cadrage_du_projet.qmd) | Cadrage | `cadrage/` |
| [01](notebooks/01_generation_des_donnees.qmd) | Génération et sauvegarde brute | `generation/` |
| [02](notebooks/02_importation_description.qmd) | Importation, types et distributions | `importation/` |
| [03](notebooks/03_controle_qualite.qmd) | Contrôle des deux variantes | `qualite/` |
| [04](notebooks/04_nettoyage.qmd) | Nettoyage et préparation | `nettoyage/` |
| [05](notebooks/05_analyse_descriptive.qmd) | Inscriptions, réussite et transitions | `descriptive/` |
| [06](notebooks/06_modelisation.qmd) | GLM et validation interne | `modelisation/` |
| [07](notebooks/07_evaluation_formations.qmd) | Évaluation et devenir | `enquetes/` |
| [08](notebooks/08_analyse_longitudinale.qmd) | Cohortes, transitions et censure | `longitudinal/` |
| [09](notebooks/09_analyse_causale.qmd) | Faisabilité causale | `faisabilite_causale/` |
| [10](notebooks/10_indicateurs_decisionnels.qmd) | Indicateurs prioritaires | `indicateurs/` |
| [11](notebooks/11_restitution_decisionnelle.qmd) | Constats et recommandations | `restitution/` |

Exemple dans PowerShell, avec Quarto et R accessibles :

```powershell
quarto render notebooks/01_generation_des_donnees.qmd --output-dir ../outputs/generation
```

Le chemin `--output-dir` est relatif au dossier du document. Si R n’est pas
détecté, définir `QUARTO_R` vers le dossier `bin` de son installation locale.
Le notebook 01 conserve les bases cohérente et anomale, leur journal et leur
manifeste dans `data/raw/`. Le notebook 04 produit les tables dans `data/processed/`.
Les écritures canoniques refusent de remplacer des objets divergents ; ne pas
supprimer les données pour contourner ce contrôle.

## Tableau de bord Shiny

Après actualisation des données :

```r
source("scripts/run_shiny.R")
```

Ouvrir <http://127.0.0.1:3838>. L’application comporte les vues **inscriptions,
réussite, parcours, enquêtes et insertion**, un filtre d’année et un filtre de
diplôme pour l’insertion. Elle affiche numérateur, dénominateur, couverture et
statut ; son téléchargement conserve la précision des données.
Le bouton d’actualisation relit les résultats contrôlés sans réestimer les analyses.
Arrêter le serveur avec Ctrl+C. Si l’aperçu de recette utilise déjà le port,
la tâche VS Code « Shiny : arreter l’apercu de recette » permet de l’arrêter.
Les cinq vues et les filtres ont été exercés dans un navigateur.

## Power BI et automatisation locale

Les exports contrôlés sont `FactIndicateur.csv` (33 lignes),
`DimIndicateur.csv` (10), `DimAnnee.csv` (3) et `DimDiplome.csv` (3), dans
`outputs/pipeline_dashboard/`. Le modèle utilise trois relations plusieurs-vers-un.
Ses cinq mesures protègent les taux et les agrégations ambiguës ; les valeurs
manquantes et les censures sont conservées. Les pages sont inscriptions,
réussite, parcours, enquêtes et insertion. La version actuelle utilise des
agrégats d’ensemble : aucun filtre par formation n’est disponible.

Sur un nouveau poste, après l’actualisation R, construire le paramètre local :

```r
source("scripts/build_powerbi.R")
```

**Ce générateur réécrit les définitions du rapport et du modèle.** L’utiliser
pour la construction initiale ; préserver toute personnalisation Desktop avant
une reconstruction. Le paramètre local `DataFolder` est généré dans
`powerbi/Observatoire.SemanticModel/definition/expressions.tmdl`, exclu de Git.

Ouvrir ensuite [powerbi/Observatoire.pbip](powerbi/Observatoire.pbip) dans
Power BI Desktop et choisir **Actualiser**. Pour les actualisations suivantes,
exécuter uniquement `scripts/refresh_dashboards.R`, puis Actualiser dans Desktop.
Le contrôle R vérifie les empreintes des sources ; Power Query contrôle les
statuts mais ne recalcule pas ces empreintes.

La recette réalisée comprend cinq pages dans Desktop, 34 fichiers JSON validés,
la désérialisation TMDL, l’actualisation Power Query et 33 résultats DAX concordants
avec R, y compris les valeurs absentes. Les filtres année/diplôme et les protections
multi-années ont été testés. Les preuves locales sont dans
`outputs/powerbi_validation/` et `outputs/shiny_validation/`.
Voir le [guide des tableaux de bord](docs/tableaux_de_bord.md) pour les commandes
de recette. Aucun Power BI Service, passerelle, déploiement Shiny ou tâche
planifiée système n’est configuré ; l’automatisation reste locale et déclenchée.

## Rapport Quarto final et note de pilotage

Le pipeline produit `rapport_pilotage.html` et `note_pilotage.html` dans
`outputs/pipeline_rapport/rapports/`, avec leurs manifestes.
Le [rapport final](docs/rapport_final.qmd) consomme les mêmes résultats contrôlés
sans relancer simulation, nettoyage ou estimation. Après actualisation :

```powershell
quarto render docs/rapport_final.qmd --to html --output-dir ../outputs/rapport_final
```

Résultat : `outputs/rapport_final/rapport_final.html`. Le HTML a été rendu et
contrôlé : 13 sections, dix tableaux, ressources embarquées et sources conformes.
Le manifeste de cette recette est `outputs/rapport_final/manifeste_rendu.csv` ;
un rendu manuel ultérieur ne régénère pas automatiquement ce manifeste.
Le PDF n’a pas été produit : aucun moteur LaTeX n’était disponible lors du contrôle.
Après installation volontaire de LuaLaTeX, le même document prévoit :

```powershell
quarto render docs/rapport_final.qmd --to pdf --output-dir ../outputs/rapport_final
```

## Présentation orale

La [présentation orale](reports/presentation_orale.qmd) propose un parcours de
10 à 12 minutes avec notes orateur, puis échanges. Elle lit les mêmes résultats
contrôlés sans réestimer les analyses. Après actualisation du pipeline :

```powershell
quarto render reports/presentation_orale.qmd --to revealjs --output-dir ../outputs/presentation
```

Ouvrir `outputs/presentation/presentation_orale.html`. Les flèches permettent de
parcourir les diapositives ; la touche S ouvre les notes orateur dans Reveal.js.
La démonstration des interfaces est facultative et nécessite leur lancement local.

Le [conducteur de préparation du jury](notebooks/13_presentation_orale.qmd)
complète le diaporama : dix parties comportent chacune « À afficher », « À dire »,
« Message clé », « Question du jury » et « Réponse ». Pour le rendre :

```powershell
quarto render notebooks/13_presentation_orale.qmd --to html --output-dir ../outputs/presentation
```

Le [discours de 3 à 5 minutes](reports/discours_oral.qmd) fournit un texte naturel
fondé sur les résultats contrôlés et des repères de répétition. Pour le rendre :

```powershell
quarto render reports/discours_oral.qmd --to html --output-dir ../outputs/presentation
```

La [simulation de jury](docs/simulation_jury.qmd) rassemble 30 questions, chacune
avec réponse courte, réponse détaillée et piège à éviter. Pour la rendre :

```powershell
quarto render docs/simulation_jury.qmd --to html --output-dir ../outputs/presentation
```

## Architecture et versionnement

```text
config/                 Simulation et catalogue des indicateurs
R/                      Fonctions métier, qualité, modèles, pipeline et interfaces
scripts/                Lanceurs et recettes
notebooks/              Analyses Quarto 00 à 11
data/raw/               Sauvegardes originales synthétiques
data/interim/           Données intermédiaires
data/processed/         Tables analytiques
data/public/synthetic/  CSV synthétiques sélectionnés pour publication
dashboard/              Application Shiny
powerbi/                Rapport PBIR et modèle TMDL
docs/                   Cadrage, dictionnaires, guides et rapport final
reports/                Rapport et note consommateurs du pipeline
tests/testthat/         Tests unitaires et d’intégration
outputs/                Calculs, exports, rendus, caches et preuves générés
.vscode/                Configuration et tâches du poste
```

Les chemins sont relatifs à la racine ; les utilitaires de `R/utils/paths.R`
refusent les composants absolus et les remontées `..`.

Les données de travail, résultats, caches `targets`/`renv`, paramètres locaux
Power BI et secrets sont exclus par `.gitignore`. Les CSV synthétiques destinés
à être publiés doivent être sélectionnés et documentés dans
`data/public/synthetic/` ; ce dossier ne contient actuellement aucun CSV.
Le dépôt doit suivre le code, les documents, `.Rprofile`, `DESCRIPTION`,
`renv.lock`, `renv/activate.R` et `renv/settings.json`, pas les bibliothèques locales.
Les `.pbix` et caches `.pbi` restent locaux. Les sources sont versionnées et
publiées dans le dépôt GitHub public `cmadjeki-dot/Observatoire_Statistique_UPEC`.
Le remote `origin` désigne ce dépôt ; la branche locale `main` suit `origin/main`.
L’intégration a conservé les deux historiques sans push forcé. Les résultats
ignorés restent à reconstruire localement.

## Limites statistiques et fonctionnelles

L’[audit sur 100](docs/audit_final.md) attribue **84/100** au démonstrateur sur
preuves disponibles, avec réserves explicites. La [validation technique finale](docs/validation_technique_finale.md)
a réussi localement : 976 assertions, audit du code, pipeline, rendus Quarto,
exports, renv et démarrage Shiny. Cette note et cette recette ne valent ni
certification ni validation institutionnelle. Le lanceur est
`scripts/validate_final.R` ; les preuves sont dans `outputs/validation_finale/`.

Le générateur fixe les mécanismes observés : aucun résultat ne se transpose à
une population réelle. Le suivi de trois ans ne décrit pas les trajectoires hors
champ ni les horizons futurs. Les taux d’enquête restent sensibles à la non-réponse.
Les trois items de satisfaction indépendants ne forment pas une échelle
psychométrique. Le GLM est une exploration sur cas complets avec validation
interne, sans usage individuel réel. Aucun effet causal n’est identifié.

Le questionnaire est un prototype documenté pour LimeSurvey ; aucune instance,
import `.lss`, collecte ou invitation réelle n’a été exécuté. Les interfaces sont
testées techniquement ; leur validation métier avec des responsables réels reste
à conduire. Le PDF et les
services de déploiement restent des livrables ou opérations non réalisés.
