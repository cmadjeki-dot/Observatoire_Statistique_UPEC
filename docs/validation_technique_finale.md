# Validation technique finale — étape 37

Date : 19 octobre 2026. Démonstrateur personnel indépendant de l’UPEC.
Données entièrement synthétiques, résultats non officiels.

## Décision : validation technique locale favorable

Les contrôles ci-dessous ont été exécutés sur le poste Windows du projet.
La relance finale s’est terminée avec succès, sans avertissement enregistré
dans les étapes R. Cette décision clôt la recette technique locale ; elle ne
vaut ni validation métier institutionnelle, ni recette de production, ni
publication GitHub.

## Tableau des statuts réels

| Contrôle | Résultat de cette étape | Preuve locale |
|---|---|---|
| Audit du code | 61 fichiers R, scripts et tests parsés ; recherche ciblée sans motif interdit dans `R/` | `outputs/validation_finale/inventaire_code.csv`, `resultats_R.csv` |
| Suite complète `testthat` | **976 assertions réussies ; zéro échec, erreur ou avertissement** | `outputs/validation_finale/tests.csv`, journal d’exécution |
| Pipeline `targets` | `tar_make()` exécuté via le lanceur ; 33 cibles déjà à jour réutilisées | Journal, `outputs/pipeline_rapport/statut.csv` et magasin `store/` |
| Exports des tableaux de bord | Clés, relations, 33 valeurs, censures et empreintes conformes | `outputs/pipeline_dashboard/recette_mesures_R.csv`, `manifest_dashboard.csv` |
| Rapport final Quarto | HTML rendu à nouveau avec succès | `outputs/rapport_final/rapport_final.html` |
| Supports oraux Quarto | Diaporama, conducteur 13, discours et jury rendus à nouveau | Quatre HTML dans `outputs/presentation/` |
| Sources et dépendances | Lecture contrôlée conforme ; `renv::status()` synchronisé | Dernière ligne de `resultats_R.csv` et journal |
| Données canoniques | 3 archives brutes et 14 objets préparés conformes aux empreintes de leurs manifestes | `outputs/validation_finale/donnees_canoniques.csv` |
| Démarrage Shiny | Instance temporaire sur `127.0.0.1:3840`, HTTP 200, arrêt après test | `outputs/validation_finale/shiny.json`, journaux Shiny |
| Git | Branche `main`, diff sans erreur de blancs, huit chemins d’exclusion vérifiés, aucune signature sensible détectée parmi les candidats | `outputs/validation_finale/git.json`, `git_status.txt`, `git_avis.txt` |
| PDF | Non réalisé : LuaLaTeX indisponible ; format optionnel | `outputs/validation_finale/pdf.json` |
| Publication distante | Non réalisée : aucun remote, destination et fichiers à confirmer avant commits et push | `git.json`, `docs/preparation_publication.md` |

Le lancement principal réellement exécuté est :

```powershell
$env:LANG = 'fr_FR.UTF-8'
$env:LC_ALL = 'fr_FR.UTF-8'
& 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe' --no-save --no-restore scripts/validate_final.R
```

Sur un autre poste, adapter le chemin de l’exécutable. Le script lance les tests,
`scripts/refresh_dashboards.R` (qui appelle le pipeline `targets`), le contrôle
des exports et les cinq rendus Quarto, puis vérifie `renv`. Il ne lance pas
Shiny et ne modifie pas Git : ces deux recettes ont été exécutées séparément.
Le journal complet est `outputs/validation_finale_execution.log`.

Les 33 cibles réutilisées indiquent que le graphe était à jour ; cette relance
n’est pas présentée comme une reconstruction forcée depuis un magasin vide.
La reconstruction depuis les graines a été exercée dans les étapes précédentes.

## Corrections et incidents traités

Le cahier des charges indique désormais explicitement son statut de cadrage
historique et distingue acceptation interne du démonstrateur et validation UPEC.

Une première exécution du contrôleur a signalé à tort les URL Microsoft comme
des chemins Windows. Sa règle a été corrigée. Une modification du contrôleur
pendant cette première exécution a également perturbé sa lecture ; les erreurs
de fonction `as.characpifnot` de ce passage ne provenaient pas des analyses.
Le script stabilisé a été relancé intégralement et les neuf contrôles R ont
réussi. Les traces initiales sont conservées dans `premiere_execution.log` et
`premiers_resultats_R.csv`, sous `outputs/validation_finale/`.

Les avis Git LF/CRLF sont conservés : ils ne constituent pas des erreurs du
contrôle de blancs. Aucun package n’a été installé et aucun paramètre global
n’a été modifié pour terminer cette recette.

Un contrôle Git lancé sous le compte d’exécution élevé a rencontré la protection
de propriétaire du dépôt. Les contrôles ont été réexécutés avec succès dans le
contexte habituel du workspace, sans ajouter d’exception globale `safe.directory`.
Le fichier `git.json` contient le résultat de cette vérification réussie.

## Portée et limites de la recette

L’audit de code combine syntaxe et recherche ciblée de chemins absolus,
changements de répertoire ou installations dans les modules métier. Il ne
constitue pas une analyse statique exhaustive ni une revue indépendante.

Le contrôle HTTP prouve le démarrage de Shiny ; les comportements réactifs
sont exercés par les tests complets. Les recettes navigateur des cinq vues
et les tests Power BI Desktop/DAX sont des preuves antérieures, non rejouées
dans cette étape. Les exports R et leurs valeurs ont en revanche été revérifiés.
L’ancienne instance d’aperçu Shiny n’a pas été utilisée pour le test sur 3840.

La recherche de signatures de secrets ne garantit pas l’absence de tout secret.
Les données, résultats, caches et paramètres locaux restent exclus de Git.
Les fichiers sources récents ne sont pas tous commités ; aucun ajout à l’index,
commit, remote ou push n’a été réalisé dans cette étape.

## Décisions de clôture

- **Accepter la recette technique locale** du démonstrateur sur les preuves listées.
- **Conserver la note d’audit de 84/100**, sans réévaluation automatique : les
  réserves de validation indépendante, métier et orale demeurent.
- **Attendre la validation de l’utilisateur** avant de considérer la revue terminée.
- **Suspendre la publication GitHub** jusqu’à confirmation de la destination,
  de sa visibilité et du périmètre de fichiers, puis contrôle des commits.
- **Ne pas annoncer de production ni de résultat institutionnel.** PDF, validation
  métier, reproduction sur un autre poste, déploiement et planification restent
  des opérations distinctes, non réalisées ici.
