# Cahier des charges — version 0.1

Date : 18 octobre 2026. Statut : cadrage initial historique du démonstrateur.
Les décisions opérationnelles sont documentées dans le protocole et les étapes
de réalisation. Leur acceptation dans le projet personnel ne constitue aucune
validation institutionnelle par l’UPEC ni recette métier par ses responsables.

## Commande simulée

Construire un observatoire démonstrateur de la réussite, des parcours, de
l'évaluation des formations et du devenir des diplômés. Ce projet personnel
est indépendant de l'UPEC. Toutes les données seront synthétiques et aucun
résultat ne constituera une statistique officielle.

Les destinataires simulés sont un service de pilotage, les responsables de
formation et les équipes pédagogiques. Les restitutions doivent permettre de
repérer des écarts et de formuler des questions, sans classer automatiquement
les formations ni attribuer des effets causaux aux caractéristiques étudiantes.

## Questions métier

| ID | Question | Livrable attendu |
|---|---|---|
| Q01 | Qui s'inscrit, dans quelles formations et à quels niveaux ? | Effectifs distincts et inscriptions, profils et couverture |
| Q02 | Quelle validation annuelle observe-t-on selon les cohortes ? | Taux à dénominateurs explicites, résultats manquants visibles |
| Q03 | Quels passages, redoublements et changements de formation observe-t-on ? | Matrices de transition et suivi des cohortes |
| Q04 | Comment les répondants évaluent-ils leur formation ? | Réponse, distributions de satisfaction et limites de représentativité |
| Q05 | Quelle est la situation des diplômés répondants à six mois ? | Situations exclusives, emploi et poursuite d'études séparés |
| Q06 | Quels indicateurs peuvent alimenter une autoévaluation ? | Tableau de bord filtrable et note de pilotage contextualisée |

## Périmètre

Environ 15 000 personnes distinctes sur l'ensemble des années 2023-2024,
2024-2025 et 2025-2026. Il ne s'agit ni de 15 000 inscriptions annuelles, ni
d'une cohorte fermée de 15 000 entrants. Des cohortes d'entrée et des populations
annuelles seront définies séparément dans le protocole.

Le premier périmètre proposé couvre L1, L2, L3, M1 et M2, avec des formations
fictives. Les autres cursus, doubles inscriptions, interruptions temporaires
documentées, mobilités et transferts entrants avec crédits antérieurs ne sont
pas simulés dans cette première version. Ces restrictions doivent apparaître
dans chaque restitution. La collecte LimeSurvey réelle, les données réelles et
la publication institutionnelle sont hors périmètre.

## Livrables et ordre de réalisation

1. Valider ce cahier des charges, le protocole, les dictionnaires initiaux et les
   décisions de simulation avant de produire les données.
2. Développer la simulation documentée, ses graines, la base cohérente et une
   copie contenant des anomalies contrôlées ; conserver les données originales.
3. Produire les contrôles de qualité, les tables finales et les indicateurs.
4. Réaliser les analyses descriptives, longitudinales, d'évaluation et de devenir.
5. Évaluer l'intérêt d'une modélisation exploratoire et documenter ses limites.
6. Automatiser avec `targets`, tester avec `testthat` et verrouiller avec `renv`.
7. Livrer le dashboard Shiny, le rapport Quarto, la note de pilotage et la
   présentation orale ; documenter et tester le dépôt avant publication GitHub.
8. Livrer un tableau de bord Power BI et un dispositif d'exports automatisés
   depuis R, avec modèle de données documenté et procédure d'actualisation testée.

Les fonctions réutilisables restent dans `R/`, les paramètres dans `config/`,
les explications dans `notebooks/` et `docs/`, les sources de restitution dans
`reports/`, l'application dans `dashboard/` et les résultats dans `outputs/`.

## Livrable Power BI et automatisation

**Objectif :** fournir aux responsables des outils accessibles sans compétence
statistique. Les pages proposeront des libellés métier, des filtres lisibles,
des définitions courtes, les populations de référence et la date d'actualisation.
Les résultats absents ou non affichables seront expliqués. La mention
« données synthétiques — démonstrateur indépendant de l'UPEC » sera visible.

1. **Exporter les tables d'indicateurs depuis R.** Intégrer les exports au pipeline
   `targets`, après validation des contrôles de qualité. Produire des fichiers
   stables dans `outputs/powerbi/`, avec numérateurs, dénominateurs, effectifs
   manquants et exclusions, clés de dimensions, périodes et version des définitions.
   Documenter l'encodage, les types, la granularité et les valeurs manquantes ;
   joindre un manifeste de génération. Aucun export n'est produit à cette étape.
