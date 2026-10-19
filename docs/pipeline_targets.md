# Pipeline de calcul — étape 27

Ce pipeline concerne le démonstrateur personnel indépendant de l'UPEC.
Les données et résultats sont entièrement synthétiques.

## Périmètre

Le point d'entrée est `data/processed/`, avec son manifeste et ses 14 RDS.
Ce mode de base ne reconstruit pas les données depuis les graines et ne
rend pas les rapports Quarto. Les modes complémentaires sont décrits plus bas.
Les sources et les anciens rapports sont préservés.

`_targets.R` définit les dépendances ; `R/pipeline/pipeline.R` contient les
fonctions d'orchestration et réutilise les fonctions métier existantes.
Les fichiers d'entrée, le catalogue YAML, la configuration de simulation,
DESCRIPTION et renv.lock sont suivis. Les fonctions sont suivies par targets.
Le contrôle qualité et la comparaison de la table analytique à sa reconstruction
bloquent toutes les analyses en cas de divergence.

Le graphe produit descriptions, enquêtes, cohortes, modèle et diagnostics,
indicateurs, audit descriptif de faisabilité causale et huit constats.
Aucun effet causal n'est estimé. Le modèle conserve sa coupe initiale,
sa séparation apprentissage/test et sa graine 20261020.

## Exécution dans le terminal PowerShell de VS Code

Depuis la racine, utiliser le Rscript constaté lors de l'audit :

```powershell
$env:LANG = 'fr_FR.UTF-8'
$env:LC_ALL = 'fr_FR.UTF-8'
& 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe' --no-save --no-restore scripts/run_pipeline.R
```

Sur un autre poste, adapter uniquement le chemin de l'exécutable dans la
commande. Restaurer les dépendances avec `renv::restore()` si nécessaire.
Le lancement refuse un environnement renv désynchronisé.
La tâche VS Code « R : pipeline targets » exécute le même script.

`targets::tar_manifest()` décrit le graphe ; `targets::tar_outdated()` identifie
les cibles périmées ; `targets::tar_meta(fields = c(name, error, warnings, seconds))`
permet d'examiner les erreurs et avertissements. Ne pas supprimer `_targets/`
pour une relance normale. Le cache reste exclu de Git.
Attendre la fin de la recette avant de lancer le pipeline habituel : deux
processus ne doivent pas utiliser simultanément le même magasin `_targets/`.
`targets` bloque ce cas ; une fois le premier processus terminé, relancer
normalement sans supprimer le magasin ni forcer son déverrouillage.

## Produits et état d'exécution

Un seul producteur écrit dans `outputs/pipeline/` : archive `resultats.rds`,
modèle RDS, indicateurs et constats CSV, synthèse Markdown, manifeste des sources
et manifeste des produits. Tous ces produits sont suivis comme fichiers :
un fichier supprimé ou modifié déclenche la reconstruction des exports.
Les CSV utilisent UTF-8, un point décimal et une virgule comme séparateur.

Utiliser `scripts/run_pipeline.R`, qui écrit `statut.csv` et ajoute les événements
à `journal.csv`. Un lancement direct de `tar_make()` ne met pas ce journal à jour.
**Seul un dernier statut `succes`, avec des produits conformes à leurs empreintes,
autorise l'utilisation des exports comme résultats courants.** En cas d'échec,
les anciens fichiers peuvent subsister, mais ne représentent pas ce lancement.
Les futurs consommateurs devront contrôler ce contrat avant affichage.

## Recette reproductible

```powershell
& 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe' --no-save --no-restore scripts/check_pipeline.R
```

La recette vérifie la concordance avec les archives numériques validées,
une relance sans recalcul, la reconstruction d'un CSV supprimé, une modification
isolée du seuil YAML, un échec qualité sur une copie et une reprise sans purge.
Elle conserve ses scénarios et leur journal sous `outputs/pipeline/recette_*`.
Les variables `UPEC_PIPELINE_INPUT`, `UPEC_PIPELINE_CONFIG` et
`UPEC_PIPELINE_OUTPUT` servent à isoler ces scénarios ; elles ne doivent pas
être configurées pour une exécution habituelle. Les sorties sont limitées
à `outputs/pipeline/` ou à un dossier `outputs/pipeline_*`.

## Reconstruction depuis les graines — étape 28

Le second mode reconstruit les données et les analyses sans lire `data/raw/`
ni `data/processed/`. Sa seule entrée statistique est `config/simulation.R`,
avec le catalogue d'indicateurs et les dépendances du projet. Il utilise le même
graphe aval et les mêmes fonctions métier. Le mode préparé reste disponible.

