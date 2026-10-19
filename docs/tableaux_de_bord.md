# Tableaux de bord Shiny et Power BI — étape 30

## Accès visuel au projet

Le [site public du projet](https://cmadjeki-dot.github.io/Observatoire_Statistique_UPEC/)
propose cinq vues interactives des exports contrôlés et le rapport final.
Le [guide d’accès](site_github.md) distingue ce site, Shiny local et Power BI
Desktop. Le site n’héberge pas une session Shiny ni Power BI Service.

Projet personnel indépendant de l'UPEC, données entièrement synthétiques.
Les cinq vues sont inscriptions, réussite, parcours, enquêtes et insertion.
Les filtres portent sur l'année de référence et, pour l'insertion, le type du
diplôme de référence. Cette première version restitue les agrégats d'ensemble :
elle ne propose pas de filtre par formation non disponible dans ces exports.

## Actualiser les données

Depuis la racine dans PowerShell, utiliser la tâche VS Code
« R : actualiser les tableaux de bord », ou :

```powershell
& 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe' --no-save --no-restore scripts/refresh_dashboards.R
```

Ce script lance le pipeline complet contrôlé et ses rapports, puis exporte dans
`outputs/pipeline_dashboard/` quatre CSV UTF-8 à virgules et point décimal :
`FactIndicateur` (33 lignes), `DimIndicateur` (10), `DimAnnee` (3), `DimDiplome` (3).
Il conserve aussi une référence RDS, un manifeste MD5 et un statut d'actualisation.
Un échec inscrit `echec` ; les anciens fichiers ne constituent pas un succès
courant. Ne pas lancer deux actualisations simultanées du même magasin targets.
Cette automatisation locale n'installe aucune tâche planifiée et ne publie rien.

## Shiny

Lancer la tâche VS Code « R : tableau de bord Shiny local », puis ouvrir
`http://127.0.0.1:3838`. Arrêter avec Ctrl+C dans le terminal.
L'aperçu démarré pour la recette est également accessible à cette adresse tant
qu'il reste actif. La tâche « Shiny : arreter l'apercu de recette » arrête
uniquement cet aperçu ; l'utiliser avant une nouvelle instance sur le même port.

```powershell
& 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe' --no-save --no-restore scripts/run_shiny.R
```

L'application `dashboard/app.R` utilise `bslib` et `DT`. Le code réutilisable est
dans `R/dashboard/dashboard.R`. Le bouton d'actualisation relit et vérifie les
exports ; il ne réestime rien. Si la lecture échoue, les anciennes données sont
retirées de la session. Le tableau affiche numérateur, dénominateur, couverture,
unité et statut ; le téléchargement conserve les types et les valeurs manquantes.
Le choix d'année s'adapte au champ de la page, notamment au dernier devenir mûr.
Les valeurs du tableau sont affichées à deux décimales, avec commandes en
français ; le téléchargement conserve la précision des données. Les taux
graphiques utilisent une échelle de 0 à 100 et les statuts sont explicités.

## Projet Power BI versionnable

`powerbi/Observatoire.pbip` contient un rapport PBIR et un modèle TMDL, sous
forme de fichiers texte modifiables et versionnables.
Le générateur est `R/dashboard/powerbi.R`, lancé par :

```powershell
& 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe' --no-save --no-restore scripts/build_powerbi.R
```

Cette génération est une opération de construction ; la relancer écrase les
définitions générées. Après personnalisation dans Desktop, utiliser seulement
le script d'actualisation des données pour conserver les modifications du rapport.

Le paramètre M `DataFolder` est dérivé du dossier du projet au moment de la
construction. Il est dans `definition/expressions.tmdl`, exclu de Git comme
configuration locale. Sur un autre poste, reconstruire ce paramètre avant ouverture.
Aucun chemin Windows absolu n'est codé en dur dans les fonctions métier R.

Le modèle comporte trois relations plusieurs-vers-un, à sens unique :

| Fait | Dimension | Clé |
|---|---|---|
| FactIndicateur | DimIndicateur | id |
| FactIndicateur | DimAnnee | annee_universitaire |
| FactIndicateur | DimDiplome | type_diplome |

Chaque page a un filtre métier sur `DimIndicateur[page]`, un segment d'année,
une courbe par indicateur et un tableau détaillé. Insertion ajoute le segment
de diplôme. Les types scolaires `non_applicable` ne sont pas des diplômes manquants.
Pour une lecture confortable dans Desktop, replier les volets d'édition
Filtres, Visualisations et Données, puis ajuster la page à la largeur disponible.

La mesure `Valeur controlee` exige une seule année et un seul indicateur dans
chaque contexte. I02 est un effectif ; les taux sont calculés par
`100 * SUM(numerateur) / SUM(denominateur)`, jamais par moyenne de taux.
Tout groupe comportant un statut non diffusable reste vide. Les mesures
numérateur, dénominateur et couverture accompagnent la valeur. Les taux de
types de diplôme d'une même année utilisent les sommes de leurs effectifs.
Un total mélangeant années ou indicateurs reste vide.
La mesure textuelle `Lecture du statut` conserve les lignes censurées dans
le tableau même lorsque toutes leurs valeurs numériques sont vides.

Power Query utilise le paramètre local, les types explicites et la culture
`en-US` des CSV. Une chaîne vide numérique devient `null`, pas zéro. Les requêtes
refusent un statut d'export ou de pipeline différent de `succes`. Avant toute
actualisation dans Desktop, lancer l'actualisation R : elle vérifie aussi les
empreintes des sources, ce que les seules requêtes M ne recalculent pas.
Dans Desktop, utiliser ensuite « Actualiser ». Aucun compte Service, passerelle,
publication ou abonnement n'est configuré.

## Recette et limites de validation

Les tests R couvrent les filtres Shiny, les censures et le retrait après échec.
`scripts/check_dashboard_exports.R` vérifie clés, relations, empreintes et les
33 valeurs recalculées depuis les CSV. Le serveur Shiny a fait l'objet d'un
contrôle HTTP local ; `testServer()` exerce ses réactifs.

`scripts/validate_powerbi.py` utilise les schémas Microsoft publics. Son outil
Python est isolé sous `outputs/powerbi_validation/python`, sans installation
globale ; la dépendance du validateur est dans `scripts/requirements-powerbi-validation.txt`.
`scripts/validate_powerbi_model.ps1` désérialise TMDL avec la bibliothèque
Microsoft du Desktop installé et vérifie les noms des mesures et colonnes.

Le moteur Microsoft d'une instance de recette dédiée a réellement exécuté
une actualisation Power Query puis DAX sur le modèle isolé, puis sur le projet
final chargé depuis son fichier PBIP. Les résultats
sont rapprochés de R par `scripts/check_powerbi_native_results.R` : 33 valeurs,
numérateurs et dénominateurs, y compris les NA. Le garde-fou multi-années est
également exécuté, ainsi que le filtre Parcours/2025-2026 conservant deux lignes
censurées. Les preuves sont dans `outputs/powerbi_validation/`.
Les cinq onglets ont ensuite été sélectionnés dans Desktop après l'actualisation
de son interface ; les captures et `navigation_pages.csv` documentent ce contrôle.
Les segments ont aussi été actionnés dans l'interface : Insertion, année
2024-2025 et diplôme licence donnent exactement trois lignes, consignées dans
`filtres_interface.json` et la capture `Insertion_filtree.png`.
La validation métier des libellés et de l'usage des indicateurs vous revient.

Pour reproduire la recette native, le script `start_powerbi_validation.ps1`
ouvre une instance dédiée ; après l'ouverture du rapport,
`find_powerbi_validation_workspace.ps1` identifie son seul workspace neuf.
Lancer ensuite `test_powerbi_native.ps1 -LaunchFile desktop_report_launch.json
-WorkspaceFile workspace_report.txt -RequireProject`, puis le rapprochement R.
Ne pas utiliser le moteur d'un autre rapport. Les scripts PowerShell du poste
sont soumis à une politique d'exécution restrictive ; les contrôles ont été
lancés avec `powershell -NoProfile -ExecutionPolicy Bypass -File ...`, pour ce
processus uniquement, sans changement de politique persistante.

Dans Desktop, une ouverture initiale sans cache peut afficher des bannières
demandant une actualisation. Utiliser le bouton « Actualiser » pour synchroniser
également le cache de l'interface, même après un test du moteur via XMLA.

Les références de format sont la documentation Microsoft
[PBIP/PBIR](https://learn.microsoft.com/en-us/power-bi/developer/projects/projects-report)
et [TMDL](https://learn.microsoft.com/en-us/analysis-services/tmdl/tmdl-overview).
Les fichiers `.platform` complètent l'identification des éléments ; une
validation JSON seule ne prouve pas le chargement natif du rapport.

## Interprétation

Les taux gardent leurs populations propres. Une validation n'est pas un diplôme,
une sortie observée n'est pas un abandon et une non-réponse n'est pas un avis
négatif. Les transitions finales restent censurées. Aucun graphique ne doit
être présenté comme officiel, causal ou utilisable pour un ciblage individuel.