2. **Construire le modèle de données Power BI.** Définir les tables de faits
   selon leur granularité et les dimensions formation, niveau, année et vague.
   Documenter clés, cardinalités, relations et mesures. Les mesures de taux
   seront fondées sur les numérateurs et dénominateurs compatibles, pas sur une
   moyenne de pourcentages. Les distincts pluriannuels ou les regroupements non
   additifs nécessiteront des exports adaptés, sans sommer les distincts annuels.
3. **Créer les pages inscriptions, réussite, parcours, enquêtes et insertion.**
   Conserver les définitions du dictionnaire, notamment la couverture des résultats,
   les transitions censurées et les non-réponses. La page insertion présentera
   l'emploi hors études et les poursuites d'études avec leurs dénominateurs propres.
4. **Tester les filtres, les mesures et l'actualisation.** Comparer Power BI à R
   pour des filtres simples et combinés, le total, les sélections sans observation,
   les petits effectifs et les années non observables. Tester une reconstruction
   des exports suivie d'une actualisation du rapport et tracer le résultat.

L'automatisation comprendra la génération reproductible des exports, un journal
de succès ou d'échec et une procédure de reprise. Préciser ensuite les modalités
de déclenchement et, si retenue, de planification de l'actualisation Power BI après
audit de l'environnement et des accès disponibles. Distinguer la régénération
des fichiers R de l'actualisation du rapport ; ne pas annoncer cette dernière
comme automatisée avant son test effectif.

Livrer le rapport Power BI éditable, le schéma du modèle, le dictionnaire des
mesures, la procédure d'actualisation et un procès-verbal de recette. Le format
source et son emplacement seront fixés après audit Power BI. Aucun logiciel,
connecteur ou package supplémentaire n'est installé pour ce cadrage.

## Critères de recette

| ID | Critère observable à vérifier lors de l'implémentation |
|---|---|
| C01 | Environ 15 000 identifiants distincts sur l'union des trois années ; cible exacte fixée avant génération |
| C02 | Clés uniques, références valides, domaines et chronologies conformes au dictionnaire |
| C03 | Une inscription principale active au maximum par étudiant et année ; transitions compatibles avec les niveaux |
| C04 | Base cohérente sans violation bloquante ; copie anomale distincte avec journal des injections et détection attendue |
| C05 | Chaque indicateur possède les neuf rubriques du dictionnaire, ses effectifs et ses exclusions |
| C06 | Validation, diplôme, sortie observée et non-réponse ne sont jamais confondus |
| C07 | Tests sur cas limites : absence de répondants, résultat inconnu, dernière année censurée et petit effectif |
| C08 | Même configuration et mêmes graines reproduisent les tables et indicateurs, indépendamment de l'ordre d'exécution |
| C09 | Depuis une copie propre : restauration renv, tests, pipeline et rendu documentés réussissent |
| C10 | Dashboard et rapports donnent les mêmes indicateurs sur le même filtre ; avertissement « données synthétiques » visible |
| C11 | Aucun résultat inventé, secret ou jeu réel dans le dépôt ; les CSV publiables sont documentés et contrôlés |
| C12 | Les limites, les non-réponses et les règles de non-affichage accompagnent les restitutions |
| C13 | Les exports Power BI sont reproductibles via targets, documentés, contrôlés et accompagnés d'un manifeste |
| C14 | Le modèle Power BI possède des clés et relations contrôlées ; les mesures concordent avec R sans double comptage |
| C15 | Les cinq pages inscriptions, réussite, parcours, enquêtes et insertion sont présentes et utilisables avec des libellés métier |
| C16 | Les filtres, cas limites et actualisations sont testés ; journal, procédure de reprise et date des données sont vérifiables |

Ces critères sont des exigences futures, pas des contrôles déjà satisfaits.
La recette finale sera consignée avec commandes, résultats, anomalies et décision.

## Validation et gestion des changements

Le propriétaire du projet valide les définitions et le périmètre. Toute évolution
d'un dénominateur, d'une règle de simulation ou d'une fenêtre d'observation doit
être datée, documentée et suivie d'une reconstruction des sorties affectées.
La version 0.1 n'autorise pas encore la génération ou l'analyse.