```powershell
& 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe' --no-save --no-restore scripts/run_reconstruction.R
& 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe' --no-save --no-restore scripts/check_reconstruction.R
```

La tâche VS Code « R : reconstruction depuis les graines » lance le premier
script. Le cache est dans `outputs/pipeline_reconstruction/store/` et les sorties
dans `outputs/pipeline_reconstruction/`. Ne pas lancer simultanément son lanceur
et sa recette : ils partagent ce magasin, distinct du `_targets/` du mode préparé.

Les 27 cibles comprennent la configuration, la génération reproductible,
l'injection contrôlée, la vérification de la détection, le nettoyage documenté,
la préparation, les analyses et les exports. Le nettoyage doit restaurer
exactement les onze tables normalisées avant toute analyse. Un journal périmé
ou une anomalie résiduelle bloque la préparation.

Le sous-dossier `reconstruction/` conserve séparément les deux bases brutes,
le journal des anomalies, les tables préparées et l'audit du nettoyage en RDS,
ainsi que les contrôles avant/après et un manifeste MD5. Ces archives sont des
sorties régénérables ; elles ne remplacent pas les fichiers canoniques ni leurs
fonctions de sauvegarde protégée. Il n'y a aucune promotion automatique vers
`data/`. Les métadonnées de nettoyage restent distinctes de la base originale.

La recette compare les archives reconstruites aux données canoniques uniquement
après exécution du graphe, puis compare indicateurs, évaluation du modèle et
constats aux références aval. Elle contrôle aussi la stabilité du cache,
la reconstruction d'une archive supprimée et la préservation des sources.
Ces lectures de comparaison ne sont pas des entrées du pipeline de reconstruction.

## Rapports consommateurs Quarto — étape 29

`scripts/run_reports.R` active la reconstruction complète et deux documents :
`reports/rapport_pilotage.qmd` (rapport détaillé) et `reports/note_pilotage.qmd`
(synthèse accessible aux responsables de formation). Ces documents lisent
`resultats.rds` ; ils ne simulent, ne nettoient et n'estiment aucun modèle.
Les graphiques présentent les tables déjà calculées. Les notebooks 00 à 11
conservent leur vocation pédagogique et leur reproduction manuelle ; leurs
anciens rendus ne sont ni remplacés ni intégrés silencieusement au nouveau graphe.

```powershell
& 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe' --no-save --no-restore scripts/run_reports.R
& 'C:\Program Files\R\R-4.6.1\bin\Rscript.exe' --no-save --no-restore scripts/check_reports.R
```

La tâche VS Code « R : rapports Quarto du pipeline » lance le premier script.
Le mode comporte 33 cibles. Son magasin est `outputs/pipeline_rapport/store/` ;
ses HTML autonomes et leurs manifestes compagnons sont sous
`outputs/pipeline_rapport/rapports/`. Le document QMD, le module de lecture et
l'exécutable Quarto sont suivis comme fichiers. Chaque HTML a son propre
producteur et ses propres dépendances éditoriales. Aucun package supplémentaire
ni `tarchetypes` n'est nécessaire.

`load_pipeline_report()` contrôle les empreintes des six produits et des sources,
ainsi que le verdict qualité. Par défaut, il exige le dernier statut `succes`.
Le paramètre interne `rendering = TRUE` autorise aussi `en_cours` pendant le
rendu effectué dans le graphe, après la cible d'export ; il refuse toujours
`echec`. Il ne doit pas servir à déclarer un ancien résultat comme courant.
Le succès n'est inscrit qu'après la fin de toutes les cibles, rendus compris.
Un HTML restant après un échec constitue une archive, pas un résultat courant.

Les manifestes compagnons enregistrent les empreintes des exports, du QMD,
du module de lecture et de l'exécutable Quarto, avec les versions de R et Quarto.
Les HTML sont des photographies du calcul ; leur statut courant dépend du
journal et de la concordance des empreintes, pas de leur seule présence.

La recette contrôle le graphe, les deux rendus, la concordance des constats,
la relance sans recalcul et la reconstruction d'un HTML supprimé. Une copie
éditoriale isolée vérifie que la branche du rapport devient périmée sans
invalider la note ou les analyses ; elle ne modifie pas les documents sources.
La variable `UPEC_PIPELINE_REPORT_SOURCE` sert uniquement à ce diagnostic.
Ne pas exécuter lanceur et recette simultanément sur leur magasin commun.

Shiny et le modèle Power BI restent des lots suivants.
